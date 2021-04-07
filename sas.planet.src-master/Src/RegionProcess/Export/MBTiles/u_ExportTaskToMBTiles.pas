{******************************************************************************}
{* SAS.Planet (SAS.�������)                                                   *}
{* Copyright (C) 2007-2015, SAS.Planet development team.                      *}
{* This program is free software: you can redistribute it and/or modify       *}
{* it under the terms of the GNU General Public License as published by       *}
{* the Free Software Foundation, either version 3 of the License, or          *}
{* (at your option) any later version.                                        *}
{*                                                                            *}
{* This program is distributed in the hope that it will be useful,            *}
{* but WITHOUT ANY WARRANTY; without even the implied warranty of             *}
{* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              *}
{* GNU General Public License for more details.                               *}
{*                                                                            *}
{* You should have received a copy of the GNU General Public License          *}
{* along with this program.  If not, see <http://www.gnu.org/licenses/>.      *}
{*                                                                            *}
{* http://sasgis.org                                                          *}
{* info@sasgis.org                                                            *}
{******************************************************************************}

unit u_ExportTaskToMBTiles;

interface

uses
  Types,
  Windows,
  SysUtils,
  Classes,
  t_GeoTypes,
  i_BinaryData,
  i_NotifierOperation,
  i_RegionProcessProgressInfo,
  i_ProjectionSetFactory,
  i_TileIteratorFactory,
  i_GeometryLonLat,
  i_TileInfoBasic,
  i_TileStorage,
  i_TileIterator,
  i_MapVersionRequest,
  i_BitmapTileSaveLoad,
  i_BitmapLayerProvider,
  u_StorageExportToMBTiles,
  u_ExportTaskAbstract;

type
  TExportTaskToMBTiles = class(TExportTaskAbstract)
  private
    FProjectionSetFactory: IProjectionSetFactory;
    FExportPath: string;
    FExportFileName: string;
    FTileStorage: ITileStorage;
    FMapVersion: IMapVersionRequest;
    FBitmapTileSaver: IBitmapTileSaver;
    FBitmapProvider: IBitmapTileUniProvider;
    FDirectTilesCopy: Boolean;
    FBasePoint: TPoint;
    FSQLiteStorage: TSQLiteStorageMBTilesBase;
  private
    function GetLonLatRect(const ATileIterator: ITileIterator): TDoubleRect;
  protected
    procedure ProcessRegion; override;
  public
    constructor Create(
      const AProgressInfo: IRegionProcessProgressInfoInternal;
      const AExportPath: string;
      const ATileIteratorFactory: ITileIteratorFactory;
      const AProjectionSetFactory: IProjectionSetFactory;
      const APolygon: IGeometryLonLatPolygon;
      const AZoomArr: TByteDynArray;
      const ATileStorage: ITileStorage;
      const AMapVersion: IMapVersionRequest;
      const ABitmapTileSaver: IBitmapTileSaver;
      const ABitmapProvider: IBitmapTileUniProvider;
      const ADirectTilesCopy: Boolean;
      const AUseXYZScheme: Boolean;
      const AMakeTileMillCompatibility: Boolean;
      const AName: string;
      const ADescription: string;
      const AAttribution: string;
      const AIsLayer: Boolean;
      const AImgFormat: string
    );
    destructor Destroy; override;
  end;

implementation

uses
  c_CoordConverter,
  i_ProjectionSet,
  i_Projection,
  i_Bitmap32Static,
  i_TileRect,
  u_ResStrings;

{ TExportTaskToMBTiles }

constructor TExportTaskToMBTiles.Create(
  const AProgressInfo: IRegionProcessProgressInfoInternal;
  const AExportPath: string;
  const ATileIteratorFactory: ITileIteratorFactory;
  const AProjectionSetFactory: IProjectionSetFactory;
  const APolygon: IGeometryLonLatPolygon;
  const AZoomArr: TByteDynArray;
  const ATileStorage: ITileStorage;
  const AMapVersion: IMapVersionRequest;
  const ABitmapTileSaver: IBitmapTileSaver;
  const ABitmapProvider: IBitmapTileUniProvider;
  const ADirectTilesCopy: Boolean;
  const AUseXYZScheme: Boolean;
  const AMakeTileMillCompatibility: Boolean;
  const AName: string;
  const ADescription: string;
  const AAttribution: string;
  const AIsLayer: Boolean;
  const AImgFormat: string
);
const
  cSQLiteStorageTypes: array [Boolean] of TSQLiteStorageMBTilesBaseClass = (
    TSQLiteStorageMBTilesClassic,
    TSQLiteStorageMBTilesTileMill
  );
var
  VSQLiteStorageClass: TSQLiteStorageMBTilesBaseClass;
begin
  inherited Create(
    AProgressInfo,
    APolygon,
    AZoomArr,
    ATileIteratorFactory
  );
  FProjectionSetFactory := AProjectionSetFactory;
  FExportPath := ExtractFilePath(AExportPath);
  FExportFileName := ExtractFileName(AExportPath);
  FTileStorage := ATileStorage;
  FMapVersion := AMapVersion;
  FBitmapTileSaver := ABitmapTileSaver;
  FBitmapProvider := ABitmapProvider;
  FDirectTilesCopy := ADirectTilesCopy;

  VSQLiteStorageClass := cSQLiteStorageTypes[AMakeTileMillCompatibility];

  FSQLiteStorage :=
    VSQLiteStorageClass.Create(
      FExportPath,
      FExportFileName,
      AName,
      ADescription,
      AAttribution,
      AIsLayer,
      AImgFormat,
      AUseXYZScheme
    );
end;

destructor TExportTaskToMBTiles.Destroy;
begin
  FreeAndNil(FSQLiteStorage);
  inherited;
end;

procedure TExportTaskToMBTiles.ProcessRegion;
var
  I: Integer;
  VZoom: Byte;
  VTile: TPoint;
  VDoDirectCopy: Boolean;
  VTilesToProcess: Int64;
  VTilesProcessed: Int64;
  VProjectionSet: IProjectionSet;
  VTileIterators: array of ITileIterator;
  VTileIterator: ITileIterator;
  VTileInfo: ITileInfoWithData;
  VBitmapTile: IBitmap32Static;
  VTileData: IBinaryData;
  VProjection: IProjection;
begin
  inherited;

  VDoDirectCopy := FDirectTilesCopy and Assigned(FTileStorage);

  if not VDoDirectCopy then begin
    Assert(FBitmapProvider <> nil);
    Assert(FBitmapTileSaver <> nil);
  end;

  if not DirectoryExists(FExportPath) then begin
    if not ForceDirectories(FExportPath) then begin
      RaiseLastOSError;
    end;
  end;

  SetLength(VTileIterators, Length(FZooms));

  VTilesToProcess := 0;

  if VDoDirectCopy then begin
    VProjectionSet := FTileStorage.ProjectionSet;
  end else begin
    VProjectionSet := FProjectionSetFactory.GetProjectionSetByCode(
      CGoogleProjectionEPSG,
      CTileSplitQuadrate256x256
    );
  end;

  for I := 0 to Length(FZooms) - 1 do begin
    VProjection := VProjectionSet.Zooms[FZooms[I]];
    VTileIterators[I] := Self.MakeTileIterator(VProjection);
    VTilesToProcess := VTilesToProcess + VTileIterators[I].TilesTotal;
  end;

  FSQLiteStorage.Open(GetLonLatRect(VTileIterators[0]), FZooms);
  try
    ProgressInfo.SetCaption(SAS_STR_ExportTiles);
    ProgressInfo.SetFirstLine(
      SAS_STR_AllSaves + ' ' + inttostr(VTilesToProcess) + ' ' + SAS_STR_Files
    );
    VTilesProcessed := 0;
    ProgressFormUpdateOnProgress(VTilesProcessed, VTilesToProcess);

    for I := 0 to Length(FZooms) - 1 do begin
      VZoom := FZooms[I];
      VTileIterator := VTileIterators[I];
      if Assigned(VTileIterator) then begin
        VProjection := VTileIterator.TilesRect.Projection;
        FBasePoint := VTileIterator.TilesRect.TopLeft;
        while VTileIterator.Next(VTile) do begin
          if CancelNotifier.IsOperationCanceled(OperationID) then begin
            Exit;
          end;

          if VDoDirectCopy then begin
            if Supports(FTileStorage.GetTileInfoEx(VTile, VZoom, FMapVersion, gtimWithData), ITileInfoWithData, VTileInfo) then begin
              FSQLiteStorage.Add(VTile, VZoom, VTileInfo.TileData);
            end;
          end else begin
            VBitmapTile :=
              FBitmapProvider.GetTile(
                Self.OperationID,
                Self.CancelNotifier,
                VProjection,
                VTile
              );
            if Assigned(VBitmapTile) then begin
              VTileData := FBitmapTileSaver.Save(VBitmapTile);
              FSQLiteStorage.Add(VTile, VZoom, VTileData);
            end;
          end;

          Inc(VTilesProcessed);
          if VTilesProcessed mod 100 = 0 then begin
            ProgressFormUpdateOnProgress(VTilesProcessed, VTilesToProcess);
          end;
        end;
      end;
    end;
  finally
    FSQLiteStorage.Close;
  end;
end;

function TExportTaskToMBTiles.GetLonLatRect(const ATileIterator: ITileIterator): TDoubleRect;
var
  VRect: TRect;
  VTileRect: ITileRect;
  VProjection: IProjection;
begin
  VTileRect := ATileIterator.TilesRect;
  VProjection := VTileRect.Projection;
  VRect := VTileRect.Rect;
  Result := VProjection.TileRect2LonLatRect(VRect);
end;

end.

{******************************************************************************}
{* SAS.Planet (SAS.�������)                                                   *}
{* Copyright (C) 2007-2014, SAS.Planet development team.                      *}
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

unit u_ThreadDeleteTiles;

interface

uses
  Windows,
  SysUtils,
  Classes,
  i_NotifierOperation,
  i_RegionProcessProgressInfo,
  i_Projection,
  i_GeometryLonLat,
  i_TileIteratorFactory,
  i_MapVersionRequest,
  i_PredicateByTileInfo,
  i_TileStorage,
  u_RegionProcessTaskAbstract;

type
  TThreadDeleteTiles = class(TRegionProcessTaskAbstract)
  private
    FZoom: byte;
    FProjection: IProjection;
    FTileStorage: ITileStorage;
    FVersion: IMapVersionRequest;
    FPredicate: IPredicateByTileInfo;
  protected
    procedure ProcessRegion; override;
    procedure ProgressFormUpdateOnProgress(
      const AProcessed, AToProcess, ADeleted: Int64
    );
  public
    constructor Create(
      const AProgressInfo: IRegionProcessProgressInfoInternal;
      const ATileIteratorFactory: ITileIteratorFactory;
      const APolyLL: IGeometryLonLatPolygon;
      const AProjection: IProjection;
      const ATileStorage: ITileStorage;
      const AVersion: IMapVersionRequest;
      const APredicate: IPredicateByTileInfo
    );
  end;

implementation

uses
  i_TileIterator,
  i_TileInfoBasic,
  u_ResStrings;

constructor TThreadDeleteTiles.Create(
  const AProgressInfo: IRegionProcessProgressInfoInternal;
  const ATileIteratorFactory: ITileIteratorFactory;
  const APolyLL: IGeometryLonLatPolygon;
  const AProjection: IProjection;
  const ATileStorage: ITileStorage;
  const AVersion: IMapVersionRequest;
  const APredicate: IPredicateByTileInfo
);
begin
  inherited Create(
    AProgressInfo,
    APolyLL,
    ATileIteratorFactory
  );
  FProjection := AProjection;
  FZoom := AProjection.Zoom;
  FTileStorage := ATileStorage;
  FPredicate := APredicate;
  FVersion := AVersion;
end;

procedure TThreadDeleteTiles.ProcessRegion;
var
  VTile: TPoint;
  VTileIterator: ITileIterator;
  VDeletedCount: integer;
  VTilesToProcess: Int64;
  VTilesProcessed: Int64;
  VTileInfo: ITileInfoBasic;
  VGetTileInfoMode: TGetTileInfoMode;
begin
  VTileIterator := Self.MakeTileIterator(FProjection);
  VTilesToProcess := VTileIterator.TilesTotal;
  ProgressInfo.SetCaption(
    SAS_STR_Deleted + ' ' + inttostr(VTilesToProcess) + ' ' + SAS_STR_Files + ' (x' + inttostr(FZoom + 1) + ')'
  );
  VTilesProcessed := 0;
  VDeletedCount := 0;
  ProgressFormUpdateOnProgress(VTilesProcessed, VTilesToProcess, VDeletedCount);

  if FPredicate.UseTileData then begin
    VGetTileInfoMode := gtimWithData;
  end else begin
    VGetTileInfoMode := gtimAsIs;
  end;

  // foreach selected tile
  while VTileIterator.Next(VTile) do begin
    if CancelNotifier.IsOperationCanceled(OperationID) then begin
      exit;
    end;
    VTileInfo := FTileStorage.GetTileInfoEx(VTile, FZoom, FVersion, VGetTileInfoMode);
    if Assigned(VTileInfo) then begin
      if FPredicate.Check(VTileInfo, FZoom, VTile) then begin
        if FTileStorage.DeleteTile(VTile, FZoom, VTileInfo.VersionInfo) then begin
          inc(VDeletedCount);
        end;
        ProgressFormUpdateOnProgress(VTilesProcessed, VTilesToProcess, VDeletedCount);
      end;
    end;
    inc(VTilesProcessed);
  end;
end;

procedure TThreadDeleteTiles.ProgressFormUpdateOnProgress(
  const AProcessed, AToProcess, ADeleted: Int64
);
begin
  ProgressInfo.SetProcessedRatio(AProcessed / AToProcess);
  ProgressInfo.SetSecondLine(SAS_STR_Processed + ' ' + inttostr(AProcessed));
  ProgressInfo.SetFirstLine(SAS_STR_AllDelete + ' ' + inttostr(ADeleted) + ' ' + SAS_STR_Files);
end;

end.

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

unit u_ExportProviderYaMobileV4;

interface

uses
  Forms,
  i_LanguageManager,
  i_GeometryLonLat,
  i_Bitmap32BufferFactory,
  i_TileIteratorFactory,
  i_ProjectionSetFactory,
  i_BitmapTileSaveLoadFactory,
  i_RegionProcessTask,
  i_RegionProcessProgressInfo,
  i_RegionProcessProgressInfoInternalFactory,
  u_ExportProviderAbstract,
  fr_MapSelect,
  fr_ExportYaMobileV4;

type
  TExportProviderYaMobileV4 = class(TExportProviderBase)
  private
    FFrame: TfrExportYaMobileV4;
    FProjectionSetFactory: IProjectionSetFactory;
    FBitmap32StaticFactory: IBitmap32StaticFactory;
    FBitmapTileSaveLoadFactory: IBitmapTileSaveLoadFactory;
  protected
    function CreateFrame: TFrame; override;
  protected
    function GetCaption: string; override;
    function PrepareTask(
      const APolygon: IGeometryLonLatPolygon;
      const AProgressInfo: IRegionProcessProgressInfoInternal
    ): IRegionProcessTask; override;
  public
    constructor Create(
      const AProgressFactory: IRegionProcessProgressInfoInternalFactory;
      const ALanguageManager: ILanguageManager;
      const AMapSelectFrameBuilder: IMapSelectFrameBuilder;
      const ATileIteratorFactory: ITileIteratorFactory;
      const ABitmap32StaticFactory: IBitmap32StaticFactory;
      const ABitmapTileSaveLoadFactory: IBitmapTileSaveLoadFactory;
      const AProjectionSetFactory: IProjectionSetFactory
    );
  end;

implementation

uses
  Types,
  Classes,
  SysUtils,
  i_MapVersionRequest,
  i_RegionProcessParamsFrame,
  u_ExportTaskToYaMobileV4,
  u_BitmapLayerProviderMapWithLayer,
  u_ResStrings;

{ TExportProviderYaMaps }

constructor TExportProviderYaMobileV4.Create(
  const AProgressFactory: IRegionProcessProgressInfoInternalFactory;
  const ALanguageManager: ILanguageManager;
  const AMapSelectFrameBuilder: IMapSelectFrameBuilder;
  const ATileIteratorFactory: ITileIteratorFactory;
  const ABitmap32StaticFactory: IBitmap32StaticFactory;
  const ABitmapTileSaveLoadFactory: IBitmapTileSaveLoadFactory;
  const AProjectionSetFactory: IProjectionSetFactory
);
begin
  Assert(Assigned(ABitmap32StaticFactory));
  inherited Create(
    AProgressFactory,
    ALanguageManager,
    AMapSelectFrameBuilder,
    ATileIteratorFactory
  );
  FProjectionSetFactory := AProjectionSetFactory;
  FBitmap32StaticFactory := ABitmap32StaticFactory;
  FBitmapTileSaveLoadFactory := ABitmapTileSaveLoadFactory;
end;

function TExportProviderYaMobileV4.CreateFrame: TFrame;
begin
  FFrame :=
    TfrExportYaMobileV4.Create(
      Self.LanguageManager,
      Self.MapSelectFrameBuilder
    );
  Result := FFrame;
  Assert(Supports(Result, IRegionProcessParamsFrameZoomArray));
  Assert(Supports(Result, IRegionProcessParamsFrameTargetPath));
end;

function TExportProviderYaMobileV4.GetCaption: string;
begin
  Result := SAS_STR_ExportYaMobileV4Caption;
end;

function TExportProviderYaMobileV4.PrepareTask(
  const APolygon: IGeometryLonLatPolygon;
  const AProgressInfo: IRegionProcessProgressInfoInternal
): IRegionProcessTask;
var
  VPath: string;
  VZoomArr: TByteDynArray;
  comprSat, comprMap: byte;
  VTasks: TExportTaskYaMobileV4Array;
  VTaskIndex: Integer;
  VMapVersion: IMapVersionRequest;
  VLayerVersion: IMapVersionRequest;
begin
  inherited;
  VZoomArr := (ParamsFrame as IRegionProcessParamsFrameZoomArray).ZoomArray;
  VPath := (ParamsFrame as IRegionProcessParamsFrameTargetPath).Path;
  comprSat := FFrame.seSatCompress.Value;
  comprMap := FFrame.seMapCompress.Value;

  VTaskIndex := -1;
  if (FFrame.GetSat.GetSelectedMapType <> nil) or (FFrame.GetHyb.GetSelectedMapType <> nil) then begin
    Inc(VTaskIndex);
    SetLength(VTasks, VTaskIndex + 1);
    if FFrame.GetHyb.GetSelectedMapType <> nil then begin
      VTasks[VTaskIndex].FMapId := 12;
      VTasks[VTaskIndex].FMapName := FFrame.GetHyb.GetSelectedMapType.GUIConfig.Name.Value;
    end else begin
      VTasks[VTaskIndex].FMapId := 10;
      VTasks[VTaskIndex].FMapName := FFrame.GetSat.GetSelectedMapType.GUIConfig.Name.Value;
    end;
    VTasks[VTaskIndex].FSaver := FBitmapTileSaveLoadFactory.CreateJpegSaver(comprSat);
    VMapVersion := nil;
    if FFrame.GetSat.GetSelectedMapType <> nil then begin
      VMapVersion := FFrame.GetSat.GetSelectedMapType.VersionRequest.GetStatic;
    end;
    VLayerVersion := nil;
    if FFrame.GetHyb.GetSelectedMapType <> nil then begin
      VLayerVersion := FFrame.GetHyb.GetSelectedMapType.VersionRequest.GetStatic;
    end;
    VTasks[VTaskIndex].FImageProvider :=
      TBitmapLayerProviderMapWithLayer.Create(
        FBitmap32StaticFactory,
        FFrame.GetSat.GetSelectedMapType,
        VMapVersion,
        FFrame.GetHyb.GetSelectedMapType,
        VLayerVersion,
        nil,
        False,
        False
      );
  end;
  if FFrame.GetMap.GetSelectedMapType <> nil then begin
    Inc(VTaskIndex);
    SetLength(VTasks, VTaskIndex + 1);
    VTasks[VTaskIndex].FMapId := 11;
    VTasks[VTaskIndex].FMapName := FFrame.GetMap.GetSelectedMapType.GUIConfig.Name.Value;
    VTasks[VTaskIndex].FSaver := FBitmapTileSaveLoadFactory.CreatePngSaver(i8bpp, comprMap);
    VTasks[VTaskIndex].FImageProvider :=
      TBitmapLayerProviderMapWithLayer.Create(
        FBitmap32StaticFactory,
        FFrame.GetMap.GetSelectedMapType,
        FFrame.GetMap.GetSelectedMapType.VersionRequest.GetStatic,
        nil,
        nil,
        nil,
        False,
        False
      );
  end;

  Result :=
    TExportTaskToYaMobileV4.Create(
      AProgressInfo,
      FProjectionSetFactory,
      Self.TileIteratorFactory,
      FBitmap32StaticFactory,
      VPath,
      APolygon,
      VTasks,
      VZoomArr,
      FFrame.chkReplaseTiles.Checked,
      TYaMobileV4TileSize(FFrame.rgTileSize.ItemIndex)
    );
end;

end.

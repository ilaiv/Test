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

unit u_ExportProviderYaMobileV3;

interface

uses
  Forms,
  i_LanguageManager,
  i_ProjectionSetFactory,
  i_Bitmap32BufferFactory,
  i_TileIteratorFactory,
  i_GeometryLonLat,
  i_RegionProcessTask,
  i_RegionProcessProgressInfo,
  i_RegionProcessProgressInfoInternalFactory,
  i_BitmapTileSaveLoadFactory,
  u_ExportProviderAbstract,
  fr_MapSelect,
  fr_ExportYaMobileV3;

type
  TExportProviderYaMobileV3 = class(TExportProviderBase)
  private
    FFrame: TfrExportYaMobileV3;
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
  u_ExportTaskToYaMobileV3,
  u_BitmapLayerProviderMapWithLayer,
  u_ResStrings;

{ TExportProviderYaMobileV3 }

constructor TExportProviderYaMobileV3.Create(
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
  FBitmap32StaticFactory := ABitmap32StaticFactory;
  FBitmapTileSaveLoadFactory := ABitmapTileSaveLoadFactory;
  FProjectionSetFactory := AProjectionSetFactory;
end;

function TExportProviderYaMobileV3.CreateFrame: TFrame;
begin
  FFrame :=
    TfrExportYaMobileV3.Create(
      Self.LanguageManager,
      Self.MapSelectFrameBuilder
    );
  Result := FFrame;
  Assert(Supports(Result, IRegionProcessParamsFrameZoomArray));
  Assert(Supports(Result, IRegionProcessParamsFrameTargetPath));
end;

function TExportProviderYaMobileV3.GetCaption: string;
begin
  Result := SAS_STR_ExportYaMobileV3Caption;
end;

function TExportProviderYaMobileV3.PrepareTask(
  const APolygon: IGeometryLonLatPolygon;
  const AProgressInfo: IRegionProcessProgressInfoInternal
): IRegionProcessTask;
var
  VPath: string;
  VZoomArr: TByteDynArray;
  comprSat, comprMap: byte;
  Replace: boolean;
  VTasks: TExportTaskYaMobileV3Array;
  VTaskIndex: Integer;
  VMapVersion: IMapVersionRequest;
  VLayerVersion: IMapVersionRequest;
begin
  inherited;
  VZoomArr := (ParamsFrame as IRegionProcessParamsFrameZoomArray).ZoomArray;
  VPath := (ParamsFrame as IRegionProcessParamsFrameTargetPath).Path;

  comprSat := FFrame.seSatCompress.Value;
  comprMap := FFrame.seMapCompress.Value;
  Replace := FFrame.chkReplaseTiles.Checked;

  VTaskIndex := -1;
  if (FFrame.GetSat.GetSelectedMapType <> nil) or (FFrame.GetHyb.GetSelectedMapType <> nil) then begin
    Inc(VTaskIndex);
    SetLength(VTasks, VTaskIndex + 1);
    VTasks[VTaskIndex].FMapId := 2;
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
    VTasks[VTaskIndex].FMapId := 1;
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
    TExportTaskToYaMobileV3.Create(
      AProgressInfo,
      FProjectionSetFactory,
      Self.TileIteratorFactory,
      FBitmap32StaticFactory,
      VPath,
      APolygon,
      VTasks,
      VZoomArr,
      Replace
    );
end;

end.

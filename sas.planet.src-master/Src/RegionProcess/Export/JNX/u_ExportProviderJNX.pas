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

unit u_ExportProviderJNX;

interface

uses
  Forms,
  i_GeometryLonLat,
  i_TileIteratorFactory,
  i_LanguageManager,
  i_BitmapTileSaveLoadFactory,
  i_BitmapPostProcessing,
  i_RegionProcessTask,
  i_RegionProcessProgressInfo,
  i_RegionProcessProgressInfoInternalFactory,
  u_ExportProviderAbstract,
  fr_MapSelect,
  fr_ExportToJNX;

type
  TExportProviderJNX = class(TExportProviderBase)
  private
    FBitmapTileSaveLoadFactory: IBitmapTileSaveLoadFactory;
    FBitmapPostProcessing: IBitmapPostProcessingChangeable;
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
      const ABitmapTileSaveLoadFactory: IBitmapTileSaveLoadFactory;
      const ABitmapPostProcessing: IBitmapPostProcessingChangeable
    );
  end;

implementation

uses
  Classes,
  SysUtils,
  i_RegionProcessParamsFrame,
  u_ExportToJnxTask,
  u_ExportTaskToJnx,
  u_ResStrings;

{ TExportProviderJNX }

constructor TExportProviderJNX.Create(
  const AProgressFactory: IRegionProcessProgressInfoInternalFactory;
  const ALanguageManager: ILanguageManager;
  const AMapSelectFrameBuilder: IMapSelectFrameBuilder;
  const ATileIteratorFactory: ITileIteratorFactory;
  const ABitmapTileSaveLoadFactory: IBitmapTileSaveLoadFactory;
  const ABitmapPostProcessing: IBitmapPostProcessingChangeable
);
begin
  inherited Create(
    AProgressFactory,
    ALanguageManager,
    AMapSelectFrameBuilder,
    ATileIteratorFactory
  );
  FBitmapTileSaveLoadFactory := ABitmapTileSaveLoadFactory;
  FBitmapPostProcessing := ABitmapPostProcessing;
end;

function TExportProviderJNX.CreateFrame: TFrame;
begin
  Result :=
    TfrExportToJNX.Create(
      Self.LanguageManager,
      FBitmapTileSaveLoadFactory,
      Self.MapSelectFrameBuilder,
      'JNX |*.jnx',
      'jnx'
    );
  Assert(Supports(Result, IRegionProcessParamsFrameTargetPath));
  Assert(Supports(Result, IRegionProcessParamsFrameExportToJNX));
end;

function TExportProviderJNX.GetCaption: string;
begin
  Result := SAS_STR_ExportJNXPackCaption;
end;

function TExportProviderJNX.PrepareTask(
  const APolygon: IGeometryLonLatPolygon;
  const AProgressInfo: IRegionProcessProgressInfoInternal
): IRegionProcessTask;
var
  VPath: string;
  VProductName: string;
  VMapName: string;
  VJNXVersion: integer;
  VZorder: integer;
  VProductID: integer;
  VTasks: TExportTaskJnxArray;
  VUseRecolor: Boolean;
  VBitmapPostProcessing: IBitmapPostProcessing;
begin
  inherited;

  VPath := (ParamsFrame as IRegionProcessParamsFrameTargetPath).Path;
  VProductName := (ParamsFrame as IRegionProcessParamsFrameExportToJNX).ProductName;
  VMapName := (ParamsFrame as IRegionProcessParamsFrameExportToJNX).MapName;
  VJNXVersion := (ParamsFrame as IRegionProcessParamsFrameExportToJNX).JNXVersion;
  VZorder := (ParamsFrame as IRegionProcessParamsFrameExportToJNX).ZOrder;
  VProductID := (ParamsFrame as IRegionProcessParamsFrameExportToJNX).ProductID;
  VTasks := (ParamsFrame as IRegionProcessParamsFrameExportToJNX).Tasks;
  VUseRecolor := (ParamsFrame as IRegionProcessParamsFrameExportToJNX).UseRecolor;
  VBitmapPostProcessing := nil;
  if VUseRecolor then begin
    VBitmapPostProcessing := FBitmapPostProcessing.GetStatic;
  end;

  Result :=
    TExportTaskToJnx.Create(
      AProgressInfo,
      Self.TileIteratorFactory,
      VPath,
      APolygon,
      VTasks,
      VProductName,
      VMapName,
      VBitmapPostProcessing,
      VJNXVersion,
      VZorder,
      VProductID
    );
end;

end.

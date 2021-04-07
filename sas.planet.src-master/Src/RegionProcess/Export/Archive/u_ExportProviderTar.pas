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

unit u_ExportProviderTar;

interface

uses
  Forms,
  i_LanguageManager,
  i_GeometryLonLat,
  i_TileIteratorFactory,
  i_ArchiveReadWriteFactory,
  i_TileStorageTypeList,
  i_TileFileNameGeneratorsList,
  i_RegionProcessTask,
  i_RegionProcessProgressInfo,
  i_RegionProcessProgressInfoInternalFactory,
  u_ExportProviderAbstract,
  fr_MapSelect,
  fr_ExportToFileCont;

type
  TExportProviderTar = class(TExportProviderBase)
  private
    FArchiveReadWriteFactory: IArchiveReadWriteFactory;
    FTileStorageTypeList: ITileStorageTypeListStatic;
    FTileNameGenerator: ITileFileNameGeneratorsList;
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
      const AArchiveReadWriteFactory: IArchiveReadWriteFactory;
      const ATileStorageTypeList: ITileStorageTypeListStatic;
      const ATileNameGenerator: ITileFileNameGeneratorsList
    );
  end;

implementation

uses
  Types,
  Classes,
  SysUtils,
  i_MapType,
  i_RegionProcessParamsFrame,
  i_TileFileNameGenerator,
  u_ExportTaskToArchive,
  u_ResStrings;

{ TExportProviderTar }

constructor TExportProviderTar.Create(
  const AProgressFactory: IRegionProcessProgressInfoInternalFactory;
  const ALanguageManager: ILanguageManager;
  const AMapSelectFrameBuilder: IMapSelectFrameBuilder;
  const ATileIteratorFactory: ITileIteratorFactory;
  const AArchiveReadWriteFactory: IArchiveReadWriteFactory;
  const ATileStorageTypeList: ITileStorageTypeListStatic;
  const ATileNameGenerator: ITileFileNameGeneratorsList
);
begin
  inherited Create(
    AProgressFactory,
    ALanguageManager,
    AMapSelectFrameBuilder,
    ATileIteratorFactory
  );
  FArchiveReadWriteFactory := AArchiveReadWriteFactory;
  FTileStorageTypeList := ATileStorageTypeList;
  FTileNameGenerator := ATileNameGenerator;
end;

function TExportProviderTar.CreateFrame: TFrame;
begin
  Result :=
    TfrExportToFileCont.Create(
      Self.LanguageManager,
      Self.MapSelectFrameBuilder,
      FTileNameGenerator,
      FTileStorageTypeList,
      'Tar |*.tar',
      'tar'
    );
  Assert(Supports(Result, IRegionProcessParamsFrameZoomArray));
  Assert(Supports(Result, IRegionProcessParamsFrameOneMap));
  Assert(Supports(Result, IRegionProcessParamsFrameTargetPath));
  Assert(Supports(Result, IRegionProcessParamsFrameExportToFileCont));
end;

function TExportProviderTar.GetCaption: string;
begin
  Result := SAS_STR_ExportTarPackCaption;
end;

function TExportProviderTar.PrepareTask(
  const APolygon: IGeometryLonLatPolygon;
  const AProgressInfo: IRegionProcessProgressInfoInternal
): IRegionProcessTask;
var
  VPath: string;
  Zoomarr: TByteDynArray;
  VMapType: IMapType;
  VNameGenerator: ITileFileNameGenerator;
begin
  inherited;
  Zoomarr := (ParamsFrame as IRegionProcessParamsFrameZoomArray).ZoomArray;
  VPath := (ParamsFrame as IRegionProcessParamsFrameTargetPath).Path;
  VMapType := (ParamsFrame as IRegionProcessParamsFrameOneMap).MapType;
  VNameGenerator := (ParamsFrame as IRegionProcessParamsFrameExportToFileCont).NameGenerator;

  Result :=
    TExportTaskToArchive.Create(
      AProgressInfo,
      FArchiveReadWriteFactory.TarSequential.WriterFactory.Build(VPath),
      Self.TileIteratorFactory,
      APolygon,
      Zoomarr,
      VMapType.TileStorage,
      VNameGenerator
    );
end;

end.

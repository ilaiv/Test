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

unit u_ProviderDeleteMarks;

interface

uses
  Windows,
  Forms,
  i_LanguageManager,
  i_MarkSystem,
  i_GeometryProjectedFactory,
  i_GeometryLonLat,
  i_LocalCoordConverterChangeable,
  i_RegionProcessTask,
  i_RegionProcessProgressInfo,
  i_RegionProcessProgressInfoInternalFactory,
  fr_MapSelect,
  u_ExportProviderAbstract;

type
  TProviderDeleteMarks = class(TExportProviderBase)
  private
    FVectorGeometryProjectedFactory: IGeometryProjectedFactory;
    FMarkSystem: IMarkSystem;
    FPosition: ILocalCoordConverterChangeable;
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
      const APosition: ILocalCoordConverterChangeable;
      const AVectorGeometryProjectedFactory: IGeometryProjectedFactory;
      const AMarkSystem: IMarkSystem
    );
  end;

implementation

uses
  Classes,
  SysUtils,
  gnugettext,
  i_RegionProcessParamsFrame,
  i_Projection,
  i_GeometryProjected,
  u_ThreadDeleteMarks,
  u_ResStrings,
  fr_DeleteMarks;

{ TProviderDeleteMarks }

constructor TProviderDeleteMarks.Create(
  const AProgressFactory: IRegionProcessProgressInfoInternalFactory;
  const ALanguageManager: ILanguageManager;
  const AMapSelectFrameBuilder: IMapSelectFrameBuilder;
  const APosition: ILocalCoordConverterChangeable;
  const AVectorGeometryProjectedFactory: IGeometryProjectedFactory;
  const AMarkSystem: IMarkSystem
);
begin
  inherited Create(
    AProgressFactory,
    ALanguageManager,
    AMapSelectFrameBuilder,
    nil
  );
  FPosition := APosition;
  FVectorGeometryProjectedFactory := AVectorGeometryProjectedFactory;
  FMarkSystem := AMarkSystem;
end;

function TProviderDeleteMarks.CreateFrame: TFrame;
begin
  Result := TfrDeleteMarks.Create(Self.LanguageManager);
  Assert(Supports(Result, IRegionProcessParamsFrameMarksState));
end;

function TProviderDeleteMarks.GetCaption: string;
begin
  Result := _('Placemarks');
end;

function TProviderDeleteMarks.PrepareTask(
  const APolygon: IGeometryLonLatPolygon;
  const AProgressInfo: IRegionProcessProgressInfoInternal
): IRegionProcessTask;
var
  VProjection: IProjection;
  VProjectedPolygon: IGeometryProjectedPolygon;
  VMarkState: Byte;
  VDelHiddenMarks: Boolean;
begin
  inherited;
  VMarkState := (ParamsFrame as IRegionProcessParamsFrameMarksState).GetMarksState;

  if VMarkState <> 0 then begin
    if (Application.MessageBox(pchar(SAS_MSG_DeleteMarksInRegionAsk), pchar(SAS_MSG_coution), 36) <> IDYES) then begin
      Exit;
    end;
  end;

  VProjection := FPosition.GetStatic.Projection;
  VProjectedPolygon :=
    FVectorGeometryProjectedFactory.CreateProjectedPolygonByLonLatPolygon(
      VProjection,
      APolygon
    );
  VDelHiddenMarks := (ParamsFrame as IRegionProcessParamsFrameMarksState).GetDeleteHiddenMarks;
  Result :=
    TThreadDeleteMarks.Create(
      AProgressInfo,
      APolygon,
      VProjectedPolygon,
      VProjection,
      FMarkSystem,
      VMarkState,
      VDelHiddenMarks
    );
end;

end.

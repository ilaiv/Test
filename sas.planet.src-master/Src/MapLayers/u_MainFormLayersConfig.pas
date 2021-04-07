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

unit u_MainFormLayersConfig;

interface

uses
  i_MapLayerGridsConfig,
  i_StatBarConfig,
  i_SunCalcConfig,
  i_MapLayerGPSMarkerConfig,
  i_MapLayerGPSTrackConfig,
  i_MapLayerNavToPointMarkerConfig,
  i_MarksLayerConfig,
  i_KmlLayerConfig,
  i_MiniMapLayerConfig,
  i_CenterScaleConfig,
  i_ScaleLineConfig,
  i_LastSelectionLayerConfig,
  i_MergePolygonsResultLayerConfig,
  i_CalcLineLayerConfig,
  i_CalcCircleLayerConfig,
  i_SelectionRectLayerConfig,
  i_SelectionPolygonLayerConfig,
  i_SelectionPolylineLayerConfig,
  i_MarkPolygonLayerConfig,
  i_MarkPolyLineLayerConfig,
  i_FillingMapLayerConfig,
  i_MainMapLayerConfig,
  i_GotoLayerConfig,
  i_FullMapMouseCursorLayerConfig,
  i_MainFormLayersConfig,
  u_ConfigDataElementComplexBase;

type
  TMainFormLayersConfig = class(TConfigDataElementComplexBase, IMainFormLayersConfig)
  private
    FMainMapLayerConfig: IMainMapLayerConfig;
    FMapLayerGridsConfig: IMapLayerGridsConfig;
    FStatBar: IStatBarConfig;
    FSunCalcConfig: ISunCalcConfig;
    FGPSMarker: IMapLayerGPSMarkerConfig;
    FGPSTrackConfig: IMapLayerGPSTrackConfig;
    FNavToPointMarkerConfig: IMapLayerNavToPointMarkerConfig;
    FMarksLayerConfig: IMarksLayerConfig;
    FKmlLayerConfig: IKmlLayerConfig;
    FMiniMapLayerConfig: IMiniMapLayerConfig;
    FCenterScaleConfig: ICenterScaleConfig;
    FScaleLineConfig: IScaleLineConfig;
    FLastSelectionLayerConfig: ILastSelectionLayerConfig;
    FMergePolygonsResultLayerConfig: IMergePolygonsResultLayerConfig;
    FCalcLineLayerConfig: ICalcLineLayerConfig;
    FCalcCircleLayerConfig: ICalcCircleLayerConfig;
    FSelectionRectLayerConfig: ISelectionRectLayerConfig;
    FSelectionPolygonLayerConfig: ISelectionPolygonLayerConfig;
    FSelectionPolylineLayerConfig: ISelectionPolylineLayerConfig;
    FMarkPolygonLayerConfig: IMarkPolygonLayerConfig;
    FMarkPolyLineLayerConfig: IMarkPolyLineLayerConfig;
    FFillingMapLayerConfig: IFillingMapLayerConfig;
    FGotoLayerConfig: IGotoLayerConfig;
    FFullMapMouseCursorLayerConfig: IFullMapMouseCursorLayerConfig;
  private
    function GetMainMapLayerConfig: IMainMapLayerConfig;
    function GetMapLayerGridsConfig: IMapLayerGridsConfig;
    function GetStatBar: IStatBarConfig;
    function GetSunCalcConfig: ISunCalcConfig;
    function GetGPSMarker: IMapLayerGPSMarkerConfig;
    function GetGPSTrackConfig: IMapLayerGPSTrackConfig;
    function GetNavToPointMarkerConfig: IMapLayerNavToPointMarkerConfig;
    function GetMarksLayerConfig: IMarksLayerConfig;
    function GetKmlLayerConfig: IKmlLayerConfig;
    function GetMiniMapLayerConfig: IMiniMapLayerConfig;
    function GetCenterScaleConfig: ICenterScaleConfig;
    function GetScaleLineConfig: IScaleLineConfig;
    function GetLastSelectionLayerConfig: ILastSelectionLayerConfig;
    function GetMergePolygonsResultLayerConfig: IMergePolygonsResultLayerConfig;
    function GetCalcLineLayerConfig: ICalcLineLayerConfig;
    function GetCalcCircleLayerConfig: ICalcCircleLayerConfig;
    function GetSelectionRectLayerConfig: ISelectionRectLayerConfig;
    function GetSelectionPolygonLayerConfig: ISelectionPolygonLayerConfig;
    function GetSelectionPolylineLayerConfig: ISelectionPolylineLayerConfig;
    function GetMarkPolygonLayerConfig: IMarkPolygonLayerConfig;
    function GetMarkPolyLineLayerConfig: IMarkPolyLineLayerConfig;
    function GetFillingMapLayerConfig: IFillingMapLayerConfig;
    function GetGotoLayerConfig: IGotoLayerConfig;
    function GetFullMapMouseCursorLayerConfig: IFullMapMouseCursorLayerConfig;
  public
    constructor Create;
  end;

implementation

uses
  u_ConfigSaveLoadStrategyBasicProviderSubItem,
  u_ConfigSaveLoadStrategyBasicUseProvider,
  u_MainMapLayerConfig,
  u_MapLayerGridsConfig,
  u_StatBarConfig,
  u_SunCalcConfig,
  u_MapLayerGPSMarkerConfig,
  u_MapLayerGPSTrackConfig,
  u_MarksLayerConfig,
  u_KmlLayerConfig,
  u_MiniMapLayerConfig,
  u_CenterScaleConfig,
  u_ScaleLineConfig,
  u_LastSelectionLayerConfig,
  u_MergePolygonsResultLayerConfig,
  u_CalcLineLayerConfig,
  u_CalcCircleLayerConfig,
  u_SelectionRectLayerConfig,
  u_SelectionPolygonLayerConfig,
  u_SelectionPolyLineLayerConfig,
  u_MarkPolygonLayerConfig,
  u_MarkPolyLineLayerConfig,
  u_FillingMapLayerConfig,
  u_GotoLayerConfig,
  u_FullMapMouseCursorLayerConfig,
  u_MapLayerNavToPointMarkerConfig;

{ TMainFormLayersConfig }

constructor TMainFormLayersConfig.Create;
begin
  inherited Create;
  FMainMapLayerConfig := TMainMapLayerConfig.Create;
  Add(FMainMapLayerConfig, TConfigSaveLoadStrategyBasicProviderSubItem.Create('MainLayer'));
  FMapLayerGridsConfig := TMapLayerGridsConfig.Create;
  Add(FMapLayerGridsConfig, TConfigSaveLoadStrategyBasicUseProvider.Create);
  FStatBar := TStatBarConfig.Create;
  Add(FStatBar, TConfigSaveLoadStrategyBasicProviderSubItem.Create('StatusBar'));
  FSunCalcConfig := TSunCalcConfig.Create;
  Add(FSunCalcConfig, TConfigSaveLoadStrategyBasicProviderSubItem.Create('SunCalc'));
  FGPSMarker := TMapLayerGPSMarkerConfig.Create;
  Add(FGPSMarker, TConfigSaveLoadStrategyBasicProviderSubItem.Create('GPSMarker'));
  FGPSTrackConfig := TMapLayerGPSTrackConfig.Create;
  Add(FGPSTrackConfig, TConfigSaveLoadStrategyBasicProviderSubItem.Create('GPSTrack'));
  FNavToPointMarkerConfig := TMapLayerNavToPointMarkerConfig.Create;
  Add(FNavToPointMarkerConfig, TConfigSaveLoadStrategyBasicProviderSubItem.Create('NavToPointMarker'));
  FMarksLayerConfig := TMarksLayerConfig.Create;
  Add(FMarksLayerConfig, TConfigSaveLoadStrategyBasicProviderSubItem.Create('MarksShow'));
  FKmlLayerConfig := TKmlLayerConfig.Create;
  Add(FKmlLayerConfig, TConfigSaveLoadStrategyBasicProviderSubItem.Create('WikiLayer'));
  FMiniMapLayerConfig := TMiniMapLayerConfig.Create;
  Add(FMiniMapLayerConfig, TConfigSaveLoadStrategyBasicProviderSubItem.Create('MiniMap'));
  FCenterScaleConfig := TCenterScaleConfig.Create;
  Add(FCenterScaleConfig, TConfigSaveLoadStrategyBasicProviderSubItem.Create('CenterScale'));
  FScaleLineConfig := TScaleLineConfig.Create;
  Add(FScaleLineConfig, TConfigSaveLoadStrategyBasicProviderSubItem.Create('ScaleLine'));
  FLastSelectionLayerConfig := TLastSelectionLayerConfig.Create;
  Add(FLastSelectionLayerConfig, TConfigSaveLoadStrategyBasicProviderSubItem.Create('LastSelection'));
  FMergePolygonsResultLayerConfig := TMergePolygonsResultLayerConfig.Create;
  Add(FMergePolygonsResultLayerConfig, TConfigSaveLoadStrategyBasicProviderSubItem.Create('MergePolygonsResult'));
  FCalcLineLayerConfig := TCalcLineLayerConfig.Create;
  Add(FCalcLineLayerConfig, TConfigSaveLoadStrategyBasicProviderSubItem.Create('CalcLine'));
  FCalcCircleLayerConfig := TCalcCircleLayerConfig.Create;
  Add(FCalcCircleLayerConfig, TConfigSaveLoadStrategyBasicProviderSubItem.Create('CalcCircle'));
  FSelectionRectLayerConfig := TSelectionRectLayerConfig.Create;
  Add(FSelectionRectLayerConfig, TConfigSaveLoadStrategyBasicProviderSubItem.Create('SelectionRect'));
  FSelectionPolygonLayerConfig := TSelectionPolygonLayerConfig.Create;
  Add(FSelectionPolygonLayerConfig, TConfigSaveLoadStrategyBasicProviderSubItem.Create('SelectionPolygon'));
  FSelectionPolylineLayerConfig := TSelectionPolylineLayerConfig.Create;
  Add(FSelectionPolylineLayerConfig, TConfigSaveLoadStrategyBasicProviderSubItem.Create('SelectionPolyline'));
  FMarkPolygonLayerConfig := TMarkPolygonLayerConfig.Create;
  Add(FMarkPolygonLayerConfig, TConfigSaveLoadStrategyBasicProviderSubItem.Create('EditMarkPolygon'));
  FMarkPolyLineLayerConfig := TMarkPolyLineLayerConfig.Create;
  Add(FMarkPolyLineLayerConfig, TConfigSaveLoadStrategyBasicProviderSubItem.Create('EditMarkPolyLine'));
  FFillingMapLayerConfig := TFillingMapLayerConfig.Create;
  Add(FFillingMapLayerConfig, TConfigSaveLoadStrategyBasicProviderSubItem.Create('FillingLayer'));
  FGotoLayerConfig := TGotoLayerConfig.Create;
  Add(FGotoLayerConfig, TConfigSaveLoadStrategyBasicProviderSubItem.Create('GotoMarker'));
  FFullMapMouseCursorLayerConfig := TFullMapMouseCursorLayerConfig.Create;
  Add(FFullMapMouseCursorLayerConfig, TConfigSaveLoadStrategyBasicProviderSubItem.Create('FullMapMouseCursor'));
end;

function TMainFormLayersConfig.GetCalcCircleLayerConfig: ICalcCircleLayerConfig;
begin
  Result := FCalcCircleLayerConfig;
end;

function TMainFormLayersConfig.GetCalcLineLayerConfig: ICalcLineLayerConfig;
begin
  Result := FCalcLineLayerConfig;
end;

function TMainFormLayersConfig.GetCenterScaleConfig: ICenterScaleConfig;
begin
  Result := FCenterScaleConfig;
end;

function TMainFormLayersConfig.GetFillingMapLayerConfig: IFillingMapLayerConfig;
begin
  Result := FFillingMapLayerConfig;
end;

function TMainFormLayersConfig.GetFullMapMouseCursorLayerConfig: IFullMapMouseCursorLayerConfig;
begin
  Result := FFullMapMouseCursorLayerConfig;
end;

function TMainFormLayersConfig.GetGotoLayerConfig: IGotoLayerConfig;
begin
  Result := FGotoLayerConfig;
end;

function TMainFormLayersConfig.GetGPSMarker: IMapLayerGPSMarkerConfig;
begin
  Result := FGPSMarker;
end;

function TMainFormLayersConfig.GetGPSTrackConfig: IMapLayerGPSTrackConfig;
begin
  Result := FGPSTrackConfig;
end;

function TMainFormLayersConfig.GetKmlLayerConfig: IKmlLayerConfig;
begin
  Result := FKmlLayerConfig;
end;

function TMainFormLayersConfig.GetLastSelectionLayerConfig: ILastSelectionLayerConfig;
begin
  Result := FLastSelectionLayerConfig;
end;

function TMainFormLayersConfig.GetMergePolygonsResultLayerConfig: IMergePolygonsResultLayerConfig;
begin
  Result := FMergePolygonsResultLayerConfig;
end;

function TMainFormLayersConfig.GetMainMapLayerConfig: IMainMapLayerConfig;
begin
  Result := FMainMapLayerConfig;
end;

function TMainFormLayersConfig.GetMapLayerGridsConfig: IMapLayerGridsConfig;
begin
  Result := FMapLayerGridsConfig;
end;

function TMainFormLayersConfig.GetMarkPolygonLayerConfig: IMarkPolygonLayerConfig;
begin
  Result := FMarkPolygonLayerConfig;
end;

function TMainFormLayersConfig.GetMarkPolyLineLayerConfig: IMarkPolyLineLayerConfig;
begin
  Result := FMarkPolyLineLayerConfig;
end;

function TMainFormLayersConfig.GetMarksLayerConfig: IMarksLayerConfig;
begin
  Result := FMarksLayerConfig;
end;

function TMainFormLayersConfig.GetMiniMapLayerConfig: IMiniMapLayerConfig;
begin
  Result := FMiniMapLayerConfig;
end;

function TMainFormLayersConfig.GetNavToPointMarkerConfig: IMapLayerNavToPointMarkerConfig;
begin
  Result := FNavToPointMarkerConfig;
end;

function TMainFormLayersConfig.GetScaleLineConfig: IScaleLineConfig;
begin
  Result := FScaleLineConfig;
end;

function TMainFormLayersConfig.GetSelectionPolygonLayerConfig: ISelectionPolygonLayerConfig;
begin
  Result := FSelectionPolygonLayerConfig;
end;

function TMainFormLayersConfig.GetSelectionPolylineLayerConfig: ISelectionPolylineLayerConfig;
begin
  Result := FSelectionPolylineLayerConfig;
end;

function TMainFormLayersConfig.GetSelectionRectLayerConfig: ISelectionRectLayerConfig;
begin
  Result := FSelectionRectLayerConfig;
end;

function TMainFormLayersConfig.GetStatBar: IStatBarConfig;
begin
  Result := FStatBar;
end;

function TMainFormLayersConfig.GetSunCalcConfig: ISunCalcConfig;
begin
  Result := FSunCalcConfig;
end;

end.

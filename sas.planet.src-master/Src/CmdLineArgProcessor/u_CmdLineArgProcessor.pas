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

unit u_CmdLineArgProcessor;

interface

uses
  Types,
  Classes,
  i_MarkSystem,
  i_MapViewGoto,
  i_RegionProcess,
  i_ViewPortState,
  i_MapTypeSet,
  i_MainFormConfig,
  i_ProjectionSet,
  i_ProjectionSetChangeable,
  i_GeometryLonLatFactory,
  i_AppearanceOfMarkFactory,
  i_VectorItemTreeImporterList,
  i_CmdLineArgProcessor,
  u_BaseInterfacedObject;

type
  TCmdLineArgProcessor = class(TBaseInterfacedObject, ICmdLineArgProcessor)
  private
    FMarkSystem: IMarkSystem;
    FMapGoTo: IMapViewGoto;
    FProjectionSet: IProjectionSetChangeable;
    FViewPortState: IViewPortState;
    FAllMapsSet: IMapTypeSet;
    FMainFormConfig: IMainFormConfig;
    FGeometryLonLatFactory: IGeometryLonLatFactory;
    FAppearanceOfMarkFactory: IAppearanceOfMarkFactory;
    FImporterList: IVectorItemTreeImporterListChangeable;
    function ProcessInternal(
      const AList: TStringList;
      const ARegionProcess: IRegionProcessFromFile
    ): Integer;
    function IsArgsInUTF8(const AArgs: AnsiString): Boolean;
  private
    function Process(
      const ARegionProcess: IRegionProcessFromFile = nil
    ): Integer; overload;
    function Process(
      const AArgs: AnsiString;
      const ARegionProcess: IRegionProcessFromFile = nil
    ): Integer; overload;
    function GetArguments: string;
    function GetErrorFromCode(const ACode: Integer): string;
  public
    constructor Create(
      const AMarkSystem: IMarkSystem;
      const AMapGoto: IMapViewGoto;
      const AProjectionSet: IProjectionSetChangeable;
      const AViewPortState: IViewPortState;
      const AAllMapsSet: IMapTypeSet;
      const AMainFormConfig: IMainFormConfig;
      const AGeometryLonLatFactory: IGeometryLonLatFactory;
      const AAppearanceOfMarkFactory: IAppearanceOfMarkFactory;
      const AImporterList: IVectorItemTreeImporterListChangeable
    );
  end;

implementation

uses
  SysUtils,
  StrUtils,
  {$IFNDef UNICODE}
  Compatibility,
  {$ENDIF}
  ArgumentParser,
  t_GeoTypes,
  i_StringListStatic,
  i_MapType,
  u_StringListStatic,
  u_CmdLineArgProcessorAPI,
  u_CmdLineArgProcessorHelpers;

{ TCmdLineArgProcessor }

constructor TCmdLineArgProcessor.Create(
  const AMarkSystem: IMarkSystem;
  const AMapGoto: IMapViewGoto;
  const AProjectionSet: IProjectionSetChangeable;
  const AViewPortState: IViewPortState;
  const AAllMapsSet: IMapTypeSet;
  const AMainFormConfig: IMainFormConfig;
  const AGeometryLonLatFactory: IGeometryLonLatFactory;
  const AAppearanceOfMarkFactory: IAppearanceOfMarkFactory;
  const AImporterList: IVectorItemTreeImporterListChangeable
);
begin
  inherited Create;
  FMarkSystem := AMarkSystem;
  FMapGoTo := AMapGoto;
  FProjectionSet := AProjectionSet;
  FViewPortState := AViewPortState;
  FAllMapsSet := AAllMapsSet;
  FMainFormConfig := AMainFormConfig;
  FGeometryLonLatFactory := AGeometryLonLatFactory;
  FAppearanceOfMarkFactory := AAppearanceOfMarkFactory;
  FImporterList := AImporterList;
end;

function TCmdLineArgProcessor.GetArguments: string;
var
  VList: TStringList;
begin
  VList := GetParamStrAsList(False);
  try
    Result := VList.Text;
  finally
    VList.Free;
  end;
end;

function TCmdLineArgProcessor.Process(
  const ARegionProcess: IRegionProcessFromFile
): Integer;
var
  VList: TStringList;
begin
  VList := GetParamStrAsList(False);
  try
    Result := ProcessInternal(VList, ARegionProcess);
  finally
    VList.Free;
  end;
end;

function TCmdLineArgProcessor.IsArgsInUTF8(const AArgs: AnsiString): Boolean;
const
  cUTF8 = '--utf8';
var
  I: Integer;
  VList: TStringList;
begin
  Result := False;
  VList := GetArgsAsList(string(AArgs));
  try
    for I := 0 to VList.Count - 1 do begin
      if SameText(VList.Strings[I], cUTF8) then begin
        Result := True;
        Break;
      end;
    end;
  finally
    VList.Free;
  end;
end;

function TCmdLineArgProcessor.Process(
  const AArgs: AnsiString;
  const ARegionProcess: IRegionProcessFromFile
): Integer;
var
  VArgs: string;
  VList: TStringList;
begin
  if IsArgsInUTF8(AArgs) then begin
    VArgs := UTF8ToString(AArgs);
  end else begin
    VArgs := string(AArgs);
  end;
  VList := GetArgsAsList(VArgs);
  try
    Result := ProcessInternal(VList, ARegionProcess);
  finally
    VList.Free;
  end;
end;

function TCmdLineArgProcessor.ProcessInternal(
  const AList: TStringList;
  const ARegionProcess: IRegionProcessFromFile
): Integer;

var
  VGUID: TGUID;
  VZoom: Byte;
  VLonLat: TDoublePoint;
  VPoint: TPoint;
  VMap: IMapType;
  i: Integer;
  VStrValue: string;
  VFilesList: TStringList;
  VFiles: IStringListStatic;
  VParser: TArgumentParser;
  VParseResult: TParseResult;
  VProjectionSet: IProjectionSet;
  VStartSlsPaused: Boolean;

  function _GetProjectionSet: IProjectionSet;
  begin
    if not Assigned(VProjectionSet) then begin
      VProjectionSet := FProjectionSet.GetStatic;
    end;
    Result := VProjectionSet;
  end;

begin
  Result := cCmdLineArgProcessorOk;

  VParser := TArgumentParser.Create;
  try
    VParser.AddArgument('--map', saStore);              // --map={GUID}
    VParser.AddArgument('--zoom', saStore);             // --zoom={value}
    VParser.AddArgument('--move', saStore);             // --move=({lon},{lat})
    VParser.AddArgument('--move-xyz', saStore);         // --move-xyz=({x},{y},{z})
    VParser.AddArgument('--navigate', saStore);         // --navigate=({lon},{lat})
    VParser.AddArgument('--show-placemarks', saStore);  // --show-placemarks={0/1}
    VParser.AddArgument('--insert-placemark', saStore); // --insert-placemark="{name}";({lon},{lat});"{desc}"
    VParser.AddArgument('--sls-autostart', saBool);     // --sls-autostart

    VParseResult := VParser.ParseArgs(AList);
    try
      if VParseResult.HasArgument('map') then begin
        VStrValue := VParseResult.GetValue('map');
        if GetGUID(VStrValue, VGUID, Result) then begin
          VMap := FAllMapsSet.GetMapTypeByGUID(VGUID);
          if VMap <> nil then begin
            if VMap.Zmp.IsLayer then begin
              FMainFormConfig.MapLayersConfig.InvertLayerSelectionByGUID(VGUID);
            end else begin
              FMainFormConfig.MainMapConfig.MainMapGUID := VGUID;
            end;
          end else begin
            Result := Result or cCmdLineArgProcessorUnknownGUID;
          end;
        end;
      end;

      if VParseResult.HasArgument('zoom') then begin
        VStrValue := VParseResult.GetValue('zoom');
        if GetZoom(VStrValue, _GetProjectionSet, VZoom, Result) then begin
          FViewPortState.ChangeZoomWithFreezeAtCenter(VZoom);
        end;
      end;

      if VParseResult.HasArgument('move') then begin
        VStrValue := VParseResult.GetValue('move');
        if GetLonLat(AnsiString(VStrValue), _GetProjectionSet.Zooms[0].ProjectionType, VLonLat, Result) then begin
          FViewPortState.ChangeLonLat(VLonLat);
        end;
      end;

      if VParseResult.HasArgument('move-xyz') then begin
        VStrValue := VParseResult.GetValue('move-xyz');
        if GetXYZ(AnsiString(VStrValue), _GetProjectionSet, VPoint, VZoom, Result) then begin
          VLonLat := _GetProjectionSet.Zooms[VZoom].TilePos2LonLat(VPoint);
          FViewPortState.ChangeLonLatAndZoom(VZoom, VLonLat);
        end;
      end;

      if VParseResult.HasArgument('navigate') then begin
        VStrValue := VParseResult.GetValue('navigate');
        if GetLonLat(AnsiString(VStrValue), _GetProjectionSet.Zooms[0].ProjectionType, VLonLat, Result) then begin
          FMainFormConfig.NavToPoint.StartNavLonLat(VLonLat);
        end;
      end;

      if VParseResult.HasArgument('show-placemarks') then begin
        VStrValue := VParseResult.GetValue('show-placemarks');
        if VStrValue = '1' then begin
          FMainFormConfig.LayersConfig.MarksLayerConfig.MarksShowConfig.IsUseMarks := True;
        end else if VStrValue = '0' then begin
          FMainFormConfig.LayersConfig.MarksLayerConfig.MarksShowConfig.IsUseMarks := False;
        end else begin
          Result := Result or cCmdLineArgProcessorShowMarksParserError;
        end;
      end;

      if VParseResult.HasArgument('insert-placemark') then begin
        VStrValue := VParseResult.GetValue('insert-placemark');
        ProcessImportPlacemark(VStrValue, FMarkSystem, FGeometryLonLatFactory);
      end;

      VStartSlsPaused := not VParseResult.HasArgument('sls-autostart');

      // unnamed arguments -> files: sls/hlg/kml/gpx/sml etc.
      if VParseResult.Args.Count > 0 then begin
        VFilesList := TStringList.Create;
        try
          for i := 0 to VParseResult.Args.Count - 1 do begin
            VFilesList.Add(GetUnquotedStr(VParseResult.Args[i]));
          end;
          VFiles := TStringListStatic.CreateWithOwn(VFilesList);
        finally
          FreeAndNil(VFilesList);
        end;
        ProcessOpenFiles(
          VFiles,
          FMapGoTo,
          ARegionProcess,
          VStartSlsPaused,
          False, // import in silent mode
          nil,
          FMarkSystem,
          FImporterList,
          FAppearanceOfMarkFactory
        );
      end;

    finally
      VParseResult.Free;
    end;
  finally
    VParser.Free;
  end;
end;

function TCmdLineArgProcessor.GetErrorFromCode(const ACode: Integer): string;
begin
  Result := u_CmdLineArgProcessorAPI.GetErrorFromCode(ACode);
end;

end.

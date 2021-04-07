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

unit u_TerrainProviderList;

interface

uses
  SysUtils,
  ActiveX,
  i_GUIDSet,
  i_Notifier,
  i_InterfaceListStatic,
  i_ProjectionSetFactory,
  i_TerrainProviderList,
  i_TerrainProviderListElement,
  i_PathConfig,
  i_ProjConverter,
  u_BaseInterfacedObject;

type
  TTerrainProviderListBase = class(TBaseInterfacedObject, ITerrainProviderList)
  private
    FList: IGUIDInterfaceSet;
    FCS: IReadWriteSync;
    FAddNotifier: INotifierInternal;
  private
    function GetGUIDEnum: IEnumGUID;
    function Get(const AGUID: TGUID): ITerrainProviderListElement;
    function GetAddNotifier: INotifier;
    function GetSorted: IInterfaceListStatic;
  protected
    procedure Add(const AItem: ITerrainProviderListElement);
  public
    constructor Create;
  end;

  TTerrainProviderListSimple = class(TTerrainProviderListBase)
  private
    FProjConverterFactory: IProjConverterFactory;
    FTerrainDataPath: IPathConfig;
  private
    procedure LoadFromIni;
  public
    constructor Create(
      const AProjConverterFactory: IProjConverterFactory;
      const AProjectionSetFactory: IProjectionSetFactory;
      const ATerrainDataPath: IPathConfig;
      const AGECachePath: IPathConfig;
      const AGCCachePath: IPathConfig
    );
  end;

implementation

uses
  IniFiles,
  Classes,
  ExplorerSort,
  c_TerrainProviderGUID,
  c_ZeroGUID,
  i_ConfigDataProvider,
  i_StringListStatic,
  i_InterfaceListSimple,
  u_InterfaceListSimple,
  u_ConfigDataProviderByIniFile,
  u_ConfigProviderHelpers,
  u_TerrainProviderListElement,
  u_TerrainProviderByGoogleEarth,
  u_ExternalTerrainsProvider,
  u_Notifier,
  u_Synchronizer,
  u_GUIDInterfaceSet;

{ TTerrainProviderListSimple }

constructor TTerrainProviderListSimple.Create(
  const AProjConverterFactory: IProjConverterFactory;
  const AProjectionSetFactory: IProjectionSetFactory;
  const ATerrainDataPath: IPathConfig;
  const AGECachePath: IPathConfig;
  const AGCCachePath: IPathConfig
);
var
  VItem: ITerrainProviderListElement;
begin
  inherited Create;
  FTerrainDataPath := ATerrainDataPath;

  FProjConverterFactory := AProjConverterFactory;

  VItem :=
    TTerrainProviderListElement.Create(
      cTerrainProviderGoogleEarthGUID,
      'GoogleEarth',
      TTerrainProviderByGoogleEarth.Create(False, AProjectionSetFactory, AGECachePath)
    );
  Add(VItem);

  VItem :=
    TTerrainProviderListElement.Create(
      cTerrainProviderGeoCacherGUID,
      'GeoCacher',
      TTerrainProviderByGoogleEarth.Create(True, AProjectionSetFactory, AGCCachePath)
    );
  Add(VItem);

  // make external items
  LoadFromIni;
end;

procedure TTerrainProviderListSimple.LoadFromIni;
var
  VFileName: String;
  VIniFile: TIniFile;
  VTerrainConfig: IConfigDataProvider;
  VSectionData: IConfigDataProvider;
  VSections: IStringListStatic;
  VSection, VCaption: String;
  VGuid: TGUID;
  VItem: ITerrainProviderListElement;
  VProjInitString: AnsiString;
  VProjConverter: IProjConverter;
  i: Integer;
begin
  // check
  if (nil = FTerrainDataPath) then begin
    Exit;
  end;
  VFileName := FTerrainDataPath.FullPath + '\SASTerrain.ini';
  if (not FileExists(VFileName)) then begin
    Exit;
  end;

  // load
  VIniFile := TIniFile.Create(VFileName);
  try
    VTerrainConfig := TConfigDataProviderByIniFile.CreateWithOwn(VIniFile);
    VIniFile := nil;
    VSections := VTerrainConfig.ReadSubItemsList;
    if Assigned(VSections) and (0 < VSections.Count) then begin
      for i := 0 to VSections.Count - 1 do begin
        try
      // loop through terrains
          VSection := VSections.Items[i];
          VSectionData := VTerrainConfig.GetSubItem(VSection);

      // get guid
          VGuid := ReadGUID(VSectionData, 'GUID', CGUID_Zero);

      // get caption
          VCaption := VSectionData.ReadString('Caption', VSection);

      // get proj4 converter
          VProjInitString := VSectionData.ReadAnsiString('Proj', '');
          if (0 < Length(VProjInitString)) then begin
            VProjConverter := FProjConverterFactory.GetByInitString(VProjInitString);
          end else begin
        // no proj converter
            VProjConverter := nil;
          end;

      // make item
          VItem := TTerrainProviderListElement.Create(
            VGuid,
            VCaption,
            TTerrainProviderByExternal.Create(
              FTerrainDataPath.FullPath,
              VProjConverter,
              VSectionData
            )
          );

      // append to list
          Add(VItem);
        except
        end;
      end;
    end;
  finally
    VIniFile.Free;
  end;
end;

{ TTerrainProviderListBase }

constructor TTerrainProviderListBase.Create;
begin
  inherited Create;
  FCS := GSync.SyncStdRecursive.Make(Self.ClassName);
  FList := TGUIDInterfaceSet.Create(False);
  FAddNotifier :=
    TNotifierBase.Create(
      GSync.SyncVariable.Make(Self.ClassName + 'Notifier')
    );
end;

procedure TTerrainProviderListBase.Add(const AItem: ITerrainProviderListElement);
begin
  FCS.BeginWrite;
  try
    FList.Add(AItem.GetGUID, AItem);
  finally
    FCS.EndWrite;
  end;
  FAddNotifier.Notify(nil);
end;

function TTerrainProviderListBase.Get(const AGUID: TGUID): ITerrainProviderListElement;
begin
  FCS.BeginRead;
  try
    Result := ITerrainProviderListElement(FList.GetByGUID(AGUID));
  finally
    FCS.EndRead;
  end;
end;

function TTerrainProviderListBase.GetAddNotifier: INotifier;
begin
  Result := FAddNotifier;
end;

function TTerrainProviderListBase.GetGUIDEnum: IEnumGUID;
begin
  FCS.BeginRead;
  try
    Result := FList.GetGUIDEnum;
  finally
    FCS.EndRead;
  end;
end;

function TTerrainProviderListBase.GetSorted: IInterfaceListStatic;

  function CompareByCaption(const A, B: IInterface): Integer;
  begin
    Result := CompareStringOrdinal(
      ITerrainProviderListElement(A).Caption,
      ITerrainProviderListElement(B).Caption
    );
  end;

  procedure QuickSort(const ASortList: IInterfaceListSimple; L, R: Integer);
  var
    I, J: Integer;
    T: IInterface;
  begin
    repeat
      I := L;
      J := R;
      T := ASortList.Items[(L + R) shr 1];
      repeat
        while CompareByCaption(ASortList.Items[I], T) < 0 do begin
          Inc(I);
        end;
        while CompareByCaption(ASortList.Items[J], T) > 0 do begin
          Dec(J);
        end;
        if I <= J then begin
          ASortList.Exchange(J, I);
          Inc(I);
          Dec(J);
        end;
      until I > J;
      if L < J then begin
        QuickSort(ASortList, L, J);
      end;
      L := I;
    until I >= R;
  end;

var
  I: Integer;
  VList: IInterfaceListSimple;
begin
  // fill
  VList := TInterfaceListSimple.Create;
  for I := 0 to FList.Count - 1 do begin
    VList.Add(FList.Items[I]);
  end;

  // sort
  I := VList.Count;
  if I > 1 then begin
    QuickSort(VList, 0, I - 1);
  end;

  Result := VList.MakeStaticAndClear;
end;

end.

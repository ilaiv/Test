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

unit u_TileStorageTypeBase;

interface

uses
  i_ProjectionSet,
  i_ContentTypeInfo,
  i_TileStorageAbilities,
  i_ConfigDataProvider,
  i_MapVersionFactory,
  i_NotifierTilePyramidUpdate,
  i_TileInfoBasicMemCache,
  i_TileStorageTypeConfig,
  i_TileStorage,
  i_TileStorageType,
  u_BaseInterfacedObject;

type
  TTileStorageTypeBase = class(TBaseInterfacedObject, ITileStorageType)
  private
    FAbilities: ITileStorageTypeAbilities;
    FMapVersionFactory: IMapVersionFactory;
    FConfig: ITileStorageTypeConfig;
    function GetStorageAbilitiesByConfig(
      const AForceAbilities: ITileStorageAbilities;
      const AStorageConfigData: IConfigDataProvider
    ): ITileStorageAbilities;
  protected
    function BuildStorageInternal(
      const AStorageConfigData: IConfigDataProvider;
      const AForceAbilities: ITileStorageAbilities;
      const AProjectionSet: IProjectionSet;
      const AMainContentType: IContentTypeInfoBasic;
      const ATileNotifier: INotifierTilePyramidUpdateInternal;
      const APath: string;
      const ACacheTileInfo: ITileInfoBasicMemCache
    ): ITileStorage; virtual; abstract;
  protected
    function GetAbilities: ITileStorageTypeAbilities;
    function GetConfig: ITileStorageTypeConfig;
    function GetMapVersionFactory: IMapVersionFactory;
    function BuildStorage(
      const AForceAbilities: ITileStorageAbilities;
      const AProjectionSet: IProjectionSet;
      const AMainContentType: IContentTypeInfoBasic;
      const ATileNotifier: INotifierTilePyramidUpdateInternal;
      const APath: string;
      const ACacheTileInfo: ITileInfoBasicMemCache
    ): ITileStorage;
  public
    constructor Create(
      const AAbilities: ITileStorageTypeAbilities;
      const AMapVersionFactory: IMapVersionFactory;
      const AConfig: ITileStorageTypeConfig
    );
  end;

implementation

uses
  SysUtils,
  IniFiles,
  {$IFNDef UNICODE}
  CompatibilityIniFiles,
  {$ENDIF}
  u_ConfigDataProviderByIniFile,
  u_TileStorageAbilities;

const
  CStorageConfFileName = 'StorageConfig.ini';

{ TTileStorageTypeBase }

function TTileStorageTypeBase.GetStorageAbilitiesByConfig(
  const AForceAbilities: ITileStorageAbilities;
  const AStorageConfigData: IConfigDataProvider
): ITileStorageAbilities;
var
  VIsReadOnly: Boolean;
  VAllowRead: Boolean;
  VAllowScan: Boolean;
  VAllowAdd: Boolean;
  VAllowDelete: Boolean;
  VAllowReplace: Boolean;
  VStorageConfigData: IConfigDataProvider;
begin
  Result := FAbilities.BaseStorageAbilities;
  if Assigned(AStorageConfigData) then begin
    VStorageConfigData := AStorageConfigData.GetSubItem('Common');
    if Assigned(VStorageConfigData) then begin
      VIsReadOnly := VStorageConfigData.ReadBool('IsReadOnly', Result.IsReadOnly);
      VAllowRead := VStorageConfigData.ReadBool('AllowRead', Result.AllowRead);
      VAllowScan := VStorageConfigData.ReadBool('AllowScan', Result.AllowScan);
      VAllowAdd := VStorageConfigData.ReadBool('AllowAdd', Result.AllowAdd);
      VAllowDelete := VStorageConfigData.ReadBool('AllowDelete', Result.AllowDelete);
      VAllowReplace := VStorageConfigData.ReadBool('AllowReplace', Result.AllowReplace);
      Result :=
        TTileStorageAbilities.Create(
          Result.AllowRead and VAllowRead,
          Result.AllowScan and VAllowScan,
          Result.AllowAdd and VAllowAdd and not VIsReadOnly,
          Result.AllowDelete and VAllowDelete and not VIsReadOnly,
          Result.AllowReplace and VAllowReplace and not VIsReadOnly
        );
    end;
  end;
  if Assigned(AForceAbilities) then begin
    Result :=
      TTileStorageAbilities.Create(
        Result.AllowRead and AForceAbilities.AllowRead,
        Result.AllowScan and AForceAbilities.AllowScan,
        Result.AllowAdd and AForceAbilities.AllowAdd,
        Result.AllowDelete and AForceAbilities.AllowDelete,
        Result.AllowReplace and AForceAbilities.AllowReplace
      );
  end;
end;

function TTileStorageTypeBase.BuildStorage(
  const AForceAbilities: ITileStorageAbilities;
  const AProjectionSet: IProjectionSet;
  const AMainContentType: IContentTypeInfoBasic;
  const ATileNotifier: INotifierTilePyramidUpdateInternal;
  const APath: string;
  const ACacheTileInfo: ITileInfoBasicMemCache
): ITileStorage;
var
  VAbilities: ITileStorageAbilities;
  VConfigFileName: string;
  VConfigData: IConfigDataProvider;
  VIniFile: TMemIniFile;
begin
  VConfigFileName := '';
  case GetAbilities.StorageClass of
    tstcOneFile: begin
      VConfigFileName := APath + '.' + CStorageConfFileName;
    end;
    tstcFolder, tstcInSeparateFiles: begin
      VConfigFileName := APath + CStorageConfFileName;
    end;

  end;
  VConfigData := nil;
  if (VConfigFileName <> '') and FileExists(VConfigFileName) then begin
    VIniFile := TMemIniFile.Create(VConfigFileName);
    try
      VConfigData := TConfigDataProviderByIniFile.CreateWithOwn(VIniFile);
      VIniFile := nil;
    finally
      VIniFile.Free;
    end;
  end;
  VAbilities := GetStorageAbilitiesByConfig(AForceAbilities, VConfigData);
  Result :=
    BuildStorageInternal(
      VConfigData,
      VAbilities,
      AProjectionSet,
      AMainContentType,
      ATileNotifier,
      APath,
      ACacheTileInfo
    );
end;

constructor TTileStorageTypeBase.Create(
  const AAbilities: ITileStorageTypeAbilities;
  const AMapVersionFactory: IMapVersionFactory;
  const AConfig: ITileStorageTypeConfig
);
begin
  Assert(Assigned(AAbilities));
  Assert(Assigned(AMapVersionFactory));
  Assert(Assigned(AConfig));
  inherited Create;
  FAbilities := AAbilities;
  FMapVersionFactory := AMapVersionFactory;
  FConfig := AConfig;
end;

function TTileStorageTypeBase.GetConfig: ITileStorageTypeConfig;
begin
  Result := FConfig;
end;

function TTileStorageTypeBase.GetAbilities: ITileStorageTypeAbilities;
begin
  Result := FAbilities;
end;

function TTileStorageTypeBase.GetMapVersionFactory: IMapVersionFactory;
begin
  Result := FMapVersionFactory;
end;

end.

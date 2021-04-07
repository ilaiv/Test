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

unit u_ZmpInfo;

interface

uses
  SysUtils,
  Classes,
  i_Bitmap32Static,
  i_ProjectionSet,
  i_ConfigDataProvider,
  i_LanguageListStatic,
  i_BinaryDataListStatic,
  i_Bitmap32BufferFactory,
  i_ContentTypeSubst,
  i_AppearanceOfMarkFactory,
  i_MarkPicture,
  i_TileDownloadRequestBuilderConfig,
  i_TileDownloaderConfig,
  i_TilePostDownloadCropConfig,
  i_LanguageManager,
  i_StringByLanguage,
  i_ProjectionSetFactory,
  i_ContentTypeManager,
  i_MapAbilitiesConfig,
  i_SimpleTileStorageConfig,
  i_ImportConfig,
  i_ZmpConfig,
  i_ZmpInfo,
  u_BaseInterfacedObject;

type
  TZmpInfoGUI = class(TBaseInterfacedObject, IZmpInfoGUI)
  private
    FGUID: TGUID;
    FName: IStringByLanguage;
    FParentSubMenu: IStringByLanguage;

    FInfoUrl: IStringByLanguage;

    FSortIndex: Integer;
    FBmp18: IBitmap32Static;
    FBmp24: IBitmap32Static;
    FHotKey: TShortCut;
    FSeparator: Boolean;
    FEnabled: Boolean;
  private
    procedure LoadConfig(
      const ALangList: ILanguageListStatic;
      const AContentTypeManager: IContentTypeManager;
      const AConfig: IConfigDataProvider;
      const AConfigIni: IConfigDataProvider;
      const AConfigIniParams: IConfigDataProvider;
      const ABitmapFactory: IBitmap32StaticFactory;
      Apnum: Integer
    );
    function CreateDefaultIcon(
      const ABitmapFactory: IBitmap32StaticFactory;
      Apnum: Integer
    ): IBitmap32Static;
    procedure LoadIcons(
      const AContentTypeManager: IContentTypeManager;
      const AConfig: IConfigDataProvider;
      const AConfigIniParams: IConfigDataProvider;
      const ABitmapFactory: IBitmap32StaticFactory;
      Apnum: Integer
    );
    procedure LoadUIParams(
      const ALangList: ILanguageListStatic;
      const AConfig: IConfigDataProvider;
      Apnum: Integer
    );
    procedure LoadInfo(
      const ALangList: ILanguageListStatic;
      const AConfig: IConfigDataProvider
    );
  private
    function GetName: IStringByLanguage;
    function GetSortIndex: Integer;
    function GetInfoUrl: IStringByLanguage;
    function GetBmp18: IBitmap32Static;
    function GetBmp24: IBitmap32Static;
    function GetHotKey: TShortCut;
    function GetSeparator: Boolean;
    function GetParentSubMenu: IStringByLanguage;
    function GetEnabled: Boolean;
  public
    constructor Create(
      const AGUID: TGUID;
      const ALanguageManager: ILanguageManager;
      const AContentTypeManager: IContentTypeManager;
      const ABitmapFactory: IBitmap32StaticFactory;
      const AConfig: IConfigDataProvider;
      const AConfigIni: IConfigDataProvider;
      const AConfigIniParams: IConfigDataProvider;
      Apnum: Integer
    );
  end;

  TZmpInfo = class(TBaseInterfacedObject, IZmpInfo)
  private
    FGUID: TGUID;
    FIsLayer: Boolean;
    FLayerZOrder: Integer;
    FLicense: IStringByLanguage;
    FFileName: string;
    FVersion: string;
    FTileDownloadRequestBuilderConfig: ITileDownloadRequestBuilderConfigStatic;
    FTileDownloaderConfig: ITileDownloaderConfigStatic;
    FTilePostDownloadCropConfig: ITilePostDownloadCropConfigStatic;
    FContentTypeSubst: IContentTypeSubst;
    FProjectionSet: IProjectionSet;
    FViewProjectionSet: IProjectionSet;
    FGUI: IZmpInfoGUI;
    FAbilities: IMapAbilitiesConfigStatic;
    FPointParams: IImportPointParams;
    FLineParams: IImportLineParams;
    FPolyParams: IImportPolyParams;
    FEmptyTileSamples: IBinaryDataListStatic;
    FBanTileSamples: IBinaryDataListStatic;
    FStorageConfig: ISimpleTileStorageConfigStatic;

    FZmpConfig: IZmpConfig;
    FConfig: IConfigDataProvider;
    FConfigIni: IConfigDataProvider;
    FConfigIniParams: IConfigDataProvider;
  private
    procedure LoadConfig(
      const AProjectionSetFactory: IProjectionSetFactory;
      const AAppearanceOfMarkFactory: IAppearanceOfMarkFactory;
      const AMarkPictureList: IMarkPictureList;
      const ALanguageManager: ILanguageManager
    );
    procedure LoadVectorAppearanceConfig(
      const AAppearanceOfMarkFactory: IAppearanceOfMarkFactory;
      const AMarkPictureList: IMarkPictureList;
      const AConfig: IConfigDataProvider
    );
    procedure LoadCropConfig(const AConfig: IConfigDataProvider);
    procedure LoadAbilities(const AConfig: IConfigDataProvider);
    procedure LoadStorageConfig(const AConfig: IConfigDataProvider);
    function LoadGUID(const AConfig: IConfigDataProvider): TGUID;
    procedure LoadVersion(
      const AConfig: IConfigDataProvider
    );
    function GetBinaryListByConfig(const AConfig: IConfigDataProvider): IBinaryDataListStatic;
    procedure LoadSamples(const AConfig: IConfigDataProvider);
    procedure LoadProjectionInfo(
      const AConfig: IConfigDataProvider;
      const AProjectionSetFactory: IProjectionSetFactory
    );
    procedure LoadTileRequestBuilderConfig(
      const AConfig: IConfigDataProvider
    );
    procedure LoadTileDownloaderConfig(const AConfig: IConfigDataProvider);
  private
    { IZmpInfo }
    function GetGUID: TGUID;
    function GetIsLayer: Boolean;
    function GetGUI: IZmpInfoGUI;
    function GetLayerZOrder: Integer;
    function GetLicense: IStringByLanguage;
    function GetFileName: string;
    function GetVersion: string;
    function GetTileDownloadRequestBuilderConfig: ITileDownloadRequestBuilderConfigStatic;
    function GetTileDownloaderConfig: ITileDownloaderConfigStatic;
    function GetTilePostDownloadCropConfig: ITilePostDownloadCropConfigStatic;
    function GetContentTypeSubst: IContentTypeSubst;
    function GetProjectionSet: IProjectionSet;
    function GetViewProjectionSet: IProjectionSet;
    function GetAbilities: IMapAbilitiesConfigStatic;
    function GetPointParams: IImportPointParams;
    function GetLineParams: IImportLineParams;
    function GetPolyParams: IImportPolyParams;
    function GetEmptyTileSamples: IBinaryDataListStatic;
    function GetBanTileSamples: IBinaryDataListStatic;
    function GetStorageConfig: ISimpleTileStorageConfigStatic;
    function GetDataProvider: IConfigDataProvider;
  public
    constructor Create(
      const AZmpConfig: IZmpConfig;
      const ALanguageManager: ILanguageManager;
      const AProjectionSetFactory: IProjectionSetFactory;
      const AContentTypeManager: IContentTypeManager;
      const AAppearanceOfMarkFactory: IAppearanceOfMarkFactory;
      const AMarkPictureList: IMarkPictureList;
      const ABitmapFactory: IBitmap32StaticFactory;
      const AFileName: string;
      const AConfig: IConfigDataProvider;
      Apnum: Integer
    );
  end;

  EZmpError = class(Exception);
  EZmpIniNotFound = class(EZmpError);
  EZmpParamsNotFound = class(EZmpError);
  EZmpGUIDError = class(EZmpError);

implementation

uses
  Types,
  ALString,
  GR32,
  gnugettext,
  c_ZeroGUID,
  i_BinaryData,
  i_StringListStatic,
  i_BitmapTileSaveLoad,
  i_Appearance,
  i_TileStorageAbilities,
  u_BinaryDataListStatic,
  u_StringByLanguageWithStaticList,
  u_TileDownloadRequestBuilderConfig,
  u_TileDownloaderConfigStatic,
  u_TilePostDownloadCropConfigStatic,
  u_ContentTypeSubstByList,
  u_MapAbilitiesConfigStatic,
  u_TileStorageAbilities,
  u_ImportConfig,
  u_ConfigProviderHelpers,
  u_SimpleTileStorageConfigStatic,
  u_ResStrings;

// common subroutine
function InternalMakeStringListByLanguage(
  const ALangList: ILanguageListStatic;
  const AConfig: IConfigDataProvider;
  const AParamName: String;
  const ADefValue: String
): TStringList;
var
  VDefValue: string;
  i: Integer;
  VLanguageCode: string;
  VValue: string;
begin
  VDefValue := AConfig.ReadString(AParamName, ADefValue);
  Result := TStringList.Create;
  try
    for i := 0 to ALangList.Count - 1 do begin
      VValue := VDefValue;
      VLanguageCode := ALangList.Code[i];
      VValue := AConfig.ReadString(AParamName + '_' + VLanguageCode, VDefValue);
      Result.Add(VValue);
    end;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function InternalMakeStringByLanguage(
  const ALangList: ILanguageListStatic;
  const AConfig: IConfigDataProvider;
  const AParamName: String;
  const ADefValue: String
): TStringByLanguageWithStaticList;
var
  VValueList: TStringList;
begin
  VValueList := InternalMakeStringListByLanguage(ALangList, AConfig, AParamName, ADefValue);
  try
    Result := TStringByLanguageWithStaticList.Create(VValueList);
  finally
    VValueList.Free;
  end;
end;

{ TZmpInfoGUI }

constructor TZmpInfoGUI.Create(
  const AGUID: TGUID;
  const ALanguageManager: ILanguageManager;
  const AContentTypeManager: IContentTypeManager;
  const ABitmapFactory: IBitmap32StaticFactory;
  const AConfig: IConfigDataProvider;
  const AConfigIni: IConfigDataProvider;
  const AConfigIniParams: IConfigDataProvider;
  Apnum: Integer
);
var
  VLangList: ILanguageListStatic;
begin
  inherited Create;
  FGUID := AGUID;
  VLangList := ALanguageManager.LanguageList;
  LoadConfig(
    VLangList,
    AContentTypeManager,
    AConfig,
    AConfigIni,
    AConfigIniParams,
    ABitmapFactory,
    Apnum
  );
end;

function TZmpInfoGUI.CreateDefaultIcon(
  const ABitmapFactory: IBitmap32StaticFactory;
  Apnum: Integer
): IBitmap32Static;
var
  VBitmap: TBitmap32;
  VNameDef: string;
  VTextSize: TSize;
  VPos: TPoint;
begin
  VBitmap := TBitmap32.Create;
  try
    VNameDef := copy(IntToStr(Apnum), 1, 2);
    VBitmap.SetSize(32, 32);
    VBitmap.Clear(clLightGray32);
    VTextSize := VBitmap.TextExtent(VNameDef);
    VPos.X := (VBitmap.Width - VTextSize.cx) div 2;
    VPos.Y := (VBitmap.Height - VTextSize.cy) div 2;
    VBitmap.RenderText(VPos.X, VPos.Y, VNameDef, 2, clBlack32);
    Result :=
      ABitmapFactory.Build(
        Types.Point(VBitmap.Width, VBitmap.Height),
        VBitmap.Bits
      )
  finally
    VBitmap.Free;
  end;
end;

function TZmpInfoGUI.GetBmp18: IBitmap32Static;
begin
  Result := FBmp18;
end;

function TZmpInfoGUI.GetBmp24: IBitmap32Static;
begin
  Result := FBmp24;
end;

function TZmpInfoGUI.GetEnabled: Boolean;
begin
  Result := FEnabled;
end;

function TZmpInfoGUI.GetHotKey: TShortCut;
begin
  Result := FHotKey;
end;

function TZmpInfoGUI.GetInfoUrl: IStringByLanguage;
begin
  Result := FInfoUrl;
end;

function TZmpInfoGUI.GetName: IStringByLanguage;
begin
  Result := FName;
end;

function TZmpInfoGUI.GetParentSubMenu: IStringByLanguage;
begin
  Result := FParentSubMenu;
end;

function TZmpInfoGUI.GetSeparator: Boolean;
begin
  Result := FSeparator;
end;

function TZmpInfoGUI.GetSortIndex: Integer;
begin
  Result := FSortIndex;
end;

procedure TZmpInfoGUI.LoadConfig(
  const ALangList: ILanguageListStatic;
  const AContentTypeManager: IContentTypeManager;
  const AConfig: IConfigDataProvider;
  const AConfigIni: IConfigDataProvider;
  const AConfigIniParams: IConfigDataProvider;
  const ABitmapFactory: IBitmap32StaticFactory;
  Apnum: Integer
);
begin
  LoadUIParams(ALangList, AConfigIniParams, Apnum);
  LoadIcons(AContentTypeManager, AConfig, AConfigIniParams, ABitmapFactory, Apnum);
  LoadInfo(ALangList, AConfig);
end;

function UpdateBMPTransp(
  const ABitmapFactory: IBitmap32StaticFactory;
  AMaskColor: TColor32;
  const ABitmap: IBitmap32Static
): IBitmap32Static;
var
  VBuffer: IBitmap32Buffer;
  VSourceLine: PColor32Array;
  VTargetLine: PColor32Array;
  i: Integer;
  VSize: TPoint;
begin
  Result := nil;
  if ABitmap <> nil then begin
    VSize := ABitmap.Size;
    VBuffer := ABitmapFactory.BufferFactory.BuildEmpty(VSize);
    if VBuffer <> nil then begin
      VSourceLine := ABitmap.Data;
      VTargetLine := VBuffer.Data;
      for i := 0 to VSize.X * VSize.Y - 1 do begin
        if VSourceLine[i] = AMaskColor then begin
          VTargetLine[i] := 0;
        end else begin
          VTargetLine[i] := VSourceLine[i];
        end;
      end;
      Result := ABitmapFactory.BuildWithOwnBuffer(VBuffer);
    end;
  end;
end;

function GetBitmap(
  const AContentTypeManager: IContentTypeManager;
  const AConfig: IConfigDataProvider;
  const AConfigIniParams: IConfigDataProvider;
  const ABitmapFactory: IBitmap32StaticFactory;
  const ADefName: string;
  const AIdent: string
): IBitmap32Static;
var
  VImageName: string;
  VData: IBinaryData;
  VLoader: IBitmapTileLoader;
begin
  Result := nil;
  VImageName := ADefName;
  VImageName := AConfigIniParams.ReadString(AIdent, VImageName);
  VData := AConfig.ReadBinary(VImageName);
  if (VData <> nil) and (VData.Size > 0) then begin
    VLoader :=  AContentTypeManager.GetBitmapLoaderByFileName(VImageName);
    if VLoader <> nil then begin
      Result := VLoader.Load(VData);
      if Result <> nil then begin
        if LowerCase(ExtractFileExt(VImageName)) = '.bmp' then begin
          Result :=
            UpdateBMPTransp(
              ABitmapFactory,
              Color32(255, 0, 255, 255),
              Result
            );
        end;
      end;
    end;
  end;
end;

procedure TZmpInfoGUI.LoadIcons(
  const AContentTypeManager: IContentTypeManager;
  const AConfig: IConfigDataProvider;
  const AConfigIniParams: IConfigDataProvider;
  const ABitmapFactory: IBitmap32StaticFactory;
  Apnum: Integer
);
begin
  try
    FBmp24 :=
      GetBitmap(
        AContentTypeManager,
        AConfig,
        AConfigIniParams,
        ABitmapFactory,
        '24.bmp',
        'BigIconName'
      );
  except
    FBmp24 := nil;
  end;
  if FBmp24 = nil then begin
    FBmp24 := CreateDefaultIcon(ABitmapFactory, Apnum);
  end;

  try
    FBmp18 :=
      GetBitmap(
        AContentTypeManager,
        AConfig,
        AConfigIniParams,
        ABitmapFactory,
        '18.bmp',
        'SmallIconName'
      );
  except
    FBmp18 := nil;
  end;
  if FBmp18 = nil then begin
    FBmp18 := FBmp24;
  end;
end;

procedure TZmpInfoGUI.LoadInfo(
  const ALangList: ILanguageListStatic;
  const AConfig: IConfigDataProvider
);
var
  VDefValue: string;
  VFileName: string;
  i: Integer;
  VLanguageCode: string;
  VValueList: TStringList;
  VValue: string;
begin
  // 'sas://ZmpInfo/' + GUIDToString(FGUID)
  if AConfig.ReadString('index.html', '') <> '' then begin
    VDefValue := '/index.html';
  end else if AConfig.ReadString('info.txt', '') <> '' then begin
    VDefValue := '/info.txt';
  end else begin
    VDefValue := '';
  end;
  VValueList := TStringList.Create;
  try
    for i := 0 to ALangList.Count - 1 do begin
      VValue := VDefValue;
      VLanguageCode := ALangList.Code[i];
      VFileName := 'index_' + VLanguageCode + '.html';
      if AConfig.ReadString(VFileName, '') <> '' then begin
        VValue := '/' + VFileName;
      end else begin
        VFileName := 'info_' + VLanguageCode + '.txt';
        if AConfig.ReadString(VFileName, '') <> '' then begin
          VValue := '/' + VFileName;
        end;
      end;
      VValueList.Add(VValue);
    end;
    FInfoUrl := TStringByLanguageWithStaticList.Create(VValueList);
  finally
    VValueList.Free;
  end;
end;

procedure TZmpInfoGUI.LoadUIParams(
  const ALangList: ILanguageListStatic;
  const AConfig: IConfigDataProvider;
  Apnum: Integer
);
begin
  // multilanguage params
  FName := InternalMakeStringByLanguage(ALangList, AConfig, 'name', 'map#' + inttostr(Apnum));
  FParentSubMenu := InternalMakeStringByLanguage(ALangList, AConfig, 'ParentSubMenu', '');

  FHotKey := AConfig.ReadInteger('DefHotKey', 0);
  FHotKey := AConfig.ReadInteger('HotKey', FHotKey);
  FSeparator := AConfig.ReadBool('separator', false);
  FEnabled := AConfig.ReadBool('Enabled', true);
  FSortIndex := AConfig.ReadInteger('pnum', -1);
end;

{ TZmpInfo }

constructor TZmpInfo.Create(
  const AZmpConfig: IZmpConfig;
  const ALanguageManager: ILanguageManager;
  const AProjectionSetFactory: IProjectionSetFactory;
  const AContentTypeManager: IContentTypeManager;
  const AAppearanceOfMarkFactory: IAppearanceOfMarkFactory;
  const AMarkPictureList: IMarkPictureList;
  const ABitmapFactory: IBitmap32StaticFactory;
  const AFileName: string;
  const AConfig: IConfigDataProvider;
  Apnum: Integer
);
begin
  inherited Create;
  FFileName := AFileName;
  FZmpConfig := AZmpConfig;
  FConfig := AConfig;
  FConfigIni := FConfig.GetSubItem('params.txt');
  if FConfigIni = nil then begin
    raise EZmpIniNotFound.Create(_('Not found "params.txt" in zmp'));
  end;
  FConfigIniParams := FConfigIni.GetSubItem('PARAMS');
  if FConfigIniParams = nil then begin
    raise EZmpParamsNotFound.Create(_('Not found PARAMS section in zmp'));
  end;
  LoadConfig(AProjectionSetFactory, AAppearanceOfMarkFactory, AMarkPictureList, ALanguageManager);
  FGUI :=
    TZmpInfoGUI.Create(
      FGUID,
      ALanguageManager,
      AContentTypeManager,
      ABitmapFactory,
      FConfig,
      FConfigIni,
      FConfigIniParams,
      Apnum
    );
  FLicense := InternalMakeStringByLanguage(ALanguageManager.LanguageList, FConfigIniParams, 'License', '');
  FLayerZOrder := FConfigIniParams.ReadInteger('LayerZOrder', 0);
end;

function TZmpInfo.GetAbilities: IMapAbilitiesConfigStatic;
begin
  Result := FAbilities;
end;

function TZmpInfo.GetBanTileSamples: IBinaryDataListStatic;
begin
  Result := FBanTileSamples;
end;

function TZmpInfo.GetBinaryListByConfig(
  const AConfig: IConfigDataProvider
): IBinaryDataListStatic;
var
  VList: IStringListStatic;
  VCount: Integer;
  i: Integer;
  VItems: array of IBinaryData;
begin
  Result := nil;
  if AConfig <> nil then begin
    VList := AConfig.ReadValuesList;
    VCount := VList.Count;
    if VCount > 0 then begin
      SetLength(VItems, VCount);
      for i := 0 to VCount - 1 do begin
        VItems[i] := AConfig.ReadBinary(VList.Items[i]);
      end;
      try
        Result := TBinaryDataListStatic.Create(VItems);
      finally
        for i := 0 to VCount - 1 do begin
          VItems[i] := nil;
        end;
      end;
    end;
  end;
end;

function TZmpInfo.GetContentTypeSubst: IContentTypeSubst;
begin
  Result := FContentTypeSubst;
end;

function TZmpInfo.GetDataProvider: IConfigDataProvider;
begin
  Result := FConfig;
end;

function TZmpInfo.GetEmptyTileSamples: IBinaryDataListStatic;
begin
  Result := FEmptyTileSamples;
end;

function TZmpInfo.GetFileName: string;
begin
  Result := FFileName;
end;

function TZmpInfo.GetPointParams: IImportPointParams;
begin
  Result := FPointParams;
end;

function TZmpInfo.GetLineParams: IImportLineParams;
begin
  Result := FLineParams;
end;

function TZmpInfo.GetPolyParams: IImportPolyParams;
begin
  Result := FPolyParams;
end;

function TZmpInfo.GetProjectionSet: IProjectionSet;
begin
  Result := FProjectionSet;
end;

function TZmpInfo.GetGUI: IZmpInfoGUI;
begin
  Result := FGUI;
end;

function TZmpInfo.GetGUID: TGUID;
begin
  Result := FGUID;
end;

function TZmpInfo.GetIsLayer: Boolean;
begin
  Result := FIsLayer;
end;

function TZmpInfo.GetLayerZOrder: Integer;
begin
  Result := FLayerZOrder;
end;

function TZmpInfo.GetLicense: IStringByLanguage;
begin
  Result := FLicense;
end;

function TZmpInfo.GetStorageConfig: ISimpleTileStorageConfigStatic;
begin
  Result := FStorageConfig;
end;

function TZmpInfo.GetViewProjectionSet: IProjectionSet;
begin
  Result := FViewProjectionSet;
end;

function TZmpInfo.GetTileDownloaderConfig: ITileDownloaderConfigStatic;
begin
  Result := FTileDownloaderConfig;
end;

function TZmpInfo.GetTilePostDownloadCropConfig: ITilePostDownloadCropConfigStatic;
begin
  Result := FTilePostDownloadCropConfig;
end;

function TZmpInfo.GetTileDownloadRequestBuilderConfig: ITileDownloadRequestBuilderConfigStatic;
begin
  Result := FTileDownloadRequestBuilderConfig;
end;

function TZmpInfo.GetVersion: string;
begin
  Result := FVersion;
end;

procedure TZmpInfo.LoadAbilities(const AConfig: IConfigDataProvider);
var
  VIsShowOnSmMap: Boolean;
  VUseDownload: Boolean;
begin
  VIsShowOnSmMap := AConfig.ReadBool('CanShowOnSmMap', True);
  VUseDownload := AConfig.ReadBool('UseDwn', True);

  FAbilities :=
    TMapAbilitiesConfigStatic.Create(
      VIsShowOnSmMap,
      VUseDownload
    );
end;

procedure TZmpInfo.LoadConfig(
  const AProjectionSetFactory: IProjectionSetFactory;
  const AAppearanceOfMarkFactory: IAppearanceOfMarkFactory;
  const AMarkPictureList: IMarkPictureList;
  const ALanguageManager: ILanguageManager
);
begin
  FGUID := LoadGUID(FConfigIniParams);
  FIsLayer := FConfigIniParams.ReadBool('asLayer', False);
  LoadVersion(FConfigIniParams);
  LoadProjectionInfo(FConfigIni, AProjectionSetFactory);
  LoadTileRequestBuilderConfig(FConfigIniParams);
  LoadTileDownloaderConfig(FConfigIniParams);
  LoadCropConfig(FConfigIniParams);
  LoadStorageConfig(FConfigIniParams);
  LoadAbilities(FConfigIniParams);
  LoadVectorAppearanceConfig(AAppearanceOfMarkFactory, AMarkPictureList, FConfigIniParams);
  LoadSamples(FConfig);
  FContentTypeSubst := TContentTypeSubstByList.Create(FConfigIniParams);
end;

procedure TZmpInfo.LoadCropConfig(const AConfig: IConfigDataProvider);
var
  VRect: TRect;
  VCutCount, VCutSize, VCutTile: TPoint;
  VCutToSkip: String;
begin
  // crop params
  VRect.Left := AConfig.ReadInteger('TileRLeft', 0);
  VRect.Top := AConfig.ReadInteger('TileRTop', 0);
  VRect.Right := AConfig.ReadInteger('TileRRight', 0);
  VRect.Bottom := AConfig.ReadInteger('TileRBottom', 0);
  // cut params
  VCutCount.X := AConfig.ReadInteger('CutCountX', 0);
  VCutCount.Y := AConfig.ReadInteger('CutCountY', 0);
  VCutSize.X := AConfig.ReadInteger('CutSizeX', 0);
  VCutSize.Y := AConfig.ReadInteger('CutSizeY', 0);
  VCutTile.X := AConfig.ReadInteger('CutTileX', 0);
  VCutTile.Y := AConfig.ReadInteger('CutTileY', 0);
  VCutToSkip := AConfig.ReadString('CutToSkip', '');
  // make
  FTilePostDownloadCropConfig := TTilePostDownloadCropConfigStatic.Create(VRect, VCutCount, VCutSize, VCutTile, VCutToSkip);
end;

function TZmpInfo.LoadGUID(const AConfig: IConfigDataProvider): TGUID;
begin
  Result := ReadGUID(AConfig, 'GUID', CGUID_Zero);
  if IsEqualGUID(Result, CGUID_Zero) then begin
    raise EZmpGUIDError.CreateRes(@SAS_ERR_MapGUIDEmpty);
  end;
end;

procedure TZmpInfo.LoadProjectionInfo(
  const AConfig: IConfigDataProvider;
  const AProjectionSetFactory: IProjectionSetFactory
);
var
  VParams: IConfigDataProvider;
begin
  VParams := AConfig.GetSubItem('ViewInfo');
  if VParams <> nil then begin
    FViewProjectionSet := AProjectionSetFactory.GetProjectionSetByConfig(VParams);
  end;
  FProjectionSet := AProjectionSetFactory.GetProjectionSetByConfig(FConfigIniParams);
  if FViewProjectionSet = nil then begin
    FViewProjectionSet := FProjectionSet;
  end;
end;

procedure TZmpInfo.LoadSamples(const AConfig: IConfigDataProvider);
begin
  FEmptyTileSamples := GetBinaryListByConfig(AConfig.GetSubItem('EmptyTiles'));
  FBanTileSamples := GetBinaryListByConfig(AConfig.GetSubItem('BanTiles'));
end;

procedure TZmpInfo.LoadStorageConfig(
  const AConfig: IConfigDataProvider
);
var
  VCacheTypeCode: Integer;
  VNameInCache: string;
  VMainStorageContentType: AnsiString;
  VTileFileExt: AnsiString;
  VIsReadOnly: Boolean;
  VAllowRead: Boolean;
  VAllowScan: Boolean;
  VAllowAdd: Boolean;
  VAllowDelete: Boolean;
  VAllowReplace: Boolean;
  VUseMemCache: Boolean;
  VMemCacheCapacity: Integer;
  VMemCacheTTL: Cardinal;
  VMemCacheClearStrategy: Integer;
  VStorageAbilities: ITileStorageAbilities;
begin
  VNameInCache := AConfig.ReadString('NameInCache', '');
  VCacheTypeCode := AConfig.ReadInteger('CacheType', 0);
  VUseMemCache := AConfig.ReadBool('UseMemCache', FZmpConfig.UseMemCache);
  VMemCacheCapacity := AConfig.ReadInteger('MemCacheCapacity', FZmpConfig.MemCacheCapacity);
  VMemCacheTTL := AConfig.ReadInteger('MemCacheTTL', FZmpConfig.MemCacheTTL);
  VMemCacheClearStrategy := AConfig.ReadInteger('MemCacheClearStrategy', FZmpConfig.MemCacheClearStrategy);
  VMainStorageContentType := AConfig.ReadAnsiString('MainStorageContentType', '');
  VTileFileExt := AlLowerCase(AConfig.ReadAnsiString('Ext', '.jpg'));

  VIsReadOnly := AConfig.ReadBool('IsReadOnly', False);
  VAllowRead := AConfig.ReadBool('AllowRead', True);
  VAllowScan := AConfig.ReadBool('AllowScan', True);
  VAllowAdd := AConfig.ReadBool('AllowAdd', not VIsReadOnly);
  VAllowDelete := AConfig.ReadBool('AllowDelete', not VIsReadOnly);
  VAllowReplace := AConfig.ReadBool('AllowScan', not VIsReadOnly);

  VStorageAbilities :=
    TTileStorageAbilities.Create(
      VAllowRead,
      VAllowScan,
      VAllowAdd,
      VAllowDelete,
      VAllowReplace
    );

  FStorageConfig :=
    TSimpleTileStorageConfigStatic.Create(
      VCacheTypeCode,
      VNameInCache,
      VMainStorageContentType,
      VTileFileExt,
      VStorageAbilities,
      VUseMemCache,
      VMemCacheCapacity,
      VMemCacheTTL,
      VMemCacheClearStrategy
    );
end;

procedure TZmpInfo.LoadTileDownloaderConfig(const AConfig: IConfigDataProvider);
var
  VUseDownload: Boolean;
  VAllowUseCookie: Boolean;
  VIgnoreMIMEType: Boolean;
  VDetectMIMEType: Boolean;
  VDefaultMIMEType: AnsiString;
  VExpectedMIMETypes: AnsiString;
  VWaitInterval: Cardinal;
  VMaxConnectToServerCount: Cardinal;
  VIteratorSubRectSize: TPoint;
  VRestartDownloaderOnMemCacheTTL: Boolean;
  fL: TStringList;
begin
  VUseDownload := AConfig.ReadBool('UseDwn', True);
  VAllowUseCookie := AConfig.ReadBool('AllowUseCookie', False);
  VIgnoreMIMEType := AConfig.ReadBool('IgnoreContentType', False);
  VDetectMIMEType := AConfig.ReadBool('DetectContentType', False);
  VDefaultMIMEType := AConfig.ReadAnsiString('DefaultContentType', 'image/jpg');
  VExpectedMIMETypes := AConfig.ReadAnsiString('ContentType', 'image/jpg');
  VWaitInterval := AConfig.ReadInteger('Sleep', 0);
  VRestartDownloaderOnMemCacheTTL := AConfig.ReadBool('RestartDownloadOnMemCacheTTL', False);
  VMaxConnectToServerCount :=
    AConfig.ReadInteger(
      'MaxConnectToServerCount',
      FZmpConfig.MaxConnectToServerCount
    );
  fL := TStringList.Create;
  try
    fL.Delimiter := ',';
    fL.StrictDelimiter := True;
    fL.DelimitedText := AConfig.ReadString('IteratorSubRectSize', '1,1');
    VIteratorSubRectSize.x := StrToInt(fL[0]);
    VIteratorSubRectSize.y := StrToInt(fL[1]);
  finally
    fL.Free
  end;
  FTileDownloaderConfig :=
    TTileDownloaderConfigStatic.Create(
      nil,
      VUseDownload,
      VAllowUseCookie,
      VWaitInterval,
      VMaxConnectToServerCount,
      VIgnoreMIMEType,
      VDetectMIMEType,
      VExpectedMIMETypes,
      VDefaultMIMEType,
      VIteratorSubRectSize,
      VRestartDownloaderOnMemCacheTTL
    );
end;

procedure TZmpInfo.LoadTileRequestBuilderConfig(
  const AConfig: IConfigDataProvider
);
var
  VUrlBase: AnsiString;
  VServerNames: AnsiString;
  VRequestHead: AnsiString;
  VIsUseDownloader: Boolean;
  VDefaultProjConverterArgs: AnsiString;
begin
  VUrlBase := AConfig.ReadAnsiString('DefURLBase', '');
  VUrlBase := AConfig.ReadAnsiString('URLBase', VUrlBase);
  VServerNames := AConfig.ReadAnsiString('ServerNames', '');
  VRequestHead := AConfig.ReadAnsiString('RequestHead', '');
  VIsUseDownloader := AConfig.ReadBool('IsUseDownloaderInScript', False);
  VDefaultProjConverterArgs := AConfig.ReadAnsiString('Proj4Args', '');

  FTileDownloadRequestBuilderConfig :=
    TTileDownloadRequestBuilderConfigStatic.Create(
      VUrlBase,
      VServerNames,
      VRequestHead,
      VIsUseDownloader,
      VDefaultProjConverterArgs
    );
end;

procedure TZmpInfo.LoadVectorAppearanceConfig(
  const AAppearanceOfMarkFactory: IAppearanceOfMarkFactory;
  const AMarkPictureList: IMarkPictureList;
  const AConfig: IConfigDataProvider
);
var
  VAppearance: IAppearance;
  VConfig: IConfigDataProvider;
  VSubConfig: IConfigDataProvider;
  VIsForceTextColor: Boolean;
  VIsForceTextBgColor: Boolean;
  VIsForceFontSize: Boolean;
  VIsForceMarkerSize: Boolean;
  VIsForcePicName: Boolean;

  VIsForceLineColor: Boolean;
  VIsForceLineWidth: Boolean;
  VIsForceFillColor: Boolean;
begin
  VConfig := AConfig.GetSubItem('Vector');
  if Assigned(VConfig) then begin
    VSubConfig := VConfig.GetSubItem('Point');
    if Assigned(VSubConfig) then begin
      VAppearance := ReadAppearancePoint(VSubConfig, AMarkPictureList, AAppearanceOfMarkFactory, nil);

      VIsForceTextColor := VSubConfig.ReadBool('IsForceTextColor', True);
      VIsForceTextBgColor := VSubConfig.ReadBool('IsForceShadowColor', True);
      VIsForceFontSize := VSubConfig.ReadBool('IsForceFontSize', True);
      VIsForceMarkerSize := VSubConfig.ReadBool('IsForceIconSize', True);
      VIsForcePicName := VSubConfig.ReadBool('IsForceIconName', True);

      FPointParams :=
        TImportPointParams.Create(
          VAppearance,
          VIsForceTextColor,
          VIsForceTextBgColor,
          VIsForceFontSize,
          VIsForceMarkerSize,
          VIsForcePicName
        );
    end;

    VSubConfig := VConfig.GetSubItem('Line');
    if Assigned(VSubConfig) then begin
      VAppearance := ReadAppearanceLine(VSubConfig, AAppearanceOfMarkFactory, nil);

      VIsForceLineColor := VSubConfig.ReadBool('IsForceLineColor', True);
      VIsForceLineWidth := VSubConfig.ReadBool('IsForceLineWidth', True);
      FLineParams := TImportLineParams.Create(VAppearance, VIsForceLineColor, VIsForceLineWidth);
    end;

    VSubConfig := VConfig.GetSubItem('Poly');
    if Assigned(VSubConfig) then begin
      VAppearance := ReadAppearancePolygon(VSubConfig, AAppearanceOfMarkFactory, nil);

      VIsForceLineColor := VSubConfig.ReadBool('IsForceLineColor', True);
      VIsForceLineWidth := VSubConfig.ReadBool('IsForceLineWidth', True);
      VIsForceFillColor := VSubConfig.ReadBool('IsForceFillColor', True);
      FPolyParams := TImportPolyParams.Create(VAppearance, VIsForceLineColor, VIsForceLineWidth, VIsForceFillColor);
    end;
  end;
end;

procedure TZmpInfo.LoadVersion(
  const AConfig: IConfigDataProvider
);
begin
  FVersion := AConfig.ReadString('Version', '');
end;

end.

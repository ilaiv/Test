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

unit frm_Settings;

interface

uses
  SysUtils,
  Classes,
  Controls,
  Forms,
  StdCtrls,
  ExtCtrls,
  ComCtrls,
  Dialogs,
  Spin,
  UITypes,
  urlmon,
  wininet,
  GR32,
  i_InetConfig,
  i_ProxySettings,
  i_ListenerNotifierLinksList,
  i_ImageResamplerFactory,
  i_MapTypeConfigModalEdit,
  i_LanguageManager,
  i_MainFormConfig,
  i_SensorList,
  i_FavoriteMapSetHelper,
  u_ShortcutManager,
  u_CommonFormAndFrameParents,
  frm_FavoriteMapSetEditor,
  fr_FavoriteMapSetManager,
  fr_MapsList,
  fr_GPSConfig,
  fr_PathSelect,
  fr_CacheTypeList,
  fr_ShortCutList;

type
  TfrmSettings = class(TFormWitghLanguageManager)
    PageControl1: TPageControl;
    tsCache: TTabSheet;
    tsInternet: TTabSheet;
    btnCancel: TButton;
    btnOk: TButton;
    tsControl: TTabSheet;
    GroupBox1: TGroupBox;
    ScrolInvert: TCheckBox;
    tsView: TTabSheet;
    btnApply: TButton;
    Label3: TLabel;
    ComboBox1: TComboBox;
    TrBarGamma: TTrackBar;
    LabelGamma: TLabel;
    TrBarContrast: TTrackBar;
    LabelContrast: TLabel;
    tsGPS: TTabSheet;
    lblResizeMethod: TLabel;
    cbbResizeMethod: TComboBox;
    MiniMapAlphaEdit: TSpinEdit;
    lblMiniMapAlfa: TLabel;
    TilesOverScreenEdit: TSpinEdit;
    Label69: TLabel;
    tsWiki: TTabSheet;
    CBWMainColor: TColorBox;
    lblWikiMainColor: TLabel;
    lblWikiBgColor: TLabel;
    CBWFonColor: TColorBox;
    CB_llstrType: TComboBox;
    Label84: TLabel;
    CBShowmapname: TCheckBox;
    CBinvertcolor: TCheckBox;
    GroupBox4: TGroupBox;
    EditPass: TEdit;
    EditLogin: TEdit;
    lblProxyPass: TLabel;
    CBLogin: TCheckBox;
    EditIP: TEdit;
    Label27: TLabel;
    Label28: TLabel;
    SpinEditBorderAlpha: TSpinEdit;
    SpinEditGenshtabBorderAlpha: TSpinEdit;
    SpinEditDegreeBorderAlpha: TSpinEdit;
    ColorBoxBorder: TColorBox;
    GenshtabBoxBorder: TColorBox;
    DegreeBoxBorder: TColorBox;
    chkRetryIfNoResponse: TCheckBox;
    chkProcessNextTile: TCheckBox;
    tsMaps: TTabSheet;
    GroupBox5: TGroupBox;
    CBoxLocal: TComboBox;
    Label8: TLabel;
    ChBoxFirstLat: TCheckBox;
    CBSaveTileNotExists: TCheckBox;
    CBBorderText: TCheckBox;
    CBGenshtabBorderText: TCheckBox;
    CBDegreeBorderText: TCheckBox;
    Label23: TLabel;
    Label24: TLabel;
    Label26: TLabel;
    MapZapColorBox: TColorBox;
    Label29: TLabel;
    MapZapAlphaEdit: TSpinEdit;
    CBlock_toolbars: TCheckBox;
    Label30: TLabel;
    SETilesOCache: TSpinEdit;
    CBShowHintOnMarks: TCheckBox;
    Label32: TLabel;
    SETimeOut: TSpinEdit;
    lblBGColor: TLabel;
    ColorBoxBackGround: TColorBox;
    CBLastSuccess: TCheckBox;
    pnlBottomButtons: TPanel;
    flwpnlMemCache: TFlowPanel;
    pnlProxyUrl: TPanel;
    lblProxyLogin: TLabel;
    flwpnlProxyAuth: TFlowPanel;
    pnlDownloadParams: TPanel;
    flwpnlDownloadTimeOut: TFlowPanel;
    pnlDistFormat: TPanel;
    pnlUILeft: TPanel;
    pnlLonLatFormat: TPanel;
    pnlImageProcess: TPanel;
    pnlResize: TPanel;
    flwpnlTileBorders: TFlowPanel;
    flwpnlGenshtabBorders: TFlowPanel;
    flwpnlDegreeBorders: TFlowPanel;
    pnlTileBorders: TPanel;
    pnlGenshtabBorders: TPanel;
    pnlDegreeBorders: TPanel;
    pnlUIRight: TPanel;
    flwpnlMiniMapAlfa: TFlowPanel;
    flwpnlTileBorder: TFlowPanel;
    pnlOptions: TPanel;
    pnlLang: TPanel;
    pnlFillMap: TPanel;
    flwpnlFillMap: TFlowPanel;
    pnlBgColor: TPanel;
    grdpnlUI: TGridPanel;
    grdpnlWiki: TGridPanel;
    CBMinimizeToTray: TCheckBox;
    pnlImageProcessTop: TPanel;
    btnImageProcessReset: TButton;
    lblImageProcessCaption: TLabel;
    pnlAreaFormat: TPanel;
    lblAreaFormat: TLabel;
    cbbAreaFormat: TComboBox;
    tsGrids: TTabSheet;
    pnlResizeOnload: TPanel;
    lblResizeOnLoad: TLabel;
    cbbResizeOnLoad: TComboBox;
    pnlResizeGetPre: TPanel;
    lblResizeGetPre: TLabel;
    cbbResizeGetPre: TComboBox;
    pnlProjectionChange: TPanel;
    lblProjectionChange: TLabel;
    cbbProjectionChange: TComboBox;
    pnlDownloadResize: TPanel;
    lblDownloadResize: TLabel;
    cbbDownloadResize: TComboBox;
    lblResize: TLabel;
    pnlResizeTileMatrixDraft: TPanel;
    lblResizeTileMatrixDraft: TLabel;
    cbbResizeTileMatrixDraft: TComboBox;
    tsGPSMarker: TTabSheet;
    SESizeStr: TSpinEdit;
    lblGPSMarkerSize: TLabel;
    flwpnlGPSMarker: TFlowPanel;
    ColorBoxGPSstr: TColorBox;
    lblGPSMarkerColor: TLabel;
    lblGPSMarkerRingsCount: TLabel;
    seGPSMarkerRingsCount: TSpinEdit;
    lblGPSMarkerRingRadius: TLabel;
    seGPSMarkerRingRadius: TSpinEdit;
    lbDBMSCachePath: TLabel;
    flwpnl1: TFlowPanel;
    lbl1: TLabel;
    seSleepOnResetConnection: TSpinEdit;
    lbl2: TLabel;
    edtUserAgent: TEdit;
    pnl1: TPanel;
    btnResetUserAgentString: TButton;
    ChkShowLogo: TCheckBox;
    tsPaths: TTabSheet;
    pnlMapsPath: TPanel;
    pnlUserDataPath: TPanel;
    pnlTerrainDataPath: TPanel;
    pnlTrackPath: TPanel;
    pnlMarksDbPath: TPanel;
    pnlMarksIconsPath: TPanel;
    pnlMediaDataPath: TPanel;
    pnlMapSvcScan: TPanel;
    pnlNewCpath: TPanel;
    pnlOldCpath: TPanel;
    pnlEScPath: TPanel;
    pnlGMTilesPath: TPanel;
    pnlGECachePath: TPanel;
    pnledtBDBCachePath: TPanel;
    pnledtBDBVerCachePath: TPanel;
    pnledtGCCachePath: TPanel;
    pnlDBMSPath: TPanel;
    pnlBaseCahcePath: TPanel;
    pnlDefCache: TPanel;
    edtDBMSCachePath: TEdit;
    pnlButtnos: TPanel;
    BtnDef: TButton;
    lbl: TLabel;
    pnlMATilesPath: TPanel;
    pnlCacheTypesList: TPanel;
    pnlTMSPath: TPanel;
    tsFavorite: TTabSheet;
    pnlCoordSys: TPanel;
    lblCoordSysType: TLabel;
    cbbCoordSysType: TComboBox;
    pnlSQLiteCachePath: TPanel;
    pnlCoordSysInfoType: TPanel;
    lblCoordSysInfoType: TLabel;
    cbbCoordSysInfoType: TComboBox;
    flwpnlMaxConnsPerServer: TFlowPanel;
    lblMaxConnsPerServer: TLabel;
    seMaxConnsPerServer: TSpinEdit;
    pnlNetworkEngine: TPanel;
    lbl3: TLabel;
    cbbNetworkEngine: TComboBox;
    rbNoProxy: TRadioButton;
    rbUseIESettings: TRadioButton;
    rbManualProxy: TRadioButton;
    pnlProxyRadioButtons: TPanel;
    cbbProxyType: TComboBox;
    procedure btnCancelClick(Sender: TObject);
    procedure btnApplyClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure TrBarGammaChange(Sender: TObject);
    procedure TrBarContrastChange(Sender: TObject);
    procedure CBLoginClick(Sender: TObject);
    procedure CBoxLocalChange(Sender: TObject);
    procedure FormCloseQuery(
      Sender: TObject;
      var CanClose: Boolean
    );
    procedure btnImageProcessResetClick(Sender: TObject);
    procedure btnResetUserAgentStringClick(Sender: TObject);
    procedure BtnDefClick(Sender: TObject);
    procedure rbProxyClick(Sender: TObject);
    procedure cbbNetworkEngineChange(Sender: TObject);
  private
    FOnSave: TNotifyEvent;
    FLinksList: IListenerNotifierLinksList;
    frShortCutList: TfrShortCutList;
    frMapsList: TfrMapsList;
    frGPSConfig: TfrGPSConfig;
    FMainFormConfig: IMainFormConfig;
    FSensorList: ISensorList;
    FMapTypeEditor: IMapTypeConfigModalEdit;
    FfrMapPathSelect: TfrPathSelect;
    FfrTerrainDataPathSelect: TfrPathSelect;
    FfrUserDataPathSelect: TfrPathSelect;
    FfrTrackPathSelect: TfrPathSelect;
    FfrMarksIconsPathSelect: TfrPathSelect;
    FfrMarksDbPathSelect: TfrPathSelect;
    FfrMediaDataPathSelect: TfrPathSelect;
    FfrMapSvcScanPathSelect: TfrPathSelect;
    FfrBaseCahcePathSelect: TfrPathSelect;
    FfrNewCpath: TfrPathSelect;
    FfrOldCpath: TfrPathSelect;
    FfrEScPath: TfrPathSelect;
    FfrGMTilesPath: TfrPathSelect;
    FfrMobileAtlasTilesPath: TfrPathSelect;
    FfrTMSTilesPath: TfrPathSelect;
    FfrGECachePath: TfrPathSelect;
    FfrBDBCachePath: TfrPathSelect;
    FfrBDBVerCachePath: TfrPathSelect;
    FfrSQLiteCachePath: TfrPathSelect;
    FfrGCCachePath: TfrPathSelect;
    FfrCacheTypesList: TfrCacheTypeList;
    frFavoriteMapSetManager: TfrFavoriteMapSetManager;

    procedure InitCoordRepresentationList;
    procedure InitResamplersList(
      const AList: IImageResamplerFactoryList;
      ABox: TComboBox
    );
    procedure RefreshProxyTypeComboBox(
      const ANetworkEngineType: TNetworkEngineType;
      const AProxyType: TProxyServerType
    );
    function StrToProxyAddress(const AStr: string): string;
    function GetProxyTypeValue: TProxyServerType;
  public
    constructor Create(
      const ALanguageManager: ILanguageManager;
      const AMainFormConfig: IMainFormConfig;
      const ASensorList: ISensorList;
      const AShortCutManager: TShortcutManager;
      const AMapTypeEditor: IMapTypeConfigModalEdit;
      const AFavoriteMapSetHelper: IFavoriteMapSetHelper;
      const AFavoriteMapSetEditor: TfrmFavoriteMapSetEditor;
      AOnSave: TNotifyEvent
    ); reintroduce;
    destructor Destroy; override;
    procedure SetProxy;
    procedure ShowGPSSettings;
    procedure RefreshTranslation; override;
  end;

implementation

uses
  gnugettext,
  c_CacheTypeCodes, // for default path
  c_InetConfig, // for default UserAgent
  t_CommonTypes,
  t_CoordRepresentation,
  i_WinInetConfig,
  u_ListenerNotifierLinksList,
  u_StrFunc,
  u_GlobalState,
  u_CoordRepresentation,
  u_ResStrings;

{$R *.dfm}

constructor TfrmSettings.Create(
  const ALanguageManager: ILanguageManager;
  const AMainFormConfig: IMainFormConfig;
  const ASensorList: ISensorList;
  const AShortCutManager: TShortcutManager;
  const AMapTypeEditor: IMapTypeConfigModalEdit;
  const AFavoriteMapSetHelper: IFavoriteMapSetHelper;
  const AFavoriteMapSetEditor: TfrmFavoriteMapSetEditor;
  AOnSave: TNotifyEvent
);
begin
  inherited Create(ALanguageManager);
  FMapTypeEditor := AMapTypeEditor;
  FMainFormConfig := AMainFormConfig;
  FSensorList := ASensorList;
  FOnSave := AOnSave;
  FLinksList := TListenerNotifierLinksList.Create;
  frShortCutList :=
    TfrShortCutList.Create(
      ALanguageManager,
      AShortCutManager
    );
  frMapsList :=
    TfrMapsList.Create(
      ALanguageManager,
      GState.InternalBrowser,
      GState.MapType.FullMapsSet,
      GState.MapType.GUIConfigList,
      AMapTypeEditor
    );
  frFavoriteMapSetManager :=
    TfrFavoriteMapSetManager.Create(
      ALanguageManager,
      GState.MapType.FullMapsSet,
      GState.CoordToStringConverter,
      GState.FavoriteMapSetConfig,
      AFavoriteMapSetHelper,
      AFavoriteMapSetEditor
    );
  frGPSConfig :=
    TfrGPSConfig.Create(
      ALanguageManager,
      GState.GpsSystem,
      FSensorList,
      GState.GUISyncronizedTimerNotifier,
      GState.SkyMapDraw,
      FMainFormConfig.GPSBehaviour,
      FMainFormConfig.LayersConfig.GPSTrackConfig,
      GState.Config.GPSConfig
    );
  FfrCacheTypesList :=
    TfrCacheTypeList.Create(
      ALanguageManager,
      GState.TileStorageTypeList,
      False,
      CTileStorageTypeClassAll,
      [tsacRead]
    );
  FfrMapPathSelect :=
    TfrPathSelect.Create(
      ALanguageManager,
      gettext_NoOp('Path to Maps'),
      GState.Config.MapsPath
    );
  FfrTerrainDataPathSelect :=
    TfrPathSelect.Create(
      ALanguageManager,
      gettext_NoOp('Path to Terrain data'),
      GState.Config.TerrainDataPath
    );
  FfrUserDataPathSelect :=
    TfrPathSelect.Create(
      ALanguageManager,
      gettext_NoOp('Path to user data'),
      GState.Config.UserDataPath
    );
  FfrTrackPathSelect :=
    TfrPathSelect.Create(
      ALanguageManager,
      gettext_NoOp('Path to gps tracks'),
      GState.Config.TrackPath
    );
  FfrMarksIconsPathSelect :=
    TfrPathSelect.Create(
      ALanguageManager,
      gettext_NoOp('Path to marks icon'),
      GState.Config.MarksIconsPath
    );
  FfrMarksDbPathSelect :=
    TfrPathSelect.Create(
      ALanguageManager,
      gettext_NoOp('Path to Marks database'),
      GState.Config.MarksDbPath
    );
  FfrMediaDataPathSelect :=
    TfrPathSelect.Create(
      ALanguageManager,
      gettext_NoOp('Path to MediaData'),
      GState.Config.MediaDataPath
    );
  FfrMapSvcScanPathSelect :=
    TfrPathSelect.Create(
      ALanguageManager,
      gettext_NoOp('Path to map scan DB'),
      GState.Config.MapSvcScanConfig.Path
    );
  FfrBaseCahcePathSelect :=
    TfrPathSelect.Create(
      ALanguageManager,
      gettext_NoOp('Base Cache path'),
      GState.Config.BaseCachePath
    );
  FfrNewCpath :=
    TfrPathSelect.Create(
      ALanguageManager,
      gettext_NoOp('Native cache folder:'),
      GState.CacheConfig.NewCPath
    );
  FfrOldCpath :=
    TfrPathSelect.Create(
      ALanguageManager,
      gettext_NoOp('GoogleMV cache folder:'),
      GState.CacheConfig.OldCPath
    );
  FfrEScPath :=
    TfrPathSelect.Create(
      ALanguageManager,
      gettext_NoOp('EarthSlicer cache folder:'),
      GState.CacheConfig.ESCPath
    );
  FfrGMTilesPath :=
    TfrPathSelect.Create(
      ALanguageManager,
      gettext_NoOp('GlobalMapper Tiles (GMT) cache folder:'),
      GState.CacheConfig.GMTilesPath
    );
  FfrMobileAtlasTilesPath :=
    TfrPathSelect.Create(
      ALanguageManager,
      gettext_NoOp('MOBAC cache folder:'),
      GState.CacheConfig.MOBACTilesPath
    );
  FfrTMSTilesPath :=
    TfrPathSelect.Create(
      ALanguageManager,
      gettext_NoOp('Tile Map Service (TMS) cache folder:'),
      GState.CacheConfig.TMSTilesPath
    );
  FfrGECachePath :=
    TfrPathSelect.Create(
      ALanguageManager,
      gettext_NoOp('GoogleEarth cache folder:'),
      GState.CacheConfig.GECachePath
    );
  FfrBDBCachePath :=
    TfrPathSelect.Create(
      ALanguageManager,
      gettext_NoOp('BerkeleyDB cache folder:'),
      GState.CacheConfig.BDBCachePath
    );
  FfrBDBVerCachePath :=
    TfrPathSelect.Create(
      ALanguageManager,
      gettext_NoOp('BerkeleyDB (Versioned) cache folder:'),
      GState.CacheConfig.BDBVerCachePath
    );
  FfrSQLiteCachePath :=
    TfrPathSelect.Create(
      ALanguageManager,
      gettext_NoOp('SQLite3 cache folder:'),
      GState.CacheConfig.SQLiteCachePath
    );
  FfrGCCachePath :=
    TfrPathSelect.Create(
      ALanguageManager,
      gettext_NoOp('GeoCacher root folder:'),
      GState.CacheConfig.GCCachePath
    );

  PageControl1.ActivePageIndex := 0;
end;

procedure TfrmSettings.btnCancelClick(Sender: TObject);
begin
  frShortCutList.CancelChanges;
  frMapsList.CancelChanges;
  frFavoriteMapSetManager.CancelChanges;
  frGPSConfig.CancelChanges;
  Close;
end;

procedure TfrmSettings.BtnDefClick(Sender: TObject);
begin
  edtDBMSCachePath.Text := c_File_Cache_Default_DBMS; // without deliiter(s)
end;

procedure TfrmSettings.btnImageProcessResetClick(Sender: TObject);
begin
  TrBarGamma.Position := 50;
  TrBarContrast.Position := 0;
  CBinvertcolor.Checked := False;
end;

procedure TfrmSettings.SetProxy;
var
  VInfo: TInternetProxyInfo;
  VProxyConfig: IProxyConfig;
  VUseIEProxy: Boolean;
  VUseProxy: Boolean;
  VHost: AnsiString;
  VProxyType: TProxyServerType;
begin
  VProxyConfig := GState.Config.InetConfig.ProxyConfig;

  VProxyConfig.LockRead;
  try
    VUseIEProxy := VProxyConfig.GetUseIESettings;
    VUseProxy := VProxyConfig.GetUseProxy;
    VHost := VProxyConfig.GetHost;
    VProxyType := VProxyConfig.ProxyType;
  finally
    VProxyConfig.UnlockRead;
  end;

  if VUseProxy then begin
    if VProxyType = ptSocks4 then begin
      VHost := 'socks=' + VHost;
    end else
    if VProxyType <> ptHttp then begin
      VUseProxy := False;
    end;
  end;

  FillChar(VInfo, SizeOf(VInfo), 0);

  if VUseIEProxy then begin
    VInfo.dwAccessType := INTERNET_OPEN_TYPE_PRECONFIG;
    VInfo.lpszProxy := nil;
    VInfo.lpszProxyBypass := nil;
    UrlMkSetSessionOption(INTERNET_OPTION_PROXY, @VInfo, SizeOf(VInfo), 0);
    UrlMkSetSessionOption(INTERNET_OPTION_REFRESH, nil, 0, 0);
  end else begin
    if VUseProxy then begin
      VInfo.dwAccessType := INTERNET_OPEN_TYPE_PROXY;
      VInfo.lpszProxy := PAnsiChar(VHost);
      VInfo.lpszProxyBypass := nil;
    end else begin
      VInfo.dwAccessType := INTERNET_OPEN_TYPE_DIRECT;
      VInfo.lpszProxy := nil;
      VInfo.lpszProxyBypass := nil;
    end;
    UrlMkSetSessionOption(INTERNET_OPTION_PROXY, @VInfo, SizeOf(VInfo), 0);
    UrlMkSetSessionOption(INTERNET_OPTION_SETTINGS_CHANGED, nil, 0, 0);
  end;
end;

procedure TfrmSettings.ShowGPSSettings;
begin
  tsGPS.Show;
  ShowModal;
end;

procedure TfrmSettings.btnResetUserAgentStringClick(Sender: TObject);
begin
  edtUserAgent.Text := cUserAgent;
end;

procedure TfrmSettings.btnApplyClick(Sender: TObject);
var
  VProxyConfig: IProxyConfig;
  VInetConfig: IInetConfig;
  VNeedReboot: boolean;
  VConnsPerServer: TConnsPerServerRec;
begin
  VNeedReboot := false;

  FMainFormConfig.LayersConfig.MiniMapLayerConfig.MasterAlpha := MiniMapAlphaEdit.Value;

  GState.Config.DownloadConfig.LockWrite;
  try
    GState.Config.DownloadConfig.IsUseSessionLastSuccess := CBLastSuccess.Checked;
    GState.Config.DownloadConfig.IsGoNextTileIfDownloadError := chkProcessNextTile.Checked;
    GState.Config.DownloadConfig.IsSaveTileNotExists := CBSaveTileNotExists.Checked;
  finally
    GState.Config.DownloadConfig.UnlockWrite;
  end;

  GState.Config.ViewConfig.BackGroundColor := ColorBoxBackGround.Selected;
  GState.Config.GlobalAppConfig.IsShowIconInTray := CBMinimizeToTray.Checked;
  GState.Config.MainMemCacheConfig.MaxSize := SETilesOCache.value;
  GState.Config.StartUpLogoConfig.IsShowLogo := ChkShowLogo.Checked;

  FMainFormConfig.LayersConfig.FillingMapLayerConfig.NoTileColor := SetAlpha(Color32(MapZapColorBox.Selected), MapZapAlphaEdit.Value);

  GState.Config.BitmapPostProcessingConfig.LockWrite;
  try
    GState.Config.BitmapPostProcessingConfig.InvertColor := CBinvertcolor.Checked;
    GState.Config.BitmapPostProcessingConfig.GammaN := TrBarGamma.Position;
    GState.Config.BitmapPostProcessingConfig.ContrastN := TrBarContrast.Position;
  finally
    GState.Config.BitmapPostProcessingConfig.UnlockWrite;
  end;
  FMainFormConfig.LayersConfig.MapLayerGridsConfig.LockWrite;
  try
    FMainFormConfig.LayersConfig.MapLayerGridsConfig.TileGrid.GridColor := SetAlpha(Color32(ColorBoxBorder.Selected), SpinEditBorderAlpha.Value);
    FMainFormConfig.LayersConfig.MapLayerGridsConfig.TileGrid.ShowText := CBBorderText.Checked;

    FMainFormConfig.LayersConfig.MapLayerGridsConfig.GenShtabGrid.GridColor := SetAlpha(Color32(GenshtabBoxBorder.Selected), SpinEditGenshtabBorderAlpha.Value);
    FMainFormConfig.LayersConfig.MapLayerGridsConfig.GenShtabGrid.ShowText := CBGenshtabBorderText.Checked;

    FMainFormConfig.LayersConfig.MapLayerGridsConfig.DegreeGrid.GridColor := SetAlpha(Color32(DegreeBoxBorder.Selected), SpinEditDegreeBorderAlpha.Value);
    FMainFormConfig.LayersConfig.MapLayerGridsConfig.DegreeGrid.ShowText := CBDegreeBorderText.Checked;
  finally
    FMainFormConfig.LayersConfig.MapLayerGridsConfig.UnlockWrite;
  end;

  GState.CacheConfig.DefCache := FfrCacheTypesList.IntCode;

  GState.Config.CoordRepresentationConfig.LockWrite;
  try
    GState.Config.CoordRepresentationConfig.IsLatitudeFirst := ChBoxFirstLat.Checked;
    GState.Config.CoordRepresentationConfig.DegrShowFormat := TDegrShowFormat(CB_llstrType.ItemIndex);
    GState.Config.CoordRepresentationConfig.CoordSysType := TCoordSysType(cbbCoordSysType.ItemIndex);
    GState.Config.CoordRepresentationConfig.CoordSysInfoType := TCoordSysInfoType(cbbCoordSysInfoType.ItemIndex);
  finally
    GState.Config.CoordRepresentationConfig.UnlockWrite;
  end;

  GState.Config.ValueToStringConverterConfig.LockWrite;
  try
    GState.Config.ValueToStringConverterConfig.DistStrFormat := TDistStrFormat(ComboBox1.ItemIndex);
    GState.Config.ValueToStringConverterConfig.AreaShowFormat := TAreaStrFormat(cbbAreaFormat.ItemIndex);
  finally
    GState.Config.ValueToStringConverterConfig.UnlockWrite;
  end;

  GState.Config.ImageResamplerConfig.ActiveGUID := GState.ImageResamplerFactoryList.GUIDs[cbbResizeMethod.ItemIndex];
  GState.Config.TileLoadResamplerConfig.ActiveGUID := GState.ImageResamplerFactoryList.GUIDs[cbbResizeOnLoad.ItemIndex];
  GState.Config.TileGetPrevResamplerConfig.ActiveGUID := GState.ImageResamplerFactoryList.GUIDs[cbbResizeGetPre.ItemIndex];
  GState.Config.TileReprojectResamplerConfig.ActiveGUID := GState.ImageResamplerFactoryList.GUIDs[cbbProjectionChange.ItemIndex];
  GState.Config.TileDownloadResamplerConfig.ActiveGUID := GState.ImageResamplerFactoryList.GUIDs[cbbDownloadResize.ItemIndex];
  GState.Config.TileMatrixDraftResamplerConfig.ActiveGUID := GState.ImageResamplerFactoryList.GUIDs[cbbResizeTileMatrixDraft.ItemIndex];

  FMainFormConfig.LayersConfig.GPSMarker.MovedMarkerConfig.LockWrite;
  try
    FMainFormConfig.LayersConfig.GPSMarker.MovedMarkerConfig.MarkerColor := SetAlpha(Color32(ColorBoxGPSstr.selected), 150);
    FMainFormConfig.LayersConfig.GPSMarker.MovedMarkerConfig.MarkerSize := SESizeStr.Value;
    FMainFormConfig.LayersConfig.GPSMarker.MarkerRingsConfig.Count := seGPSMarkerRingsCount.Value;
    FMainFormConfig.LayersConfig.GPSMarker.MarkerRingsConfig.StepDistance := seGPSMarkerRingRadius.Value;
  finally
    FMainFormConfig.LayersConfig.GPSMarker.MovedMarkerConfig.UnlockWrite;
  end;

  FMainFormConfig.ToolbarsLock.IsLock := CBlock_toolbars.Checked;

  // Internet Tab
  VInetConfig := GState.Config.InetConfig;
  VInetConfig.LockWrite;
  try
    if cbbNetworkEngine.ItemIndex <> Integer(VInetConfig.NetworkEngineType) then begin
      VInetConfig.NetworkEngineType := TNetworkEngineType(cbbNetworkEngine.ItemIndex);
      VNeedReboot := True;
    end;

    VProxyConfig := VInetConfig.ProxyConfig;
    if (rbUseIESettings.Checked) and (VProxyConfig.GetUseIESettings <> rbUseIESettings.Checked) then begin
      VNeedReboot := True;
    end;
    VProxyConfig.UseIESettings := rbUseIESettings.Checked;
    VProxyConfig.UseProxy := rbManualProxy.Checked;
    VProxyConfig.Host := StringToAsciiSafe(StrToProxyAddress(EditIP.Text));
    VProxyConfig.UseLogin := CBLogin.Checked;
    VProxyConfig.Login := Trim(EditLogin.Text);
    VProxyConfig.Password := Trim(EditPass.Text);
    VProxyConfig.ProxyType := GetProxyTypeValue;

    SetProxy;

    VInetConfig.SetTimeOut(SETimeOut.Value);
    VInetConfig.SleepOnResetConnection := seSleepOnResetConnection.Value;

    if Trim(edtUserAgent.Text) <> '' then begin
      VInetConfig.UserAgentString := StringToAsciiSafe(Trim(edtUserAgent.Text));
    end;

    if chkRetryIfNoResponse.Checked then begin
      if VInetConfig.DownloadTryCount < 2 then begin
        VInetConfig.DownloadTryCount := 2;
      end;
    end else begin
      VInetConfig.DownloadTryCount := 1;
    end;

    VConnsPerServer := VInetConfig.WinInetConfig.MaxConnsPerServer;
    if seMaxConnsPerServer.Value <> Integer(VConnsPerServer.Value) then begin
      VNeedReboot := True;
      VConnsPerServer.Value := seMaxConnsPerServer.Value;
      VInetConfig.WinInetConfig.MaxConnsPerServer := VConnsPerServer;
      // set same value for proxy
      VConnsPerServer := VInetConfig.WinInetConfig.MaxConnsPerProxy;
      VConnsPerServer.Value := seMaxConnsPerServer.Value;
      VInetConfig.WinInetConfig.MaxConnsPerProxy := VConnsPerServer;
    end;
  finally
    VInetConfig.UnlockWrite;
  end;

  FMainFormConfig.MainConfig.LockWrite;
  try
    FMainFormConfig.MainConfig.ShowMapName := CBShowmapname.Checked;
    FMainFormConfig.MainConfig.MouseScrollInvert := ScrolInvert.Checked;
    FMainFormConfig.MainConfig.ShowHintOnMarks := CBShowHintOnMarks.checked;
  finally
    FMainFormConfig.MainConfig.UnlockWrite;
  end;

  FfrNewCpath.ApplyChanges;
  FfrOldCpath.ApplyChanges;
  FfrESCPath.ApplyChanges;
  FfrGMTilesPath.ApplyChanges;
  FfrMobileAtlasTilesPath.ApplyChanges;
  FfrTMSTilesPath.ApplyChanges;
  FfrGECachePath.ApplyChanges;
  FfrBDBCachePath.ApplyChanges;
  FfrBDBVerCachePath.ApplyChanges;
  FfrSQLiteCachePath.ApplyChanges;
  FfrGCCachePath.ApplyChanges;

  GState.CacheConfig.DBMSCachePath.Path := edtDBMSCachePath.Text; // do not add delimiter(s)

  FfrMapPathSelect.ApplyChanges;
  FfrTerrainDataPathSelect.ApplyChanges;
  FfrUserDataPathSelect.ApplyChanges;
  FfrTrackPathSelect.ApplyChanges;
  FfrMarksIconsPathSelect.ApplyChanges;
  FfrMarksDbPathSelect.ApplyChanges;
  FfrMediaDataPathSelect.ApplyChanges;
  FfrMapSvcScanPathSelect.ApplyChanges;
  FfrBaseCahcePathSelect.ApplyChanges;

  FMainFormConfig.LayersConfig.KmlLayerConfig.DrawConfig.LockWrite;
  try
    FMainFormConfig.LayersConfig.KmlLayerConfig.DrawConfig.MainColor :=
      SetAlpha(
        Color32(CBWMainColor.Selected),
        AlphaComponent(FMainFormConfig.LayersConfig.KmlLayerConfig.DrawConfig.MainColor)
      );
    FMainFormConfig.LayersConfig.KmlLayerConfig.DrawConfig.ShadowColor :=
      SetAlpha(
        Color32(CBWFonColor.Selected),
        AlphaComponent(FMainFormConfig.LayersConfig.KmlLayerConfig.DrawConfig.ShadowColor)
      );
  finally
    FMainFormConfig.LayersConfig.KmlLayerConfig.DrawConfig.UnlockWrite;
  end;

  GState.Config.LanguageManager.SetCurrentLanguageIndex(CBoxLocal.ItemIndex);

  FMainFormConfig.DownloadUIConfig.TilesOut := TilesOverScreenEdit.Value;

  frShortCutList.ApplyChanges;
  frMapsList.ApplyChanges;
  frFavoriteMapSetManager.ApplyChanges;
  frGPSConfig.ApplyChanges;
  if Assigned(FOnSave) then begin
    FOnSave(nil);
  end;
  if VNeedReboot then begin
    MessageDlg(SAS_MSG_need_reload_application_curln, mtInformation, [mbOK], 0);
  end;
end;

procedure TfrmSettings.CBoxLocalChange(Sender: TObject);
begin
  GState.Config.LanguageManager.SetCurrentLanguageIndex(CBoxLocal.ItemIndex);
end;

destructor TfrmSettings.Destroy;
begin
  FreeAndNil(frShortCutList);
  FreeAndNil(frMapsList);
  FreeAndNil(frFavoriteMapSetManager);
  FreeAndNil(frGPSConfig);
  FreeAndNil(FfrMapPathSelect);
  FreeAndNil(FfrTerrainDataPathSelect);
  FreeAndNil(FfrTrackPathSelect);
  FreeAndNil(FfrUserDataPathSelect);
  FreeAndNil(FfrMarksIconsPathSelect);
  FreeAndNil(FfrMarksDbPathSelect);
  FreeAndNil(FfrMediaDataPathSelect);
  FreeAndNil(FfrMapSvcScanPathSelect);
  FreeAndNil(FfrBaseCahcePathSelect);
  FreeAndNil(FfrNewCpath);
  FreeAndNil(FfrOldCpath);
  FreeAndNil(FfrEScPath);
  FreeAndNil(FfrGMTilesPath);
  FreeAndNil(FfrMobileAtlasTilesPath);
  FreeAndNil(FfrTMSTilesPath);
  FreeAndNil(FfrGECachePath);
  FreeAndNil(FfrBDBCachePath);
  FreeAndNil(FfrBDBVerCachePath);
  FreeAndNil(FfrSQLiteCachePath);
  FreeAndNil(FfrGCCachePath);
  FreeAndNil(FfrCacheTypesList);
  inherited;
end;

procedure TfrmSettings.FormShow(Sender: TObject);
var
  VProxyConfig: IProxyConfig;
  VInetConfig: IInetConfig;
  i: Integer;
  VConnsPerServer: TConnsPerServerRec;
begin
  FLinksList.ActivateLinks;

  CBoxLocal.Clear;
  frShortCutList.Parent := GroupBox5;
  frMapsList.Parent := tsMaps;
  frMapsList.Init;
  frFavoriteMapSetManager.Parent := tsFavorite;
  frFavoriteMapSetManager.Init;
  FfrMapPathSelect.Show(pnlMapsPath);
  FfrTerrainDataPathSelect.Show(pnlTerrainDataPath);
  FfrUserDataPathSelect.Show(pnlUserDataPath);
  FfrTrackPathSelect.Show(pnlTrackPath);
  FfrMarksIconsPathSelect.Show(pnlMarksIconsPath);
  FfrMarksDbPathSelect.Show(pnlMarksDbPath);
  FfrMediaDataPathSelect.Show(pnlMediaDataPath);
  FfrMapSvcScanPathSelect.Show(pnlMapSvcScan);
  FfrBaseCahcePathSelect.Show(pnlBaseCahcePath);
  FfrNewCpath.Show(pnlNewCpath);
  FfrOldCpath.Show(pnlOldCpath);
  FfrEScPath.Show(pnlEScPath);
  FfrGMTilesPath.Show(pnlGMTilesPath);
  FfrMobileAtlasTilesPath.Show(pnlMATilesPath);
  FfrTMSTilesPath.Show(pnlTMSPath);
  FfrGECachePath.Show(pnlGECachePath);
  FfrBDBCachePath.Show(pnledtBDBCachePath);
  FfrBDBVerCachePath.Show(pnledtBDBVerCachePath);
  FfrSQLiteCachePath.Show(pnlSQLiteCachePath);
  FfrGCCachePath.Show(pnledtGCCachePath);
  FfrCacheTypesList.Show(pnlCacheTypesList);

  frGPSConfig.Parent := tsGPS;
  frGPSConfig.Init;

  CBoxLocal.Items.Clear;
  for i := 0 to GState.Config.LanguageManager.LanguageList.Count - 1 do begin
    CBoxLocal.Items.Add(GState.Config.LanguageManager.GetLangNameByIndex(i));
  end;
  CBoxLocal.ItemIndex := GState.Config.LanguageManager.GetCurrentLanguageIndex;

  MiniMapAlphaEdit.Value := FMainFormConfig.LayersConfig.MiniMapLayerConfig.MasterAlpha;

  GState.Config.DownloadConfig.LockRead;
  try
    CBLastSuccess.Checked := GState.Config.DownloadConfig.IsUseSessionLastSuccess;
    chkProcessNextTile.Checked := GState.Config.DownloadConfig.IsGoNextTileIfDownloadError;
    CBSaveTileNotExists.Checked := GState.Config.DownloadConfig.IsSaveTileNotExists;
  finally
    GState.Config.DownloadConfig.UnlockRead;
  end;

  ColorBoxBackGround.Selected := GState.Config.ViewConfig.BackGroundColor;

  // Internet Tab
  VInetConfig := GState.Config.InetConfig;
  VInetConfig.LockRead;
  try
    cbbNetworkEngine.Items.Clear;
    cbbNetworkEngine.Items.Add('WinInet');
    cbbNetworkEngine.Items.Add('cURL');
    cbbNetworkEngine.ItemIndex := Integer(VInetConfig.NetworkEngineType);

    chkRetryIfNoResponse.Checked := (VInetConfig.DownloadTryCount > 1);
    SETimeOut.Value := VInetConfig.GetTimeOut;
    seSleepOnResetConnection.Value := VInetConfig.SleepOnResetConnection;
    edtUserAgent.Text := VInetConfig.UserAgentString;

    VProxyConfig := VInetConfig.ProxyConfig;
    rbUseIESettings.Checked := VProxyConfig.GetUseIESettings;
    rbManualProxy.Checked := VProxyConfig.GetUseProxy;
    rbNoProxy.Checked := not rbManualProxy.Checked and not rbUseIESettings.Checked;
    CBLogin.Checked := VProxyConfig.GetUseLogin;
    EditIP.Text := VProxyConfig.GetHost;
    EditLogin.Text := VProxyConfig.GetLogin;
    EditPass.Text := VProxyConfig.GetPassword;
    RefreshProxyTypeComboBox(VInetConfig.NetworkEngineType, VProxyConfig.ProxyType);

    VConnsPerServer := VInetConfig.WinInetConfig.MaxConnsPerServer;
    seMaxConnsPerServer.MinValue := VConnsPerServer.Min;
    seMaxConnsPerServer.MaxValue := VConnsPerServer.Max;
    seMaxConnsPerServer.Value := VConnsPerServer.Value;
  finally
    VInetConfig.UnlockRead;
  end;

  SETilesOCache.Value := GState.Config.MainMemCacheConfig.MaxSize;
  FMainFormConfig.LayersConfig.FillingMapLayerConfig.LockRead;
  try
    MapZapColorBox.Selected := WinColor(FMainFormConfig.LayersConfig.FillingMapLayerConfig.NoTileColor);
    MapZapAlphaEdit.Value := AlphaComponent(FMainFormConfig.LayersConfig.FillingMapLayerConfig.NoTileColor);
  finally
    FMainFormConfig.LayersConfig.FillingMapLayerConfig.UnlockRead;
  end;
  CBlock_toolbars.Checked := FMainFormConfig.ToolbarsLock.GetIsLock;
  GState.Config.BitmapPostProcessingConfig.LockRead;
  try
    CBinvertcolor.Checked := GState.Config.BitmapPostProcessingConfig.InvertColor;
    TrBarGamma.Position := GState.Config.BitmapPostProcessingConfig.GammaN;
    TrBarContrast.Position := GState.Config.BitmapPostProcessingConfig.ContrastN;
  finally
    GState.Config.BitmapPostProcessingConfig.UnlockRead;
  end;
  if TrBarGamma.Position < 50 then begin
    LabelGamma.Caption := SAS_STR_Gamma + ' (' + floattostr((TrBarGamma.Position * 2) / 100) + ')';
  end else begin
    LabelGamma.Caption := SAS_STR_Gamma + ' (' + floattostr((TrBarGamma.Position - 40) / 10) + ')';
  end;
  LabelContrast.Caption := SAS_STR_Contrast + ' (' + inttostr(TrBarContrast.Position) + ')';

  FMainFormConfig.LayersConfig.MapLayerGridsConfig.LockRead;
  try
    ColorBoxBorder.Selected := WinColor(FMainFormConfig.LayersConfig.MapLayerGridsConfig.TileGrid.GridColor);
    SpinEditBorderAlpha.Value := AlphaComponent(FMainFormConfig.LayersConfig.MapLayerGridsConfig.TileGrid.GridColor);
    CBBorderText.Checked := FMainFormConfig.LayersConfig.MapLayerGridsConfig.TileGrid.ShowText;

    GenshtabBoxBorder.Selected := WinColor(FMainFormConfig.LayersConfig.MapLayerGridsConfig.GenShtabGrid.GridColor);
    SpinEditGenshtabBorderAlpha.Value := AlphaComponent(FMainFormConfig.LayersConfig.MapLayerGridsConfig.GenShtabGrid.GridColor);
    CBGenshtabBorderText.Checked := FMainFormConfig.LayersConfig.MapLayerGridsConfig.GenShtabGrid.ShowText;

    DegreeBoxBorder.Selected := WinColor(FMainFormConfig.LayersConfig.MapLayerGridsConfig.DegreeGrid.GridColor);
    SpinEditDegreeBorderAlpha.Value := AlphaComponent(FMainFormConfig.LayersConfig.MapLayerGridsConfig.DegreeGrid.GridColor);
    CBDegreeBorderText.Checked := FMainFormConfig.LayersConfig.MapLayerGridsConfig.DegreeGrid.ShowText;
  finally
    FMainFormConfig.LayersConfig.MapLayerGridsConfig.UnlockRead;
  end;

  FMainFormConfig.MainConfig.LockRead;
  try
    CBShowmapname.Checked := FMainFormConfig.MainConfig.ShowMapName;
    ScrolInvert.Checked := FMainFormConfig.MainConfig.MouseScrollInvert;
    CBShowHintOnMarks.checked := FMainFormConfig.MainConfig.ShowHintOnMarks;
  finally
    FMainFormConfig.MainConfig.UnlockRead;
  end;

  FfrCacheTypesList.IntCode := GState.CacheConfig.DefCache;
  edtDBMSCachePath.text := GState.CacheConfig.DBMSCachePath.Path;

  FMainFormConfig.LayersConfig.GPSMarker.MovedMarkerConfig.LockRead;
  try
    ColorBoxGPSstr.Selected := WinColor(FMainFormConfig.LayersConfig.GPSMarker.MovedMarkerConfig.MarkerColor);
    SESizeStr.Value := FMainFormConfig.LayersConfig.GPSMarker.MovedMarkerConfig.MarkerSize;
    seGPSMarkerRingsCount.Value := FMainFormConfig.LayersConfig.GPSMarker.MarkerRingsConfig.Count;
    seGPSMarkerRingRadius.Value := Trunc(FMainFormConfig.LayersConfig.GPSMarker.MarkerRingsConfig.StepDistance);
  finally
    FMainFormConfig.LayersConfig.GPSMarker.MovedMarkerConfig.UnlockRead;
  end;

  InitResamplersList(GState.ImageResamplerFactoryList, cbbResizeMethod);
  cbbResizeMethod.ItemIndex := GState.ImageResamplerFactoryList.GetIndexByGUID(GState.Config.ImageResamplerConfig.ActiveGUID);

  InitResamplersList(GState.ImageResamplerFactoryList, cbbResizeOnLoad);
  cbbResizeOnLoad.ItemIndex := GState.ImageResamplerFactoryList.GetIndexByGUID(GState.Config.TileLoadResamplerConfig.ActiveGUID);

  InitResamplersList(GState.ImageResamplerFactoryList, cbbResizeGetPre);
  cbbResizeGetPre.ItemIndex := GState.ImageResamplerFactoryList.GetIndexByGUID(GState.Config.TileGetPrevResamplerConfig.ActiveGUID);

  InitResamplersList(GState.ImageResamplerFactoryList, cbbProjectionChange);
  cbbProjectionChange.ItemIndex := GState.ImageResamplerFactoryList.GetIndexByGUID(GState.Config.TileReprojectResamplerConfig.ActiveGUID);

  InitResamplersList(GState.ImageResamplerFactoryList, cbbDownloadResize);
  cbbDownloadResize.ItemIndex := GState.ImageResamplerFactoryList.GetIndexByGUID(GState.Config.TileDownloadResamplerConfig.ActiveGUID);

  InitResamplersList(GState.ImageResamplerFactoryList, cbbResizeTileMatrixDraft);
  cbbResizeTileMatrixDraft.ItemIndex := GState.ImageResamplerFactoryList.GetIndexByGUID(GState.Config.TileMatrixDraftResamplerConfig.ActiveGUID);

  InitCoordRepresentationList;

  GState.Config.CoordRepresentationConfig.LockRead;
  try
    ChBoxFirstLat.Checked := GState.Config.CoordRepresentationConfig.IsLatitudeFirst;
    CB_llstrType.ItemIndex := byte(GState.Config.CoordRepresentationConfig.DegrShowFormat);
    cbbCoordSysType.ItemIndex := byte(GState.Config.CoordRepresentationConfig.CoordSysType);
    cbbCoordSysInfoType.ItemIndex := byte(GState.Config.CoordRepresentationConfig.CoordSysInfoType);
  finally
    GState.Config.CoordRepresentationConfig.UnlockRead;
  end;

  GState.Config.ValueToStringConverterConfig.LockRead;
  try
    ComboBox1.ItemIndex := byte(GState.Config.ValueToStringConverterConfig.DistStrFormat);
    cbbAreaFormat.ItemIndex := byte(GState.Config.ValueToStringConverterConfig.AreaShowFormat);
  finally
    GState.Config.ValueToStringConverterConfig.UnlockRead;
  end;
  FMainFormConfig.LayersConfig.KmlLayerConfig.DrawConfig.LockRead;
  try
    CBWMainColor.Selected := WinColor(FMainFormConfig.LayersConfig.KmlLayerConfig.DrawConfig.MainColor);
    CBWFonColor.Selected := WinColor(FMainFormConfig.LayersConfig.KmlLayerConfig.DrawConfig.ShadowColor);
  finally
    FMainFormConfig.LayersConfig.KmlLayerConfig.DrawConfig.UnlockRead;
  end;

  TilesOverScreenEdit.Value := FMainFormConfig.DownloadUIConfig.TilesOut;
  CBMinimizeToTray.Checked := GState.Config.GlobalAppConfig.IsShowIconInTray;
  ChkShowLogo.Checked := GState.Config.StartUpLogoConfig.IsShowLogo;

  rbProxyClick(Self);
end;

procedure TfrmSettings.FormCloseQuery(
  Sender: TObject;
  var CanClose: Boolean
);
begin
  CanClose := frGPSConfig.CanClose;
end;

procedure TfrmSettings.TrBarGammaChange(Sender: TObject);
begin
  if TrBarGamma.Position < 50 then begin
    LabelGamma.Caption := SAS_STR_Gamma + ' (' + floattostr((TrBarGamma.Position * 2) / 100) + ')';
  end else begin
    LabelGamma.Caption := SAS_STR_Gamma + ' (' + floattostr((TrBarGamma.Position - 40) / 10) + ')';
  end;
end;

procedure TfrmSettings.TrBarContrastChange(Sender: TObject);
begin
  LabelContrast.Caption := SAS_STR_Contrast + ' (' + inttostr(TrBarContrast.Position) + ')';
end;

procedure TfrmSettings.RefreshTranslation;
begin
  inherited;
  FormShow(Self);
end;

procedure TfrmSettings.InitCoordRepresentationList;
var
  I: TDegrShowFormat;
  VCaption: TDegrShowFormatCaption;
begin
  VCaption := GetDegrShowFormatCaption;
  CB_llstrType.Clear;
  for I := Low(TDegrShowFormat) to High(TDegrShowFormat) do begin
    CB_llstrType.Items.Add(VCaption[I]);
  end;
end;

procedure TfrmSettings.InitResamplersList(
  const AList: IImageResamplerFactoryList;
  ABox: TComboBox
);
var
  i: Integer;
begin
  ABox.Items.Clear;
  for i := 0 to AList.Count - 1 do begin
    ABox.Items.Add(AList.Captions[i]);
  end;
end;

procedure TfrmSettings.rbProxyClick(Sender: TObject);
var
  VIsManual: Boolean;
begin
  VIsManual := rbManualProxy.Checked;

  cbbProxyType.Enabled := VIsManual;
  EditIP.Enabled := VIsManual;

  CBLogin.Enabled := VIsManual;
  CBLoginClick(Sender);
end;

procedure TfrmSettings.CBLoginClick(Sender: TObject);
var
  VUseAuth: Boolean;
begin
  VUseAuth := CBLogin.Enabled and CBLogin.Checked;

  lblProxyLogin.Enabled := VUseAuth;
  EditLogin.Enabled := VUseAuth;

  lblProxyPass.Enabled := VUseAuth;
  EditPass.Enabled := VUseAuth;
end;

function TfrmSettings.GetProxyTypeValue: TProxyServerType;
begin
  if cbbNetworkEngine.ItemIndex = 0 then begin
    if cbbProxyType.ItemIndex = 1 then begin
      Result := ptSocks4;
    end else begin
      Result := ptHttp;
    end;
  end else begin
    Result := TProxyServerType(cbbProxyType.ItemIndex);
  end;
end;

procedure TfrmSettings.RefreshProxyTypeComboBox(
  const ANetworkEngineType: TNetworkEngineType;
  const AProxyType: TProxyServerType
);
const
  cWinInetItems: array [0..1] of string = (
    'HTTP', 'SOCKS4'
  );
  cCurlItems: array [0..5] of string = (
    'HTTP', 'HTTPS', 'SOCKS4', 'SOCKS4A', 'SOCKS5', 'SOCKS5H'
  );

  procedure AddItems(const AItems: array of string);
  var
    I: Integer;
  begin
    cbbProxyType.Items.Clear;
    for I := 0 to Length(AItems) - 1 do begin
      cbbProxyType.Items.Add(AItems[I]);
    end;
    cbbProxyType.ItemIndex := 0;
  end;

begin
  case ANetworkEngineType of
    neWinInet: begin
      AddItems(cWinInetItems);
      if AProxyType = ptSocks4 then begin
        cbbProxyType.ItemIndex := 1;
      end;
    end;
    neCurl: begin
      AddItems(cCurlItems);
      cbbProxyType.ItemIndex := Integer(AProxyType);
    end
  else
    raise Exception.CreateFmt(
      'Unexpected NetworkEngineType: %d', [Integer(ANetworkEngineType)]
    );
  end;
end;

procedure TfrmSettings.cbbNetworkEngineChange(Sender: TObject);
begin
  RefreshProxyTypeComboBox(TNetworkEngineType(cbbNetworkEngine.ItemIndex), ptHttp);
end;

function TfrmSettings.StrToProxyAddress(const AStr: string): string;
var
  I: Integer;
begin
  Result := Trim(AStr);

  I := Pos('=', Result);
  if I > 0 then begin
    Delete(Result, 1, I);
  end;

  I := Pos('://', Result);
  if I > 0 then begin
    Delete(Result, 1, I+2);
  end;
end;

end.

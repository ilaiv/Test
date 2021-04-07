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

unit fr_TilesCopy;

interface

uses
  Types,
  SysUtils,
  Classes,
  Controls,
  Forms,
  StdCtrls,
  CheckLst,
  ComCtrls,
  Spin,
  ExtCtrls,
  fr_MapSelect,
  fr_ZoomsSelect,
  fr_CacheTypeList,
  i_LanguageManager,
  i_MapType,
  i_MapVersionRequest,
  i_MapTypeSet,
  i_MapTypeListStatic,
  i_MapTypeListBuilder,
  i_ActiveMapsConfig,
  i_MapTypeGUIConfigList,
  i_MapTypeListChangeable,
  i_GeometryLonLat,
  i_ContentTypeInfo,
  i_ContentTypeManager,
  i_BitmapTileSaveLoad,
  i_BitmapLayerProvider,
  i_Bitmap32BufferFactory,
  i_BitmapTileSaveLoadFactory,
  i_TileStorageTypeList,
  i_RegionProcessParamsFrame,
  u_CommonFormAndFrameParents;

type
  IRegionProcessParamsFrameTilesCopy = interface(IRegionProcessParamsFrameBase)
    ['{71851148-93F1-42A9-ADAC-757928C5C85A}']
    function GetReplaseTarget: Boolean;
    property ReplaseTarget: Boolean read GetReplaseTarget;

    function GetDeleteSource: Boolean;
    property DeleteSource: Boolean read GetDeleteSource;

    function GetTargetCacheType: Byte;
    property TargetCacheType: Byte read GetTargetCacheType;

    function GetMapTypeList: IMapTypeListStatic;
    property MapTypeList: IMapTypeListStatic read GetMapTypeList;

    function GetPlaceInNameSubFolder: Boolean;
    property PlaceInNameSubFolder: Boolean read GetPlaceInNameSubFolder;

    function GetSetTargetVersionEnabled: Boolean;
    property SetTargetVersionEnabled: Boolean read GetSetTargetVersionEnabled;

    function GetSetTargetVersionValue: String;
    property SetTargetVersionValue: String read GetSetTargetVersionValue;

    // For modifications
    function GetMapSource: IMapType;
    property MapSource: IMapType read GetMapSource;

    function GetOverlay: IMapType;
    property Overlay: IMapType read GetOverlay;

    function GetBitmapTileSaver: IBitmapTileSaver;
    property BitmapTileSaver: IBitmapTileSaver read GetBitmapTileSaver;

    function GetContentType: IContentTypeInfoBasic;
    property ContentType: IContentTypeInfoBasic read GetContentType;
  end;

type
  TfrTilesCopy = class(
      TFrame,
      IRegionProcessParamsFrameBase,
      IRegionProcessParamsFrameZoomArray,
      IRegionProcessParamsFrameTargetPath,
      IRegionProcessParamsFrameTilesCopy,
      IRegionProcessParamsFrameImageProvider
    )
    pnlCenter: TPanel;
    pnlZoom: TPanel;
    pnlMain: TPanel;
    lblNamesType: TLabel;
    pnlCacheTypes: TPanel;
    pnlTop: TPanel;
    lblTargetPath: TLabel;
    btnSelectTargetPath: TButton;
    chkReplaseTarget: TCheckBox;
    Panel1: TPanel;
    chkSetTargetVersionTo: TCheckBox;
    edSetTargetVersionValue: TEdit;
    pnSetTargetVersionOptions: TPanel;
    pcSource: TPageControl;
    tsDirectCopy: TTabSheet;
    tsOverlay: TTabSheet;
    chklstMaps: TCheckListBox;
    chkAllMaps: TCheckBox;
    lblOverlay: TLabel;
    pnlOverlay: TPanel;
    chkDeleteSource: TCheckBox;
    pnlImageFormat: TPanel;
    lblJpgQulity: TLabel;
    lblCompression: TLabel;
    seJpgQuality: TSpinEdit;
    seCompression: TSpinEdit;
    pnlMap: TPanel;
    lblMap: TLabel;
    chkPlaceInNameSubFolder: TCheckBox;
    lblImageFormat: TLabel;
    cbbImageFormat: TComboBox;
    chkAddVisibleLayers: TCheckBox;
    cbbTargetPath: TComboBox;
    procedure btnSelectTargetPathClick(Sender: TObject);
    procedure OnCacheTypeChange(Sender: TObject);
    procedure chkSetTargetVersionToClick(Sender: TObject);
    procedure chkAllMapsClick(Sender: TObject);
    procedure cbbImageFormatChange(Sender: TObject);
    procedure chkAddVisibleLayersClick(Sender: TObject);
  private
    FBitmap32StaticFactory: IBitmap32StaticFactory;
    FBitmapTileSaveLoadFactory: IBitmapTileSaveLoadFactory;
    FMapTypeListBuilderFactory: IMapTypeListBuilderFactory;
    FContentTypeManager: IContentTypeManager;
    FMainMapConfig: IActiveMapConfig;
    FFullMapsSet: IMapTypeSet;
    FActiveMapsList: IMapTypeListChangeable;
    FGUIConfigList: IMapTypeGUIConfigList;
    FfrMapSelect: TfrMapSelect;
    FfrOverlaySelect: TfrMapSelect;
    FfrZoomsSelect: TfrZoomsSelect;
    FfrCacheTypeList: TfrCacheTypeList;
  private
    procedure Init(
      const AZoom: byte;
      const APolygon: IGeometryLonLatPolygon
    );
    function Validate: Boolean;
    procedure UpdateSetTargetVersionState;
    function GetSelectedLayer: IMapType;
  private
    function GetZoomArray: TByteDynArray;
    function GetPath: string;
  private
    function GetAllowCopy(const AMapType: IMapType): Boolean;
    { IRegionProcessParamsFrameTilesCopy }
    function GetReplaseTarget: Boolean;
    function GetDeleteSource: Boolean;
    function GetTargetCacheType: Byte;
    function GetMapTypeList: IMapTypeListStatic;
    function GetPlaceInNameSubFolder: Boolean;
    function GetSetTargetVersionEnabled: Boolean;
    function GetSetTargetVersionValue: String;

    function GetMapSource: IMapType;
    function GetOverlay: IMapType;
    function GetProvider: IBitmapTileUniProvider;
    function GetBitmapTileSaver: IBitmapTileSaver;
    function GetContentType: IContentTypeInfoBasic;
  public
    constructor Create(
      const ALanguageManager: ILanguageManager;
      const AMapSelectFrameBuilder: IMapSelectFrameBuilder;
      const AActiveMapsList: IMapTypeListChangeable;
      const AMapTypeListBuilderFactory: IMapTypeListBuilderFactory;
      const AMainMapConfig: IActiveMapConfig;
      const AFullMapsSet: IMapTypeSet;
      const AGUIConfigList: IMapTypeGUIConfigList;
      const ATileStorageTypeList: ITileStorageTypeListStatic;
      const ABitmap32StaticFactory: IBitmap32StaticFactory;
      const ABitmapTileSaveLoadFactory: IBitmapTileSaveLoadFactory;
      const AContentTypeManager: IContentTypeManager
    ); reintroduce;
    destructor Destroy; override;
  end;

implementation

uses
  Dialogs,
  gnugettext,
  {$WARN UNIT_PLATFORM OFF}
  FileCtrl,
  {$WARN UNIT_PLATFORM ON}
  c_CacheTypeCodes, // for cache types
  i_TileStorageAbilities,
  u_BitmapLayerProviderMapWithLayer,
  i_GUIDListStatic;

{$R *.dfm}

constructor TfrTilesCopy.Create(
  const ALanguageManager: ILanguageManager;
  const AMapSelectFrameBuilder: IMapSelectFrameBuilder;
  const AActiveMapsList: IMapTypeListChangeable;
  const AMapTypeListBuilderFactory: IMapTypeListBuilderFactory;
  const AMainMapConfig: IActiveMapConfig;
  const AFullMapsSet: IMapTypeSet;
  const AGUIConfigList: IMapTypeGUIConfigList;
  const ATileStorageTypeList: ITileStorageTypeListStatic;
  const ABitmap32StaticFactory: IBitmap32StaticFactory;
  const ABitmapTileSaveLoadFactory: IBitmapTileSaveLoadFactory;
  const AContentTypeManager: IContentTypeManager
);
begin
  inherited Create(ALanguageManager);
  FActiveMapsList := AActiveMapsList;
  FMainMapConfig := AMainMapConfig;
  FMapTypeListBuilderFactory := AMapTypeListBuilderFactory;
  FFullMapsSet := AFullMapsSet;
  FGUIConfigList := AGUIConfigList;
  FBitmap32StaticFactory := ABitmap32StaticFactory;
  FBitmapTileSaveLoadFactory := ABitmapTileSaveLoadFactory;
  FContentTypeManager := AContentTypeManager;
  FfrCacheTypeList :=
    TfrCacheTypeList.Create(
      ALanguageManager,
      ATileStorageTypeList,
      False,
      CTileStorageTypeClassAll - [tstcInMemory],
      [tsacAdd],
      Self.OnCacheTypeChange
    );
  FfrMapSelect :=
    AMapSelectFrameBuilder.Build(
      mfMaps,          // show maps
      True,            // add -NO- to combobox
      False,           // show disabled map
      GetAllowCopy
    );
  FfrOverlaySelect :=
    AMapSelectFrameBuilder.Build(
      mfLayers,        // show layers
      True,            // add -NO- to combobox
      False,           // show disabled map
      GetAllowCopy
    );
  FfrZoomsSelect :=
    TfrZoomsSelect.Create(
      ALanguageManager
    );
  FfrZoomsSelect.Init(0, 23);
  pcSource.ActivePageIndex := 0;
end;

destructor TfrTilesCopy.Destroy;
begin
  FreeAndNil(FfrMapSelect);
  FreeAndNil(FfrOverlaySelect);
  FreeAndNil(FfrZoomsSelect);
  FreeAndNil(FfrCacheTypeList);
  inherited;
end;

procedure TfrTilesCopy.btnSelectTargetPathClick(Sender: TObject);
var
  TempPath: String;
  i: Integer;
  vFind: Boolean;
begin
  if SelectDirectory('', '', TempPath) then begin
    cbbTargetPath.Text := IncludeTrailingPathDelimiter(TempPath);
    vFind := False;
    if cbbTargetPath.Items.Count > 0 then     
      for i := 0 to cbbTargetPath.Items.Count - 1 do
       if cbbTargetPath.Items.ValueFromIndex[i] = cbbTargetPath.Text then vFind := True;
    if not vFind then cbbTargetPath.Items.Add(cbbTargetPath.Text)
  end;
end;

procedure TfrTilesCopy.OnCacheTypeChange(Sender: TObject);
var
  VIntCode: Byte;
  VAllowSetVersion: Boolean;
begin
  VIntCode := GetTargetCacheType;
  VAllowSetVersion := (VIntCode in [c_File_Cache_Id_DBMS, c_File_Cache_Id_BDB_Versioned, c_File_Cache_Id_SQLite]);
  chkSetTargetVersionTo.Enabled := VAllowSetVersion;
  UpdateSetTargetVersionState;
end;

procedure TfrTilesCopy.cbbImageFormatChange(Sender: TObject);
var
  VValue: Boolean;
begin
  VValue := not (cbbImageFormat.ItemIndex <= 0) and cbbImageFormat.Enabled;

  lblJpgQulity.Enabled := VValue;
  seJpgQuality.Enabled := VValue;

  lblCompression.Enabled := VValue;
  seCompression.Enabled := VValue;
end;

procedure TfrTilesCopy.chkAddVisibleLayersClick(Sender: TObject);
begin
  FfrOverlaySelect.SetEnabled(not chkAddVisibleLayers.Checked);
end;

procedure TfrTilesCopy.chkAllMapsClick(Sender: TObject);
var
  i: byte;
begin
  if chkAllMaps.state <> cbGrayed then begin
    for i := 0 to chklstMaps.Count - 1 do begin
      if chklstMaps.ItemEnabled[i]// Select only enabled items
        or (not TCheckBox(Sender).Checked and chklstMaps.Checked[i]) // deselect disabled items
      then begin
        chklstMaps.Checked[i] := TCheckBox(Sender).Checked;
      end;
    end;
  end;
end;

procedure TfrTilesCopy.chkSetTargetVersionToClick(Sender: TObject);
begin
  UpdateSetTargetVersionState;
end;

function TfrTilesCopy.GetAllowCopy(const AMapType: IMapType): Boolean;
begin
  Result := AMapType.IsBitmapTiles;
end;

function TfrTilesCopy.GetSelectedLayer: IMapType;
var
  VActiveMapsSet: IMapTypeListStatic;
begin
  if chkAddVisibleLayers.Checked then begin
    VActiveMapsSet := FActiveMapsList.List;
    if Assigned(VActiveMapsSet) and (VActiveMapsSet.Count > 0) then begin
      Result := VActiveMapsSet.Items[0];
    end else begin
      Result := nil;
    end;
  end else begin
    Result := FfrOverlaySelect.GetSelectedMapType;
  end;
end;

function TfrTilesCopy.GetBitmapTileSaver: IBitmapTileSaver;

  function _GetSaver(const AMap: IMapType): IBitmapTileSaver;
  var
    VContentType: IContentTypeInfoBitmap;
  begin
    Result := nil;
    if Assigned(AMap) then begin
      if Supports(AMap.ContentType, IContentTypeInfoBitmap, VContentType) then begin
        Result := VContentType.GetSaver;
      end;
    end;
  end;

begin
  if pcSource.ActivePageIndex = 0 then begin
    Result := nil;
    Exit;
  end;

  if cbbImageFormat.ItemIndex <= 0 then begin
    Result := _GetSaver(FfrMapSelect.GetSelectedMapType);
    if not Assigned(Result) then begin
      Result := _GetSaver(GetSelectedLayer);
    end;
  end else begin
    case cbbImageFormat.ItemIndex of
      1: Result := FBitmapTileSaveLoadFactory.CreateJpegSaver(seJpgQuality.Value);
      2: Result := FBitmapTileSaveLoadFactory.CreateBmpSaver;
      3: Result := FBitmapTileSaveLoadFactory.CreateGifSaver;
      4: Result := FBitmapTileSaveLoadFactory.CreatePngSaver(i8bpp, seCompression.Value);
      5: Result := FBitmapTileSaveLoadFactory.CreatePngSaver(i24bpp, seCompression.Value);
      6: Result := FBitmapTileSaveLoadFactory.CreatePngSaver(i32bpp, seCompression.Value);
    end;
  end;
  if not Assigned(Result) then begin
    Assert(False, 'Unexpected result!');
    Result := FBitmapTileSaveLoadFactory.CreateJpegSaver;
  end;
end;

function TfrTilesCopy.GetContentType: IContentTypeInfoBasic;

  function _GetContentType(const AMap: IMapType): IContentTypeInfoBasic;
  begin
    Result := nil;
    if Assigned(AMap) then begin
      Supports(AMap.ContentType, IContentTypeInfoBitmap, Result);
    end;
  end;

begin
  if pcSource.ActivePageIndex = 0 then begin
    Result := nil;
    Exit;
  end;

  if cbbImageFormat.ItemIndex <= 0 then begin
    Result := _GetContentType(FfrMapSelect.GetSelectedMapType);
    if not Assigned(Result) then begin
      Result := _GetContentType(GetSelectedLayer);
    end;
  end else begin
    case cbbImageFormat.ItemIndex of
      1: Result := FContentTypeManager.GetInfo('image/jpeg');
      2: Result := FContentTypeManager.GetInfo('image/bmp');
      3: Result := FContentTypeManager.GetInfo('image/gif');
      4..6: Result := FContentTypeManager.GetInfo('image/png');
    end;
  end;
  if not Assigned(Result) then begin
    Assert(False, 'Unexpected result!');
    Result := FContentTypeManager.GetInfo('image/jpeg');
  end;
end;

function TfrTilesCopy.GetDeleteSource: Boolean;
begin
  if pcSource.ActivePageIndex = 0 then begin
    Result := chkDeleteSource.Checked;
  end else begin
    Result := False;
  end;
end;

function TfrTilesCopy.GetMapSource: IMapType;
begin
  Result := FfrMapSelect.GetSelectedMapType;
  if not Assigned(Result) then begin
    Result := GetSelectedLayer;
  end;
end;

function TfrTilesCopy.GetMapTypeList: IMapTypeListStatic;
var
  VMaps: IMapTypeListBuilder;
  VMapType: IMapType;
  i: Integer;
begin
  if pcSource.ActivePageIndex <> 0 then begin
    Result := nil;
    Exit;
  end;

  VMaps := FMapTypeListBuilderFactory.Build;
  for i := 0 to chklstMaps.Items.Count - 1 do begin
    if chklstMaps.Checked[i] then begin
      VMapType := IMapType(Pointer(chklstMaps.Items.Objects[i]));
      if VMapType <> nil then begin
        VMaps.Add(VMapType);
      end;
    end;
  end;
  Result := VMaps.MakeAndClear;
end;

function TfrTilesCopy.GetOverlay: IMapType;
begin
  Result := nil;
  if (pcSource.ActivePageIndex <> 0) and not chkAddVisibleLayers.Checked then begin
    Result := FfrOverlaySelect.GetSelectedMapType;
  end;
end;

function TfrTilesCopy.GetPath: string;
begin
  Result := cbbTargetPath.Text;
end;

function TfrTilesCopy.GetPlaceInNameSubFolder: Boolean;
begin
  Result := chkPlaceInNameSubFolder.Checked;
end;

function TfrTilesCopy.GetProvider: IBitmapTileUniProvider;
var
  VMap: IMapType;
  VMapVersion: IMapVersionRequest;
  VLayer: IMapType;
  VLayerVersion: IMapVersionRequest;
  VActiveMapsSet: IMapTypeListStatic;
begin
  if pcSource.ActivePageIndex = 0 then begin
    Result := nil;
  end;

  VMap := FfrMapSelect.GetSelectedMapType;
  if Assigned(VMap) then begin
    VMapVersion := VMap.VersionRequest.GetStatic;
  end else begin
    VMapVersion := nil;
  end;

  VLayer := FfrOverlaySelect.GetSelectedMapType;
  if Assigned(VLayer) then begin
    VLayerVersion := VLayer.VersionRequest.GetStatic;
  end else begin
    VLayerVersion := nil;
  end;

  if chkAddVisibleLayers.Checked then begin
    VLayer := nil;
    VLayerVersion := nil;
    VActiveMapsSet := FActiveMapsList.List;
  end else begin
    VActiveMapsSet := nil;
  end;

  Result :=
    TBitmapLayerProviderMapWithLayer.Create(
      FBitmap32StaticFactory,
      VMap,
      VMapVersion,
      VLayer,
      VLayerVersion,
      VActiveMapsSet,
      False,
      False
    );
end;

function TfrTilesCopy.GetReplaseTarget: Boolean;
begin
  Result := chkReplaseTarget.Checked;
end;

function TfrTilesCopy.GetSetTargetVersionEnabled: Boolean;
begin
  Result := chkSetTargetVersionTo.Enabled and chkSetTargetVersionTo.Checked;
end;

function TfrTilesCopy.GetSetTargetVersionValue: String;
begin
  Result := Trim(edSetTargetVersionValue.Text);
end;

function TfrTilesCopy.GetTargetCacheType: Byte;
begin
  Result := Byte(FfrCacheTypeList.IntCode);
end;

function TfrTilesCopy.GetZoomArray: TByteDynArray;
begin
  Result := FfrZoomsSelect.GetZoomList;
end;

procedure TfrTilesCopy.Init;
var
  i: integer;
  VMapType: IMapType;
  VActiveMapGUID: TGUID;
  VAddedIndex: Integer;
  VGUIDList: IGUIDListStatic;
  VGUID: TGUID;
begin
  FfrMapSelect.Show(pnlMap);
  FfrOverlaySelect.Show(pnlOverlay);
  FfrZoomsSelect.Show(pnlZoom);
  FfrCacheTypeList.Show(pnlCacheTypes);
  FfrCacheTypeList.IntCode := c_File_Cache_Id_SAS;
  VActiveMapGUID := FMainMapConfig.MainMapGUID;
  chklstMaps.Items.Clear;
  VGUIDList := FGUIConfigList.OrderedMapGUIDList;
  For i := 0 to VGUIDList.Count - 1 do begin
    VGUID := VGUIDList.Items[i];
    VMapType := FFullMapsSet.GetMapTypeByGUID(VGUID);
    if (VMapType.GUIConfig.Enabled) then begin
      VAddedIndex := chklstMaps.Items.AddObject(VMapType.GUIConfig.Name.Value, TObject(Pointer(VMapType)));
      if IsEqualGUID(VMapType.Zmp.GUID, VActiveMapGUID) then begin
        chklstMaps.ItemIndex := VAddedIndex;
        chklstMaps.Checked[VAddedIndex] := True;
      end;
    end;
  end;
  FfrOverlaySelect.cbbMap.ItemIndex := 0;
  cbbImageFormat.ItemIndex := 0;
  cbbImageFormatChange(nil);
end;

procedure TfrTilesCopy.UpdateSetTargetVersionState;
begin
  edSetTargetVersionValue.Enabled := chkSetTargetVersionTo.Enabled and chkSetTargetVersionTo.Checked;
end;

function TfrTilesCopy.Validate: Boolean;
var
  VMaps: IMapTypeListStatic;
begin
  Result := (cbbTargetPath.Text <> '');
  if not Result then begin
    ShowMessage(_('Please select output folder'));
    Exit;
  end;

  Result := FfrZoomsSelect.Validate;
  if not Result then begin
    ShowMessage(_('Please select at least one zoom'));
    Exit;
  end;

  if pcSource.ActivePageIndex = 0 then begin
    VMaps := GetMapTypeList;
    Result := Assigned(VMaps) and (VMaps.Count > 0);
    if not Result then begin
      ShowMessage(_('Please select at least one map'));
      Exit;
    end;
  end;
end;

end.

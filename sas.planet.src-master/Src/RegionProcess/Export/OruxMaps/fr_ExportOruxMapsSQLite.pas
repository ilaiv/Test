{******************************************************************************}
{* SAS.Planet (SAS.�������)                                                   *}
{* Copyright (C) 2007-2015, SAS.Planet development team.                      *}
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

unit fr_ExportOruxMapsSQLite;

interface

uses
  Types,
  SysUtils,
  Classes,
  Controls,
  Forms,
  Dialogs,
  StdCtrls,
  ExtCtrls,
  Spin,
  i_LanguageManager,
  i_GeometryLonLat,
  i_RegionProcessParamsFrame,
  i_Bitmap32BufferFactory,
  i_BitmapLayerProvider,
  i_BitmapTileSaveLoad,
  i_BitmapTileSaveLoadFactory,
  i_MapType,
  i_BinaryData,
  i_MapTypeListChangeable,
  fr_MapSelect,
  fr_ZoomsSelect,
  u_CommonFormAndFrameParents;

type
  IRegionProcessParamsFrameOruxMapsSQLiteExport = interface(IRegionProcessParamsFrameBase)
    ['{AF048EAA-5AE3-45CD-94FD-443DFCB580B6}']
    function GetDirectTilesCopy: Boolean;
    property DirectTilesCopy: Boolean read GetDirectTilesCopy;

    function GetBlankTile: IBinaryData;
    property BlankTile: IBinaryData read GetBlankTile;

    function GetBitmapTileSaver: IBitmapTileSaver;
    property BitmapTileSaver: IBitmapTileSaver read GetBitmapTileSaver;
  end;

type
  TfrExportOruxMapsSQLite = class(
      TFrame,
      IRegionProcessParamsFrameBase,
      IRegionProcessParamsFrameZoomArray,
      IRegionProcessParamsFrameTargetPath,
      IRegionProcessParamsFrameOneMap,
      IRegionProcessParamsFrameImageProvider,
      IRegionProcessParamsFrameOruxMapsSQLiteExport
    )
    pnlCenter: TPanel;
    pnlTop: TPanel;
    lblTargetPath: TLabel;
    edtTargetPath: TEdit;
    btnSelectTargetPath: TButton;
    pnlMain: TPanel;
    lblMap: TLabel;
    pnlMap: TPanel;
    PnlZoom: TPanel;
    lblOverlay: TLabel;
    pnlOverlay: TPanel;
    pnlImageFormat: TPanel;
    seJpgQuality: TSpinEdit;
    lblJpgQulity: TLabel;
    cbbImageFormat: TComboBox;
    lblImageFormat: TLabel;
    seCompression: TSpinEdit;
    lblCompression: TLabel;
    chkUsePrevZoom: TCheckBox;
    chkStoreBlankTiles: TCheckBox;
    chkAddVisibleLayers: TCheckBox;
    procedure btnSelectTargetPathClick(Sender: TObject);
    procedure cbbImageFormatChange(Sender: TObject);
    procedure chkAddVisibleLayersClick(Sender: TObject);
  private
    FLastPath: string;
    FBitmap32StaticFactory: IBitmap32StaticFactory;
    FBitmapTileSaveLoadFactory: IBitmapTileSaveLoadFactory;
    FActiveMapsList: IMapTypeListChangeable;
    FfrMapSelect: TfrMapSelect;
    FfrOverlaySelect: TfrMapSelect;
    FfrZoomsSelect: TfrZoomsSelect;
  private
    procedure Init(
      const AZoom: byte;
      const APolygon: IGeometryLonLatPolygon
    );
    function Validate: Boolean;
  private
    function GetMapType: IMapType;
    function GetZoomArray: TByteDynArray;
    function GetPath: string;
    function GetDirectTilesCopy: Boolean;
    function GetAllowExport(const AMapType: IMapType): Boolean;
    function GetProvider: IBitmapTileUniProvider;
    function GetBitmapTileSaver: IBitmapTileSaver;
    function GetBlankTile: IBinaryData;
  public
    constructor Create(
      const ALanguageManager: ILanguageManager;
      const AMapSelectFrameBuilder: IMapSelectFrameBuilder;
      const AActiveMapsList: IMapTypeListChangeable;
      const ABitmap32StaticFactory: IBitmap32StaticFactory;
      const ABitmapTileSaveLoadFactory: IBitmapTileSaveLoadFactory
    ); reintroduce;
    destructor Destroy; override;
  end;

implementation

uses
  {$WARN UNIT_PLATFORM OFF}
  FileCtrl,
  {$WARN UNIT_PLATFORM ON}
  gnugettext,
  Graphics,
  c_CoordConverter,
  t_Bitmap32,
  i_Bitmap32Static,
  i_MapVersionRequest,
  i_ContentTypeInfo,
  i_MapTypeListStatic,
  u_BitmapLayerProviderMapWithLayer;

{$R *.dfm}

constructor TfrExportOruxMapsSQLite.Create(
  const ALanguageManager: ILanguageManager;
  const AMapSelectFrameBuilder: IMapSelectFrameBuilder;
  const AActiveMapsList: IMapTypeListChangeable;
  const ABitmap32StaticFactory: IBitmap32StaticFactory;
  const ABitmapTileSaveLoadFactory: IBitmapTileSaveLoadFactory
);
begin
  Assert(Assigned(ABitmap32StaticFactory));
  inherited Create(ALanguageManager);

  FLastPath := '';

  FActiveMapsList := AActiveMapsList;
  FBitmap32StaticFactory := ABitmap32StaticFactory;
  FBitmapTileSaveLoadFactory := ABitmapTileSaveLoadFactory;

  FfrMapSelect :=
    AMapSelectFrameBuilder.Build(
      mfMaps,          // show maps
      True,            // add -NO- to combobox
      False,           // show disabled map
      GetAllowExport
    );

  FfrOverlaySelect :=
    AMapSelectFrameBuilder.Build(
      mfLayers,        // show layers
      True,            // add -NO- to combobox
      False,           // show disabled map
      GetAllowExport
    );

  FfrZoomsSelect :=
    TfrZoomsSelect.Create(
      ALanguageManager
    );
  FfrZoomsSelect.Init(0, 23);
end;

destructor TfrExportOruxMapsSQLite.Destroy;
begin
  FreeAndNil(FfrMapSelect);
  FreeAndNil(FfrOverlaySelect);
  FreeAndNil(FfrZoomsSelect);
  inherited;
end;

procedure TfrExportOruxMapsSQLite.cbbImageFormatChange(Sender: TObject);
var
  VValue: Boolean;
begin
  VValue := not (cbbImageFormat.ItemIndex = 0) and cbbImageFormat.Enabled;

  lblJpgQulity.Enabled := VValue;
  seJpgQuality.Enabled := VValue;

  lblCompression.Enabled := VValue;
  seCompression.Enabled := VValue;
end;

procedure TfrExportOruxMapsSQLite.chkAddVisibleLayersClick(Sender: TObject);
begin
  FfrOverlaySelect.SetEnabled(not chkAddVisibleLayers.Checked);
end;

procedure TfrExportOruxMapsSQLite.btnSelectTargetPathClick(Sender: TObject);
begin
  if SelectDirectory('', '', FLastPath, [sdNewFolder, sdNewUI, sdShowEdit, sdShowShares]) then begin
    FLastPath := IncludeTrailingPathDelimiter(FLastPath);
    edtTargetPath.Text := FLastPath;
  end;
end;

function TfrExportOruxMapsSQLite.GetAllowExport(const AMapType: IMapType): Boolean;
begin
  Result := AMapType.IsBitmapTiles;
end;

function TfrExportOruxMapsSQLite.GetBlankTile: IBinaryData;
const
  cOruxMapsBackground = TColor32($FFCBD3F3);
var
  VBuffer: IBitmap32Buffer;
  VBitmapStatic: IBitmap32Static;
  VBitmapSaver: IBitmapTileSaver;
begin
  Result := nil;
  if chkStoreBlankTiles.Checked then begin
    VBuffer :=
      FBitmap32StaticFactory.BufferFactory.BuildEmptyClear(
        Point(256, 256),
        cOruxMapsBackground
      );
    VBitmapStatic := FBitmap32StaticFactory.BuildWithOwnBuffer(VBuffer);
    VBitmapSaver := Self.GetBitmapTileSaver;
    Result := VBitmapSaver.Save(VBitmapStatic);
  end;
end;

function TfrExportOruxMapsSQLite.GetMapType: IMapType;
var
  VMapType: IMapType;
begin
  VMapType := FfrMapSelect.GetSelectedMapType;
  if not Assigned(VMapType) then begin
    VMapType := FfrOverlaySelect.GetSelectedMapType;
  end;
  Result := VMapType;
end;

function TfrExportOruxMapsSQLite.GetPath: string;
begin
  Result := IncludeTrailingPathDelimiter(edtTargetPath.Text);
end;

function TfrExportOruxMapsSQLite.GetDirectTilesCopy: Boolean;

  function _IsValidMap(const AMapType: IMapType): Boolean;
  begin
    Result := False;
    if AMapType.IsBitmapTiles then begin
      case AMapType.ProjectionSet.Zooms[0].ProjectionType.ProjectionEPSG of
        CGoogleProjectionEPSG,
        CYandexProjectionEPSG,
        CGELonLatProjectionEPSG: Result := True;
      end;
    end;
  end;

var
  VMap: IMapType;
  VLayer: IMapType;
begin
  Result := False;
  if chkAddVisibleLayers.Checked or chkUsePrevZoom.Checked then begin
    Exit;
  end;
  VMap := FfrMapSelect.GetSelectedMapType;
  VLayer := FfrOverlaySelect.GetSelectedMapType;
  if Assigned(VMap) and not Assigned(VLayer) then begin
    Result := _IsValidMap(VMap);
  end else if not Assigned(VMap) and Assigned(VLayer) then begin
    Result := _IsValidMap(VLayer);
  end;
  Result := Result and (cbbImageFormat.ItemIndex = 0);
end;

function TfrExportOruxMapsSQLite.GetZoomArray: TByteDynArray;
begin
  Result := FfrZoomsSelect.GetZoomList;
end;

function TfrExportOruxMapsSQLite.GetProvider: IBitmapTileUniProvider;
var
  VMap: IMapType;
  VMapVersion: IMapVersionRequest;
  VLayer: IMapType;
  VLayerVersion: IMapVersionRequest;
  VActiveMapsSet: IMapTypeListStatic;
begin
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
      chkUsePrevZoom.Checked,
      chkUsePrevZoom.Checked
    );
end;

function TfrExportOruxMapsSQLite.GetBitmapTileSaver: IBitmapTileSaver;

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
  if cbbImageFormat.ItemIndex = 0 then begin
    Result := _GetSaver(FfrMapSelect.GetSelectedMapType);
    if not Assigned(Result) then begin
      Result := _GetSaver(FfrOverlaySelect.GetSelectedMapType);
    end;
  end else begin
    case cbbImageFormat.ItemIndex of
      1: Result := FBitmapTileSaveLoadFactory.CreateJpegSaver(seJpgQuality.Value);
      2: Result := FBitmapTileSaveLoadFactory.CreatePngSaver(i8bpp, seCompression.Value);
      3: Result := FBitmapTileSaveLoadFactory.CreatePngSaver(i24bpp, seCompression.Value);
      4: Result := FBitmapTileSaveLoadFactory.CreatePngSaver(i32bpp, seCompression.Value);
    end;
  end;
  if not Assigned(Result) then begin
    Assert(False, 'Unexpected result!');
    Result := FBitmapTileSaveLoadFactory.CreateJpegSaver;
  end;
end;

procedure TfrExportOruxMapsSQLite.Init;
begin
  FfrMapSelect.Show(pnlMap);
  FfrOverlaySelect.Show(pnlOverlay);
  FfrZoomsSelect.Show(pnlZoom);
  cbbImageFormat.ItemIndex := 0; // Auto
  cbbImageFormatChange(Self);
end;

function TfrExportOruxMapsSQLite.Validate: Boolean;
begin
  Result := False;

  if Trim(edtTargetPath.Text) = '' then begin
    ShowMessage(_('Please select output folder'));
    Exit;
  end;

  if not FfrZoomsSelect.Validate then begin
    ShowMessage(_('Please select at least one zoom'));
    Exit;
  end;

  if
    (FfrMapSelect.GetSelectedMapType = nil) and
    (FfrOverlaySelect.GetSelectedMapType = nil) then
  begin
    ShowMessage(_('Please select at least one map or overlay layer'));
    Exit;
  end;

  Result := True;
end;

end.

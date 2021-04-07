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

unit fr_ExportToJNX;

interface

uses
  SysUtils,
  Classes,
  Controls,
  Forms,
  Dialogs,
  StdCtrls,
  Spin,
  ComCtrls,
  ExtCtrls,
  i_LanguageManager,
  i_MapType,
  i_GeometryLonLat,
  i_BitmapTileSaveLoadFactory,
  i_RegionProcessParamsFrame,
  u_ExportToJnxTask,
  fr_MapSelect,
  u_CommonFormAndFrameParents;

type
  IRegionProcessParamsFrameExportToJNX = interface(IRegionProcessParamsFrameBase)
    ['{BBF2A4A5-C6CC-45D0-A010-A122617EFBB6}']
    function GetProductName: string;
    property ProductName: string read GetProductName;

    function GetMapName: string;
    property MapName: string read GetMapName;

    function GetJNXVersion: Integer;
    property JNXVersion: Integer read GetJNXVersion;

    function GetZOrder: Integer;
    property ZOrder: Integer read GetZOrder;

    function GetProductID: Integer;
    property ProductID: Integer read GetProductID;

    function GetTasks: TExportTaskJnxArray;
    property Tasks: TExportTaskJnxArray read GetTasks;

    function GetUseRecolor: Boolean;
    property UseRecolor: Boolean read GetUseRecolor;
  end;

type
  TfrExportToJNX = class(
      TFrame,
      IRegionProcessParamsFrameBase,
      IRegionProcessParamsFrameTargetPath,
      IRegionProcessParamsFrameExportToJNX
    )
    pnlCenter: TPanel;
    pnlTop: TPanel;
    lblTargetFile: TLabel;
    edtTargetFile: TEdit;
    btnSelectTargetFile: TButton;
    dlgSaveTargetFile: TSaveDialog;
    EJpgQuality1: TSpinEdit;
    lblCompress: TLabel;
    PageControl1: TPageControl;
    Map: TTabSheet;
    Info: TTabSheet;
    TreeView1: TTreeView;
    EZorder: TSpinEdit;
    LVersion: TLabel;
    LZOrder: TLabel;
    LProductID: TLabel;
    EProductID: TComboBox;
    EProductName: TEdit;
    LProductName: TLabel;
    LMapName: TLabel;
    EMapName: TEdit;
    Label1: TLabel;
    CbbZoom1: TComboBox;
    EJpgQuality2: TSpinEdit;
    CbbZoom2: TComboBox;
    EJpgQuality4: TSpinEdit;
    CbbZoom4: TComboBox;
    EJpgQuality5: TSpinEdit;
    CbbZoom5: TComboBox;
    EJpgQuality3: TSpinEdit;
    CbbZoom3: TComboBox;
    Label2: TLabel;
    cbbscale1: TComboBox;
    cbbscale2: TComboBox;
    cbbscale3: TComboBox;
    cbbscale4: TComboBox;
    cbbscale5: TComboBox;
    ChRecompress1: TCheckBox;
    ChRecompress2: TCheckBox;
    ChRecompress3: TCheckBox;
    ChRecompress4: TCheckBox;
    ChRecompress5: TCheckBox;
    lblMap: TLabel;
    ChMap5: TCheckBox;
    ChMap4: TCheckBox;
    ChMap3: TCheckBox;
    ChMap2: TCheckBox;
    ChMap1: TCheckBox;
    MapsPanel: TPanel;
    PnlInfo: TPanel;
    cbbVersion: TComboBox;
    chkUseRecolor: TCheckBox;
    chkUseMapMarks: TCheckBox;
    pnlMap1: TPanel;
    pnlMap2: TPanel;
    pnlMap3: TPanel;
    pnlMap4: TPanel;
    pnlMap5: TPanel;
    procedure btnSelectTargetFileClick(Sender: TObject);
    procedure PageControl1Change(Sender: TObject);
    procedure ChMap1Click(Sender: TObject);
    procedure ChMap2Click(Sender: TObject);
    procedure ChMap3Click(Sender: TObject);
    procedure ChMap4Click(Sender: TObject);
    procedure ChMap5Click(Sender: TObject);
    procedure CbbZoom1Change(Sender: TObject);
    procedure CbbZoom2Change(Sender: TObject);
    procedure CbbZoom3Change(Sender: TObject);
    procedure CbbZoom4Change(Sender: TObject);
    procedure CbbZoom5Change(Sender: TObject);
    procedure cbbVersionChange(Sender: TObject);
    procedure ChRecompress1Click(Sender: TObject);
    procedure ChRecompress2Click(Sender: TObject);
    procedure ChRecompress3Click(Sender: TObject);
    procedure ChRecompress4Click(Sender: TObject);
    procedure ChRecompress5Click(Sender: TObject);
    procedure Map1Change(Sender: TObject);
    procedure Map2Change(Sender: TObject);
    procedure Map3Change(Sender: TObject);
    procedure Map4Change(Sender: TObject);
    procedure Map5Change(Sender: TObject);
  private
    FBitmapTileSaveLoadFactory: IBitmapTileSaveLoadFactory;
    FfrMap1Select: TfrMapSelect;
    FfrMap2Select: TfrMapSelect;
    FfrMap3Select: TfrMapSelect;
    FfrMap4Select: TfrMapSelect;
    FfrMap5Select: TfrMapSelect;
    FZoom: Byte;
    FPolygon: IGeometryLonLatPolygon;
  private
    procedure Init(
      const AZoom: byte;
      const APolygon: IGeometryLonLatPolygon
    );
    function Validate: Boolean;
  private
    function GetPath: string;
    function GetAllowExport(const AMapType: IMapType): boolean;
    function GetUseRecolor: Boolean;
  private
    function GetTasks: TExportTaskJnxArray;
    function GetProductName: string;
    function GetMapName: string;
    function GetJNXVersion: Integer;
    function GetZOrder: Integer;
    function GetProductID: Integer;
  public
    constructor Create(
      const ALanguageManager: ILanguageManager;
      const ABitmapTileSaveLoadFactory: IBitmapTileSaveLoadFactory;
      const AMapSelectFrameBuilder: IMapSelectFrameBuilder;
      const AFileFilters: string;
      const AFileExtDefault: string
    ); reintroduce;
    destructor Destroy; override;
  end;

implementation

uses
  IniFiles,
  {$IFNDef UNICODE}
  CompatibilityIniFiles,
  {$ENDIF}
  ALString,
  RegExprUtils,
  gnugettext,
  i_ConfigDataProvider,
  i_PathConfig,
  u_FileSystemFunc,
  u_ConfigDataProviderByIniFile,
  u_GlobalState;

{$R *.dfm}

constructor TfrExportToJNX.Create(
  const ALanguageManager: ILanguageManager;
  const ABitmapTileSaveLoadFactory: IBitmapTileSaveLoadFactory;
  const AMapSelectFrameBuilder: IMapSelectFrameBuilder;
  const AFileFilters: string;
  const AFileExtDefault: string
);
var
  i: integer;
begin
  inherited Create(ALanguageManager);
  FBitmapTileSaveLoadFactory := ABitmapTileSaveLoadFactory;
  dlgSaveTargetFile.Filter := AFileFilters;
  dlgSaveTargetFile.DefaultExt := AFileExtDefault;
  FfrMap1Select :=
    AMapSelectFrameBuilder.Build(
      mfMaps, // show maps and layers
      True,   // add -NO- to combobox
      False,  // show disabled map
      GetAllowExport
    );
  FfrMap1Select.SetEnabled(False);
  FfrMap1Select.OnMapChange := Map1Change;
  FfrMap2Select :=
    AMapSelectFrameBuilder.Build(
      mfMaps, // show maps and layers
      True,   // add -NO- to combobox
      False,  // show disabled map
      GetAllowExport
    );
  FfrMap2Select.SetEnabled(False);
  FfrMap2Select.OnMapChange := Map2Change;
  FfrMap3Select :=
    AMapSelectFrameBuilder.Build(
      mfMaps, // show maps and layers
      True,   // add -NO- to combobox
      False,  // show disabled map
      GetAllowExport
    );
  FfrMap3Select.SetEnabled(False);
  FfrMap3Select.OnMapChange := Map3Change;
  FfrMap4Select :=
    AMapSelectFrameBuilder.Build(
      mfMaps, // show maps and layers
      True,   // add -NO- to combobox
      False,  // show disabled map
      GetAllowExport
    );
  FfrMap4Select.SetEnabled(False);
  FfrMap4Select.OnMapChange := Map4Change;
  FfrMap5Select :=
    AMapSelectFrameBuilder.Build(
      mfMaps, // show maps and layers
      True,   // add -NO- to combobox
      False,  // show disabled map
      GetAllowExport
    );
  FfrMap5Select.SetEnabled(False);
  FfrMap5Select.OnMapChange := Map5Change;

  CbbZoom1.Items.BeginUpdate;
  try
    for i := 1 to 24 do begin
      CbbZoom1.Items.Add(inttostr(i));
    end;
  finally
    CbbZoom1.Items.EndUpdate;
  end;

  CbbZoom2.Items := CbbZoom1.Items;
  CbbZoom3.Items := CbbZoom1.Items;
  CbbZoom4.Items := CbbZoom1.Items;
  CbbZoom5.Items := CbbZoom1.Items;

  cbbscale2.Items := cbbscale1.Items;
  cbbscale3.Items := cbbscale1.Items;
  cbbscale4.Items := cbbscale1.Items;
  cbbscale5.Items := cbbscale1.Items;

end;

destructor TfrExportToJNX.Destroy;
begin
  FreeAndNil(FfrMap1Select);
  FreeAndNil(FfrMap2Select);
  FreeAndNil(FfrMap3Select);
  FreeAndNil(FfrMap4Select);
  FreeAndNil(FfrMap5Select);
  inherited;
end;

procedure TfrExportToJNX.btnSelectTargetFileClick(Sender: TObject);
begin
  if dlgSaveTargetFile.Execute then begin
    edtTargetFile.Text := dlgSaveTargetFile.FileName;
  end;
end;

function TfrExportToJNX.GetUseRecolor: Boolean;
begin
  Result := chkUseRecolor.Checked;
end;

procedure TfrExportToJNX.Map1Change(Sender: TObject);
var
  BlankLayer: Boolean;
begin
  if ChMap1.Checked then begin
    EProductName.text := 'SAS Palnet';
    EMapName.text := FfrMap1Select.Text;
    TreeView1.Items[1].Text := FfrMap1Select.text;
  end;

  BlankLayer := (FfrMap1Select.GetSelectedMapType = Nil);
  CbbZoom1.Enabled := not BlankLayer;
  ChRecompress1.Enabled := not BlankLayer;
  EJpgQuality1.Enabled :=  not BlankLayer;
end;

procedure TfrExportToJNX.Map2Change(Sender: TObject);
var
  cnt: integer;
  BlankLayer: Boolean;
begin
  cnt := 0;
  if ChMap1.Checked then begin
    inc(cnt);
  end;
  TreeView1.Items[cnt * 3 + 1].Text := FfrMap2Select.text;

  BlankLayer := (FfrMap2Select.GetSelectedMapType = Nil);
  CbbZoom2.Enabled := not BlankLayer;
  ChRecompress2.Enabled := not BlankLayer;
  EJpgQuality2.Enabled :=  not BlankLayer;
end;

procedure TfrExportToJNX.Map3Change(Sender: TObject);
var
  cnt: integer;
  BlankLayer: Boolean;
begin
  cnt := 0;
  if ChMap1.Checked then begin
    inc(cnt);
  end;
  if ChMap2.Checked then begin
    inc(cnt);
  end;
  TreeView1.Items[cnt * 3 + 1].Text := FfrMap3Select.text;

  BlankLayer := (FfrMap3Select.GetSelectedMapType = Nil);
  CbbZoom3.Enabled := not BlankLayer;
  ChRecompress3.Enabled := not BlankLayer;
  EJpgQuality3.Enabled :=  not BlankLayer;
end;

procedure TfrExportToJNX.Map4Change(Sender: TObject);
var
  cnt: integer;
  BlankLayer: Boolean;
begin
  cnt := 0;
  if ChMap1.Checked then begin
    inc(cnt);
  end;
  if ChMap2.Checked then begin
    inc(cnt);
  end;
  if ChMap3.Checked then begin
    inc(cnt);
  end;
  TreeView1.Items[cnt * 3 + 1].Text := FfrMap4Select.text;

  BlankLayer := (FfrMap4Select.GetSelectedMapType = Nil);
  CbbZoom4.Enabled := not BlankLayer;
  ChRecompress4.Enabled := not BlankLayer;
  EJpgQuality4.Enabled :=  not BlankLayer;
end;

procedure TfrExportToJNX.Map5Change(Sender: TObject);
var
  cnt: integer;
  BlankLayer: Boolean;
begin
  cnt := 0;
  if ChMap1.Checked then begin
    inc(cnt);
  end;
  if ChMap2.Checked then begin
    inc(cnt);
  end;
  if ChMap3.Checked then begin
    inc(cnt);
  end;
  if ChMap4.Checked then begin
    inc(cnt);
  end;
  TreeView1.Items[cnt * 3 + 1].Text := FfrMap5Select.Text;

  BlankLayer := (FfrMap5Select.GetSelectedMapType = Nil);
  CbbZoom5.Enabled := not BlankLayer;
  ChRecompress5.Enabled := not BlankLayer;
  EJpgQuality5.Enabled :=  not BlankLayer;
end;

procedure TfrExportToJNX.cbbVersionChange(Sender: TObject);
begin
  if cbbVersion.ItemIndex = 1 then begin
    EZorder.visible := true;
    LZOrder.visible := true;
  end else begin
    EZorder.visible := false;
    LZOrder.visible := false;
  end;
end;

type
  TZoomIndexToScaleIndex = array [0..23] of integer;

const
  DefZoomIndexToScaleIndex: TZoomIndexToScaleIndex = (
    0, 0, 0, 0, 2, 3, 5,
    6, 8, 9, 11, 12, 14, 15, 17,
    18, 20, 21, 23, 24, 26, 26, 26, 26
  );
var
  ZoomIndexToScaleIndex: TZoomIndexToScaleIndex;

procedure InitZoomIndexToScaleIndex;
const
  GarminMetricZoomListStr =
    '800km,500km,300km,200km,120km,80km,50km,30km,20km,' +
    '12km,8km,5km,3km,2km,1.2km,800m,500m,300m,' +
    '200m,120m,80m,50m,30m,20m,12m,8m,5m';
var
  VGarminZoomList: TStringList;
  VConfigPath: IPathConfig;
  VIniFileName: string;
  VIniFile: TMeminiFile;
  VJnxScaleConfig: IConfigDataProvider;
  VJnxLevelMappingConfig: IConfigDataProvider;
  VStr: String;
  i: integer;
  VIndex: integer;
begin
  ZoomIndexToScaleIndex := DefZoomIndexToScaleIndex;

  try
    VGarminZoomList := TStringList.Create;
    try
      VGarminZoomList.CommaText := GarminMetricZoomListStr;

      VConfigPath := GState.Config.BaseConfigPath;
      VIniFileName := IncludeTrailingPathDelimiter(VConfigPath.Path) + 'JnxScales.ini';
      if FileExists(VIniFileName) then begin
        VIniFile := TMeminiFile.Create(VIniFileName);
        VJnxScaleConfig := TConfigDataProviderByIniFile.CreateWithOwn(VIniFile);
        VJnxLevelMappingConfig := VJnxScaleConfig.GetSubItem('LevelMapping');

        if Assigned(VJnxScaleConfig) then begin
          for i := 0 to 23 do begin
            VStr := VJnxLevelMappingConfig.ReadString('z' + IntToStr(i + 1), '');
            // ���� � INI����� ��� ���������������� ��������, ����� ������������ �������� �� ������ �� ���������.
            if VStr <> '' then begin
              VIndex := VGarminZoomList.IndexOf(VStr);
              if VIndex <> -1 then begin
                ZoomIndexToScaleIndex[i] := VIndex;
              end;
            end;
          end;
        end;
      end;
    finally
      VJnxLevelMappingConfig := Nil;
      VJnxScaleConfig := Nil;
      VGarminZoomList.Free;
    end;
  except
  end;
end;

procedure TfrExportToJNX.CbbZoom1Change(Sender: TObject);
begin
  cbbscale1.ItemIndex := ZoomIndexToScaleIndex[CbbZoom1.itemindex];
end;

procedure TfrExportToJNX.CbbZoom2Change(Sender: TObject);
begin
  cbbscale2.ItemIndex := ZoomIndexToScaleIndex[CbbZoom2.itemindex];
end;

procedure TfrExportToJNX.CbbZoom3Change(Sender: TObject);
begin
  cbbscale3.ItemIndex := ZoomIndexToScaleIndex[CbbZoom3.itemindex];
end;

procedure TfrExportToJNX.CbbZoom4Change(Sender: TObject);
begin
  cbbscale4.ItemIndex := ZoomIndexToScaleIndex[CbbZoom4.itemindex];
end;

procedure TfrExportToJNX.CbbZoom5Change(Sender: TObject);
begin
  cbbscale5.ItemIndex := ZoomIndexToScaleIndex[CbbZoom5.itemindex];
end;

procedure TfrExportToJNX.Init(
  const AZoom: byte;
  const APolygon: IGeometryLonLatPolygon
);
begin
  // �������������� ������ ������������ ��������� ������ ���,
  // ����� ����� ���� ��������� ��������� ���������, �� ������������ ���������.
  InitZoomIndexToScaleIndex;
  if not Assigned(FfrMap1Select.Parent) then
    FfrMap1Select.Show(pnlMap1);
  if not Assigned(FfrMap2Select.Parent) then
    FfrMap2Select.Show(pnlMap2);
  if not Assigned(FfrMap3Select.Parent) then
    FfrMap3Select.Show(pnlMap3);
  if not Assigned(FfrMap4Select.Parent) then
    FfrMap4Select.Show(pnlMap4);
  if not Assigned(FfrMap5Select.Parent) then
    FfrMap5Select.Show(pnlMap5);

  if (AZoom <> FZoom) or (not APolygon.IsSameGeometry(FPolygon)) then begin
    FfrMap1Select.SetEnabled(ChMap1.Checked);
    FfrMap2Select.SetEnabled(ChMap2.Checked);
    FfrMap3Select.SetEnabled(ChMap3.Checked);
    FfrMap4Select.SetEnabled(ChMap4.Checked);
    FfrMap5Select.SetEnabled(ChMap5.Checked);

    CbbZoom1.ItemIndex := AZoom;
    CbbZoom2.ItemIndex := AZoom;
    CbbZoom3.ItemIndex := AZoom;
    CbbZoom4.ItemIndex := AZoom;
    CbbZoom5.ItemIndex := AZoom;

    cbbscale1.ItemIndex := ZoomIndexToScaleIndex[AZoom];
    cbbscale2.ItemIndex := ZoomIndexToScaleIndex[AZoom];
    cbbscale3.ItemIndex := ZoomIndexToScaleIndex[AZoom];
    cbbscale4.ItemIndex := ZoomIndexToScaleIndex[AZoom];
    cbbscale5.ItemIndex := ZoomIndexToScaleIndex[AZoom];

    EMapName.text := FfrMap1Select.Text;
    EProductName.text := 'SAS Planet';
    EProductID.ItemIndex := 0;
    if cbbVersion.ItemIndex = -1 then begin
      cbbVersion.ItemIndex := 0;
    end;
    if cbbVersion.ItemIndex = 1 then begin
      EZorder.visible := true;
      LZOrder.visible := true;
    end else begin
      EZorder.visible := false;
      LZOrder.visible := false;
    end;
    FZoom := AZoom;
    FPolygon := APolygon;
  end;
end;

function TfrExportToJNX.GetAllowExport(const AMapType: IMapType): boolean;
begin
  Result := AMapType.IsBitmapTiles;
end;

procedure TfrExportToJNX.ChMap1Click(Sender: TObject);
var
  VItemNode, VParentNode: TTreeNode;
  BlankLayer: Boolean;
begin
  FfrMap1Select.SetEnabled(ChMap1.Checked);
  BlankLayer := (FfrMap1Select.GetSelectedMapType = Nil);

  EJpgQuality1.Enabled := ChMap1.Checked and ChRecompress1.Checked and not BlankLayer;
  CbbZoom1.Enabled := ChMap1.Checked and not BlankLayer;
  cbbscale1.Enabled := ChMap1.Checked;
  ChMap2.Enabled := ChMap1.Checked;
  ChRecompress1.Enabled := ChMap1.Checked and not BlankLayer;

  if ChMap1.Checked then begin
    VParentNode := TreeView1.Items.AddFirst(nil, 'Level' + inttostr(1));
    TreeView1.Items.AddChild(VParentNode, FfrMap1Select.text);
    TreeView1.Items.AddChild(VParentNode, '(c) ' + EProductName.text);
  end else begin
    VItemNode := TreeView1.Items[0];
    TreeView1.Items.delete(VItemNode);
    ChMap2.Checked := False;
  end;
end;

procedure TfrExportToJNX.ChMap2Click(Sender: TObject);
var
  VItemNode, VParentNode: TTreeNode;
  cnt: integer;
  BlankLayer: Boolean;  
begin
  cnt := 0;
  FfrMap2Select.SetEnabled(ChMap2.Checked);
  BlankLayer := (FfrMap2Select.GetSelectedMapType = Nil);

  EJpgQuality2.Enabled := ChMap2.Checked and ChRecompress2.Checked and not BlankLayer;
  CbbZoom2.Enabled := ChMap2.Checked and not BlankLayer;
  cbbscale2.Enabled := ChMap2.Checked;
  ChMap3.Enabled := ChMap2.Checked;
  ChRecompress2.Enabled := ChMap2.Checked and not BlankLayer;
  if ChMap1.Checked then begin
    inc(cnt);
  end;
  if ChMap2.Checked then begin
    if (TreeView1.Items.count > cnt * 3) then begin
      VItemNode := TreeView1.Items[cnt * 3];
      VParentNode := TreeView1.Items.insert(VItemNode, 'Level' + inttostr(2));
    end else begin
      if TreeView1.Items.Count = 0 then begin
        VParentNode := TreeView1.Items.AddFirst(nil, 'Level' + inttostr(2));
      end else begin
        VParentNode := TreeView1.Items.Add(nil, 'Level' + inttostr(2));
      end;
    end;
    TreeView1.Items.AddChild(VParentNode, FfrMap2Select.text);
    TreeView1.Items.AddChild(VParentNode, '(c) ' + EProductName.text);
  end else begin
    VItemNode := TreeView1.Items[cnt * 3];
    TreeView1.Items.delete(VItemNode);
    ChMap3.Checked := False;
  end;
end;

procedure TfrExportToJNX.ChMap3Click(Sender: TObject);
var
  VItemNode, VParentNode: TTreeNode;
  cnt: integer;
  BlankLayer: Boolean;
begin
  cnt := 0;
  FfrMap3Select.SetEnabled(ChMap3.Checked);
  BlankLayer := (FfrMap3Select.GetSelectedMapType = Nil);

  EJpgQuality3.Enabled := ChMap3.Checked and ChRecompress3.Checked and not BlankLayer;
  CbbZoom3.Enabled := ChMap3.Checked and not BlankLayer;
  cbbscale3.Enabled := ChMap3.Checked;
  ChMap4.Enabled := ChMap3.Checked;
  ChRecompress3.Enabled := ChMap3.Checked and not BlankLayer;
  if ChMap1.Checked then begin
    inc(cnt);
  end;
  if ChMap2.Checked then begin
    inc(cnt);
  end;
  if ChMap3.Checked then begin
    if (TreeView1.Items.count > cnt * 3) then begin
      VItemNode := TreeView1.Items[cnt * 3];
      VParentNode := TreeView1.Items.insert(VItemNode, 'Level' + inttostr(3));
    end else begin
      if TreeView1.Items.Count = 0 then begin
        VParentNode := TreeView1.Items.AddFirst(nil, 'Level' + inttostr(3));
      end else begin
        VParentNode := TreeView1.Items.Add(nil, 'Level' + inttostr(3));
      end;
    end;
    TreeView1.Items.AddChild(VParentNode, FfrMap3Select.text);
    TreeView1.Items.AddChild(VParentNode, '(c) ' + EProductName.text);
  end else begin
    VItemNode := TreeView1.Items[cnt * 3];
    TreeView1.Items.delete(VItemNode);
    ChMap4.Checked := False;
  end;
end;

procedure TfrExportToJNX.ChMap4Click(Sender: TObject);
var
  VItemNode, VParentNode: TTreeNode;
  cnt: integer;
  BlankLayer: Boolean;
begin
  cnt := 0;
  FfrMap4Select.SetEnabled(ChMap4.Checked);
  BlankLayer := (FfrMap4Select.GetSelectedMapType = Nil);

  EJpgQuality4.Enabled := ChMap4.Checked and ChRecompress4.Checked and not BlankLayer;
  CbbZoom4.Enabled := ChMap4.Checked and not BlankLayer;
  cbbscale4.Enabled := ChMap4.Checked;
  ChMap5.Enabled := ChMap4.Checked;
  ChRecompress4.Enabled := ChMap4.Checked and not BlankLayer;
  if ChMap1.Checked then begin
    inc(cnt);
  end;
  if ChMap2.Checked then begin
    inc(cnt);
  end;
  if ChMap3.Checked then begin
    inc(cnt);
  end;
  if ChMap4.Checked then begin
    if (TreeView1.Items.count > cnt * 3) then begin
      VItemNode := TreeView1.Items[cnt * 3];
      VParentNode := TreeView1.Items.insert(VItemNode, 'Level' + inttostr(4));
    end else begin
      if TreeView1.Items.Count = 0 then begin
        VParentNode := TreeView1.Items.AddFirst(nil, 'Level' + inttostr(4));
      end else begin
        VParentNode := TreeView1.Items.Add(nil, 'Level' + inttostr(4));
      end;
    end;
    TreeView1.Items.AddChild(VParentNode, FfrMap4Select.text);
    TreeView1.Items.AddChild(VParentNode, '(c) ' + EProductName.text);
  end else begin
    VItemNode := TreeView1.Items[cnt * 3];
    TreeView1.Items.delete(VItemNode);
    ChMap5.Checked := False;
  end;
end;

procedure TfrExportToJNX.ChMap5Click(Sender: TObject);
var
  VItemNode, VParentNode: TTreeNode;
  cnt: integer;
  BlankLayer: Boolean;
begin
  cnt := 0;
  FfrMap5Select.SetEnabled(ChMap5.Checked);
  BlankLayer := (FfrMap5Select.GetSelectedMapType = Nil);

  EJpgQuality5.Enabled := ChMap5.Checked and ChRecompress5.Checked and not BlankLayer;
  CbbZoom5.Enabled := ChMap5.Checked and not BlankLayer;
  cbbscale5.Enabled := ChMap5.Checked;
  ChRecompress5.Enabled := ChMap5.Checked and not BlankLayer;
  if ChMap1.Checked then begin
    inc(cnt);
  end;
  if ChMap2.Checked then begin
    inc(cnt);
  end;
  if ChMap3.Checked then begin
    inc(cnt);
  end;
  if ChMap4.Checked then begin
    inc(cnt);
  end;
  if ChMap5.Checked then begin
    if (TreeView1.Items.count > cnt * 3) then begin
      VItemNode := TreeView1.Items[(cnt) * 3];
      VParentNode := TreeView1.Items.insert(VItemNode, 'Level' + inttostr(5));
    end else begin
      if TreeView1.Items.Count = 0 then begin
        VParentNode := TreeView1.Items.AddFirst(nil, 'Level' + inttostr(5));
      end else begin
        VParentNode := TreeView1.Items.Add(nil, 'Level' + inttostr(5));
      end;
    end;
    TreeView1.Items.AddChild(VParentNode, FfrMap5Select.text);
    TreeView1.Items.AddChild(VParentNode, '(c) ' + EProductName.text);
  end else begin
    VItemNode := TreeView1.Items[cnt * 3];
    TreeView1.Items.delete(VItemNode);
  end;
end;

procedure TfrExportToJNX.PageControl1Change(Sender: TObject);
begin
  if PageControl1.TabIndex >= 2 then begin
    MapsPanel.Visible := false;
  end else begin
    MapsPanel.Visible := true;
  end;
end;

function TfrExportToJNX.Validate: Boolean;
begin
  Result := False;

  if not IsValidFileName(edtTargetFile.Text) then begin
    ShowMessage(_('Output file name is not set or incorrect!'));
    Exit;
  end;

  Result := ChMap1.Checked;
end;

function TfrExportToJNX.GetJNXVersion: Integer;
begin
  if cbbVersion.ItemIndex = 0 then begin
    Result := 3;
  end else begin
    Result := 4;
  end;
end;

function TfrExportToJNX.GetMapName: string;
begin
  Result := EMapName.Text;
end;

function TfrExportToJNX.GetPath: string;
begin
  Result := Trim(edtTargetFile.Text);
end;

function TfrExportToJNX.GetProductID: Integer;
var
  VMatchSubStr: AnsiString;
begin
  try
    VMatchSubStr := RegExprGetMatchSubStr(AnsiString(EProductID.Text), '[0-9]+', 0);
    Result := ALStrToIntDef(VMatchSubStr, 0);
  except
    Result := 0;
  end;
end;

function TfrExportToJNX.GetProductName: string;
begin
  Result := EProductName.Text;
end;

function TfrExportToJNX.GetTasks: TExportTaskJnxArray;
var
  VMap: IMapType;
  VTask: TExportTaskJnx;
begin
  Result := nil;
  if ChMap1.Checked then begin
    VMap := FfrMap1Select.GetSelectedMapType;
    if Assigned(VMap) then begin
      VTask.FTileStorage := VMap.TileStorage;
      VTask.FMapVersion := VMap.VersionRequest.GetStatic;
      VTask.FBlankLevel := False;
    end else begin
      VTask.FTileStorage := Nil;
      VTask.FMapVersion := Nil;
      VTask.FBlankLevel := True;
    end;
    VTask.FScale := cbbscale1.ItemIndex;
    VTask.FZoom := CbbZoom1.ItemIndex;
    VTask.FRecompress := ChRecompress1.Checked;
    VTask.FSaver := FBitmapTileSaveLoadFactory.CreateJpegSaver(EJpgQuality1.Value);
    VTask.FLevelDesc := TreeView1.Items[0].text;
    VTask.FLevelName := TreeView1.Items[1].text;
    VTask.FLevelCopyright := TreeView1.Items[2].text;
    SetLength(Result, Length(Result) + 1);
    Result[Length(Result) - 1] := VTask;
  end;

  if ChMap2.Checked then begin
    VMap := FfrMap2Select.GetSelectedMapType;
    if Assigned(VMap) then begin
      VTask.FTileStorage := VMap.TileStorage;
      VTask.FMapVersion := VMap.VersionRequest.GetStatic;
      VTask.FBlankLevel := False;
    end else begin
      VTask.FTileStorage := Nil;
      VTask.FMapVersion := Nil;
      VTask.FBlankLevel := True;
    end;
    VTask.FScale := cbbscale2.ItemIndex;
    VTask.FZoom := CbbZoom2.ItemIndex;
    VTask.FRecompress := ChRecompress2.Checked;
    VTask.FSaver := FBitmapTileSaveLoadFactory.CreateJpegSaver(EJpgQuality2.Value);
    VTask.FLevelDesc := TreeView1.Items[3].text;
    VTask.FLevelName := TreeView1.Items[4].text;
    VTask.FLevelCopyright := TreeView1.Items[5].text;
    SetLength(Result, Length(Result) + 1);
    Result[Length(Result) - 1] := VTask;
  end;

  if ChMap3.Checked then begin
    VMap := FfrMap3Select.GetSelectedMapType;
    if Assigned(VMap) then begin
      VTask.FTileStorage := VMap.TileStorage;
      VTask.FMapVersion := VMap.VersionRequest.GetStatic;
      VTask.FBlankLevel := False;
    end else begin
      VTask.FTileStorage := Nil;
      VTask.FMapVersion := Nil;
      VTask.FBlankLevel := True;
    end;
    VTask.FScale := cbbscale3.ItemIndex;
    VTask.FZoom := CbbZoom3.ItemIndex;
    VTask.FRecompress := ChRecompress3.Checked;
    VTask.FSaver := FBitmapTileSaveLoadFactory.CreateJpegSaver(EJpgQuality3.Value);
    VTask.FLevelDesc := TreeView1.Items[6].text;
    VTask.FLevelName := TreeView1.Items[7].text;
    VTask.FLevelCopyright := TreeView1.Items[8].text;
    SetLength(Result, Length(Result) + 1);
    Result[Length(Result) - 1] := VTask;
  end;

  if ChMap4.Checked then begin
    VMap := FfrMap4Select.GetSelectedMapType;
    if Assigned(VMap) then begin
      VTask.FTileStorage := VMap.TileStorage;
      VTask.FMapVersion := VMap.VersionRequest.GetStatic;
      VTask.FBlankLevel := False;
    end else begin
      VTask.FTileStorage := Nil;
      VTask.FMapVersion := Nil;
      VTask.FBlankLevel := True;
    end;
    VTask.FScale := cbbscale4.ItemIndex;
    VTask.FZoom := CbbZoom4.ItemIndex;
    VTask.FRecompress := ChRecompress4.Checked;
    VTask.FSaver := FBitmapTileSaveLoadFactory.CreateJpegSaver(EJpgQuality4.Value);
    VTask.FLevelDesc := TreeView1.Items[9].text;
    VTask.FLevelName := TreeView1.Items[10].text;
    VTask.FLevelCopyright := TreeView1.Items[11].text;
    SetLength(Result, Length(Result) + 1);
    Result[Length(Result) - 1] := VTask;
  end;

  if ChMap5.Checked then begin
    VMap := FfrMap5Select.GetSelectedMapType;
    if Assigned(VMap) then begin
      VTask.FTileStorage := VMap.TileStorage;
      VTask.FMapVersion := VMap.VersionRequest.GetStatic;
      VTask.FBlankLevel := False;
    end else begin
      VTask.FTileStorage := Nil;
      VTask.FMapVersion := Nil;
      VTask.FBlankLevel := True;
    end;
    VTask.FScale := cbbscale5.ItemIndex;
    VTask.FZoom := CbbZoom5.ItemIndex;
    VTask.FRecompress := ChRecompress5.Checked;
    VTask.FSaver := FBitmapTileSaveLoadFactory.CreateJpegSaver(EJpgQuality5.Value);
    VTask.FLevelDesc := TreeView1.Items[12].text;
    VTask.FLevelName := TreeView1.Items[13].text;
    VTask.FLevelCopyright := TreeView1.Items[14].text;
    SetLength(Result, Length(Result) + 1);
    Result[Length(Result) - 1] := VTask;
  end;
end;

function TfrExportToJNX.GetZOrder: Integer;
begin
  if cbbVersion.ItemIndex = 0 then begin
    Result := 0;
  end else begin
    Result := EZorder.Value;
  end;
end;

procedure TfrExportToJNX.ChRecompress1Click(Sender: TObject);
begin
  EJpgQuality1.Enabled := ChRecompress1.Checked;
end;

procedure TfrExportToJNX.ChRecompress2Click(Sender: TObject);
begin
  EJpgQuality2.Enabled := ChRecompress2.Checked;
end;

procedure TfrExportToJNX.ChRecompress3Click(Sender: TObject);
begin
  EJpgQuality3.Enabled := ChRecompress3.Checked;
end;

procedure TfrExportToJNX.ChRecompress4Click(Sender: TObject);
begin
  EJpgQuality4.Enabled := ChRecompress4.Checked;
end;

procedure TfrExportToJNX.ChRecompress5Click(Sender: TObject);
begin
  EJpgQuality5.Enabled := ChRecompress5.Checked;
end;

end.

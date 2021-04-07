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

unit frm_ProgressDownload;

interface

uses
  Forms,
  windows,
  messages,
  Dialogs,
  ExtCtrls,
  StdCtrls,
  Controls,
  Classes,
  DateUtils,
  UITypes,
  RarProgress,
  TB2Item,
  TB2Dock,
  TB2Toolbar,
  TBXStatusBars,
  TBX,
  i_MapType,
  i_MapTypeIconsList,
  i_MapViewGoto,
  i_ActiveMapsConfig,
  i_LogSimpleProvider,
  i_LanguageManager,
  i_NotifierOperation,
  i_ValueToStringConverter,
  i_RegionProcessProgressInfoDownload,
  i_GeometryLonLat,
  i_RegionProcess,
  u_MarkDbGUIHelper,
  u_CommonFormAndFrameParents;

type
  TfrmProgressDownload = class(TFormWitghLanguageManager)
    Panel1: TPanel;
    mmoLog: TMemo;
    lblToProcessValue: TLabel;
    lblProcessedValue: TLabel;
    lblDownloadedValue: TLabel;
    lblTimeToFinishValue: TLabel;
    lblToProcess: TLabel;
    lblProcessed: TLabel;
    lblDownloaded: TLabel;
    lblTimeToFinish: TLabel;
    lblSizeToFinish: TLabel;
    lblSizeToFinishValue: TLabel;
    SaveSessionDialog: TSaveDialog;
    UpdateTimer: TTimer;
    btnPause: TButton;
    btnClose: TButton;
    pnlBottom: TPanel;
    pnlProgress: TPanel;
    chkAutoCloseWhenFinish: TCheckBox;
    pnlToProcess: TPanel;
    pnlProcessed: TPanel;
    pnlDownloaded: TPanel;
    pnlSizeToFinish: TPanel;
    pnlTimeToFinish: TPanel;
    TBXOperationsToolbar: TTBXToolbar;
    tbtmZoom: TTBItem;
    tbtmSave: TTBSubmenuItem;
    tbtmMark: TTBItem;
    tbtmSelect: TTBItem;
    tbtmGotoMap: TTBItem;
    tbxStatusBar: TTBXStatusBar;
    procedure btnCloseClick(Sender: TObject);
    procedure btnPauseClick(Sender: TObject);
    procedure UpdateTimerTimer(Sender: TObject);
    procedure FormClose(
      Sender: TObject;
      var Action: TCloseAction
    );
    procedure Panel1Resize(Sender: TObject);
    procedure tbtmSaveClick(Sender: TObject);
    procedure tbtmZoomClick(Sender: TObject);
    procedure tbtmSelectClick(Sender: TObject);
    procedure tbtmMarkClick(Sender: TObject);
    procedure tbtmGotoMapClick(Sender: TObject);
    procedure chkAutoCloseWhenFinishClick(Sender: TObject);
  private
    FValueToStringConverter: IValueToStringConverterChangeable;
    FCancelNotifier: INotifierOperationInternal;
    FProgressInfo: IRegionProcessProgressInfoDownload;
    FLastLogID: Cardinal;
    FStoped: boolean;
    FFinished: Boolean;
    FProgress: TRarProgress;
    FRegionProcess: IRegionProcess;
    FMapGoto: IMapViewGoto;
    FPolygon: IGeometryLonLatPolygon;
    FFormCaption: string;
    FMarkDBGUI: TMarkDbGUIHelper;
    FMainConfig: IActiveMapConfig;
    FMapType: IMapType;
    FMapTypeIcons18List: IMapTypeIconsList;
    FIsSessionInitialized: Boolean;
    FSessionPrefix: string;
    FSessionFileName: string;
    FSessionFileNameBack: string;
    FLastElapsedTime: TDateTime;
    procedure CheckSessionAutosave;
    procedure DoSaveSession(const ATargetFileName: string);
    procedure UpdateProgressForm;
    procedure UpdateMemoProgressForm;
    function GetTimeEnd(
      loadAll, load: Int64;
      AElapsedTime: TDateTime
    ): String;
    function GetLenEnd(
      loadAll, obrab, loaded: Int64;
      len: Double
    ): string;
  public
    constructor Create(
      const ALanguageManager: ILanguageManager;
      const AValueToStringConverter: IValueToStringConverterChangeable;
      const ACancelNotifier: INotifierOperationInternal;
      const AProgressInfo: IRegionProcessProgressInfoDownload;
      const APolygon: IGeometryLonLatPolygon;
      const AFormCaption: string;
      const ARegionProcess: IRegionProcess;
      const AMapGoto: IMapViewGoto;
      const AMarkDBGUI: TMarkDbGUIHelper;
      const AMainConfig: IActiveMapConfig;
      const AMapType: IMapType
    ); reintroduce;
    destructor Destroy; override;
  end;

implementation

uses
  SysUtils,
  Graphics,
  IniFiles,
  {$IFNDef UNICODE}
  CompatibilityIniFiles,
  {$ENDIF}
  i_ConfigDataWriteProvider,
  u_ResStrings,
  u_MapTypeIconsList,
  u_ConfigDataWriteProviderByIniFile;

resourcestring
  rsFailedSessionSave = 'Failed to save session to file: ';
  rsSessionSavedToFile = 'Session saved to file: ';

{$R *.dfm}

constructor TfrmProgressDownload.Create(
  const ALanguageManager: ILanguageManager;
  const AValueToStringConverter: IValueToStringConverterChangeable;
  const ACancelNotifier: INotifierOperationInternal;
  const AProgressInfo: IRegionProcessProgressInfoDownload;
  const APolygon: IGeometryLonLatPolygon;
  const AFormCaption: string;
  const ARegionProcess: IRegionProcess;
  const AMapGoto: IMapViewGoto;
  const AMarkDBGUI: TMarkDbGUIHelper;
  const AMainConfig: IActiveMapConfig;
  const AMapType: IMapType
);
var
  VList18: TMapTypeIconsList;
begin
  Assert(AValueToStringConverter <> nil);
  Assert(ACancelNotifier <> nil);
  Assert(AProgressInfo <> nil);
  inherited Create(ALanguageManager);
  FValueToStringConverter := AValueToStringConverter;
  FProgressInfo := AProgressInfo;
  FCancelNotifier := ACancelNotifier;
  FProgress := TRarProgress.Create(Self);
  FRegionProcess := ARegionProcess;
  FMapGoto := AMapGoto;
  FPolygon := APolygon;
  FFormCaption := AFormCaption;
  FMarkDBGUI := AMarkDBGUI;
  FMainConfig := AMainConfig;
  FMapType := AMapType;
  // Goto map button avail and icon ..
  tbtmGotoMap.Caption := FMapType.GUIConfig.Name.Value;
  tbtmGotoMap.Enabled := not FMapType.Zmp.IsLayer;
  VList18 := TMapTypeIconsList.Create(18, 18);
  FMapTypeIcons18List := VList18;
  VList18.Add(AMapType.GUID, AMapType.Zmp.GUI.Bmp18);
  tbtmGotoMap.Images := FMapTypeIcons18List.GetImageList;
  tbtmGotoMap.ImageIndex := FMapTypeIcons18List.GetIconIndexByGUID(FMapType.GUID);

  with FProgress do begin
    Height := 17;
    Min := 0;
    Max := 100;
    Progress1 := 0;
    Progress2 := 0;
    Double := True;
    LightColor1 := 16770764;
    DarkColor1 := 13395456;
    LightColor2 := 16768959;
    FrameColor1 := 16758122;
    FrameColor2 := 16747546;
    FillColor1 := 16757606;
    FillColor2 := 16749867;
    BackFrameColor1 := 16633762;
    BackFrameColor2 := 16634540;
    BackFillColor := 16635571;
    ShadowColor := clGray;
  end;
  FProgress.Parent := pnlProgress;
  FProgress.Align := alClient;
  FProgress.Max := FProgressInfo.TotalToProcess;
  FProgress.Progress1 := FProgressInfo.Downloaded;
  FProgress.Progress2 := FProgressInfo.Processed;
  if FProgressInfo.IsPaused then begin
    FStoped := true;
    btnPause.Caption := SAS_STR_Continue;
  end else begin
    FStoped := false;
    btnPause.Caption := SAS_STR_Pause;
  end;
  FFinished := False;
  chkAutoCloseWhenFinish.Checked := FProgressInfo.AutoCloseAtFinish;
  FLastElapsedTime := FProgressInfo.ElapsedTime;
  FSessionPrefix := '';
  FSessionFileName := '';
  FSessionFileNameBack := '';
  FIsSessionInitialized := False;
end;

destructor TfrmProgressDownload.Destroy;
begin
  if Assigned(UpdateTimer) then begin
    UpdateTimer.Enabled := false;
  end;
  if Assigned(FCancelNotifier) then begin
    FCancelNotifier.NextOperation;
  end;
  FreeAndNil(FProgress);
  inherited;
end;

procedure TfrmProgressDownload.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmProgressDownload.btnPauseClick(Sender: TObject);
begin
  if FStoped then begin
    FProgressInfo.Resume;
    FStoped := false;
    btnPause.Caption := SAS_STR_Pause;
  end else begin
    FProgressInfo.Pause;
    FStoped := true;
    btnPause.Caption := SAS_STR_Continue;
  end;
end;

procedure TfrmProgressDownload.chkAutoCloseWhenFinishClick(Sender: TObject);
begin
  FProgressInfo.AutoCloseAtFinish := chkAutoCloseWhenFinish.Checked;
end;

procedure TfrmProgressDownload.Panel1Resize(Sender: TObject);
begin
  FProgress.Top := TPanel(Sender).Height - 48;
  FProgress.Width := TPanel(Sender).Width - 14;
end;

procedure TfrmProgressDownload.tbtmSelectClick(Sender: TObject);
begin
  if (FPolygon <> nil) then begin
    FRegionProcess.ProcessPolygon(FPolygon);
  end;
end;

procedure TfrmProgressDownload.tbtmZoomClick(Sender: TObject);
begin
  if (FMapGoto <> nil) and (FPolygon <> nil) then begin
    FMapGoto.FitRectToScreen(FPolygon.Bounds.Rect);
  end;
end;

procedure TfrmProgressDownload.UpdateProgressForm;
var
  VZoom: Byte;
  VPoint: TPoint;
  VSize: Integer;
  VComplete: string;
  VValueConverter: IValueToStringConverter;
  VTotal: Int64;
  VDownloadSize: Double;
begin
  VTotal := FProgressInfo.TotalToProcess;
  if VTotal > 0 then begin
    VComplete := inttostr(round(FProgressInfo.Processed / VTotal * 100)) + '%';
  end else begin
    VComplete := '~%';
  end;
  VDownloadSize := FProgressInfo.DownloadSize / 1024;
  VValueConverter := FValueToStringConverter.GetStatic;

  FProgressInfo.GetLastTileInfo(VZoom, VPoint, VSize);

  tbxStatusBar.Panels.Items[0].Caption := 'z' + inttostr(VZoom + 1);

  if FProgressInfo.Finished then begin
    if not FFinished then begin
      FFinished := True;
      UpdateTimer.Enabled := false;
      UpdateMemoProgressForm;
      Self.Caption := SAS_MSG_LoadComplete + ' ' + FFormCaption;
      lblToProcessValue.Caption := inttostr(VTotal) + ' ' + SAS_STR_Files;
      lblProcessedValue.Caption := inttostr(FProgressInfo.Processed) + ' ' + SAS_STR_Files;
      lblDownloadedValue.Caption := inttostr(FProgressInfo.Downloaded) + ' (' + VValueConverter.DataSizeConvert(VDownloadSize) + ') ' + SAS_STR_Files;
      lblTimeToFinishValue.Caption := GetTimeEnd(VTotal, FProgressInfo.Processed, FProgressInfo.ElapsedTime);
      lblSizeToFinishValue.Caption := GetLenEnd(VTotal, FProgressInfo.Processed, FProgressInfo.Downloaded, VDownloadSize);
      FProgress.Max := VTotal;
      FProgress.Progress1 := FProgressInfo.Processed;
      FProgress.Progress2 := FProgressInfo.Downloaded;
      tbxStatusBar.Panels.Items[1].Caption := '';
      tbxStatusBar.Panels.Items[2].Caption := '';
      Repaint;
      if FProgressInfo.AutoCloseAtFinish then begin
        btnCloseClick(nil);
      end;
    end;
  end else begin
    UpdateMemoProgressForm;
    if (FStoped) then begin
      Self.Caption := Format(SAS_STR_Paused, [VComplete]) + ' ' + FFormCaption;
    end else begin
      Self.Caption := Format(SAS_STR_DownloadingCaption, [VComplete]) + ' ' + FFormCaption;
      Application.ProcessMessages;
      lblToProcessValue.Caption := inttostr(VTotal) + ' ' + SAS_STR_Files;
      lblProcessedValue.Caption := inttostr(FProgressInfo.Processed) + ' ' + SAS_STR_Files;
      lblDownloadedValue.Caption := inttostr(FProgressInfo.Downloaded) + ' (' + VValueConverter.DataSizeConvert(VDownloadSize) + ') ' + SAS_STR_Files;
      lblTimeToFinishValue.Caption := GetTimeEnd(VTotal, FProgressInfo.Processed, FProgressInfo.ElapsedTime);
      lblSizeToFinishValue.Caption := GetLenEnd(VTotal, FProgressInfo.Processed, FProgressInfo.Downloaded, VDownloadSize);
      UpdateMemoProgressForm;
      FProgress.Max := VTotal;
      FProgress.Progress1 := FProgressInfo.Processed;
      FProgress.Progress2 := FProgressInfo.Downloaded;
    end;
    if (VPoint.X >= 0) and (VPoint.Y >= 0) then begin
      tbxStatusBar.Panels.Items[1].Caption := Format('X:%d; Y:%d', [VPoint.X, VPoint.Y]);
    end else begin
      tbxStatusBar.Panels.Items[1].Caption := '';
    end;
    if VSize > 0 then begin
      tbxStatusBar.Panels.Items[2].Caption := VValueConverter.DataSizeConvert(VSize / 1024);
    end else begin
      tbxStatusBar.Panels.Items[2].Caption := '';
    end;
  end;
end;

procedure TfrmProgressDownload.UpdateMemoProgressForm;
var
  i: Cardinal;
  VAddToMemo: String;
begin
  VAddToMemo := FProgressInfo.LogProvider.GetLastMessages(100, FLastLogID, i);
  if i > 0 then begin
    if mmoLog.Lines.Count > 5000 then begin
      mmoLog.Lines.Clear;
    end;
    mmoLog.Lines.Add(VAddToMemo);
  end;
end;

function TfrmProgressDownload.GetLenEnd(
  loadAll, obrab, loaded: Int64;
  len: Double
): string;
var
  VValueConverter: IValueToStringConverter;
begin
  if loaded = 0 then begin
    result := '~ Kb';
  end else begin
    VValueConverter := FValueToStringConverter.GetStatic;
    Result := VValueConverter.DataSizeConvert((len / loaded) * (loadAll - obrab));
  end;
end;

function TfrmProgressDownload.GetTimeEnd(
  loadAll, load: Int64;
  AElapsedTime: TDateTime
): String;
var
  dd: integer;
  VExpectedTime: TDateTime;
begin
  if load = 0 then begin
    result := '~';
  end else begin
    VExpectedTime := AElapsedTime * (loadAll / load);
    dd := DaysBetween(AElapsedTime, VExpectedTime);
    Result := '';
    if dd > 0 then begin
      Result := inttostr(dd) + ' days, ';
    end;
    Result := Result + FormatDateTime('hh:nn:ss', VExpectedTime - AElapsedTime);
  end;
end;

procedure TfrmProgressDownload.UpdateTimerTimer(Sender: TObject);
begin
  CheckSessionAutosave;
  UpdateProgressForm;
end;

procedure TfrmProgressDownload.tbtmGotoMapClick(Sender: TObject);
begin
  FMainConfig.MainMapGUID := FMapType.GUID;
end;

procedure TfrmProgressDownload.tbtmMarkClick(Sender: TObject);
begin
  if (FPolygon <> nil) and (FMarkDBGUI <> nil) then begin
    FMarkDBGUI.SaveMarkModal(nil, FPolygon);
  end;
end;

procedure TfrmProgressDownload.DoSaveSession(const ATargetFileName: string);
var
  VIniFile: TMemIniFile;
  VSLSData: IConfigDataWriteProvider;
  VSessionSection: IConfigDataWriteProvider;
begin
  if ATargetFileName <> '' then begin
    VIniFile := TMemIniFile.Create(ATargetFileName);
    try
      VSLSData := TConfigDataWriteProviderByIniFile.CreateWithOwn(VIniFile);
      VIniFile := nil;
    finally
      VIniFile.Free;
    end;
    VSessionSection := VSLSData.GetOrCreateSubItem('Session');
    FProgressInfo.SaveState(VSessionSection);

    mmoLog.Lines.Add(rsSessionSavedToFile + ATargetFileName);
  end;
end;

procedure TfrmProgressDownload.CheckSessionAutosave;

  function _CreateFileUnique(out AFileName: string): Boolean;
  const
    cTryCount = 10;
  var
    I: Integer;
    VHandle: THandle;
    VDateTimeFmt: string;
    VWorkerIndex, VWorkersCount: Integer;
  begin
    if not FIsSessionInitialized then begin
      FSessionPrefix := FProgressInfo.SessionAutosavePrefix;
      if FSessionPrefix <> '' then begin
        FSessionPrefix := StringReplace(FSessionPrefix, '/', '\', [rfReplaceAll]);
      end;
      FSessionPrefix := ExtractFilePath(ParamStr(0)) + 'AutoSave\' + FSessionPrefix;
      if not ForceDirectories(ExtractFilePath(FSessionPrefix)) then begin
        RaiseLastOSError;
      end;
      FProgressInfo.GetWorkerInfo(VWorkerIndex, VWorkersCount);
      if VWorkersCount > 1 then begin
        FSessionPrefix := FSessionPrefix + Format('%.2d_', [VWorkerIndex+1]);
      end;
    end;

    if FProgressInfo.SessionAutosavePrefix = '' then begin
      VDateTimeFmt := 'yymmdd_hhnnss_zzz';
    end else begin
      VDateTimeFmt := 'hhnnss_zzz';
    end;

    I := 0;
    while I < cTryCount do begin
      AFileName := FSessionPrefix + FormatDateTime(VDateTimeFmt, Now) + '.sls';
      if not FileExists(AFileName) then begin
        VHandle :=
          CreateFile(
            PChar(AFileName),
            GENERIC_READ or GENERIC_WRITE,
            0,
            nil,
            CREATE_NEW,
            FILE_ATTRIBUTE_NORMAL,
            0
          );
        if VHandle <> INVALID_HANDLE_VALUE then begin
          FileClose(VHandle);
          Break;
        end;
      end;
      Sleep(100);
      Inc(I);
    end;
    Result := I < cTryCount;
  end;

var
  VInterval: Integer;
  VMinutes: Integer;
  VFileName: string;
  VErrMsg: string;
begin
  VInterval := FProgressInfo.SessionAutosaveInterval;
  if VInterval <= 0 then begin
    // disabled
    Exit;
  end;

  VMinutes := Round((FProgressInfo.ElapsedTime - FLastElapsedTime) * 24 * 60);
  if FIsSessionInitialized and (VMinutes < VInterval) then begin
    // timeout is not expired yet
    Exit;
  end;

  try
    if not _CreateFileUnique(VFileName) then begin
      // error
      Exit;
    end;
    DoSaveSession(VFileName);

    if FSessionFileName <> '' then begin
      if FSessionFileNameBack <> '' then begin
        DeleteFile(FSessionFileNameBack);
      end;
      FSessionFileNameBack := ChangeFileExt(FSessionFileName, '.bk');
      if not RenameFile(FSessionFileName, FSessionFileNameBack) then begin
        FSessionFileNameBack := FSessionFileName;
      end;
    end;
    FSessionFileName := VFileName;

    FLastElapsedTime := FProgressInfo.ElapsedTime;
  except
    on E: Exception do begin
      VErrMsg := rsFailedSessionSave + VFileName + #13#10 + E.ClassName + ': ' + E.Message;
      mmoLog.Lines.Add(VErrMsg);
      if not FIsSessionInitialized then begin
        MessageDlg(VErrMsg, mtError, [mbOK], -1);
      end;
    end;
  end;

  FIsSessionInitialized := True;
end;

procedure TfrmProgressDownload.tbtmSaveClick(Sender: TObject);
begin
  if SaveSessionDialog.Execute then begin
    DoSaveSession(SaveSessionDialog.FileName);
  end;
end;

procedure TfrmProgressDownload.FormClose(
  Sender: TObject;
  var Action: TCloseAction
);
begin
  UpdateTimer.Enabled := false;
  FCancelNotifier.NextOperation;
  if FSessionFileNameBack <> '' then begin
    DeleteFile(FSessionFileNameBack);
  end;
  Action := caFree;
  Application.MainForm.SetFocus;
end;

end.

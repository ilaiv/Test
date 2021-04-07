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

unit u_ThreadDownloadTiles;

interface

uses
  Types,
  Windows,
  SyncObjs,
  Classes,
  {$IFNDef UNICODE}
  Compatibility,
  {$ENDIF}
  i_Listener,
  i_LogSimple,
  i_MapVersionInfo,
  i_MapVersionRequest,
  i_NotifierOperation,
  i_GlobalDownloadConfig,
  i_TileRequestTask,
  i_TileRequestResult,
  i_DownloadInfoSimple,
  i_MapType,
  i_TileIterator,
  i_DownloadTaskProvider,
  i_RegionProcessProgressInfoDownload;

type
  TThreadDownloadTiles = class(TThread)
  private
    FWorkerIndex: Integer;
    FProgressInfo: IRegionProcessProgressInfoDownloadInternal;

    FAppClosingNotifier: INotifierOneOperation;
    FMapType: IMapType;
    FVersionForCheck: IMapVersionRequest;
    FVersionForDownload: IMapVersionInfo;
    FDownloadInfo: IDownloadInfoSimple;
    FSecondLoadTNE: boolean;
    FCheckTneOlderDate: Boolean;
    FReplaceTneOlderDate: TDateTime;
    FReplaceExistTiles: boolean;
    FCheckExistTileSize: boolean;
    FCheckExistTileDate: boolean;
    FDownloadTaskProvider: IDownloadTaskProvider;
    FDownloadConfig: IGlobalDownloadConfig;
    FCheckTileDate: TDateTime;
    
    FPausedSleepTime: Cardinal;
    FBanSleepTime: Cardinal;
    FProxyAuthErrorSleepTime: Cardinal;
    FDownloadErrorSleepTime: Cardinal;

    FTileRequestResult: ITileRequestResult;

    FRES_UserStop: string;
    FRES_ProcessedFile: string;
    FRES_LoadProcessRepl: string;
    FRES_LoadProcess: string;
    FRES_FileBeCreateTime: string;
    FRES_TneBeCreateTime: string;
    FRES_FileBeCreateLen: string;
    FRES_Authorization: string;
    FRES_WaitTime: string;
    FRES_Ban: string;
    FRES_BadMIME: string;
    FRES_TileNotExists: string;
    FRES_Noconnectionstointernet: string;
    FRES_FileExistsShort: string;
    FRES_ProcessFilesComplete: string;

    FOperationID: Integer;
    FCancelNotifier: INotifierOperation;
    FFinishEvent: TEvent;
    FTaskFinishNotifier: ITileRequestTaskFinishNotifier;

    FAppClosingListener: IListener;

    procedure OnTileDownloadFinish(
      const ATask: ITileRequestTask;
      const AResult: ITileRequestResult
    );
    procedure OnAppClosing;
    function ProcessResultAndCheckGotoNextTile(const AResult: ITileRequestResult): Boolean;
    procedure SleepCancelable(ATime: Cardinal);

    procedure PrepareStrings;

    procedure ProcessTask(
      const ATileIterator: ITileIterator;
      const ACancelNotifier: INotifierOneOperation
    );
  protected
    procedure Execute; override;
  public
    constructor Create(
      const AWorkerIndex: Integer;
      const ACancelNotifier: INotifierOperation;
      AOperationID: Integer;
      const AProgressInfo: IRegionProcessProgressInfoDownloadInternal;
      const AAppClosingNotifier: INotifierOneOperation;
      const AMapType: IMapType;
      const AVersionForCheck: IMapVersionRequest;
      const AVersionForDownload: IMapVersionInfo;
      const ADownloadTaskProvider: IDownloadTaskProvider;
      const ADownloadConfig: IGlobalDownloadConfig;
      const ADownloadInfo: IDownloadInfoSimple;
      AReplaceExistTiles: Boolean;
      ACheckExistTileSize: Boolean;
      ACheckExistTileDate: Boolean;
      const AReplaceOlderDate: TDateTime;
      ASecondLoadTNE: Boolean;
      ACheckTneOlderDate: Boolean;
      const AReplaceTneOlderDate: TDateTime
    );
    destructor Destroy; override;
  end;

implementation

uses
  SysUtils,
  i_DownloadResult,
  i_TileInfoBasic,
  i_TileDownloaderState,
  i_TileStorage,
  i_InterfaceListStatic,
  u_NotifierOperation,
  u_TileRequestTask,
  u_ListenerByEvent,
  u_ReadableThreadNames,
  u_ResStrings;

constructor TThreadDownloadTiles.Create(
  const AWorkerIndex: Integer;
  const ACancelNotifier: INotifierOperation;
  AOperationID: Integer;
  const AProgressInfo: IRegionProcessProgressInfoDownloadInternal;
  const AAppClosingNotifier: INotifierOneOperation;
  const AMapType: IMapType;
  const AVersionForCheck: IMapVersionRequest;
  const AVersionForDownload: IMapVersionInfo;
  const ADownloadTaskProvider: IDownloadTaskProvider;
  const ADownloadConfig: IGlobalDownloadConfig;
  const ADownloadInfo: IDownloadInfoSimple;
  AReplaceExistTiles, ACheckExistTileSize, ACheckExistTileDate: Boolean;
  const AReplaceOlderDate: TDateTime;
  ASecondLoadTNE: Boolean;
  ACheckTneOlderDate: Boolean;
  const AReplaceTneOlderDate: TDateTime
);
var
  VState: ITileDownloaderStateStatic;
begin
  Assert(ACancelNotifier <> nil);
  Assert(AProgressInfo <> nil);
  Assert(AAppClosingNotifier <> nil);
  Assert(AMapType <> nil);
  Assert(ADownloadTaskProvider <> nil);
  Assert(ADownloadConfig <> nil);
  Assert(ADownloadInfo <> nil);
  inherited Create(True);
  Priority := tpLower;
  FreeOnTerminate := True;

  FWorkerIndex := AWorkerIndex;
  FCancelNotifier := ACancelNotifier;
  FOperationID := AOperationID;
  FProgressInfo := AProgressInfo;
  FAppClosingNotifier := AAppClosingNotifier;
  FDownloadInfo := ADownloadInfo;
  FDownloadConfig := ADownloadConfig;
  FDownloadTaskProvider := ADownloadTaskProvider;

  FPausedSleepTime := 100;
  FBanSleepTime := 5000;
  FProxyAuthErrorSleepTime := 10000;
  FDownloadErrorSleepTime := 5000;
  Priority := tpLower;

  FReplaceExistTiles := AReplaceExistTiles;
  FCheckExistTileSize := ACheckExistTileSize;
  FMapType := AMapType;
  FVersionForCheck := AVersionForCheck;
  FVersionForDownload := AVersionForDownload;
  FCheckTileDate := AReplaceOlderDate;
  FCheckExistTileDate := ACheckExistTileDate;
  FSecondLoadTNE := ASecondLoadTNE;
  FCheckTneOlderDate := ACheckTneOlderDate;
  FReplaceTneOlderDate := AReplaceTneOlderDate;

  if FMapType = nil then begin
    Terminate;
    Exit;
  end;
  if not FMapType.Abilities.UseDownload then begin
    FProgressInfo.Log.WriteText(Format('Download of map %s disabled by map params', [FMapType.GUIConfig.Name.Value]), 10);
    Terminate;
    Exit;
  end;
  VState := FMapType.TileDownloadSubsystem.State.GetStatic;
  if not VState.Enabled then begin
    FProgressInfo.Log.WriteText(Format('Download of map %s disabled. Reason: %s', [FMapType.GUIConfig.Name.Value, VState.DisableReason]), 10);
    Terminate;
    Exit;
  end;

  PrepareStrings;

  FFinishEvent := TEvent.Create;

  FTaskFinishNotifier := TTileRequestTaskFinishNotifier.Create(Self.OnTileDownloadFinish);

  FAppClosingListener := TNotifyNoMmgEventListener.Create(Self.OnAppClosing);
  FAppClosingNotifier.Add(FAppClosingListener);
  FCancelNotifier.AddListener(FAppClosingListener);

  if FAppClosingNotifier.IsExecuted or FCancelNotifier.IsOperationCanceled(FOperationID) then begin
    OnAppClosing;
  end;
end;

destructor TThreadDownloadTiles.Destroy;
begin
  if Assigned(FTaskFinishNotifier) then begin
    FTaskFinishNotifier.Enabled := False;
    FTaskFinishNotifier := nil;
  end;

  if FFinishEvent <> nil then begin
    FTileRequestResult := nil;
    FFinishEvent.SetEvent;
  end;

  if Assigned(FCancelNotifier) and Assigned(FAppClosingListener) then begin
    FCancelNotifier.RemoveListener(FAppClosingListener);
    FCancelNotifier := nil;
  end;

  if Assigned(FAppClosingNotifier) and Assigned(FAppClosingListener) then begin
    FAppClosingNotifier.Remove(FAppClosingListener);
    FAppClosingNotifier := nil;
    FAppClosingListener := nil;
  end;

  FreeAndNil(FFinishEvent);
  inherited;
end;

procedure TThreadDownloadTiles.SleepCancelable(ATime: Cardinal);
begin
  FFinishEvent.WaitFor(ATime);
end;

procedure TThreadDownloadTiles.ProcessTask(
  const ATileIterator: ITileIterator;
  const ACancelNotifier: INotifierOneOperation
);
var
  VTile: TPoint;
  VZoom: Byte;
  VRequestTask: ITileRequestTask;
  VTileInfo: ITileInfoBasic;
  VGotoNextTile: Boolean;
  VProcessingTileMsg: string;
begin
  VZoom := FMapType.ProjectionSet.GetSuitableZoom(ATileIterator.TilesRect.Projection);
  FProgressInfo.SetZoom(VZoom);

  while ATileIterator.Next(VTile) do begin
    VGotoNextTile := False;
    while not VGotoNextTile do begin
      FFinishEvent.ResetEvent;
      if FProgressInfo.NeedPause then begin
        FProgressInfo.SetPaused;
        FProgressInfo.Log.WriteText(FRES_UserStop, 10);
        while FProgressInfo.NeedPause do begin
          if FCancelNotifier.IsOperationCanceled(FOperationID) then begin
            Exit;
          end;
          SleepCancelable(FPausedSleepTime);
        end;
        FProgressInfo.SetStarted;
      end;
      if FCancelNotifier.IsOperationCanceled(FOperationID) then begin
        Exit;
      end;

      // notify about current tile
      VProcessingTileMsg := Format('[z%d/x%d/y%d]' + #13#10 + '%s',
        [VZoom + 1, VTile.X, VTile.Y, FMapType.GetTileShowName(VTile, VZoom, FVersionForDownload)]);
      FProgressInfo.Log.WriteText(Format(FRES_ProcessedFile, [VProcessingTileMsg]), 0);

      // if gtimWithData - tile will be loaded, so we use gtimAsIs
      VTileInfo := FMapType.TileStorage.GetTileInfoEx(VTile, VZoom, FVersionForCheck, gtimAsIs);
      if Assigned(VTileInfo) and (VTileInfo.IsExists or VTileInfo.IsExistsTNE) then begin
        if VTileInfo.IsExists then begin
          if FReplaceExistTiles then begin
            FProgressInfo.Log.WriteText(FRES_LoadProcessRepl, 0);
          end else begin
            FProgressInfo.Log.WriteText(FRES_FileExistsShort, 0);
            VGotoNextTile := True;
          end;
          if not VGotoNextTile then begin
            if FCheckExistTileDate and (VTileInfo.LoadDate >= FCheckTileDate) then begin
              // skip existing newer tile
              FProgressInfo.Log.WriteText(FRES_FileBeCreateTime, 0);
              VGotoNextTile := True;
            end;
          end;
        end else if VTileInfo.IsExistsTNE then begin
          if FSecondLoadTNE then begin
            FProgressInfo.Log.WriteText(FRES_LoadProcess, 0);
          end else begin
            FProgressInfo.Log.WriteText('(tne exists)', 0);
            VGotoNextTile := True;
          end;
          if not VGotoNextTile then begin
            if FCheckTneOlderDate and (VTileInfo.LoadDate >= FReplaceTneOlderDate) then begin
              // skip existing newer tne
              FProgressInfo.Log.WriteText(FRES_TneBeCreateTime, 0);
              VGotoNextTile := True;
            end;
          end;
        end;
      end else begin
        FProgressInfo.Log.WriteText(FRES_LoadProcess, 0);
      end;
      if VGotoNextTile then begin
        FProgressInfo.AddProcessedTile(VTile);
      end else begin
        try
          // download tile
          VRequestTask := FMapType.TileDownloadSubsystem.GetRequestTask(
            ACancelNotifier,
            FCancelNotifier,
            FOperationID,
            FTaskFinishNotifier,
            VTile,
            VZoom,
            FVersionForDownload,
            FCheckExistTileSize
          );
          if VRequestTask <> nil then begin
            FTileRequestResult := nil;
            FMapType.TileDownloadSubsystem.Download(VRequestTask);
            if FCancelNotifier.IsOperationCanceled(FOperationID) then begin
              Exit;
            end;
            FFinishEvent.WaitFor(INFINITE);
            if FCancelNotifier.IsOperationCanceled(FOperationID) then begin
              Exit;
            end;
            VGotoNextTile := ProcessResultAndCheckGotoNextTile(FTileRequestResult);
            if FCancelNotifier.IsOperationCanceled(FOperationID) then begin
              Exit;
            end;
            if VGotoNextTile then begin
              FProgressInfo.AddProcessedTile(VTile);
            end;
          end else begin
            FProgressInfo.Log.WriteText('Download disabled', 0);
            VGotoNextTile := False;
            FProgressInfo.NeedPause := True;
          end;
        except
          on E: Exception do begin
            FProgressInfo.Log.WriteText(E.Message, 0);
            VGotoNextTile := True;
            FProgressInfo.AddProcessedTile(VTile);
          end;
        end;
      end;

      if FCancelNotifier.IsOperationCanceled(FOperationID) then begin
        Exit;
      end;
    end;
    if FCancelNotifier.IsOperationCanceled(FOperationID) then begin
      Exit;
    end;
  end;
end;

procedure TThreadDownloadTiles.Execute;
var
  I: Integer;
  VTilesTotal: Int64;
  VTasksList: IInterfaceListStatic;
  VSoftCancelNotifier: INotifierOneOperation;
begin
  try
    if Terminated then begin
      Exit;
    end;

    SetCurrentThreadName(Self.ClassName);
    Randomize;

    try
      FDownloadTaskProvider.GetTasksList(FWorkerIndex, VTilesTotal, VTasksList);

      if FCancelNotifier.IsOperationCanceled(FOperationID) then begin
        Exit;
      end;

      FProgressInfo.SetTotalToProcess(VTilesTotal);

      VSoftCancelNotifier :=
        TNotifierOneOperationByNotifier.Create(FCancelNotifier, FOperationID);

      if Assigned(VTasksList) then begin
        for I := 0 to VTasksList.Count - 1 do begin
          ProcessTask(
            VTasksList.Items[I] as ITileIterator,
            VSoftCancelNotifier
          );
          if FCancelNotifier.IsOperationCanceled(FOperationID) then begin
            Exit;
          end;
        end;
      end;

      FProgressInfo.Log.WriteText(FRES_ProcessFilesComplete, 0);
    except
      on E: Exception do begin
        FProgressInfo.Log.WriteText(E.ClassName + ': ' + E.Message, 10);
      end;
    end;
  finally
    FProgressInfo.Finish;
  end;
end;

procedure TThreadDownloadTiles.OnAppClosing;
begin
  if Assigned(FTaskFinishNotifier) then begin
    FTaskFinishNotifier.Enabled := False;
  end;
  Terminate;
  if Assigned(FFinishEvent) then begin
    FFinishEvent.SetEvent;
  end;
end;

procedure TThreadDownloadTiles.OnTileDownloadFinish(
  const ATask: ITileRequestTask;
  const AResult: ITileRequestResult
);
begin
  FTileRequestResult := AResult;
  if Assigned(FFinishEvent) then begin
    FFinishEvent.SetEvent;
  end;
end;

procedure TThreadDownloadTiles.PrepareStrings;
begin
  FRES_UserStop := SAS_STR_UserStop;
  FRES_ProcessedFile := SAS_STR_ProcessedFile;
  FRES_LoadProcessRepl := SAS_STR_LoadProcessRepl;
  FRES_LoadProcess := SAS_STR_LoadProcess;
  FRES_FileBeCreateTime := SAS_MSG_FileBeCreateTime;
  FRES_TneBeCreateTime := SAS_MSG_TneBeCreateTime;
  FRES_FileBeCreateLen := SAS_MSG_FileBeCreateLen;
  FRES_Authorization := SAS_ERR_Authorization;
  FRES_WaitTime := SAS_ERR_WaitTime;
  FRES_Ban := SAS_ERR_Ban;
  FRES_BadMIME := SAS_ERR_BadMIME;
  FRES_TileNotExists := SAS_ERR_TileNotExists;
  FRES_Noconnectionstointernet := SAS_ERR_Noconnectionstointernet;
  FRES_FileExistsShort := SAS_ERR_FileExistsShort;
  FRES_ProcessFilesComplete := SAS_MSG_ProcessFilesComplete;
end;

function TThreadDownloadTiles.ProcessResultAndCheckGotoNextTile(
  const AResult: ITileRequestResult
): Boolean;
var
  VResultError: ITileRequestResultError;
  VResultOk: IDownloadResultOk;
  VResultBadContentType: IDownloadResultBadContentType;
  VResultDownloadError: IDownloadResultError;
  VResultWithDownload: ITileRequestResultWithDownloadResult;
begin
  if Supports(AResult, ITileRequestResultWithDownloadResult, VResultWithDownload) then begin
    FFinishEvent.ResetEvent;
    if Supports(VResultWithDownload.DownloadResult, IDownloadResultOk, VResultOk) then begin
      if Supports(AResult, ITileRequestResultError, VResultError) then begin
        // tile downloaded successfully downloaded, but not saved
        FProgressInfo.Log.WriteText('Error: ' + VResultError.ErrorText, 0);
        FProgressInfo.NeedPause := True;
        Result := False;
      end else begin
        // tile downloaded successfully
        FProgressInfo.Log.WriteText('(Ok!)', 0);
        FProgressInfo.AddDownloadedTile(AResult.Request.Tile, VResultOk.Data.Size);
        Result := True;
      end;
      FDownloadInfo.Add(1, VResultOk.Data.Size);
    end else if Supports(VResultWithDownload.DownloadResult, IDownloadResultNotNecessary) then begin
      // same file size - assuming file the same
      FProgressInfo.Log.WriteText(FRES_FileBeCreateLen, 0);
      FProgressInfo.AddNotNecessaryTile(AResult.Request.Tile);
      Result := True;
    end else if Supports(VResultWithDownload.DownloadResult, IDownloadResultProxyError) then begin
      FProgressInfo.Log.WriteText(FRES_Authorization + #13#10 + Format(FRES_WaitTime, [FProxyAuthErrorSleepTime div 1000]), 10);
      SleepCancelable(FProxyAuthErrorSleepTime);
      Result := false;
    end else if Supports(VResultWithDownload.DownloadResult, IDownloadResultBanned) then begin
      FProgressInfo.Log.WriteText(FRES_Ban + #13#10 + Format(FRES_WaitTime, [FBanSleepTime div 1000]), 10);
      SleepCancelable(FBanSleepTime);
      Result := false;
    end else if Supports(VResultWithDownload.DownloadResult, IDownloadResultBadContentType, VResultBadContentType) then begin
      FProgressInfo.Log.WriteText(Format(FRES_BadMIME, [VResultBadContentType.ContentType]), 1);
      Result := True;
    end else if Supports(VResultWithDownload.DownloadResult, IDownloadResultDataNotExists) then begin
      FProgressInfo.Log.WriteText(FRES_TileNotExists, 1);
      Result := True;
    end else if Supports(VResultWithDownload.DownloadResult, IDownloadResultError, VResultDownloadError) then begin
      if Supports(VResultWithDownload.DownloadResult, IDownloadResultNoConnetctToServer) then begin
        FProgressInfo.Log.WriteText(VResultDownloadError.ErrorText + #13#10 + Format(FRES_WaitTime, [FDownloadErrorSleepTime div 1000]), 10);
        SleepCancelable(FDownloadErrorSleepTime);
        Result := false;
      end else begin
        FProgressInfo.Log.WriteText(FRES_Noconnectionstointernet + #13#10 + Format(FRES_WaitTime, [FDownloadErrorSleepTime div 1000]), 10);
        SleepCancelable(FDownloadErrorSleepTime);
        if FDownloadConfig.IsGoNextTileIfDownloadError then begin
          Result := True;
        end else begin
          Result := False;
        end;
      end;
    end else begin
      FProgressInfo.Log.WriteText('Unknown download result', 10);
      Result := False;
    end;
  end else begin
    if Supports(AResult, ITileRequestResultCanceled) then begin
      Result := False;
    end else begin
      Result := True;
    end;
  end;
end;

end.

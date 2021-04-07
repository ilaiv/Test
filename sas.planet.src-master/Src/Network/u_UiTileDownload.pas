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

unit u_UiTileDownload;

interface

uses
  SysUtils,
  t_CommonTypes,
  i_Notifier,
  i_NotifierOperation,
  i_NotifierTime,
  i_Listener,
  i_ListenerTime,
  i_DownloadUIConfig,
  i_DownloadInfoSimple,
  i_BackgroundTask,
  i_MapType,
  i_MapTypeSetChangeable,
  i_TileError,
  i_TileRequestTask,
  i_TileRequestResult,
  i_TileDownloaderState,
  i_GlobalInternetState,
  i_TileRect,
  i_TileRectChangeable,
  i_ListenerNotifierLinksList,
  u_UiTileRequestManager,
  u_BaseInterfacedObject;

type
  TUiTileDownload = class(TBaseInterfacedObject)
  private
    FConfig: IDownloadUIConfig;
    FGCNotifier: INotifierTime;
    FAppClosingNotifier: INotifierOneOperation;
    FTileRect: ITileRectChangeable;
    FMapType: IMapType;
    FActiveMaps: IMapTypeSetChangeable;
    FDownloadInfo: IDownloadInfoSimple;
    FGlobalInternetState: IGlobalInternetState;
    FErrorLogger: ITileErrorLogger;

    FCS: IReadWriteSync;
    FLinksList: IListenerNotifierLinksList;
    FDownloadTask: IBackgroundTask;
    FTTLListener: IListenerTimeWithUsedFlag;
    FCacheTileInfoTTLListener: IListener;
    FCacheTileInfoTTLNotifier: INotifier;
    FDownloadState: ITileDownloaderStateChangeble;

    FUseDownload: TTileSource;
    FTileMaxAgeInInternet: TDateTime;
    FTilesOut: Integer;

    FRequestManager: TUiTileRequestManager;

    FMapActive: Boolean;
    FTaskFinishNotifier: ITileRequestTaskFinishNotifier;
    FSoftCancelNotifier: INotifierOneOperation;
    FHardCancelNotifierInternal: INotifierOperationInternal;

    procedure OnTTLTrim;
    procedure OnMemCacheTTLTrim;
    procedure OnPosChange;
    procedure OnMapTypeActiveChange;
    procedure OnConfigChange;
    procedure OnVersionConfigChange;
    procedure DoProcessDownloadRequests(
      AOperationID: Integer;
      const ACancelNotifier: INotifierOperation
    );
    procedure RestartDownloadIfNeed;
    procedure OnTileDownloadFinish(
      const ATask: ITileRequestTask;
      const AResult: ITileRequestResult
    );
    procedure OnAppClosing;
  public
    constructor Create(
      const AConfig: IDownloadUIConfig;
      const AGCNotifier: INotifierTime;
      const AAppClosingNotifier: INotifierOneOperation;
      const ATileRect: ITileRectChangeable;
      const AMapType: IMapType;
      const AActiveMaps: IMapTypeSetChangeable;
      const ADownloadInfo: IDownloadInfoSimple;
      const AGlobalInternetState: IGlobalInternetState;
      const AErrorLogger: ITileErrorLogger
    );
    destructor Destroy; override;
  end;

implementation

uses
  Types,
  u_Synchronizer,
  i_DownloadResult,
  i_Projection,
  i_TileInfoBasic,
  i_TileStorage,
  i_TileRequest,
  i_MapVersionRequest,
  u_Notifier,
  u_NotifierOperation,
  u_ListenerNotifierLinksList,
  u_ListenerByEvent,
  u_ListenerTime,
  u_TileRect,
  u_TileRequestTask,
  u_BackgroundTask,
  u_TileRectChangeableByOtherTileRect,
  u_TileErrorInfo;

{ TUiTileDownload }

constructor TUiTileDownload.Create(
  const AConfig: IDownloadUIConfig;
  const AGCNotifier: INotifierTime;
  const AAppClosingNotifier: INotifierOneOperation;
  const ATileRect: ITileRectChangeable;
  const AMapType: IMapType;
  const AActiveMaps: IMapTypeSetChangeable;
  const ADownloadInfo: IDownloadInfoSimple;
  const AGlobalInternetState: IGlobalInternetState;
  const AErrorLogger: ITileErrorLogger
);
begin
  inherited Create;

  FConfig := AConfig;
  FGCNotifier := AGCNotifier;
  FAppClosingNotifier := AAppClosingNotifier;
  FMapType := AMapType;
  FActiveMaps := AActiveMaps;
  FDownloadInfo := ADownloadInfo;
  FGlobalInternetState := AGlobalInternetState;
  FErrorLogger := AErrorLogger;

  FTileRect :=
    TTileRectChangeableByOtherTileRect.Create(
      ATileRect,
      FMapType.TileStorage.ProjectionSet,
      GSync.SyncVariable.Make(Self.ClassName + 'TileRectMain'),
      GSync.SyncVariable.Make(Self.ClassName + 'TileRectResult')
    );

  FDownloadState := FMapType.TileDownloadSubsystem.State;

  FRequestManager := TUiTileRequestManager.Create(FConfig.MapUiRequestCount);

  FSoftCancelNotifier := nil;
  FHardCancelNotifierInternal :=
    TNotifierOperation.Create(
      TNotifierBase.Create(GSync.SyncVariable.Make(Self.ClassName + 'Notifier'))
    );

  FCS := GSync.SyncStd.Make(Self.ClassName);
  FTaskFinishNotifier := TTileRequestTaskFinishNotifier.Create(Self.OnTileDownloadFinish);

  FLinksList := TListenerNotifierLinksList.Create;

  FLinksList.Add(
    TNotifyNoMmgEventListener.Create(Self.OnConfigChange),
    FConfig.ChangeNotifier
  );
  FLinksList.Add(
    TNotifyNoMmgEventListener.Create(Self.OnMapTypeActiveChange),
    FActiveMaps.ChangeNotifier
  );
  FLinksList.Add(
    TNotifyNoMmgEventListener.Create(Self.OnMapTypeActiveChange),
    FDownloadState.ChangeNotifier
  );
  FLinksList.Add(
    TNotifyNoMmgEventListener.Create(Self.OnPosChange),
    FTileRect.ChangeNotifier
  );
  FLinksList.Add(
    TNotifyNoMmgEventListener.Create(Self.OnAppClosing),
    FAppClosingNotifier
  );
  FLinksList.Add(
    TNotifyNoMmgEventListener.Create(Self.OnVersionConfigChange),
    FMapType.VersionRequestConfig.ChangeNotifier
  );

  FTTLListener := TListenerTTLCheck.Create(Self.OnTTLTrim, 300000);
  FGCNotifier.Add(FTTLListener);

  if
    FMapType.StorageConfig.UseMemCache and
    FMapType.Zmp.TileDownloaderConfig.RestartDownloadOnMemCacheTTL
  then begin
    Assert(FMapType.CacheTileInfo <> nil);
    FCacheTileInfoTTLListener := TNotifyNoMmgEventListener.Create(Self.OnMemCacheTTLTrim);
    FCacheTileInfoTTLNotifier := FMapType.CacheTileInfo.ClearByTTLNotifier;
    FCacheTileInfoTTLNotifier.Add(FCacheTileInfoTTLListener);
  end else begin
    FCacheTileInfoTTLListener := nil;
    FCacheTileInfoTTLNotifier := nil;
  end;

  FLinksList.ActivateLinks;
  OnConfigChange;
  OnMapTypeActiveChange;
  OnPosChange;
end;

destructor TUiTileDownload.Destroy;
begin
  if Assigned(FTaskFinishNotifier) then begin
    FTaskFinishNotifier.Enabled := False;
    FTaskFinishNotifier := nil;
  end;

  if Assigned(FCacheTileInfoTTLListener) and Assigned(FCacheTileInfoTTLNotifier) then begin
    FCacheTileInfoTTLNotifier.Remove(FCacheTileInfoTTLListener);
    FCacheTileInfoTTLListener := nil;
    FCacheTileInfoTTLNotifier := nil;
  end;

  if Assigned(FGCNotifier) then begin
    if Assigned(FTTLListener) then begin
      FGCNotifier.Remove(FTTLListener);
      FTTLListener := nil;
    end;
    FGCNotifier := nil;
  end;
  if Assigned(FLinksList) then begin
    FLinksList.DeactivateLinks;
  end;

  if Assigned(FCS) then begin
    FCS.BeginWrite;
    try
      if Assigned(FDownloadTask) then begin
        FDownloadTask.StopExecute;
        FDownloadTask.Terminate;
        FDownloadTask := nil;
      end;
    finally
      FCS.EndWrite;
    end;
  end;

  FreeAndNil(FRequestManager);

  FCS := nil;

  inherited;
end;

procedure TUiTileDownload.OnAppClosing;
begin
  if Assigned(FHardCancelNotifierInternal) then begin
    FHardCancelNotifierInternal.NextOperation;
  end;
  if Assigned(FTaskFinishNotifier) then begin
    FTaskFinishNotifier.Enabled := False;
  end;
  OnTTLTrim;
end;

procedure TUiTileDownload.OnMemCacheTTLTrim;
begin
  RestartDownloadIfNeed;
end;

procedure TUiTileDownload.OnVersionConfigChange;
begin
  if Assigned(FHardCancelNotifierInternal) then begin
    FHardCancelNotifierInternal.NextOperation;
  end;
  RestartDownloadIfNeed;
end;

procedure TUiTileDownload.OnConfigChange;
begin
  FConfig.LockRead;
  try
    FUseDownload := FConfig.UseDownload;
    FTileMaxAgeInInternet := FConfig.TileMaxAgeInInternet;
    FTilesOut := FConfig.TilesOut;
  finally
    FConfig.UnlockRead;
  end;
  if not (FUseDownload in [tsInternet, tsCacheInternet]) then begin
    if Assigned(FHardCancelNotifierInternal) then begin
      FHardCancelNotifierInternal.NextOperation;
    end;
  end;
  RestartDownloadIfNeed;
end;

procedure TUiTileDownload.OnMapTypeActiveChange;
begin
  if FDownloadState.GetStatic.Enabled then begin
    FMapActive := FActiveMaps.GetStatic.IsExists(FMapType.GUID);
  end else begin
    FMapActive := False;
  end;
  if not FMapActive then begin
    if Assigned(FHardCancelNotifierInternal) then begin
      FHardCancelNotifierInternal.NextOperation;
    end;
  end;
  RestartDownloadIfNeed;
end;

procedure TUiTileDownload.OnPosChange;
begin
  RestartDownloadIfNeed;
end;

procedure TUiTileDownload.DoProcessDownloadRequests(
  AOperationID: Integer;
  const ACancelNotifier: INotifierOperation
);
var
  VTile: TPoint;
  VTileRect: ITileRect;
  VProjection: IProjection;
  VMapTileRect: TRect;
  VDownloadTileRect: ITileRect;
  VZoom: Byte;
  VNeedDownload: Boolean;
  VTask: ITileRequestTask;
  VVersionInfo: IMapVersionRequest;
  VTileInfo: ITileInfoBasic;
  VCurrentOperation: Integer;
  VStorage: ITileStorage;
begin
  FTTLListener.UpdateUseTime;

  VStorage := FMapType.TileStorage;
  VVersionInfo := FMapType.VersionRequest.GetStatic;

  VTileRect := FTileRect.GetStatic;

  if VTileRect <> nil then begin
    ACancelNotifier.AddListener(FRequestManager.SessionCancelListener);
    FSoftCancelNotifier := TNotifierOneOperationByNotifier.Create(ACancelNotifier, AOperationID);
    VCurrentOperation := FHardCancelNotifierInternal.CurrentOperation;
    try
      VProjection := FMapType.ProjectionSet.GetSuitableProjection(VTileRect.Projection);
      Assert(VProjection.IsSame(VTileRect.Projection));
      VZoom := VTileRect.GetZoom;

      VMapTileRect := VTileRect.Rect;
      Dec(VMapTileRect.Left, FTilesOut);
      Dec(VMapTileRect.Top, FTilesOut);
      Inc(VMapTileRect.Right, FTilesOut);
      Inc(VMapTileRect.Bottom, FTilesOut);
      VProjection.ValidateTileRect(VMapTileRect);
      VDownloadTileRect := TTileRect.Create(VTileRect.Projection, VMapTileRect);

      FRequestManager.InitSession(VDownloadTileRect, VVersionInfo.BaseVersion);

      while FRequestManager.Acquire(VTile) do begin
        VNeedDownload := False;
        if (FUseDownload = tsCache) then begin
          break;
        end;
        VTileInfo := VStorage.GetTileInfoEx(VTile, VZoom, VVersionInfo, gtimWithoutData);
        if Assigned(VTileInfo) and (VTileInfo.IsExists or VTileInfo.IsExistsTNE) then begin
          if FUseDownload = tsInternet then begin
            if Now - VTileInfo.LoadDate > FTileMaxAgeInInternet then begin
              VNeedDownload := True;
            end;
          end else begin
            VNeedDownload := False;
          end;
        end else begin
          VNeedDownload := True;
        end;

        if ACancelNotifier.IsOperationCanceled(AOperationID) then begin
          FRequestManager.Release(VTile, VZoom, VVersionInfo.BaseVersion, True);
          Break;
        end;

        VTask := nil;
        if VNeedDownload then begin
          VTask :=
            FMapType.TileDownloadSubsystem.GetRequestTask(
              FSoftCancelNotifier,
              FHardCancelNotifierInternal as INotifierOperation,
              VCurrentOperation,
              FTaskFinishNotifier,
              VTile,
              VZoom,
              VVersionInfo.BaseVersion,
              False
            );
        end;

        if VTask <> nil then begin
          FGlobalInternetState.IncQueueCount;
          FMapType.TileDownloadSubsystem.Download(VTask);
        end else begin
          FRequestManager.Release(VTile, VZoom, VVersionInfo.BaseVersion, VNeedDownload);
        end;
      end;
    finally
      ACancelNotifier.RemoveListener(FRequestManager.SessionCancelListener);
    end;
  end;
end;

procedure TUiTileDownload.OnTileDownloadFinish(
  const ATask: ITileRequestTask;
  const AResult: ITileRequestResult
);
var
  VResultWithDownload: ITileRequestResultWithDownloadResult;
  VDownloadResultOk: IDownloadResultOk;
  VResultDownloadError: IDownloadResultError;
  VResultNotNecessary: IDownloadResultNotNecessary;
  VResultDataNotExists: IDownloadResultDataNotExists;
  VRequestError: ITileRequestResultError;
  VError: ITileErrorInfo;
  VTileRequest: ITileRequest;
begin
  Assert(ATask <> nil);

  FTTLListener.UpdateUseTime;

  FGlobalInternetState.DecQueueCount;

  Assert(Assigned(FRequestManager));

  VTileRequest := ATask.TileRequest;
  FRequestManager.Release(
    VTileRequest.Tile,
    VTileRequest.Zoom,
    VTileRequest.VersionInfo,
    Supports(AResult, ITileRequestResultCanceled)
  );

  VError := nil;
  if Supports(AResult, ITileRequestResultError, VRequestError) then begin
    VError :=
      TTileErrorInfoByTileRequestResult.Create(
        FMapType.GUID,
        VRequestError
      );
  end else if Supports(AResult, ITileRequestResultWithDownloadResult, VResultWithDownload) then begin
    if Supports(VResultWithDownload.DownloadResult, IDownloadResultOk, VDownloadResultOk) then begin
      if FDownloadInfo <> nil then begin
        FDownloadInfo.Add(1, VDownloadResultOk.Data.Size);
      end;
    end else if Supports(VResultWithDownload.DownloadResult, IDownloadResultDataNotExists, VResultDataNotExists) then begin
      VError :=
        TTileErrorInfoByDataNotExists.Create(
          FMapType.GUID,
          ATask.TileRequest.Zoom,
          ATask.TileRequest.Tile,
          VResultDataNotExists
        );
    end else if Supports(VResultWithDownload.DownloadResult, IDownloadResultError, VResultDownloadError) then begin
      VError :=
        TTileErrorInfoByDownloadResultError.Create(
          FMapType.GUID,
          ATask.TileRequest.Zoom,
          ATask.TileRequest.Tile,
          VResultDownloadError
        );
    end else if Supports(VResultWithDownload.DownloadResult, IDownloadResultNotNecessary, VResultNotNecessary) then begin
      VError :=
        TTileErrorInfoByNotNecessary.Create(
          FMapType.GUID,
          ATask.TileRequest.Zoom,
          ATask.TileRequest.Tile,
          VResultNotNecessary
        );
    end else begin
      VError :=
        TTileErrorInfo.Create(
          FMapType.GUID,
          ATask.TileRequest.Zoom,
          ATask.TileRequest.Tile,
          'Unexpected error'
        );
    end;
  end;
  if VError <> nil then begin
    if FErrorLogger <> nil then begin
      FErrorLogger.LogError(VError);
    end;
  end;
end;

procedure TUiTileDownload.OnTTLTrim;
var
  VDownloadTask: IBackgroundTask;
begin
  FCS.BeginWrite;
  try
    VDownloadTask := FDownloadTask;
    if VDownloadTask <> nil then begin
      FDownloadTask := nil;
      VDownloadTask.StopExecute;
      VDownloadTask.Terminate;
    end;
  finally
    FCS.EndWrite;
  end;
end;

procedure TUiTileDownload.RestartDownloadIfNeed;
var
  VDownloadTask: IBackgroundTask;
  VTileRect: ITileRect;
begin
  FCS.BeginWrite;
  try
    VDownloadTask := FDownloadTask;
    if VDownloadTask <> nil then begin
      VDownloadTask.StopExecute;
    end;

    if (FUseDownload in [tsInternet, tsCacheInternet]) and FMapActive then begin
      // allow download
      VTileRect := FTileRect.GetStatic;

      if (VTileRect <> nil) then begin
        if VDownloadTask = nil then begin
          VDownloadTask := TBackgroundTask.Create(
            FAppClosingNotifier,
            Self.DoProcessDownloadRequests,
            FConfig.ThreadConfig,
            Self.ClassName
          );
          VDownloadTask.Start;
          FDownloadTask := VDownloadTask;
        end;
        VDownloadTask.StartExecute;
      end;
    end;
  finally
    FCS.EndWrite;
  end;
end;

end.

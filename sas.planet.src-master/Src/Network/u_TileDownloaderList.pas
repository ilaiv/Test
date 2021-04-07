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

unit u_TileDownloaderList;

interface

uses
  SysUtils,
  i_SimpleFlag,
  i_Notifier,
  i_NotifierOperation,
  i_Listener,
  i_TileDownloaderConfig,
  i_TileDownloader,
  i_DownloaderFactory,
  i_TileDownloadResultSaver,
  i_TileDownloaderState,
  i_NotifierTime,
  i_TileDownloadRequestBuilderFactory,
  i_TileDownloaderList,
  u_BaseInterfacedObject;

type
  TTileDownloaderList = class(TBaseInterfacedObject, ITileDownloaderList)
  private
    FGCNotifier: INotifierTime;
    FAppClosingNotifier: INotifierOneOperation;
    FDownloaderFactory: IDownloaderFactory;
    FDownloadSystemState: ITileDownloaderStateChangeble;
    FTileDownloaderConfig: ITileDownloaderConfig;
    FResultSaver: ITileDownloadResultSaver;
    FRequestBuilderFactory: ITileDownloadRequestBuilderFactory;

    FChangeCounter: ICounter;
    FChangeNotifier: INotifierInternal;
    FConfigListener: IListener;
    FCS: IReadWriteSync;

    FStatic: ITileDownloaderListStatic;
    procedure OnConfigChange;
    function CreateDownloader: ITileDownloader;
  private
    function GetStatic: ITileDownloaderListStatic;
    function GetChangeNotifier: INotifier;
  public
    constructor Create(
      const AGCNotifier: INotifierTime;
      const AAppClosingNotifier: INotifierOneOperation;
      const ADownloaderFactory: IDownloaderFactory;
      const ADownloadSystemState: ITileDownloaderStateChangeble;
      const ATileDownloaderConfig: ITileDownloaderConfig;
      const AResultSaver: ITileDownloadResultSaver;
      const ARequestBuilderFactory: ITileDownloadRequestBuilderFactory
    );
    destructor Destroy; override;
  end;

implementation

uses
  u_Synchronizer,
  i_TileDownloadRequestBuilder,
  i_Downloader,
  u_Notifier,
  u_SimpleFlagWithInterlock,
  u_ListenerByEvent,
  u_LastResponseInfo,
  u_TileDownloadRequestBuilderLazy,
  u_DownloaderHttpWithTTL,
  u_TileDownloaderSimple,
  u_TileDownloaderListStatic;

{ TTileDownloaderList }

constructor TTileDownloaderList.Create(
  const AGCNotifier: INotifierTime;
  const AAppClosingNotifier: INotifierOneOperation;
  const ADownloaderFactory: IDownloaderFactory;
  const ADownloadSystemState: ITileDownloaderStateChangeble;
  const ATileDownloaderConfig: ITileDownloaderConfig;
  const AResultSaver: ITileDownloadResultSaver;
  const ARequestBuilderFactory: ITileDownloadRequestBuilderFactory
);
begin
  inherited Create;
  FGCNotifier := AGCNotifier;
  FAppClosingNotifier := AAppClosingNotifier;
  FDownloaderFactory := ADownloaderFactory;
  FDownloadSystemState := ADownloadSystemState;
  FTileDownloaderConfig := ATileDownloaderConfig;
  FResultSaver := AResultSaver;
  FRequestBuilderFactory := ARequestBuilderFactory;

  FChangeNotifier := TNotifierBase.Create(GSync.SyncVariable.Make(Self.ClassName + 'Notifier'));
  FCS := GSync.SyncVariable.Make(Self.ClassName);
  FChangeCounter := TCounterInterlock.Create;

  FConfigListener := TNotifyNoMmgEventListener.Create(Self.OnConfigChange);

  FTileDownloaderConfig.ChangeNotifier.Add(FConfigListener);
  FDownloadSystemState.ChangeNotifier.Add(FConfigListener);

  OnConfigChange;
end;

destructor TTileDownloaderList.Destroy;
begin
  if Assigned(FTileDownloaderConfig) and Assigned(FConfigListener) then begin
    FTileDownloaderConfig.ChangeNotifier.Remove(FConfigListener);
  end;
  if Assigned(FDownloadSystemState) and Assigned(FConfigListener) then begin
    FDownloadSystemState.ChangeNotifier.Remove(FConfigListener);
  end;

  FConfigListener := nil;
  FTileDownloaderConfig := nil;
  FRequestBuilderFactory := nil;
  FDownloadSystemState := nil;

  FCS := nil;
  inherited;
end;

function TTileDownloaderList.CreateDownloader: ITileDownloader;
var
  VDownloader: IDownloader;
  VTileDownloadRequestBuilder: ITileDownloadRequestBuilder;
begin
  VDownloader :=
    TDownloaderHttpWithTTL.Create(
      FGCNotifier,
      FDownloaderFactory,
      FTileDownloaderConfig.AllowUseCookie,
      FTileDownloaderConfig.DetectMIMEType
    );
  VTileDownloadRequestBuilder :=
    TTileDownloadRequestBuilderLazy.Create(
      VDownloader,
      FRequestBuilderFactory
    );
  Result :=
    TTileDownloaderSimple.Create(
      FAppClosingNotifier,
      VTileDownloadRequestBuilder,
      FTileDownloaderConfig.GetStatic,
      VDownloader,
      FResultSaver,
      TLastResponseInfo.Create
    );
end;

function TTileDownloaderList.GetChangeNotifier: INotifier;
begin
  Result := FChangeNotifier;
end;

function TTileDownloaderList.GetStatic: ITileDownloaderListStatic;
begin
  FCS.BeginRead;
  try
    Result := FStatic;
  finally
    FCS.EndRead;
  end;
end;

procedure TTileDownloaderList.OnConfigChange;
var
  I: Integer;
  VCount: Integer;
  VCounter: Integer;
  VList: array of ITileDownloader;
  VState: ITileDownloaderStateStatic;
  VStatic: ITileDownloaderListStatic;
begin
  VCounter := FChangeCounter.Inc;

  VCount := FTileDownloaderConfig.MaxConnectToServerCount;
  VState := FDownloadSystemState.GetStatic;

  if not VState.Enabled then begin
    VCount := 0;
  end;

  SetLength(VList, VCount);
  for I := 0 to VCount - 1 do begin
    VList[I] := CreateDownloader;
    if not FChangeCounter.CheckEqual(VCounter) then begin
      Exit;
    end;
  end;

  VStatic := TTileDownloaderListStatic.Create(VList);
  if not FChangeCounter.CheckEqual(VCounter) then begin
    Exit;
  end;

  FCS.BeginWrite;
  try
    FStatic := VStatic;
  finally
    FCS.EndWrite;
  end;

  FChangeNotifier.Notify(nil);
end;

end.

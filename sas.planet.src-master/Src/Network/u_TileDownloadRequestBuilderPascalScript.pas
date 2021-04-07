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

unit u_TileDownloadRequestBuilderPascalScript;

interface

uses
  Types,
  SysUtils,
  uPSRuntime,
  uPSUtils,
  i_Notifier,
  i_Listener,
  i_Projection,
  i_ProjectionSet,
  i_ProjectionType,
  i_CoordConverterSimple,
  i_NotifierOperation,
  i_TileDownloaderConfig,
  i_TileRequest,
  i_Downloader,
  i_DownloadChecker,
  i_LanguageManager,
  i_LastResponseInfo,
  i_ProjConverter,
  i_SimpleFlag,
  i_TileDownloadRequest,
  i_TileDownloadRequestBuilderConfig,
  i_PascalScriptGlobal,
  u_PascalScriptUrlTemplate,
  u_PSExecEx,
  u_TileDownloadRequestBuilder,
  u_TileDownloadRequestBuilderPascalScriptVars;

type
  TTileDownloadRequestBuilderPascalScript = class(TTileDownloadRequestBuilder)
  private
    FTileDownloaderConfig: ITileDownloaderConfig;
    FCheker: IDownloadChecker;
    FDownloader: IDownloader;
    FProjectionSet: IProjectionSet;
    FCoordConverter: ICoordConverterSimple;
    FDefProjConverter: IProjConverter;
    FProjFactory: IProjConverterFactory;
    FScriptBuffer: AnsiString;
    FPSGlobal: IPascalScriptGlobal;
    FPSUrlTemplate: TPascalScriptUrlTemplate;

    FLang: AnsiString;
    FLangManager: ILanguageManager;
    FLangListener: IListener;
    FLangChangeFlag: ISimpleFlag;

    FPSExec: TPSExecEx;
    FPSVars: TRequestBuilderVars;

    FUseUrlTemplateDirectly: Boolean;

    procedure PrepareCompiledScript(const ACompiledData: TbtString);
    procedure SetVar(
      const ALastResponseInfo: ILastResponseInfo;
      const ADownloaderConfig: ITileDownloaderConfigStatic;
      const ASource: ITileRequest;
      const ACancelNotifier: INotifierOperation;
      AOperationID: Integer
    );
    procedure OnLangChange;
  protected
    function BuildRequest(
      const ASource: ITileRequest;
      const ALastResponseInfo: ILastResponseInfo;
      const ACancelNotifier: INotifierOperation;
      AOperationID: Integer
    ): ITileDownloadRequest; override;
  public
    constructor Create(
      const ACompiledData: TbtString;
      const AConfig: ITileDownloadRequestBuilderConfig;
      const ATileDownloaderConfig: ITileDownloaderConfig;
      const AProjectionSet: IProjectionSet;
      const ACoordConverter: ICoordConverterSimple;
      const ADownloader: IDownloader;
      const ACheker: IDownloadChecker;
      const ADefProjConverter: IProjConverter;
      const AProjFactory: IProjConverterFactory;
      const ALangManager: ILanguageManager;
      const APSGlobal: IPascalScriptGlobal
    );
    destructor Destroy; override;
  end;

implementation

uses
  t_GeoTypes,
  t_PascalScript,
  i_BinaryData,
  i_MapVersionInfo,
  i_SimpleHttpDownloader,
  u_BinaryData,
  u_ListenerByEvent,
  u_TileDownloadRequest,
  u_SimpleHttpDownloader,
  u_SimpleFlagWithInterlock,
  u_PascalScriptWriteLn,
  u_ResStrings;

{ TTileRequestBuilderPascalScript }

constructor TTileDownloadRequestBuilderPascalScript.Create(
  const ACompiledData: TbtString;
  const AConfig: ITileDownloadRequestBuilderConfig;
  const ATileDownloaderConfig: ITileDownloaderConfig;
  const AProjectionSet: IProjectionSet;
  const ACoordConverter: ICoordConverterSimple;
  const ADownloader: IDownloader;
  const ACheker: IDownloadChecker;
  const ADefProjConverter: IProjConverter;
  const AProjFactory: IProjConverterFactory;
  const ALangManager: ILanguageManager;
  const APSGlobal: IPascalScriptGlobal
);
begin
  inherited Create(AConfig);
  FPSExec := nil;
  FTileDownloaderConfig := ATileDownloaderConfig;
  FProjectionSet := AProjectionSet;
  FLangManager := ALangManager;
  FDownloader := ADownloader;
  FDefProjConverter := ADefProjConverter;
  FProjFactory := AProjFactory;
  FPSGlobal := APSGlobal;
  FCheker := ACheker;

  FLangChangeFlag := TSimpleFlagWithInterlock.Create;

  FLangListener := TNotifyNoMmgEventListener.Create(Self.OnLangChange);
  FLangManager.ChangeNotifier.Add(FLangListener);

  FCoordConverter := ACoordConverter;

  FPSUrlTemplate :=
    TPascalScriptUrlTemplate.Create(
      FLangManager,
      FProjectionSet,
      AConfig
    );

  FUseUrlTemplateDirectly := ACompiledData = '';

  if not FUseUrlTemplateDirectly then begin
    PrepareCompiledScript(ACompiledData);
  end;

  OnLangChange;
end;

destructor TTileDownloadRequestBuilderPascalScript.Destroy;
begin
  if Assigned(FLangManager) and Assigned(FLangListener) then begin
    FLangManager.ChangeNotifier.Remove(FLangListener);
    FLangManager := nil;
    FLangListener := nil;
  end;

  FreeAndNil(FPSExec);
  FreeAndNil(FPSUrlTemplate);
  FCoordConverter := nil;
  FDownloader := nil;

  inherited;
end;

procedure TTileDownloadRequestBuilderPascalScript.OnLangChange;
begin
  FLangChangeFlag.SetFlag;
end;

function TTileDownloadRequestBuilderPascalScript.BuildRequest(
  const ASource: ITileRequest;
  const ALastResponseInfo: ILastResponseInfo;
  const ACancelNotifier: INotifierOperation;
  AOperationID: Integer
): ITileDownloadRequest;
var
  VResultUrl: string;
  VDownloaderConfig: ITileDownloaderConfigStatic;
  VPostData: IBinaryData;
begin
  Result := nil;
  if (ACancelNotifier <> nil) and (not ACancelNotifier.IsOperationCanceled(AOperationID)) then begin
    Lock;
    try
      if (ACancelNotifier <> nil) and (not ACancelNotifier.IsOperationCanceled(AOperationID)) then begin
        VDownloaderConfig := FTileDownloaderConfig.GetStatic;

        if FUseUrlTemplateDirectly then begin
          VResultUrl := FPSUrlTemplate.Render(ASource);
          if VResultUrl <> '' then begin
            Result :=
              TTileDownloadRequest.Create(
                AnsiString(VResultUrl),
                Config.RequestHeader,
                VDownloaderConfig.InetConfigStatic,
                FCheker,
                ASource
              );
          end;
          Exit;
        end;

        SetVar(
          ALastResponseInfo,
          VDownloaderConfig,
          ASource,
          ACancelNotifier,
          AOperationID
        );
        try
          if not FPSExec.RunScript then begin
            FPSExec.RaiseCurrentException;
          end;
        except
          FPSExec.Stop;
          raise;
        end;
        if FPSVars.ResultUrl <> '' then begin
          if FPSVars.PostData <> '' then begin
            VPostData := TBinaryData.CreateByAnsiString(FPSVars.PostData);
            Result :=
              TTileDownloadPostRequest.Create(
                FPSVars.ResultUrl,
                FPSVars.RequestHead,
                VPostData,
                VDownloaderConfig.InetConfigStatic,
                FCheker,
                ASource
              );
          end else begin
            Result :=
              TTileDownloadRequest.Create(
                FPSVars.ResultUrl,
                FPSVars.RequestHead,
                VDownloaderConfig.InetConfigStatic,
                FCheker,
                ASource
              );
          end;
        end;
        FScriptBuffer := FPSVars.ScriptBuffer;
      end;
    finally
      Unlock;
    end;
  end;
end;

procedure TTileDownloadRequestBuilderPascalScript.PrepareCompiledScript(
  const ACompiledData: TbtString
);

  function GetExecTimeRegMethodArray: TOnExecTimeRegMethodArray;
  begin
    SetLength(Result, 2);

    Result[0].Obj := nil;
    Result[0].Func := @ExecTimeReg_WriteLn;

    Result[1].Obj := FPSUrlTemplate;
    Result[1].Func := @ExecTimeReg_UrlTemplate;
  end;

begin
  FScriptBuffer := '';

  // create
  FPSExec := TPSExecEx.Create(nil, GetExecTimeRegMethodArray);

  // load
  if not FPSExec.LoadData(ACompiledData) then begin
    raise Exception.Create(
      SAS_ERR_PascalScriptByteCodeLoad + #13#10 +
      string(TIFErrorToString(FPSExec.ExceptionCode, FPSExec.ExceptionString))
    );
  end;

  // loaded - add variables
  FPSVars.ExecTimeInit(FPSExec);
end;

procedure TTileDownloadRequestBuilderPascalScript.SetVar(
  const ALastResponseInfo: ILastResponseInfo;
  const ADownloaderConfig: ITileDownloaderConfigStatic;
  const ASource: ITileRequest;
  const ACancelNotifier: INotifierOperation;
  AOperationID: Integer
);
var
  VUrlBase: AnsiString;
  VRequestHeader: AnsiString;
  VUseDownloader: Boolean;
  VSimpleDownloader: ISimpleHttpDownloader;
begin
  Config.LockRead;
  try
    VUrlBase := Config.UrlBase;
    VRequestHeader := Config.RequestHeader;
    VUseDownloader := Config.IsUseDownloader;
  finally
    Config.UnlockRead;
  end;

  if FLangChangeFlag.CheckFlagAndReset then begin
    FLang := AnsiString(FLangManager.GetCurrentLanguageCode);
  end;

  VSimpleDownloader := nil;
  if FDownloader <> nil then begin
    if VUseDownloader then begin
      VSimpleDownloader :=
        TSimpleHttpDownloader.Create(
          FDownloader,
          ADownloaderConfig.InetConfigStatic,
          ACancelNotifier,
          AOperationID
        );
    end;
  end;

  FPSVars.ExecTimeSet(
    VUrlBase,
    VRequestHeader,
    FScriptBuffer,
    FLang,
    FCoordConverter,
    FProjectionSet,
    VSimpleDownloader,
    ALastResponseInfo,
    ASource,
    FDefProjConverter,
    FProjFactory,
    FPSGlobal
  );

  FPSUrlTemplate.Request := ASource;
end;

end.

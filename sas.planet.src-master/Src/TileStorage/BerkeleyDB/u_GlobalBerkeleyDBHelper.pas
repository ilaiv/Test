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

unit u_GlobalBerkeleyDBHelper;

interface

uses
  Windows,
  Classes,
  SyncObjs,
  SysUtils,
  libdb51,
  i_Listener,
  i_PathConfig,
  i_InterfaceListSimple,
  i_GlobalBerkeleyDBHelper,
  i_BerkeleyDBEnv,
  i_TileStorageBerkeleyDBConfigStatic,
  u_BaseInterfacedObject;

type
  TGlobalBerkeleyDBHelper = class(TBaseInterfacedObject, IGlobalBerkeleyDBHelper)
  private
    FSaveErrorsToLog: Boolean;
    FLogFileStream: TFileStream;
    FFullBaseCachePath: string;
    FCacheConfigChangeListener: IListener;
    FBaseCachePath: IPathConfig;
    FEnvList: IInterfaceListSimple;
    FEnvCS: TCriticalSection;
    FLogCS: TCriticalSection;
    FFormatSettings: TFormatSettings;
    procedure LogMsg(const AMsg: string);
    procedure OnCacheConfigChange;
  private
    { IGlobalBerkeleyDBHelper }
    function AllocateEnvironment(
      const AIsReadOnly: Boolean;
      const AStorageConfig: ITileStorageBerkeleyDBConfigStatic;
      const AStorageEPSG: Integer;
      const AEnvRootPath: string
    ): IBerkeleyDBEnvironment;
    procedure FreeEnvironment(const AEnv: IBerkeleyDBEnvironment);
    procedure LogException(const EMsg: string);
  public
    constructor Create(const ABaseCachePath: IPathConfig);
    destructor Destroy; override;
  end;

procedure TryShowLastExceptionData;

implementation

{.$DEFINE LOG_EVN_OPERATIONS}

uses
  {$IFDEF EUREKALOG}
  ExceptionLog,
  {$ENDIF}
  u_FileSystemFunc,
  u_InterfaceListSimple,
  u_ListenerByEvent,
  u_BerkeleyDBEnv;

procedure TryShowLastExceptionData;
begin
  {$IFDEF EUREKALOG}
  ShowLastExceptionData;
  {$ENDIF}
end;

{ TGlobalBerkeleyDBHelper }

constructor TGlobalBerkeleyDBHelper.Create(const ABaseCachePath: IPathConfig);
begin
  Assert(ABaseCachePath <> nil);
  inherited Create;
  FBaseCachePath := ABaseCachePath;
  FEnvList := TInterfaceListSimple.Create;
  FEnvCS := TCriticalSection.Create;
  FLogCS := TCriticalSection.Create;
  FLogFileStream := nil;
  FFormatSettings.DateSeparator := '-';
  FFormatSettings.TimeSeparator := ':';
  FFormatSettings.DecimalSeparator := '.';
  FSaveErrorsToLog := True;
  FFullBaseCachePath := FBaseCachePath.FullPath;
  FCacheConfigChangeListener := TNotifyNoMmgEventListener.Create(Self.OnCacheConfigChange);
  Assert(FBaseCachePath.ChangeNotifier <> nil);
  FBaseCachePath.ChangeNotifier.Add(FCacheConfigChangeListener);
end;

destructor TGlobalBerkeleyDBHelper.Destroy;
begin
  if (FBaseCachePath <> nil) and (FCacheConfigChangeListener <> nil) then begin
    FBaseCachePath.ChangeNotifier.Remove(FCacheConfigChangeListener);
    FBaseCachePath := nil;
    FCacheConfigChangeListener := nil;
  end;
  FEnvList := nil;
  FreeAndNil(FEnvCS);
  FreeAndNil(FLogFileStream);
  FreeAndNil(FLogCS);
  inherited;
end;

procedure TGlobalBerkeleyDBHelper.OnCacheConfigChange;
begin
  FLogCS.Acquire;
  try
    FFullBaseCachePath := FBaseCachePath.FullPath;
    FreeAndNil(FLogFileStream);
  finally
    FLogCS.Release;
  end;
end;

function TGlobalBerkeleyDBHelper.AllocateEnvironment(
  const AIsReadOnly: Boolean;
  const AStorageConfig: ITileStorageBerkeleyDBConfigStatic;
  const AStorageEPSG: Integer;
  const AEnvRootPath: string
): IBerkeleyDBEnvironment;
var
  I: Integer;
  VPath: string;
  VEnv: IBerkeleyDBEnvironment;
begin
  Assert(AStorageConfig <> nil);
  Result := nil;
  {$IFDEF LOG_EVN_OPERATIONS}
  LogMsg(Format('Enter AllocateEnvironment [%s]', [AEnvRootPath]));
  {$ENDIF}
  FEnvCS.Acquire;
  try
    VPath := LowerCase(GetFullPath(FFullBaseCachePath, AEnvRootPath));
    for I := 0 to FEnvList.Count - 1 do begin
      VEnv := FEnvList.Items[I] as IBerkeleyDBEnvironment;
      if Assigned(VEnv) then begin
        if VEnv.RootPath = VPath then begin
          VEnv.ClientsCount := VEnv.ClientsCount + 1;
          Result := VEnv;
          {$IFDEF LOG_EVN_OPERATIONS}
          LogMsg(Format('Found existing env, ClientsCount = %d [%s]', [VEnv.ClientsCount, VPath]));
          {$ENDIF}
          Break;
        end;
      end;
    end;
    if not Assigned(Result) then begin
      {$IFDEF LOG_EVN_OPERATIONS}
      LogMsg(Format('Try create new env [%s]', [VPath]));
      {$ENDIF}
      VEnv := TBerkeleyDBEnv.Create(
        (Self as IGlobalBerkeleyDBHelper),
        AIsReadOnly,
        AStorageConfig,
        AStorageEPSG,
        VPath
      );
      FEnvList.Add(VEnv);
      Result := VEnv;
      {$IFDEF LOG_EVN_OPERATIONS}
      LogMsg(Format('Env created successful [%s]', [VPath]));
      {$ENDIF}
    end;
  finally
    FEnvCS.Release;
  end;
  {$IFDEF LOG_EVN_OPERATIONS}
  LogMsg(Format('Leave AllocateEnvironment [%s]', [AEnvRootPath]));
  {$ENDIF}
end;

procedure TGlobalBerkeleyDBHelper.FreeEnvironment(const AEnv: IBerkeleyDBEnvironment);
var
  I: Integer;
  VEnv: IBerkeleyDBEnvironment;
begin
  {$IFDEF LOG_EVN_OPERATIONS}
  LogMsg('Enter FreeEnvironment');
  {$ENDIF}
  FEnvCS.Acquire;
  try
    if Assigned(AEnv) then begin
      for I := 0 to FEnvList.Count - 1 do begin
        VEnv := FEnvList.Items[I] as IBerkeleyDBEnvironment;
        if Assigned(VEnv) then begin
          if (VEnv as IInterface) = (AEnv as IInterface) then begin
            {$IFDEF LOG_EVN_OPERATIONS}
            LogMsg(Format('Found assigned env, ClientsCount = %d [%s]', [VEnv.ClientsCount, VEnv.RootPath]));
            {$ENDIF}
            VEnv.ClientsCount := VEnv.ClientsCount - 1;
            if VEnv.ClientsCount <= 0 then begin
              FEnvList.Remove(VEnv);
              {$IFDEF LOG_EVN_OPERATIONS}
              LogMsg(Format('Destroy env [%s]', [VEnv.RootPath]));
              {$ENDIF}
            end;
            Break;
          end;
        end;
      end;
    end;
  finally
    FEnvCS.Release;
  end;
  {$IFDEF LOG_EVN_OPERATIONS}
  LogMsg('Leave FreeEnvironment');
  {$ENDIF}
end;

procedure TGlobalBerkeleyDBHelper.LogMsg(const AMsg: string);
var
  VLogMsg: string;
  VLogFileName: string;
begin
  FLogCS.Acquire;
  try
    if not Assigned(FLogFileStream) then begin
      VLogFileName := IncludeTrailingPathDelimiter(FFullBaseCachePath) + 'sdb.log';
      if not FileExists(VLogFileName) then begin
        FLogFileStream := TFileStream.Create(VLogFileName, fmCreate);
        FLogFileStream.Free;
      end;
      FLogFileStream := TFileStream.Create(VLogFileName, fmOpenReadWrite or fmShareDenyNone);
    end;

    VLogMsg := FormatDateTime('dd-mm-yyyy hh:nn:ss.zzzz', Now, FFormatSettings) + #09 + AMsg + #13#10;

    FLogFileStream.Position := FLogFileStream.Size;
    FLogFileStream.Write(PChar(VLogMsg)^, Length(VLogMsg) * SizeOf(Char));
  finally
    FLogCS.Release;
  end;
end;

procedure TGlobalBerkeleyDBHelper.LogException(const EMsg: string);
begin
  if FSaveErrorsToLog then begin
    try
      LogMsg(EMsg);
    except
    // ignore
    end;
  end;
end;

end.

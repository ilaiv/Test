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

unit u_StorageStateProxy;

interface

uses
  SysUtils,
  t_CommonTypes,
  i_Listener,
  i_StorageState,
  i_StorageStateProxy,
  u_ChangeableBase;

type
  TStorageStateProxy = class(TChangeableWithSimpleLockBase, IStorageStateProxy, IStorageStateChangeble)
  private
    FTarget: IStorageStateChangeble;
    FTargetChangeListener: IListener;
    FDisableStatic: IStorageStateStatic;

    FLastStatic: IStorageStateStatic;
    procedure OnTargetChange;
  private
    function GetTarget: IStorageStateChangeble;
    procedure SetTarget(const AValue: IStorageStateChangeble);

    function GetStatic: IStorageStateStatic;
  public
    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses
  u_ListenerByEvent,
  u_StorageStateStatic;

{ TStorageStateProxy }

constructor TStorageStateProxy.Create;
begin
  inherited Create;
  FTarget := nil;
  FDisableStatic := TStorageStateStatic.Create(False, False, False, False, False);
  FLastStatic := FDisableStatic;
  FTargetChangeListener := TNotifyNoMmgEventListener.Create(Self.OnTargetChange);
end;

destructor TStorageStateProxy.Destroy;
begin
  CS.BeginWrite;
  try
    if Assigned(FTarget) and Assigned(FTargetChangeListener) then begin
      FTarget.ChangeNotifier.Remove(FTargetChangeListener);
      FTarget := nil;
      FTargetChangeListener := nil;
    end;
  finally
    CS.EndWrite;
  end;

  inherited;
end;

function TStorageStateProxy.GetStatic: IStorageStateStatic;
begin
  CS.BeginRead;
  try
    Result := FLastStatic;
  finally
    CS.EndRead;
  end;
end;

function TStorageStateProxy.GetTarget: IStorageStateChangeble;
begin
  CS.BeginRead;
  try
    Result := FTarget;
  finally
    CS.EndRead;
  end;
end;

procedure TStorageStateProxy.OnTargetChange;
var
  VState: IStorageStateStatic;
  VNeedNotify: Boolean;
begin
  VNeedNotify := False;
  CS.BeginWrite;
  try
    VState := nil;
    if FTarget <> nil then begin
      VState := FTarget.GetStatic;
    end;
    if VState = nil then begin
      VState := FDisableStatic;
    end;
    if not FLastStatic.IsSame(VState) then begin
      FLastStatic := VState;
      VNeedNotify := True;
    end;
  finally
    CS.EndWrite;
  end;
  if VNeedNotify then begin
    DoChangeNotify;
  end;
end;

procedure TStorageStateProxy.SetTarget(const AValue: IStorageStateChangeble);
var
  VState: IStorageStateStatic;
  VNeedNotify: Boolean;
begin
  VNeedNotify := False;
  CS.BeginWrite;
  try
    if FTarget <> AValue then begin
      VState := nil;
      if FTarget <> nil then begin
        FTarget.ChangeNotifier.Remove(FTargetChangeListener);
      end;
      FTarget := AValue;
      if FTarget <> nil then begin
        FTarget.ChangeNotifier.Add(FTargetChangeListener);
        VState := FTarget.GetStatic;
      end;
      if VState = nil then begin
        VState := FDisableStatic;
      end;
      if not FLastStatic.IsSame(VState) then begin
        FLastStatic := VState;
        VNeedNotify := True;
      end;
    end;
  finally
    CS.EndWrite;
  end;
  if VNeedNotify then begin
    DoChangeNotify;
  end;
end;

end.

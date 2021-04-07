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

unit u_ProjectionSetChangeableByConfig;

interface

uses
  i_MapType,
  i_ViewProjectionConfig,
  i_ProjectionSet,
  i_ProjectionSetChangeable,
  i_Listener,
  i_ListenerNotifierLinksList,
  i_ProjectionSetFactory,
  u_ChangeableBase;

type
  TProjectionSetChangeableByConfig = class(TChangeableWithSimpleLockBase, IProjectionSetChangeable)
  private
    FFactory: IProjectionSetFactory;
    FMapChangeable: IMapTypeChangeable;
    FConfig: IViewProjectionConfig;
    FLinkList: IListenerNotifierLinksList;
    FProjectionSet: IProjectionSet;

    function GetProjectionSetByEPSG(
      const AEPSG: Integer
    ): IProjectionSet;

    procedure OnConfigChange;
  private
    { IProjectionSetChangeable }
    function GetStatic: IProjectionSet;
  public
    constructor Create(
      const AFactory: IProjectionSetFactory;
      const AMapChangeable: IMapTypeChangeable;
      const AConfig: IViewProjectionConfig
    );
  end;

implementation

uses
  c_CoordConverter,
  u_ListenerByEvent,
  u_ListenerNotifierLinksList;

{ TLocalCoordConverterChangeable }

constructor TProjectionSetChangeableByConfig.Create(
  const AFactory: IProjectionSetFactory;
  const AMapChangeable: IMapTypeChangeable;
  const AConfig: IViewProjectionConfig
);
var
  VListener: IListener;
begin
  Assert(Assigned(AFactory));
  Assert(Assigned(AMapChangeable));
  Assert(Assigned(AConfig));
  inherited Create;
  FFactory := AFactory;
  FMapChangeable := AMapChangeable;
  FConfig := AConfig;

  FLinkList := TListenerNotifierLinksList.Create;

  VListener := TNotifyNoMmgEventListener.Create(Self.OnConfigChange);

  FLinkList.Add(VListener, FMapChangeable.ChangeNotifier);
  FLinkList.Add(VListener, FConfig.ChangeNotifier);

  FProjectionSet := GetProjectionSetByEPSG(FConfig.EPSG);
  FLinkList.ActivateLinks;
end;

function TProjectionSetChangeableByConfig.GetProjectionSetByEPSG(
  const AEPSG: Integer
): IProjectionSet;
begin
  Result := nil;
  if AEPSG > 0 then begin
    Result := FFactory.GetProjectionSetByCode(AEPSG, CTileSplitQuadrate256x256);
  end;
  if not Assigned(Result) then begin
    Result := FMapChangeable.GetStatic.ViewProjectionSet;
  end;
end;

function TProjectionSetChangeableByConfig.GetStatic: IProjectionSet;
begin
  CS.BeginRead;
  try
    Result := FProjectionSet;
  finally
    CS.EndRead;
  end;
end;

procedure TProjectionSetChangeableByConfig.OnConfigChange;
var
  VProjectionSet: IProjectionSet;
  VNeedNotify: Boolean;
begin
  VProjectionSet := GetProjectionSetByEPSG(FConfig.EPSG);
  VNeedNotify := False;
  CS.BeginWrite;
  try
    if not FProjectionSet.IsSame(VProjectionSet) then begin
      FProjectionSet := VProjectionSet;
      VNeedNotify := True;
    end;
  finally
    CS.EndWrite;
  end;
  if VNeedNotify then begin
    DoChangeNotify;
  end;
end;

end.

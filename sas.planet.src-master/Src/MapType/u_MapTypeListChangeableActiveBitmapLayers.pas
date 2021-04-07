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

unit u_MapTypeListChangeableActiveBitmapLayers;

interface

uses
  i_Notifier,
  i_Listener,
  i_MapType,
  i_MapTypeSet,
  i_MapTypeSetChangeable,
  i_MapTypeListStatic,
  i_MapTypeListBuilder,
  i_MapTypeListChangeable,
  u_ChangeableBase;

type
  TMapTypeListChangeableByActiveMapsSet = class(TChangeableWithSimpleLockBase, IMapTypeListChangeable)
  private
    FMapTypeListBuilderFactory: IMapTypeListBuilderFactory;
    FSourceSet: IMapTypeSetChangeable;

    FZOrderListener: IListener;
    FLayerSetListener: IListener;
    FLayersSet: IMapTypeSet;
    FStatic: IMapTypeListStatic;
    procedure OnMapZOrderChanged;
    procedure OnLayerSetChanged;
    function CreateStatic: IMapTypeListStatic;
  private
    function GetList: IMapTypeListStatic;
  public
    constructor Create(
      const AMapTypeListBuilderFactory: IMapTypeListBuilderFactory;
      const ASourceSet: IMapTypeSetChangeable
    );
    destructor Destroy; override;
  end;

implementation

uses
  i_InterfaceListSimple,
  u_InterfaceListSimple,
  u_SortFunc,
  u_ListenerByEvent;

{ TMapTypeListChangeableByActiveMapsSet }

constructor TMapTypeListChangeableByActiveMapsSet.Create(
  const AMapTypeListBuilderFactory: IMapTypeListBuilderFactory;
  const ASourceSet: IMapTypeSetChangeable
);
begin
  inherited Create;
  FSourceSet := ASourceSet;
  FMapTypeListBuilderFactory := AMapTypeListBuilderFactory;

  FZOrderListener := TNotifyNoMmgEventListener.Create(Self.OnMapZOrderChanged);
  FLayerSetListener := TNotifyNoMmgEventListener.Create(Self.OnLayerSetChanged);
  FSourceSet.ChangeNotifier.Add(FLayerSetListener);
  OnLayerSetChanged;
end;

destructor TMapTypeListChangeableByActiveMapsSet.Destroy;
var
  i: Integer;
  VMapType: IMapType;
begin
  if Assigned(FSourceSet) and Assigned(FLayerSetListener) then begin
    FSourceSet.ChangeNotifier.Remove(FLayerSetListener);
    FLayerSetListener := nil;
    FSourceSet := nil;
  end;
  if Assigned(FLayersSet) and Assigned(FZOrderListener) then begin
    for i := 0 to FLayersSet.Count - 1 do begin
      VMapType := FLayersSet.Items[i];
      if VMapType <> nil then begin
        VMapType.LayerDrawConfig.ChangeNotifier.Remove(FZOrderListener);
      end;
    end;
    FLayersSet := nil;
  end;
  inherited;
end;

function TMapTypeListChangeableByActiveMapsSet.CreateStatic: IMapTypeListStatic;
var
  VLayers: IMapTypeListBuilder;
  VZArray: array of Integer;
  i: Integer;
  VCount: Integer;
  VMapType: IMapType;
  VList: IInterfaceListSimple;
begin
  VLayers := FMapTypeListBuilderFactory.Build;
  if Assigned(FLayersSet) and (FLayersSet.Count > 0) then begin
    VCount := FLayersSet.GetCount;
    VList := TInterfaceListSimple.Create;
    VList.Capacity := VCount;
    for i := 0 to VCount - 1 do begin
      VMapType := FLayersSet.Items[i];
      Assert(Assigned(VMapType));
      VList.Add(VMapType);
    end;

    VCount := VList.GetCount;
    if VCount > 1 then begin
      SetLength(VZArray, VCount);
      for i := 0 to VCount - 1 do begin
        VZArray[i] := IMapType(VList[i]).LayerDrawConfig.LayerZOrder;
      end;
      SortInterfaceListByIntegerMeasure(VList, VZArray);
    end;
    VLayers.Capacity := VCount;
    for i := 0 to VList.Count - 1 do begin
      VLayers.Add(IMapType(VList[i]));
    end;
  end;
  Result := VLayers.MakeAndClear;
end;

function TMapTypeListChangeableByActiveMapsSet.GetList: IMapTypeListStatic;
begin
  CS.BeginRead;
  try
    Result := FStatic;
  finally
    CS.EndRead;
  end;
end;

procedure TMapTypeListChangeableByActiveMapsSet.OnLayerSetChanged;
var
  VNewSet: IMapTypeSet;
  VMapType: IMapType;
  i: Integer;
  VNeedNotify: Boolean;
begin
  VNeedNotify := False;
  CS.BeginWrite;
  try
    VNewSet := FSourceSet.GetStatic;
    if (FLayersSet = nil) or not FLayersSet.IsEqual(VNewSet) then begin
      if Assigned(FLayersSet) then begin
        for i := 0 to FLayersSet.Count - 1 do begin
          VMapType := FLayersSet.Items[i];
          if not Assigned(VNewSet) or not Assigned(VNewSet.GetMapTypeByGUID(VMapType.GUID)) then begin
            VMapType.LayerDrawConfig.ChangeNotifier.Remove(FZOrderListener);
          end;
        end;
      end;
      if VNewSet <> nil then begin
        for i := 0 to VNewSet.Count - 1 do begin
          VMapType := VNewSet.Items[i];
          if not Assigned(FLayersSet) or not Assigned(FLayersSet.GetMapTypeByGUID(VMapType.GUID)) then begin
            VMapType.LayerDrawConfig.ChangeNotifier.Add(FZOrderListener);
          end;
        end;
      end;
      FLayersSet := VNewSet;
      FStatic := CreateStatic;
      VNeedNotify := True;
    end;
  finally
    CS.EndWrite;
  end;
  if VNeedNotify then begin
    DoChangeNotify;
  end;
end;

procedure TMapTypeListChangeableByActiveMapsSet.OnMapZOrderChanged;
begin
  CS.BeginWrite;
  try
    FStatic := CreateStatic;
  finally
    CS.EndWrite;
  end;
end;

end.

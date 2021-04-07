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

unit u_SourceDataUpdateInRectByFillingMap;

interface

uses
  SysUtils,
  i_ObjectWithListener,
  i_Listener,
  i_FillingMapLayerConfig,
  i_Projection,
  i_ProjectionSet,
  i_MapType,
  i_TileRect,
  u_BaseInterfacedObject;

type
  TSourceDataUpdateInRectByFillingMap = class(TBaseInterfacedObject, IObjectWithListener)
  private
    FConfig: IFillingMapLayerConfig;
    FMapType: IMapTypeChangeable;

    FConfigListener: IListener;
    FMapTypeListener: IListener;
    FCS: IReadWriteSync;
    FMapListener: IListener;

    FMapListened: IMapType;

    FListener: IListener;
    FListenTileRect: ITileRect;
    function GetActualProjection(
      const AProjectionSet: IProjectionSet;
      const ATileRect: ITileRect
    ): IProjection;
    procedure OnTileUpdate(const AMsg: IInterface);
    procedure OnMapChange;
    procedure OnConfigChange;

    procedure _RemoveListener(
      const AMapListened: IMapType
    );
    procedure _SetListener(
      const AMapListened: IMapType;
      const ATileRect: ITileRect
    );
  private
    procedure SetListener(
      const AListener: IListener;
      const ATileRect: ITileRect
    );
    procedure RemoveListener;

  public
    constructor Create(
      const AMapType: IMapTypeChangeable;
      const AConfig: IFillingMapLayerConfig
    );
    destructor Destroy; override;
  end;

implementation

uses
  Types,
  Math,
  t_GeoTypes,
  i_LonLatRect,
  i_NotifierTilePyramidUpdate,
  u_ListenerByEvent,
  u_TileUpdateListenerToLonLat,
  u_GeoFunc,
  u_Synchronizer;

{ TSourceDataUpdateInRectByMap }

constructor TSourceDataUpdateInRectByFillingMap.Create(
  const AMapType: IMapTypeChangeable;
  const AConfig: IFillingMapLayerConfig
);
begin
  Assert(Assigned(AMapType));
  Assert(Assigned(AConfig));
  inherited Create;
  FMapType := AMapType;
  FConfig := AConfig;
  FCS := GSync.SyncVariable.Make(Self.ClassName);
  FMapListener := TTileUpdateListenerToLonLat.Create(Self.OnTileUpdate);

  FMapTypeListener := TNotifyNoMmgEventListener.Create(Self.OnMapChange);
  FMapType.ChangeNotifier.Add(FMapTypeListener);

  FConfigListener := TNotifyNoMmgEventListener.Create(Self.OnConfigChange);
  FConfig.ChangeNotifier.Add(FConfigListener);

  OnMapChange;
end;

destructor TSourceDataUpdateInRectByFillingMap.Destroy;
begin
  if Assigned(FMapType) and Assigned(FMapTypeListener) then begin
    FMapType.ChangeNotifier.Remove(FMapTypeListener);
    FMapType := nil;
    FMapTypeListener := nil;
  end;
  if Assigned(FConfig) and Assigned(FConfigListener) then begin
    FConfig.ChangeNotifier.Remove(FConfigListener);
    FConfig := nil;
    FConfigListener := nil;
  end;
  if Assigned(FMapListened) and Assigned(FMapListener) then begin
    _RemoveListener(FMapListened);
  end;
  inherited;
end;

function TSourceDataUpdateInRectByFillingMap.GetActualProjection(
  const AProjectionSet: IProjectionSet;
  const ATileRect: ITileRect
): IProjection;
var
  VZoom: Integer;
  VResult: Byte;
  VConfig: IFillingMapLayerConfigStatic;
begin
  Result := nil;
  VConfig := FConfig.GetStatic;
  if VConfig.Visible then begin
    VZoom := VConfig.Zoom;
    if VConfig.UseRelativeZoom then begin
      VZoom := VZoom + AProjectionSet.GetSuitableZoom(ATileRect.Projection);
    end;
    if VZoom < 0 then begin
      Result := AProjectionSet.Zooms[0];
    end else begin
      VResult := VZoom;
      AProjectionSet.ValidateZoom(VResult);
      Result := AProjectionSet.Zooms[VResult];
    end;
  end;
end;

procedure TSourceDataUpdateInRectByFillingMap.OnConfigChange;
var
  VConfig: IFillingMapLayerConfigStatic;
begin
  VConfig := FConfig.GetStatic;
  FCS.BeginWrite;
  try
    if Assigned(FMapListened) and Assigned(FListenTileRect) then begin
      _RemoveListener(FMapListened);
      _SetListener(FMapListened, FListenTileRect);
    end;
  finally
    FCS.EndWrite;
  end;
end;

procedure TSourceDataUpdateInRectByFillingMap.OnMapChange;
var
  VMap: IMapType;
begin
  VMap := FMapType.GetStatic;
  FCS.BeginWrite;
  try
    if Assigned(FMapListened) and not (FMapListened = VMap) then begin
      if Assigned(FListener) and Assigned(FListenTileRect) then begin
        _RemoveListener(FMapListened);
      end;
    end;
    if Assigned(VMap) and not (VMap = FMapListened) then begin
      if Assigned(FListener) and Assigned(FListenTileRect) then begin
        _SetListener(VMap, FListenTileRect);
      end;
    end;
    FMapListened := VMap;
  finally
    FCS.EndWrite;
  end;
end;

procedure TSourceDataUpdateInRectByFillingMap.OnTileUpdate(const AMsg: IInterface);
var
  VListener: IListener;
  VLonLatRect: ILonLatRect;
begin
  FCS.BeginRead;
  try
    VListener := FListener;
  finally
    FCS.EndRead;
  end;
  if VListener <> nil then begin
    if Supports(AMsg, ILonLatRect, VLonLatRect) then begin
      VListener.Notification(VLonLatRect);
    end else begin
      VListener.Notification(nil);
    end;
  end;
end;

procedure TSourceDataUpdateInRectByFillingMap.RemoveListener;
begin
  FCS.BeginWrite;
  try
    if Assigned(FListener) and Assigned(FListenTileRect) and Assigned(FMapListened) then begin
      _RemoveListener(FMapListened);
    end;
    FListener := nil;
    FListenTileRect := nil;
  finally
    FCS.EndWrite;
  end;
end;

procedure TSourceDataUpdateInRectByFillingMap._RemoveListener(
  const AMapListened: IMapType
);
var
  VNotifier: INotifierTilePyramidUpdate;
begin
  Assert(Assigned(FMapListener));
  if Assigned(AMapListened) and Assigned(FMapListener) then begin
    VNotifier := AMapListened.TileStorage.TileNotifier;
    if VNotifier <> nil then begin
      VNotifier.Remove(FMapListener);
    end;
  end;
end;

procedure TSourceDataUpdateInRectByFillingMap.SetListener(
  const AListener: IListener;
  const ATileRect: ITileRect
);
begin
  FCS.BeginWrite;
  try
    if not Assigned(AListener) or not Assigned(ATileRect) then begin
      if Assigned(FListener) and Assigned(FListenTileRect) and Assigned(FMapListened) then begin
        _RemoveListener(FMapListened);
      end;
      FListener := nil;
      FListenTileRect := nil;
    end else begin
      if not ATileRect.IsEqual(FListenTileRect) then begin
        if Assigned(FListener) and Assigned(FListenTileRect) and Assigned(FMapListened) then begin
          _RemoveListener(FMapListened);
        end;
        if Assigned(FMapListened) then begin
          _SetListener(FMapListened, ATileRect);
        end;
        FListenTileRect := ATileRect;
      end;
      FListener := AListener;
    end;
  finally
    FCS.EndWrite;
  end;
end;

procedure TSourceDataUpdateInRectByFillingMap._SetListener(
  const AMapListened: IMapType;
  const ATileRect: ITileRect
);
var
  VSourceProjection: IProjection;
  VTileRect: TRect;
  VLonLatRect: TDoubleRect;
  VProjection: IProjection;
  VMapLonLatRect: TDoubleRect;
  VNotifier: INotifierTilePyramidUpdate;
begin
  if AMapListened <> nil then begin
    VProjection := ATileRect.Projection;
    VLonLatRect := VProjection.TileRect2LonLatRect(ATileRect.Rect);
    VNotifier := AMapListened.TileStorage.TileNotifier;
    if VNotifier <> nil then begin
      VMapLonLatRect := VLonLatRect;
      VSourceProjection := GetActualProjection(AMapListened.ProjectionSet, ATileRect);
      if Assigned(VSourceProjection) then begin
        VSourceProjection.ProjectionType.ValidateLonLatRect(VMapLonLatRect);
        VTileRect :=
          RectFromDoubleRect(
            VSourceProjection.LonLatRect2TileRectFloat(VMapLonLatRect),
            rrOutside
          );
        VNotifier.AddListenerByRect(FMapListener, VSourceProjection.Zoom, VTileRect);
      end;
    end;
  end;
end;

end.

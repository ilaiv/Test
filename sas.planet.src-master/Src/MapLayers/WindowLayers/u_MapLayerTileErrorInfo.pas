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

unit u_MapLayerTileErrorInfo;

interface

uses
  Windows,
  SysUtils,
  GR32,
  GR32_Image,
  t_GeoTypes,
  i_NotifierTime,
  i_NotifierOperation,
  i_LocalCoordConverter,
  i_LocalCoordConverterChangeable,
  i_InternalPerformanceCounter,
  i_Bitmap32BufferFactory,
  i_TileError,
  i_SimpleFlag,
  i_MarkerDrawable,
  i_TileErrorLogProviedrStuped,
  i_MapType,
  i_MapTypeSet,
  u_MapLayerBasicNoBitmap;

type
  TMapLayerTileErrorInfo = class(TMapLayerBasicNoBitmap)
  private
    FLogProvider: ITileErrorLogProviedrStuped;
    FBitmapFactory: IBitmap32StaticFactory;
    FMapsSet: IMapTypeSet;
    FNeedUpdateFlag: ISimpleFlag;

    FErrorInfo: ITileErrorInfo;
    FErrorInfoCS: IReadWriteSync;
    FHideAfterTime: Cardinal;
    FMarker: IMarkerDrawable;

    procedure OnTimer;
    procedure OnErrorRecive;
    function CreateMarkerByError(
      const AMapType: IMapType;
      const AErrorInfo: ITileErrorInfo
    ): IMarkerDrawable;
  protected
    procedure PaintLayer(
      ABuffer: TBitmap32;
      const ALocalConverter: ILocalCoordConverter
    ); override;
    procedure DoHide; override;
  public
    constructor Create(
      const APerfList: IInternalPerformanceCounterList;
      const AAppStartedNotifier: INotifierOneOperation;
      const AAppClosingNotifier: INotifierOneOperation;
      AParentMap: TImage32;
      const AView: ILocalCoordConverterChangeable;
      const AMapsSet: IMapTypeSet;
      const ABitmapFactory: IBitmap32StaticFactory;
      const ALogProvider: ITileErrorLogProviedrStuped;
      const ATimerNoifier: INotifierTime
    );
  end;

implementation

uses
  Types,
  c_ZeroGUID,
  i_Projection,
  i_Bitmap32Static,
  u_ListenerByEvent,
  u_ListenerTime,
  u_SimpleFlagWithInterlock,
  u_MarkerDrawableByBitmap32Static,
  u_Synchronizer,
  u_GeoFunc;


{ TTileErrorInfoLayer }

constructor TMapLayerTileErrorInfo.Create(
  const APerfList: IInternalPerformanceCounterList;
  const AAppStartedNotifier: INotifierOneOperation;
  const AAppClosingNotifier: INotifierOneOperation;
  AParentMap: TImage32;
  const AView: ILocalCoordConverterChangeable;
  const AMapsSet: IMapTypeSet;
  const ABitmapFactory: IBitmap32StaticFactory;
  const ALogProvider: ITileErrorLogProviedrStuped;
  const ATimerNoifier: INotifierTime
);
begin
  inherited Create(
    APerfList,
    AAppStartedNotifier,
    AAppClosingNotifier,
    AParentMap,
    AView
  );
  FLogProvider := ALogProvider;
  FMapsSet := AMapsSet;
  FBitmapFactory := ABitmapFactory;
  FErrorInfo := nil;
  FNeedUpdateFlag := TSimpleFlagWithInterlock.Create;
  FErrorInfoCS := GSync.SyncVariable.Make(Self.ClassName);

  LinksList.Add(
    TNotifyNoMmgEventListener.Create(Self.OnErrorRecive),
    FLogProvider.GetNotifier
  );
  LinksList.Add(
    TListenerTimeCheck.Create(Self.OnTimer, 1000),
    ATimerNoifier
  );
end;

function TMapLayerTileErrorInfo.CreateMarkerByError(
  const AMapType: IMapType;
  const AErrorInfo: ITileErrorInfo
): IMarkerDrawable;
var
  VText: string;
  VSize: TPoint;
  VMapNameSize: TSize;
  VMessageSize: TSize;
  VBitmap: TBitmap32;
  VBitmapStatic: IBitmap32Static;
begin
  inherited;
  Result := nil;
  if AErrorInfo <> nil then begin
    VBitmap := TBitmap32.Create;
    try
      VBitmap.CombineMode := cmMerge;
      if AMapType <> nil then begin
        VText := AMapType.GUIConfig.Name.Value;
        VMapNameSize := VBitmap.TextExtent(VText);
        VSize.X := VMapNameSize.cx;
        VSize.Y := VMapNameSize.cy + 20;
        VMessageSize := VBitmap.TextExtent(AErrorInfo.ErrorText);
        if VSize.X < VMessageSize.cx then begin
          VSize.X := VMessageSize.cx;
        end;
        Inc(VSize.Y, VMessageSize.cy + 20);
        Inc(VSize.X, 20);
        VBitmap.SetSize(VSize.X, VSize.Y);
        VBitmap.Clear(0);

        VBitmap.RenderText((VSize.X - VMapNameSize.cx) div 2, 10, VText, 0, clBlack32);
        VBitmap.RenderText((VSize.X - VMessageSize.cx) div 2, 30 + VMapNameSize.cy, AErrorInfo.ErrorText, 0, clBlack32);
      end else begin
        VMessageSize := VBitmap.TextExtent(AErrorInfo.ErrorText);
        VSize.X := VMessageSize.cx + 20;
        VSize.Y := VMessageSize.cy + 20;

        VBitmap.SetSize(VSize.X, VSize.Y);
        VBitmap.Clear(0);

        VBitmap.RenderText((VSize.X - VMessageSize.cx) div 2, 10, AErrorInfo.ErrorText, 0, clBlack32);
      end;
      VBitmapStatic := FBitmapFactory.Build(VSize, VBitmap.Bits);
    finally
      VBitmap.Free;
    end;
    Result := TMarkerDrawableByBitmap32Static.Create(VBitmapStatic, DoublePoint(VSize.X / 2, VSize.Y / 2));
  end;
end;

procedure TMapLayerTileErrorInfo.DoHide;
begin
  inherited;
  FHideAfterTime := 0;
  FErrorInfo := nil;
  FMarker := nil;
end;

procedure TMapLayerTileErrorInfo.OnErrorRecive;
begin
  FNeedUpdateFlag.SetFlag;
end;

procedure TMapLayerTileErrorInfo.OnTimer;
var
  VCurrTime: Cardinal;
  VNeedHide: Boolean;
  VErrorInfo: ITileErrorInfo;
begin
  VErrorInfo := nil;
  if FNeedUpdateFlag.CheckFlagAndReset then begin
    VErrorInfo := FLogProvider.GetLastErrorInfo;
  end;
  if VErrorInfo <> nil then begin
    VCurrTime := GetTickCount;
    ViewUpdateLock;
    try
      FErrorInfoCS.BeginWrite;
      try
        FErrorInfo := VErrorInfo;
        FHideAfterTime := VCurrTime + 10000;
      finally
        FErrorInfoCS.EndWrite;
      end;
      SetNeedRedraw;
      Show;
    finally
      ViewUpdateUnlock;
    end;
  end else begin
    VCurrTime := GetTickCount;
    VNeedHide := False;
    ViewUpdateLock;
    try
      FErrorInfoCS.BeginWrite;
      try
        if (FHideAfterTime = 0) or (FErrorInfo = nil) or (VCurrTime >= FHideAfterTime) then begin
          VNeedHide := True;
          FHideAfterTime := 0;
          FErrorInfo := nil;
        end;
      finally
        FErrorInfoCS.EndWrite;
      end;
      if VNeedHide then begin
        FMarker := nil;
        Hide;
      end;
    finally
      ViewUpdateUnlock;
    end;
  end;

end;

procedure TMapLayerTileErrorInfo.PaintLayer(
  ABuffer: TBitmap32;
  const ALocalConverter: ILocalCoordConverter
);
var
  VMarker: IMarkerDrawable;
  VFixedOnView: TDoublePoint;
  VErrorInfo: ITileErrorInfo;
  VProjection: IProjection;
  VGUID: TGUID;
  VMapType: IMapType;
  VTile: TPoint;
  VFixedLonLat: TDoublePoint;
begin
  FErrorInfoCS.BeginRead;
  try
    VErrorInfo := FErrorInfo;
  finally
    FErrorInfoCS.EndRead;
  end;
  if FErrorInfo <> nil then begin
    VGUID := VErrorInfo.MapTypeGUID;
    VMapType := nil;
    if not IsEqualGUID(VGUID, CGUID_Zero) then begin
      VMapType := FMapsSet.GetMapTypeByGUID(VGUID);
    end;
    VProjection := VMapType.ProjectionSet.Zooms[VErrorInfo.Zoom];
    VTile := VErrorInfo.Tile;
    VProjection.ValidateTilePosStrict(VTile, True);
    VFixedLonLat := VProjection.PixelPosFloat2LonLat(RectCenter(VProjection.TilePos2PixelRect(VTile)));
    ALocalConverter.Projection.ProjectionType.ValidateLonLatPos(VFixedLonLat);
    VFixedOnView := ALocalConverter.LonLat2LocalPixelFloat(VFixedLonLat);
    if PixelPointInRect(VFixedOnView, DoubleRect(ALocalConverter.GetLocalRect)) then begin
      VMarker := FMarker;
      if VMarker = nil then begin
        VMarker := CreateMarkerByError(VMapType, FErrorInfo);
      end;
      FMarker := VMarker;
      if VMarker <> nil then begin
        VFixedOnView := ALocalConverter.LonLat2LocalPixelFloat(VFixedLonLat);
        VMarker.DrawToBitmap(ABuffer, VFixedOnView);
      end;
    end;
  end;
end;

end.

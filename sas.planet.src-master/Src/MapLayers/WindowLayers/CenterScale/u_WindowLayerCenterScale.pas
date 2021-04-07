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

unit u_WindowLayerCenterScale;

interface

uses
  GR32,
  GR32_Image,
  GR32_Layers,
  t_GeoTypes,
  i_NotifierOperation,
  i_MarkerDrawable,
  i_LocalCoordConverter,
  i_LocalCoordConverterChangeable,
  i_InternalPerformanceCounter,
  i_CenterScaleConfig,
  u_WindowLayerBasicBase;

type
  TWindowLayerCenterScale = class(TWindowLayerBasicBase)
  private
    FConfig: ICenterScaleConfig;
    FMarkerChangeable: IMarkerDrawableChangeable;
    FPosition: ILocalCoordConverterChangeable;

    FLastFixedPoint: TDoublePoint;

    procedure OnConfigChange;
    procedure OnPosChange;
  protected
    procedure PaintLayer(ABuffer: TBitmap32); override;
    procedure StartThreads; override;
  public
    constructor Create(
      const APerfList: IInternalPerformanceCounterList;
      const AAppStartedNotifier: INotifierOneOperation;
      const AAppClosingNotifier: INotifierOneOperation;
      AParentMap: TImage32;
      const APosition: ILocalCoordConverterChangeable;
      const AMarkerChangeable: IMarkerDrawableChangeable;
      const AConfig: ICenterScaleConfig
    );
  end;

implementation

uses
  Types,
  Math,
  u_ListenerByEvent,
  u_GeoFunc;

{ TWindowLayerCenterScale }

constructor TWindowLayerCenterScale.Create(
  const APerfList: IInternalPerformanceCounterList;
  const AAppStartedNotifier: INotifierOneOperation;
  const AAppClosingNotifier: INotifierOneOperation;
  AParentMap: TImage32;
  const APosition: ILocalCoordConverterChangeable;
  const AMarkerChangeable: IMarkerDrawableChangeable;
  const AConfig: ICenterScaleConfig
);
begin
  inherited Create(
    APerfList,
    AAppStartedNotifier,
    AAppClosingNotifier,
    TCustomLayer.Create(AParentMap.Layers)
  );
  FConfig := AConfig;
  FPosition := APosition;
  FMarkerChangeable := AMarkerChangeable;
  FLastFixedPoint := CEmptyDoublePoint;

  LinksList.Add(
    TNotifyNoMmgEventListener.Create(Self.OnConfigChange),
    FConfig.ChangeNotifier
  );
  LinksList.Add(
    TNotifyNoMmgEventListener.Create(Self.OnPosChange),
    FPosition.ChangeNotifier
  );
end;

procedure TWindowLayerCenterScale.OnConfigChange;
begin
  ViewUpdateLock;
  try
    Visible := FConfig.Visible;
  finally
    ViewUpdateUnlock;
  end;
end;

procedure TWindowLayerCenterScale.PaintLayer(ABuffer: TBitmap32);
var
  VMarker: IMarkerDrawable;
  VFixedPoint: TDoublePoint;
begin
  VMarker := FMarkerChangeable.GetStatic;
  if VMarker <> nil then begin
    VFixedPoint := RectCenter(FPosition.GetStatic.GetLocalRect);
    VMarker.DrawToBitmap(ABuffer, VFixedPoint);
  end;
end;

procedure TWindowLayerCenterScale.OnPosChange;
var
  VNewFixedPoint: TDoublePoint;
begin
  if Visible then begin
    VNewFixedPoint := RectCenter(FPosition.GetStatic.GetLocalRect);
    if not DoublePointsEqual(VNewFixedPoint, FLastFixedPoint) then begin
      FLastFixedPoint := VNewFixedPoint;
      ViewUpdateLock;
      try
        SetNeedFullRepaintLayer;
      finally
        ViewUpdateUnlock;
      end;
    end;
  end;
end;

procedure TWindowLayerCenterScale.StartThreads;
begin
  inherited;
  OnConfigChange;
end;

end.

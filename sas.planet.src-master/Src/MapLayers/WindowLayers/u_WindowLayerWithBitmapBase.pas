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

unit u_WindowLayerWithBitmapBase;

interface

uses
  Types,
  SysUtils,
  GR32,
  GR32_Layers,
  i_NotifierOperation,
  i_SimpleFlag,
  i_InternalPerformanceCounter,
  u_WindowLayerAbstract;

type
  TWindowLayerWithBitmapBase = class(TWindowLayerAbstract)
  private
    FLayer: TBitmapLayer;
    FVisible: Boolean;
    FNeedUpdateLayerVisibilityFlag: ISimpleFlag;
    FNeedUpdateBitmapDrawFlag: ISimpleFlag;
    FNeedUpdateBitmapSizeFlag: ISimpleFlag;
    FNeedUpdateLayerLocationFlag: ISimpleFlag;

    FResizeCounter: IInternalPerformanceCounter;
    FRedrawCounter: IInternalPerformanceCounter;

    procedure SetVisible(const Value: Boolean);
  protected
    procedure DoViewUpdate; override;
  protected
    procedure SetNeedUpdateLayerVisibility;
    procedure DoUpdateLayerVisibility; virtual;

    procedure SetNeedUpdateBitmapDraw;
    procedure DoUpdateBitmapDraw; virtual; abstract;

    procedure SetNeedUpdateBitmapSize;
    function GetNewBitmapSize: TPoint; virtual; abstract;
    procedure DoUpdateBitmapSize(const ASize: TPoint); virtual;

    procedure SetNeedUpdateLayerLocation;
    function GetNewLayerLocation: TFloatRect; virtual; abstract;
    procedure DoUpdateLayerLocation(ALocation: TFloatRect); virtual;

    property Layer: TBitmapLayer read FLayer;
    property Visible: Boolean read FVisible write SetVisible;
  public
    constructor Create(
      const APerfList: IInternalPerformanceCounterList;
      const AAppStartedNotifier: INotifierOneOperation;
      const AAppClosingNotifier: INotifierOneOperation;
      ALayer: TBitmapLayer
    );
  end;

implementation

uses
  u_SimpleFlagWithInterlock;

{ TWindowLayerWithBitmapBase }

constructor TWindowLayerWithBitmapBase.Create(
  const APerfList: IInternalPerformanceCounterList;
  const AAppStartedNotifier,
  AAppClosingNotifier: INotifierOneOperation;
  ALayer: TBitmapLayer
);
begin
  inherited Create(
    AAppStartedNotifier,
    AAppClosingNotifier
  );
  FLayer := ALayer;
  FLayer.Visible := False;
  FLayer.MouseEvents := False;
  FLayer.Bitmap.DrawMode := dmBlend;

  FNeedUpdateLayerVisibilityFlag := TSimpleFlagWithInterlock.Create;
  FNeedUpdateBitmapDrawFlag := TSimpleFlagWithInterlock.Create;
  FNeedUpdateBitmapSizeFlag := TSimpleFlagWithInterlock.Create;
  FNeedUpdateLayerLocationFlag := TSimpleFlagWithInterlock.Create;

  FResizeCounter := APerfList.CreateAndAddNewCounter('Resize');
  FRedrawCounter := APerfList.CreateAndAddNewCounter('Redraw');
end;

procedure TWindowLayerWithBitmapBase.DoUpdateBitmapSize(const ASize: TPoint);
begin
  FLayer.Bitmap.SetSize(ASize.X, ASize.Y);
end;

procedure TWindowLayerWithBitmapBase.DoUpdateLayerLocation(ALocation: TFloatRect);
begin
  FLayer.Location := ALocation;
end;

procedure TWindowLayerWithBitmapBase.DoUpdateLayerVisibility;
begin
  FLayer.Visible := FVisible;
end;

procedure TWindowLayerWithBitmapBase.DoViewUpdate;
var
  VSize: TPoint;
  VLocation: TFloatRect;
  VCounterContext: TInternalPerformanceCounterContext;
begin
  inherited;
  if FNeedUpdateLayerVisibilityFlag.CheckFlagAndReset then begin
    if FVisible <> FLayer.Visible then begin
      SetNeedUpdateLayerVisibility;
      SetNeedUpdateBitmapSize;
    end;
  end;
  if FNeedUpdateBitmapSizeFlag.CheckFlagAndReset then begin
    if FVisible then begin
      VSize := GetNewBitmapSize;
    end else begin
      VSize := Types.Point(0, 0);
    end;
    if (VSize.X <> FLayer.Bitmap.Width) or (VSize.Y <> FLayer.Bitmap.Height) then begin
      VCounterContext := FResizeCounter.StartOperation;
      try
        DoUpdateBitmapSize(VSize);
        if FVisible then begin
          SetNeedUpdateBitmapDraw;
          SetNeedUpdateLayerLocation;
        end;
      finally
        FResizeCounter.FinishOperation(VCounterContext);
      end;
    end;
  end;
  if FNeedUpdateBitmapDrawFlag.CheckFlagAndReset then begin
    if FVisible then begin
      VCounterContext := FRedrawCounter.StartOperation;
      try
        DoUpdateBitmapDraw;
      finally
        FRedrawCounter.FinishOperation(VCounterContext);
      end;
    end;
  end;
  if FNeedUpdateLayerLocationFlag.CheckFlagAndReset then begin
    VLocation := GetNewLayerLocation;
    if not EqualRect(VLocation, FLayer.Location) then begin
      DoUpdateLayerLocation(VLocation);
    end;
  end;
  if FNeedUpdateLayerVisibilityFlag.CheckFlagAndReset then begin
    if FLayer.Visible <> FVisible then begin
      DoUpdateLayerVisibility;
    end;
  end;
end;

procedure TWindowLayerWithBitmapBase.SetNeedUpdateBitmapDraw;
begin
  FNeedUpdateBitmapDrawFlag.SetFlag;
end;

procedure TWindowLayerWithBitmapBase.SetNeedUpdateBitmapSize;
begin
  FNeedUpdateBitmapSizeFlag.SetFlag;
end;

procedure TWindowLayerWithBitmapBase.SetNeedUpdateLayerLocation;
begin
  FNeedUpdateLayerLocationFlag.SetFlag;
end;

procedure TWindowLayerWithBitmapBase.SetNeedUpdateLayerVisibility;
begin
  FNeedUpdateLayerVisibilityFlag.SetFlag;
end;

procedure TWindowLayerWithBitmapBase.SetVisible(const Value: Boolean);
begin
  ViewUpdateLock;
  try
    FVisible := Value;
    SetNeedUpdateLayerVisibility;
  finally
    ViewUpdateUnlock;
  end;
end;

end.

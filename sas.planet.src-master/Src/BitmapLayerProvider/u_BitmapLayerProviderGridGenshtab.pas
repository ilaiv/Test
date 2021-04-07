{******************************************************************************}
{* SAS.Planet (SAS.�������)                                                   *}
{* Copyright (C) 2007-2012, SAS.Planet development team.                      *}
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

unit u_BitmapLayerProviderGridGenshtab;

interface

uses
  Types,
  SysUtils,
  GR32,
  i_SimpleFlag,
  i_NotifierOperation,
  i_Projection,
  i_Bitmap32Static,
  i_Bitmap32BufferFactory,
  i_BitmapLayerProvider,
  u_BaseInterfacedObject;

type
  TBitmapLayerProviderGridGenshtab = class(TBaseInterfacedObject, IBitmapTileUniProvider)
  private
    FColor: TColor32;
    FShowText: Boolean;
    FShowLines: Boolean;
    FScale: Integer;
    FBitmapFactory: IBitmap32StaticFactory;

    FCS: IReadWriteSync;
    FBitmap: TBitmap32;
    FBitmapChangeFlag: ISimpleFlag;
    procedure OnBitmapChange(Sender: TObject);
    procedure InitBitmap(const ASize: TPoint);
    procedure DrawLines(
      const AProjection: IProjection;
      const AMapRect: TRect
    );
    procedure DrawCaptions(
      AOperationID: Integer;
      const ACancelNotifier: INotifierOperation;
      const AProjection: IProjection;
      const AMapRect: TRect
    );
  private
    function GetTile(
      AOperationID: Integer;
      const ACancelNotifier: INotifierOperation;
      const AProjection: IProjection;
      const ATile: TPoint
    ): IBitmap32Static;
  public
    constructor Create(
      const ABitmapFactory: IBitmap32StaticFactory;
      AColor: TColor32;
      AScale: Integer;
      AShowText: Boolean;
      AShowLines: Boolean
    );
    destructor Destroy; override;
  end;

implementation

uses
  Math,
  t_GeoTypes,
  i_ProjectionType,
  u_SimpleFlagWithInterlock,
  u_GeoFunc,
  u_GeoToStrFunc,
  u_Synchronizer;

{ TBitmapLayerProviderGridGenshtab }

constructor TBitmapLayerProviderGridGenshtab.Create(
  const ABitmapFactory: IBitmap32StaticFactory;
  AColor: TColor32;
  AScale: Integer;
  AShowText, AShowLines: Boolean
);
begin
  inherited Create;
  FColor := AColor;
  FScale := AScale;
  FShowText := AShowText;
  FShowLines := AShowLines;
  FBitmapFactory := ABitmapFactory;

  FCS := GSync.SyncVariable.Make(Self.ClassName);
  FBitmapChangeFlag := TSimpleFlagWithInterlock.Create;
  FBitmap := TBitmap32.Create;
  FBitmap.SetSize(256, 256);
  FBitmap.OnChange := Self.OnBitmapChange;
end;

destructor TBitmapLayerProviderGridGenshtab.Destroy;
begin
  FreeAndNil(FBitmap);
  inherited;
end;

procedure TBitmapLayerProviderGridGenshtab.DrawCaptions(
  AOperationID: Integer;
  const ACancelNotifier: INotifierOperation;
  const AProjection: IProjection;
  const AMapRect: TRect
);
var
  VLocalRect: TRect;
  z: TDoublePoint;
  VZoom: Byte;
  VLoadedLonLatRect: TDoubleRect;
  VGridLonLatRect: TDoubleRect;
  VLonLatRectOfCell: TDoubleRect;
  VMapRectOfCell: TDoubleRect;
  VLocalRectOfCell: TDoubleRect;
  VProjectionType: IProjectionType;
  VGridRect: TRect;
  i, j: Integer;
  VTextSize: TSize;
  VListName: String;
  VLonLatCenter: TDoublePoint;
  VLocalCellCenter: TDoublePoint;
  VOutPoint: TPoint;
begin
  VProjectionType := AProjection.ProjectionType;
  VZoom := AProjection.Zoom;
  z := GetGhBordersStepByScale(FScale, VZoom);
  VLocalRect := Rect(0, 0, AMapRect.Right - AMapRect.Left, AMapRect.Bottom - AMapRect.Top);

  VLoadedLonLatRect := AProjection.PixelRect2LonLatRect(AMapRect);
  if VLoadedLonLatRect.Top > 90 then begin
    VLoadedLonLatRect.Top := 90;
  end;
  if VLoadedLonLatRect.Bottom < -90 then begin
    VLoadedLonLatRect.Bottom := -90;
  end;
  VGridRect.Left := Floor(VLoadedLonLatRect.Left / z.X);
  VGridRect.Top := Ceil(VLoadedLonLatRect.Top / z.Y);
  VGridRect.Right := Ceil(VLoadedLonLatRect.Right / z.X);
  VGridRect.Bottom := Floor(VLoadedLonLatRect.Bottom / z.Y);

  VGridLonLatRect.Left := VGridRect.Left * z.X;
  VGridLonLatRect.Top := VGridRect.Top * z.Y;
  VGridLonLatRect.Right := VGridRect.Right * z.X;
  VGridLonLatRect.Bottom := VGridRect.Bottom * z.Y;

  VLonLatRectOfCell.TopLeft := VGridLonLatRect.TopLeft;
  VLonLatRectOfCell.BottomRight := DoublePoint(VGridLonLatRect.Left + z.X, VGridLonLatRect.Top - z.Y);
  VProjectionType.ValidateLonLatRect(VLonLatRectOfCell);
  VMapRectOfCell := AProjection.LonLatRect2PixelRectFloat(VLonLatRectOfCell);
  VLocalRectOfCell := RectMove(VMapRectOfCell, AMapRect.TopLeft);
  if abs(VLocalRectOfCell.Right - VLocalRectOfCell.Left) < 30 then begin
    exit;
  end;
  VLonLatRectOfCell.Right := VGridLonLatRect.Left;
  for i := VGridRect.Left + 1 to VGridRect.Right do begin
    VLonLatRectOfCell.Left := VLonLatRectOfCell.Right;
    VLonLatRectOfCell.Right := i * z.X;
    VLonLatRectOfCell.Top := VGridLonLatRect.Bottom;
    for j := VGridRect.Bottom + 1 to VGridRect.Top do begin
      VLonLatRectOfCell.Bottom := VLonLatRectOfCell.Top;
      VLonLatRectOfCell.Top := j * z.Y;
      VProjectionType.ValidateLonLatRect(VLonLatRectOfCell);

      VLonLatCenter := RectCenter(VLonLatRectOfCell);
      VListName := LonLat2GShListName(VLonLatCenter, GetActualGshSCale(FScale, VZoom), 100000000);

      VTextSize := FBitmap.TextExtent(VListName);

      VMapRectOfCell := AProjection.LonLatRect2PixelRectFloat(VLonLatRectOfCell);
      VLocalRectOfCell := RectMove(VMapRectOfCell, AMapRect.TopLeft);
      VLocalCellCenter := RectCenter(VLocalRectOfCell);
      VOutPoint := Types.Point(Trunc(VLocalCellCenter.X - VTextSize.cx / 2), Trunc(VLocalCellCenter.Y - VTextSize.cy));
      FBitmap.RenderText(VOutPoint.X, VOutPoint.Y, VListName, 0, FColor);
    end;
  end;
end;

procedure TBitmapLayerProviderGridGenshtab.DrawLines(
  const AProjection: IProjection;
  const AMapRect: TRect
);
var
  VLocalRect: TRect;
  z: TDoublePoint;
  VLoadedLonLatRect: TDoubleRect;
  VGridLonLatRect: TDoubleRect;
  VLonLatRectOfCellsLine: TDoubleRect;
  VMapRectOfCellsLine: TDoubleRect;
  VLocalRectOfCellsLine: TRect;
  VProjectionType: IProjectionType;
  VGridRect: TRect;
  i: Integer;
begin
  VProjectionType := AProjection.ProjectionType;
  z := GetGhBordersStepByScale(FScale, AProjection.Zoom);
  VLocalRect := Rect(0, 0, AMapRect.Right - AMapRect.Left, AMapRect.Bottom - AMapRect.Top);

  VLoadedLonLatRect := AProjection.PixelRect2LonLatRect(AMapRect);
  if VLoadedLonLatRect.Top > 90 then begin
    VLoadedLonLatRect.Top := 90;
  end;
  if VLoadedLonLatRect.Bottom < -90 then begin
    VLoadedLonLatRect.Bottom := -90;
  end;
  VGridRect.Left := Floor(VLoadedLonLatRect.Left / z.X);
  VGridRect.Top := Ceil(VLoadedLonLatRect.Top / z.Y);
  VGridRect.Right := Ceil(VLoadedLonLatRect.Right / z.X);
  VGridRect.Bottom := Floor(VLoadedLonLatRect.Bottom / z.Y);

  VGridLonLatRect.Left := VGridRect.Left * z.X;
  VGridLonLatRect.Top := VGridRect.Top * z.Y;
  VGridLonLatRect.Right := VGridRect.Right * z.X;
  VGridLonLatRect.Bottom := VGridRect.Bottom * z.Y;

  VLonLatRectOfCellsLine.TopLeft := VGridLonLatRect.TopLeft;
  VLonLatRectOfCellsLine.BottomRight := DoublePoint(VGridLonLatRect.Left + z.X, VGridLonLatRect.Top - z.Y);
  VProjectionType.ValidateLonLatRect(VLonLatRectOfCellsLine);
  VMapRectOfCellsLine := AProjection.LonLatRect2PixelRectFloat(VLonLatRectOfCellsLine);
  VLocalRectOfCellsLine :=
    RectFromDoubleRect(
      RectMove(VMapRectOfCellsLine, AMapRect.TopLeft),
      rrToTopLeft
    );
  if abs(VLocalRectOfCellsLine.Right - VLocalRectOfCellsLine.Left) < 4 then begin
    exit;
  end;

  for i := VGridRect.Left to VGridRect.Right do begin
    VLonLatRectOfCellsLine.Left := i * z.X;
    VLonLatRectOfCellsLine.Top := VGridLonLatRect.Top;
    VLonLatRectOfCellsLine.Right := VLonLatRectOfCellsLine.Left;
    VLonLatRectOfCellsLine.Bottom := VGridLonLatRect.Bottom;
    VProjectionType.ValidateLonLatRect(VLonLatRectOfCellsLine);
    VMapRectOfCellsLine := AProjection.LonLatRect2PixelRectFloat(VLonLatRectOfCellsLine);
    VLocalRectOfCellsLine :=
      RectFromDoubleRect(
        RectMove(VMapRectOfCellsLine, AMapRect.TopLeft),
        rrToTopLeft
      );
    VLocalRectOfCellsLine.Top := VLocalRect.Top;
    VLocalRectOfCellsLine.Bottom := VLocalRect.Bottom;

    if (VLocalRectOfCellsLine.Left >= VLocalRect.Left) and
      (VLocalRectOfCellsLine.Left < VLocalRect.Right) then begin
      FBitmap.VertLineTS(
        VLocalRectOfCellsLine.Left,
        VLocalRectOfCellsLine.Top,
        VLocalRectOfCellsLine.Bottom,
        FColor
      );
    end;
  end;

  for i := VGridRect.Bottom to VGridRect.Top do begin
    VLonLatRectOfCellsLine.Left := VGridLonLatRect.Left;
    VLonLatRectOfCellsLine.Top := i * z.Y;
    VLonLatRectOfCellsLine.Right := VGridLonLatRect.Right;
    VLonLatRectOfCellsLine.Bottom := VLonLatRectOfCellsLine.Top;

    VProjectionType.ValidateLonLatRect(VLonLatRectOfCellsLine);
    VMapRectOfCellsLine := AProjection.LonLatRect2PixelRectFloat(VLonLatRectOfCellsLine);
    VLocalRectOfCellsLine :=
      RectFromDoubleRect(
        RectMove(VMapRectOfCellsLine, AMapRect.TopLeft),
        rrToTopLeft
      );
    VLocalRectOfCellsLine.Left := VLocalRect.Left;
    VLocalRectOfCellsLine.Right := VLocalRect.Right;

    if (VLocalRectOfCellsLine.Top >= VLocalRect.Top) and
      (VLocalRectOfCellsLine.Bottom < VLocalRect.Bottom) then begin
      FBitmap.HorzLineTS(
        VLocalRectOfCellsLine.Left,
        VLocalRectOfCellsLine.Top,
        VLocalRectOfCellsLine.Right,
        FColor
      );
    end;
  end;
end;

function TBitmapLayerProviderGridGenshtab.GetTile(
  AOperationID: Integer;
  const ACancelNotifier: INotifierOperation;
  const AProjection: IProjection;
  const ATile: TPoint
): IBitmap32Static;
var
  VMapRect: TRect;
begin
  Result := nil;
  FCS.BeginWrite;
  try
    VMapRect := AProjection.TilePos2PixelRect(ATile);
    InitBitmap(RectSize(VMapRect));
    FBitmapChangeFlag.CheckFlagAndReset;
    if FShowLines then begin
      DrawLines(AProjection, VMapRect);
    end;

    if FShowText then begin
      DrawCaptions(AOperationID, ACancelNotifier, AProjection, VMapRect);
    end;
    if FBitmapChangeFlag.CheckFlagAndReset then begin
      Result := FBitmapFactory.Build(Types.Point(FBitmap.Width, FBitmap.Height), FBitmap.Bits);
    end;
  finally
    FCS.EndWrite;
  end;
end;

procedure TBitmapLayerProviderGridGenshtab.InitBitmap(
  const ASize: TPoint
);
begin
  FBitmap.SetSize(ASize.X, ASize.Y);
  FBitmap.Clear(0);
end;

procedure TBitmapLayerProviderGridGenshtab.OnBitmapChange(Sender: TObject);
begin
  FBitmapChangeFlag.SetFlag;
end;

end.

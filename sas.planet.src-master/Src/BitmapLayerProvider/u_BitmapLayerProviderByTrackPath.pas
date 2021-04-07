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

unit u_BitmapLayerProviderByTrackPath;

interface

uses
  GR32,
  t_GeoTypes,
  i_NotifierOperation,
  i_Projection,
  i_Bitmap32Static,
  i_Bitmap32BufferFactory,
  i_BitmapLayerProvider,
  i_GPSRecorder,
  i_MapLayerGPSTrackConfig,
  u_BaseInterfacedObject;

type
  TBitmapLayerProviderByTrackPath = class(TBaseInterfacedObject, IBitmapTileUniProvider)
  private
    FLineWidth: Double;
    FTrackColorer: ITrackColorerStatic;
    FBitmap32StaticFactory: IBitmap32StaticFactory;

    FRectIsEmpty: Boolean;
    FLonLatRect: TDoubleRect;

    FPointsLonLat: array of TGPSTrackPoint;
    FPointsLonLatCount: Integer;

    FPreparedProjection: IProjection;
    FPointsProjected: array of TGPSTrackPoint;
    FPointsProjectedCount: Integer;

    procedure PrepareLonLatPointsByEnum(
      AMaxPointsCount: Integer;
      const AEnum: IEnumGPSTrackPoint
    );
    procedure PrepareProjectedPoints(
      const AProjection: IProjection
    );
    procedure InitBitmap(
      ATargetBmp: TCustomBitmap32;
      const ASize: TPoint
    );
    procedure DrawSection(
      ATargetBmp: TCustomBitmap32;
      const ATrackColorer: ITrackColorerStatic;
      const ALineWidth: Double;
      const APointPrev, APointCurr: TDoublePoint;
      const ASpeed: Double
    );
    function DrawPath(
      AOperationID: Integer;
      const ACancelNotifier: INotifierOperation;
      ATargetBmp: TCustomBitmap32;
      const AProjection: IProjection;
      const AMapRect: TRect;
      const ATrackColorer: ITrackColorerStatic;
      const ALineWidth: Double;
      APointsCount: Integer
    ): Boolean;
  private
    function GetTile(
      AOperationID: Integer;
      const ACancelNotifier: INotifierOperation;
      const AProjection: IProjection;
      const ATile: TPoint
    ): IBitmap32Static;
  public
    constructor Create(
      AMaxPointsCount: Integer;
      const ALineWidth: Double;
      const ATrackColorer: ITrackColorerStatic;
      const ABitmap32StaticFactory: IBitmap32StaticFactory;
      const AEnum: IEnumGPSTrackPoint
    );
  end;

implementation

uses
  SysUtils,
  Types,
  Math,
  GR32_Polygons,
  GR32_VectorUtils,
  i_ProjectionType,
  u_Bitmap32ByStaticBitmap,
  u_GeometryFunc,
  u_GeoFunc;

{ TBitmapLayerProviderByTrackPath }

constructor TBitmapLayerProviderByTrackPath.Create(
  AMaxPointsCount: Integer;
  const ALineWidth: Double;
  const ATrackColorer: ITrackColorerStatic;
  const ABitmap32StaticFactory: IBitmap32StaticFactory;
  const AEnum: IEnumGPSTrackPoint
);
begin
  Assert(Assigned(ATrackColorer));
  Assert(Assigned(AEnum));
  Assert(Assigned(ABitmap32StaticFactory));
  inherited Create;
  FLineWidth := ALineWidth;
  FTrackColorer := ATrackColorer;
  FBitmap32StaticFactory := ABitmap32StaticFactory;
  Assert(FLineWidth >= 0);
  Assert(FTrackColorer <> nil);
  SetLength(FPointsLonLat, AMaxPointsCount);
  SetLength(FPointsProjected, AMaxPointsCount);

  PrepareLonLatPointsByEnum(AMaxPointsCount, AEnum);

end;

function TBitmapLayerProviderByTrackPath.DrawPath(
  AOperationID: Integer;
  const ACancelNotifier: INotifierOperation;
  ATargetBmp: TCustomBitmap32;
  const AProjection: IProjection;
  const AMapRect: TRect;
  const ATrackColorer: ITrackColorerStatic;
  const ALineWidth: Double;
  APointsCount: Integer
): Boolean;
  function GetCode(
  const AMapRect: TDoubleRect;
  const APoint: TDoublePoint
  ): Byte;
    //  ����� �������� ����:

    // 1 �� = 1 - ����� ��� ������� ����� ����;

    // 2 �� = 1 - ����� ��� ������ ����� ����;

    // 3 �� = 1 - ����� ������ �� ������� ���� ����;

    // 4 �� = 1 - ����� ����� �� ������ ���� ����.
  begin
    Result := 0;
    if AMapRect.Top > APoint.Y then begin
      Result := 1;
    end else if AMapRect.Bottom < APoint.Y then begin
      Result := 2;
    end;

    if AMapRect.Left > APoint.X then begin
      Result := Result or 8;
    end else if AMapRect.Right < APoint.X then begin
      Result := Result or 4;
    end;
  end;

var
  VPointPrev: TDoublePoint;
  VPointPrevIsEmpty: Boolean;
  VPointPrevCode: Byte;
  VPointPrevLocal: TDoublePoint;
  i: Integer;
  VPointCurr: TDoublePoint;
  VPointCurrIsEmpty: Boolean;
  VPointCurrCode: Byte;
  VPointCurrLocal: TDoublePoint;

  VMapPixelRect: TDoubleRect;
begin
  Result := False;
  VMapPixelRect := DoubleRect(AMapRect);

  VPointCurrCode := 0;
  VPointPrevCode := 0;
  VPointPrev := FPointsProjected[APointsCount - 1].Point;
  VPointPrevIsEmpty := PointIsEmpty(VPointPrev);
  if not VPointPrevIsEmpty then begin
    VPointPrevCode := GetCode(VMapPixelRect, VPointPrev);
    VPointPrevLocal.X := VPointPrev.X - VMapPixelRect.Left;
    VPointPrevLocal.Y := VPointPrev.Y - VMapPixelRect.Top;
  end;
  for i := APointsCount - 2 downto 0 do begin
    if ACancelNotifier.IsOperationCanceled(AOperationID) then begin
      Break;
    end;
    VPointCurr := FPointsProjected[i].Point;
    VPointCurrIsEmpty := PointIsEmpty(VPointCurr);
    if not VPointCurrIsEmpty then begin
      VPointCurrCode := GetCode(VMapPixelRect, VPointCurr);
      VPointCurrLocal.X := VPointCurr.X - VMapPixelRect.Left;
      VPointCurrLocal.Y := VPointCurr.Y - VMapPixelRect.Top;
      if not VPointPrevIsEmpty then begin
        if (VPointPrevCode and VPointCurrCode) = 0 then begin
          if not Result then begin
            InitBitmap(ATargetBmp, Types.Point(AMapRect.Right - AMapRect.Left, AMapRect.Bottom - AMapRect.Top));
            Result := True;
          end;
          DrawSection(ATargetBmp, ATrackColorer, ALineWidth, VPointPrevLocal, VPointCurrLocal, FPointsProjected[i].Speed);
        end;
      end;
    end;
    VPointPrev := VPointCurr;
    VPointPrevLocal := VPointCurrLocal;
    VPointPrevIsEmpty := VPointCurrIsEmpty;
    VPointPrevCode := VPointCurrCode;
  end;
end;

procedure TBitmapLayerProviderByTrackPath.DrawSection(
  ATargetBmp: TCustomBitmap32;
  const ATrackColorer: ITrackColorerStatic;
  const ALineWidth: Double;
  const APointPrev, APointCurr: TDoublePoint;
  const ASpeed: Double
);
var
  VSegmentColor: TColor32;
  VLine: TArrayOfFloatPoint;
  VLines: TArrayOfArrayOfFloatPoint;
begin
  if (APointPrev.x < 32767) and (APointPrev.x > -32767) and (APointPrev.y < 32767) and (APointPrev.y > -32767) then begin
    VSegmentColor := ATrackColorer.GetColorForSpeed(ASpeed);
    SetLength(VLine, 2);
    VLine[0] := FloatPoint(APointPrev.X, APointPrev.Y);
    VLine[1] := FloatPoint(APointCurr.X, APointCurr.Y);
    SetLength(VLines, 1);
    VLines[0] := VLine;
    VLines := BuildPolyPolyLine(VLines, False, ALineWidth);

    PolyPolygonFS(
      ATargetBmp,
      VLines,
      VSegmentColor
    );
  end;
end;

function TBitmapLayerProviderByTrackPath.GetTile(
  AOperationID: Integer;
  const ACancelNotifier: INotifierOperation;
  const AProjection: IProjection;
  const ATile: TPoint
): IBitmap32Static;
var
  VTargetRect: TRect;
  VLonLatRect: TDoubleRect;
  VBitmap: TBitmap32ByStaticBitmap;
begin
  Result := nil;
  if not FRectIsEmpty then begin
    VTargetRect := AProjection.TilePos2PixelRect(ATile);
    AProjection.ValidatePixelRect(VTargetRect);
    VLonLatRect := AProjection.PixelRect2LonLatRect(VTargetRect);
    if IsIntersecLonLatRect(FLonLatRect, VLonLatRect) then begin
      VBitmap := TBitmap32ByStaticBitmap.Create(FBitmap32StaticFactory);
      try
        if not AProjection.IsSame(FPreparedProjection) then begin
          PrepareProjectedPoints(AProjection);
        end;
        if
          DrawPath(
            AOperationID,
            ACancelNotifier,
            VBitmap,
            AProjection,
            VTargetRect,
            FTrackColorer,
            FLineWidth,
            FPointsProjectedCount
          )
        then begin
          Result := VBitmap.MakeAndClear;
        end;
      finally
        VBitmap.Free;
      end;
    end;
  end;
end;

procedure TBitmapLayerProviderByTrackPath.InitBitmap(
  ATargetBmp: TCustomBitmap32;
  const ASize: TPoint
);
begin
  ATargetBmp.SetSize(ASize.X, ASize.Y);
  ATargetBmp.Clear(0);
  ATargetBmp.CombineMode := cmMerge;
end;

procedure TBitmapLayerProviderByTrackPath.PrepareLonLatPointsByEnum(
  AMaxPointsCount: Integer;
  const AEnum: IEnumGPSTrackPoint
);
var
  i: Integer;
  VPoint: TGPSTrackPoint;
begin
  FRectIsEmpty := True;
  FPointsLonLatCount := 0;
  i := 0;
  while (i < AMaxPointsCount) and AEnum.Next(VPoint) do begin
    if not PointIsEmpty(VPoint.Point) then begin
      if FRectIsEmpty then begin
        FLonLatRect.TopLeft := VPoint.Point;
        FLonLatRect.BottomRight := VPoint.Point;
        FRectIsEmpty := False;
      end else begin
        UpdateLonLatMBRByPoint(FLonLatRect, VPoint.Point);
      end;
    end;
    FPointsLonLat[i] := VPoint;
    Inc(i);
  end;
  FPointsLonLatCount := i;
end;

procedure TBitmapLayerProviderByTrackPath.PrepareProjectedPoints(
  const AProjection: IProjection
);
var
  i: Integer;
  VIndex: Integer;
  VPoint: TGPSTrackPoint;
  VProjectionType: IProjectionType;
  VCurrPointIsEmpty: Boolean;
  VPrevPointIsEmpty: Boolean;
  VCurrPoint: TDoublePoint;
  VPrevPoint: TDoublePoint;
begin
  FPointsProjectedCount := 0;
  FPreparedProjection := AProjection;
  VProjectionType := AProjection.ProjectionType;
  i := 0;
  VIndex := 0;
  VPrevPointIsEmpty := True;
  while (i < FPointsLonLatCount) do begin
    VPoint := FPointsLonLat[i];
    VCurrPointIsEmpty := PointIsEmpty(VPoint.Point);
    if not VCurrPointIsEmpty then begin
      VProjectionType.ValidateLonLatPos(VPoint.Point);
      if FRectIsEmpty then begin
        FLonLatRect.TopLeft := VPoint.Point;
        FLonLatRect.BottomRight := VPoint.Point;
        FRectIsEmpty := False;
      end else begin
        UpdateLonLatMBRByPoint(FLonLatRect, VPoint.Point);
      end;
      VPoint.Point := AProjection.LonLat2PixelPosFloat(VPoint.Point);
    end;

    VCurrPoint := VPoint.Point;
    if VCurrPointIsEmpty then begin
      if not VPrevPointIsEmpty then begin
        FPointsProjected[VIndex] := VPoint;
        Inc(VIndex);
        VPrevPointIsEmpty := VCurrPointIsEmpty;
        VPrevPoint := VCurrPoint;
      end;
    end else begin
      if VPrevPointIsEmpty then begin
        FPointsProjected[VIndex] := VPoint;
        Inc(VIndex);
        VPrevPointIsEmpty := VCurrPointIsEmpty;
        VPrevPoint := VCurrPoint;
      end else begin
        if (abs(VPrevPoint.X - VCurrPoint.X) > 2) or
          (abs(VPrevPoint.Y - VCurrPoint.Y) > 2) then begin
          FPointsProjected[VIndex] := VPoint;
          Inc(VIndex);
          VPrevPointIsEmpty := VCurrPointIsEmpty;
          VPrevPoint := VCurrPoint;
        end;
      end;
    end;
    Inc(i);
  end;
  FPointsProjectedCount := VIndex;
end;

end.

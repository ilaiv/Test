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

unit u_VectorTileRenderer;

interface

uses
  Types,
  GR32,
  t_GeoTypes,
  i_NotifierOperation,
  i_Appearance,
  i_Projection,
  i_Bitmap32Static,
  i_Bitmap32BufferFactory,
  i_GeometryLonLat,
  i_GeometryProjected,
  i_GeometryProjectedProvider,
  i_VectorDataItemSimple,
  i_VectorItemSubset,
  i_BitmapMarker,
  i_MarkerProviderByAppearancePointIcon,
  i_VectorTileRenderer,
  u_BaseInterfacedObject;

type
  TVectorTileRenderer = class(TBaseInterfacedObject, IVectorTileRenderer)
  private
    FColorMain: TColor32;
    FColorBG: TColor32;
    FPointMarker: IBitmapMarker;
    FBitmap32StaticFactory: IBitmap32StaticFactory;
    FMarkerIconProvider: IMarkerProviderByAppearancePointIcon;
    FProjectedCache: IGeometryProjectedProvider;

    function DrawSubset(
      AOperationID: Integer;
      const ACancelNotifier: INotifierOperation;
      const AMarksSubset: IVectorItemSubset;
      ATargetBmp: TCustomBitmap32;
      const AProjection: IProjection;
      const AMapRect: TRect;
      var APointArray: TArrayOfFloatPoint
    ): Boolean;
    function DrawPoint(
      var ABitmapInited: Boolean;
      ATargetBmp: TCustomBitmap32;
      const AProjection: IProjection;
      const AMapRect: TRect;
      const AGeometry: IGeometryLonLatPoint;
      const APoint: IVectorDataItem
    ): Boolean;
    function DrawPath(
      var ABitmapInited: Boolean;
      ATargetBmp: TCustomBitmap32;
      const AProjection: IProjection;
      const AMapRect: TRect;
      const AAppearance: IAppearance;
      const ALine: IGeometryLonLatLine;
      var APointArray: TArrayOfFloatPoint
    ): Boolean;
    function DrawPoly(
      var ABitmapInited: Boolean;
      ATargetBmp: TCustomBitmap32;
      const AProjection: IProjection;
      const AMapRect: TRect;
      const AAppearance: IAppearance;
      const APoly: IGeometryLonLatPolygon;
      var APointArray: TArrayOfFloatPoint
    ): Boolean;
    function DrawSinglePolygon(
      var ABitmapInited: Boolean;
      ATargetBmp: TCustomBitmap32;
      const AMapRect: TRect;
      const AAppearance: IAppearance;
      const APoly: IGeometryProjectedSinglePolygon;
      var APointArray: TArrayOfFloatPoint
    ): Boolean;
    procedure InitBitmap(
      ATargetBmp: TCustomBitmap32;
      const ASize: TPoint
    );
    function GetMarkerBoundsForPosition(
      const AMarker: IBitmapMarker;
      const APosition: TDoublePoint
    ): TRect;
    function DrawMarkerToBitmap(
      ABitmap: TCustomBitmap32;
      const AMarker: IBitmapMarker;
      const APosition: TDoublePoint
    ): Boolean;
  private
    function RenderVectorTile(
      AOperationID: Integer;
      const ACancelNotifier: INotifierOperation;
      const AProjection: IProjection;
      const ATile: TPoint;
      const ASource: IVectorItemSubset
    ): IBitmap32Static;
  public
    constructor Create(
      AColorMain: TColor32;
      AColorBG: TColor32;
      const APointMarker: IBitmapMarker;
      const ABitmap32StaticFactory: IBitmap32StaticFactory;
      const AProjectedCache: IGeometryProjectedProvider;
      const AMarkerIconProvider: IMarkerProviderByAppearancePointIcon
    );
  end;

implementation

uses
  ActiveX,
  Math,
  SysUtils,
  GR32_Polygons,
  i_AppearanceOfVectorItem,
  u_Bitmap32ByStaticBitmap,
  u_GeoFunc,
  u_BitmapFunc,
  u_GeometryFunc;

{ TVectorTileRenderer }

constructor TVectorTileRenderer.Create(
  AColorMain: TColor32;
  AColorBG: TColor32;
  const APointMarker: IBitmapMarker;
  const ABitmap32StaticFactory: IBitmap32StaticFactory;
  const AProjectedCache: IGeometryProjectedProvider;
  const AMarkerIconProvider: IMarkerProviderByAppearancePointIcon
);
begin
  Assert(Assigned(APointMarker));
  Assert(Assigned(ABitmap32StaticFactory));
  Assert(Assigned(AProjectedCache));
  Assert(Assigned(AMarkerIconProvider));
  inherited Create;
  FColorMain := AColorMain;
  FColorBG := AColorBG;
  FPointMarker := APointMarker;
  FBitmap32StaticFactory := ABitmap32StaticFactory;
  FProjectedCache := AProjectedCache;
  FMarkerIconProvider := AMarkerIconProvider;
end;

function TVectorTileRenderer.DrawPoint(
  var ABitmapInited: Boolean;
  ATargetBmp: TCustomBitmap32;
  const AProjection: IProjection;
  const AMapRect: TRect;
  const AGeometry: IGeometryLonLatPoint;
  const APoint: IVectorDataItem
): Boolean;
var
  VLonLat: TDoublePoint;
  VMapPoint: TDoublePoint;
  VLocalPoint: TDoublePoint;
  VRect: TRect;
  VDrawMarker: IBitmapMarker;
  VAppearanceIcon: IAppearancePointIcon;
begin
  Result := False;
  VLonLat := AGeometry.Point;
  AProjection.ProjectionType.ValidateLonLatPos(VLonLat);
  VMapPoint := AProjection.LonLat2PixelPosFloat(VLonLat);
  VLocalPoint.X := VMapPoint.X - AMapRect.Left;
  VLocalPoint.Y := VMapPoint.Y - AMapRect.Top;
  if Supports(APoint.Appearance, IAppearancePointIcon, VAppearanceIcon) then begin
    VDrawMarker := FMarkerIconProvider.GetMarker(VAppearanceIcon);
  end;
  if not Assigned(VDrawMarker) then begin
    VDrawMarker := FPointMarker;
  end;

  VRect := GetMarkerBoundsForPosition(VDrawMarker, VLocalPoint);
  if Types.IntersectRect(VRect, Rect(0, 0, AMapRect.Right - AMapRect.Left, AMapRect.Bottom - AMapRect.Top), VRect) then begin
    if not ABitmapInited then begin
      InitBitmap(ATargetBmp, Types.Point(AMapRect.Right - AMapRect.Left, AMapRect.Bottom - AMapRect.Top));
      ABitmapInited := True;
    end;

    Result := DrawMarkerToBitmap(ATargetBmp, VDrawMarker, VLocalPoint);
  end;
end;

function TVectorTileRenderer.DrawPath(
  var ABitmapInited: Boolean;
  ATargetBmp: TCustomBitmap32;
  const AProjection: IProjection;
  const AMapRect: TRect;
  const AAppearance: IAppearance;
  const ALine: IGeometryLonLatLine;
  var APointArray: TArrayOfFloatPoint
): Boolean;
var
  VPolygon: TArrayOfArrayOfFloatPoint;
  VProjected: IGeometryProjectedLine;
  VAppearanceLine: IAppearanceLine;
begin
  Result := False;
  VProjected := FProjectedCache.GetProjectedPath(AProjection, ALine);
  VPolygon := ProjectedLine2ArrayOfArray(VProjected, AMapRect, APointArray);
  if Assigned(VPolygon) then begin
    if not ABitmapInited then begin
      InitBitmap(ATargetBmp, Types.Point(AMapRect.Right - AMapRect.Left, AMapRect.Bottom - AMapRect.Top));
      ABitmapInited := True;
    end;

    if Supports(AAppearance, IAppearanceLine, VAppearanceLine) then begin
      PolyPolylineFS(ATargetBmp, VPolygon, VAppearanceLine.LineColor, False, VAppearanceLine.LineWidth);
    end else begin
      PolyPolylineFS(ATargetBmp, VPolygon, FColorBG, False, 2);
      PolyPolylineFS(ATargetBmp, VPolygon, FColorMain, False, 1);
    end;

    Result := True;
  end;
end;

function TVectorTileRenderer.DrawSinglePolygon(
  var ABitmapInited: Boolean;
  ATargetBmp: TCustomBitmap32;
  const AMapRect: TRect;
  const AAppearance: IAppearance;
  const APoly: IGeometryProjectedSinglePolygon;
  var APointArray: TArrayOfFloatPoint
): Boolean;
var
  VPolygon: TArrayOfArrayOfFloatPoint;
  VAppearanceBorder: IAppearancePolygonBorder;
  VAppearanceFill: IAppearancePolygonFill;
begin
  Result := False;
  VPolygon := ProjectedPolygon2ArrayOfArray(APoly, AMapRect, APointArray);
  if VPolygon <> nil then begin
    if not ABitmapInited then begin
      InitBitmap(ATargetBmp, Types.Point(AMapRect.Right - AMapRect.Left, AMapRect.Bottom - AMapRect.Top));
      ABitmapInited := True;
    end;
    if Assigned(AAppearance) then begin
      if Supports(AAppearance, IAppearancePolygonFill, VAppearanceFill) then begin
        PolyPolygonFS(ATargetBmp, VPolygon, VAppearanceFill.FillColor, pfWinding);
      end;
      if Supports(AAppearance, IAppearancePolygonBorder, VAppearanceBorder) then begin
        PolyPolylineFS(ATargetBmp, VPolygon, VAppearanceBorder.LineColor, True, VAppearanceBorder.LineWidth);
      end;
    end else begin
      PolyPolylineFS(ATargetBmp, VPolygon, FColorBG, True, 2);
      PolyPolylineFS(ATargetBmp, VPolygon, FColorMain, True, 1);
    end;
    Result := True;
  end;
end;

function TVectorTileRenderer.DrawPoly(
  var ABitmapInited: Boolean;
  ATargetBmp: TCustomBitmap32;
  const AProjection: IProjection;
  const AMapRect: TRect;
  const AAppearance: IAppearance;
  const APoly: IGeometryLonLatPolygon;
  var APointArray: TArrayOfFloatPoint
): Boolean;
var
  VProjected: IGeometryProjectedPolygon;
  VProjectedSingle: IGeometryProjectedSinglePolygon;
  VProjectedMulti: IGeometryProjectedMultiPolygon;
  i: Integer;
begin
  Result := False;
  VProjected := FProjectedCache.GetProjectedPolygon(AProjection, APoly);
  if Assigned(VProjected) then begin
    if Supports(VProjected, IGeometryProjectedSinglePolygon, VProjectedSingle) then begin
      Result := DrawSinglePolygon(ABitmapInited, ATargetBmp, AMapRect, AAppearance, VProjectedSingle, APointArray);
    end else if Supports(VProjected, IGeometryProjectedMultiPolygon, VProjectedMulti) then begin
      for i := 0 to VProjectedMulti.Count - 1 do begin
        VProjectedSingle := VProjectedMulti.Item[i];
        if DrawSinglePolygon(ABitmapInited, ATargetBmp, AMapRect, AAppearance, VProjectedSingle, APointArray) then begin
          Result := True;
        end;
      end;
    end else begin
      Assert(False);
    end;
  end;
end;

function TVectorTileRenderer.DrawSubset(
  AOperationID: Integer;
  const ACancelNotifier: INotifierOperation;
  const AMarksSubset: IVectorItemSubset;
  ATargetBmp: TCustomBitmap32;
  const AProjection: IProjection;
  const AMapRect: TRect;
  var APointArray: TArrayOfFloatPoint
): Boolean;
var
  VEnumMarks: IEnumUnknown;
  VMark: IVectorDataItem;
  i: Cardinal;
  VPoint: IGeometryLonLatPoint;
  VLine: IGeometryLonLatLine;
  VPoly: IGeometryLonLatPolygon;
  VBitmapInited: Boolean;
begin
  Result := False;
  VBitmapInited := False;
  VEnumMarks := AMarksSubset.GetEnum;
  while (VEnumMarks.Next(1, VMark, @i) = S_OK) do begin
    if ACancelNotifier.IsOperationCanceled(AOperationID) then begin
      Break;
    end;
    if Supports(VMark.Geometry, IGeometryLonLatPolygon, VPoly) then begin
      if DrawPoly(VBitmapInited, ATargetBmp, AProjection, AMapRect, VMark.Appearance, VPoly, APointArray) then begin
        Result := True;
      end;
    end;
  end;
  VEnumMarks.Reset;
  while (VEnumMarks.Next(1, VMark, @i) = S_OK) do begin
    if ACancelNotifier.IsOperationCanceled(AOperationID) then begin
      Break;
    end;
    if Supports(VMark.Geometry, IGeometryLonLatLine, VLine) then begin
      if DrawPath(VBitmapInited, ATargetBmp, AProjection, AMapRect, VMark.Appearance, VLine, APointArray) then begin
        Result := True;
      end;
    end;
  end;
  VEnumMarks.Reset;
  while (VEnumMarks.Next(1, VMark, @i) = S_OK) do begin
    if ACancelNotifier.IsOperationCanceled(AOperationID) then begin
      Break;
    end;
    if Supports(VMark.Geometry, IGeometryLonLatPoint, VPoint) then begin
      if DrawPoint(VBitmapInited, ATargetBmp, AProjection, AMapRect, VPoint, VMark) then begin
        Result := True;
      end;
    end;
  end;
end;

function TVectorTileRenderer.RenderVectorTile(
  AOperationID: Integer;
  const ACancelNotifier: INotifierOperation;
  const AProjection: IProjection;
  const ATile: TPoint;
  const ASource: IVectorItemSubset
): IBitmap32Static;
var
  VMapRect: TRect;
  VBitmap: TBitmap32ByStaticBitmap;
  VPointArray: TArrayOfFloatPoint;
begin
  Result := nil;
  if Assigned(ASource) and not ASource.IsEmpty then begin
    VBitmap := TBitmap32ByStaticBitmap.Create(FBitmap32StaticFactory);
    try
      VMapRect := AProjection.TilePos2PixelRect(ATile);
      if DrawSubset(AOperationID, ACancelNotifier, ASource, VBitmap, AProjection, VMapRect, VPointArray) then begin
        Result := VBitmap.MakeAndClear;
      end;
    finally
      VBitmap.Free;
    end;
  end;
end;

procedure TVectorTileRenderer.InitBitmap(
  ATargetBmp: TCustomBitmap32;
  const ASize: TPoint
);
begin
  ATargetBmp.SetSize(ASize.X, ASize.Y);
  ATargetBmp.Clear(0);
  ATargetBmp.CombineMode := cmMerge;
end;

function TVectorTileRenderer.GetMarkerBoundsForPosition(
  const AMarker: IBitmapMarker;
  const APosition: TDoublePoint
): TRect;
var
  VTargetPoint: TPoint;
  VTargetPointFloat: TDoublePoint;
  VSourceSize: TPoint;
begin
  VTargetPointFloat :=
    DoublePoint(
      APosition.X - AMarker.AnchorPoint.X,
      APosition.Y - AMarker.AnchorPoint.Y
    );
  VSourceSize := AMarker.Size;
  VTargetPoint := PointFromDoublePoint(VTargetPointFloat, prToTopLeft);

  Result.TopLeft := VTargetPoint;
  Result.Right := Result.Left + VSourceSize.X;
  Result.Bottom := Result.Top + VSourceSize.Y;
end;

function TVectorTileRenderer.DrawMarkerToBitmap(
  ABitmap: TCustomBitmap32;
  const AMarker: IBitmapMarker;
  const APosition: TDoublePoint
): Boolean;
var
  VTargetPoint: TPoint;
  VTargetRect: TRect;
begin
  VTargetRect := GetMarkerBoundsForPosition(AMarker, APosition);
  VTargetPoint := VTargetRect.TopLeft;
  Types.IntersectRect(VTargetRect, ABitmap.ClipRect, VTargetRect);
  if Types.IsRectEmpty(VTargetRect) then begin
    Result := False;
    Exit;
  end;

  BlockTransferFull(
    ABitmap,
    VTargetPoint.X, VTargetPoint.Y,
    AMarker,
    dmBlend,
    ABitmap.CombineMode
  );
  Result := True;
end;

end.

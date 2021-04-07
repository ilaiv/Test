{******************************************************************************}
{* SAS.Planet (SAS.�������)                                                   *}
{* Copyright (C) 2007-2018, SAS.Planet development team.                      *}
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

unit u_GeometryLonLatFactory;

interface

uses
  t_GeoTypes,
  i_HashFunction,
  i_Datum,
  i_EnumDoublePoint,
  i_DoublePoints,
  i_DoublePointFilter,
  i_DoublePointsAggregator,
  i_GeometryLonLat,
  i_GeometryLonLatFactory,
  i_InternalPerformanceCounter,
  u_BaseInterfacedObject;

type
  TGeometryLonLatFactory = class(TBaseInterfacedObject, IGeometryLonLatFactory)
  private
    FHashFunction: IHashFunction;

    FLineToPolyByGenCounter: IInternalPerformanceCounter;
    FLineToPolyByFilterCounter: IInternalPerformanceCounter;

    function CreateLonLatPolygonInternal(
      const ARect: TDoubleRect;
      const APoints: IDoublePoints
    ): IGeometryLonLatSinglePolygon;
    procedure AddPolygonsBySingleLine(
      const ASource: IGeometryLonLatSingleLine;
      const AFilter: ILonLatPointFilter;
      const ABuilder: IGeometryLonLatPolygonBuilder;
      const ATemp: IDoublePointsAggregator
    );
  private
    function CreateLonLatPoint(
      const APoint: TDoublePoint
    ): IGeometryLonLatPoint;
    function CreateLonLatMultiPoint(
      const APoints: PDoublePointArray;
      ACount: Integer
    ): IGeometryLonLatMultiPoint;

    function MakeLineBuilder(): IGeometryLonLatLineBuilder;
    function MakePolygonBuilder(): IGeometryLonLatPolygonBuilder;

    function CreateLonLatLine(
      const APoints: PDoublePointArray;
      ACount: Integer
    ): IGeometryLonLatLine;
    function CreateLonLatPolygon(
      const APoints: PDoublePointArray;
      ACount: Integer
    ): IGeometryLonLatPolygon;
    function CreateLonLatLineByEnum(
      const AEnum: IEnumLonLatPoint;
      const ATemp: IDoublePointsAggregator = nil
    ): IGeometryLonLatLine;

    function CreateLonLatPolygonByRect(
      const ARect: TDoubleRect
    ): IGeometryLonLatSinglePolygon;

    function CreateLonLatPolygonCircleByPoint(
      const ADatum: IDatum;
      const APos: TDoublePoint;
      const ARadius: double
    ): IGeometryLonLatSinglePolygon;

    function CreateLonLatPolygonSquareByPoint(
      const ADatum: IDatum;
      const APos: TDoublePoint;
      const ARadius: double
    ): IGeometryLonLatSinglePolygon;

    function CreateLonLatPolygonSquareOnSurfaceByPoint(
      const ADatum: IDatum;
      const APos: TDoublePoint;
      const ARadius: double
    ): IGeometryLonLatSinglePolygon;

    function CreateLonLatPolygonByLine(
      const ADatum: IDatum;
      const ALine: IGeometryLonLatLine;
      const ARadius: Double
    ): IGeometryLonLatPolygon;

    function CreateLonLatPolygonByLonLatPathAndFilter(
      const ASource: IGeometryLonLatLine;
      const AFilter: ILonLatPointFilter
    ): IGeometryLonLatPolygon;
  public
    constructor Create(
      const APerfCounterList: IInternalPerformanceCounterList;
      const AHashFunction: IHashFunction
    );
  end;

implementation

uses
  Math,
  SysUtils,
  t_Hash,
  i_LonLatRect,
  i_InterfaceListSimple,
  u_GeoFunc,
  u_InterfaceListSimple,
  u_DoublePointsAggregator,
  u_GeometryLonLat,
  u_DoublePoints,
  u_LonLatRect,
  u_LonLatRectByPoint,
  u_LonLatPolygonGenerator,
  u_EnumDoublePointByLineSet,
  u_GeometryLonLatMulti;

function MakeLonLatRectByRect(const ARect: TDoubleRect): ILonLatRect;
begin
  if (ARect.Left <> ARect.Right) or (ARect.Top <> ARect.Bottom) then begin
    Result := TLonLatRect.Create(ARect);
  end else begin
    Result := TLonLatRectByPoint.Create(ARect.TopLeft);
  end;
end;

type
  TGeometryLonLatLineBuilder = class(TBaseInterfacedObject, IGeometryLonLatLineBuilder)
  private
    FHashFunction: IHashFunction;
    FHash: THashValue;
    FBounds: TDoubleRect;
    FLine: IGeometryLonLatSingleLine;
    FList: IInterfaceListSimple;
  private
    procedure AddLine(
      const ABounds: TDoubleRect;
      const APoints: IDoublePoints
    ); overload;
    procedure AddLine(
      const APoints: IDoublePoints
    ); overload;

    function MakeStaticAndClear: IGeometryLonLatLine;
    function MakeStaticCopy: IGeometryLonLatLine;
  public
    constructor Create(
      const AHashFunction: IHashFunction
    );
  end;

{ TGeometryLonLatLineBuilder }

constructor TGeometryLonLatLineBuilder.Create(
  const AHashFunction: IHashFunction
);
begin
  inherited Create;
  FHashFunction := AHashFunction;
end;

procedure TGeometryLonLatLineBuilder.AddLine(
  const ABounds: TDoubleRect;
  const APoints: IDoublePoints
);
var
  VLine: IGeometryLonLatSingleLine;
  VHash: THashValue;
  VRect: ILonLatRect;
begin
  Assert(Assigned(APoints));
  VRect := MakeLonLatRectByRect(ABounds);
  VHash := FHashFunction.CalcHashByBuffer(APoints.Points, APoints.Count * SizeOf(TDoublePoint));
  VLine := TGeometryLonLatSingleLine.Create(VRect, VHash, APoints);

  if not Assigned(FLine) then begin
    FLine := VLine;
    FHash := VHash;
    FBounds := ABounds;
  end else begin
    if not Assigned(FList) then begin
      FList := TInterfaceListSimple.Create;
      FList.Add(FLine);
    end else if FList.Count = 0 then begin
      FList.Add(FLine);
    end;
    FList.Add(VLine);
    FHashFunction.UpdateHashByHash(FHash, VHash);
    FBounds := VRect.UnionWithRect(FBounds);
  end;
end;

procedure TGeometryLonLatLineBuilder.AddLine(
  const APoints: IDoublePoints
);
begin
  Assert(Assigned(APoints));
  AddLine(LonLatMBRByPoints(APoints.Points, APoints.Count), APoints);
end;

function TGeometryLonLatLineBuilder.MakeStaticAndClear: IGeometryLonLatLine;
var
  VRect: ILonLatRect;
begin
  Result := nil;
  if Assigned(FLine) then begin
    if Assigned(FList) and (FList.Count > 0) then begin
      VRect := TLonLatRect.Create(FBounds);
      Result := TGeometryLonLatMultiLine.Create(VRect, FHash, FList.MakeStaticAndClear);
    end else begin
      Result := FLine;
    end;
    FLine := nil;
  end;
end;

function TGeometryLonLatLineBuilder.MakeStaticCopy: IGeometryLonLatLine;
var
  VRect: ILonLatRect;
begin
  Result := nil;
  if Assigned(FLine) then begin
    if Assigned(FList) and (FList.Count > 0) then begin
      VRect := TLonLatRect.Create(FBounds);
      Result := TGeometryLonLatMultiLine.Create(VRect, FHash, FList.MakeStaticCopy);
    end else begin
      Result := FLine;
    end;
  end;
end;

type
  TGeometryLonLatPolygonBuilder = class(TBaseInterfacedObject, IGeometryLonLatPolygonBuilder)
  private
    FHashFunction: IHashFunction;

    FReadyMultiPolygon: IGeometryLonLatMultiPolygon;
    FReadySinglePolygon: IGeometryLonLatSinglePolygon;
    FReadyOuterContour: IGeometryLonLatContour;

    FOuterDataExists: Boolean;

    FPolygonBounds: TDoubleRect;
    FPolygonHash: THashValue;
    FMultiPolygonBounds: TDoubleRect;
    FMultiPolygonHash: THashValue;

    FPoints: IDoublePoints;
    FOuterContourHash: THashValue;
    FPolygonList: IInterfaceListSimple;
    FHoleList: IInterfaceListSimple;
    procedure AddSinglePolygonToList(const APolygon: IGeometryLonLatSinglePolygon);
    procedure AddHoleContourToList(const AContour: IGeometryLonLatContour);
    function MakeCurrentSinglePolygon(const AIsClear: Boolean): IGeometryLonLatSinglePolygon;
  private
    procedure AddPolygon(
      const APolygon: IGeometryLonLatSinglePolygon
    ); overload;
    procedure AddPolygon(
      const APolygon: IGeometryLonLatMultiPolygon
    ); overload;
    procedure AddPolygon(
      const APolygon: IGeometryLonLatPolygon
    ); overload;
    procedure AddOuter(
      const ABounds: TDoubleRect;
      const APoints: IDoublePoints
    ); overload;
    procedure AddOuter(
      const APoints: IDoublePoints
    ); overload;
    procedure AddOuter(
      const AContour: IGeometryLonLatContour
    ); overload;
    procedure AddHole(
      const ABounds: TDoubleRect;
      const APoints: IDoublePoints
    ); overload;
    procedure AddHole(
      const APoints: IDoublePoints
    ); overload;
    procedure AddHole(
      const AContour: IGeometryLonLatContour
    ); overload;

    function MakeStaticAndClear: IGeometryLonLatPolygon;
    function MakeStaticCopy: IGeometryLonLatPolygon;
  public
    constructor Create(
      const AHashFunction: IHashFunction
    );
  end;

{ TGeometryLonLatPolygonBuilder }

constructor TGeometryLonLatPolygonBuilder.Create(
  const AHashFunction: IHashFunction
);
begin
  Assert(Assigned(AHashFunction));
  inherited Create;
  FHashFunction := AHashFunction;
end;

procedure TGeometryLonLatPolygonBuilder.AddHoleContourToList(
  const AContour: IGeometryLonLatContour
);
begin
  if not Assigned(FHoleList) then begin
    FHoleList := TInterfaceListSimple.Create;
  end;
  FHoleList.Add(AContour);
  FHashFunction.UpdateHashByHash(FPolygonHash, AContour.Hash);
end;

procedure TGeometryLonLatPolygonBuilder.AddSinglePolygonToList(
  const APolygon: IGeometryLonLatSinglePolygon
);
begin
  if not Assigned(FPolygonList) then begin
    FPolygonList := TInterfaceListSimple.Create;
  end;
  if FPolygonList.Count = 0 then begin
    FMultiPolygonBounds := APolygon.Bounds.Rect;
    FMultiPolygonHash := $db1267d24f3f3f36;
  end else begin
    FMultiPolygonBounds := APolygon.Bounds.UnionWithRect(FMultiPolygonBounds);
  end;
  FHashFunction.UpdateHashByHash(FMultiPolygonHash, APolygon.Hash);
  FPolygonList.Add(APolygon);
end;

procedure TGeometryLonLatPolygonBuilder.AddPolygon(
  const APolygon: IGeometryLonLatPolygon
);
var
  VSinglePolygon: IGeometryLonLatSinglePolygon;
  VMultiPolygon: IGeometryLonLatMultiPolygon;
begin
  if Supports(APolygon, IGeometryLonLatSinglePolygon, VSinglePolygon) then begin
    AddPolygon(VSinglePolygon);
  end else if Supports(APolygon, IGeometryLonLatMultiPolygon, VMultiPolygon) then begin
    AddPolygon(VMultiPolygon);
  end else begin
    Assert(False);
  end;
end;

procedure TGeometryLonLatPolygonBuilder.AddPolygon(
  const APolygon: IGeometryLonLatSinglePolygon
);
var
  i: Integer;
  VPolygon: IGeometryLonLatSinglePolygon;
begin
  Assert(Assigned(APolygon));
  if FOuterDataExists then begin
    if Assigned(FReadyMultiPolygon) then begin
      for i := 0 to FReadyMultiPolygon.Count - 1 do begin
        VPolygon := FReadyMultiPolygon.Item[i];
        AddSinglePolygonToList(VPolygon);
      end;
      FReadyMultiPolygon := nil;
    end else if Assigned(FReadySinglePolygon) then begin
      VPolygon := FReadySinglePolygon;
      AddSinglePolygonToList(VPolygon);
      FReadySinglePolygon := nil;
    end else if Assigned(FPoints) or Assigned(FReadyOuterContour) then begin
      VPolygon := MakeCurrentSinglePolygon(True);
      AddSinglePolygonToList(VPolygon);
    end else begin
      Assert(False);
    end;
  end;
  FOuterDataExists := True;
  FReadySinglePolygon := APolygon;
end;

procedure TGeometryLonLatPolygonBuilder.AddPolygon(
  const APolygon: IGeometryLonLatMultiPolygon
);
var
  i: Integer;
  VPolygon: IGeometryLonLatSinglePolygon;
begin
  Assert(Assigned(APolygon));
  if FOuterDataExists then begin
    if Assigned(FReadyMultiPolygon) then begin
      for i := 0 to FReadyMultiPolygon.Count - 1 do begin
        VPolygon := FReadyMultiPolygon.Item[i];
        AddSinglePolygonToList(VPolygon);
      end;
      FReadyMultiPolygon := nil;
    end else if Assigned(FReadySinglePolygon) then begin
      VPolygon := FReadySinglePolygon;
      AddSinglePolygonToList(VPolygon);
      FReadySinglePolygon := nil;
    end else if Assigned(FPoints) or Assigned(FReadyOuterContour) then begin
      VPolygon := MakeCurrentSinglePolygon(True);
      AddSinglePolygonToList(VPolygon);
    end else begin
      Assert(False);
    end;
    for i := 0 to APolygon.Count - 2 do begin
      VPolygon := APolygon.Item[i];
      AddSinglePolygonToList(VPolygon);
    end;
    FReadySinglePolygon := APolygon.Item[APolygon.Count - 1];
  end else begin
    FReadyMultiPolygon := APolygon;
    FOuterDataExists := True;
  end;
end;

procedure TGeometryLonLatPolygonBuilder.AddHole(
  const AContour: IGeometryLonLatContour
);
var
  i: Integer;
  VPolygon: IGeometryLonLatSinglePolygon;
begin
  Assert(Assigned(AContour));
  if FOuterDataExists then begin
    if Assigned(FReadyMultiPolygon) then begin
      for i := 0 to FReadyMultiPolygon.Count - 2 do begin
        VPolygon := FReadyMultiPolygon.Item[i];
        AddSinglePolygonToList(VPolygon);
      end;
      FReadySinglePolygon := FReadyMultiPolygon.Item[FReadyMultiPolygon.Count];
      FReadyMultiPolygon := nil;
    end;
    if Assigned(FReadySinglePolygon) then begin
      FReadyOuterContour := FReadySinglePolygon.OuterBorder;
      FOuterContourHash := FReadyOuterContour.Hash;
      FPolygonHash := FOuterContourHash;
      for i := 0 to FReadySinglePolygon.HoleCount - 1 do begin
        AddHoleContourToList(FReadySinglePolygon.HoleBorder[i]);
      end;
      FReadySinglePolygon := nil;
    end;
    AddHoleContourToList(AContour);
  end else begin
    FReadyOuterContour := AContour;
    FOuterContourHash := FReadyOuterContour.Hash;
    FPolygonHash := FOuterContourHash;
    FOuterDataExists := True;
  end;
end;

procedure TGeometryLonLatPolygonBuilder.AddHole(
  const APoints: IDoublePoints
);
begin
  Assert(Assigned(APoints));
  AddHole(LonLatMBRByPoints(APoints.Points, APoints.Count), APoints);
end;

procedure TGeometryLonLatPolygonBuilder.AddHole(
  const ABounds: TDoubleRect;
  const APoints: IDoublePoints
);
var
  VHole: IGeometryLonLatContour;
  VHash: THashValue;
  VRect: ILonLatRect;
begin
  Assert(Assigned(APoints));
  if FOuterDataExists then begin
    VRect := MakeLonLatRectByRect(ABounds);
    VHash := FHashFunction.CalcHashByBuffer(APoints.Points, APoints.Count * SizeOf(TDoublePoint));
    VHole := TGeometryLonLatContour.Create(VRect, VHash, APoints);
    AddHoleContourToList(VHole);
  end else begin
    FOuterDataExists := True;
    FPoints := APoints;
    FPolygonBounds := ABounds;
    FOuterContourHash := FHashFunction.CalcHashByBuffer(APoints.Points, APoints.Count * SizeOf(TDoublePoint));
    FPolygonHash := FOuterContourHash;
  end;
end;

procedure TGeometryLonLatPolygonBuilder.AddOuter(
  const AContour: IGeometryLonLatContour
);
var
  i: Integer;
  VPolygon: IGeometryLonLatSinglePolygon;
begin
  Assert(Assigned(AContour));
  if FOuterDataExists then begin
    if Assigned(FReadyMultiPolygon) then begin
      for i := 0 to FReadyMultiPolygon.Count - 1 do begin
        VPolygon := FReadyMultiPolygon.Item[i];
        AddSinglePolygonToList(VPolygon);
      end;
      FReadyMultiPolygon := nil;
    end else if Assigned(FReadySinglePolygon) then begin
      VPolygon := FReadySinglePolygon;
      AddSinglePolygonToList(VPolygon);
      FReadySinglePolygon := nil;
    end else if Assigned(FPoints) or Assigned(FReadyOuterContour) then begin
      VPolygon := MakeCurrentSinglePolygon(True);
      AddSinglePolygonToList(VPolygon);
    end else begin
      Assert(False);
    end;
  end;
  FOuterDataExists := True;
  FReadyOuterContour := AContour;
  FOuterContourHash := FReadyOuterContour.Hash;
  FPolygonHash := FOuterContourHash;
end;

procedure TGeometryLonLatPolygonBuilder.AddOuter(
  const APoints: IDoublePoints
);
begin
  Assert(Assigned(APoints));
  AddOuter(LonLatMBRByPoints(APoints.Points, APoints.Count), APoints);
end;

procedure TGeometryLonLatPolygonBuilder.AddOuter(
  const ABounds: TDoubleRect;
  const APoints: IDoublePoints
);
var
  i: Integer;
  VPolygon: IGeometryLonLatSinglePolygon;
begin
  Assert(Assigned(APoints));
  if FOuterDataExists then begin
    if Assigned(FReadyMultiPolygon) then begin
      for i := 0 to FReadyMultiPolygon.Count - 1 do begin
        VPolygon := FReadyMultiPolygon.Item[i];
        AddSinglePolygonToList(VPolygon);
      end;
      FReadyMultiPolygon := nil;
    end else if Assigned(FReadySinglePolygon) then begin
      VPolygon := FReadySinglePolygon;
      AddSinglePolygonToList(VPolygon);
      FReadySinglePolygon := nil;
    end else if Assigned(FPoints) or Assigned(FReadyOuterContour) then begin
      VPolygon := MakeCurrentSinglePolygon(True);
      AddSinglePolygonToList(VPolygon);
    end else begin
      Assert(False);
    end;
  end;
  FOuterDataExists := True;
  FPoints := APoints;
  FPolygonBounds := ABounds;
  FOuterContourHash := FHashFunction.CalcHashByBuffer(APoints.Points, APoints.Count * SizeOf(TDoublePoint));
  FPolygonHash := FOuterContourHash;
end;

function TGeometryLonLatPolygonBuilder.MakeCurrentSinglePolygon(const AIsClear: Boolean): IGeometryLonLatSinglePolygon;
var
  VContour: IGeometryLonLatContour;
begin
  Assert(Assigned(FPoints) or Assigned(FReadyOuterContour));
  if Assigned(FHoleList) and (FHoleList.Count > 0) then begin
    if Assigned(FReadyOuterContour) then begin
      VContour := FReadyOuterContour;
    end else begin
      VContour :=
        TGeometryLonLatContour.Create(
          MakeLonLatRectByRect(FPolygonBounds),
          FOuterContourHash,
          FPoints
        );
    end;
    Result :=
      TGeometryLonLatSinglePolygonWithHoles.Create(
        MakeLonLatRectByRect(FPolygonBounds),
        FPolygonHash,
        VContour,
        FHoleList.MakeStaticAndClear
      );
    if AIsClear then begin
      FPoints := nil;
      FHoleList.Clear;
      FReadyOuterContour := nil;
      FOuterDataExists := false;
    end;
  end else begin
    if Assigned(FReadyOuterContour) then begin
      Result :=
        TGeometryLonLatSinglePolygon.Create(
          FReadyOuterContour.Bounds,
          FReadyOuterContour.Hash,
          TDoublePoints.Create(FReadyOuterContour.Points, FReadyOuterContour.Count)
        );
    end else begin
      Result :=
        TGeometryLonLatSinglePolygon.Create(
          MakeLonLatRectByRect(FPolygonBounds),
          FPolygonHash,
          FPoints
        );
    end;
    if AIsClear then begin
      FPoints := nil;
      FReadyOuterContour := nil;
      FOuterDataExists := false;
    end;
  end;
end;

function TGeometryLonLatPolygonBuilder.MakeStaticAndClear: IGeometryLonLatPolygon;
var
  VPolygon: IGeometryLonLatSinglePolygon;
begin
  Result := nil;
  if FOuterDataExists then begin
    if Assigned(FReadyMultiPolygon) then begin
      Result := FReadyMultiPolygon;
      FReadyMultiPolygon := nil;
      FOuterDataExists := False;
    end else if Assigned(FReadySinglePolygon) then begin
      if Assigned(FPolygonList) and (FPolygonList.Count > 0) then begin
        VPolygon := FReadySinglePolygon;
        AddSinglePolygonToList(VPolygon);

        Result :=
          TGeometryLonLatMultiPolygon.Create(
            MakeLonLatRectByRect(FMultiPolygonBounds),
            FMultiPolygonHash,
            FPolygonList.MakeStaticAndClear
          );
      end else begin
        Result := FReadySinglePolygon;
      end;
      FReadySinglePolygon := nil;
      FOuterDataExists := False;
    end else if Assigned(FPolygonList) and (FPolygonList.Count > 0) then begin
      VPolygon := MakeCurrentSinglePolygon(True);
      AddSinglePolygonToList(VPolygon);

      Result :=
        TGeometryLonLatMultiPolygon.Create(
          MakeLonLatRectByRect(FMultiPolygonBounds),
          FMultiPolygonHash,
          FPolygonList.MakeStaticAndClear
        );
    end else begin
      Result := MakeCurrentSinglePolygon(True);
    end;
  end;
end;

function TGeometryLonLatPolygonBuilder.MakeStaticCopy: IGeometryLonLatPolygon;
var
  VPolygon: IGeometryLonLatSinglePolygon;
begin
  Result := nil;
  if FOuterDataExists then begin
    if Assigned(FReadyMultiPolygon) then begin
      Result := FReadyMultiPolygon;
    end else if Assigned(FReadySinglePolygon) then begin
      if Assigned(FPolygonList) and (FPolygonList.Count > 0) then begin
        VPolygon := FReadySinglePolygon;
        AddSinglePolygonToList(VPolygon);

        Result :=
          TGeometryLonLatMultiPolygon.Create(
            MakeLonLatRectByRect(FMultiPolygonBounds),
            FMultiPolygonHash,
            FPolygonList.MakeStaticCopy
          );
      end else begin
        Result := FReadySinglePolygon;
      end;
    end else if Assigned(FPolygonList) and (FPolygonList.Count > 0) then begin
      VPolygon := MakeCurrentSinglePolygon(False);
      AddSinglePolygonToList(VPolygon);

      Result :=
        TGeometryLonLatMultiPolygon.Create(
          MakeLonLatRectByRect(FMultiPolygonBounds),
          FMultiPolygonHash,
          FPolygonList.MakeStaticCopy
        );
    end else begin
      Result := MakeCurrentSinglePolygon(False);
    end;
  end;
end;

{ TGeometryLonLatFactory }

constructor TGeometryLonLatFactory.Create(
  const APerfCounterList: IInternalPerformanceCounterList;
  const AHashFunction: IHashFunction
);
begin
  Assert(Assigned(AHashFunction));
  inherited Create;
  FHashFunction := AHashFunction;

  FLineToPolyByGenCounter := APerfCounterList.CreateAndAddNewCounter('LineToPolyByGen');
  FLineToPolyByFilterCounter := APerfCounterList.CreateAndAddNewCounter('LineToPolyByFilter');
end;

function TGeometryLonLatFactory.CreateLonLatPolygonCircleByPoint(
  const ADatum: IDatum;
  const APos: TDoublePoint;
  const ARadius: double
): IGeometryLonLatSinglePolygon;
const
  CPointCount = 64;
var
  I: Integer;
  VAngle: Double;
  VPoint: TDoublePoint;
  VBounds: TDoubleRect;
  VAggreagator: IDoublePointsAggregator;
begin
  Assert(not PointIsEmpty(APos));
  VAggreagator := TDoublePointsAggregator.Create(CPointCount);
  VBounds.TopLeft := APos;
  VBounds.BottomRight := APos;
  for I := 0 to CPointCount - 1 do begin
    VAngle := I * 360 / CPointCount;
    VPoint := ADatum.CalcFinishPosition(APos, VAngle, ARadius);
    VAggreagator.Add(VPoint);
    UpdateLonLatMBRByPoint(VBounds, VPoint);
  end;
  Result := CreateLonLatPolygonInternal(VBounds, VAggreagator.MakeStaticAndClear);
end;

function TGeometryLonLatFactory.CreateLonLatPolygonSquareByPoint(
  const ADatum: IDatum;
  const APos: TDoublePoint;
  const ARadius: double
): IGeometryLonLatSinglePolygon;
var
  I: Integer;
  VPoint: TDoublePoint;
  VBounds: TDoubleRect;
begin
  Assert(not PointIsEmpty(APos));
  VBounds.TopLeft := APos;
  VBounds.BottomRight := APos;
  for I := 0 to 3 do begin
    VPoint := ADatum.CalcFinishPosition(APos, I * 90, ARadius);
    UpdateLonLatMBRByPoint(VBounds, VPoint);
  end;
  Result := CreateLonLatPolygonByRect(VBounds);
end;

function TGeometryLonLatFactory.CreateLonLatPolygonSquareOnSurfaceByPoint(
  const ADatum: IDatum;
  const APos: TDoublePoint;
  const ARadius: double
): IGeometryLonLatSinglePolygon;
var
  VBounds: TDoubleRect;
  VAggreagator: IDoublePointsAggregator;

  procedure _AddPoint(const APoint: TDoublePoint);
  begin
    VAggreagator.Add(APoint);
    UpdateLonLatMBRByPoint(VBounds, APoint);
  end;

var
  VPoint: TDoublePoint;
begin
  Assert(not PointIsEmpty(APos));

  VBounds.TopLeft := APos;
  VBounds.BottomRight := APos;

  VAggreagator := TDoublePointsAggregator.Create(8);

  // Top
  VPoint := ADatum.CalcFinishPosition(APos, 0, ARadius);
  _AddPoint( ADatum.CalcFinishPosition(VPoint, 270, ARadius) );
  _AddPoint(VPoint);
  _AddPoint( ADatum.CalcFinishPosition(VPoint, 90, ARadius) );

  // Right
  _AddPoint( ADatum.CalcFinishPosition(APos, 90, ARadius) );

  // Bottom
  VPoint := ADatum.CalcFinishPosition(APos, 180, ARadius);
  _AddPoint( ADatum.CalcFinishPosition(VPoint, 90, ARadius) );
  _AddPoint(VPoint);
  _AddPoint( ADatum.CalcFinishPosition(VPoint, 270, ARadius) );

  // Left
  _AddPoint( ADatum.CalcFinishPosition(APos, 270, ARadius) );

  Result := CreateLonLatPolygonInternal(VBounds, VAggreagator.MakeStaticAndClear);
end;

function TGeometryLonLatFactory.CreateLonLatPolygonByLine(
  const ADatum: IDatum;
  const ALine: IGeometryLonLatLine;
  const ARadius: Double
): IGeometryLonLatPolygon;
var
  VPolygonGenerator: TLonLatPolygonGenerator;
  VBuilder: IGeometryLonLatPolygonBuilder;
  VCounterContext: TInternalPerformanceCounterContext;
begin
  VCounterContext := FLineToPolyByGenCounter.StartOperation;
  try
    VPolygonGenerator := TLonLatPolygonGenerator.Create;
    try
      VBuilder := MakePolygonBuilder;
      Result := VPolygonGenerator.Generate(VBuilder, ADatum, ALine, ARadius);
    finally
      VPolygonGenerator.Free;
    end;
  finally
    FLineToPolyByGenCounter.FinishOperation(VCounterContext);
  end;
end;

function TGeometryLonLatFactory.CreateLonLatPolygonInternal(
  const ARect: TDoubleRect;
  const APoints: IDoublePoints
): IGeometryLonLatSinglePolygon;
var
  VHash: THashValue;
  VRect: ILonLatRect;
begin
  Result := nil;
  if Assigned(APoints) then begin
    if APoints.Count > 1 then begin
      VRect := TLonLatRect.Create(ARect);
    end else begin
      VRect := TLonLatRectByPoint.Create(ARect.TopLeft);
    end;
    VHash := FHashFunction.CalcHashByBuffer(APoints.Points, APoints.Count * SizeOf(TDoublePoint));
    Result := TGeometryLonLatSinglePolygon.Create(VRect, VHash, APoints);
  end;
end;

function TGeometryLonLatFactory.CreateLonLatLine(
  const APoints: PDoublePointArray;
  ACount: Integer
): IGeometryLonLatLine;
var
  i: Integer;
  VStart: PDoublePointArray;
  VLineLen: Integer;
  VPoint: TDoublePoint;
  VPoints: IDoublePoints;
  VLineBounds: TDoubleRect;
  VBuilder: IGeometryLonLatLineBuilder;
begin
  VBuilder := MakeLineBuilder;
  VStart := APoints;
  VLineLen := 0;
  for i := 0 to ACount - 1 do begin
    VPoint := APoints[i];
    if PointIsEmpty(VPoint) then begin
      if VLineLen > 0 then begin
        VPoints := TDoublePoints.Create(VStart, VLineLen);
        VBuilder.AddLine(VLineBounds, VPoints);
        VLineLen := 0;
      end;
    end else begin
      if VLineLen = 0 then begin
        VStart := @APoints[i];
        VLineBounds.TopLeft := VPoint;
        VLineBounds.BottomRight := VPoint;
      end else begin
        UpdateLonLatMBRByPoint(VLineBounds, VPoint);
      end;
      Inc(VLineLen);
    end;
  end;
  if VLineLen > 0 then begin
    VPoints := TDoublePoints.Create(VStart, VLineLen);
    VBuilder.AddLine(VLineBounds, VPoints);
  end;
  Result := VBuilder.MakeStaticAndClear;
end;

function TGeometryLonLatFactory.CreateLonLatLineByEnum(
  const AEnum: IEnumLonLatPoint;
  const ATemp: IDoublePointsAggregator
): IGeometryLonLatLine;
var
  VPoint: TDoublePoint;
  VTemp: IDoublePointsAggregator;
  VLineBounds: TDoubleRect;
  VBuilder: IGeometryLonLatLineBuilder;
begin
  VBuilder := MakeLineBuilder;
  VTemp := ATemp;
  if VTemp = nil then begin
    VTemp := TDoublePointsAggregator.Create;
  end;
  VTemp.Clear;
  while AEnum.Next(VPoint) do begin
    if PointIsEmpty(VPoint) then begin
      if VTemp.Count > 0 then begin
        VBuilder.AddLine(VLineBounds, VTemp.MakeStaticAndClear);
      end;
    end else begin
      if VTemp.Count = 0 then begin
        VLineBounds.TopLeft := VPoint;
        VLineBounds.BottomRight := VPoint;
      end else begin
        UpdateLonLatMBRByPoint(VLineBounds, VPoint);
      end;
      VTemp.Add(VPoint);
    end;
  end;
  if VTemp.Count > 0 then begin
    VBuilder.AddLine(VLineBounds, VTemp.MakeStaticAndClear);
  end;
  Result := VBuilder.MakeStaticAndClear;
end;

function TGeometryLonLatFactory.CreateLonLatMultiPoint(
  const APoints: PDoublePointArray;
  ACount: Integer
): IGeometryLonLatMultiPoint;
var
  VHash: THashValue;
  VBounds: TDoubleRect;
  VRect: ILonLatRect;
  VPoints: IDoublePoints;
begin
  Assert(Assigned(APoints));
  Assert(ACount > 0);
  Result := nil;
  if Assigned(APoints) then begin
    if ACount > 0 then begin
      VBounds := LonLatMBRByPoints(APoints, ACount);
      VHash := FHashFunction.CalcHashByBuffer(APoints, ACount * SizeOf(TDoublePoint));
      VRect := TLonLatRect.Create(VBounds);
      VPoints := TDoublePoints.Create(APoints, ACount);
      Result := TGeometryLonLatMultiPoint.Create(VRect, VHash, VPoints);
    end;
  end;
end;

function TGeometryLonLatFactory.CreateLonLatPoint(
  const APoint: TDoublePoint
): IGeometryLonLatPoint;
var
  VHash: THashValue;
  VRect: ILonLatRect;
begin
  VHash := FHashFunction.CalcHashByDoublePoint(APoint);
  VRect := TLonLatRectByPoint.Create(APoint);
  Result := TGeometryLonLatPoint.Create(VHash, VRect);
end;

function TGeometryLonLatFactory.CreateLonLatPolygon(
  const APoints: PDoublePointArray;
  ACount: Integer
): IGeometryLonLatPolygon;
var
  i: Integer;
  VStart: PDoublePointArray;
  VLineLen: Integer;
  VPoint: TDoublePoint;
  VPoints: IDoublePoints;
  VLineBounds: TDoubleRect;
  VBuilder: IGeometryLonLatPolygonBuilder;
begin
  VStart := APoints;
  VLineLen := 0;
  VBuilder := MakePolygonBuilder;
  for i := 0 to ACount - 1 do begin
    VPoint := APoints[i];
    if PointIsEmpty(VPoint) then begin
      if VLineLen > 0 then begin
        VPoints := TDoublePoints.Create(VStart, VLineLen);
        VBuilder.AddOuter(VLineBounds, VPoints);
        VLineLen := 0;
      end;
    end else begin
      if VLineLen = 0 then begin
        VStart := @APoints[i];
        VLineBounds.TopLeft := VPoint;
        VLineBounds.BottomRight := VPoint;
      end else begin
        UpdateLonLatMBRByPoint(VLineBounds, VPoint);
      end;
      Inc(VLineLen);
    end;
  end;
  if VLineLen > 0 then begin
    VPoints := TDoublePoints.Create(VStart, VLineLen);
    VBuilder.AddOuter(VLineBounds, VPoints);
  end;
  Result := VBuilder.MakeStaticAndClear;
end;

procedure TGeometryLonLatFactory.AddPolygonsBySingleLine(
  const ASource: IGeometryLonLatSingleLine;
  const AFilter: ILonLatPointFilter;
  const ABuilder: IGeometryLonLatPolygonBuilder;
  const ATemp: IDoublePointsAggregator
);
var
  VEnum: IEnumLonLatPoint;
  VPoint: TDoublePoint;
  VPoints: IDoublePoints;
  VLineBounds: TDoubleRect;
begin
  VEnum := ASource.GetEnum;
  VEnum := AFilter.CreateFilteredEnum(VEnum);
  while VEnum.Next(VPoint) do begin
    if PointIsEmpty(VPoint) then begin
      if ATemp.Count > 0 then begin
        VPoints := ATemp.MakeStaticAndClear;
        ABuilder.AddOuter(VLineBounds, VPoints);
      end;
    end else begin
      if ATemp.Count = 0 then begin
        VLineBounds.TopLeft := VPoint;
        VLineBounds.BottomRight := VPoint;
      end else begin
        UpdateLonLatMBRByPoint(VLineBounds, VPoint);
      end;
      ATemp.Add(VPoint);
    end;
  end;
  if ATemp.Count > 0 then begin
    VPoints := ATemp.MakeStaticAndClear;
    ABuilder.AddOuter(VLineBounds, VPoints);
  end;
end;

function TGeometryLonLatFactory.CreateLonLatPolygonByLonLatPathAndFilter(
  const ASource: IGeometryLonLatLine;
  const AFilter: ILonLatPointFilter
): IGeometryLonLatPolygon;
var
  I: Integer;
  VTemp: IDoublePointsAggregator;
  VBuilder: IGeometryLonLatPolygonBuilder;
  VLineSingle: IGeometryLonLatSingleLine;
  VLineMulti: IGeometryLonLatMultiLine;
  VCounterContext: TInternalPerformanceCounterContext;
begin
  VCounterContext := FLineToPolyByFilterCounter.StartOperation;
  try
    VBuilder := MakePolygonBuilder;
    VTemp := TDoublePointsAggregator.Create;
    if Supports(ASource, IGeometryLonLatSingleLine, VLineSingle) then begin
      AddPolygonsBySingleLine(VLineSingle, AFilter, VBuilder, VTemp);
    end else if Supports(ASource, IGeometryLonLatMultiLine, VLineMulti) then begin
      for I := 0 to VLineMulti.Count - 1 do begin
        VLineSingle := VLineMulti.Item[I];
        AddPolygonsBySingleLine(VLineSingle, AFilter, VBuilder, VTemp);
      end;
    end;
    Result := VBuilder.MakeStaticAndClear;
  finally
    FLineToPolyByFilterCounter.FinishOperation(VCounterContext);
  end;
end;

function TGeometryLonLatFactory.CreateLonLatPolygonByRect(
  const ARect: TDoubleRect
): IGeometryLonLatSinglePolygon;
var
  VPointsArray: array [0..4] of TDoublePoint;
  VPoints: IDoublePoints;
begin
  VPointsArray[0] := ARect.TopLeft;
  VPointsArray[1].X := ARect.Right;
  VPointsArray[1].Y := ARect.Top;
  VPointsArray[2] := ARect.BottomRight;
  VPointsArray[3].X := ARect.Left;
  VPointsArray[3].Y := ARect.Bottom;
  VPoints := TDoublePoints.Create(@VPointsArray[0], 4);
  Result := CreateLonLatPolygonInternal(ARect, VPoints);
end;

function TGeometryLonLatFactory.MakeLineBuilder: IGeometryLonLatLineBuilder;
begin
  Result := TGeometryLonLatLineBuilder.Create(FHashFunction);
end;

function TGeometryLonLatFactory.MakePolygonBuilder: IGeometryLonLatPolygonBuilder;
begin
  Result := TGeometryLonLatPolygonBuilder.Create(FHashFunction);
end;

end.

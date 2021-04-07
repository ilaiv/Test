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

unit u_EnumDoublePointClipInternal;

interface

uses
  t_GeoTypes,
  i_EnumDoublePoint,
  u_BaseInterfacedObject;

type
  TEnumDoublePointClipByLineAbstract = class(TBaseInterfacedObject, IEnumDoublePoint, IEnumProjectedPoint, IEnumLocalPoint)
  private
    FSourceEnum: IEnumDoublePoint;
    FFinished: Boolean;
    FPrevPoint: TDoublePoint;
    FPrevPointCode: Byte;
    FPreparedPoint: TDoublePoint;
    FPreparedPointExists: Boolean;
  private
    function Next(out APoint: TDoublePoint): Boolean;
  protected
    function GetPointCode(const APoint: TDoublePoint): Byte; virtual; abstract;
    function GetIntersectPoint(const APrevPoint, ACurrPoint: TDoublePoint): TDoublePoint; virtual; abstract;
  public
    constructor Create(
      const ASourceEnum: IEnumDoublePoint
    );
  end;

  TEnumDoublePointClipByVerticalLine = class(TEnumDoublePointClipByLineAbstract)
  private
    FLineX: Double;
  protected
    function GetIntersectPoint(const APrevPoint, ACurrPoint: TDoublePoint): TDoublePoint; override;
    property LineX: Double read FLineX;
  public
    constructor Create(
      const AX: Double;
      const ASourceEnum: IEnumDoublePoint
    );
  end;

  TEnumDoublePointClipByLeftBorder = class(TEnumDoublePointClipByVerticalLine)
  protected
    function GetPointCode(const APoint: TDoublePoint): Byte; override;
  end;

  TEnumDoublePointClipByRightBorder = class(TEnumDoublePointClipByVerticalLine)
  protected
    function GetPointCode(const APoint: TDoublePoint): Byte; override;
  end;

  TEnumDoublePointClipByHorizontalLine = class(TEnumDoublePointClipByLineAbstract)
  private
    FLineY: Double;
  protected
    function GetIntersectPoint(const APrevPoint, ACurrPoint: TDoublePoint): TDoublePoint; override;
    property LineY: Double read FLineY;
  public
    constructor Create(
      const AY: Double;
      const ASourceEnum: IEnumDoublePoint
    );
  end;

  TEnumDoublePointClipByTopBorder = class(TEnumDoublePointClipByHorizontalLine)
  protected
    function GetPointCode(const APoint: TDoublePoint): Byte; override;
  end;

  TEnumDoublePointClipByBottomBorder = class(TEnumDoublePointClipByHorizontalLine)
  protected
    function GetPointCode(const APoint: TDoublePoint): Byte; override;
  end;

implementation

uses
  Math,
  u_GeoFunc;

{ TEnumDoublePointClipByLineAbstract }

constructor TEnumDoublePointClipByLineAbstract.Create(
  const ASourceEnum: IEnumDoublePoint
);
begin
  inherited Create;
  FSourceEnum := ASourceEnum;
  FFinished := False;
  FPrevPointCode := 3;
  FPreparedPointExists := False;
end;

function TEnumDoublePointClipByLineAbstract.Next(
  out APoint: TDoublePoint): Boolean;
var
  VCurrPoint: TDoublePoint;
  VCurrPointCode: Byte;
  VLineCode: Byte;
  VIntersectPoint: TDoublePoint;
begin
  while not FFinished do begin
    if FPreparedPointExists then begin
      APoint := FPreparedPoint;
      FPreparedPointExists := False;
      Break;
    end else begin
      if FSourceEnum.Next(VCurrPoint) then begin
        VCurrPointCode := GetPointCode(VCurrPoint);
        VLineCode := FPrevPointCode * 16 + VCurrPointCode;
        {
        ���      ���� ��� �����
        $00:     ���-��� ���
        $01:     ���-��  ��������
        $02:     ���-��� �����,���
        $03:     ���-��� ��������
        $10:     �� -��� ���
        $11:     �� -��  ��������
        $12:     �� -��� ��������
        $13:     �� -��� ��������
        $20:     ���-��� ���������
        $21:     ���-��  ��������
        $22:     ���-��� ��������
        $23:     ���-��� ��������
        $30:     ���-��� ���
        $31:     ���-�� ��������
        $32:     ���-��� ��������
        $33:     ���-��� ���
        }
        case VLineCode of
          $01, $11, $12, $21, $22, $03, $13, $23, $31, $32: begin
            APoint := VCurrPoint;
            FPrevPoint := VCurrPoint;
            FPrevPointCode := VCurrPointCode;
            Break;
          end;
          $02: begin
            VIntersectPoint := GetIntersectPoint(FPrevPoint, VCurrPoint);
            APoint := VIntersectPoint;
            FPreparedPoint := VCurrPoint;
            FPreparedPointExists := True;
            FPrevPoint := VCurrPoint;
            FPrevPointCode := VCurrPointCode;
            Break;
          end;
          $20: begin
            VIntersectPoint := GetIntersectPoint(FPrevPoint, VCurrPoint);
            APoint := VIntersectPoint;
            FPrevPoint := VCurrPoint;
            FPrevPointCode := VCurrPointCode;
            Break;
          end;
          $00, $10, $30: begin
            FPrevPoint := VCurrPoint;
            FPrevPointCode := VCurrPointCode;
          end;
        end;
      end else begin
        APoint := CEmptyDoublePoint;
        FFinished := True;
        Break;
      end;
    end;
  end;
  Result := not FFinished;
end;

{ TEnumDoublePointClipByVerticalLine }

constructor TEnumDoublePointClipByVerticalLine.Create(
  const AX: Double;
  const ASourceEnum: IEnumDoublePoint
);
begin
  inherited Create(ASourceEnum);
  FLineX := AX;
end;

function TEnumDoublePointClipByVerticalLine.GetIntersectPoint(
  const APrevPoint, ACurrPoint: TDoublePoint
): TDoublePoint;
begin
  Result.X := LineX;
  Result.Y :=
    (ACurrPoint.Y - APrevPoint.Y) / (ACurrPoint.X - APrevPoint.X) *
    (LineX - APrevPoint.X) + APrevPoint.Y;
end;

{ TEnumDoublePointClipByLeftBorder }

function TEnumDoublePointClipByLeftBorder.GetPointCode(
  const APoint: TDoublePoint
): Byte;
begin
  if PointIsEmpty(APoint) then begin
    Result := 3;
  end else if APoint.X < LineX then begin
    Result := 0;
  end else if APoint.X > LineX then begin
    Result := 2;
  end else begin
    Result := 1;
  end;
end;

{ TEnumDoublePointClipByRightBorder }

function TEnumDoublePointClipByRightBorder.GetPointCode(
  const APoint: TDoublePoint
): Byte;
begin
  if PointIsEmpty(APoint) then begin
    Result := 3;
  end else if APoint.X > LineX then begin
    Result := 0;
  end else if APoint.X < LineX then begin
    Result := 2;
  end else begin
    Result := 1;
  end;
end;

{ TEnumDoublePointClipByHorizontalLine }

constructor TEnumDoublePointClipByHorizontalLine.Create(
  const AY: Double;
  const ASourceEnum: IEnumDoublePoint
);
begin
  inherited Create(ASourceEnum);
  FLineY := AY;
end;

function TEnumDoublePointClipByHorizontalLine.GetIntersectPoint(
  const APrevPoint, ACurrPoint: TDoublePoint
): TDoublePoint;
begin
  Result.X :=
    (ACurrPoint.X - APrevPoint.X) / (ACurrPoint.Y - APrevPoint.Y) *
    (LineY - APrevPoint.Y) + APrevPoint.X;
  Result.Y := LineY;
end;

{ TEnumDoublePointClipByTopBorder }

function TEnumDoublePointClipByTopBorder.GetPointCode(
  const APoint: TDoublePoint
): Byte;
begin
  if PointIsEmpty(APoint) then begin
    Result := 3;
  end else if APoint.Y < LineY then begin
    Result := 0;
  end else if APoint.Y > LineY then begin
    Result := 2;
  end else begin
    Result := 1;
  end;
end;

{ TEnumDoublePointClipByBottomBorder }

function TEnumDoublePointClipByBottomBorder.GetPointCode(
  const APoint: TDoublePoint
): Byte;
begin
  if PointIsEmpty(APoint) then begin
    Result := 3;
  end else if APoint.Y > LineY then begin
    Result := 0;
  end else if APoint.Y < LineY then begin
    Result := 2;
  end else begin
    Result := 1;
  end;
end;

end.

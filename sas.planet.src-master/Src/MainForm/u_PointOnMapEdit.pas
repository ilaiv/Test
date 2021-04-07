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

unit u_PointOnMapEdit;

interface

uses
  SysUtils,
  t_GeoTypes,
  i_PointOnMapEdit,
  u_ChangeableBase;

type
  TPointOnMapEdit = class(TChangeableWithSimpleLockBase, IPointOnMapEdit)
  private
    FPoint: TDoublePoint;
  private
    function GetPoint: TDoublePoint;
    procedure SetPoint(const AValue: TDoublePoint);

    procedure Clear;
  public
    constructor Create;
  end;

implementation

uses
  Math,
  u_GeoFunc;

{ TPointOnMapEdit }

constructor TPointOnMapEdit.Create;
begin
  inherited Create;
  FPoint := CEmptyDoublePoint;
end;

procedure TPointOnMapEdit.Clear;
begin
  SetPoint(CEmptyDoublePoint);
end;

function TPointOnMapEdit.GetPoint: TDoublePoint;
begin
  CS.BeginRead;
  try
    Result := FPoint;
  finally
    CS.EndRead;
  end;
end;

procedure TPointOnMapEdit.SetPoint(const AValue: TDoublePoint);
var
  VNeedNotify: Boolean;
begin
  VNeedNotify := False;
  CS.BeginWrite;
  try
    if not DoublePointsEqual(AValue, FPoint) then begin
      FPoint := AValue;
      VNeedNotify := True;
    end;
  finally
    CS.EndWrite;
  end;
  if VNeedNotify then begin
    DoChangeNotify;
  end;
end;

end.

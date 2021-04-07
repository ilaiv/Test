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

unit u_LastSelectionInfo;

interface

uses
  i_LastSelectionInfo,
  i_GeometryLonLat,
  u_ChangeableBase;

type
  TLastSelectionInfo = class(TChangeableWithSimpleLockBase, ILastSelectionInfo)
  private
    // ������� ���������� ��������� ��� ��������� � ��������.
    FPolygon: IGeometryLonLatPolygon;
    // �������, �� ������� ���� ��������� ���������
    FZoom: Byte;
  private
    function GetZoom: Byte;
    function GetPolygon: IGeometryLonLatPolygon;
    procedure SetPolygon(
      const ALonLatPolygon: IGeometryLonLatPolygon;
      AZoom: Byte
    );
  public
    constructor Create;
  end;

implementation

{ TLastSelectionInfo }

constructor TLastSelectionInfo.Create;
begin
  inherited Create;
  FPolygon := nil;
  FZoom := 0;
end;

function TLastSelectionInfo.GetPolygon: IGeometryLonLatPolygon;
begin
  CS.BeginRead;
  try
    Result := FPolygon;
  finally
    CS.EndRead;
  end;
end;

function TLastSelectionInfo.GetZoom: Byte;
begin
  CS.BeginRead;
  try
    Result := FZoom;
  finally
    CS.EndRead;
  end;
end;

procedure TLastSelectionInfo.SetPolygon(
  const ALonLatPolygon: IGeometryLonLatPolygon;
  AZoom: Byte
);
begin
  CS.BeginWrite;
  try
    FPolygon := ALonLatPolygon;
    FZoom := AZoom;
  finally
    CS.EndWrite;
  end;
  DoChangeNotify;
end;

end.

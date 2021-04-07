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

unit i_CoordConverterSimple;

interface

uses
  Types,
  t_GeoTypes;

type
  ICoordConverterSimple = interface
    ['{3EE2987F-7681-425A-8EFE-B676C506CDD4}']

    // ����������� ������� ����� �� �������� ���� � ������������ ���������� ��� �������� ������ ����
    function Pos2LonLat(
      const XY: TPoint;
      AZoom: byte
    ): TDoublePoint; stdcall;
    // ����������� ������������� ���������� � ������� ����� �� �������� ���� ������������ ������ ����������
    function LonLat2Pos(
      const Ll: TDoublePoint;
      AZoom: byte
    ): Tpoint; stdcall;

    // ����������� ����������
    function LonLat2Metr(const Ll: TDoublePoint): TDoublePoint; stdcall;
    function Metr2LonLat(const Mm: TDoublePoint): TDoublePoint; stdcall;

    // ���������� ���������� ������ � �������� ����
    function TilesAtZoom(const AZoom: byte): Longint; stdcall;
    // ���������� ����� ���������� �������� �� �������� ����
    function PixelsAtZoom(const AZoom: byte): Longint; stdcall;

    // ����������� ������� ����� ��������� ���� � ���������� ������� ��� ������ �������� ����
    function TilePos2PixelPos(
      const XY: TPoint;
      const AZoom: byte
    ): TPoint; stdcall;
    // ����������� ������� ����� ��������� ���� � ������ �������� ��� ����� �� �������� ����
    function TilePos2PixelRect(
      const XY: TPoint;
      const AZoom: byte
    ): TRect; stdcall;
  end;

implementation

end.

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

unit i_TileIterator;

interface

uses
  Types,
  i_TileRect;

type
  ITileIterator = interface
    ['{E563544C-4A6E-4A8C-B5C9-81190F1416AF}']
    function Next(out ATile: TPoint): Boolean;
    procedure Reset;

    function GetTilesTotal: Int64;
    property TilesTotal: Int64 read GetTilesTotal;

    function GetTilesRect: ITileRect;
    property TilesRect: ITileRect read GetTilesRect;
  end;

  ITileIteratorByRows = interface(ITileIterator)
    ['{E030EE2E-8AC5-4DF7-AAF5-0EB23A4CD589}']
  end;

  ITileIteratorByCols = interface(ITileIterator)
    ['{947F77CB-2368-4734-95D1-FC1D65487BD9}']
  end;

implementation

end.

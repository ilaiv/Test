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

unit i_PredicateByTileInfo;

interface

uses
  Types,
  i_TileInfoBasic;

type
  IPredicateByTileInfo = interface
    ['{9A3F53A1-7EBB-47D4-B081-064A093EBA0D}']
    function GetUseTileData: Boolean;
    property UseTileData: Boolean read GetUseTileData;

    function Check(
      const ATileInfo: ITileInfoBasic;
      AZoom: Byte;
      const ATile: TPoint
    ): Boolean; overload;
    function Check(const ATileInfo: TTileInfo): Boolean; overload;
  end;

implementation

end.

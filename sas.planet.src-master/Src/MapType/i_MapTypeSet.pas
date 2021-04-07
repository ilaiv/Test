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

unit i_MapTypeSet;

interface

uses
  t_Hash,
  i_MapType;

type
  IMapTypeSet = interface
    ['{45EF5080-01DC-4FE1-92E1-E93574439718}']
    function GetHash: THashValue;
    property Hash: THashValue read GetHash;

    function GetCount: Integer;
    property Count: Integer read GetCount;

    function GetItem(AIndex: Integer): IMapType;
    property Items[AIndex: Integer]: IMapType read GetItem;

    function IsEqual(const AValue: IMapTypeSet): Boolean;
    function IsExists(const AGUID: TGUID): Boolean;
    function GetMapTypeByGUID(const AGUID: TGUID): IMapType;
//    function GetIterator: IEnumGUID;
//    function GetMapTypeIterator: IEnumUnknown;
  end;

implementation

end.

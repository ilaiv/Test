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

unit i_MarkPicture;

interface

uses
  Classes,
  t_Hash,
  i_BinaryData,
  i_BitmapMarker;

type
  IMarkPicture = interface
    ['{4F70C829-D49A-4019-AAF6-3AA9BCD2CCAE}']
    function GetSource: IBinaryData;
    property Source: IBinaryData read GetSource;

    function GetMarker: IBitmapMarker;

    function GetName: string;

    function GetTextAlignment: TAlignment;
    function GetTextVerticalAlignment: TVerticalAlignment;

    function GetHash: THashValue;
    property Hash: THashValue read GetHash;
  end;

  IMarkPictureList = interface
    ['{C080A087-C571-4654-8B3E-63D6E6A5542F}']
    function GetCount: Integer;
    property Count: Integer read GetCount;

    function Get(AIndex: Integer): IMarkPicture;
    function GetName(AIndex: Integer): string;
    function GetIndexByName(const AValue: string): Integer;

    function GetDefaultPicture: IMarkPicture;
    function FindByName(const AValue: string): IMarkPicture;
    function FindByNameOrDefault(const AValue: string): IMarkPicture;
  end;

  IMarkPictureListInternal = interface(IMarkPictureList)
    ['{97E01615-372D-4FCD-A7D8-99272D820D15}']
    procedure LoadList;
  end;

implementation

end.

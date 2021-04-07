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

unit i_TileStorageAbilities;

interface

uses
  t_CommonTypes;

type
  ITileStorageAbilities = interface
    ['{EBB122FB-5382-49CA-A265-3BEA89694B0E}']
    function GetAllowRead: Boolean;
    property AllowRead: Boolean read GetAllowRead;

    function GetAllowScan: Boolean;
    property AllowScan: Boolean read GetAllowScan;

    function GetAllowAdd: Boolean;
    property AllowAdd: Boolean read GetAllowAdd;

    function GetAllowDelete: Boolean;
    property AllowDelete: Boolean read GetAllowDelete;

    function GetAllowReplace: Boolean;
    property AllowReplace: Boolean read GetAllowReplace;

    function IsReadOnly: Boolean;
  end;

type
  TTileStorageTypeClass = (
    tstcInMemory,
    tstcOneFile,
    tstcFolder,
    tstcInSeparateFiles,
    tstcOther
  );

type
  TTileStorageTypeVersionSupport = (
    tstvsVersionIgnored,
    tstvsVersionStored,
    tstvsMultiVersions
  );

type
  ITileStorageTypeAbilities = interface
    ['{EEB09E02-E81A-4566-866F-356008CC808D}']
    function GetStorageClass: TTileStorageTypeClass;
    property StorageClass: TTileStorageTypeClass read GetStorageClass;

    function GetBaseStorageAbilities: ITileStorageAbilities;
    property BaseStorageAbilities: ITileStorageAbilities read GetBaseStorageAbilities;

    function GetVersionSupport: TTileStorageTypeVersionSupport;
    property VersionSupport: TTileStorageTypeVersionSupport read GetVersionSupport;

    function GetSupportDifferentContentTypes: Boolean;
    property SupportDifferentContentTypes: Boolean read GetSupportDifferentContentTypes;

    function GetPathStringSupport: TStringTypeSupport;
    property PathStringSupport: TStringTypeSupport read GetPathStringSupport;
  end;

implementation

end.

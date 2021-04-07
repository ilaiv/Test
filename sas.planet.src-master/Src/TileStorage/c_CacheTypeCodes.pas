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

unit c_CacheTypeCodes;

interface

const
  c_File_Cache_Id_DEFAULT = 0; // subst only

  // File system based caches
  c_File_Cache_Id_GMV = 1;  // old (GoogleMV)
  c_File_Cache_Id_SAS = 2;  // new
  c_File_Cache_Id_ES = 3; // EarthSlicer
  c_File_Cache_Id_GM = 4; // GlobalMapper
  c_File_Cache_Id_GM_Aux = 41; // auxillary
  c_File_Cache_Id_GM_Bing = 42; // "Bing Maps (Virtual Earth) Tiles" <ZOOM>\<Y>\<X>.<ext>
  c_File_Cache_Id_MOBAC = 43; // "Mobile Atlas Creator" <ZOOM>\<X>\<Y>.<ext>
  c_File_Cache_Id_OsmAnd = 44; // OsmAnd+ <ZOOM>\<X>\<Y>.<ext>.tile
  c_File_Cache_Id_TMS = 45; // "TileMapService" <ZOOM>\<X>\<Yb>.<ext> (<Yb> - starts from bottom)

  // other
  c_File_Cache_Id_GE = 5;  // GE imagery cache direct access
  c_File_Cache_Id_GEt = 51;  // GE terrain cache direct access
  c_File_Cache_Id_BDB = 6;
  c_File_Cache_Id_BDB_Versioned = 61;
  c_File_Cache_Id_DBMS = 7;
  c_File_Cache_Id_SQLite = 71;
  c_File_Cache_Id_GC = 8;  // GeoCacher.LOCAL direct access
  c_File_Cache_Id_RAM = 9; // only in-memory cache

  c_File_Cache_Default_GMV  = 'cache_old';     // for 1
  c_File_Cache_Default_SAS  = 'cache';         // for 2
  c_File_Cache_Default_ES   = 'cache_es';      // for 3
  c_File_Cache_Default_GM   = 'cache_gmt';     // for 4, 41, 42
  c_File_Cache_Default_MA   = 'cache_ma';      // for 43
  c_File_Cache_Default_TMS  = 'cache_tms';     // for 45
  c_File_Cache_Default_GE   = 'cache_ge';      // for 5
  c_File_Cache_Default_BDB  = 'cache_db';      // for 6
  c_File_Cache_Default_BDBv = 'cache_dbv';     // for 61
  c_File_Cache_Default_DBMS = 'SASGIS_DBMS\$'; // for 7
  c_File_Cache_Default_SQLite = 'cache_sqlite'; // for 71
  c_File_Cache_Default_GC   = 'cache_gc';      // for 8
  c_File_Cache_Default_RAM  = '';              // for 9

implementation

end.

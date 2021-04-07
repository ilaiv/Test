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

unit u_SimpleTileStorageConfigStatic;

interface

uses
  i_TileStorageAbilities,
  i_SimpleTileStorageConfig,
  u_BaseInterfacedObject;

type
  TSimpleTileStorageConfigStatic = class(TBaseInterfacedObject, ISimpleTileStorageConfigStatic)
  private
    FCacheTypeCode: Integer;
    FNameInCache: string;
    FMainContentType: AnsiString;
    FTileFileExt: AnsiString;
    FAbilities: ITileStorageAbilities;
    FUseMemCache: Boolean;
    FMemCacheCapacity: Integer;
    FMemCacheTTL: Cardinal;
    FMemCacheClearStrategy: Integer;
  private
    function GetCacheTypeCode: Integer;
    function GetNameInCache: string;
    function GetMainContentType: AnsiString;
    function GetTileFileExt: AnsiString;
    function GetAbilities: ITileStorageAbilities;
    function GetUseMemCache: Boolean;
    function GetMemCacheCapacity: Integer;
    function GetMemCacheTTL: Cardinal;
    function GetMemCacheClearStrategy: Integer;
  public
    constructor Create(
      const ACacheTypeCode: Integer;
      const ANameInCache: string;
      const AMainContentType: AnsiString;
      const ATileFileExt: AnsiString;
      const AAbilities: ITileStorageAbilities;
      const AUseMemCache: Boolean;
      const AMemCacheCapacity: Integer;
      const AMemCacheTTL: Cardinal;
      const AMemCacheClearStrategy: Integer
    );
  end;

implementation

{ TSimpleTileStorageConfigStatic }

constructor TSimpleTileStorageConfigStatic.Create(
  const ACacheTypeCode: Integer;
  const ANameInCache: string;
  const AMainContentType: AnsiString;
  const ATileFileExt: AnsiString;
  const AAbilities: ITileStorageAbilities;
  const AUseMemCache: Boolean;
  const AMemCacheCapacity: Integer;
  const AMemCacheTTL: Cardinal;
  const AMemCacheClearStrategy: Integer
);
begin
  inherited Create;
  FCacheTypeCode := ACacheTypeCode;
  FNameInCache := ANameInCache;
  FMainContentType := AMainContentType;
  FTileFileExt := ATileFileExt;
  FAbilities := AAbilities;
  FUseMemCache := AUseMemCache;
  FMemCacheCapacity := AMemCacheCapacity;
  FMemCacheTTL := AMemCacheTTL;
  FMemCacheClearStrategy := AMemCacheClearStrategy;
end;

function TSimpleTileStorageConfigStatic.GetAbilities: ITileStorageAbilities;
begin
  Result := FAbilities;
end;

function TSimpleTileStorageConfigStatic.GetCacheTypeCode: Integer;
begin
  Result := FCacheTypeCode;
end;

function TSimpleTileStorageConfigStatic.GetNameInCache: string;
begin
  Result := FNameInCache;
end;

function TSimpleTileStorageConfigStatic.GetTileFileExt: AnsiString;
begin
  Result := FTileFileExt;
end;

function TSimpleTileStorageConfigStatic.GetUseMemCache: Boolean;
begin
  Result := FUseMemCache;
end;

function TSimpleTileStorageConfigStatic.GetMainContentType: AnsiString;
begin
  Result := FMainContentType;
end;

function TSimpleTileStorageConfigStatic.GetMemCacheCapacity: Integer;
begin
  Result := FMemCacheCapacity;
end;

function TSimpleTileStorageConfigStatic.GetMemCacheTTL: Cardinal;
begin
  Result := FMemCacheTTL;
end;

function TSimpleTileStorageConfigStatic.GetMemCacheClearStrategy: Integer;
begin
  Result := FMemCacheClearStrategy;
end;

end.

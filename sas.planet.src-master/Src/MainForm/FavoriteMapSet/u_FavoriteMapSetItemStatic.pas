{******************************************************************************}
{* SAS.Planet (SAS.�������)                                                   *}
{* Copyright (C) 2007-2015, SAS.Planet development team.                      *}
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

unit u_FavoriteMapSetItemStatic;

interface

uses
  Classes,
  t_GeoTypes,
  i_GUIDListStatic,
  i_FavoriteMapSetItemStatic,
  u_BaseInterfacedObject;

type
  TFavoriteMapSetItemStatic = class(TBaseInterfacedObject, IFavoriteMapSetItemStatic)
  private
    FID: TGUID;
    FBaseMap: TGUID;
    FLayers: IGUIDSetStatic;
    FZoom: Integer;
    FLonLat: TDoublePoint;
    FName: string;
    FHotKey: TShortCut;
    FMergeLayers: Boolean;
  private
    { IFavoriteMapSetItemStatic }
    function GetID: TGUID;
    function GetBaseMap: TGUID;
    function GetLayers: IGUIDSetStatic;
    function GetMergeLayers: Boolean;
    function GetZoom: Integer;
    function GetLonLat: TDoublePoint;
    function GetName: string;
    function GetHotKey: TShortCut;
  public
    constructor Create(
      const AID: TGUID;
      const ABaseMap: TGUID;
      const ALayers: IGUIDSetStatic;
      const AMergeLayers: Boolean;
      const AZoom: Integer;
      const ALonLat: TDoublePoint;
      const AName: string;
      const AHotKey: TShortCut
    );
  end;

implementation

{ TFavoriteMapSetItemStatic }

constructor TFavoriteMapSetItemStatic.Create(
  const AID: TGUID;
  const ABaseMap: TGUID;
  const ALayers: IGUIDSetStatic;
  const AMergeLayers: Boolean;
  const AZoom: Integer;
  const ALonLat: TDoublePoint;
  const AName: string;
  const AHotKey: TShortCut
);
begin
  inherited Create;
  FID := AID;
  FBaseMap := ABaseMap;
  FLayers := ALayers;
  FMergeLayers := AMergeLayers;
  FZoom := AZoom;
  FLonLat := ALonLat;
  FName := AName;
  FHotKey := AHotKey;
end;

function TFavoriteMapSetItemStatic.GetID: TGUID;
begin
  Result := FID;
end;

function TFavoriteMapSetItemStatic.GetBaseMap: TGUID;
begin
  Result := FBaseMap;
end;

function TFavoriteMapSetItemStatic.GetLayers: IGUIDSetStatic;
begin
  Result := FLayers;
end;

function TFavoriteMapSetItemStatic.GetMergeLayers: Boolean;
begin
  Result := FMergeLayers;
end;

function TFavoriteMapSetItemStatic.GetZoom: Integer;
begin
  Result := FZoom;
end;

function TFavoriteMapSetItemStatic.GetLonLat: TDoublePoint;
begin
  Result := FLonLat;
end;

function TFavoriteMapSetItemStatic.GetName: string;
begin
  Result := FName;
end;

function TFavoriteMapSetItemStatic.GetHotKey: TShortCut;
begin
  Result := FHotKey;
end;

end.

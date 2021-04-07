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

unit u_GeoCoderListEntity;

interface

uses
  i_GeoCoder,
  i_GeoCoderList,
  u_BaseInterfacedObject;

type
  TGeoCoderListEntity = class(TBaseInterfacedObject, IGeoCoderListEntity)
  private
    FGUID: TGUID;
    FCaption: string;
    FGeoCoder: IGeoCoder;
  private
    function GetGUID: TGUID;
    function GetCaption: string;
    function GetGeoCoder: IGeoCoder;
  public
    constructor Create(
      const AGUID: TGUID;
      const ACaption: string;
      const AGeoCoder: IGeoCoder
    );
  end;

implementation

{ TGeoCoderListEntity }

constructor TGeoCoderListEntity.Create(
  const AGUID: TGUID;
  const ACaption: string;
  const AGeoCoder: IGeoCoder
);
begin
  inherited Create;
  FGUID := AGUID;
  FCaption := ACaption;
  FGeoCoder := AGeoCoder;
end;

function TGeoCoderListEntity.GetCaption: string;
begin
  Result := FCaption;
end;

function TGeoCoderListEntity.GetGeoCoder: IGeoCoder;
begin
  Result := FGeoCoder;
end;

function TGeoCoderListEntity.GetGUID: TGUID;
begin
  Result := FGUID;
end;

end.

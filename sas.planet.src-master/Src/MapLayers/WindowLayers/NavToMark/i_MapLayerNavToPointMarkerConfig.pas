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

unit i_MapLayerNavToPointMarkerConfig;

interface

uses
  i_ConfigDataElement,
  i_MarkerSimpleConfig;

type
  IMapLayerNavToPointMarkerConfig = interface(IConfigDataElement)
    ['{7477526C-A086-41F6-9853-6992035DD10E}']
    function GetCrossDistInPixels: Double;
    procedure SetCrossDistInPixels(AValue: Double);
    property CrossDistInPixels: Double read GetCrossDistInPixels write SetCrossDistInPixels;

    function GetArrowMarkerConfig: IMarkerSimpleConfig;
    property ArrowMarkerConfig: IMarkerSimpleConfig read GetArrowMarkerConfig;

    function GetReachedMarkerConfig: IMarkerSimpleConfig;
    property ReachedMarkerConfig: IMarkerSimpleConfig read GetReachedMarkerConfig;
  end;

implementation

end.

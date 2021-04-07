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

unit i_GPSPositionFactory;

interface

uses
  vsagps_public_base,
  vsagps_public_position,
  i_GPS;

type
  IGPSPositionFactory = interface
    ['{542F6E48-EC4E-4C8D-9A53-8B392B0E8EA6}']
    function BuildSatelliteInfo(
      const AData: PSingleSatFixibilityData;
      const ASky: PSingleSatSkyData
    ): IGPSSatelliteInfo;

    function BuildSatellitesInViewEmpty: IGPSSatellitesInView;

    function BuildSatellitesInView(
      const AItemsGP, AItemsGL: IGPSSatelliteInfoList
    ): IGPSSatellitesInView;

    function BuildPositionEmpty: IGPSPosition;
    function BuildPosition(
      const FSingleGPSData: PSingleGPSData;
      const ASatellites: IGPSSatellitesInView
    ): IGPSPosition;
  end;

implementation

end.

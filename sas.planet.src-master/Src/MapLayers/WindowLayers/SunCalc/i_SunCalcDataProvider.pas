{******************************************************************************}
{* SAS.Planet (SAS.�������)                                                   *}
{* Copyright (C) 2007-2019, SAS.Planet development team.                      *}
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

unit i_SunCalcDataProvider;

interface

uses
  t_GeoTypes,
  t_SunCalcDataProvider,
  i_Changeable,
  i_MarkerDrawable;

type
  ISunCalcDataProvider = interface
    ['{448C3FEE-A49C-41E4-9080-5B0389181AB3}']
    function GetTimes(
      const AStartOfTheDay: TDateTime;
      const AEndOfTheDay: TDateTime;
      const ALonLat: TDoublePoint
    ): TSunCalcProviderTimes;

    function GetPosition(
      const AUtcDate: TDateTime;
      const ALonLat: TDoublePoint
    ): TSunCalcProviderPosition;

    function GetMaxAltitudeDay(
      const AUtcDate: TDateTime;
      const ALonLat: TDoublePoint
    ): TDateTime;

    function GetMinAltitudeDay(
      const AUtcDate: TDateTime;
      const ALonLat: TDoublePoint
    ): TDateTime;

    function GetDayEvents(
      const AParams: TSunCalcParams
    ): TSunCalcDayEvents;

    function GetDayInfo(
      const AStartOfTheDay: TDateTime;
      const AEndOfTheDay: TDateTime;
      const ACurrentTime: TDateTime;
      const ALonLat: TDoublePoint
    ): TSunCalcDayInfo;

    function GetYearEvents(
      const AUtcDate: TDateTime;
      const ALonLat: TDoublePoint
    ): TSunCalcYearEvents;

    function GetYearMarker: IMarkerDrawable;
    property YearMarker: IMarkerDrawable read GetYearMarker;

    function GetDayMarker: IMarkerDrawable;
    property DayMarker: IMarkerDrawable read GetDayMarker;
  end;

  ISunCalcDataProviderChangeable = interface(IChangeable)
    ['{A247F3A2-8B7D-49C2-80F4-7B9504995C11}']
    function GetStatic: ISunCalcDataProvider;
  end;

implementation

end.

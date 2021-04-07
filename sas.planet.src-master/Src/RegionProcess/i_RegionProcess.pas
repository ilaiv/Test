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

unit i_RegionProcess;

interface

uses
  i_GeometryLonLat;

type
  IRegionProcess = interface
    procedure ProcessPolygon(
      const APolygon: IGeometryLonLatPolygon
    );
    procedure ProcessPolygonWithZoom(
      const AZoom: Byte;
      const APolygon: IGeometryLonLatPolygon
    );
  end;

  IRegionProcessFromFile = interface(IRegionProcess)
    ['{8A267DB0-B9EC-4547-8F2A-69177F9C7878}']
    procedure LoadSelFromFile(
      const AFileName: string;
      out APolygon: IGeometryLonLatPolygon
    );
    procedure StartSlsFromFile(
      const AFileName: string;
      const AStartPaused: Boolean
    );
  end;

implementation

end.

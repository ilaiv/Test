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

unit u_ExportTaskAbstract;

interface

uses
  Classes,
  Types,
  i_GeometryLonLat,
  i_TileIteratorFactory,
  i_RegionProcessProgressInfo,
  u_RegionProcessTaskAbstract;

type
  TExportTaskAbstract = class(TRegionProcessTaskAbstract)
  protected
    FZooms: TByteDynArray;
    procedure ProcessRegion; override;
  public
    constructor Create(
      const AProgressInfo: IRegionProcessProgressInfoInternal;
      const APolygon: IGeometryLonLatPolygon;
      const AZooms: TByteDynArray;
      const ATileIteratorFactory: ITileIteratorFactory
    );
  end;

implementation

uses
  SysUtils;

constructor TExportTaskAbstract.Create(
  const AProgressInfo: IRegionProcessProgressInfoInternal;
  const APolygon: IGeometryLonLatPolygon;
  const AZooms: TByteDynArray;
  const ATileIteratorFactory: ITileIteratorFactory
);
var
  I: Integer;
  VZoomSourceCount: Integer;
  VZoomCount: Integer;
  VZoom: Byte;
begin
  inherited Create(
    AProgressInfo,
    APolygon,
    ATileIteratorFactory
  );
  Assert(AZooms <> nil);
  VZoomSourceCount := Length(AZooms);
  Assert(VZoomSourceCount > 0);
  Assert(VZoomSourceCount <= 24);
  if VZoomSourceCount > 24 then begin
    VZoomSourceCount := 24;
  end;
  VZoomCount := 0;
  for I := 0 to VZoomSourceCount - 1 do begin
    VZoom := AZooms[I];
    if VZoom < 24 then begin
      if VZoomCount > 0 then begin
        if FZooms[VZoomCount - 1] < VZoom then begin
          SetLength(FZooms, VZoomCount + 1);
          FZooms[VZoomCount] := VZoom;
          Inc(VZoomCount);
        end;
      end else begin
        SetLength(FZooms, VZoomCount + 1);
        FZooms[VZoomCount] := VZoom;
        Inc(VZoomCount);
      end;
    end;
  end;
end;

procedure TExportTaskAbstract.ProcessRegion;
begin
  inherited;
  if Length(FZooms) <= 0 then begin
    raise Exception.Create('Please select at least one zoom');
  end;
end;

end.

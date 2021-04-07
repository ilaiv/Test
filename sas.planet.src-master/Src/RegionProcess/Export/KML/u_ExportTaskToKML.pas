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

unit u_ExportTaskToKML;

interface

uses
  Types,
  SysUtils,
  Classes,
  t_GeoTypes,
  i_NotifierOperation,
  i_RegionProcessProgressInfo,
  i_TileIteratorFactory,
  i_GeometryLonLat,
  i_MapVersionInfo,
  i_TileStorage,
  u_ExportTaskAbstract;

type
  TExportTaskToKML = class(TExportTaskAbstract)
  private
    FTileStorage: ITileStorage;
    FVersion: IMapVersionInfo;
    FNotSaveNotExists: boolean;
    FPathExport: string;
    FRelativePath: boolean;
    FTilesToProcess: Int64;
    FTilesProcessed: Int64;
    procedure KmlFileWrite(
      AKmlStream: TStream;
      const ATile: TPoint;
      AZoom, level: byte
    );
  protected
    procedure ProcessRegion; override;
  public
    constructor Create(
      const AProgressInfo: IRegionProcessProgressInfoInternal;
      const APath: string;
      const ATileIteratorFactory: ITileIteratorFactory;
      const APolygon: IGeometryLonLatPolygon;
      const AZoomArr: TByteDynArray;
      const ATileStorage: ITileStorage;
      const AVersion: IMapVersionInfo;
      const ANotSaveNotExists: boolean;
      const ARelativePath: boolean
    );
  end;

implementation

uses
  Math,
  i_Projection,
  i_TileInfoBasic,
  i_TileIterator,
  u_TileIteratorByRect,
  u_GeoToStrFunc,
  u_GeoFunc,
  u_ResStrings;

constructor TExportTaskToKML.Create(
  const AProgressInfo: IRegionProcessProgressInfoInternal;
  const APath: string;
  const ATileIteratorFactory: ITileIteratorFactory;
  const APolygon: IGeometryLonLatPolygon;
  const AZoomArr: TByteDynArray;
  const ATileStorage: ITileStorage;
  const AVersion: IMapVersionInfo;
  const ANotSaveNotExists: boolean;
  const ARelativePath: boolean
);
begin
  inherited Create(
    AProgressInfo,
    APolygon,
    AZoomArr,
    ATileIteratorFactory
  );
  FPathExport := APath;
  FNotSaveNotExists := ANotSaveNotExists;
  FRelativePath := ARelativePath;
  FTileStorage := ATileStorage;
  FVersion := AVersion;
end;

procedure TExportTaskToKML.KmlFileWrite(
  AKmlStream: TStream;
  const ATile: TPoint;
  AZoom, level: byte
);
var
  VZoom: Byte;
  VIterator: TTileIteratorByRectRecord;
  savepath, north, south, east, west: string;
  VText: UTF8String;
  VTileRect: TRect;
  VTile: TPoint;
  VExtRect: TDoubleRect;
  VTileInfo: ITileInfoBasic;
begin
  //TODO: ����� ������ �� ������ ����� ����� ����� � ���� ������
  if FNotSaveNotExists then begin
    VTileInfo := FTileStorage.GetTileInfo(ATile, AZoom, FVersion, gtimAsIs);
    if not Assigned(VTileInfo) or not VTileInfo.GetIsExists then begin
      exit;
    end;
  end;
  savepath := FTileStorage.GetTileFileName(ATile, AZoom, FVersion);
  if FRelativePath then begin
    savepath := ExtractRelativePath(ExtractFilePath(FPathExport), savepath);
  end;
  VExtRect := FTileStorage.ProjectionSet.Zooms[AZoom].TilePos2LonLatRect(ATile);

  north := R2StrPoint(VExtRect.Top);
  south := R2StrPoint(VExtRect.Bottom);
  east := R2StrPoint(VExtRect.Right);
  west := R2StrPoint(VExtRect.Left);
  VText := #13#10;
  VText := VText + AnsiToUtf8('<Folder>') + #13#10;
  VText := VText + AnsiToUtf8('  <Region>') + #13#10;
  VText := VText + AnsiToUtf8('    <LatLonAltBox>') + #13#10;
  VText := VText + AnsiToUtf8('      <north>' + north + '</north>') + #13#10;
  VText := VText + AnsiToUtf8('      <south>' + south + '</south>') + #13#10;
  VText := VText + AnsiToUtf8('      <east>' + east + '</east>') + #13#10;
  VText := VText + AnsiToUtf8('      <west>' + west + '</west>') + #13#10;
  VText := VText + AnsiToUtf8('    </LatLonAltBox>') + #13#10;
  VText := VText + AnsiToUtf8('    <Lod>') + #13#10;
  if level > 1 then begin
    VText := VText + AnsiToUtf8('      <minLodPixels>128</minLodPixels>') + #13#10;
  end else begin
    VText := VText + AnsiToUtf8('      <minLodPixels>16</minLodPixels>') + #13#10;
  end;
  VText := VText + AnsiToUtf8('      <maxLodPixels>-1</maxLodPixels>') + #13#10;
  VText := VText + AnsiToUtf8('    </Lod>') + #13#10;
  VText := VText + AnsiToUtf8('  </Region>') + #13#10;
  VText := VText + AnsiToUtf8('  <GroundOverlay>') + #13#10;
  VText := VText + AnsiToUtf8('    <drawOrder>' + inttostr(level) + '</drawOrder>') + #13#10;
  VText := VText + AnsiToUtf8('    <Icon>') + #13#10;
  VText := VText + AnsiToUtf8('      <href>' + savepath + '</href>') + #13#10;
  VText := VText + AnsiToUtf8('    </Icon>') + #13#10;
  VText := VText + AnsiToUtf8('    <LatLonBox>') + #13#10;
  VText := VText + AnsiToUtf8('      <north>' + north + '</north>') + #13#10;
  VText := VText + AnsiToUtf8('      <south>' + south + '</south>') + #13#10;
  VText := VText + AnsiToUtf8('      <east>' + east + '</east>') + #13#10;
  VText := VText + AnsiToUtf8('      <west>' + west + '</west>') + #13#10;
  VText := VText + AnsiToUtf8('    </LatLonBox>') + #13#10;
  VText := VText + AnsiToUtf8('  </GroundOverlay>');
  AKmlStream.WriteBuffer(VText[1], Length(VText));
  inc(FTilesProcessed);
  if FTilesProcessed mod 100 = 0 then begin
    ProgressFormUpdateOnProgress(FTilesProcessed, FTilesToProcess);
  end;
  if level < Length(FZooms) then begin
    VZoom := FZooms[level];
    VTileRect :=
      RectFromDoubleRect(
        FTileStorage.ProjectionSet.Zooms[VZoom].RelativeRect2TileRectFloat(FTileStorage.ProjectionSet.Zooms[AZoom].TilePos2RelativeRect(ATile)),
        rrClosest
      );
    VIterator.Init(VTileRect);
    while VIterator.Next(VTile) do begin
      KmlFileWrite(AKmlStream, VTile, VZoom, level + 1);
    end;
  end;
  VText := #13#10;
  VText := VText + AnsiToUtf8('</Folder>');
  AKmlStream.WriteBuffer(VText[1], Length(VText));
end;

procedure TExportTaskToKML.ProcessRegion;
var
  I: Integer;
  VZoom: Byte;
  VText: UTF8String;
  VProjection: IProjection;
  VTempIterator: ITileIterator;
  VIterator: ITileIterator;
  VTile: TPoint;
  VKMLStream: TFileStream;
begin
  inherited;
  FTilesToProcess := 0;
  if Length(FZooms) > 0 then begin
    VZoom := FZooms[0];
    VProjection := FTileStorage.ProjectionSet.Zooms[VZoom];
    VIterator := Self.MakeTileIterator(VProjection);
    FTilesToProcess := FTilesToProcess + VIterator.TilesTotal;
    for I := 0 to Length(FZooms) - 1 do begin
      VZoom := FZooms[I];
      VProjection := FTileStorage.ProjectionSet.Zooms[VZoom];
      VTempIterator := Self.MakeTileIterator(VProjection);
      FTilesToProcess := FTilesToProcess + VTempIterator.TilesTotal;
    end;
  end;
  FTilesProcessed := 0;
  ProgressInfo.SetCaption(SAS_STR_ExportTiles);
  ProgressInfo.SetFirstLine(
    SAS_STR_AllSaves + ' ' + inttostr(FTilesToProcess) + ' ' + SAS_STR_Files
  );
  ProgressFormUpdateOnProgress(FTilesProcessed, FTilesToProcess);
  try
    VKMLStream := TFileStream.Create(FPathExport, fmCreate);
    try
      VText := '';
      VText := VText + AnsiToUtf8('<?xml version="1.0" encoding="UTF-8"?>') + #13#10;
      VText := VText + AnsiToUtf8('<kml xmlns="http://earth.google.com/kml/2.1">') + #13#10;
      VText := VText + AnsiToUtf8('<Document>') + #13#10;
      VText := VText + AnsiToUtf8('<name>' + ExtractFileName(FPathExport) + '</name>') + #13#10;
      VKMLStream.WriteBuffer(VText[1], Length(VText));

      VZoom := FZooms[0];
      while VIterator.Next(VTile) do begin
        if not CancelNotifier.IsOperationCanceled(OperationID) then begin
          KmlFileWrite(VKMLStream, VTile, VZoom, 1);
        end;
      end;
      VText := #13#10 + AnsiToUtf8('</Document>') + #13#10;
      VText := VText + AnsiToUtf8('</kml>') + #13#10;
      VKMLStream.WriteBuffer(VText[1], Length(VText));
    finally
      VKMLStream.Free;
    end;
  finally
    ProgressFormUpdateOnProgress(FTilesProcessed, FTilesToProcess);
  end;
end;

end.

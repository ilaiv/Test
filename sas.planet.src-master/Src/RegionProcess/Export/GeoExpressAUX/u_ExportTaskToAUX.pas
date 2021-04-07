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

unit u_ExportTaskToAUX;

interface

uses
  Windows,
  SysUtils,
  i_TileStorage,
  i_Projection,
  i_MapVersionInfo,
  i_NotifierOperation,
  i_RegionProcessProgressInfo,
  i_GeometryLonLat,
  i_TileIteratorFactory,
  u_RegionProcessTaskAbstract;

type
  TExportTaskToAUX = class(TRegionProcessTaskAbstract)
  private
    FTileStorage: ITileStorage;
    FVersion: IMapVersionInfo;
    FProjection: IProjection;
    FFileName: string;
    FZoom: Byte;
  protected
    procedure ProcessRegion; override;
    procedure ProgressFormUpdateOnProgress(AProcessed, AToProcess: Int64);
  public
    constructor Create(
      const AProgressInfo: IRegionProcessProgressInfoInternal;
      const APolygon: IGeometryLonLatPolygon;
      const ATileIteratorFactory: ITileIteratorFactory;
      const AProjection: IProjection;
      const ATileStorage: ITileStorage;
      const AVersion: IMapVersionInfo;
      const AFileName: string
    );
  end;

implementation

uses
  Classes,
  i_TileInfoBasic,
  i_TileIterator,
  u_ResStrings;

{ TExportTaskToAUX }

constructor TExportTaskToAUX.Create(
  const AProgressInfo: IRegionProcessProgressInfoInternal;
  const APolygon: IGeometryLonLatPolygon;
  const ATileIteratorFactory: ITileIteratorFactory;
  const AProjection: IProjection;
  const ATileStorage: ITileStorage;
  const AVersion: IMapVersionInfo;
  const AFileName: string
);
begin
  inherited Create(
    AProgressInfo,
    APolygon,
    ATileIteratorFactory
  );
  FProjection := AProjection;
  FZoom := AProjection.Zoom;
  FTileStorage := ATileStorage;
  FVersion := AVersion;
  FFileName := AFileName;
end;

procedure TExportTaskToAUX.ProcessRegion;
var
  VTileIterator: ITileIterator;
  VTile: TPoint;
  VFileStream: TFileStream;
  VPixelRect: TRect;
  VRectOfTilePixels: TRect;
  VFileName: string;
  VOutString: AnsiString;
  VOutPos: TPoint;
  VTilesToProcess: Int64;
  VTilesProcessed: Int64;
  VTileInfo: ITileInfoBasic;
begin
  VTileIterator := Self.MakeTileIterator(FProjection);
  VTilesToProcess := VTileIterator.TilesTotal;
  ProgressInfo.SetCaption(SAS_STR_ExportTiles);
  ProgressInfo.SetFirstLine(
    SAS_STR_AllSaves + ' ' + inttostr(VTilesToProcess) + ' ' + SAS_STR_Files
  );
  VTilesProcessed := 0;
  ProgressFormUpdateOnProgress(VTilesProcessed, VTilesToProcess);
  VPixelRect := FProjection.TileRect2PixelRect(VTileIterator.TilesRect.Rect);
  VFileStream := TFileStream.Create(FFileName, fmCreate);
  try
    while VTileIterator.Next(VTile) do begin
      if CancelNotifier.IsOperationCanceled(OperationID) then begin
        exit;
      end;
      VTileInfo := FTileStorage.GetTileInfo(VTile, FZoom, FVersion, gtimAsIs);
      if Assigned(VTileInfo) and VTileInfo.GetIsExists then begin
        VRectOfTilePixels := FProjection.TilePos2PixelRect(VTile);
        VOutPos.X := VRectOfTilePixels.Left - VPixelRect.Left;
        VOutPos.Y := VPixelRect.Bottom - VRectOfTilePixels.Bottom;
        VFileName := FTileStorage.GetTileFileName(VTile, FZoom, FVersion);
        VOutString := UTF8Encode(Format('"%s" %d %d', [VFileName, VOutPos.X, VOutPos.Y])) + #13#10;
        VFileStream.WriteBuffer(VOutString[1], Length(VOutString));
      end;
      inc(VTilesProcessed);
      if VTilesProcessed mod 100 = 0 then begin
        ProgressFormUpdateOnProgress(VTilesProcessed, VTilesToProcess);
      end;
    end;
  finally
    VFileStream.Free;
  end;
end;

procedure TExportTaskToAUX.ProgressFormUpdateOnProgress(AProcessed, AToProcess: Int64);
begin
  ProgressInfo.SetProcessedRatio(AProcessed / AToProcess);
  ProgressInfo.SetSecondLine(SAS_STR_Processed + ' ' + inttostr(AProcessed));
end;

end.

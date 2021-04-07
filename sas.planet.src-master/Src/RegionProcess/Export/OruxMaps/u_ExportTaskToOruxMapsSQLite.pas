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

unit u_ExportTaskToOruxMapsSQLite;

interface

uses
  Types,
  Windows,
  SysUtils,
  Classes,
  SQLite3Handler,
  i_BinaryData,
  i_NotifierOperation,
  i_RegionProcessProgressInfo,
  i_ProjectionSetFactory,
  i_GeometryProjectedFactory,
  i_TileIteratorFactory,
  i_GeometryLonLat,
  i_TileInfoBasic,
  i_TileStorage,
  i_TileIterator,
  i_MapVersionRequest,
  i_BitmapTileSaveLoad,
  i_BitmapLayerProvider,
  u_ExportTaskAbstract;

type
  TExportTaskToOruxMapsSQLite = class(TExportTaskAbstract)
  private
    FFormatSettings: TFormatSettings;
    FVectorGeometryProjectedFactory: IGeometryProjectedFactory;
    FProjectionSetFactory: IProjectionSetFactory;
    FExportPath: string;
    FTileStorage: ITileStorage;
    FMapVersion: IMapVersionRequest;
    FBitmapTileSaver: IBitmapTileSaver;
    FBitmapProvider: IBitmapTileUniProvider;
    FDirectTilesCopy: Boolean;
    FSQLite3DB: TSQLite3DbHandler;
    FSQLiteAvailable: Boolean;
    FBlankTile: IBinaryData;
    FBasePoint: TPoint;
  private
    procedure WriteMainOtrk2File(const ATileIterators: array of ITileIterator);
    procedure OpenSQLiteStorage;
    procedure CloseSQLiteStorage;
    procedure SaveTileToSQLiteStorage(
      const ATile: TPoint;
      const AZoom: Byte;
      const AData: IBinaryData
    );
  protected
    procedure ProcessRegion; override;
  public
    constructor Create(
      const AProgressInfo: IRegionProcessProgressInfoInternal;
      const AExportPath: string;
      const ATileIteratorFactory: ITileIteratorFactory;
      const AVectorGeometryProjectedFactory: IGeometryProjectedFactory;
      const AProjectionSetFactory: IProjectionSetFactory;
      const APolygon: IGeometryLonLatPolygon;
      const AZoomArr: TByteDynArray;
      const ATileStorage: ITileStorage;
      const AMapVersion: IMapVersionRequest;
      const ABitmapTileSaver: IBitmapTileSaver;
      const ABitmapProvider: IBitmapTileUniProvider;
      const ABlankTile: IBinaryData;
      const ADirectTilesCopy: Boolean
    );
  end;

implementation

uses
  Math,
  ALString,
  ALSqlite3Wrapper,
  c_CoordConverter,
  t_GeoTypes,
  i_GeometryProjected,
  i_ProjectionSet,
  i_Projection,
  i_Bitmap32Static,
  i_TileRect,
  u_TileRect,
  u_TileIteratorByRect,
  u_TileIteratorByPolygon,
  u_GeoFunc,
  u_ResStrings;

const
  DATABASE_FILENAME = 'OruxMapsImages.db';
  TABLE_TILES_DDL = 'CREATE TABLE IF NOT EXISTS tiles (x int, y int, z int, image blob, PRIMARY KEY (x,y,z))';
  INDEX_DDL = 'CREATE INDEX IF NOT EXISTS IND on tiles (x,y,z)';
  INSERT_SQL = 'INSERT or IGNORE INTO tiles (x,y,z,image) VALUES (%d,%d,%d,?)';
  TABLE_ANDROID_METADATA_DDL = 'CREATE TABLE IF NOT EXISTS android_metadata (locale TEXT)';

{ TExportTaskToOruxMapsSQLite }

constructor TExportTaskToOruxMapsSQLite.Create(
  const AProgressInfo: IRegionProcessProgressInfoInternal;
  const AExportPath: string;
  const ATileIteratorFactory: ITileIteratorFactory;
  const AVectorGeometryProjectedFactory: IGeometryProjectedFactory;
  const AProjectionSetFactory: IProjectionSetFactory;
  const APolygon: IGeometryLonLatPolygon;
  const AZoomArr: TByteDynArray;
  const ATileStorage: ITileStorage;
  const AMapVersion: IMapVersionRequest;
  const ABitmapTileSaver: IBitmapTileSaver;
  const ABitmapProvider: IBitmapTileUniProvider;
  const ABlankTile: IBinaryData;
  const ADirectTilesCopy: Boolean
);
begin
  inherited Create(
    AProgressInfo,
    APolygon,
    AZoomArr,
    ATileIteratorFactory
  );
  FFormatSettings.DecimalSeparator := '.';
  FVectorGeometryProjectedFactory := AVectorGeometryProjectedFactory;
  FProjectionSetFactory := AProjectionSetFactory;
  FExportPath := AExportPath;
  FTileStorage := ATileStorage;
  FMapVersion := AMapVersion;
  FBitmapTileSaver := ABitmapTileSaver;
  FBitmapProvider := ABitmapProvider;
  FBlankTile := ABlankTile;
  FDirectTilesCopy := ADirectTilesCopy;
  FSQLiteAvailable := FSQLite3DB.Init;
end;

procedure TExportTaskToOruxMapsSQLite.ProcessRegion;
var
  I: Integer;
  VZoom: Byte;
  VTile: TPoint;
  VDoubleRect: TDoubleRect;
  VDoDirectCopy: Boolean;
  VTilesToProcess: Int64;
  VTilesProcessed: Int64;
  VProjectionSet: IProjectionSet;
  VRect: TRect;
  VTileRect: ITileRect;
  VTileIterators: array of ITileIterator;
  VTileIterator: ITileIterator;
  VProjectedPolygons: array of IGeometryProjectedPolygon;
  VProjectedPolygon: IGeometryProjectedPolygon;
  VTileInfo: ITileInfoWithData;
  VBitmapTile: IBitmap32Static;
  VTileData: IBinaryData;
  VProjection: IProjection;
  VIterByRect: Boolean;
  VDoSaveBlank: Boolean;
begin
  inherited;

  VDoDirectCopy := FDirectTilesCopy and Assigned(FTileStorage);

  if not VDoDirectCopy then begin
    Assert(FBitmapProvider <> nil);
    Assert(FBitmapTileSaver <> nil);
  end;

  if not DirectoryExists(FExportPath) then begin
    if not ForceDirectories(FExportPath) then begin
      RaiseLastOSError;
    end;
  end;

  VIterByRect := Assigned(FBlankTile);

  SetLength(VTileIterators, Length(FZooms));
  SetLength(VProjectedPolygons, Length(FZooms));

  VTilesToProcess := 0;

  if VDoDirectCopy then begin
    VProjectionSet := FTileStorage.ProjectionSet;
  end else begin
    VProjectionSet := FProjectionSetFactory.GetProjectionSetByCode(
      CGoogleProjectionEPSG,
      CTileSplitQuadrate256x256
    );
  end;

  for I := 0 to Length(FZooms) - 1 do begin
    VProjection := VProjectionSet.Zooms[FZooms[I]];
    VProjectedPolygons[I] :=
      FVectorGeometryProjectedFactory.CreateProjectedPolygonByLonLatPolygon(
        VProjection,
        PolygLL
      );
    if VIterByRect then begin
      VRect :=
        RectFromDoubleRect(
          VProjection.PixelRectFloat2TileRectFloat(VProjectedPolygons[I].Bounds),
          rrOutside
        );
      VTileRect := TTileRect.Create(VProjection, VRect);
      VTileIterators[I] := TTileIteratorByRect.Create(VTileRect);
    end else begin
      VTileIterators[I] := Self.MakeTileIterator(VProjection);
    end;
    VTilesToProcess := VTilesToProcess + VTileIterators[I].TilesTotal;
  end;

  WriteMainOtrk2File(VTileIterators);

  OpenSQLiteStorage;
  try
    ProgressInfo.SetCaption(SAS_STR_ExportTiles);
    ProgressInfo.SetFirstLine(
      SAS_STR_AllSaves + ' ' + inttostr(VTilesToProcess) + ' ' + SAS_STR_Files
    );
    VTilesProcessed := 0;
    ProgressFormUpdateOnProgress(VTilesProcessed, VTilesToProcess);

    for I := 0 to Length(FZooms) - 1 do begin
      VZoom := FZooms[I];
      VTileIterator := VTileIterators[I];
      VProjectedPolygon := VProjectedPolygons[I];
      if Assigned(VTileIterator) then begin
        VProjection := VTileIterator.TilesRect.Projection;
        FBasePoint := VTileIterator.TilesRect.TopLeft;
        while VTileIterator.Next(VTile) do begin
          if CancelNotifier.IsOperationCanceled(OperationID) then begin
            Exit;
          end;

          VDoSaveBlank := False;

          if VIterByRect then begin
            VDoubleRect := VProjection.TilePos2PixelRectFloat(VTile);
            VDoSaveBlank := not VProjectedPolygon.IsRectIntersectPolygon(VDoubleRect);
          end;

          if not VDoSaveBlank then begin
            if VDoDirectCopy then begin
              if Supports(FTileStorage.GetTileInfoEx(VTile, VZoom, FMapVersion, gtimWithData), ITileInfoWithData, VTileInfo) then begin
                // save tile as is
                SaveTileToSQLiteStorage(VTile, VZoom, VTileInfo.TileData);
              end else begin
                VDoSaveBlank := True;
              end;
            end else begin
              VBitmapTile :=
                FBitmapProvider.GetTile(
                  Self.OperationID,
                  Self.CancelNotifier,
                  VProjection,
                  VTile
                );
              if Assigned(VBitmapTile) then begin
                VTileData := FBitmapTileSaver.Save(VBitmapTile);
                // save tile with overlay
                SaveTileToSQLiteStorage(VTile, VZoom, VTileData);
              end else begin
                VDoSaveBlank := True;
              end;
            end;
          end;

          if VIterByRect and VDoSaveBlank then begin
            SaveTileToSQLiteStorage(VTile, VZoom, FBlankTile);
          end;

          Inc(VTilesProcessed);
          if VTilesProcessed mod 100 = 0 then begin
            ProgressFormUpdateOnProgress(VTilesProcessed, VTilesToProcess);
          end;
        end;
      end;
    end;
  finally
    CloseSQLiteStorage;
    for I := 0 to Length(FZooms) - 1 do begin
      VTileIterators[I] := nil;
      VProjectedPolygons[I] := nil;
    end;
    VTileIterators := nil;
    VProjectedPolygons := nil;
  end;
end;

procedure TExportTaskToOruxMapsSQLite.WriteMainOtrk2File(
  const ATileIterators: array of ITileIterator
);
const
  CR = #13#10;
var
  I: Integer;
  VRect: TRect;
  VTileRect: ITileRect;
  VLonLatRect: TDoubleRect;
  VProjection: IProjection;
  VText: string;
  VMapName: string;
  VLayerFormat: string;
  VProjectionStr: string;
  xMax, yMax: Integer;
  VUtf8Text: UTF8String;
  VMemStream: TMemoryStream;
begin
  VMapName := ExtractFileName(ExcludeTrailingPathDelimiter(FExportPath));

  VText :=
    '<?xml version="1.0" encoding="UTF-8"?>' + CR +
    '<OruxTracker xmlns="http://oruxtracker.com/app/res/calibration"' + CR +
    'versionCode="3.0">' + CR +
    '<MapCalibration layers="true" layerLevel="0">' + CR +
    '<MapName><![CDATA[' + VMapName + ']]></MapName>' + CR;

  VLayerFormat :=
    '<OruxTracker  versionCode="2.1">' + CR +
    '<MapCalibration layers="false" layerLevel="%d">' + CR +
    '<MapName><![CDATA[%s]]></MapName>' + CR +
    '<MapChunks xMax="%d" yMax="%d" datum="WGS84" projection="%s" img_height="256" img_width="256" file_name="%s" />' + CR +
    '<MapDimensions height="%d" width="%d" />' + CR +
    '<MapBounds minLat="%.8f" maxLat="%.8f" minLon="%.8f" maxLon="%.8f" />' + CR +
    '<CalibrationPoints>' + CR +
    '<CalibrationPoint corner="TL" lon="%.6f" lat="%.6f" />' + CR +
    '<CalibrationPoint corner="BR" lon="%.6f" lat="%.6f" />' + CR +
    '<CalibrationPoint corner="TR" lon="%.6f" lat="%.6f" />' + CR +
    '<CalibrationPoint corner="BL" lon="%.6f" lat="%.6f" />' + CR +
    '</CalibrationPoints>' + CR +
    '</MapCalibration>' + CR +
    '</OruxTracker>' + CR;

  for I := 0 to Length(ATileIterators) - 1 do begin
    VTileRect := ATileIterators[I].TilesRect;
    VProjection := VTileRect.Projection;
    VRect := VTileRect.Rect;

    VLonLatRect := VProjection.TileRect2LonLatRect(VRect);

    xMax := VRect.Right - VRect.Left;
    yMax := VRect.Bottom - VRect.Top;

    if VProjectionStr = '' then begin
      case VProjection.ProjectionType.ProjectionEPSG of
        CGoogleProjectionEPSG: VProjectionStr := 'Mercator';
        CYandexProjectionEPSG: VProjectionStr := 'Mercator Ellipsoidal';
        CGELonLatProjectionEPSG: VProjectionStr := 'Latitude/Longitude';
      else
        raise Exception.CreateFmt('Unknown projection EPSG: %d', [VProjection.ProjectionType.ProjectionEPSG]);
      end;
    end;

    VText := VText +
      Format(VLayerFormat, [
        VProjection.Zoom,
        VMapName,
        xMax, yMax, VProjectionStr, VMapName,
        yMax*256, xMax*256,
        VLonLatRect.Bottom, VLonLatRect.Top, VLonLatRect.Left, VLonLatRect.Right,
        VLonLatRect.TopLeft.X, VLonLatRect.TopLeft.Y,
        VLonLatRect.BottomRight.X, VLonLatRect.BottomRight.Y,
        VLonLatRect.BottomRight.X, VLonLatRect.TopLeft.Y,
        VLonLatRect.TopLeft.X, VLonLatRect.BottomRight.Y
      ], FFormatSettings);
  end;

  VText := VText + '</MapCalibration>' + CR + '</OruxTracker>';

  VUtf8Text := AnsiToUtf8(VText);

  VMemStream := TMemoryStream.Create;
  try
    VMemStream.WriteBuffer(VUtf8Text[1], Length(VUtf8Text));
    VMemStream.SaveToFile(FExportPath + VMapName + '.otrk2.xml');
  finally
    VMemStream.Free;
  end;
end;

procedure TExportTaskToOruxMapsSQLite.OpenSQLiteStorage;
const
  cLocale = '''en_US''';
var
  VFileName: string;
begin
  if not FSQLiteAvailable then begin
    raise ESQLite3SimpleError.Create('SQLite not available');
  end;

  CloseSQLiteStorage;

  VFileName := FExportPath + DATABASE_FILENAME;

  if FileExists(VFileName) then begin
    if not DeleteFile(VFileName) then begin
      raise ESQLite3SimpleError.CreateFmt('Can''t delete database: %s', [VFileName]);
    end;
  end;

  FSQLite3Db.OpenW(VFileName);

  FSQLite3DB.ExecSQL(TABLE_TILES_DDL);
  FSQLite3DB.ExecSQL(INDEX_DDL);

  FSQLite3DB.ExecSQL(TABLE_ANDROID_METADATA_DDL);
  FSQLite3DB.ExecSQL('INSERT INTO android_metadata VALUES (' + cLocale + ')');

  FSQLite3DB.SetExclusiveLockingMode;
  FSQLite3DB.ExecSQL('PRAGMA synchronous=OFF');
  FSQLite3DB.ExecSQL('PRAGMA journal_mode=OFF');
end;

procedure TExportTaskToOruxMapsSQLite.CloseSQLiteStorage;
begin
  if FSQLite3DB.Opened then begin
    FSQLite3DB.Close;
  end;
end;

procedure TExportTaskToOruxMapsSQLite.SaveTileToSQLiteStorage(
  const ATile: TPoint;
  const AZoom: Byte;
  const AData: IBinaryData
);
var
  X, Y: Integer;
begin
  Assert(AData <> nil);

  X := ATile.X - FBasePoint.X;
  Y := ATile.Y - FBasePoint.Y;

  FSQLite3DB.ExecSQLWithBLOB(
    ALFormat(INSERT_SQL, [X, Y, AZoom]),
    AData.Buffer,
    AData.Size
  );
end;

end.

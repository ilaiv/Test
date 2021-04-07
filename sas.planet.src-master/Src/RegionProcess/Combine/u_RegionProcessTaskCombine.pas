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

unit u_RegionProcessTaskCombine;

interface

uses
  Classes,
  Types,
  i_Projection,
  i_BitmapTileProvider,
  i_RegionProcessProgressInfo,
  i_GeometryLonLat,
  i_MapCalibration,
  i_BitmapMapCombiner,
  u_RegionProcessTaskAbstract;

type
  TRegionProcessTaskCombine = class(TRegionProcessTaskAbstract)
  private
    FImageProvider: IBitmapTileProvider;
    FMapRect: TRect;
    FMapCalibrationList: IMapCalibrationList;
    FSplitCount: TPoint;
    FSkipExistingFiles: Boolean;
    FFileName: string;
    FFilePath: string;
    FFileExt: string;
    FCombiner: IBitmapMapCombiner;
  protected
    procedure ProgressFormUpdateOnProgress(AProgress: Double);
    procedure ProcessRegion; override;
  public
    constructor Create(
      const AProgressInfo: IRegionProcessProgressInfoInternal;
      const APolygon: IGeometryLonLatPolygon;
      const AMapRect: TRect;
      const ACombiner: IBitmapMapCombiner;
      const AImageProvider: IBitmapTileProvider;
      const AMapCalibrationList: IMapCalibrationList;
      const AFileName: string;
      const ASplitCount: TPoint;
      const ASkipExistingFiles: Boolean
    );
  end;

implementation

uses
  SysUtils,
  u_GeoFunc,
  u_ResStrings;

{ TRegionProcessTaskCombine }

constructor TRegionProcessTaskCombine.Create(
  const AProgressInfo: IRegionProcessProgressInfoInternal;
  const APolygon: IGeometryLonLatPolygon;
  const AMapRect: TRect;
  const ACombiner: IBitmapMapCombiner;
  const AImageProvider: IBitmapTileProvider;
  const AMapCalibrationList: IMapCalibrationList;
  const AFileName: string;
  const ASplitCount: TPoint;
  const ASkipExistingFiles: Boolean
);
begin
  inherited Create(
    AProgressInfo,
    APolygon,
    nil
  );
  FMapRect := AMapRect;
  FCombiner := ACombiner;
  FImageProvider := AImageProvider;
  FSplitCount := ASplitCount;
  FSkipExistingFiles := ASkipExistingFiles;
  FFilePath := ExtractFilePath(AFileName);
  FFileExt := ExtractFileExt(AFileName);
  FFileName := ChangeFileExt(ExtractFileName(AFileName), '');
  FMapCalibrationList := AMapCalibrationList;
end;

procedure TRegionProcessTaskCombine.ProgressFormUpdateOnProgress(AProgress: Double);
begin
  ProgressInfo.SetProcessedRatio(AProgress);
  ProgressInfo.SetSecondLine(SAS_STR_Processed + ': ' + IntToStr(Trunc(AProgress * 100)) + '%');
end;


procedure TRegionProcessTaskCombine.ProcessRegion;
var
  VProjection: IProjection;
  i, j, pti: integer;
  VProcessTiles: Int64;
  VTileRect: TRect;
  VMapRect: TRect;
  VMapSize: TPoint;
  VCurrentPieceRect: TRect;
  VMapPieceSize: TPoint;
  VSizeInTile: TPoint;
  VCurrentFileName: string;
  VStr: string;
begin
  inherited;
  VProjection := FImageProvider.Projection;
  VMapRect := FMapRect;
  VMapSize := RectSize(VMapRect);
  VTileRect := VProjection.PixelRect2TileRect(VMapRect);
  VSizeInTile.X := VTileRect.Right - VTileRect.Left;
  VSizeInTile.Y := VTileRect.Bottom - VTileRect.Top;
  VProcessTiles := VSizeInTile.X;
  VProcessTiles := VProcessTiles * VSizeInTile.Y;

  VStr :=
    Format(
      SAS_STR_MapCombineProgressCaption,
      [VMapSize.X, VMapSize.Y, FSplitCount.X * FSplitCount.Y]
    );
  ProgressInfo.SetCaption(VStr);
  VStr :=
    Format(
      SAS_STR_MapCombineProgressLine0,
      [VSizeInTile.X, VSizeInTile.Y, VProcessTiles]
    );
  ProgressInfo.SetFirstLine(VStr);
  ProgressFormUpdateOnProgress(0);
  VMapPieceSize.X := VMapSize.X div FSplitCount.X;
  VMapPieceSize.Y := VMapSize.Y div FSplitCount.Y;

  for i := 1 to FSplitCount.X do begin
    for j := 1 to FSplitCount.Y do begin
      VCurrentPieceRect.Left := VMapRect.Left + VMapPieceSize.X * (i - 1);
      VCurrentPieceRect.Right := VMapRect.Left + VMapPieceSize.X * i;
      VCurrentPieceRect.Top := VMapRect.Top + VMapPieceSize.Y * (j - 1);
      VCurrentPieceRect.Bottom := VMapRect.Top + VMapPieceSize.Y * j;

      if (FSplitCount.X > 1) or (FSplitCount.Y > 1) then begin
        VCurrentFileName := FFilePath + FFileName + '_' + inttostr(i) + '-' + inttostr(j) + FFileExt;
        if FSkipExistingFiles and FileExists(VCurrentFileName) then begin
          Continue;
        end;
      end else begin
        VCurrentFileName := FFilePath + FFileName + FFileExt;
      end;

      if Assigned(FMapCalibrationList) then begin
        for pti := 0 to FMapCalibrationList.Count - 1 do begin
          try
            (FMapCalibrationList.get(pti) as IMapCalibration).SaveCalibrationInfo(
              VCurrentFileName,
              VCurrentPieceRect.TopLeft,
              VCurrentPieceRect.BottomRight,
              VProjection
            );
          except
            //TODO: �������� ���� ���������� ��������� ������.
          end;
        end;
      end;
      try
        FCombiner.SaveRect(
          OperationID,
          CancelNotifier,
          VCurrentFileName,
          FImageProvider,
          VCurrentPieceRect
        );
      except
        on E: Exception do begin
          if (FSplitCount.X > 1) or (FSplitCount.Y > 1) then begin
            raise Exception.CreateFmt(
              '%0:s'#13#10'Piece %1:dx%2:d',
              [E.message, i, j]
            );
          end else begin
            raise;
          end;
        end;
      end;
    end;
  end;
end;

end.

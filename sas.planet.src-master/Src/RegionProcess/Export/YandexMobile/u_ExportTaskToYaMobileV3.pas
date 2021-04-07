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

unit u_ExportTaskToYaMobileV3;

interface

uses
  Windows,
  Types,
  SysUtils,
  Classes,
  i_BinaryData,
  i_Bitmap32BufferFactory,
  i_NotifierOperation,
  i_BitmapTileSaveLoad,
  i_BitmapLayerProvider,
  i_RegionProcessProgressInfo,
  i_ProjectionSetFactory,
  i_TileIteratorFactory,
  i_GeometryLonLat,
  u_ExportTaskAbstract;

type
  TExportTaskYaMobileV3 = record
    FMapId: Integer;
    FSaver: IBitmapTileSaver;
    FImageProvider: IBitmapTileUniProvider;
  end;
  TExportTaskYaMobileV3Array = array of TExportTaskYaMobileV3;

  TExportTaskToYaMobileV3 = class(TExportTaskAbstract)
  private
    FTasks: TExportTaskYaMobileV3Array;
    FBitmapFactory: IBitmap32StaticFactory;
    FIsReplace: boolean;
    FExportPath: string;
    FProjectionSetFactory: IProjectionSetFactory;
    function GetMobileFile(
      X, Y: Integer;
      Z: Byte;
      AMapType: Byte
    ): string;
    function TileToTablePos(const ATile: TPoint): Integer;
    procedure CreateNilFile(
      const AFileName: string;
      ATableSize: Integer
    );
    procedure WriteTileToYaCache(
      const ATile: TPoint;
      AZoom, AMapType, sm_xy: Byte;
      const AExportPath: string;
      const AData: IBinaryData;
      AReplace: Boolean
    );
  protected
    procedure ProcessRegion; override;
  public
    constructor Create(
      const AProgressInfo: IRegionProcessProgressInfoInternal;
      const AProjectionSetFactory: IProjectionSetFactory;
      const ATileIteratorFactory: ITileIteratorFactory;
      const ABitmapFactory: IBitmap32StaticFactory;
      const APath: string;
      const APolygon: IGeometryLonLatPolygon;
      const ATasks: TExportTaskYaMobileV3Array;
      const AZoomArr: TByteDynArray;
      AReplace: boolean
    );
    destructor Destroy; override;
  end;

implementation

uses
  GR32,
  c_CoordConverter,
  i_ProjectionSet,
  i_Bitmap32Static,
  i_Projection,
  i_TileIterator,
  u_BitmapFunc,
  u_ResStrings;

const
  YaHeaderSize: integer = 1024;

constructor TExportTaskToYaMobileV3.Create(
  const AProgressInfo: IRegionProcessProgressInfoInternal;
  const AProjectionSetFactory: IProjectionSetFactory;
  const ATileIteratorFactory: ITileIteratorFactory;
  const ABitmapFactory: IBitmap32StaticFactory;
  const APath: string;
  const APolygon: IGeometryLonLatPolygon;
  const ATasks: TExportTaskYaMobileV3Array;
  const AZoomArr: TByteDynArray;
  AReplace: boolean
);
begin
  inherited Create(
    AProgressInfo,
    APolygon,
    AZoomArr,
    ATileIteratorFactory
  );
  FProjectionSetFactory := AProjectionSetFactory;
  FBitmapFactory := ABitmapFactory;
  FExportPath := APath;
  FIsReplace := AReplace;
  FTasks := ATasks;

end;

function TExportTaskToYaMobileV3.GetMobileFile(
  X, Y: Integer;
  Z: Byte;
  AMapType: Byte
): string;
var
  Mask, Num: Integer;
begin
  Result := IntToStr(Z) + PathDelim;
  if (Z > 15) then begin
    Mask := (1 shl (Z - 15)) - 1;
    Num := (((X shr 15) and Mask) shl 4) + ((Y shr 15) and Mask);
    Result := Result + IntToHex(Num, 2) + PathDelim;
  end;
  if (Z > 11) then begin
    Mask := (1 shl (Z - 11)) - 1;
    Mask := Mask and $F;
    Num := (((X shr 11) and Mask) shl 4) + ((Y shr 11) and Mask);
    Result := Result + IntToHex(Num, 2) + PathDelim;
  end;
  if (Z > 7) then begin
    Mask := (1 shl (Z - 7)) - 1;
    Mask := Mask and $F;
    Num := (((X shr 7) and Mask) shl 8) + (((Y shr 7) and Mask) shl 4) + AMapType;
  end else begin
    Num := AMapType;
  end;
  Result := LowerCase(Result + IntToHex(Num, 3));
end;

function TExportTaskToYaMobileV3.TileToTablePos(const ATile: TPoint): Integer;
var
  X, Y: Integer;
begin
  X := ATile.X and $7F;
  Y := ATile.Y and $7F;
  Result := ((Y and $40) shl 9) +
    ((X and $40) shl 8) +
    ((Y and $20) shl 8) +
    ((X and $20) shl 7) +
    ((Y and $10) shl 7) +
    ((X and $10) shl 6) +
    ((Y and $08) shl 6) +
    ((X and $08) shl 5) +
    ((Y and $04) shl 5) +
    ((X and $04) shl 4) +
    ((Y and $02) shl 4) +
    ((X and $02) shl 3) +
    ((Y and $01) shl 3) +
    ((X and $01) shl 2);
end;

procedure TExportTaskToYaMobileV3.CreateNilFile(
  const AFileName: string;
  ATableSize: Integer
);
var
  VYaMob: TMemoryStream;
  VInitSize: Integer;
  VPath: string;
begin
  VYaMob := TMemoryStream.Create;
  try
    VPath := copy(AFileName, 1, LastDelimiter(PathDelim, AFileName));
    if not (DirectoryExists(VPath)) then begin
      if not ForceDirectories(VPath) then begin
        Exit;
      end;
    end;
    VInitSize := YaHeaderSize + 6 * (sqr(ATableSize));
    VYaMob.SetSize(VInitSize);
    FillChar(VYaMob.Memory^, VInitSize, 0);
    VYaMob.Position := 0;
    VYaMob.Write(AnsiString('YNDX'), 4);    // Magic = "YNDX"
    VYaMob.Write(AnsiString(#01#00), 2);    // Reserved
    VYaMob.Write(YaHeaderSize, 4);          // HeadSize = 1024 byte
    VYaMob.Write(AnsiString(#00#00#00), 3); // "Author"
    VYaMob.SaveToFile(AFileName);
  finally
    VYaMob.Free;
  end;
end;

destructor TExportTaskToYaMobileV3.Destroy;
var
  i: Integer;
begin
  for i := 0 to Length(FTasks) - 1 do begin
    FTasks[i].FSaver := nil;
    FTasks[i].FImageProvider := nil;
  end;
  inherited;
end;

procedure TExportTaskToYaMobileV3.WriteTileToYaCache(
  const ATile: TPoint;
  AZoom, AMapType, sm_xy: Byte;
  const AExportPath: string;
  const AData: IBinaryData;
  AReplace: Boolean
);
var
  VYaMobileFile: string;
  VYaMobileStream: TFileStream;
  VTablePos: Integer;
  VTableOffset: Integer;
  VTableSize: Integer;
  VTileOffset: Integer;
  VExistsTileOffset: Integer;
  VTileSize: SmallInt;
  VHead: array [0..12] of byte;
begin
  if AZoom > 7 then begin
    VTableSize := 256;
  end else begin
    VTableSize := 2 shl AZoom;
  end;

  VYaMobileFile := AExportPath + GetMobileFile(ATile.X, ATile.Y, AZoom, AMapType);

  if not FileExists(VYaMobileFile) then begin
    CreateNilFile(VYaMobileFile, VTableSize);
  end;

  VYaMobileStream := TFileStream.Create(VYaMobileFile, fmOpenReadWrite or fmShareExclusive);
  try
    VYaMobileStream.ReadBuffer(VHead, Length(VHead));
    VTableOffset := (VHead[6] or (VHead[7] shl 8) or (VHead[8] shl 16) or (VHead[9] shl 24));
    VTablePos := TileToTablePos(ATile) * 6 + sm_xy * 6;
    VTileOffset := VYaMobileStream.Size;
    VTileSize := AData.Size;
    VYaMobileStream.Position := VTableOffset + VTablePos;
    VYaMobileStream.ReadBuffer(VExistsTileOffset, 4);
    if (VExistsTileOffset = 0) or AReplace then begin
      VYaMobileStream.Position := VTableOffset + VTablePos;
      VYaMobileStream.WriteBuffer(VTileOffset, 4);
      VYaMobileStream.WriteBuffer(VTileSize, 2);
      VYaMobileStream.Position := VYaMobileStream.Size;
      VYaMobileStream.WriteBuffer(AData.Buffer^, VTileSize);
    end;
  finally
    VYaMobileStream.Free;
  end;
end;

procedure TExportTaskToYaMobileV3.ProcessRegion;
var
  i, j, xi, yi, hxyi, sizeim: integer;
  VZoom: Byte;
  VBitmapTile: IBitmap32Static;
  bmp32crop: TCustomBitmap32;
  tc: cardinal;
  VProjectionSet: IProjectionSet;
  VTile: TPoint;
  VTileIterators: array of ITileIterator;
  VTileIterator: ITileIterator;
  VProjection: IProjection;
  VTilesToProcess: Int64;
  VTilesProcessed: Int64;
  VStaticBitmapCrop: IBitmap32Static;
  VDataToSave: IBinaryData;
begin
  inherited;
  bmp32crop := TCustomBitmap32.Create;
  try
    hxyi := 1;
    sizeim := 128;
    bmp32crop.Width := sizeim;
    bmp32crop.Height := sizeim;
    VProjectionSet := FProjectionSetFactory.GetProjectionSetByCode(CYandexProjectionEPSG, CTileSplitQuadrate256x256);
    VTilesToProcess := 0;
    SetLength(VTileIterators, Length(FZooms));

    for i := 0 to Length(FZooms) - 1 do begin
      VZoom := FZooms[i];
      VProjection := VProjectionSet.Zooms[VZoom];
      VTileIterators[i] := Self.MakeTileIterator(VProjection);
      VTilesToProcess := VTilesToProcess + VTileIterators[i].TilesTotal * Length(FTasks);
    end;
    try
      ProgressInfo.SetCaption(SAS_STR_ExportTiles);
      ProgressInfo.SetFirstLine(
        SAS_STR_AllSaves + ' ' + inttostr(VTilesToProcess) + ' ' + SAS_STR_Files
      );

      VTilesProcessed := 0;
      ProgressFormUpdateOnProgress(VTilesProcessed, VTilesToProcess);
      tc := GetTickCount;
      for i := 0 to Length(FZooms) - 1 do begin
        VTileIterator := VTileIterators[i];
        VProjection := VTileIterator.TilesRect.Projection;
        VZoom := VProjection.Zoom;
        while VTileIterator.Next(VTile) do begin
          if CancelNotifier.IsOperationCanceled(OperationID) then begin
            exit;
          end;
          for j := 0 to length(FTasks) - 1 do begin
            VBitmapTile :=
              FTasks[j].FImageProvider.GetTile(
                OperationID,
                CancelNotifier,
                VProjection,
                VTile
              );
            if VBitmapTile <> nil then begin
              for xi := 0 to hxyi do begin
                for yi := 0 to hxyi do begin
                  bmp32crop.Clear;
                  BlockTransfer(
                    bmp32crop,
                    0,
                    0,
                    VBitmapTile,
                    bounds(sizeim * xi, sizeim * yi, sizeim, sizeim),
                    dmOpaque
                  );
                  VStaticBitmapCrop :=
                    FBitmapFactory.Build(
                      Point(sizeim, sizeim),
                      bmp32crop.Bits
                    );
                  VDataToSave := FTasks[j].FSaver.Save(VStaticBitmapCrop);
                  WriteTileToYaCache(
                    VTile,
                    VZoom,
                    FTasks[j].FMapId,
                    (yi * 2) + xi,
                    FExportPath,
                    VDataToSave,
                    FIsReplace
                  );
                end;
              end;
              inc(VTilesProcessed);
              if (GetTickCount - tc > 1000) then begin
                tc := GetTickCount;
                ProgressFormUpdateOnProgress(VTilesProcessed, VTilesToProcess);
              end;
            end;
          end;
        end;
      end;
    finally
      for i := 0 to Length(FZooms) - 1 do begin
        VTileIterators[i] := nil;
      end;
    end;
    ProgressFormUpdateOnProgress(VTilesProcessed, VTilesToProcess);
  finally
    bmp32crop.Free;
  end;
end;

end.

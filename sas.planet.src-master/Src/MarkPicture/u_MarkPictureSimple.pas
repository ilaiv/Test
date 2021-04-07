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

unit u_MarkPictureSimple;

interface

uses
  SysUtils,
  Classes,
  t_Hash,
  t_GeoTypes,
  i_SimpleFlag,
  i_BinaryData,
  i_BitmapMarker,
  i_BitmapTileSaveLoad,
  i_MarkPicture,
  u_BaseInterfacedObject;

type
  TMarkPictureSimple = class(TBaseInterfacedObject, IMarkPicture)
  private
    FHash: THashValue;
    FFullFileName: string;
    FName: string;
    FLoader: IBitmapTileLoader;

    FCS: IReadWriteSync;
    FBitmapMarker: IBitmapMarker;
    FSource: IBinaryData;
    FPicAnchor: TDoublePoint;

    FInitedFlag: ISimpleFlag;
    procedure InitPic;
  private
    function GetHash: THashValue;

    function GetMarker: IBitmapMarker;

    function GetName: string;
    function GetSource: IBinaryData;

    function GetTextAlignment: TAlignment;
    function GetTextVerticalAlignment: TVerticalAlignment;
  public
    constructor Create(
      const AHash: THashValue;
      const AFullFileName: string;
      const AName: string;
      const ALoader: IBitmapTileLoader;
      const APicAnchor: TDoublePoint
    );
  end;

implementation

uses
  i_Bitmap32Static,
  u_BitmapMarker,
  u_BinaryDataByMemStream,
  u_MarkPictureAnchorFunc,
  u_SimpleFlagWithInterlock,
  u_Synchronizer;

{ TMarkPictureSimple }
constructor TMarkPictureSimple.Create(
  const AHash: THashValue;
  const AFullFileName: string;
  const AName: string;
  const ALoader: IBitmapTileLoader;
  const APicAnchor: TDoublePoint
);
begin
  inherited Create;
  FHash := AHash;
  FFullFileName := AFullFileName;
  FName := AName;
  FLoader := ALoader;
  FPicAnchor := APicAnchor;

  FCS := GSync.SyncSymmetrical.Make(Self.ClassName);
  FInitedFlag := TSimpleFlagWithInterlock.Create;
end;

function TMarkPictureSimple.GetTextAlignment: TAlignment;
begin
  Result := taRightJustify;
end;

function TMarkPictureSimple.GetTextVerticalAlignment: TVerticalAlignment;
begin
  Result := taVerticalCenter;
end;

procedure TMarkPictureSimple.InitPic;
var
  VMemStream: TMemoryStream;
  VBitmap: IBitmap32Static;
  VAnchor: TDoublePoint;
begin
  if not FInitedFlag.CheckFlag then begin
    FCS.BeginWrite;
    try
      if not FInitedFlag.CheckFlag then begin
        VMemStream := TMemoryStream.Create;
        try
          VMemStream.LoadFromFile(FFullFileName);
          FSource := TBinaryDataByMemStream.CreateWithOwn(VMemStream);
          VMemStream := nil;
        finally
          VMemStream.Free;
        end;
        VBitmap := FLoader.Load(FSource);

        VAnchor := AnchorRelativeToAbsolute(FPicAnchor, VBitmap.Size);

        FBitmapMarker := TBitmapMarker.Create(VBitmap, VAnchor);
        FInitedFlag.SetFlag;
      end;
    finally
      FCS.EndWrite;
    end;
  end;
end;

function TMarkPictureSimple.GetHash: THashValue;
begin
  Result := FHash;
end;

function TMarkPictureSimple.GetMarker: IBitmapMarker;
begin
  InitPic;
  Result := FBitmapMarker;
end;

function TMarkPictureSimple.GetName: string;
begin
  Result := FName;
end;

function TMarkPictureSimple.GetSource: IBinaryData;
begin
  InitPic;
  Result := FSource;
end;

end.

{******************************************************************************}
{* SAS.Planet (SAS.�������)                                                   *}
{* Copyright (C) 2007-2012, SAS.Planet development team.                      *}
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

unit u_BitmapTileProviderWithBGColor;

interface

uses
  Types,
  t_Bitmap32,
  i_NotifierOperation,
  i_Bitmap32Static,
  i_Bitmap32BufferFactory,
  i_Projection,
  i_BitmapTileProvider,
  u_BaseInterfacedObject;

type
  TBitmapTileProviderWithBGColor = class(TBaseInterfacedObject, IBitmapTileProvider)
  private
    FBitmap32StaticFactory: IBitmap32StaticFactory;
    FSourceProvider: IBitmapTileProvider;
    FEmptyTile: IBitmap32Static;
    FBackGroundColor: TColor32;
    FEmptyColor: TColor32;
  private
    function GetProjection: IProjection;
    function GetTile(
      AOperationID: Integer;
      const ACancelNotifier: INotifierOperation;
      const ATile: TPoint
    ): IBitmap32Static;
  public
    constructor Create(
      ABackGroundColor: TColor32;
      AEmptyColor: TColor32;
      const ABitmap32StaticFactory: IBitmap32StaticFactory;
      const ASourceProvider: IBitmapTileProvider
    );
  end;

implementation

uses
  GR32,
  u_BitmapFunc,
  u_GeoFunc,
  u_Bitmap32ByStaticBitmap;

{ TBitmapTileProviderWithBGColor }

constructor TBitmapTileProviderWithBGColor.Create(
  ABackGroundColor: TColor32;
  AEmptyColor: TColor32;
  const ABitmap32StaticFactory: IBitmap32StaticFactory;
  const ASourceProvider: IBitmapTileProvider
);
var
  VTileSize: TPoint;
  VTargetBmp: TBitmap32ByStaticBitmap;
begin
  Assert(Assigned(ASourceProvider));
  Assert(Assigned(ABitmap32StaticFactory));
  inherited Create;
  FSourceProvider := ASourceProvider;
  FBackGroundColor := ABackGroundColor;
  FEmptyColor := AEmptyColor;
  FBitmap32StaticFactory := ABitmap32StaticFactory;

  VTileSize := ASourceProvider.Projection.GetTileSize(Types.Point(0, 0));
  VTargetBmp := TBitmap32ByStaticBitmap.Create(FBitmap32StaticFactory);
  try
    VTargetBmp.SetSize(VTileSize.X, VTileSize.Y);
    VTargetBmp.Clear(FEmptyColor);
    FEmptyTile := VTargetBmp.MakeAndClear;
  finally
    VTargetBmp.Free;
  end;

  Assert(FSourceProvider <> nil);
end;

function TBitmapTileProviderWithBGColor.GetProjection: IProjection;
begin
  Result := FSourceProvider.Projection;
end;

function TBitmapTileProviderWithBGColor.GetTile(
  AOperationID: Integer;
  const ACancelNotifier: INotifierOperation;
  const ATile: TPoint
): IBitmap32Static;
var
  VTileSize: TPoint;
  VTargetBmp: TBitmap32ByStaticBitmap;
begin
  Result :=
    FSourceProvider.GetTile(
      AOperationID,
      ACancelNotifier,
      ATile
    );
  if Result <> nil then begin
    if FBackGroundColor <> 0 then begin
      VTargetBmp := TBitmap32ByStaticBitmap.Create(FBitmap32StaticFactory);
      try
        VTileSize := FSourceProvider.Projection.GetTileSize(ATile);
        VTargetBmp.SetSize(VTileSize.X, VTileSize.Y);
        VTargetBmp.Clear(FBackGroundColor);
        BlockTransferFull(
          VTargetBmp,
          0,
          0,
          Result,
          dmBlend
        );
        Result := VTargetBmp.MakeAndClear;
      finally
        VTargetBmp.Free;
      end;
    end;
  end else begin
    VTileSize := FSourceProvider.Projection.GetTileSize(ATile);
    if IsPointsEqual(VTileSize, FEmptyTile.Size) then begin
      Result := FEmptyTile;
    end else begin
      VTargetBmp := TBitmap32ByStaticBitmap.Create(FBitmap32StaticFactory);
      try
        VTargetBmp.SetSize(VTileSize.X, VTileSize.Y);
        VTargetBmp.Clear(FEmptyColor);
        Result := VTargetBmp.MakeAndClear;
      finally
        VTargetBmp.Free;
      end;
    end;
  end;
end;

end.

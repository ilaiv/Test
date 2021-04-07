{******************************************************************************}
{* SAS.Planet (SAS.�������)                                                   *}
{* Copyright (C) 2007-2016, SAS.Planet development team.                      *}
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

unit u_BitmapLayerProviderMapWithLayer;

interface

uses
  Types,
  i_NotifierOperation,
  i_Bitmap32Static,
  i_Bitmap32BufferFactory,
  i_Projection,
  i_BitmapLayerProvider,
  i_MapTypeListStatic,
  i_MapVersionRequest,
  i_MapType,
  u_BaseInterfacedObject;

type
  TBitmapLayerProviderMapWithLayer = class(
    TBaseInterfacedObject,
    IBitmapTileUniProvider,
    IBitmapUniProvider
  )
  private
    type
      TMapTypeItem = record
        FMapType: IMapType;
        FVersion: IMapVersionRequest;
      end;
      TUniType = (uniTile, uniBitmap);
  private
    FBitmap32StaticFactory: IBitmap32StaticFactory;
    FMapTypeArray: array of TMapTypeItem;
    FUsePrevZoomAtMap: Boolean;
    FUsePrevZoomAtLayers: Boolean;
    function GetUni(
      AOperationID: Integer;
      const ACancelNotifier: INotifierOperation;
      const AProjection: IProjection;
      const AUniType: TUniType;
      const ATile: TPoint;
      const APixelRectTarget: TRect
    ): IBitmap32Static;
  private
    { IBitmapTileUniProvider }
    function GetTile(
      AOperationID: Integer;
      const ACancelNotifier: INotifierOperation;
      const AProjection: IProjection;
      const ATile: TPoint
    ): IBitmap32Static;
    { IBitmapUniProvider }
    function GetBitmap(
      AOperationID: Integer;
      const ACancelNotifier: INotifierOperation;
      const AProjection: IProjection;
      const APixelRectTarget: TRect
    ): IBitmap32Static;
  public
    constructor Create(
      const ABitmap32StaticFactory: IBitmap32StaticFactory;
      const AMapTypeMain: IMapType;
      const AMapTypeMainVersion: IMapVersionRequest;
      const AMapTypeHybr: IMapType;
      const AMapTypeHybrVersion: IMapVersionRequest;
      const AMapTypeActiveMapsSet: IMapTypeListStatic;
      const AUsePrevZoomAtMap: Boolean;
      const AUsePrevZoomAtLayers: Boolean
    );
  end;

implementation

uses
  GR32,
  u_BitmapFunc,
  u_Bitmap32ByStaticBitmap;

{ TBitmapLayerProviderMapWithLayer }

constructor TBitmapLayerProviderMapWithLayer.Create(
  const ABitmap32StaticFactory: IBitmap32StaticFactory;
  const AMapTypeMain: IMapType;
  const AMapTypeMainVersion: IMapVersionRequest;
  const AMapTypeHybr: IMapType;
  const AMapTypeHybrVersion: IMapVersionRequest;
  const AMapTypeActiveMapsSet: IMapTypeListStatic;
  const AUsePrevZoomAtMap: Boolean;
  const AUsePrevZoomAtLayers: Boolean
);
var
  I, J: Integer;
begin
  Assert(Assigned(ABitmap32StaticFactory));

  if Assigned(AMapTypeActiveMapsSet) then begin
    Assert(not Assigned(AMapTypeHybr));
  end;

  inherited Create;

  FBitmap32StaticFactory := ABitmap32StaticFactory;

  I := 2;
  if Assigned(AMapTypeActiveMapsSet) then begin
    Inc(I, AMapTypeActiveMapsSet.Count);
  end;

  SetLength(FMapTypeArray, I);

  I := 0;

  FMapTypeArray[I].FMapType := AMapTypeMain;
  FMapTypeArray[I].FVersion := AMapTypeMainVersion;
  Inc(I);

  FMapTypeArray[I].FMapType := AMapTypeHybr;
  FMapTypeArray[I].FVersion := AMapTypeHybrVersion;
  Inc(I);

  if Assigned(AMapTypeActiveMapsSet) then begin
    for J := 0 to AMapTypeActiveMapsSet.Count - 1 do begin
      FMapTypeArray[I].FMapType := AMapTypeActiveMapsSet.Items[J];
      FMapTypeArray[I].FVersion := AMapTypeActiveMapsSet.Items[J].VersionRequest.GetStatic;
      Inc(I);
    end;
  end;

  FUsePrevZoomAtMap := AUsePrevZoomAtMap;
  FUsePrevZoomAtLayers := AUsePrevZoomAtLayers;
end;

function TBitmapLayerProviderMapWithLayer.GetUni(
  AOperationID: Integer;
  const ACancelNotifier: INotifierOperation;
  const AProjection: IProjection;
  const AUniType: TUniType;
  const ATile: TPoint;
  const APixelRectTarget: TRect
): IBitmap32Static;
var
  I: Integer;
  VResult: IBitmap32Static;
  VBitmap: TBitmap32ByStaticBitmap;
  VUsePrevZoom: Boolean;
begin
  Result := nil;

  for I := 0 to Length(FMapTypeArray) - 1 do begin
    VResult := nil;

    if FMapTypeArray[I].FMapType <> nil then begin

      if FMapTypeArray[I].FMapType.Zmp.IsLayer then begin
        VUsePrevZoom := FUsePrevZoomAtLayers;
      end else begin
        VUsePrevZoom := FUsePrevZoomAtMap;
      end;

      case AUniType of
        uniTile: begin
          VResult :=
            FMapTypeArray[I].FMapType.LoadTileUni(
              ATile,
              AProjection,
              FMapTypeArray[I].FVersion,
              VUsePrevZoom,
              True,
              True
            );
        end;

        uniBitmap: begin
          VResult :=
            FMapTypeArray[I].FMapType.LoadBitmapUni(
              APixelRectTarget,
              AProjection,
              FMapTypeArray[I].FVersion,
              VUsePrevZoom,
              True,
              True
            );
        end;
      else
        Assert(False, 'Unknown uni type!');
      end;
    end;

    if Result <> nil then begin
      if VResult <> nil then begin
        VBitmap := TBitmap32ByStaticBitmap.Create(FBitmap32StaticFactory);
        try
          AssignStaticToBitmap32(VBitmap, Result);
          BlockTransferFull(
            VBitmap,
            0, 0,
            VResult,
            dmBlend
          );
          Result := VBitmap.MakeAndClear;
        finally
          VBitmap.Free;
        end;
      end;
    end else begin
      Result := VResult;
    end;
  end;
end;

function TBitmapLayerProviderMapWithLayer.GetBitmap(
  AOperationID: Integer;
  const ACancelNotifier: INotifierOperation;
  const AProjection: IProjection;
  const APixelRectTarget: TRect
): IBitmap32Static;
begin
  Result := GetUni(
    AOperationID,
    ACancelNotifier,
    AProjection,
    uniBitmap,
    Types.Point(0, 0),
    APixelRectTarget
  );
end;

function TBitmapLayerProviderMapWithLayer.GetTile(
  AOperationID: Integer;
  const ACancelNotifier: INotifierOperation;
  const AProjection: IProjection;
  const ATile: TPoint
): IBitmap32Static;
begin
  Result := GetUni(
    AOperationID,
    ACancelNotifier,
    AProjection,
    uniTile,
    ATile,
    Types.Rect(0, 0, 0, 0)
  );
end;

end.

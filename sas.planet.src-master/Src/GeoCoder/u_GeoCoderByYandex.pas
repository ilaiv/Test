{******************************************************************************}
{* SAS.Planet (SAS.�������)                                                   *}
{* Copyright (C) 2007-2019, SAS.Planet development team.                      *}
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

unit u_GeoCoderByYandex;

interface

uses
  Classes,
  i_InterfaceListSimple,
  i_NotifierOperation,
  i_LocalCoordConverter,
  i_DownloadRequest,
  i_DownloadResult,
  u_GeoCoderBasic;

type
  TGeoCoderByYandex = class(TGeoCoderBasic)
  protected
    function PrepareRequest(
      const ASearch: string;
      const ALocalConverter: ILocalCoordConverter
    ): IDownloadRequest; override;
    function ParseResultToPlacemarksList(
      const ACancelNotifier: INotifierOperation;
      AOperationID: Integer;
      const AResult: IDownloadResultOk;
      const ASearch: string;
      const ALocalConverter: ILocalCoordConverter
    ): IInterfaceListSimple; override;
  end;

const
  cYandexApiKeyFileName = 'YandexApiKey.txt';

implementation

uses
  SysUtils,
  superobject,
  t_GeoTypes,
  i_GeoCoder,
  i_Projection,
  i_VectorDataItemSimple,
  u_InterfaceListSimple,
  u_GeoToStrFunc,
  u_ResStrings;

resourcestring
  // https://tech.yandex.ru/maps/doc/geocoder/desc/concepts/input_params-docpage/
  rsYandexSearchLanguage = 'en_US'; // ru_RU, uk_UA, be_BY, en_RU, en_US, tr_TR

{ TGeoCoderByYandex }

function TGeoCoderByYandex.ParseResultToPlacemarksList(
  const ACancelNotifier: INotifierOperation;
  AOperationID: Integer;
  const AResult: IDownloadResultOk;
  const ASearch: string;
  const ALocalConverter: ILocalCoordConverter
): IInterfaceListSimple;

  function _PosToPoint(const APos: string): TDoublePoint; // "27.560573 53.865552"
  var
    I: Integer;
    VLat, VLon: string;
    VFormatSettings: TFormatSettings;
  begin
    I := Pos(' ', APos);
    if I > 0 then begin
      VLon := Copy(APos, 0, I - 1);
      VLat := Copy(APos, I + 1, Length(APos) - I);
    end else begin
      raise EParserError.CreateFmt('Can''t parse coordinates from string: "%s"', [APos]);
    end;
    VFormatSettings.DecimalSeparator := '.';
    try
      Result.Y := StrToFloat(VLat, VFormatSettings);
      Result.X := StrToFloat(VLon, VFormatSettings);
    except
      raise EParserError.CreateFmt(SAS_ERR_CoordParseError, [VLat, VLon]);
    end;
  end;

var
  I: Integer;
  VTmpBuf: UTF8String;
  VPoint: TDoublePoint;
  VPlace: IVectorDataItem;
  VList: IInterfaceListSimple;
  VJsonObject: ISuperObject;
  VJsonArray: TSuperArray;
  VResultItem: ISuperObject;
  VName, VDescription: string;
begin
  if AResult.Data.Size <= 0 then begin
    raise EParserError.Create(SAS_ERR_EmptyServerResponse);
  end;

  VList := TInterfaceListSimple.Create;

  SetLength(VTmpBuf, AResult.Data.Size);
  Move(AResult.Data.Buffer^, VTmpBuf[1], AResult.Data.Size);

  VJsonObject := SO(Utf8ToAnsi(VTmpBuf));

  if not Assigned(VJsonObject) then begin
    raise EParserError.Create('JSON parser error');
  end;

  VJsonArray := VJsonObject.A['response.GeoObjectCollection.featureMember'];
  if Assigned(VJsonArray) then begin
    for I := 0 to VJsonArray.Length - 1 do begin
      VResultItem := VJsonArray.O[I];
      Assert(VResultItem <> nil);
      VName := VResultItem.S['GeoObject.name'];
      VDescription := VResultItem.S['GeoObject.description'];
      VPoint := _PosToPoint(VResultItem.S['GeoObject.Point.pos']);
      VPlace := PlacemarkFactory.Build(VPoint, VName, VDescription, '', 4);
      VList.Add(VPlace);
    end;
  end;

  Result := VList;
end;

function TGeoCoderByYandex.PrepareRequest(
  const ASearch: string;
  const ALocalConverter: ILocalCoordConverter
): IDownloadRequest;
var
  VSearch: string;
  VProjection: IProjection;
  VMapRect: TDoubleRect;
  VLonLatRect: TDoubleRect;
begin
  VSearch := StringReplace(ASearch, ' ', '+', [rfReplaceAll]);
  VProjection := ALocalConverter.Projection;
  VMapRect := ALocalConverter.GetRectInMapPixelFloat;
  VProjection.ValidatePixelRectFloat(VMapRect);
  VLonLatRect := VProjection.PixelRectFloat2LonLatRect(VMapRect);

  // http://api.yandex.ru/maps/doc/geocoder/desc/concepts/input_params.xml
  Result :=
    PrepareRequestByURL(
      'https://geocode-maps.yandex.ru/1.x/?' +
      'apikey=' + AnsiString(FApiKey) +
      '&geocode=' + URLEncode(Utf8Encode(ASearch)) +
      '&ll=' + R2AnsiStrPoint(ALocalConverter.GetCenterLonLat.x) + ',' + R2AnsiStrPoint(ALocalConverter.GetCenterLonLat.y) +
      '&spn=' + R2AnsiStrPoint(VLonLatRect.Right - VLonLatRect.Left) + ',' + R2AnsiStrPoint(VLonLatRect.Top - VLonLatRect.Bottom) +
      '&format=json' +
      '&results=15' +
      '&lang=' + AnsiString(rsYandexSearchLanguage)
    );
end;

end.

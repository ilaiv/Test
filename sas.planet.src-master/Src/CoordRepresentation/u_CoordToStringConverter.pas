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

unit u_CoordToStringConverter;

interface

uses
  SysUtils,
  t_GeoTypes,
  t_CoordRepresentation,
  i_CoordToStringConverter,
  u_BaseInterfacedObject;

type
  TCoordToStringConverter = class(TBaseInterfacedObject, ICoordToStringConverter)
  private
    FIsLatitudeFirst: Boolean;
    FDegrShowFormat: TDegrShowFormat;
    FCoordSysType: TCoordSysType;
    FCoordSysInfoType: TCoordSysInfoType;
    FEastMarker: string;
    FWestMarker: string;
    FNorthMarker: string;
    FSouthMarker: string;
    FFormatSettings: TFormatSettings;
  private
    function FloatToStr(const AFormat: string; const AValue: Double): string; inline;
    function DegrToStr(
      const ADegr: Double;
      const ACutZero: Boolean
    ): string;
    function GetLatitudeMarker(const ADegr: Double): string;
    function GetLongitudeMarker(const ADegr: Double): string;
  private
    function GetCoordSysInfo(
      const ALonLat: TDoublePoint
    ): string;
    function LonLatConvert(
      const ALonLat: TDoublePoint
    ): string; overload;
    procedure LonLatConvert(
      const ALon: Double;
      const ALat: Double;
      const ACutZero: Boolean;
      out ALonStr: string;
      out ALatStr: string
    ); overload;
  public
    constructor Create(
      const AIsLatitudeFirst: Boolean;
      const ADegrShowFormat: TDegrShowFormat;
      const ACoordSysType: TCoordSysType;
      const ACoordSysInfoType: TCoordSysInfoType
    );
  end;

implementation

uses
  Math,
  StrUtils,
  Proj4SK42,
  u_ResStrings;

{ TCoordToStringConverter }

constructor TCoordToStringConverter.Create(
  const AIsLatitudeFirst: Boolean;
  const ADegrShowFormat: TDegrShowFormat;
  const ACoordSysType: TCoordSysType;
  const ACoordSysInfoType: TCoordSysInfoType
);
begin
  inherited Create;
  FIsLatitudeFirst := AIsLatitudeFirst;
  FDegrShowFormat := ADegrShowFormat;
  FCoordSysType := ACoordSysType;
  FCoordSysInfoType := ACoordSysInfoType;
  FNorthMarker := 'N';
  FEastMarker := 'E';
  FWestMarker := 'W';
  FSouthMarker := 'S';
  FFormatSettings.DecimalSeparator := '.';
end;

function TCoordToStringConverter.FloatToStr(
  const AFormat: string;
  const AValue: Double
): string;
begin
  Result := FormatFloat(AFormat, AValue, FFormatSettings);
end;

function TCoordToStringConverter.DegrToStr(
  const ADegr: Double;
  const ACutZero: Boolean
): string;
var
  VDegr: Double;
  VInt: Int64;
  VValue: Int64;
begin
  Result := '';
  VDegr := Abs(ADegr);
  case FDegrShowFormat of

    dshCharDegrMinSec, dshSignDegrMinSec: begin
      VValue := Trunc(VDegr * 60 * 60 * 10000 + 0.005);
      VInt := Trunc(VValue / (60 * 60 * 10000));
      VValue := VValue - VInt * (60 * 60 * 10000);
      Result := IntToStr(VInt) + '�';
      VInt := Trunc(VValue / (60 * 10000));
      VValue := VValue - VInt * (60 * 10000);

      if VInt < 10 then begin
        Result := Result + '0' + IntToStr(VInt) + '''';
      end else begin
        Result := Result + IntToStr(VInt) + '''';
      end;

      Result := Result + FloatToStr('00.0000', VValue / 10000) + '"';

      if ACutZero then begin
        if Copy(Result, Length(Result) - 3, 4) = '.00"' then begin // X12�30'45.00" -> X12�30'45"
          Result := ReplaceStr(Result, '.00"', '"');
          if Copy(Result, Length(Result) - 2, 3) = '00"' then begin   // X12�30'00" -> X12�30'
            Result := ReplaceStr(Result, '00"', '');
            if Copy(Result, Length(Result) - 2, 3) = '00''' then begin  // X12�00' -> X12�
              Result := ReplaceStr(Result, '00''', '');
            end;
          end;
        end;
      end;
    end;

    dshCharDegrMin, dshSignDegrMin: begin
      VValue := Trunc(VDegr * 60 * 1000000 + 0.00005);
      VInt := Trunc(VValue / (60 * 1000000));
      VValue := VValue - VInt * (60 * 1000000);
      Result := IntToStr(VInt) + '�';
      Result := Result + FloatToStr('00.000000', VValue / 1000000) + '''';
      if ACutZero then begin
        while Copy(Result, Length(Result) - 1, 2) = '0''' do begin
          Result := ReplaceStr(Result, '0''', '''');
        end;   // 12�34.50000' -> 12�34.5'   12�00.00000' -> 12�00.'
        if Copy(Result, Length(Result) - 1, 2) = '.''' then begin
          Result := ReplaceStr(Result, '.''', '''');
        end; // 12�40,' -> 12�40'
        if Copy(Result, Length(Result) - 2, 3) = '00''' then begin
          Result := ReplaceStr(Result, '00''', '');
        end; //  12�00' -> 12�
      end;
    end;

    dshCharDegr, dshSignDegr: begin
      Result := FloatToStr('0.00000000', VDegr) + '�';
      if ACutZero then begin
        // 12.3450000� -> 12.345�
        while Copy(Result, Length(Result) - 1, 2) = '0�' do begin
          Result := ReplaceStr(Result, '0�', '�');
        end;
        // 12.� -> 12�
        if Copy(Result, Length(Result) - 1, 2) = '.�' then begin
          Result := ReplaceStr(Result, '.�', '�');
        end;
      end;
    end;
  else
    raise Exception.CreateFmt(
      'Unexpected degree format value: %d', [Integer(FDegrShowFormat)]
    );
  end;
end;

function TCoordToStringConverter.GetLatitudeMarker(const ADegr: Double): string;
begin
  case FDegrShowFormat of
    dshCharDegrMinSec, dshCharDegrMin, dshCharDegr: begin
      if ADegr > 0 then begin
        Result := FNorthMarker;
      end else if ADegr < 0 then begin
        Result := FSouthMarker;
      end else begin
        Result := '';
      end;
    end;
    dshSignDegrMinSec, dshSignDegrMin, dshSignDegr: begin
      if ADegr >= 0 then begin
        Result := '';
      end else begin
        Result := '-';
      end;
    end;
  end;
end;

function TCoordToStringConverter.GetLongitudeMarker(const ADegr: Double): string;
begin
  case FDegrShowFormat of
    dshCharDegrMinSec, dshCharDegrMin, dshCharDegr: begin
      if ADegr > 0 then begin
        Result := FEastMarker;
      end else if ADegr < 0 then begin
        Result := FWestMarker;
      end else begin
        Result := '';
      end;
    end;
    dshSignDegrMinSec, dshSignDegrMin, dshSignDegr: begin
      if ADegr >= 0 then begin
        Result := '';
      end else begin
        Result := '-';
      end;
    end;
  end;
end;

function TCoordToStringConverter.GetCoordSysInfo(
  const ALonLat: TDoublePoint
): string;
begin
  Result := '';
  if FCoordSysInfoType <> csitDontShow then begin
    case FCoordSysType of
      cstWGS84: begin
        if FCoordSysInfoType <> csitShowExceptWGS84 then begin
          Result := 'GEO (WGS84)';
        end;
      end;
      cstSK42: begin
        Result := 'GEO (S-42)';
      end;
      cstSK42GK: begin
        Result := Format('GK%d (S-42) ', [long_to_gauss_kruger_zone(ALonLat.X)]);
      end
    else
      Assert(False, 'Unknown CoordSysType: ' + IntToStr(Integer(FCoordSysType)));
    end;
  end;
end;

function TCoordToStringConverter.LonLatConvert(
  const ALonLat: TDoublePoint
): string;
var
  VLatStr: string;
  VLonStr: string;
begin
  LonLatConvert(ALonLat.X, ALonLat.Y, False, VLonStr, VLatStr);
  if FIsLatitudeFirst and (FCoordSysType in [cstWGS84, cstSK42]) then begin
    Result := VLatStr + ' ' + VLonStr;
  end else begin
    Result := VLonStr + ' ' + VLatStr;
  end;
end;

procedure TCoordToStringConverter.LonLatConvert(
  const ALon: Double;
  const ALat: Double;
  const ACutZero: Boolean;
  out ALonStr: string;
  out ALatStr: string
);

  procedure _GeodeticCoordToStr(const ALonLat: TDoublePoint; out ALon, ALat: string);
  begin
    ALon := GetLongitudeMarker(ALonLat.X) + DegrToStr(ALonLat.X, ACutZero);
    ALat := GetLatitudeMarker(ALonLat.Y) + DegrToStr(ALonLat.Y, ACutZero);
  end;

  procedure _ProjectedCoordToStr(const AXY: TDoublePoint; out AX, AY: string);
  begin
    AX := FloatToStr('0.00', AXY.X);
    AY := FloatToStr('0.00', AXY.Y);
  end;

var
  VPoint: TDoublePoint;
  VLonLat: TDoublePoint;
begin
  ALonStr := 'NaN';
  ALatStr := 'NaN';
  VLonLat.X := ALon;
  VLonLat.Y := ALat;
  case FCoordSysType of
    cstWGS84: begin
      _GeodeticCoordToStr(VLonLat, ALonStr, ALatStr);
    end;
    cstSK42: begin
      if geodetic_wgs84_to_sk42(VLonLat.X, VLonLat.Y) then begin
        _GeodeticCoordToStr(VLonLat, ALonStr, ALatStr);
      end;
    end;
    cstSK42GK: begin
      if geodetic_wgs84_to_gauss_kruger(VLonLat.X, VLonLat.Y, VPoint.X, VPoint.Y) then begin
        _ProjectedCoordToStr(VPoint, ALatStr, ALonStr); // !
      end;
    end;
  end;
end;

end.

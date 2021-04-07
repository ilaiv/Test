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

unit u_ProjectionTypeFactorySimple;

interface

uses
  i_Datum,
  i_DatumFactory,
  i_HashFunction,
  i_ProjectionType,
  i_ConfigDataProvider,
  i_ProjectionTypeFactory,
  u_BaseInterfacedObject;

type
  TProjectionTypeFactorySimple = class(TBaseInterfacedObject, IProjectionTypeFactory)
  private
    FHashFunction: IHashFunction;
    FDatumFactory: IDatumFactory;

    FGoogle: IProjectionType;
    FYandex: IProjectionType;
    FLonLat: IProjectionType;
    FEPSG53004: IProjectionType;
  private
    function GetByConfig(const AConfig: IConfigDataProvider): IProjectionType;
    function GetByCode(
      AProjectionEPSG: Integer
    ): IProjectionType;
  public
    constructor Create(
      const AHashFunction: IHashFunction;
      const ADatumFactory: IDatumFactory
    );
  end;

implementation

uses
  SysUtils,
  t_Hash,
  c_CoordConverter,
  u_ProjectionTypeMercatorOnSphere,
  u_ProjectionTypeMercatorOnEllipsoid,
  u_ProjectionTypeGELonLat,
  u_ResStrings;

{ TProjectionTypeFactorySimple }

constructor TProjectionTypeFactorySimple.Create(
  const AHashFunction: IHashFunction;
  const ADatumFactory: IDatumFactory
);
var
  VHash: THashValue;
  VDatum: IDatum;
begin
  inherited Create;
  FHashFunction := AHashFunction;
  FDatumFactory := ADatumFactory;

  VHash := FHashFunction.CalcHashByInteger(1);
  VDatum := FDatumFactory.GetByCode(CGoogleDatumEPSG);
  FHashFunction.UpdateHashByHash(VHash, VDatum.Hash);
  FHashFunction.UpdateHashByInteger(VHash, CGoogleProjectionEPSG);
  FGoogle := TProjectionTypeMercatorOnSphere.Create(VHash, VDatum, CGoogleProjectionEPSG);

  VHash := FHashFunction.CalcHashByInteger(1);
  VDatum := FDatumFactory.GetByCode(53004);
  FHashFunction.UpdateHashByHash(VHash, VDatum.Hash);
  FHashFunction.UpdateHashByInteger(VHash, 53004);
  FEPSG53004 := TProjectionTypeMercatorOnSphere.Create(VHash, VDatum, 53004);

  VHash := FHashFunction.CalcHashByInteger(2);
  VDatum := FDatumFactory.GetByCode(CYandexDatumEPSG);
  FHashFunction.UpdateHashByHash(VHash, VDatum.Hash);
  FHashFunction.UpdateHashByInteger(VHash, CYandexProjectionEPSG);
  FYandex := TProjectionTypeMercatorOnEllipsoid.Create(VHash, VDatum, CYandexProjectionEPSG);

  VHash := FHashFunction.CalcHashByInteger(3);
  VDatum := FDatumFactory.GetByCode(CYandexDatumEPSG);
  FHashFunction.UpdateHashByHash(VHash, VDatum.Hash);
  FHashFunction.UpdateHashByInteger(VHash, CGELonLatProjectionEPSG);
  FLonLat := TProjectionTypeGELonLat.Create(VHash, VDatum, CGELonLatProjectionEPSG);
end;

function TProjectionTypeFactorySimple.GetByCode(
  AProjectionEPSG: Integer
): IProjectionType;
begin
  Result := nil;
  case AProjectionEPSG of
    CGoogleProjectionEPSG: begin
      Result := FGoogle;
    end;
    53004: begin
      Result := FEPSG53004;
    end;
    CYandexProjectionEPSG: begin
      Result := FYandex;
    end;
    CGELonLatProjectionEPSG: begin
      Result := FLonLat;
    end;
  else begin
    raise Exception.CreateFmt(SAS_ERR_MapProjectionUnexpectedType, [IntToStr(AProjectionEPSG)]);
  end;
  end;
end;

function TProjectionTypeFactorySimple.GetByConfig(
  const AConfig: IConfigDataProvider
): IProjectionType;
var
  VProjection: byte;
  VRadiusA: Double;
  VRadiusB: Double;
  VEPSG: Integer;
  VDatum: IDatum;
  VHash: THashValue;
begin
  Result := nil;
  VEPSG := 0;
  VProjection := 1;
  VRadiusA := 6378137;
  VRadiusB := VRadiusA;

  if AConfig <> nil then begin
    VEPSG := AConfig.ReadInteger('EPSG', VEPSG);
    VProjection := AConfig.ReadInteger('projection', VProjection);
    VRadiusA := AConfig.ReadFloat('sradiusa', VRadiusA);
    VRadiusB := AConfig.ReadFloat('sradiusb', VRadiusA);
  end;

  if VEPSG = 0 then begin
    case VProjection of
      1: begin
        if Abs(VRadiusA - 6378137) < 1 then begin
          VEPSG := CGoogleProjectionEPSG;
        end else if Abs(VRadiusA - 6371000) < 1 then begin
          VEPSG := 53004;
        end;
      end;
      2: begin
        if (Abs(VRadiusA - 6378137) < 1) and (Abs(VRadiusB - 6356752) < 1) then begin
          VEPSG := CYandexProjectionEPSG;
        end;
      end;
      3: begin
        if (Abs(VRadiusA - 6378137) < 1) and (Abs(VRadiusB - 6356752) < 1) then begin
          VEPSG := CGELonLatProjectionEPSG;
        end;
      end else begin
      raise Exception.CreateFmt(SAS_ERR_MapProjectionUnexpectedType, [IntToStr(VProjection)]);
    end;
    end;
  end;

  if VEPSG <> 0 then begin
    try
      Result := GetByCode(VEPSG);
    except
      Result := nil;
    end;
  end;

  if Result = nil then begin
    case VProjection of
      1: begin
        VDatum := FDatumFactory.GetByRadius(VRadiusA, VRadiusA);
        if VDatum.EPSG = CGoogleDatumEPSG then begin
          Result := FGoogle;
        end else if VDatum.EPSG = 53004 then begin
          Result := FEPSG53004;
        end else begin
          VHash := FHashFunction.CalcHashByInteger(1);
          FHashFunction.UpdateHashByHash(VHash, VDatum.Hash);
          FHashFunction.UpdateHashByInteger(VHash, 0);
          Result := TProjectionTypeMercatorOnSphere.Create(VHash, VDatum, 0);
        end;
      end;
      2: begin
        VDatum := FDatumFactory.GetByRadius(VRadiusA, VRadiusB);
        if VDatum.EPSG = CYandexDatumEPSG then begin
          Result := FYandex;
        end else begin
          VHash := FHashFunction.CalcHashByInteger(2);
          FHashFunction.UpdateHashByHash(VHash, VDatum.Hash);
          FHashFunction.UpdateHashByInteger(VHash, 0);
          Result := TProjectionTypeMercatorOnEllipsoid.Create(VHash, VDatum, 0);
        end;
      end;
      3: begin
        VDatum := FDatumFactory.GetByRadius(VRadiusA, VRadiusB);
        if VDatum.EPSG = CYandexDatumEPSG then begin
          Result := FLonLat;
        end else begin
          VHash := FHashFunction.CalcHashByInteger(3);
          FHashFunction.UpdateHashByHash(VHash, VDatum.Hash);
          FHashFunction.UpdateHashByInteger(VHash, 0);
          Result := TProjectionTypeGELonLat.Create(VHash, VDatum, 0);
        end;
      end;
    else begin
      raise Exception.CreateFmt(SAS_ERR_MapProjectionUnexpectedType, [IntToStr(VProjection)]);
    end;
    end;
  end;
end;

end.

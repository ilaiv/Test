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

unit u_DownloadSession;

interface

uses
  Types,
  i_GeometryLonLat,
  i_GeometryLonLatFactory,
  i_MapType,
  i_MapTypeSet,
  i_MapVersionInfo,
  i_MapVersionRequest,
  i_GlobalDownloadConfig,
  i_ConfigDataProvider,
  i_ConfigDataWriteProvider,
  i_DownloadSession,
  u_BaseInterfacedObject;

type
  TDownloadSession = class(TBaseInterfacedObject, IDownloadSession)
  private
    FZoom: Byte;
    FZoomArr: TByteDynArray;
    FMapType: IMapType;
    FPolygon: IGeometryLonLatPolygon;
    FVersionForCheck: IMapVersionRequest;
    FVersionForDownload: IMapVersionInfo;
    FSecondLoadTNE: Boolean;
    FReplaceTneOlderDate: TDateTime;
    FReplaceExistTiles: Boolean;
    FCheckExistTileSize: Boolean;
    FCheckExistTileDate: Boolean;
    FCheckTileDate: TDateTime;
    FElapsedTime: TDateTime;
    FProcessed: Int64;
    FProcessedFromLastSuccessfulPoint: Int64;
    FDownloadedSize: UInt64;
    FDownloadedCount: Int64;
    FLastProcessedPoint: TPoint;
    FLastProcessedCount: Int64;
    FLastSuccessfulPoint: TPoint;
    FAutoCloseAtFinish: Boolean;
    FAutoSaveInterval: Integer;
    FAutosavePrefix: string;
    FWorkersCount: Integer;
    FWorkerIndex: Integer;
  private
    procedure _InitSession;
  private
    function GetMapType: IMapType;
    function GetVersionForCheck: IMapVersionRequest;
    function GetCheckExistTileDate: Boolean;
    function GetCheckExistTileSize: Boolean;
    function GetCheckTileDate: TDateTime;
    function GetDownloadedCount: Int64;
    function GetDownloadedSize: UInt64;
    function GetElapsedTime: TDateTime;
    function GetLastProcessedPoint: TPoint;
    function GetPolygon: IGeometryLonLatPolygon;
    function GetReplaceExistTiles: Boolean;
    function GetReplaceTneOlderDate: TDateTime;
    function GetSecondLoadTNE: Boolean;
    function GetVersionForDownload: IMapVersionInfo;
    function GetZoom: Byte;
    function GetZoomArr: TByteDynArray;
    function GetLastSuccessfulPoint: TPoint;
    function GetLastProcessedCount: Int64;
    function GetProcessed: Int64;
    function GetAutoCloseAtFinish: Boolean;
    function GetAutoSaveInterval: Integer;
    function GetAutosavePrefix: string;
    function GetWorkersCount: Integer;
    function GetWorkerIndex: Integer;

    procedure SetZoom(const Value: Byte);
    procedure SetLastSuccessfulPoint(const Value: TPoint);
    procedure SetProcessed(const Value: Int64);
    procedure SetDownloadedCount(const Value: Int64);
    procedure SetDownloadedSize(const Value: UInt64);
    procedure SetElapsedTime(const Value: TDateTime);
    procedure SetLastProcessedPoint(const Value: TPoint);
    procedure SetAutoCloseAtFinish(const Value: Boolean);
    procedure SetAutoSaveInterval(const AValue: Integer);
    procedure SetAutosavePrefix(const AValue: string);

    procedure Save(
      const ASessionSection: IConfigDataWriteProvider
    );

    procedure Load(
      const ASessionSection: IConfigDataProvider;
      const AFullMapsSet: IMapTypeSet;
      const ADownloadConfig: IGlobalDownloadConfig;
      const AVectorGeometryLonLatFactory: IGeometryLonLatFactory
    );
  public
    constructor Create(
      const AMapType: IMapType;
      const AVersionForCheck: IMapVersionRequest;
      const AVersionForDownload: IMapVersionInfo;
      const AZoom: Byte;
      const AZoomArr: TByteDynArray;
      const APolygon: IGeometryLonLatPolygon;
      const ASecondLoadTNE: Boolean;
      const AReplaceTneOlderDate: TDateTime;
      const AReplaceExistTiles: Boolean;
      const ACheckExistTileSize: Boolean;
      const ACheckExistTileDate: Boolean;
      const ACheckTileDate: TDateTime;
      const AAutoCloseAtFinish: Boolean;
      const AAutoSaveInterval: Integer;
      const AAutosavePrefix: string;
      const AWorkersCount: Integer;
      const AWorkerIndex: Integer
    ); overload;

    constructor Create; overload;
  end;

implementation

uses
  Math,
  SysUtils,
  c_ZeroGUID,
  i_ProjectionSet,
  u_MapVersionRequest,
  u_ConfigProviderHelpers,
  u_GeoFunc,
  u_ZoomArrayFunc;

{ TDownloadSession }

constructor TDownloadSession.Create;
begin
  inherited Create;
  _InitSession;
end;

constructor TDownloadSession.Create(
  const AMapType: IMapType;
  const AVersionForCheck: IMapVersionRequest;
  const AVersionForDownload: IMapVersionInfo;
  const AZoom: Byte;
  const AZoomArr: TByteDynArray;
  const APolygon: IGeometryLonLatPolygon;
  const ASecondLoadTNE: Boolean;
  const AReplaceTneOlderDate: TDateTime;
  const AReplaceExistTiles, ACheckExistTileSize, ACheckExistTileDate: Boolean;
  const ACheckTileDate: TDateTime;
  const AAutoCloseAtFinish: Boolean;
  const AAutoSaveInterval: Integer;
  const AAutosavePrefix: string;
  const AWorkersCount: Integer;
  const AWorkerIndex: Integer
);
begin
  inherited Create;
  _InitSession;

  FMapType := AMapType;
  FVersionForCheck := AVersionForCheck;
  FVersionForDownload := AVersionForDownload;
  FZoom := AZoom;
  FZoomArr := GetZoomArrayCopy(AZoomArr);
  FReplaceExistTiles := AReplaceExistTiles;
  FCheckExistTileSize := ACheckExistTileSize;
  FCheckExistTileDate := ACheckExistTileDate;
  FCheckTileDate := ACheckTileDate;
  FSecondLoadTNE := ASecondLoadTNE;
  FReplaceTneOlderDate := AReplaceTneOlderDate;
  FPolygon := APolygon;
  FWorkersCount := AWorkersCount;
  FWorkerIndex := AWorkerIndex;
  FAutoCloseAtFinish := AAutoCloseAtFinish;
  FAutoSaveInterval := AAutoSaveInterval;
  FAutosavePrefix := AAutosavePrefix;
end;

procedure TDownloadSession._InitSession;
begin
  FMapType := nil;
  FVersionForCheck := nil;
  FVersionForDownload := nil;
  FZoom := 0;
  SetLength(FZoomArr, 0);
  FPolygon := nil;
  FSecondLoadTNE := False;
  FReplaceTneOlderDate := NaN;
  FReplaceExistTiles := False;
  FCheckExistTileSize := False;
  FCheckExistTileDate := False;
  FCheckTileDate := Now;
  FElapsedTime := 0;
  FProcessed := 0;
  FProcessedFromLastSuccessfulPoint := 0;
  FDownloadedSize := 0;
  FDownloadedCount := 0;
  FLastProcessedPoint := Point(-1, -1);
  FLastProcessedCount := 0;
  FLastSuccessfulPoint := Point(-1, -1);
  FAutoCloseAtFinish := False;
  FAutoSaveInterval := 0;
  FAutosavePrefix := '';
  FWorkerIndex := 0;
  FWorkersCount := 1;
end;

procedure TDownloadSession.Save(
  const ASessionSection: IConfigDataWriteProvider
);
var
  VVersionForCheck: string;
  VVersionForCheckUseOther: Boolean;
begin
  VVersionForCheck := '';
  VVersionForCheckUseOther := False;

  if Assigned(FVersionForCheck) then begin
    if Assigned(FVersionForCheck.BaseVersion) then begin
      VVersionForCheck := FVersionForCheck.BaseVersion.StoreString;
    end;
    VVersionForCheckUseOther := FVersionForCheck.ShowOtherVersions;
  end;

  if IsPointsEqual(FLastSuccessfulPoint, FLastProcessedPoint) then begin
    FProcessedFromLastSuccessfulPoint := 0;
  end;

  ASessionSection.WriteString('MapGUID', GUIDToString(FMapType.GUID));
  ASessionSection.WriteString('VersionDownload', FVersionForDownload.StoreString);
  ASessionSection.WriteString('VersionCheck', VVersionForCheck);
  ASessionSection.WriteBool('VersionCheckOther', VVersionForCheckUseOther);
  ASessionSection.WriteInteger('Zoom', FZoom + 1);
  ASessionSection.WriteString('ZoomArr', ZoomArrayToStr(FZoomArr));
  ASessionSection.WriteBool('ReplaceExistTiles', FReplaceExistTiles);
  ASessionSection.WriteBool('CheckExistTileSize', FCheckExistTileSize);
  ASessionSection.WriteBool('CheckExistTileDate', FCheckExistTileDate);
  ASessionSection.WriteDate('CheckTileDate', FCheckTileDate);
  ASessionSection.WriteBool('SecondLoadTNE', FSecondLoadTNE);

  if not IsNan(FReplaceTneOlderDate) then begin
    ASessionSection.WriteDate('LoadTneOlderDate', FReplaceTneOlderDate);
  end;

  ASessionSection.WriteInteger('ProcessedTileCount', FDownloadedCount);
  ASessionSection.WriteInteger('Processed', FProcessed);
  ASessionSection.WriteInteger('ProcessedFromLastSuccessfulPoint', FProcessedFromLastSuccessfulPoint);
  ASessionSection.WriteInteger('LastProcessedCount', FLastProcessedCount);
  ASessionSection.WriteFloat('ProcessedSize', FDownloadedSize / 1024);
  ASessionSection.WriteInteger('StartX', FLastProcessedPoint.X);
  ASessionSection.WriteInteger('StartY', FLastProcessedPoint.Y);
  ASessionSection.WriteInteger('LastSuccessfulStartX', FLastSuccessfulPoint.X);
  ASessionSection.WriteInteger('LastSuccessfulStartY', FLastSuccessfulPoint.Y);
  ASessionSection.WriteFloat('ElapsedTime', FElapsedTime);
  ASessionSection.WriteBool('AutoCloseAtFinish', FAutoCloseAtFinish);
  ASessionSection.WriteInteger('AutoSaveInterval', FAutoSaveInterval);
  ASessionSection.WriteString('AutoSavePrefix', FAutoSavePrefix);
  ASessionSection.WriteInteger('WorkersCount', FWorkersCount);
  ASessionSection.WriteInteger('WorkerIndex', FWorkerIndex);

  WritePolygon(ASessionSection, FPolygon);
end;

procedure TDownloadSession.Load(
  const ASessionSection: IConfigDataProvider;
  const AFullMapsSet: IMapTypeSet;
  const ADownloadConfig: IGlobalDownloadConfig;
  const AVectorGeometryLonLatFactory: IGeometryLonLatFactory
);

  procedure _CheckZoom(const AProjectionSet: IProjectionSet; var AZoom: Byte);
  begin
    if AZoom > 0 then begin
      Dec(AZoom);
    end else begin
      raise Exception.Create('Unknown zoom: ' + IntToStr(AZoom));
    end;
    if not AProjectionSet.CheckZoom(AZoom) then begin
      raise Exception.Create('Unknown zoom: ' + IntToStr(AZoom));
    end;
  end;

  procedure _ReadZoom(
    const AProjectionSet: IProjectionSet;
    const ASessionSection: IConfigDataProvider;
    out AZoom: Byte;
    out AZoomArr: TByteDynArray
  );
  var
    I: Integer;
  begin
    AZoom := ASessionSection.ReadInteger('Zoom', 0);
    _CheckZoom(AProjectionSet, AZoom);
    if not ZoomArrayFromStr(ASessionSection.ReadString('ZoomArr', ''), AZoomArr) then begin
      SetLength(AZoomArr, 1);
      AZoomArr[0] := AZoom + 1;
    end;
    for I := Low(AZoomArr) to High(AZoomArr) do begin
      _CheckZoom(AProjectionSet, AZoomArr[I]);
    end;
    Assert(IsZoomInZoomArray(AZoom, AZoomArr));
  end;

var
  VGuid: TGUID;
  VZoom: Byte;
  VZoomArr: TByteDynArray;
  VReplaceExistTiles: Boolean;
  VCheckExistTileSize: Boolean;
  VCheckExistTileDate: Boolean;
  VCheckTileDate: TDateTime;
  VProcessed: Int64;
  VProcessedFromLastSuccessfulPoint: Int64;
  VProcessedTileCount: Int64;
  VProcessedSize: Int64;
  VLastProcessedCount: Int64;
  VSecondLoadTNE: Boolean;
  VLoadTneOlderDate: TDateTime;
  VLastProcessedPoint: TPoint;
  VLastSuccessfulPoint: TPoint;
  VElapsedTime: TDateTime;
  VMapType: IMapType;
  VPolygon: IGeometryLonLatPolygon;
  VVersionForDownload: IMapVersionInfo;
  VVersionForCheck: IMapVersionRequest;
  VVersionString: string;
  VVersionCheckShowPrev: Boolean;
  VAutoCloseAtFinish: Boolean;
  VAutoSaveInterval: Integer;
  VAutosavePrefix: string;
  VWorkersCount: Integer;
  VWorkerIndex: Integer;
begin
  Assert(AFullMapsSet <> nil);
  Assert(ADownloadConfig <> nil);

  if ASessionSection = nil then begin
    raise Exception.Create('No SLS data');
  end;

  VGuid := ReadGUID(ASessionSection, 'MapGUID', CGUID_Zero);
  if IsEqualGUID(VGuid, CGUID_Zero) then begin
    raise Exception.Create('Map GUID is empty');
  end;

  VMapType := AFullMapsSet.GetMapTypeByGUID(VGuid);
  if VMapType = nil then begin
    raise Exception.CreateFmt('Map with GUID = %s not found', [GUIDToString(VGuid)]);
  end;

  VVersionString := ASessionSection.ReadString('VersionDownload', '');
  if VVersionString <> '' then begin
    VVersionForDownload :=
      VMapType.VersionFactory.GetStatic.CreateByStoreString(
        VVersionString
      );
  end else begin
    VVersionForDownload := VMapType.VersionRequest.GetStatic.BaseVersion;
  end;

  VVersionCheckShowPrev := ASessionSection.ReadBool('VersionCheckOther', False);
  VVersionString := ASessionSection.ReadString('VersionCheck', '');

  if VVersionString <> '' then begin
    VVersionForCheck :=
      TMapVersionRequest.Create(
        VMapType.VersionFactory.GetStatic.CreateByStoreString(VVersionString),
        VVersionCheckShowPrev
      );
  end else begin
    VVersionForCheck :=
      TMapVersionRequest.Create(
        VVersionForDownload,
        VVersionCheckShowPrev
      );
  end;

  _ReadZoom(VMapType.ProjectionSet, ASessionSection, VZoom, VZoomArr);

  VReplaceExistTiles := ASessionSection.ReadBool('ReplaceExistTiles', False);
  VCheckExistTileSize := ASessionSection.ReadBool('CheckExistTileSize', False);
  VCheckExistTileDate := ASessionSection.ReadBool('CheckExistTileDate', False);
  VCheckTileDate := ASessionSection.ReadDate('CheckTileDate', Now);
  VProcessed := ASessionSection.ReadInteger('Processed', 0);
  VProcessedFromLastSuccessfulPoint := ASessionSection.ReadInteger('ProcessedFromLastSuccessfulPoint', 0);
  VLastProcessedCount := ASessionSection.ReadInteger('LastProcessedCount', 0);
  VProcessedTileCount := ASessionSection.ReadInteger('ProcessedTileCount', 0);
  VProcessedSize := Trunc(ASessionSection.ReadFloat('ProcessedSize', 0) * 1024);
  VSecondLoadTNE := ASessionSection.ReadBool('SecondLoadTNE', False);
  VLoadTneOlderDate := ASessionSection.ReadDate('LoadTneOlderDate', NaN);
  VElapsedTime := ASessionSection.ReadFloat('ElapsedTime', 0);
  VAutoCloseAtFinish := ASessionSection.ReadBool('AutoCloseAtFinish', False);
  VAutoSaveInterval := ASessionSection.ReadInteger('AutoSaveInterval', 0);
  VAutoSavePrefix := ASessionSection.ReadString('AutoSavePrefix', '');
  VWorkersCount := ASessionSection.ReadInteger('WorkersCount', 1);
  VWorkerIndex := ASessionSection.ReadInteger('WorkerIndex', 0);

  VLastSuccessfulPoint.X := ASessionSection.ReadInteger('LastSuccessfulStartX', -1);
  VLastSuccessfulPoint.Y := ASessionSection.ReadInteger('LastSuccessfulStartY', -1);

  VLastProcessedPoint.X := ASessionSection.ReadInteger('StartX', -1);
  VLastProcessedPoint.Y := ASessionSection.ReadInteger('StartY', -1);

  if IsPointsEqual(VLastSuccessfulPoint, VLastProcessedPoint) then begin
    VProcessedFromLastSuccessfulPoint := 0;
  end;

  if ADownloadConfig.IsUseSessionLastSuccess then begin
    // rollback processed point to last successful point
    VLastProcessedPoint := VLastSuccessfulPoint;
    if (VProcessed > 0) and (VProcessedFromLastSuccessfulPoint > 0) then begin
      Dec(VProcessed, VProcessedFromLastSuccessfulPoint);
      Assert(VProcessed >= 0);
      Dec(VLastProcessedCount, VProcessedFromLastSuccessfulPoint);
      Assert(VLastProcessedCount >= 0);
      VProcessedFromLastSuccessfulPoint := 0;
    end;
  end;

  VPolygon := ReadPolygon(ASessionSection, AVectorGeometryLonLatFactory);
  if not Assigned(VPolygon) then begin
    raise Exception.Create('Empty polygon');
  end;

  FMapType := VMapType;

  FVersionForCheck := VVersionForCheck;
  FVersionForDownload := VVersionForDownload;

  FZoom := VZoom;
  FZoomArr := GetZoomArrayCopy(VZoomArr);

  FReplaceExistTiles := VReplaceExistTiles;
  FCheckExistTileSize := VCheckExistTileSize;
  FCheckExistTileDate := VCheckExistTileDate;
  FCheckTileDate := VCheckTileDate;
  FProcessed := VProcessed;
  FProcessedFromLastSuccessfulPoint := VProcessedFromLastSuccessfulPoint;
  FLastProcessedCount := VLastProcessedCount;
  FDownloadedCount := VProcessedTileCount;
  FDownloadedSize := VProcessedSize;

  FSecondLoadTNE := VSecondLoadTNE;
  FReplaceTneOlderDate := VLoadTneOlderDate;
  FElapsedTime := VElapsedTime;
  FAutoCloseAtFinish := VAutoCloseAtFinish;
  FAutoSaveInterval := VAutoSaveInterval;
  FAutosavePrefix := VAutosavePrefix;
  FWorkersCount := VWorkersCount;
  FWorkerIndex := VWorkerIndex;

  FLastProcessedPoint := VLastProcessedPoint;
  FLastSuccessfulPoint := VLastSuccessfulPoint;

  FPolygon := VPolygon;
end;

function TDownloadSession.GetAutoCloseAtFinish: Boolean;
begin
  Result := FAutoCloseAtFinish;
end;

function TDownloadSession.GetAutoSaveInterval: Integer;
begin
  Result := FAutoSaveInterval;
end;

function TDownloadSession.GetAutoSavePrefix: string;
begin
  Result := FAutosavePrefix;
end;

function TDownloadSession.GetCheckExistTileDate: Boolean;
begin
  Result := FCheckExistTileDate;
end;

function TDownloadSession.GetCheckExistTileSize: Boolean;
begin
  Result := FCheckExistTileSize;
end;

function TDownloadSession.GetCheckTileDate: TDateTime;
begin
  Result := FCheckTileDate;
end;

function TDownloadSession.GetDownloadedCount: Int64;
begin
  Result := FDownloadedCount;
end;

function TDownloadSession.GetDownloadedSize: UInt64;
begin
  Result := FDownloadedSize;
end;

function TDownloadSession.GetElapsedTime: TDateTime;
begin
  Result := FElapsedTime;
end;

function TDownloadSession.GetLastProcessedPoint: TPoint;
begin
  Result := FLastProcessedPoint;
end;

function TDownloadSession.GetLastSuccessfulPoint: TPoint;
begin
  Result := FLastSuccessfulPoint;
end;

function TDownloadSession.GetMapType: IMapType;
begin
  Result := FMapType;
end;

function TDownloadSession.GetPolygon: IGeometryLonLatPolygon;
begin
  Result := FPolygon;
end;

function TDownloadSession.GetProcessed: Int64;
begin
  Result := FProcessed;
end;

function TDownloadSession.GetLastProcessedCount: Int64;
begin
  Result := FLastProcessedCount;
end;

function TDownloadSession.GetReplaceExistTiles: Boolean;
begin
  Result := FReplaceExistTiles;
end;

function TDownloadSession.GetReplaceTneOlderDate: TDateTime;
begin
  Result := FReplaceTneOlderDate;
end;

function TDownloadSession.GetSecondLoadTNE: Boolean;
begin
  Result := FSecondLoadTNE;
end;

function TDownloadSession.GetVersionForCheck: IMapVersionRequest;
begin
  Result := FVersionForCheck;
end;

function TDownloadSession.GetVersionForDownload: IMapVersionInfo;
begin
  Result := FVersionForDownload;
end;

function TDownloadSession.GetWorkerIndex: Integer;
begin
  Result := FWorkerIndex;
end;

function TDownloadSession.GetWorkersCount: Integer;
begin
  Result := FWorkersCount;
end;

function TDownloadSession.GetZoom: Byte;
begin
  Result := FZoom;
end;

function TDownloadSession.GetZoomArr: TByteDynArray;
begin
  Result := GetZoomArrayCopy(FZoomArr);
end;

procedure TDownloadSession.SetAutoCloseAtFinish(const Value: Boolean);
begin
  FAutoCloseAtFinish := Value;
end;

procedure TDownloadSession.SetAutoSaveInterval(const AValue: Integer);
begin
  FAutoSaveInterval := AValue;
end;

procedure TDownloadSession.SetAutoSavePrefix(const AValue: string);
begin
  FAutoSavePrefix := AValue;
end;

procedure TDownloadSession.SetDownloadedCount(const Value: Int64);
begin
  FDownloadedCount := Value;
end;

procedure TDownloadSession.SetDownloadedSize(const Value: UInt64);
begin
  FDownloadedSize := Value;
end;

procedure TDownloadSession.SetElapsedTime(const Value: TDateTime);
begin
  FElapsedTime := Value;
end;

procedure TDownloadSession.SetLastProcessedPoint(const Value: TPoint);
begin
  FLastProcessedPoint := Value;
  if IsPointsEqual(FLastSuccessfulPoint, FLastProcessedPoint) then begin
    FProcessedFromLastSuccessfulPoint := 0;
  end else begin
    Inc(FProcessedFromLastSuccessfulPoint);
  end;
  Inc(FLastProcessedCount);
end;

procedure TDownloadSession.SetLastSuccessfulPoint(const Value: TPoint);
begin
  FLastSuccessfulPoint := Value;
  if IsPointsEqual(FLastSuccessfulPoint, FLastProcessedPoint) then begin
    FProcessedFromLastSuccessfulPoint := 0;
  end;
end;

procedure TDownloadSession.SetProcessed(const Value: Int64);
begin
  FProcessed := Value;
end;

procedure TDownloadSession.SetZoom(const Value: Byte);
begin
  if FZoom <> Value then begin
    FZoom := Value;
    FLastSuccessfulPoint := Point(-1, -1);
    FLastProcessedPoint := Point(-1, -1);
    FProcessedFromLastSuccessfulPoint := 0;
    FLastProcessedCount := 0;
  end;
end;

end.

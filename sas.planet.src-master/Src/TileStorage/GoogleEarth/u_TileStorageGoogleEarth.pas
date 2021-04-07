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

unit u_TileStorageGoogleEarth;

interface

uses
  Windows,
  SysUtils,
  libge,
  i_BinaryData,
  i_MapVersionInfo,
  i_MapVersionFactory,
  i_MapVersionListStatic,
  i_MapVersionRequest,
  i_ContentTypeInfo,
  i_TileInfoBasic,
  i_ProjectionSet,
  i_NotifierOperation,
  i_NotifierTilePyramidUpdate,
  i_TileStorageAbilities,
  i_TileStorage,
  i_TileInfoBasicMemCache,
  u_TileStorageAbstract;

type
  TTileStorageGoogleEarth = class(TTileStorageAbstract, IEnumTileInfo)
  private
    FCachePath: string;
    FDatabaseName: string;
    FIsTerrainStorage: Boolean;
    FIsGeoCacherStorage: Boolean;
    FMainContentType: IContentTypeInfoBasic;
    FTileNotExistsTileInfo: ITileInfoBasic;
    FTileInfoMemCache: ITileInfoBasicMemCache;
    FCacheProvider: IGoogleEarthCacheProvider;
    FCacheTmProvider: IGoogleEarthCacheProvider;
    FLock: IReadWriteSync;
    FIsProvidersCreated: Boolean;
  private
    function InternalGetTileInfo(
      const AXY: TPoint;
      const AZoom: Byte;
      const AVersionInfo: IMapVersionInfo;
      const AShowOtherVersions: Boolean;
      const AMode: TGetTileInfoMode
    ): ITileInfoBasic;
  protected
    function LazyBuildProviders: Boolean;
  protected
    { ITileStorage }
    function GetTileFileName(
      const AXY: TPoint;
      const AZoom: Byte;
      const AVersionInfo: IMapVersionInfo
    ): string; override;

    function GetTileInfo(
      const AXY: TPoint;
      const AZoom: Byte;
      const AVersionInfo: IMapVersionInfo;
      const AMode: TGetTileInfoMode
    ): ITileInfoBasic; override;

    function GetTileInfoEx(
      const AXY: TPoint;
      const AZoom: Byte;
      const AVersionInfo: IMapVersionRequest;
      const AMode: TGetTileInfoMode
    ): ITileInfoBasic; override;

    function GetTileRectInfo(
      AOperationID: Integer;
      const ACancelNotifier: INotifierOperation;
      const ARect: TRect;
      const AZoom: Byte;
      const AVersionInfo: IMapVersionRequest
    ): ITileRectInfo; override;

    function DeleteTile(
      const AXY: TPoint;
      const AZoom: Byte;
      const AVersionInfo: IMapVersionInfo
    ): Boolean; override;

    function SaveTile(
      const AXY: TPoint;
      const AZoom: Byte;
      const AVersionInfo: IMapVersionInfo;
      const ALoadDate: TDateTime;
      const AContentType: IContentTypeInfoBasic;
      const AData: IBinaryData;
      const AIsOverwrite: Boolean
    ): Boolean; override;

    function GetListOfTileVersions(
      const AXY: TPoint;
      const AZoom: Byte;
      const AVersionInfo: IMapVersionRequest
    ): IMapVersionListStatic; override;

    function ScanTiles(
      const AIgnoreTNE: Boolean;
      const AIgnoreMultiVersionTiles: Boolean
    ): IEnumTileInfo; override;
  private
    { IEnumTileInfo }
    function Next(var ATileInfo: TTileInfo): Boolean;
  public
    constructor Create(
      const AStorageTypeAbilities: ITileStorageTypeAbilities;
      const AStorageForceAbilities: ITileStorageAbilities;
      const AProjectionSet: IProjectionSet;
      const ATileNotifier: INotifierTilePyramidUpdateInternal;
      const AStoragePath: string;
      const ANameInCache: string;
      const AIsTerrainStorage: Boolean;
      const AIsGeoCacherStorage: Boolean;
      const ATileInfoMemCache: ITileInfoBasicMemCache;
      const AMapVersionFactory: IMapVersionFactory;
      const AMainContentType: IContentTypeInfoBasic
    );
    destructor Destroy; override;
  end;

implementation

uses
  Types,
  Math,
  t_GeoTypes,
  i_InterfaceListSimple,
  u_GeoFunc,
  u_InterfaceListSimple,
  u_MapVersionListStatic,
  u_TileRectInfoShort,
  u_TileIteratorByRect,
  u_TileInfoBasic,
  u_Synchronizer;

{ TTileStorageGoogleEarth }

constructor TTileStorageGoogleEarth.Create(
  const AStorageTypeAbilities: ITileStorageTypeAbilities;
  const AStorageForceAbilities: ITileStorageAbilities;
  const AProjectionSet: IProjectionSet;
  const ATileNotifier: INotifierTilePyramidUpdateInternal;
  const AStoragePath: string;
  const ANameInCache: string;
  const AIsTerrainStorage: Boolean;
  const AIsGeoCacherStorage: Boolean;
  const ATileInfoMemCache: ITileInfoBasicMemCache;
  const AMapVersionFactory: IMapVersionFactory;
  const AMainContentType: IContentTypeInfoBasic
);
begin
  FCachePath := IncludeTrailingPathDelimiter(AStoragePath);

  inherited Create(
    AStorageTypeAbilities,
    AStorageForceAbilities,
    AMapVersionFactory,
    AProjectionSet,
    ATileNotifier,
    FCachePath
  );

  FDatabaseName := ANameInCache;
  FIsTerrainStorage := AIsTerrainStorage;
  FIsGeoCacherStorage := AIsGeoCacherStorage;

  FMainContentType := AMainContentType;
  FTileInfoMemCache := ATileInfoMemCache;
  FTileNotExistsTileInfo := TTileInfoBasicNotExists.Create(0, nil);

  FLock := GSync.SyncVariable.Make(Self.ClassName);
  FIsProvidersCreated := False;

  FCacheProvider := nil;
  FCacheTmProvider := nil;
end;

destructor TTileStorageGoogleEarth.Destroy;
begin
  FCacheProvider := nil;
  FCacheTmProvider := nil;
  FTileInfoMemCache := nil;
  FMainContentType := nil;
  FTileNotExistsTileInfo := nil;
  FLock := nil;
  inherited;
end;

function TTileStorageGoogleEarth.LazyBuildProviders: Boolean;
var
  VCachePath: PAnsiChar;
  VOpenErrorMsg: WideString;
  VCacheFactory: IGoogleEarthCacheProviderFactory;
begin
  FLock.BeginRead;
  try
    Result := FIsProvidersCreated;
  finally
    FLock.EndRead;
  end;

  if not Result then begin
    FLock.BeginWrite;
    try
      if not FIsProvidersCreated then begin
        FIsProvidersCreated := True;

        FCacheProvider := nil;
        FCacheTmProvider := nil;

        if FIsGeoCacherStorage then begin
          VCachePath := PAnsiChar(AnsiToUtf8(FCachePath));
          VCacheFactory := libge.CreateGeoCacherCacheProviderFactory;
        end else begin
          VCachePath := PAnsiChar(AnsiString(FCachePath)); // TODO: Fix for unicode path
          VCacheFactory := libge.CreateGoogleEarthCacheProviderFactory;
        end;

        if VCacheFactory <> nil then begin
          if (FDatabaseName = '') or SameText(FDatabaseName, 'earth') then begin
            if not FIsTerrainStorage then begin
              FCacheProvider := VCacheFactory.CreateEarthProvider(VCachePath, VOpenErrorMsg);
              RaiseGoogleEarthExceptionIfError(VOpenErrorMsg);
              FCacheTmProvider := VCacheFactory.CreateEarthTmProvider(VCachePath, VOpenErrorMsg);
            end else begin
              FCacheProvider := VCacheFactory.CreateEarthTerrainProvider(VCachePath, VOpenErrorMsg);
            end;
          end else if SameText(FDatabaseName, 'mars') then begin
            if not FIsTerrainStorage then begin
              FCacheProvider := VCacheFactory.CreateMarsProvider(VCachePath, VOpenErrorMsg);
            end else begin
              FCacheProvider := VCacheFactory.CreateMarsTerrainProvider(VCachePath, VOpenErrorMsg);
            end;
          end else if SameText(FDatabaseName, 'moon') then begin
            if not FIsTerrainStorage then begin
              FCacheProvider := VCacheFactory.CreateMoonProvider(VCachePath, VOpenErrorMsg);
            end else begin
              FCacheProvider := VCacheFactory.CreateMoonTerrainProvider(VCachePath, VOpenErrorMsg);
            end;
          end else if SameText(FDatabaseName, 'sky') then begin
            if not FIsTerrainStorage then begin
              FCacheProvider := VCacheFactory.CreateSkyProvider(VCachePath, VOpenErrorMsg);
            end;
          end;
          RaiseGoogleEarthExceptionIfError(VOpenErrorMsg);
          Result := (FCacheProvider <> nil) or (FCacheTmProvider <> nil);
        end;
      end;
    finally
      FLock.EndWrite;
    end;
  end;
end;

function TTileStorageGoogleEarth.GetTileFileName(
  const AXY: TPoint;
  const AZoom: Byte;
  const AVersionInfo: IMapVersionInfo
): string;
begin
  Result := StoragePath;
end;

procedure ParseVersionInfo(
  const AVersionInfo: IMapVersionInfo;
  const AShowOtherVersions: Boolean;
  out ATileVersion: Word;
  out ATileDate: TDateTime;
  out ASearchAnyVersion: Boolean;
  out ASearchAnyDate: Boolean;
  out AIsTmVersion: Boolean
);
var
  I: Integer;
  VStr: string;
begin
  ATileVersion := 0;
  ATileDate := 0;
  ASearchAnyVersion := True;
  ASearchAnyDate := True;
  AIsTmVersion := False;

  if Assigned(AVersionInfo) and (AVersionInfo.StoreString <> '') then begin
    I := Pos('::', AVersionInfo.StoreString);
    if I > 0 then begin
      AIsTmVersion := True;

      VStr := Copy(AVersionInfo.StoreString, I + 3, Length(AVersionInfo.StoreString) - I - 2);
      ATileDate := StrToDateDef(VStr, 0);

      VStr := Copy(AVersionInfo.StoreString, 1, I - 2);
      ATileVersion := StrToIntDef(VStr, 0);

      ASearchAnyVersion := AShowOtherVersions;
      ASearchAnyDate := AShowOtherVersions;
    end else if AVersionInfo.StoreString <> '' then begin
      ATileVersion := StrToIntDef(AVersionInfo.StoreString, 0);
      ASearchAnyVersion := AShowOtherVersions;
    end;
  end;
end;

function BuildVersionStr(
  const ATileVersion: Word;
  const ATileDate: TDateTime;
  const AIsTmVersion: Boolean
): string;
begin
  if AIsTmVersion then begin
    Result := IntToStr(ATileVersion) + ' :: ' + DateToStr(ATileDate);
  end else begin
    Result := IntToStr(ATileVersion);
  end;
end;

function TTileStorageGoogleEarth.InternalGetTileInfo(
  const AXY: TPoint;
  const AZoom: Byte;
  const AVersionInfo: IMapVersionInfo;
  const AShowOtherVersions: Boolean;
  const AMode: TGetTileInfoMode
): ITileInfoBasic;
var
  I: Integer;
  VResult: Boolean;
  VData: IInterface;
  VXY: TPoint;
  VLonLat: TDoublePoint;
  VZoom: Byte;
  VInTileVersion: Word;
  VInTileDate: TDateTime;
  VOutTileVersion: Word;
  VOutTileDate: TDateTime;
  VTileSize: Integer;
  VWithData: Boolean;
  VSearchAnyVersion: Boolean;
  VSearchAnyDate: Boolean;
  VIsTmVersion: Boolean;
  VBinData, VTmpData: IBinaryData;
  VTileVersionStr: string;
  VTileVersionInfo: IMapVersionInfo;
  VIsOceanTerrain: Boolean;
  VProjectionSet: IProjectionSet;
  VTerrainList: IGoogleEarthTerrainTileList;
  VImageTileContentProvider: IGoogleEarthImageTileProvider;
  VTerrainTileContentProvider: IGoogleEarthTerrainTileProvider;
begin
  Result := nil;

  if not LazyBuildProviders then begin
    Exit;
  end;

  VXY.X := AXY.X;
  VXY.Y := AXY.Y;
  VZoom := AZoom;

  if FIsTerrainStorage then begin
    CheckGoogleEarthTerrainTileZoom(VZoom);
    if VZoom <> AZoom then begin
      VProjectionSet := Self.ProjectionSet;
      VLonLat := VProjectionSet.Zooms[AZoom].TilePos2LonLat(AXY);
      VXY := PointFromDoublePoint(
        VProjectionSet.Zooms[VZoom].LonLat2TilePosFloat(VLonLat),
        prToTopLeft
      );
    end;
  end;

  ParseVersionInfo(
    AVersionInfo,
    AShowOtherVersions,
    VInTileVersion,
    VInTileDate,
    VSearchAnyVersion,
    VSearchAnyDate,
    VIsTmVersion
  );

  VWithData := AMode in [gtimWithData];
  VResult := False;

  if VIsTmVersion then begin
    if (FCacheTmProvider <> nil) then begin
      VResult := FCacheTmProvider.GetTileInfo(
        VXY,
        VZoom,
        VInTileVersion,
        VInTileDate,
        True,
        VSearchAnyDate,
        VWithData,
        VTileSize,
        VOutTileVersion,
        VOutTileDate,
        VData
      );
    end;
    if not VResult and VSearchAnyVersion and (FCacheProvider <> nil) then begin
      VResult := FCacheProvider.GetTileInfo(
        VXY,
        VZoom,
        0,
        0,
        True,
        True,
        VWithData,
        VTileSize,
        VOutTileVersion,
        VOutTileDate,
        VData
      );
    end;
  end else begin
    if (FCacheProvider <> nil) then begin
      VResult := FCacheProvider.GetTileInfo(
        VXY,
        VZoom,
        VInTileVersion,
        VInTileDate,
        VSearchAnyVersion,
        VSearchAnyDate,
        VWithData,
        VTileSize,
        VOutTileVersion,
        VOutTileDate,
        VData
      );
    end;
    if not VResult and VSearchAnyVersion and (FCacheTmProvider <> nil) then begin
      VResult := FCacheTmProvider.GetTileInfo(
        VXY,
        VZoom,
        0,
        0,
        True,
        True,
        VWithData,
        VTileSize,
        VOutTileVersion,
        VOutTileDate,
        VData
      );
    end;
  end;

  if VResult then begin
    VTileVersionStr := BuildVersionStr(VOutTileVersion, VOutTileDate, VIsTmVersion);
    VTileVersionInfo := MapVersionFactory.CreateByStoreString(VTileVersionStr);
    if VWithData then begin
      if Supports(VData, IGoogleEarthImageTileProvider, VImageTileContentProvider) then begin
        VBinData := VImageTileContentProvider.GetJPEG;
      end else if Supports(VData, IGoogleEarthTerrainTileProvider, VTerrainTileContentProvider) then begin
        VBinData := nil;
        VTerrainList := VTerrainTileContentProvider.GetKML;
        if Assigned(VTerrainList) then begin
          for I := 0 to VTerrainList.Count - 1 do begin
            VTmpData := VTerrainList.Get(I, VXY.X, VXY.Y, VZoom, VIsOceanTerrain);
            if (VXY.X = AXY.X) and (VXY.Y = AXY.Y) and (VZoom = AZoom) then begin
              VBinData := VTmpData;
            end;
            if Assigned(FTileInfoMemCache) then begin
              Result := TTileInfoBasicExistsWithTile.Create(
                VOutTileDate,
                VTmpData,
                VTileVersionInfo,
                FMainContentType
              );
              FTileInfoMemCache.Add(VXY, VZoom, VTileVersionInfo, Result);
            end;
          end;
          Result := nil;
        end else begin
          Assert(False);
        end;
      end else begin
        VBinData := nil;
      end;

      if Assigned(VBinData) then begin
        Result :=
          TTileInfoBasicExistsWithTile.Create(
            VOutTileDate,
            VBinData,
            VTileVersionInfo,
            FMainContentType
          );
      end;
    end else begin
      Result :=
        TTileInfoBasicExists.Create(
          VOutTileDate,
          VTileSize,
          VTileVersionInfo,
          FMainContentType
        );
    end;
  end;
end;

function TTileStorageGoogleEarth.GetTileInfo(
  const AXY: TPoint;
  const AZoom: Byte;
  const AVersionInfo: IMapVersionInfo;
  const AMode: TGetTileInfoMode
): ITileInfoBasic;
begin
  if Assigned(FTileInfoMemCache) then begin
    Result := FTileInfoMemCache.Get(AXY, AZoom, AVersionInfo, AMode, True);
    if Result <> nil then begin
      Exit;
    end;
  end;

  Result := FTileNotExistsTileInfo;

  if StorageStateInternal.ReadAccess then begin
    Result := InternalGetTileInfo(AXY, AZoom, AVersionInfo, False, AMode);

    if not Assigned(Result) then begin
      Result := TTileInfoBasicNotExists.Create(0, AVersionInfo);
    end;
  end;

  if Assigned(FTileInfoMemCache) then begin
    FTileInfoMemCache.Add(AXY, AZoom, AVersionInfo, Result);
  end;
end;

function TTileStorageGoogleEarth.GetTileInfoEx(
  const AXY: TPoint;
  const AZoom: Byte;
  const AVersionInfo: IMapVersionRequest;
  const AMode: TGetTileInfoMode
): ITileInfoBasic;
var
  VVersion: IMapVersionInfo;
  VShowOtherVersions: Boolean;
begin
  VVersion := nil;
  VShowOtherVersions := False;
  if Assigned(AVersionInfo) then begin
    VVersion := AVersionInfo.BaseVersion;
    VShowOtherVersions := AVersionInfo.ShowOtherVersions;
  end;
  if Assigned(FTileInfoMemCache) then begin
    Result := FTileInfoMemCache.Get(AXY, AZoom, VVersion, AMode, True);
    if Result <> nil then begin
      Exit;
    end;
  end;

  Result := FTileNotExistsTileInfo;

  if StorageStateInternal.ReadAccess then begin
    Result := InternalGetTileInfo(AXY, AZoom, VVersion, VShowOtherVersions, AMode);

    if not Assigned(Result) then begin
      Result := TTileInfoBasicNotExists.Create(0, VVersion);
    end;
  end;

  if Assigned(FTileInfoMemCache) then begin
    FTileInfoMemCache.Add(AXY, AZoom, VVersion, Result);
  end;
end;

function TTileStorageGoogleEarth.GetListOfTileVersions(
  const AXY: TPoint;
  const AZoom: Byte;
  const AVersionInfo: IMapVersionRequest
): IMapVersionListStatic;

  procedure _TileInfoListToListSimple(
    const ATileInfoList: IGoogleEarthTileInfoList;
    const AListSimple: IInterfaceListSimple;
    const AIsTmVersion: Boolean
  );
  var
    I: Integer;
    VTileVersion: Word;
    VTileDate: TDateTime;
    VTileSize: Integer;
    VVersionStr: string;
    VMapVersionInfo: IMapVersionInfo;
  begin
    Assert(Assigned(AListSimple));
    if Assigned(ATileInfoList) then begin
      if AIsTmVersion then begin
        ATileInfoList.SortByDate;
      end else begin
        ATileInfoList.SortByVersion;
      end;
      for I := 0 to ATileInfoList.Count - 1 do begin
        if ATileInfoList.Get(I, VTileSize, VTileVersion, VTileDate) then begin
          VVersionStr := BuildVersionStr(VTileVersion, VTileDate, AIsTmVersion);
          VMapVersionInfo := MapVersionFactory.CreateByStoreString(VVersionStr);
          AListSimple.Add(VMapVersionInfo);
        end;
      end;
    end;
  end;

var
  VList: IGoogleEarthTileInfoList;
  VListSimple: IInterfaceListSimple;
begin
  Result := nil;
  if StorageStateInternal.ReadAccess then begin
    if not LazyBuildProviders then begin
      Exit;
    end;

    VListSimple := TInterfaceListSimple.Create;

    if FCacheProvider <> nil then begin
      VList := FCacheProvider.GetListOfTileVersions(AXY, AZoom, 0, 0);
      _TileInfoListToListSimple(VList, VListSimple, False);
    end;

    if FCacheTmProvider <> nil then begin
      VList := FCacheTmProvider.GetListOfTileVersions(AXY, AZoom, 0, 0);
      _TileInfoListToListSimple(VList, VListSimple, True);
    end;

    if VListSimple.Count > 0 then begin
      Result := TMapVersionListStatic.Create(VListSimple.MakeStaticAndClear, True);
    end;
  end;
end;

function TTileStorageGoogleEarth.GetTileRectInfo(
  AOperationID: Integer;
  const ACancelNotifier: INotifierOperation;
  const ARect: TRect;
  const AZoom: Byte;
  const AVersionInfo: IMapVersionRequest
): ITileRectInfo;
var
  VRect: TRect;
  VZoom: Byte;
  VCount: TPoint;
  VItems: TArrayOfTileInfoShortInternal;
  VIndex: Integer;
  VTile: TPoint;
  VIterator: TTileIteratorByRectRecord;
  VTileInfo: ITileInfoBasic;
  VVersion: IMapVersionInfo;
  VShowOtherVersions: Boolean;
begin
  Result := nil;
  if StorageStateInternal.ReadAccess then begin
    if not LazyBuildProviders then begin
      Exit;
    end;
    VVersion := nil;
    VShowOtherVersions := False;
    if Assigned(AVersionInfo) then begin
      VVersion := AVersionInfo.BaseVersion;
      VShowOtherVersions := AVersionInfo.ShowOtherVersions;
    end;
    VRect := ARect;
    VZoom := AZoom;
    ProjectionSet.Zooms[VZoom].ValidateTileRect(VRect);
    VCount.X := VRect.Right - VRect.Left;
    VCount.Y := VRect.Bottom - VRect.Top;
    if (VCount.X > 0) and (VCount.Y > 0) and (VCount.X <= 2048) and (VCount.Y <= 2048) then begin
      SetLength(VItems, VCount.X * VCount.Y);
      VIterator.Init(VRect);
      while VIterator.Next(VTile) do begin
        if ACancelNotifier.IsOperationCanceled(AOperationID) then begin
          Result := nil;
          Exit;
        end;
        VIndex := TTileRectInfoShort.TileInRectToIndex(VTile, VRect);
        Assert(VIndex >= 0);
        if VIndex >= 0 then begin
          VTileInfo := InternalGetTileInfo(VTile, VZoom, VVersion, VShowOtherVersions, gtimWithoutData);
          if Assigned(VTileInfo) then begin
            VItems[VIndex].FLoadDate := 0;
            VItems[VIndex].FSize := VTileInfo.Size;
            VItems[VIndex].FInfoType := titExists;
          end else begin
            VItems[VIndex].FLoadDate := 0;
            VItems[VIndex].FSize := 0;
            VItems[VIndex].FInfoType := titNotExists;
          end;
        end;
      end;
      Result :=
        TTileRectInfoShort.CreateWithOwn(
          VRect,
          VZoom,
          nil,
          FMainContentType,
          VItems
        );
      VItems := nil;
    end;
  end;
end;

function TTileStorageGoogleEarth.SaveTile(
  const AXY: TPoint;
  const AZoom: Byte;
  const AVersionInfo: IMapVersionInfo;
  const ALoadDate: TDateTime;
  const AContentType: IContentTypeInfoBasic;
  const AData: IBinaryData;
  const AIsOverwrite: Boolean
): Boolean;
begin
  Result := False;
end;

function TTileStorageGoogleEarth.DeleteTile(
  const AXY: TPoint;
  const AZoom: Byte;
  const AVersionInfo: IMapVersionInfo
): Boolean;
begin
  Result := False;
end;

function TTileStorageGoogleEarth.ScanTiles(
  const AIgnoreTNE: Boolean;
  const AIgnoreMultiVersionTiles: Boolean
): IEnumTileInfo;
begin
  Result := nil; // ToDo
end;

function TTileStorageGoogleEarth.Next(var ATileInfo: TTileInfo): Boolean;
begin
  Result := False; // ToDo
end;

end.

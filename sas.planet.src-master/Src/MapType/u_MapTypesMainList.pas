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

unit u_MapTypesMainList;

interface

uses
  ActiveX,
  SysUtils,
  i_NotifierOperation,
  i_InternalPerformanceCounter,
  i_ConfigDataProvider,
  i_ConfigDataWriteProvider,
  i_LanguageManager,
  i_HashFunction,
  i_ThreadConfig,
  i_ProjectionSetFactory,
  i_ZmpInfoSet,
  i_NotifierTime,
  i_InetConfig,
  i_Bitmap32BufferFactory,
  i_ImageResamplerFactoryChangeable,
  i_GlobalDownloadConfig,
  i_DownloaderFactory,
  i_ContentTypeManager,
  i_InvisibleBrowser,
  i_ProjConverter,
  i_LocalCoordConverter,
  i_MapVersionFactoryList,
  i_MainMemCacheConfig,
  i_MapTypeGUIConfigList,
  i_MapType,
  i_MapTypeSet,
  i_MapTypeSetBuilder,
  i_MapTypeSetChangeable,
  i_TileStorageTypeList,
  i_GlobalCacheConfig,
  u_MapTypeSetChangeableSimple;

type
  EMapTypesNoMaps = class(Exception);

  TMapTypesMainList = class
  private
    FMapTypeSetBuilderFactory: IMapTypeSetBuilderFactory;
    FGUIConfigList: IMapTypeGUIConfigList;
    FZmpInfoSet: IZmpInfoSet;
    FPerfCounterList: IInternalPerformanceCounterList;

    FTileLoadResampler: IImageResamplerFactoryChangeable;
    FTileGetPrevResampler: IImageResamplerFactoryChangeable;
    FTileReprojectResampler: IImageResamplerFactoryChangeable;
    FTileDownloadResampler: IImageResamplerFactoryChangeable;

    FFullMapsSet: IMapTypeSet;
    FFullMapsSetChangeable: IMapTypeSetChangeable;
    FFullMapsSetChangeableInternal: IMapTypeSetChangeableSimpleInternal;
    FMapsSet: IMapTypeSet;
    FLayersSet: IMapTypeSet;

    procedure BuildMapsLists;
    function GetFirstMainMapGUID: TGUID;
    function GetDefaultMainMapGUID: TGUID;
  public
    constructor Create(
      const AMapTypeSetBuilderFactory: IMapTypeSetBuilderFactory;
      const AZmpInfoSet: IZmpInfoSet;
      const ATileLoadResamplerConfig: IImageResamplerFactoryChangeable;
      const ATileGetPrevResamplerConfig: IImageResamplerFactoryChangeable;
      const ATileReprojectResamplerConfig: IImageResamplerFactoryChangeable;
      const ATileDownloadResamplerConfig: IImageResamplerFactoryChangeable;
      const APerfCounterList: IInternalPerformanceCounterList
    );

    function NextMapWithTile(
      const AView: ILocalCoordConverter;
      const AActiveMap: IMapType;
      AStep: integer
    ): IMapType;

    property FullMapsSetChangeable: IMapTypeSetChangeable read FFullMapsSetChangeable;
    property FullMapsSet: IMapTypeSet read FFullMapsSet;
    property MapsSet: IMapTypeSet read FMapsSet;
    property LayersSet: IMapTypeSet read FLayersSet;
    property FirstMainMapGUID: TGUID read GetFirstMainMapGUID;
    property DefaultMainMapGUID: TGUID read GetDefaultMainMapGUID;
    property GUIConfigList: IMapTypeGUIConfigList read FGUIConfigList;

    procedure LoadMaps(
      const ALanguageManager: ILanguageManager;
      const AMapVersionFactoryList: IMapVersionFactoryList;
      const AMainMemCacheConfig: IMainMemCacheConfig;
      const AGlobalCacheConfig: IGlobalCacheConfig;
      const ATileStorageTypeList: ITileStorageTypeListStatic;
      const AHashFunction: IHashFunction;
      const AGCNotifier: INotifierTime;
      const AAppClosingNotifier: INotifierOneOperation;
      const AInetConfig: IInetConfig;
      const ADownloadConfig: IGlobalDownloadConfig;
      const ADownloaderThreadConfig: IThreadConfig;
      const ADownloaderFactory: IDownloaderFactory;
      const ABitmap32StaticFactory: IBitmap32StaticFactory;
      const AContentTypeManager: IContentTypeManager;
      const AProjectionSetFactory: IProjectionSetFactory;
      const AInvisibleBrowser: IInvisibleBrowser;
      const AProjFactory: IProjConverterFactory;
      const ALocalMapsConfig: IConfigDataProvider;
      const AMapsListConfig: IConfigDataProvider
    );
    procedure SaveMaps(
      const ALocalMapsConfig: IConfigDataWriteProvider;
      const AMapsListConfig: IConfigDataWriteProvider
    );
  end;

implementation

uses
  Dialogs,
  Types,
  Math,
  c_ZeroGUID,
  t_GeoTypes,
  i_GUIDListStatic,
  i_Projection,
  i_MapVersionRequest,
  i_TileInfoBasic,
  i_TileStorage,
  i_ZmpInfo,
  u_MapTypeGUIConfigList,
  u_MapType,
  u_GeoFunc,
  u_ResStrings;

{ TMapTypesMainList }

constructor TMapTypesMainList.Create(
  const AMapTypeSetBuilderFactory: IMapTypeSetBuilderFactory;
  const AZmpInfoSet: IZmpInfoSet;
  const ATileLoadResamplerConfig: IImageResamplerFactoryChangeable;
  const ATileGetPrevResamplerConfig: IImageResamplerFactoryChangeable;
  const ATileReprojectResamplerConfig: IImageResamplerFactoryChangeable;
  const ATileDownloadResamplerConfig: IImageResamplerFactoryChangeable;
  const APerfCounterList: IInternalPerformanceCounterList
);
begin
  inherited Create;
  FMapTypeSetBuilderFactory := AMapTypeSetBuilderFactory;
  FZmpInfoSet := AZmpInfoSet;
  FTileLoadResampler := ATileLoadResamplerConfig;
  FTileGetPrevResampler := ATileGetPrevResamplerConfig;
  FTileReprojectResampler := ATileReprojectResamplerConfig;
  FTileDownloadResampler := ATileDownloadResamplerConfig;
  FPerfCounterList := APerfCounterList;
  FFullMapsSetChangeableInternal :=
    TMapTypeSetChangeableSimple.Create(
      AMapTypeSetBuilderFactory,
      nil
    );
  FFullMapsSetChangeable := FFullMapsSetChangeableInternal;
end;

function TMapTypesMainList.GetDefaultMainMapGUID: TGUID;
const
  CDefaultMainMapGUID: TGUID = '{CBA03063-23D9-4FA4-931A-9182B98644B1}';
var
  VGUID: TGUID;
begin
  VGUID := CDefaultMainMapGUID;
  if FMapsSet.GetMapTypeByGUID(VGUID) <> nil then begin
    Result := VGUID;
  end else begin
    Result := GetFirstMainMapGUID;
  end;
end;

function TMapTypesMainList.GetFirstMainMapGUID: TGUID;
var
  i: integer;
  VGUID: TGUID;
  VGUIDList: IGUIDListStatic;
begin
  Result := CGUID_Zero;
  VGUIDList := FGUIConfigList.OrderedMapGUIDList;
  for i := 0 to VGUIDList.Count - 1 do begin
    VGUID := VGUIDList.Items[i];
    if FMapsSet.GetMapTypeByGUID(VGUID) <> nil then begin
      result := VGUID;
      exit;
    end;
  end;
end;

procedure TMapTypesMainList.BuildMapsLists;
var
  i: Integer;
  VMapType: IMapType;
  VMapsList: IMapTypeSetBuilder;
  VLayersList: IMapTypeSetBuilder;
begin
  VMapsList := FMapTypeSetBuilderFactory.Build(False);
  VLayersList := FMapTypeSetBuilderFactory.Build(False);
  for i := 0 to FFullMapsSet.Count - 1 do begin
    VMapType := FFullMapsSet.Items[i];
    if VMapType.Zmp.IsLayer then begin
      VLayersList.Add(VMapType);
    end else begin
      VMapsList.Add(VMapType);
    end;
  end;
  FMapsSet := VMapsList.MakeAndClear;
  FLayersSet := VLayersList.MakeAndClear;
  FFullMapsSetChangeableInternal.SetStatic(FFullMapsSet);
end;

procedure TMapTypesMainList.LoadMaps(
  const ALanguageManager: ILanguageManager;
  const AMapVersionFactoryList: IMapVersionFactoryList;
  const AMainMemCacheConfig: IMainMemCacheConfig;
  const AGlobalCacheConfig: IGlobalCacheConfig;
  const ATileStorageTypeList: ITileStorageTypeListStatic;
  const AHashFunction: IHashFunction;
  const AGCNotifier: INotifierTime;
  const AAppClosingNotifier: INotifierOneOperation;
  const AInetConfig: IInetConfig;
  const ADownloadConfig: IGlobalDownloadConfig;
  const ADownloaderThreadConfig: IThreadConfig;
  const ADownloaderFactory: IDownloaderFactory;
  const ABitmap32StaticFactory: IBitmap32StaticFactory;
  const AContentTypeManager: IContentTypeManager;
  const AProjectionSetFactory: IProjectionSetFactory;
  const AInvisibleBrowser: IInvisibleBrowser;
  const AProjFactory: IProjConverterFactory;
  const ALocalMapsConfig: IConfigDataProvider;
  const AMapsListConfig: IConfigDataProvider
);
var
  VMapType: IMapType;
  VMapOnlyCount: integer;
  VLocalMapConfig: IConfigDataProvider;
  VMapTypeCount: integer;
  VZmp: IZmpInfo;
  VEnum: IEnumGUID;
  VGUID: TGUID;
  VGetCount: Cardinal;
  VGUIDList: IGUIDListStatic;
  i: Integer;
  VFullMapsList: IMapTypeSetBuilder;
begin
  VMapOnlyCount := 0;
  VMapTypeCount := 0;

  VEnum := FZmpInfoSet.GetIterator;
  while VEnum.Next(1, VGUID, VGetCount) = S_OK do begin
    VZmp := FZmpInfoSet.GetZmpByGUID(VGUID);
    if not VZmp.IsLayer then begin
      Inc(VMapOnlyCount);
    end;
    Inc(VMapTypeCount);
  end;

  if VMapTypeCount = 0 then begin
    raise EMapTypesNoMaps.Create(SAS_ERR_NoMaps);
  end;
  if VMapOnlyCount = 0 then begin
    raise Exception.Create(SAS_ERR_MainMapNotExists);
  end;
  VEnum.Reset;
  VFullMapsList := FMapTypeSetBuilderFactory.Build(False);
  VFullMapsList.Capacity := VMapTypeCount;

  VMapOnlyCount := 0;
  VMapTypeCount := 0;
  while VEnum.Next(1, VGUID, VGetCount) = S_OK do begin
    try
      VZmp := FZmpInfoSet.GetZmpByGUID(VGUID);
      VLocalMapConfig := ALocalMapsConfig.GetSubItem(GUIDToString(VZmp.GUID));
      VMapType :=
        TMapType.Create(
          ALanguageManager,
          VZmp,
          AMapVersionFactoryList,
          AMainMemCacheConfig,
          AGlobalCacheConfig,
          ATileStorageTypeList,
          AGCNotifier,
          AAppClosingNotifier,
          AInetConfig,
          FTileLoadResampler,
          FTileGetPrevResampler,
          FTileReprojectResampler,
          FTileDownloadResampler,
          ABitmap32StaticFactory,
          AHashFunction,
          ADownloadConfig,
          ADownloaderThreadConfig,
          ADownloaderFactory,
          AContentTypeManager,
          AProjectionSetFactory,
          AInvisibleBrowser,
          AProjFactory,
          VLocalMapConfig,
          FPerfCounterList
        );
      VFullMapsList.Add(VMapType);
    except
      if ExceptObject <> nil then begin
        ShowMessage((ExceptObject as Exception).Message);
      end;
      VMapType := nil;
    end;
    if VMapType <> nil then begin
      if not VMapType.Zmp.IsLayer then begin
        Inc(VMapOnlyCount);
      end;
      inc(VMapTypeCount);
    end;
  end;

  if VMapTypeCount = 0 then begin
    raise EMapTypesNoMaps.Create(SAS_ERR_NoMaps);
  end;
  if VMapOnlyCount = 0 then begin
    raise Exception.Create(SAS_ERR_MainMapNotExists);
  end;
  FFullMapsSet := VFullMapsList.MakeAndClear;

  BuildMapsLists;
  
  FGUIConfigList :=
    TMapTypeGUIConfigList.Create(
      ALanguageManager,
      FFullMapsSet
    );
  FGUIConfigList.ReadConfig(AMapsListConfig);

  VGUIDList := FGUIConfigList.OrderedMapGUIDList;
  FGUIConfigList.LockWrite;
  try
    for i := 0 to VGUIDList.Count - 1 do begin
      VGUID := VGUIDList.Items[i];
      VMapType := FFullMapsSet.GetMapTypeByGUID(VGUID);
      VMapType.GUIConfig.SortIndex := i + 1;
    end;
  finally
    FGUIConfigList.UnlockWrite;
  end;
end;

function TMapTypesMainList.NextMapWithTile(
  const AView: ILocalCoordConverter;
  const AActiveMap: IMapType;
  AStep: integer
): IMapType;
var
  VMapType: IMapType;
  VProjection: IProjection;
  VMapProjection: IProjection;
  VMapTile: Tpoint;
  VVersion: IMapVersionRequest;
  VTileInfo: ITileInfoBasic;
  VLonLat: TDoublePoint;
  VGUIDList: IGUIDListStatic;
  VGUID: TGUID;
  i: Integer;
  VLoopCnt: Integer;
begin
  Result := nil;
  VProjection := AView.Projection;
  VLonLat := AView.GetCenterLonLat;
  VGUIDList := FGUIConfigList.OrderedMapGUIDList;
  VLoopCnt := 0;
  for i := 0 to VGUIDList.Count - 1 do begin
    if IsEqualGUID(AActiveMap.GUID, VGUIDList.Items[i]) then begin
      Break;
    end;
  end;

  while (VLoopCnt < VGUIDList.Count) do begin
    Inc(VLoopCnt);
    i := i + AStep;
    if i < 0 then begin
      i := VGUIDList.Count - 1;
    end;
    if i > VGUIDList.Count - 1 then begin
      i := 0;
    end;
    VGUID := VGUIDList.Items[i];
    VMapType := FMapsSet.GetMapTypeByGUID(VGUID);
    if VMapType <> nil then begin
      if (not VMapType.Zmp.IsLayer) and (VMapType.GUIConfig.Enabled) then begin
        VMapProjection := VMapType.ProjectionSet.GetSuitableProjection(VProjection);
        VMapTile :=
          PointFromDoublePoint(
            VMapProjection.LonLat2TilePosFloat(VLonLat),
            prToTopLeft
          );
        VVersion := VMapType.VersionRequest.GetStatic;
        VTileInfo := VMapType.TileStorage.GetTileInfoEx(VMapTile, VMapProjection.Zoom, VVersion, gtimAsIs);
        if Assigned(VTileInfo) and VTileInfo.GetIsExists then begin
          Result := VMapType;
          break;
        end;
      end;
    end;
  end;
end;

procedure TMapTypesMainList.SaveMaps(
  const ALocalMapsConfig: IConfigDataWriteProvider;
  const AMapsListConfig: IConfigDataWriteProvider
);
var
  i: integer;
  VGUIDString: string;
  VMapType: IMapType;
  VSubItem: IConfigDataWriteProvider;
  VGUID: TGUID;
  VGUIDList: IGUIDListStatic;
begin
  VGUIDList := FGUIConfigList.OrderedMapGUIDList;
  for i := 0 to VGUIDList.Count - 1 do begin
    VGUID := VGUIDList.Items[i];
    VMapType := FFullMapsSet.GetMapTypeByGUID(VGUID);
    VGUIDString := GUIDToString(VGUID);
    VSubItem := ALocalMapsConfig.GetOrCreateSubItem(VGUIDString);
    VMapType.SaveConfig(VSubItem);
  end;
  FGUIConfigList.WriteConfig(AMapsListConfig);
end;

end.

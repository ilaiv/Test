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

unit u_ProviderMapCombine;

interface

uses
  Windows,
  Forms,
  t_GeoTypes,
  i_LanguageManager,
  i_ProjectionSetList,
  i_ProjectionSetChangeable,
  i_BitmapLayerProvider,
  i_BitmapTileProvider,
  i_HashFunction,
  i_Projection,
  i_GeometryProjected,
  i_GeometryLonLat,
  i_GeometryProjectedProvider,
  i_VectorItemSubsetBuilder,
  i_UseTilePrevZoomConfig,
  i_Bitmap32BufferFactory,
  i_BitmapPostProcessing,
  i_MapLayerGridsConfig,
  i_CoordToStringConverter,
  i_UsedMarksConfig,
  i_MarksDrawConfig,
  i_MarkSystem,
  i_MapCalibration,
  i_MapType,
  i_FillingMapLayerConfig,
  i_FillingMapPolygon,
  i_GeometryProjectedFactory,
  i_GlobalViewMainConfig,
  i_ViewProjectionConfig,
  i_MapTypeListChangeable,
  i_BitmapMapCombiner,
  i_RegionProcessTask,
  i_RegionProcessProgressInfo,
  i_RegionProcessProgressInfoInternalFactory,
  i_RegionProcessParamsFrame,
  u_ExportProviderAbstract,
  fr_MapSelect,
  fr_MapCombine;

type
  TProviderMapCombine = class(TExportProviderBase)
  private
    FCombinerFactory: IBitmapMapCombinerFactory;
    FViewConfig: IGlobalViewMainConfig;
    FViewProjectionConfig: IViewProjectionConfig;
    FUseTilePrevZoomConfig: IUseTilePrevZoomConfig;
    FHashFunction: IHashFunction;
    FBitmapFactory: IBitmap32StaticFactory;
    FProjectionSet: IProjectionSetChangeable;
    FProjectionSetList: IProjectionSetList;
    FVectorGeometryProjectedFactory: IGeometryProjectedFactory;
    FProjectedGeometryProvider: IGeometryProjectedProvider;
    FVectorSubsetBuilderFactory: IVectorItemSubsetBuilderFactory;
    FMarksDB: IMarkSystem;
    FMarksShowConfig: IUsedMarksConfig;
    FMarksDrawConfig: IMarksDrawConfig;
    FActiveMapsSet: IMapTypeListChangeable;
    FBitmapPostProcessing: IBitmapPostProcessingChangeable;
    FMapCalibrationList: IMapCalibrationList;
    FFillingMapConfig: IFillingMapLayerConfig;
    FFillingMapType: IMapTypeChangeable;
    FFillingMapPolygon: IFillingMapPolygon;
    FGridsConfig: IMapLayerGridsConfig;
    FCoordToStringConverter: ICoordToStringConverterChangeable;
    function PrepareGridsProvider(const AProjection: IProjection): IBitmapTileProvider;
    function PrepareFillingMapProvider(const AProjection: IProjection): IBitmapTileProvider;
  protected
    function PrepareTargetFileName: string;
    function PrepareTargetRect(
      const AProjection: IProjection;
      const APolygon: IGeometryProjectedPolygon
    ): TRect;
    function PrepareImageProvider(
      const APolygon: IGeometryLonLatPolygon;
      const AProjection: IProjection;
      const AProjectedPolygon: IGeometryProjectedPolygon
    ): IBitmapTileProvider;
    function PrepareProjection: IProjection;
    function PreparePolygon(
      const AProjection: IProjection;
      const APolygon: IGeometryLonLatPolygon
    ): IGeometryProjectedPolygon;
    function PrepareCombineProgressUpdate(
      const AProgressInfo: IRegionProcessProgressInfoInternal
    ): IBitmapCombineProgressUpdate;
  protected
    function Validate(const APolygon: IGeometryLonLatPolygon): Boolean; override;
    function CreateFrame: TFrame; override;
  protected
    function GetCaption: string; override;
    function PrepareTask(
      const APolygon: IGeometryLonLatPolygon;
      const AProgressInfo: IRegionProcessProgressInfoInternal
    ): IRegionProcessTask; override;
  public
    constructor Create(
      const ACombinerFactory: IBitmapMapCombinerFactory;
      const AProgressFactory: IRegionProcessProgressInfoInternalFactory;
      const ALanguageManager: ILanguageManager;
      const AMapSelectFrameBuilder: IMapSelectFrameBuilder;
      const AActiveMapsSet: IMapTypeListChangeable;
      const AViewConfig: IGlobalViewMainConfig;
      const AViewProjectionConfig: IViewProjectionConfig;
      const AUseTilePrevZoomConfig: IUseTilePrevZoomConfig;
      const AProjectionSet: IProjectionSetChangeable;
      const AProjectionSetList: IProjectionSetList;
      const AVectorGeometryProjectedFactory: IGeometryProjectedFactory;
      const AProjectedGeometryProvider: IGeometryProjectedProvider;
      const AVectorSubsetBuilderFactory: IVectorItemSubsetBuilderFactory;
      const AMarksShowConfig: IUsedMarksConfig;
      const AMarksDrawConfig: IMarksDrawConfig;
      const AMarksDB: IMarkSystem;
      const AHashFunction: IHashFunction;
      const ABitmapFactory: IBitmap32StaticFactory;
      const ABitmapPostProcessing: IBitmapPostProcessingChangeable;
      const AFillingMapConfig: IFillingMapLayerConfig;
      const AFillingMapType: IMapTypeChangeable;
      const AFillingMapPolygon: IFillingMapPolygon;
      const AGridsConfig: IMapLayerGridsConfig;
      const ACoordToStringConverter: ICoordToStringConverterChangeable;
      const AMapCalibrationList: IMapCalibrationList
    );
  end;

implementation

uses
  Classes,
  SysUtils,
  Types,
  Math,
  gnugettext,
  t_Bitmap32,
  i_LonLatRect,
  i_InternalPerformanceCounter,
  i_MarkCategoryList,
  i_TextDrawerBasic,
  i_MarkerProviderByAppearancePointIcon,
  i_MarkerProviderForVectorItem,
  u_InternalPerformanceCounterFake,
  i_VectorItemSubset,
  i_VectorTileProvider,
  i_VectorTileRenderer,
  i_FillingMapColorer,
  i_MapVersionRequest,
  u_BaseInterfacedObject,
  u_GeoFunc,
  u_ResStrings,
  u_RegionProcessTaskCombine,
  u_TextDrawerBasic,
  u_MarkerProviderByAppearancePointIcon,
  u_MarkerProviderForVectorItemForMarkPoints,
  u_VectorTileProviderByFixedSubset,
  u_VectorTileRendererForMarks,
  u_FillingMapColorerSimple,
  u_BitmapLayerProviderFillingMap,
  u_BitmapLayerProviderComplex,
  u_BitmapLayerProviderGridGenshtab,
  u_BitmapLayerProviderGridDegree,
  u_BitmapLayerProviderGridTiles,
  u_BitmapTileProviderByBitmapTileUniProvider,
  u_BitmapTileProviderWithRecolor,
  u_BitmapTileProviderByVectorTileProvider,
  u_BitmapTileProviderComplex,
  u_BitmapTileProviderInPolygon,
  u_BitmapTileProviderWithBGColor;

type
  TBitmapCombineProgressUpdate = class(TBaseInterfacedObject, IBitmapCombineProgressUpdate)
  private
    FProgressInfo: IRegionProcessProgressInfoInternal;
  private
    procedure Update(AProgress: Double);
  public
    constructor Create(
      const AProgressInfo: IRegionProcessProgressInfoInternal
    );
  end;

{ TBitmapCombineProgressUpdate }

constructor TBitmapCombineProgressUpdate.Create(
  const AProgressInfo: IRegionProcessProgressInfoInternal
);
begin
  inherited Create;
  FProgressInfo := AProgressInfo;
end;

procedure TBitmapCombineProgressUpdate.Update(AProgress: Double);
begin
  FProgressInfo.SetProcessedRatio(AProgress);
  FProgressInfo.SetSecondLine(SAS_STR_Processed + ': ' + IntToStr(Trunc(AProgress * 100)) + '%');
end;


{ TProviderMapCombineBase }

constructor TProviderMapCombine.Create(
  const ACombinerFactory: IBitmapMapCombinerFactory;
  const AProgressFactory: IRegionProcessProgressInfoInternalFactory;
  const ALanguageManager: ILanguageManager;
  const AMapSelectFrameBuilder: IMapSelectFrameBuilder;
  const AActiveMapsSet: IMapTypeListChangeable;
  const AViewConfig: IGlobalViewMainConfig;
  const AViewProjectionConfig: IViewProjectionConfig;
  const AUseTilePrevZoomConfig: IUseTilePrevZoomConfig;
  const AProjectionSet: IProjectionSetChangeable;
  const AProjectionSetList: IProjectionSetList;
  const AVectorGeometryProjectedFactory: IGeometryProjectedFactory;
  const AProjectedGeometryProvider: IGeometryProjectedProvider;
  const AVectorSubsetBuilderFactory: IVectorItemSubsetBuilderFactory;
  const AMarksShowConfig: IUsedMarksConfig;
  const AMarksDrawConfig: IMarksDrawConfig;
  const AMarksDB: IMarkSystem;
  const AHashFunction: IHashFunction;
  const ABitmapFactory: IBitmap32StaticFactory;
  const ABitmapPostProcessing: IBitmapPostProcessingChangeable;
  const AFillingMapConfig: IFillingMapLayerConfig;
  const AFillingMapType: IMapTypeChangeable;
  const AFillingMapPolygon: IFillingMapPolygon;
  const AGridsConfig: IMapLayerGridsConfig;
  const ACoordToStringConverter: ICoordToStringConverterChangeable;
  const AMapCalibrationList: IMapCalibrationList
);
begin
  Assert(Assigned(ACombinerFactory));
  Assert(Assigned(AFillingMapConfig));
  Assert(Assigned(AFillingMapType));
  Assert(Assigned(AFillingMapPolygon));
  Assert(Assigned(AHashFunction));
  inherited Create(
    AProgressFactory,
    ALanguageManager,
    AMapSelectFrameBuilder,
    nil
  );
  FCombinerFactory := ACombinerFactory;
  FMapCalibrationList := AMapCalibrationList;
  FViewConfig := AViewConfig;
  FViewProjectionConfig := AViewProjectionConfig;
  FUseTilePrevZoomConfig := AUseTilePrevZoomConfig;
  FMarksShowConfig := AMarksShowConfig;
  FMarksDrawConfig := AMarksDrawConfig;
  FMarksDB := AMarksDB;
  FActiveMapsSet := AActiveMapsSet;
  FBitmapPostProcessing := ABitmapPostProcessing;
  FhashFunction := AHashFunction;
  FBitmapFactory := ABitmapFactory;
  FProjectionSet := AProjectionSet;
  FProjectionSetList := AProjectionSetList;
  FVectorGeometryProjectedFactory := AVectorGeometryProjectedFactory;
  FProjectedGeometryProvider := AProjectedGeometryProvider;
  FVectorSubsetBuilderFactory := AVectorSubsetBuilderFactory;
  FFillingMapConfig := AFillingMapConfig;
  FFillingMapType := AFillingMapType;
  FFillingMapPolygon := AFillingMapPolygon;
  FGridsConfig := AGridsConfig;
  FCoordToStringConverter := ACoordToStringConverter;
end;

function TProviderMapCombine.CreateFrame: TFrame;
begin
  Result :=
    TfrMapCombine.Create(
      Self.LanguageManager,
      FProjectionSetList,
      FVectorGeometryProjectedFactory,
      FBitmapFactory,
      Self.MapSelectFrameBuilder,
      FActiveMapsSet,
      FViewConfig,
      FViewProjectionConfig,
      FUseTilePrevZoomConfig,
      FMapCalibrationList,
      FCombinerFactory.MinPartSize,
      FCombinerFactory.MaxPartSize,
      FCombinerFactory.OptionsSet,
      FCombinerFactory.CombinePathStringTypeSupport,
      FCombinerFactory.DefaultExt,
      FCombinerFactory.FormatName
    );
  Assert(Supports(Result, IRegionProcessParamsFrameImageProvider));
  Assert(Supports(Result, IRegionProcessParamsFrameMapCalibrationList));
  Assert(Supports(Result, IRegionProcessParamsFrameTargetProjection));
  Assert(Supports(Result, IRegionProcessParamsFrameTargetPath));
  Assert(Supports(Result, IRegionProcessParamsFrameMapCombine));
end;

function TProviderMapCombine.GetCaption: string;
begin
  Result := _(FCombinerFactory.FormatName);
end;

function TProviderMapCombine.PrepareCombineProgressUpdate(
  const AProgressInfo: IRegionProcessProgressInfoInternal): IBitmapCombineProgressUpdate;
begin
  Result := TBitmapCombineProgressUpdate.Create(AProgressInfo);
end;

function TProviderMapCombine.PrepareFillingMapProvider(
  const AProjection: IProjection
): IBitmapTileProvider;
var
  VConfig: IFillingMapLayerConfigStatic;
  VResult: IBitmapTileUniProvider;
  VMap: IMapType;
  VColorer: IFillingMapColorer;
  VVersionRequest: IMapVersionRequest;
begin
  VResult := nil;
  VConfig := FFillingMapConfig.GetStatic;
  if VConfig.Visible then begin
    VMap := FFillingMapType.GetStatic;
    VVersionRequest := VMap.VersionRequest.GetStatic;
    VColorer :=
      TFillingMapColorerSimple.Create(
        VConfig.NoTileColor,
        VConfig.ShowTNE,
        VConfig.TNEColor,
        VConfig.FillMode,
        VConfig.FilterMode,
        VConfig.FillFirstDay,
        VConfig.FillLastDay
      );
    VResult :=
      TBitmapLayerProviderFillingMap.Create(
        FBitmapFactory,
        FVectorGeometryProjectedFactory,
        VMap.TileStorage,
        VVersionRequest,
        VConfig.UseRelativeZoom,
        VConfig.Zoom,
        FFillingMapPolygon.Polygon,
        VColorer
      );
    Result :=
      TBitmapTileProviderByBitmapTileUniProvider.Create(
        AProjection,
        VResult
      );
  end;
end;

function TProviderMapCombine.PrepareGridsProvider(
  const AProjection: IProjection
): IBitmapTileProvider;
var
  VVisible: Boolean;
  VColor: TColor32;
  VUseRelativeZoom: Boolean;
  VZoom: Integer;
  VShowText: Boolean;
  VShowLines: Boolean;
  VScale: Integer;
  VScaleDegree: Double;
  VProvider: IBitmapTileUniProvider;
  VResult: IBitmapTileUniProvider;
begin
  Result := nil;
  VResult := nil;
  FGridsConfig.TileGrid.LockRead;
  try
    VVisible := FGridsConfig.TileGrid.Visible;
    VColor := FGridsConfig.TileGrid.GridColor;
    VUseRelativeZoom := FGridsConfig.TileGrid.UseRelativeZoom;
    VZoom := FGridsConfig.TileGrid.Zoom;
    VShowText := FGridsConfig.TileGrid.ShowText;
    VShowLines := True;
  finally
    FGridsConfig.TileGrid.UnlockRead;
  end;
  if VVisible then begin
    VResult :=
      TBitmapLayerProviderGridTiles.Create(
        FBitmapFactory,
        FProjectionSet.GetStatic,
        VColor,
        VUseRelativeZoom,
        VZoom,
        VShowText,
        VShowLines
      );
  end;
  FGridsConfig.GenShtabGrid.LockRead;
  try
    VVisible := FGridsConfig.GenShtabGrid.Visible;
    VColor := FGridsConfig.GenShtabGrid.GridColor;
    VScale := FGridsConfig.GenShtabGrid.Scale;
    VShowText := FGridsConfig.GenShtabGrid.ShowText;
    VShowLines := True;
  finally
    FGridsConfig.GenShtabGrid.UnlockRead;
  end;
  if VVisible then begin
    VProvider :=
      TBitmapLayerProviderGridGenshtab.Create(
        FBitmapFactory,
        VColor,
        VScale,
        VShowText,
        VShowLines
      );

    if VResult <> nil then begin
      VResult :=
        TBitmapLayerProviderComplex.Create(
          FBitmapFactory,
          VResult,
          VProvider
        );
    end else begin
      VResult := VProvider;
    end;
  end;
  FGridsConfig.DegreeGrid.LockRead;
  try
    VVisible := FGridsConfig.DegreeGrid.Visible;
    VColor := FGridsConfig.DegreeGrid.GridColor;
    VScaleDegree := FGridsConfig.DegreeGrid.Scale;
    VShowText := FGridsConfig.DegreeGrid.ShowText;
    VShowLines := True;
  finally
    FGridsConfig.DegreeGrid.UnlockRead;
  end;
  if VVisible then begin
    VProvider :=
      TBitmapLayerProviderGridDegree.Create(
        FBitmapFactory,
        VColor,
        VScaleDegree,
        VShowText,
        VShowLines,
        FCoordToStringConverter.GetStatic
      );
    if VResult <> nil then begin
      VResult :=
        TBitmapLayerProviderComplex.Create(
          FBitmapFactory,
          VResult,
          VProvider
        );
    end else begin
      VResult := VProvider;
    end;
  end;
  if Assigned(VResult) then begin
    Result :=
      TBitmapTileProviderByBitmapTileUniProvider.Create(
        AProjection,
        VResult
      );
  end;
end;

function TProviderMapCombine.PrepareImageProvider(
  const APolygon: IGeometryLonLatPolygon;
  const AProjection: IProjection;
  const AProjectedPolygon: IGeometryProjectedPolygon
): IBitmapTileProvider;
var
  VRect: ILonLatRect;
  VLonLatRect: TDoubleRect;
  VMarksSubset: IVectorItemSubset;
  VPerf: IInternalPerformanceCounterList;
  VMarksConfigStatic: IUsedMarksConfigStatic;
  VTextDrawerBasic: ITextDrawerBasic;
  VIconProvider :IMarkerProviderByAppearancePointIcon;
  VList: IMarkCategoryList;
  VMarksImageProvider: IBitmapTileProvider;
  VRecolorConfig: IBitmapPostProcessing;
  VSourceProvider: IBitmapTileUniProvider;
  VUseMarks: Boolean;
  VUseRecolor: Boolean;
  VVectorTileProvider: IVectorTileUniProvider;
  VVectorTileRenderer: IVectorTileRenderer;
  VMarkerProvider: IMarkerProviderForVectorItem;
  VGridsProvider: IBitmapTileProvider;
  VFillingMapProvider: IBitmapTileProvider;
begin
  VSourceProvider := (ParamsFrame as IRegionProcessParamsFrameImageProvider).Provider;
  Result :=
    TBitmapTileProviderByBitmapTileUniProvider.Create(
      AProjection,
      VSourceProvider
    );
  VUseRecolor := (ParamsFrame as IRegionProcessParamsFrameMapCombine).UseRecolor;
  if VUseRecolor then begin
    VRecolorConfig := FBitmapPostProcessing.GetStatic;
    Result :=
      TBitmapTileProviderWithRecolor.Create(
        VRecolorConfig,
        Result
      );
  end;

  VRect := APolygon.Bounds;
  VLonLatRect := VRect.Rect;
  AProjection.ProjectionType.ValidateLonLatRect(VLonLatRect);

  VUseMarks := (ParamsFrame as IRegionProcessParamsFrameMapCombine).UseMarks;
  if VUseMarks then begin
    VMarksSubset := nil;
    VMarksConfigStatic := FMarksShowConfig.GetStatic;
    if VMarksConfigStatic.IsUseMarks then begin
      VList := nil;
      if not VMarksConfigStatic.IgnoreCategoriesVisible then begin
        VList := FMarksDB.CategoryDB.GetVisibleCategories(AProjection.Zoom);
      end;
      try
        if (VList <> nil) and (VList.Count = 0) then begin
          VMarksSubset := nil;
        end else begin
          VMarksSubset :=
            FMarksDB.MarkDb.GetMarkSubsetByCategoryListInRect(
              VLonLatRect,
              VList,
              VMarksConfigStatic.IgnoreMarksVisible,
              DoublePoint(0, 0) // ToDo
            );
        end;
      finally
        VList := nil;
      end;
    end;
    if VMarksSubset <> nil then begin
      VPerf := TInternalPerformanceCounterFake.Create;
      VTextDrawerBasic :=
        TTextDrawerBasic.Create(
          VPerf,
          FHashFunction,
          FBitmapFactory,
          512,
          1
        );
      VIconProvider :=
        TMarkerProviderByAppearancePointIcon.Create(
          VPerf,
          FHashFunction,
          FBitmapFactory,
          nil
        );

      VMarkerProvider :=
        TMarkerProviderForVectorItemForMarkPoints.Create(
          VTextDrawerBasic,
          VIconProvider
        );
      VVectorTileRenderer :=
        TVectorTileRendererForMarks.Create(
          FMarksDrawConfig.CaptionDrawConfig.GetStatic,
          FBitmapFactory,
          FProjectedGeometryProvider,
          VMarkerProvider
        );
      VVectorTileProvider :=
        TVectorTileProviderByFixedSubset.Create(
          FVectorSubsetBuilderFactory,
          FMarksDrawConfig.DrawOrderConfig.GetStatic.OverSizeRect,
          VMarksSubset
        );
      VMarksImageProvider :=
        TBitmapTileProviderByVectorTileProvider.Create(
          AProjection,
          VVectorTileProvider,
          VVectorTileRenderer
        );
      Result :=
        TBitmapTileProviderComplex.Create(
          FBitmapFactory,
          Result,
          VMarksImageProvider
        );
    end;
  end;
  if (ParamsFrame as IRegionProcessParamsFrameMapCombine).UseFillingMap then begin
    VFillingMapProvider := PrepareFillingMapProvider(AProjection);
    if Assigned(VFillingMapProvider) then begin
      Result :=
        TBitmapTileProviderComplex.Create(
          FBitmapFactory,
          Result,
          VFillingMapProvider
        );
    end;
  end;
  if (ParamsFrame as IRegionProcessParamsFrameMapCombine).UseGrids then begin
    VGridsProvider := PrepareGridsProvider(AProjection);
    if Assigned(VGridsProvider) then begin
      Result :=
        TBitmapTileProviderComplex.Create(
          FBitmapFactory,
          Result,
          VGridsProvider
        );
    end;
  end;

  Result :=
    TBitmapTileProviderInPolygon.Create(
      AProjectedPolygon,
      Result
    );
  Result :=
    TBitmapTileProviderWithBGColor.Create(
      (ParamsFrame as IRegionProcessParamsFrameMapCombine).BGColor,
      (ParamsFrame as IRegionProcessParamsFrameMapCombine).BGColor,
      FBitmapFactory,
      Result
    );
end;

function TProviderMapCombine.PreparePolygon(
  const AProjection: IProjection;
  const APolygon: IGeometryLonLatPolygon
): IGeometryProjectedPolygon;
begin
  Result :=
    FVectorGeometryProjectedFactory.CreateProjectedPolygonByLonLatPolygon(
      AProjection,
      APolygon
    );
end;

function TProviderMapCombine.PrepareProjection: IProjection;
begin
  Result := (ParamsFrame as IRegionProcessParamsFrameTargetProjection).Projection;
end;

function TProviderMapCombine.PrepareTargetRect(
  const AProjection: IProjection;
  const APolygon: IGeometryProjectedPolygon
): TRect;
begin
  Result := RectFromDoubleRect(APolygon.Bounds, rrOutside);
end;

function TProviderMapCombine.PrepareTask(
  const APolygon: IGeometryLonLatPolygon;
  const AProgressInfo: IRegionProcessProgressInfoInternal
): IRegionProcessTask;
var
  VMapCalibrations: IMapCalibrationList;
  VFileName: string;
  VSplitCount: TPoint;
  VSkipExistingFiles: Boolean;
  VProjection: IProjection;
  VProjectedPolygon: IGeometryProjectedPolygon;
  VImageProvider: IBitmapTileProvider;
  VProgressUpdate: IBitmapCombineProgressUpdate;
  VCombiner: IBitmapMapCombiner;
begin
  VProjection := PrepareProjection;
  VProjectedPolygon := PreparePolygon(VProjection, APolygon);
  VImageProvider := PrepareImageProvider(APolygon, VProjection, VProjectedPolygon);
  VMapCalibrations := (ParamsFrame as IRegionProcessParamsFrameMapCalibrationList).MapCalibrationList;
  VFileName := PrepareTargetFileName;
  VSplitCount := (ParamsFrame as IRegionProcessParamsFrameMapCombine).SplitCount;
  VSkipExistingFiles := (ParamsFrame as IRegionProcessParamsFrameMapCombine).SkipExistingFiles;
  VProgressUpdate := PrepareCombineProgressUpdate(AProgressInfo);
  VCombiner := FCombinerFactory.PrepareMapCombiner(ParamsFrame as IRegionProcessParamsFrameMapCombine, VProgressUpdate);
  Result :=
    TRegionProcessTaskCombine.Create(
      AProgressInfo,
      APolygon,
      PrepareTargetRect(VProjection, VProjectedPolygon),
      VCombiner,
      VImageProvider,
      VMapCalibrations,
      VFileName,
      VSplitCount,
      VSkipExistingFiles
    );
end;

function TProviderMapCombine.Validate(
  const APolygon: IGeometryLonLatPolygon
): Boolean;
begin
  Result := inherited Validate(APolygon);
  if Result then begin
    Result := FCombinerFactory.Validate(ParamsFrame as IRegionProcessParamsFrameMapCombine, APolygon);
  end;
end;

function TProviderMapCombine.PrepareTargetFileName: string;
begin
  Result := (ParamsFrame as IRegionProcessParamsFrameTargetPath).Path;
  if Result = '' then begin
    raise Exception.Create(_('Please, select output file first!'));
  end;
end;

end.

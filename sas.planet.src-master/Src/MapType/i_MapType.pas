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

unit i_MapType;

interface

uses
  Types,
  i_Changeable,
  i_MapVersionInfo,
  i_MapVersionFactory,
  i_MapVersionRequest,
  i_TileObjCache,
  i_TileInfoBasicMemCache,
  i_Bitmap32Static,
  i_VectorItemSubset,
  i_Projection,
  i_ProjectionSet,
  i_ZmpInfo,
  i_MapVersionRequestConfig,
  i_MapVersionRequestChangeable,
  i_ContentTypeInfo,
  i_MapAbilitiesConfig,
  i_SimpleTileStorageConfig,
  i_TileDownloadSubsystem,
  i_TileStorage,
  i_LocalCoordConverter,
  i_MapTypeGUIConfig,
  i_LayerDrawConfig,
  i_TileDownloaderConfig,
  i_TileDownloadRequestBuilderConfig,
  i_ConfigDataWriteProvider;

type
  IMapType = interface
    ['{85957D2C-19D7-4F44-A183-F3679B2A5973}']
    procedure SaveConfig(const ALocalConfig: IConfigDataWriteProvider);

    function GetGUID: TGUID;
    property GUID: TGUID read GetGUID;

    procedure ClearMemCache;
    function GetTileShowName(
      const AXY: TPoint;
      const AZoom: byte;
      const AVersion: IMapVersionInfo
    ): string;
    function LoadTile(
      const AXY: TPoint;
      const AZoom: byte;
      const AVersion: IMapVersionRequest;
      IgnoreError: Boolean;
      const ACache: ITileObjCacheBitmap = nil
    ): IBitmap32Static;
    function LoadTileVector(
      const AXY: TPoint;
      const AZoom: byte;
      const AVersion: IMapVersionRequest;
      AUsePre, AIgnoreError: Boolean;
      const ACache: ITileObjCacheVector = nil
    ): IVectorItemSubset;
    function LoadTileUni(
      const AXY: TPoint;
      const AProjection: IProjection;
      const AVersion: IMapVersionRequest;
      AUsePre, AAllowPartial, IgnoreError: Boolean;
      const ACache: ITileObjCacheBitmap = nil
    ): IBitmap32Static;
    function LoadBitmap(
      const APixelRectTarget: TRect;
      const AZoom: byte;
      const AVersion: IMapVersionRequest;
      AUsePre, AAllowPartial, IgnoreError: Boolean;
      const ACache: ITileObjCacheBitmap = nil
    ): IBitmap32Static;
    function LoadBitmapUni(
      const APixelRectTarget: TRect;
      const AProjection: IProjection;
      const AVersion: IMapVersionRequest;
      AUsePre, AAllowPartial, IgnoreError: Boolean;
      const ACache: ITileObjCacheBitmap = nil
    ): IBitmap32Static;

    function GetShortFolderName: string;
    procedure NextVersion(const AView: ILocalCoordConverter; AStep: integer);

    function GetZmp: IZmpInfo;
    property Zmp: IZmpInfo read GetZmp;

    function GetProjectionSet: IProjectionSet;
    property ProjectionSet: IProjectionSet read GetProjectionSet;
    function GetViewProjectionSet: IProjectionSet;
    property ViewProjectionSet: IProjectionSet read GetViewProjectionSet;
    function GetVersionFactory: IMapVersionFactoryChangeable;
    property VersionFactory: IMapVersionFactoryChangeable read GetVersionFactory;
    function GetVersionRequestConfig: IMapVersionRequestConfig;
    property VersionRequestConfig: IMapVersionRequestConfig read GetVersionRequestConfig;
    function GetVersionRequest: IMapVersionRequestChangeable;
    property VersionRequest: IMapVersionRequestChangeable read GetVersionRequest;
    function GetContentType: IContentTypeInfoBasic;
    property ContentType: IContentTypeInfoBasic read GetContentType;

    function GetAbilities: IMapAbilitiesConfig;
    property Abilities: IMapAbilitiesConfig read GetAbilities;
    function GetStorageConfig: ISimpleTileStorageConfig;
    property StorageConfig: ISimpleTileStorageConfig read GetStorageConfig;
    function GetIsBitmapTiles: Boolean;
    property IsBitmapTiles: Boolean read GetIsBitmapTiles;
    function GetIsKmlTiles: Boolean;
    property IsKmlTiles: Boolean read GetIsKmlTiles;

    function GetTileDownloadSubsystem: ITileDownloadSubsystem;
    property TileDownloadSubsystem: ITileDownloadSubsystem read GetTileDownloadSubsystem;
    function GetTileStorage: ITileStorage;
    property TileStorage: ITileStorage read GetTileStorage;
    function GetGUIConfig: IMapTypeGUIConfig;
    property GUIConfig: IMapTypeGUIConfig read GetGUIConfig;
    function GetLayerDrawConfig: ILayerDrawConfig;
    property LayerDrawConfig: ILayerDrawConfig read GetLayerDrawConfig;
    function GetTileDownloaderConfig: ITileDownloaderConfig;
    property TileDownloaderConfig: ITileDownloaderConfig read GetTileDownloaderConfig;
    function GetTileDownloadRequestBuilderConfig: ITileDownloadRequestBuilderConfig;
    property TileDownloadRequestBuilderConfig: ITileDownloadRequestBuilderConfig read GetTileDownloadRequestBuilderConfig;
    function GetCacheBitmap: ITileObjCacheBitmap;
    property CacheBitmap: ITileObjCacheBitmap read GetCacheBitmap;
    function GetCacheVector: ITileObjCacheVector;
    property CacheVector: ITileObjCacheVector read GetCacheVector;
    function GetCacheTileInfo: ITileInfoBasicMemCache;
    property CacheTileInfo: ITileInfoBasicMemCache read GetCacheTileInfo;

  end;

  IMapTypeChangeable = interface(IChangeable)
    ['{8B43402D-0D20-4A6B-8198-71DDAAADD2A9}']
    function GetStatic: IMapType;
  end;

implementation

end.

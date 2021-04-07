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

unit u_TileStorageAbstract;

interface

uses
  Types,
  i_BinaryData,
  i_ProjectionSet,
  i_MapVersionInfo,
  i_MapVersionFactory,
  i_MapVersionRequest,
  i_MapVersionListStatic,
  i_ContentTypeInfo,
  i_TileStorageAbilities,
  i_StorageState,
  i_StorageStateInternal,
  i_TileInfoBasic,
  i_TileStorage,
  i_NotifierOperation,
  i_NotifierTilePyramidUpdate,
  u_BaseInterfacedObject;

type
  TTileStorageAbstract = class(TBaseInterfacedObject, ITileStorage)
  private
    FStorageTypeAbilities: ITileStorageTypeAbilities;
    FProjectionSet: IProjectionSet;
    FMapVersionFactory: IMapVersionFactory;
    FTileNotifier: INotifierTilePyramidUpdate;
    FStoragePath: string;
    FStorageState: IStorageStateChangeble;
    FStorageStateInternal: IStorageStateInternal;
    FTileNotifierInternal: INotifierTilePyramidUpdateInternal;
  protected
    procedure NotifyTileUpdate(
      const ATile: TPoint;
      const AZoom: Byte;
      const AVersion: IMapVersionInfo
    ); inline;
    property StorageStateInternal: IStorageStateInternal read FStorageStateInternal;
    property StoragePath: string read FStoragePath;
    property ProjectionSet: IProjectionSet read FProjectionSet;
    property MapVersionFactory: IMapVersionFactory read FMapVersionFactory;
  protected
    function GetStorageTypeAbilities: ITileStorageTypeAbilities;
    function GetTileNotifier: INotifierTilePyramidUpdate;
    function GetState: IStorageStateChangeble;
    function GetProjectionSet: IProjectionSet;

    function GetTileFileName(
      const AXY: TPoint;
      const AZoom: byte;
      const AVersionInfo: IMapVersionInfo
    ): string; virtual; abstract;
    function GetTileInfo(
      const AXY: TPoint;
      const AZoom: byte;
      const AVersionInfo: IMapVersionInfo;
      const AMode: TGetTileInfoMode
    ): ITileInfoBasic; virtual; abstract;
    function GetTileInfoEx(
      const AXY: TPoint;
      const AZoom: byte;
      const AVersionInfo: IMapVersionRequest;
      const AMode: TGetTileInfoMode
    ): ITileInfoBasic; virtual; abstract;
    function GetTileRectInfo(
      AOperationID: Integer;
      const ACancelNotifier: INotifierOperation;
      const ARect: TRect;
      const AZoom: byte;
      const AVersionInfo: IMapVersionRequest
    ): ITileRectInfo; virtual; abstract;
    function DeleteTile(
      const AXY: TPoint;
      const AZoom: byte;
      const AVersionInfo: IMapVersionInfo
    ): Boolean; virtual; abstract;
    function SaveTile(
      const AXY: TPoint;
      const AZoom: byte;
      const AVersionInfo: IMapVersionInfo;
      const ALoadDate: TDateTime;
      const AContentType: IContentTypeInfoBasic;
      const AData: IBinaryData;
      const AIsOverwrite: Boolean
    ): Boolean; virtual; abstract;

    function GetListOfTileVersions(
      const AXY: TPoint;
      const AZoom: byte;
      const AVersionInfo: IMapVersionRequest
    ): IMapVersionListStatic; virtual;

    function ScanTiles(
      const AIgnoreTNE: Boolean;
      const AIgnoreMultiVersionTiles: Boolean
    ): IEnumTileInfo; virtual;
  public
    constructor Create(
      const AStorageTypeAbilities: ITileStorageTypeAbilities;
      const AStorageForceAbilities: ITileStorageAbilities;
      const AMapVersionFactory: IMapVersionFactory;
      const AProjectionSet: IProjectionSet;
      const ATileNotifier: INotifierTilePyramidUpdateInternal;
      const AStoragePath: string
    );
  end;

implementation

uses
  u_StorageStateInternal;

{ TTileStorageAbstract }

constructor TTileStorageAbstract.Create(
  const AStorageTypeAbilities: ITileStorageTypeAbilities;
  const AStorageForceAbilities: ITileStorageAbilities;
  const AMapVersionFactory: IMapVersionFactory;
  const AProjectionSet: IProjectionSet;
  const ATileNotifier: INotifierTilePyramidUpdateInternal;
  const AStoragePath: string
);
var
  VState: TStorageStateInternal;
begin
  inherited Create;
  FStorageTypeAbilities := AStorageTypeAbilities;
  FMapVersionFactory := AMapVersionFactory;
  FStoragePath := AStoragePath;
  FProjectionSet := AProjectionSet;

  VState := TStorageStateInternal.Create(AStorageForceAbilities);
  FStorageStateInternal := VState;
  FStorageState := VState;

  FTileNotifier := ATileNotifier;
  FTileNotifierInternal := ATileNotifier;
end;

function TTileStorageAbstract.GetProjectionSet: IProjectionSet;
begin
  Result := FProjectionSet;
end;

function TTileStorageAbstract.GetListOfTileVersions(
  const AXY: TPoint;
  const AZoom: byte;
  const AVersionInfo: IMapVersionRequest
): IMapVersionListStatic;
begin
  Result := nil;
end;

function TTileStorageAbstract.GetTileNotifier: INotifierTilePyramidUpdate;
begin
  Result := FTileNotifier;
end;

function TTileStorageAbstract.GetState: IStorageStateChangeble;
begin
  Result := FStorageState;
end;

function TTileStorageAbstract.GetStorageTypeAbilities: ITileStorageTypeAbilities;
begin
  Result := FStorageTypeAbilities;
end;

procedure TTileStorageAbstract.NotifyTileUpdate(
  const ATile: TPoint;
  const AZoom: Byte;
  const AVersion: IMapVersionInfo
);
begin
  if Assigned(FTileNotifierInternal) then begin
    FTileNotifierInternal.TileUpdateNotify(ATile, AZoom);
  end;
end;

function TTileStorageAbstract.ScanTiles(
  const AIgnoreTNE: Boolean;
  const AIgnoreMultiVersionTiles: Boolean
): IEnumTileInfo;
begin
  Result := nil;
end;

end.

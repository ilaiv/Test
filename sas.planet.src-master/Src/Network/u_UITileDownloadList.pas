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

unit u_UITileDownloadList;

interface

uses
  i_NotifierOperation,
  i_DownloadUIConfig,
  i_TileRectChangeable,
  i_NotifierTime,
  i_MapTypeSet,
  i_MapTypeSetChangeable,
  i_DownloadInfoSimple,
  i_GlobalInternetState,
  i_InterfaceListStatic,
  i_TileError,
  u_BaseInterfacedObject;

type
  TUITileDownloadList = class(TBaseInterfacedObject)
  private
    FList: IInterfaceListStatic;
  public
    constructor Create(
      const AGCNotifier: INotifierTime;
      const AAppClosingNotifier: INotifierOneOperation;
      const AConfig: IDownloadUIConfig;
      const ATileRect: ITileRectChangeable;
      const AMapsSet: IMapTypeSet;
      const AActiveMaps: IMapTypeSetChangeable;
      const ADownloadInfo: IDownloadInfoSimple;
      const AGlobalInternetState: IGlobalInternetState;
      const AErrorLogger: ITileErrorLogger
    );
  end;

implementation

uses
  i_InterfaceListSimple,
  i_MapType,
  u_InterfaceListSimple,
  u_UiTileDownload;

{ TUITileDownloadList }

constructor TUITileDownloadList.Create(
  const AGCNotifier: INotifierTime;
  const AAppClosingNotifier: INotifierOneOperation;
  const AConfig: IDownloadUIConfig;
  const ATileRect: ITileRectChangeable;
  const AMapsSet: IMapTypeSet;
  const AActiveMaps: IMapTypeSetChangeable;
  const ADownloadInfo: IDownloadInfoSimple;
  const AGlobalInternetState: IGlobalInternetState;
  const AErrorLogger: ITileErrorLogger
);
var
  VDownload: IInterface;
  VList: IInterfaceListSimple;
  VMapType: IMapType;
  i: Integer;
begin
  Assert(Assigned(AMapsSet));
  inherited Create;
  VList := TInterfaceListSimple.Create;
  for i := 0 to AMapsSet.Count - 1 do begin
    VMapType := AMapsSet.Items[i];
    if VMapType.Zmp.TileDownloaderConfig.Enabled then begin
      VDownload :=
        TUiTileDownload.Create(
          AConfig,
          AGCNotifier,
          AAppClosingNotifier,
          ATileRect,
          VMapType,
          AActiveMaps,
          ADownloadInfo,
          AGlobalInternetState,
          AErrorLogger
        );
      VList.Add(VDownload);
    end;
  end;

  FList := VList.MakeStaticAndClear;
end;

end.

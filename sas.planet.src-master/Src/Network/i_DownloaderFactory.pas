{******************************************************************************}
{* SAS.Planet (SAS.???????)                                                   *}
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

unit i_DownloaderFactory;

interface

uses
  i_Downloader;

type
  IDownloaderFactory = interface
    ['{1B4DEDE8-01C2-4513-974D-FDD2A0CF8E82}']
    function BuildDownloader(
      const AAllowUseCookie: Boolean;
      const AAllowRedirect: Boolean;
      const ATryDetectContentType: Boolean;
      const AOnDownloadProgress: TOnDownloadProgress
    ): IDownloader;

    function BuildDownloaderAsync(
      const AAllowUseCookie: Boolean;
      const AAllowRedirect: Boolean;
      const ATryDetectContentType: Boolean;
      const AOnDownloadProgress: TOnDownloadProgress
    ): IDownloaderAsync;
  end;

implementation

end.

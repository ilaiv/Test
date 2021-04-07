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

unit i_TileDownloadRequestBuilderConfig;

interface

uses
  i_ConfigDataElement;

type
  ITileDownloadRequestBuilderConfigStatic = interface
    ['{84B1A72C-951D-4591-80E4-3DA0CDC30ED7}']
    function GetUrlBase: AnsiString;
    property UrlBase: AnsiString read GetUrlBase;

    function GetServerNames: AnsiString;
    property ServerNames: AnsiString read GetServerNames;

    function GetRequestHeader: AnsiString;
    property RequestHeader: AnsiString read GetRequestHeader;

    function GetIsUseDownloader: Boolean;
    property IsUseDownloader: Boolean read GetIsUseDownloader;

    function GetDefaultProjConverterArgs: AnsiString;
    property DefaultProjConverterArgs: AnsiString read GetDefaultProjConverterArgs;
  end;


  ITileDownloadRequestBuilderConfig = interface(IConfigDataElement)
    ['{FA554C29-EDAF-4E3C-9B59-BC881502F33A}']
    function GetUrlBase: AnsiString;
    procedure SetUrlBase(const AValue: AnsiString);
    property UrlBase: AnsiString read GetUrlBase write SetUrlBase;

    function GetServerNames: AnsiString;
    procedure SetServerNames(const AValue: AnsiString);
    property ServerNames: AnsiString read GetServerNames write SetServerNames;

    function GetRequestHeader: AnsiString;
    procedure SetRequestHeader(const AValue: AnsiString);
    property RequestHeader: AnsiString read GetRequestHeader write SetRequestHeader;

    function GetIsUseDownloader: Boolean;
    property IsUseDownloader: Boolean read GetIsUseDownloader;

    function GetDefaultProjConverterArgs: AnsiString;
    property DefaultProjConverterArgs: AnsiString read GetDefaultProjConverterArgs;
  end;

implementation

end.

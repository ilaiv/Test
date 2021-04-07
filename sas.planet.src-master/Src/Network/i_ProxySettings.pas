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

unit i_ProxySettings;

interface

uses
  i_ConfigDataElement;

type
  TProxyServerType = (
    ptHttp,
    ptHttps,
    ptSocks4,
    ptSocks4a,
    ptSocks5,
    ptSocks5h
  );

  IProxyConfigStatic = interface(IInterface)
    ['{DD723CA2-3A8F-4350-B04E-284B00AC47EA}']
    function GetUseIESettings: Boolean;
    property UseIESettings: Boolean read GetUseIESettings;

    function GetUseProxy: boolean;
    property UseProxy: boolean read GetUseProxy;

    function GetProxyType: TProxyServerType;
    property ProxyType: TProxyServerType read GetProxyType;

    function GetHost: AnsiString;
    property Host: AnsiString read GetHost;

    function GetUseLogin: boolean;
    property UseLogin: boolean read GetUseLogin;

    function GetLogin: string;
    property Login: string read GetLogin;

    function GetPassword: string;
    property Password: string read GetPassword;
  end;

  IProxyConfig = interface(IConfigDataElement)
    ['{0CE5A97E-471D-4A3E-93E3-D130DD1F50F5}']
    function GetUseIESettings: Boolean; safecall;
    procedure SetUseIESettings(AValue: Boolean);
    property UseIESettings: Boolean read GetUseIESettings write SetUseIESettings;

    function GetUseProxy: Boolean; safecall;
    procedure SetUseProxy(AValue: Boolean);
    property UseProxy: boolean read GetUseProxy write SetUseProxy;

    function GetProxyType: TProxyServerType;
    procedure SetProxyType(const AValue: TProxyServerType);
    property ProxyType: TProxyServerType read GetProxyType write SetProxyType;

    function GetHost: AnsiString; safecall;
    procedure SetHost(const AValue: AnsiString);
    property Host: AnsiString read GetHost write SetHost;

    function GetUseLogin: boolean; safecall;
    procedure SetUseLogin(AValue: Boolean);
    property UseLogin: boolean read GetUseLogin write SetUseLogin;

    function GetLogin: string; safecall;
    procedure SetLogin(const AValue: string);
    property Login: string read GetLogin write SetLogin;

    function GetPassword: string; safecall;
    procedure SetPassword(const AValue: string);
    property Password: string read GetPassword write SetPassword;

    function GetStatic: IProxyConfigStatic;
  end;

implementation

end.

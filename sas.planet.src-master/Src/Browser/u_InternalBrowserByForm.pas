{******************************************************************************}
{* SAS.Planet (SAS.�������)                                                   *}
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

unit u_InternalBrowserByForm;

interface

uses
  i_InetConfig,
  i_DownloadRequest,
  i_InternalBrowser,
  i_LanguageManager,
  i_InternalBrowserLastContent,
  i_WindowPositionConfig,
  i_InternalDomainUrlHandler,
  u_BaseInterfacedObject,
  frm_InternalBrowser;

type
  TInternalBrowserByForm = class(TBaseInterfacedObject, IInternalBrowser)
  private
    FLanguageManager: ILanguageManager;
    FInetConfig: IInetConfig;
    FConfig: IWindowPositionConfig;
    FContent: IInternalBrowserLastContent;
    FUrlHandler: IInternalDomainUrlHandler;
    FfrmInternalBrowser: TfrmInternalBrowser;
  private
    procedure SafeCreateInternal;
  private
    { IInternalBrowser }
    procedure ShowMessage(const ACaption, AText: string);
    procedure Navigate(const ACaption, AUrl: string);
    procedure NavigateByRequest(const ACaption: string; const ARequest: IDownloadRequest);
  public
    constructor Create(
      const ALanguageManager: ILanguageManager;
      const AContent: IInternalBrowserLastContent;
      const AConfig: IWindowPositionConfig;
      const AInetConfig: IInetConfig;
      const AUrlHandler: IInternalDomainUrlHandler
    );
    destructor Destroy; override;
  end;

implementation

uses
  SysUtils,
  c_InternalBrowser;

{ TInternalBrowserByForm }

constructor TInternalBrowserByForm.Create(
  const ALanguageManager: ILanguageManager;
  const AContent: IInternalBrowserLastContent;
  const AConfig: IWindowPositionConfig;
  const AInetConfig: IInetConfig;
  const AUrlHandler: IInternalDomainUrlHandler
);
begin
  inherited Create;
  FLanguageManager := ALanguageManager;
  FContent := AContent;
  FConfig := AConfig;
  FInetConfig := AInetConfig;
  FUrlHandler := AUrlHandler;
end;

destructor TInternalBrowserByForm.Destroy;
begin
  if FfrmInternalBrowser <> nil then begin
    FreeAndNil(FfrmInternalBrowser);
  end;
  inherited;
end;

procedure TInternalBrowserByForm.ShowMessage(const ACaption, AText: string);
begin
  SafeCreateInternal;
  FContent.Content := AText;
  FfrmInternalBrowser.Navigate(ACaption, CShowMessageInternalURL);
end;

procedure TInternalBrowserByForm.Navigate(const ACaption, AUrl: string);
begin
  SafeCreateInternal;
  FfrmInternalBrowser.Navigate(ACaption, AUrl);
end;

procedure TInternalBrowserByForm.NavigateByRequest(
  const ACaption: string;
  const ARequest: IDownloadRequest
);
begin
  SafeCreateInternal;
  FfrmInternalBrowser.NavigateByRequest(ACaption, ARequest);
end;

procedure TInternalBrowserByForm.SafeCreateInternal;
begin
  if FfrmInternalBrowser = nil then begin
    FfrmInternalBrowser :=
      TfrmInternalBrowser.Create(
        FLanguageManager,
        FConfig,
        FInetConfig,
        FUrlHandler
      );
  end;
end;

end.

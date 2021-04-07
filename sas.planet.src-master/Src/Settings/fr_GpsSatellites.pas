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

unit fr_GpsSatellites;

interface

uses
  Classes,
  Controls,
  Forms,
  ExtCtrls,
  StdCtrls,
  GR32_Image,
  i_SimpleFlag,
  i_NotifierTime,
  i_ListenerNotifierLinksList,
  i_LanguageManager,
  i_Sensor,
  i_SatellitesInViewMapDraw,
  u_CommonFormAndFrameParents;

type
  TfrGpsSatellites = class(TFrame)
    SatellitePaintBox: TImage32;
    pnlSatInfoLegend: TPanel;
    pnlSatInfoActive: TPanel;
    lblSatInfoActive: TLabel;
    shpSatInfoActive: TShape;
    pnlSatInfoVisible: TPanel;
    shpSatInfoVisible: TShape;
    lblSatInfoVisible: TLabel;
    pnlSatInfoZeroSignal: TPanel;
    lblSatInfoZeroSignal: TLabel;
    shpSatInfoZeroSignal: TShape;
    procedure SatellitePaintBoxResize(Sender: TObject);
  private
    FGpsSatellitesSensor: ISensorGPSSatellites;
    FMapDraw: ISatellitesInViewMapDraw;

    FLinksList: IListenerNotifierLinksList;
    FValueChangeCounter: ICounter;
    FValueShowId: Integer;

    function CheckVisible: Boolean;
    procedure OnSensorDataUpdate;
    procedure OnTimer;
    procedure UpdateDataView;
  public
    constructor Create(
      const ALanguageManager: ILanguageManager;
      const ATimerNoifier: INotifierTime;
      const AGpsSatellitesSensor: ISensorGPSSatellites;
      const AMapDraw: ISatellitesInViewMapDraw;
      AShowLegend: Boolean
    );
  end;

implementation

uses
  i_GPS,
  u_SimpleFlagWithInterlock,
  u_ListenerNotifierLinksList,
  u_ListenerTime,
  u_ListenerByEvent;

{$R *.dfm}

constructor TfrGpsSatellites.Create(
  const ALanguageManager: ILanguageManager;
  const ATimerNoifier: INotifierTime;
  const AGpsSatellitesSensor: ISensorGPSSatellites;
  const AMapDraw: ISatellitesInViewMapDraw;
  AShowLegend: Boolean
);
begin
  inherited Create(ALanguageManager);
  FGpsSatellitesSensor := AGpsSatellitesSensor;
  FMapDraw := AMapDraw;

  pnlSatInfoLegend.Visible := AShowLegend;

  FLinksList := TListenerNotifierLinksList.Create;
  FValueChangeCounter := TCounterInterlock.Create;

  FLinksList.Add(
    TNotifyNoMmgEventListener.Create(Self.OnSensorDataUpdate),
    FGpsSatellitesSensor.ChangeNotifier
  );

  FLinksList.Add(
    TListenerTimeCheck.Create(Self.OnTimer, 1000),
    ATimerNoifier
  );

  FLinksList.ActivateLinks;
  OnSensorDataUpdate;
end;

function TfrGpsSatellites.CheckVisible: Boolean;
var
  VParent: TWinControl;
begin
  Result := Visible;
  if Result then begin
    VParent := Self.Parent;
    while VParent <> nil do begin
      Result := VParent.Visible;
      if Result then begin
        VParent := VParent.Parent;
      end else begin
        VParent := nil;
      end;
    end;
  end;
end;

procedure TfrGpsSatellites.OnSensorDataUpdate;
begin
  FValueChangeCounter.Inc;
end;

procedure TfrGpsSatellites.OnTimer;
var
  VId: Integer;
begin
  if Self.Visible then begin
    VId := FValueChangeCounter.GetValue;
    if VId <> FValueShowId then begin
      UpdateDataView;
      FValueShowId := VId;
    end;
  end;
end;

procedure TfrGpsSatellites.SatellitePaintBoxResize(Sender: TObject);
begin
  SatellitePaintBox.Bitmap.Lock;
  try
    SatellitePaintBox.Bitmap.SetSizeFrom(SatellitePaintBox);
    UpdateDataView;
  finally
    SatellitePaintBox.Bitmap.Unlock;
  end;
end;

procedure TfrGpsSatellites.UpdateDataView;
var
  VSatellites: IGPSSatellitesInView;
begin
  if CheckVisible then begin
    VSatellites := FGpsSatellitesSensor.Info;
    SatellitePaintBox.Bitmap.Lock;
    try
      FMapDraw.Draw(SatellitePaintBox.Bitmap, VSatellites);
    finally
      SatellitePaintBox.Bitmap.Unlock;
    end;
  end;
end;

end.

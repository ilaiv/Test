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

unit frm_MarkInfo;

interface

uses
  SysUtils,
  Classes,
  Controls,
  Forms,
  StdCtrls,
  ExtCtrls,
  OleCtrls,
  i_NotifierOperation,
  i_LanguageManager,
  i_GeometryLonLat,
  i_GeoCalc,
  i_CoordToStringConverter,
  i_ValueToStringConverter,
  i_VectorDataItemSimple,
  i_InetConfig,
  i_InternalDomainUrlHandler,
  u_InternalBrowserImplByIE,
  u_CommonFormAndFrameParents;

type
  TfrmMarkInfo = class(TFormWitghLanguageManager)
    mmoInfo: TMemo;
    splDesc: TSplitter;
    pnlDesc: TPanel;
    procedure FormClose(
      Sender: TObject;
      var Action: TCloseAction
    );
    procedure FormDestroy(Sender: TObject);
  private
    FBrowser: TInternalBrowserImplByIE;
    FCancelNotifier: INotifierOperationInternal;
    FCoordToStringConverter: ICoordToStringConverterChangeable;
    FValueToStringConverter: IValueToStringConverterChangeable;
    FGeoCalc: IGeoCalc;
    FArea: Double;
    FMark: IVectorDataItem;
    procedure OnAreaCalc(const AArea: Double);
    function GetTextForMark(const AMark: IVectorDataItem): string;
    function GetTextForGeometry(const AGeometry: IGeometryLonLat): string;
    function GetTextForPoint(const APoint: IGeometryLonLatPoint): string;
    function GetTextForLine(const ALine: IGeometryLonLatSingleLine): string;
    function GetTextForMultiLine(const ALine: IGeometryLonLatMultiLine): string;
    function GetTextForPoly(const APoly: IGeometryLonLatSinglePolygon): string;
    function GetTextForMultiPoly(const APoly: IGeometryLonLatMultiPolygon): string;
  public
    procedure ShowInfoModal(const AMark: IVectorDataItem);
  public
    constructor Create(
      const ALanguageManager: ILanguageManager;
      const ACoordToStringConverter: ICoordToStringConverterChangeable;
      const AValueToStringConverter: IValueToStringConverterChangeable;
      const AGeoCalc: IGeoCalc;
      const AInetConfig: IInetConfig;
      const AInternalDomainUrlHandler: IInternalDomainUrlHandler
    ); reintroduce;
  end;

implementation

uses
  Math,
  gnugettext,
  c_InternalBrowser,
  u_Notifier,
  u_NotifierOperation,
  u_Synchronizer,
  u_ReadableThreadNames;

{$R *.dfm}

type
  TOnAreaCalc = procedure(const AArea: Double) of object;

  TCalcAreaThread = class(TThread)
  private
    FPoly: IGeometryLonLatPolygon;
    FGeoCalc: IGeoCalc;
    FArea: Double;
    FOnFinish: TOnAreaCalc;
    FOperationID: Cardinal;
    FCancelNotifier: INotifierOperation;
    procedure OnFinishSync;
  protected
    procedure Execute; override;
  public
    constructor Create(
      const APoly: IGeometryLonLatPolygon;
      const AGeoCalc: IGeoCalc;
      const ACancelNotifier: INotifierOperation;
      const AOperationID: Cardinal;
      const AOnFinish: TOnAreaCalc
    );
  end;

{ TCalcAreaThread }

constructor TCalcAreaThread.Create(
  const APoly: IGeometryLonLatPolygon;
  const AGeoCalc: IGeoCalc;
  const ACancelNotifier: INotifierOperation;
  const AOperationID: Cardinal;
  const AOnFinish: TOnAreaCalc
);
begin
  FPoly := APoly;
  FGeoCalc := AGeoCalc;
  FArea := 0;
  FOperationID := AOperationID;
  FCancelNotifier := ACancelNotifier;
  FOnFinish := AOnFinish;
  FreeOnTerminate := True;
  inherited Create(False);
end;

procedure TCalcAreaThread.OnFinishSync;
begin
  if not FCancelNotifier.IsOperationCanceled(FOperationID) then begin
    FOnFinish(FArea);
  end;
end;

procedure TCalcAreaThread.Execute;
begin
  SetCurrentThreadName(Self.ClassName);
  FArea := FGeoCalc.CalcPolygonArea(FPoly, FCancelNotifier, FOperationID);
  if FCancelNotifier.IsOperationCanceled(FOperationID) then begin
    Terminate;
  end else begin
    Synchronize(OnFinishSync);
  end;
end;

{ TfrmMarkInfo }

constructor TfrmMarkInfo.Create(
  const ALanguageManager: ILanguageManager;
  const ACoordToStringConverter: ICoordToStringConverterChangeable;
  const AValueToStringConverter: IValueToStringConverterChangeable;
  const AGeoCalc: IGeoCalc;
  const AInetConfig: IInetConfig;
  const AInternalDomainUrlHandler: IInternalDomainUrlHandler
);
begin
  Assert(ACoordToStringConverter <> nil);
  Assert(AValueToStringConverter <> nil);
  Assert(AGeoCalc <> nil);
  Assert(AInetConfig <> nil);
  Assert(AInternalDomainUrlHandler <> nil);

  inherited Create(ALanguageManager);
  FCoordToStringConverter := ACoordToStringConverter;
  FValueToStringConverter := AValueToStringConverter;
  FGeoCalc := AGeoCalc;
  FCancelNotifier :=
    TNotifierOperation.Create(
      TNotifierBase.Create(GSync.SyncVariable.Make(Self.ClassName + 'Notifier'))
    );
  FBrowser :=
    TInternalBrowserImplByIE.Create(
      pnlDesc,
      False,
      AInetConfig.ProxyConfig,
      AInternalDomainUrlHandler,
      AInetConfig.UserAgentString
    );
end;

procedure TfrmMarkInfo.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FBrowser);
end;

procedure TfrmMarkInfo.FormClose(
  Sender: TObject;
  var Action: TCloseAction
);
begin
  FCancelNotifier.NextOperation;
end;

function TfrmMarkInfo.GetTextForGeometry(
  const AGeometry: IGeometryLonLat
): string;
var
  VPoint: IGeometryLonLatPoint;
  VLine: IGeometryLonLatSingleLine;
  VMultiLine: IGeometryLonLatMultiLine;
  VPoly: IGeometryLonLatSinglePolygon;
  VMultiPoly: IGeometryLonLatMultiPolygon;
begin
  Result := '';
  if Supports(AGeometry, IGeometryLonLatPoint, VPoint) then begin
    Result := GetTextForPoint(VPoint);
  end else if Supports(AGeometry, IGeometryLonLatSingleLine, VLine) then begin
    Result := GetTextForLine(VLine);
  end else if Supports(AGeometry, IGeometryLonLatMultiLine, VMultiLine) then begin
    Result := GetTextForMultiLine(VMultiLine);
  end else if Supports(AGeometry, IGeometryLonLatSinglePolygon, VPoly) then begin
    Result := GetTextForPoly(VPoly);
    if IsNan(FArea) then begin
      TCalcAreaThread.Create(
        VPoly,
        FGeoCalc,
        FCancelNotifier,
        FCancelNotifier.CurrentOperation,
        Self.OnAreaCalc
      );
    end;
  end else if Supports(AGeometry, IGeometryLonLatMultiPolygon, VMultiPoly) then begin
    Result := GetTextForMultiPoly(VMultiPoly);
    if IsNan(FArea) then begin
      TCalcAreaThread.Create(
        VMultiPoly,
        FGeoCalc,
        FCancelNotifier,
        FCancelNotifier.CurrentOperation,
        Self.OnAreaCalc
      );
    end;
  end;
end;

function TfrmMarkInfo.GetTextForMark(
  const AMark: IVectorDataItem
): string;
var
  VItemWithCategory: IVectorDataItemWithCategory;
  VCategoryName: string;
begin
  Result := '';
  VCategoryName := '';
  if Supports(AMark.MainInfo, IVectorDataItemWithCategory, VItemWithCategory) then begin
    if VItemWithCategory.Category <> nil then begin
      VCategoryName := VItemWithCategory.Category.Name;
    end;
  end;
  Result := Result + Format(_('Category: %s'), [VCategoryName]) + #13#10;
  Result := Result + Format(_('Name: %s'), [AMark.Name]) + #13#10;
  Result := Result + GetTextForGeometry(AMark.Geometry);
end;

function TfrmMarkInfo.GetTextForLine(const ALine: IGeometryLonLatSingleLine): string;
var
  VLength: Double;
  VPartsCount: Integer;
  VPointsCount: Integer;
  VConverter: IValueToStringConverter;
begin
  VPartsCount := 1;
  VPointsCount := ALine.Count;
  VLength := FGeoCalc.CalcLineLength(ALine);
  VConverter := FValueToStringConverter.GetStatic;
  Result := '';
  Result := Result + Format(_('Parts count: %d'), [VPartsCount]) + #13#10;
  Result := Result + Format(_('Points count: %d'), [VPointsCount]) + #13#10;
  Result := Result + Format(_('Length: %s'), [VConverter.DistConvert(VLength)]) + #13#10;
end;

function TfrmMarkInfo.GetTextForMultiLine(const ALine: IGeometryLonLatMultiLine): string;
var
  VLength: Double;
  VPartsCount: Integer;
  VPointsCount: Integer;
  i: Integer;
  VConverter: IValueToStringConverter;
begin
  VPartsCount := ALine.Count;
  VPointsCount := 0;
  for i := 0 to VPartsCount - 1 do begin
    Inc(VPointsCount, ALine.Item[i].Count);
  end;
  VLength := FGeoCalc.CalcMultiLineLength(ALine);
  VConverter := FValueToStringConverter.GetStatic;
  Result := '';
  Result := Result + Format(_('Parts count: %d'), [VPartsCount]) + #13#10;
  Result := Result + Format(_('Points count: %d'), [VPointsCount]) + #13#10;
  Result := Result + Format(_('Length: %s'), [VConverter.DistConvert(VLength)]) + #13#10;
end;

function TfrmMarkInfo.GetTextForPoint(const APoint: IGeometryLonLatPoint): string;
var
  VConverter: ICoordToStringConverter;
begin
  VConverter := FCoordToStringConverter.GetStatic;
  Result := '';
  Result := Result + Format(_('Coordinates: %s'), [VConverter.LonLatConvert(APoint.Point)]) + #13#10;
end;

function CalcPolyPointsCount(const APoly: IGeometryLonLatSinglePolygon): Integer; inline;
var
  i: Integer;
begin
  Result := APoly.OuterBorder.Count;
  for i := 0 to APoly.HoleCount - 1 do begin
    Inc(Result, APoly.HoleBorder[i].Count);
  end;
end;

function TfrmMarkInfo.GetTextForPoly(const APoly: IGeometryLonLatSinglePolygon): string;
var
  VLength: Double;
  VPartsCount: Integer;
  VPointsCount: Integer;
  VConverter: IValueToStringConverter;
begin
  VPartsCount := 1;
  VPointsCount := CalcPolyPointsCount(APoly);
  VLength := FGeoCalc.CalcPolygonPerimeter(APoly);
  VConverter := FValueToStringConverter.GetStatic;
  Result := '';
  Result := Result + Format(_('Parts count: %d'), [VPartsCount]) + #13#10;
  Result := Result + Format(_('Points count: %d'), [VPointsCount]) + #13#10;
  Result := Result + Format(_('Perimeter: %s'), [VConverter.DistConvert(VLength)]) + #13#10;
  if not IsNan(FArea) then begin
    Result := Result + Format(_('Area: %s'), [VConverter.AreaConvert(FArea)]) + #13#10;
  end else begin
    Result := Result + Format(_('Area: %s'), [_('calc...')]) + #13#10;
  end;
end;

function TfrmMarkInfo.GetTextForMultiPoly(const APoly: IGeometryLonLatMultiPolygon): string;
var
  VLength: Double;
  VPartsCount: Integer;
  VPointsCount: Integer;
  i: Integer;
  VConverter: IValueToStringConverter;
begin
  VPartsCount := APoly.Count;
  VPointsCount := 0;
  for i := 0 to VPartsCount - 1 do begin
    Inc(VPointsCount, CalcPolyPointsCount(APoly.Item[i]));
  end;
  VLength := FGeoCalc.CalcMultiPolygonPerimeter(APoly);
  VConverter := FValueToStringConverter.GetStatic;
  Result := '';
  Result := Result + Format(_('Parts count: %d'), [VPartsCount]) + #13#10;
  Result := Result + Format(_('Points count: %d'), [VPointsCount]) + #13#10;
  Result := Result + Format(_('Perimeter: %s'), [VConverter.DistConvert(VLength)]) + #13#10;
  if not IsNan(FArea) then begin
    Result := Result + Format(_('Area: %s'), [VConverter.AreaConvert(FArea)]) + #13#10;
  end else begin
    Result := Result + Format(_('Area: %s'), [_('calc...')]) + #13#10;
  end;
end;

procedure TfrmMarkInfo.OnAreaCalc(const AArea: Double);
begin
  FArea := AArea;
  mmoInfo.Lines.Text := GetTextForMark(FMark);
end;

procedure TfrmMarkInfo.ShowInfoModal(const AMark: IVectorDataItem);
var
  VText: string;
begin
  FArea := NaN;
  FMark := AMark;
  VText := GetTextForMark(AMark);
  mmoInfo.Lines.Text := VText;
  if (AMark.GetInfoUrl <> '') and (AMark.Desc <> '') then begin
    FBrowser.Navigate(AMark.GetInfoUrl + CVectorItemInfoSuffix);
  end else begin
    FBrowser.AssignEmptyDocument;
  end;
  Self.ShowModal;
  FMark := nil;
end;

end.

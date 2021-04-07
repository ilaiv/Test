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

unit u_BitmapMapCombinerPNG;

interface

uses
  i_InternalPerformanceCounter,
  i_BitmapMapCombiner,
  i_RegionProcessParamsFrame,
  u_BitmapMapCombinerFactoryBase;

type
  TBitmapMapCombinerFactoryPNG = class(TBitmapMapCombinerFactoryBase)
  private
    FSaveRectCounter: IInternalPerformanceCounter;
    FPrepareDataCounter: IInternalPerformanceCounter;
    FGetLineCounter: IInternalPerformanceCounter;
  protected
    function PrepareMapCombiner(
      const AParams: IRegionProcessParamsFrameMapCombine;
      const AProgressInfo: IBitmapCombineProgressUpdate
    ): IBitmapMapCombiner; override;
  public
    constructor Create(
      const ACounterList: IInternalPerformanceCounterList
    );
  end;

implementation

uses
  SysUtils,
  Classes,
  Types,
  gnugettext,
  LibPngWriter,
  t_CommonTypes,
  t_MapCombineOptions,
  i_ImageLineProvider,
  i_NotifierOperation,
  i_BitmapTileProvider,
  u_BaseInterfacedObject,
  u_ImageLineProvider,
  u_GeoFunc,
  u_ResStrings;

type
  TBitmapMapCombinerPNG = class(TBaseInterfacedObject, IBitmapMapCombiner)
  private
    FProgressUpdate: IBitmapCombineProgressUpdate;
    FWidth: Integer;
    FHeight: Integer;
    FWithAlpha: Boolean;
    FSaveRectCounter: IInternalPerformanceCounter;
    FPrepareDataCounter: IInternalPerformanceCounter;
    FGetLineCounter: IInternalPerformanceCounter;
    FLineProvider: IImageLineProvider;
    FOperationID: Integer;
    FCancelNotifier: INotifierOperation;
  private
    function GetLineCallBack(
      const ARowNumber: Integer;
      const ALineSize: Integer;
      const AUserInfo: Pointer
    ): Pointer;
  private
    procedure SaveRect(
      AOperationID: Integer;
      const ACancelNotifier: INotifierOperation;
      const AFileName: string;
      const AImageProvider: IBitmapTileProvider;
      const AMapRect: TRect
    );
  public
    constructor Create(
      const AProgressUpdate: IBitmapCombineProgressUpdate;
      const ASaveRectCounter: IInternalPerformanceCounter;
      const APrepareDataCounter: IInternalPerformanceCounter;
      const AGetLineCounter: IInternalPerformanceCounter;
      AWithAlpha: Boolean
    );
  end;

{ TThreadMapCombinePNG }

constructor TBitmapMapCombinerPNG.Create(
  const AProgressUpdate: IBitmapCombineProgressUpdate;
  const ASaveRectCounter: IInternalPerformanceCounter;
  const APrepareDataCounter: IInternalPerformanceCounter;
  const AGetLineCounter: IInternalPerformanceCounter;
  AWithAlpha: Boolean
);
begin
  inherited Create;
  FProgressUpdate := AProgressUpdate;
  FSaveRectCounter := ASaveRectCounter;
  FPrepareDataCounter := APrepareDataCounter;
  FGetLineCounter := AGetLineCounter;
  FWithAlpha := AWithAlpha;
end;

procedure TBitmapMapCombinerPNG.SaveRect(
  AOperationID: Integer;
  const ACancelNotifier: INotifierOperation;
  const AFileName: string;
  const AImageProvider: IBitmapTileProvider;
  const AMapRect: TRect
);
const
  PNG_MAX_HEIGHT = 65536;
  PNG_MAX_WIDTH = 65536;
var
  VDest: TFileStream;
  VBitsPerPix: Integer;
  VCurrentPieceRect: TRect;
  VMapPieceSize: TPoint;
  VPngWriter: TLibPngWriter;
  VContext: TInternalPerformanceCounterContext;
begin
  FOperationID := AOperationID;
  FCancelNotifier := ACancelNotifier;

  VContext := FSaveRectCounter.StartOperation;
  try
  VCurrentPieceRect := AMapRect;
  VMapPieceSize := RectSize(VCurrentPieceRect);

  FWidth := VMapPieceSize.X;
  FHeight := VMapPieceSize.Y;

  if (FWidth >= PNG_MAX_WIDTH) or (FHeight >= PNG_MAX_HEIGHT) then begin
    raise Exception.CreateFmt(
      SAS_ERR_ImageIsTooBig,
      ['PNG', FWidth, PNG_MAX_WIDTH, FHeight, PNG_MAX_HEIGHT, 'PNG']
    );
  end;

  if FWithAlpha then begin
    VBitsPerPix := 32;
    FLineProvider :=
      TImageLineProviderRGBA.Create(
        FPrepareDataCounter,
        FGetLineCounter,
        AImageProvider,
        AMapRect
      );
  end else begin
    VBitsPerPix := 24;
    FLineProvider :=
      TImageLineProviderRGB.Create(
        FPrepareDataCounter,
        FGetLineCounter,
        AImageProvider,
        AMapRect
      );
  end;

  VDest := TFileStream.Create(AFileName, fmCreate);
  try
    VPngWriter := TLibPngWriter.Create;
    try
      VPngWriter.Write(
        VDest,
        FWidth,
        FHeight,
        VBitsPerPix,
        Self.GetLineCallBack
      );
    finally
      VPngWriter.Free;
    end;
  finally
    VDest.Free;
  end;
  finally
    FSaveRectCounter.FinishOperation(VContext);
  end;
end;

function TBitmapMapCombinerPNG.GetLineCallBack(
  const ARowNumber: Integer;
  const ALineSize: Integer;
  const AUserInfo: Pointer
): Pointer;
begin
  if ARowNumber mod 256 = 0 then begin
    FProgressUpdate.Update(ARowNumber / FHeight);
  end;
  if not FCancelNotifier.IsOperationCanceled(FOperationID) then begin
    Result := FLineProvider.GetLine(FOperationID, FCancelNotifier, ARowNumber);
  end else begin
    Result := nil;
  end;
end;

{ TBitmapMapCombinerFactoryPNG }

constructor TBitmapMapCombinerFactoryPNG.Create(
  const ACounterList: IInternalPerformanceCounterList
);
var
  VCounterList: IInternalPerformanceCounterList;
begin
  inherited Create(
    Point(0, 0),
    Point(65536, 65536),
    stsUnicode,
    'png',
    gettext_NoExtract('PNG (Portable Network Graphics)'),
    [mcAlphaCheck]
  );
  VCounterList := ACounterList.CreateAndAddNewSubList('PNG');
  FSaveRectCounter := VCounterList.CreateAndAddNewCounter('SaveRect');
  FPrepareDataCounter := VCounterList.CreateAndAddNewCounter('PrepareData');
  FGetLineCounter := VCounterList.CreateAndAddNewCounter('GetLine');
end;

function TBitmapMapCombinerFactoryPNG.PrepareMapCombiner(
  const AParams: IRegionProcessParamsFrameMapCombine;
  const AProgressInfo: IBitmapCombineProgressUpdate
): IBitmapMapCombiner;
begin
  Result :=
    TBitmapMapCombinerPNG.Create(
      AProgressInfo,
      FSaveRectCounter,
      FPrepareDataCounter,
      FGetLineCounter,
      AParams.CustomOptions.IsSaveAlfa
    );
end;

end.

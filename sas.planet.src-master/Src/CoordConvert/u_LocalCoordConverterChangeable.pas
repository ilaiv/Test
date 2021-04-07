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

unit u_LocalCoordConverterChangeable;

interface

uses
  SysUtils,
  i_InternalPerformanceCounter,
  i_LocalCoordConverter,
  i_LocalCoordConverterChangeable,
  u_ChangeableBase;

type
  TLocalCoordConverterChangeable = class(TChangeableWithSimpleLockBase, ILocalCoordConverterChangeable)
  private
    FConverter: ILocalCoordConverter;
    FChangeCounter: IInternalPerformanceCounter;
  private
    function GetStatic: ILocalCoordConverter;
  protected
    property _Converter: ILocalCoordConverter read FConverter;
    function _SetConverter(const AValue: ILocalCoordConverter): Boolean;
  protected
    procedure DoChangeNotify; override;
  public
    constructor Create(
      const ASource: ILocalCoordConverter;
      const AChangeCounter: IInternalPerformanceCounter
    );
  end;

implementation

{ TLocalCoordConverterChangeable }

constructor TLocalCoordConverterChangeable.Create(
  const ASource: ILocalCoordConverter;
  const AChangeCounter: IInternalPerformanceCounter
);
begin
  inherited Create;
  FConverter := ASource;
  FChangeCounter := AChangeCounter;
end;

procedure TLocalCoordConverterChangeable.DoChangeNotify;
var
  VCounterContext: TInternalPerformanceCounterContext;
begin
  VCounterContext := FChangeCounter.StartOperation;
  try
    inherited;
  finally
    FChangeCounter.FinishOperation(VCounterContext);
  end;
end;

function TLocalCoordConverterChangeable.GetStatic: ILocalCoordConverter;
begin
  CS.BeginRead;
  try
    Result := FConverter;
  finally
    CS.EndRead;
  end;
end;

function TLocalCoordConverterChangeable._SetConverter(
  const AValue: ILocalCoordConverter
): Boolean;
begin
  Result := False;
  if (Assigned(FConverter) and not FConverter.GetIsSameConverter(AValue)) or (Assigned(AValue) and not Assigned(FConverter)) then begin
    FConverter := AValue;
    Result := True;
  end;
end;

end.

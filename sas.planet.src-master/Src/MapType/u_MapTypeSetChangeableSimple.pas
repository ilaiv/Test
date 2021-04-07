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

unit u_MapTypeSetChangeableSimple;

interface

uses
  SysUtils,
  i_MapTypeSet,
  i_MapTypeSetBuilder,
  i_MapTypeSetChangeable,
  u_ChangeableBase;

type
  IMapTypeSetChangeableSimpleInternal = interface(IMapTypeSetChangeable)
    procedure SetStatic(const AValue: IMapTypeSet);
  end;

  TMapTypeSetChangeableSimple = class(TChangeableWithSimpleLockBase, IMapTypeSetChangeable, IMapTypeSetChangeableSimpleInternal)
  private
    FMapTypeSetBuilderFactory: IMapTypeSetBuilderFactory;
    FStatic: IMapTypeSet;
  private
    function GetStatic: IMapTypeSet;
  private
    procedure SetStatic(const AValue: IMapTypeSet);
  public
    constructor Create(
      const AMapTypeSetBuilderFactory: IMapTypeSetBuilderFactory;
      const ACurrentSet: IMapTypeSet
    );
  end;

implementation

{ TMapTypeSetChangeableSimple }

constructor TMapTypeSetChangeableSimple.Create(
  const AMapTypeSetBuilderFactory: IMapTypeSetBuilderFactory;
  const ACurrentSet: IMapTypeSet
);
begin
  inherited Create;
  FMapTypeSetBuilderFactory := AMapTypeSetBuilderFactory;
  SetStatic(ACurrentSet);
end;

function TMapTypeSetChangeableSimple.GetStatic: IMapTypeSet;
begin
  CS.BeginRead;
  try
    Result := FStatic;
  finally
    CS.EndRead;
  end;
end;

procedure TMapTypeSetChangeableSimple.SetStatic(const AValue: IMapTypeSet);
var
  VList: IMapTypeSetBuilder;
begin
  CS.BeginWrite;
  try
    if AValue = nil then begin
      VList := FMapTypeSetBuilderFactory.Build(False);
      FStatic := VList.MakeAndClear;
    end else begin
      FStatic := AValue;
    end;
  finally
    CS.EndWrite;
  end;
end;

end.

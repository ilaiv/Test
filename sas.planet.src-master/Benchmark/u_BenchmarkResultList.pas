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

unit u_BenchmarkResultList;

interface

uses
  i_InterfaceListStatic,
  i_BenchmarkResult,
  i_BenchmarkResultList;

type
  TBenchmarkResultList = class(TInterfacedObject, IBenchmarkResultList)
  private
    FList: IInterfaceListStatic;
  private
    function GetCount: Integer;
    function GetItem(const AIndex: Integer): IBenchmarkResult;
  public
    constructor Create(const AList: IInterfaceListStatic);
  end;

implementation

{ TBenchmarkResultList }

constructor TBenchmarkResultList.Create(const AList: IInterfaceListStatic);
begin
  Assert(Assigned(AList));
  Assert(AList.Count > 0);
  inherited Create;
  FList := AList;
end;

function TBenchmarkResultList.GetCount: Integer;
begin
  Result := FList.Count;
end;

function TBenchmarkResultList.GetItem(const AIndex: Integer): IBenchmarkResult;
begin
  Result := IBenchmarkResult(FList.Items[AIndex]);
end;

end.


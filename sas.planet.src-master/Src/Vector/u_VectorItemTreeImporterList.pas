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

unit u_VectorItemTreeImporterList;

interface

uses
  i_InterfaceListStatic,
  i_VectorItemTreeImporter,
  i_VectorItemTreeImporterList,
  u_BaseInterfacedObject;

type
  TVectorItemTreeImporterListItem = class(TBaseInterfacedObject, IVectorItemTreeImporterListItem)
  private
    FImporter: IVectorItemTreeImporter;
    FDefaultExt: string;
    FName: string;
  private
    function GetImporter: IVectorItemTreeImporter;
    function GetDefaultExt: string;
    function GetName: string;
  public
    constructor Create(
      const AImporter: IVectorItemTreeImporter;
      const ADefaultExt: string;
      const AName: string
    );
  end;

  TVectorItemTreeImporterListStatic = class(TBaseInterfacedObject, IVectorItemTreeImporterListStatic)
  private
    FList: IInterfaceListStatic;
  private
    function GetCount: Integer;
    function GetItem(const AIndex: Integer): IVectorItemTreeImporterListItem;

    function GetImporterByExt(const AExt: string): IVectorItemTreeImporter;
  public
    constructor Create(const AList: IInterfaceListStatic);
  end;

implementation

uses
  SysUtils,
  StrUtils;

{ TVectorItemTreeImporterListItem }

constructor TVectorItemTreeImporterListItem.Create(
  const AImporter: IVectorItemTreeImporter;
  const ADefaultExt, AName: string
);
begin
  Assert(Assigned(AImporter));
  Assert(ADefaultExt <> '');
  Assert(AName <> '');
  inherited Create;
  FImporter := AImporter;
  FDefaultExt := ADefaultExt;
  FName := AName;
end;

function TVectorItemTreeImporterListItem.GetDefaultExt: string;
begin
  Result := FDefaultExt;
end;

function TVectorItemTreeImporterListItem.GetImporter: IVectorItemTreeImporter;
begin
  Result := FImporter;
end;

function TVectorItemTreeImporterListItem.GetName: string;
begin
  Result := FName;
end;

{ TVectorItemTreeImporterListStatic }

constructor TVectorItemTreeImporterListStatic.Create(
  const AList: IInterfaceListStatic
);
begin
  inherited Create;
  FList := AList;
end;

function TVectorItemTreeImporterListStatic.GetCount: Integer;
begin
  if Assigned(FList) then begin
    Result := FList.Count;
  end else begin
    Result := 0;
  end;
end;

function TVectorItemTreeImporterListStatic.GetImporterByExt(
  const AExt: string
): IVectorItemTreeImporter;
var
  VExt: string;
  i: Integer;
  VItem: IVectorItemTreeImporterListItem;
begin
  Result := nil;
  VExt := LowerCase(AExt);
  if VExt[1] = '.' then begin
    VExt := RightStr(VExt, Length(VExt) - 1);
  end;
  for i := 0 to FList.Count - 1 do begin
    VItem := GetItem(i);
    if VExt = VItem.DefaultExt then begin
      Result := VItem.Importer;
    end;
  end;
end;

function TVectorItemTreeImporterListStatic.GetItem(
  const AIndex: Integer
): IVectorItemTreeImporterListItem;
begin
  Result := IVectorItemTreeImporterListItem(FList.Items[AIndex]);
end;

end.

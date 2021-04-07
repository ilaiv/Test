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

unit u_VectorItemSubset;

interface

uses
  ActiveX,
  t_Hash,
  i_VectorDataItemSimple,
  i_InterfaceListStatic,
  i_VectorItemSubset,
  u_BaseInterfacedObject;

type
  TVectorItemSubset = class(TBaseInterfacedObject, IVectorItemSubset)
  private
    FHash: THashValue;
    FList: IInterfaceListStatic;
  private
    function GetEnum: IEnumUnknown;
    function IsEmpty: Boolean;
    function IsEqual(const ASubset: IVectorItemSubset): Boolean;

    function GetCount: Integer;
    function GetItem(AIndex: Integer): IVectorDataItem;
    function GetHash: THashValue;
  public
    constructor Create(
      const AHash: THashValue;
      const AList: IInterfaceListStatic
    );
  end;

implementation

uses
  u_EnumUnknown;

{ TVectorItemSubset }

constructor TVectorItemSubset.Create(
  const AHash: THashValue;
  const AList: IInterfaceListStatic
);
begin
  inherited Create;
  FHash := AHash;
  FList := AList;
end;

function TVectorItemSubset.GetCount: Integer;
begin
  Result := FList.Count;
end;

function TVectorItemSubset.GetEnum: IEnumUnknown;
begin
  Result := TEnumUnknownByStatic.Create(FList);
end;

function TVectorItemSubset.GetHash: THashValue;
begin
  Result := FHash;
end;

function TVectorItemSubset.GetItem(AIndex: Integer): IVectorDataItem;
begin
  Result := IVectorDataItem(FList.Items[AIndex]);
end;

function TVectorItemSubset.IsEmpty: Boolean;
begin
  Result := FList.Count = 0;
end;

function TVectorItemSubset.IsEqual(const ASubset: IVectorItemSubset): Boolean;
var
  i: Integer;
begin
  if not Assigned(ASubset) then begin
    Result := False;
  end else if ASubset = IVectorItemSubset(Self) then begin
    Result := True;
  end else if FList.Count <> ASubset.Count then begin
    Result := False;
  end else if (FHash <> 0) and (ASubset.Hash <> 0) and (FHash <> ASubset.Hash) then begin
    Result := False;
  end else begin
    Result := True;
    for i := 0 to FList.Count - 1 do begin
      if not IVectorDataItem(FList.Items[i]).IsEqual(ASubset.Items[i]) then begin
        Result := False;
        Break;
      end;
    end;
  end;
end;

end.

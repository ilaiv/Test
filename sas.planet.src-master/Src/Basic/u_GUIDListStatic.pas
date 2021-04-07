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

unit u_GUIDListStatic;

interface

uses
  i_GUIDListStatic,
  u_BaseInterfacedObject;

type
  TGUIDListStatic = class(TBaseInterfacedObject, IGUIDListStatic)
  private
    FList: array of TGUID;
    FCount: Integer;
  private
    function GetItem(AIndex: Integer): TGUID;
    function GetCount: Integer;
  public
    constructor Create(
      const AList: array of TGUID;
      ACount: Integer
    );
    destructor Destroy; override;
  end;

  TGUIDSetStatic = class(TBaseInterfacedObject, IGUIDSetStatic)
  private
    FList: array of TGUID;
    FCount: Integer;
    function Find(
      const AGUID: TGUID;
      var Index: Integer
    ): Boolean;
  private
    function GetItem(AIndex: Integer): TGUID;
    function GetCount: Integer;
    function IsExists(const AGUID: TGUID): boolean;
  private
    constructor Create(
      const AList: array of TGUID;
      ACount: Integer
    );
  public
    class function CreateAndSort(
      const AList: array of TGUID;
      ACount: Integer
    ): IGUIDSetStatic;
    class function CreateByAdd(
      const ASource: IGUIDSetStatic;
      const AGUID: TGUID
    ): IGUIDSetStatic;
    class function CreateByRemove(
      const ASource: IGUIDSetStatic;
      const AGUID: TGUID
    ): IGUIDSetStatic;
    destructor Destroy; override;
  end;

implementation

uses
  SysUtils,
  u_GUIDTool;

procedure QuickSort(
  var SortList: array of TGUID;
  L, R: Integer
);
var
  I, J: Integer;
  P, T: TGUID;
begin
  repeat
    I := L;
    J := R;
    P := SortList[(L + R) shr 1];
    repeat
      while CompareGUIDs(SortList[I], P) < 0 do begin
        Inc(I);
      end;
      while CompareGUIDs(SortList[J], P) > 0 do begin
        Dec(J);
      end;
      if I <= J then begin
        T := SortList[I];
        SortList[I] := SortList[J];
        SortList[J] := T;
        Inc(I);
        Dec(J);
      end;
    until I > J;
    if L < J then begin
      QuickSort(SortList, L, J);
    end;
    L := I;
  until I >= R;
end;

{ TGUIDListStatic }

constructor TGUIDListStatic.Create(
  const AList: array of TGUID;
  ACount: Integer
);
var
  i: Integer;
begin
  inherited Create;
  SetLength(FList, ACount);
  FCount := ACount;
  for i := 0 to FCount - 1 do begin
    FList[i] := AList[i];
  end;
end;

destructor TGUIDListStatic.Destroy;
begin
  FList := nil;
  inherited;
end;

function TGUIDListStatic.GetCount: Integer;
begin
  Result := FCount;
end;

function TGUIDListStatic.GetItem(AIndex: Integer): TGUID;
begin
  Result := FList[AIndex];
end;

{ TGUIDSetStatic }

constructor TGUIDSetStatic.Create(
  const AList: array of TGUID;
  ACount: Integer
);
var
  i: Integer;
begin
  inherited Create;
  SetLength(FList, ACount);
  FCount := ACount;
  for i := 0 to FCount - 1 do begin
    FList[i] := AList[i];
  end;
end;

class function TGUIDSetStatic.CreateAndSort(
  const AList: array of TGUID;
  ACount: Integer
): IGUIDSetStatic;
var
  i: Integer;
  VGUIDCurr: TGUID;
  VGUIDPrev: TGUID;
  VPrevIndex: Integer;
  VList: array of TGUID;
  VCount: Integer;
begin
  Assert(ACount >= 0);
  if ACount = 0 then begin
    Result := nil;
    Exit;
  end;
  SetLength(VList, ACount);
  VCount := ACount;
  for i := 0 to VCount - 1 do begin
    VList[i] := AList[i];
  end;
  if VCount > 1 then begin
    QuickSort(VList, 0, VCount - 1);
    VGUIDPrev := VList[0];
    VPrevIndex := VCount - 1;
    for i := 1 to VCount - 1 do begin
      VGUIDCurr := VList[i];
      if IsEqualGUID(VGUIDPrev, VGUIDCurr) then begin
        VPrevIndex := i - 1;
        Break;
      end else begin
        VGUIDPrev := VGUIDCurr;
      end;
    end;
    if VPrevIndex < VCount - 1 then begin
      for i := VPrevIndex + 1 to VCount - 1 do begin
        VGUIDCurr := VList[i];
        if not IsEqualGUID(VGUIDPrev, VGUIDCurr) then begin
          Inc(VPrevIndex);
          VGUIDPrev := VGUIDCurr;
          VList[VPrevIndex] := VGUIDCurr;
        end;
      end;
      VCount := VPrevIndex + 1;
    end;
  end;
  Result := TGUIDSetStatic.Create(VList, VCount);
end;

class function TGUIDSetStatic.CreateByAdd(
  const ASource: IGUIDSetStatic;
  const AGUID: TGUID
): IGUIDSetStatic;
var
  VList: array of TGUID;
  VCount: Integer;
  i: Integer;
begin
  if not Assigned(ASource) then begin
    Result := TGUIDSetStatic.Create(AGUID, 1);
  end else begin
    VCount := ASource.Count + 1;
    SetLength(VList, VCount);
    for i := 0 to ASource.Count - 1 do begin
      VList[i] := ASource.Items[i];
    end;
    VList[VCount - 1] := AGUID;
    Result := CreateAndSort(VList, VCount);
  end;
end;

class function TGUIDSetStatic.CreateByRemove(
  const ASource: IGUIDSetStatic;
  const AGUID: TGUID
): IGUIDSetStatic;
var
  VList: array of TGUID;
  VCount: Integer;
  i: Integer;
  VIndex: Integer;
  VGUID: TGUID;
begin
  Assert(Assigned(ASource));
  Assert(ASource.IsExists(AGUID));
  if not Assigned(ASource) then begin
    Result := nil;
  end else begin
    if (ASource.Count = 1) and IsEqualGUID(ASource.Items[0], AGUID) then begin
      Result := nil;
    end else begin
      VCount := ASource.Count;
      VIndex := 0;
      SetLength(VList, VCount);
      for i := 0 to VCount - 1 do begin
        VGUID := ASource.Items[i];
        if not IsEqualGUID(VGUID, AGUID) then begin
          VList[VIndex] := VGUID;
          Inc(VIndex);
        end;
      end;
      VCount := VIndex;
      Result := TGUIDSetStatic.Create(VList, VCount);
    end;
  end;
end;

destructor TGUIDSetStatic.Destroy;
begin
  FList := nil;
  inherited;
end;

function TGUIDSetStatic.GetCount: Integer;
begin
  Result := FCount;
end;

function TGUIDSetStatic.GetItem(AIndex: Integer): TGUID;
begin
  Result := FList[AIndex];
end;

function TGUIDSetStatic.Find(
  const AGUID: TGUID;
  var Index: Integer
): Boolean;
var
  L, H, I, C: Integer;
begin
  Result := False;
  L := 0;
  H := FCount - 1;
  while L <= H do begin
    I := (L + H) shr 1;
    C := CompareGUIDs(fList[I], AGUID);
    if C < 0 then begin
      L := I + 1;
    end else begin
      H := I - 1;
      if C = 0 then begin
        Result := True;
        L := I;
      end;
    end;
  end;
  Index := L;
end;

function TGUIDSetStatic.IsExists(const AGUID: TGUID): boolean;
var
  VIndex: Integer;
begin
  Result := Find(AGUID, VIndex);
end;

end.

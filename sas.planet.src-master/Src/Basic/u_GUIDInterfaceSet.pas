{*******************************************************************************
     
    Version: 0.1
    Copyright (C) 2009 Demydov Viktor
    mailto:vdemidov@gmail.com
    http://viktor.getcv.ru/

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*******************************************************************************}
unit u_GUIDInterfaceSet;

interface

uses
  ActiveX,
  i_GUIDSet,
  u_GUIDSet;

type
  TInterfaceWithGUID = record
    GUID: TGUID;
    Obj: IInterface;
  end;

const
  MaxInterfaceWithGUIDListSize = Maxint div (sizeof(TInterfaceWithGUID) * 2);

type
  PInterfaceWithGUIDList = ^TInterfaceWithGUIDList;
  TInterfaceWithGUIDList = array[0..MaxInterfaceWithGUIDListSize - 1] of TInterfaceWithGUID;

  TGUIDInterfaceSet = class(TGUIDSetBase, IGUIDInterfaceSet)
  private
    FList: PInterfaceWithGUIDList;
    procedure Insert(
      Index: Integer;
      const AGUID: TGUID;
      const AObj: IInterface
    );
  protected
    procedure SetCapacity(NewCapacity: Integer); override;
    procedure SetCount(NewCount: Integer); override;
    procedure Delete(Index: Integer); override;
    function GetItemGUID(Index: Integer): TGUID; override;
  private
    function GetItem(Index: Integer): IInterface;
    function GetEnumUnknown: IEnumUnknown;
    // ���������� �������. ���� ������ � ����� GUID ��� ����, �� ���������� �� �����
    // ���������� �������� ������
    function Add(
      const AGUID: TGUID;
      const AInterface: IInterface
    ): IInterface;

    // ��������� ������� �� GUID
    function GetByGUID(const AGUID: TGUID): IInterface;

    // ������ ������������� ������� �����, ���� �����������, �� ������ ���������
    procedure Replace(
      const AGUID: TGUID;
      const AInterface: IInterface
    );
  end;

resourcestring
  SInterfaceIsNilError = 'Interface is nil';

implementation

uses
  Windows,
  Math,
  SysUtils;

type
  TGUIDInterfaceListEnum = class(TInterfacedObject, IEnumUnknown)
  private
    FGUIDList: TGUIDInterfaceSet;
    FCurrentIndex: integer;
  private
    function Next(
      celt: Longint;
      out rgelt;
      pceltFetched: PLongint
    ): HResult; stdcall;
    function Skip(celt: Longint): HResult; stdcall;
    function Reset: HResult; stdcall;
    function Clone(out ppenum: IEnumUnknown): HResult; stdcall;
  public
    constructor Create(AGUIDList: TGUIDInterfaceSet);
  end;

{ TGUIDInterfaceListEnum }

function TGUIDInterfaceListEnum.Clone(out ppenum: IEnumUnknown): HResult;
var
  VGUIDListEnum: TGUIDInterfaceListEnum;
begin
  VGUIDListEnum := TGUIDInterfaceListEnum.Create(FGUIDList);
  ppenum := VGUIDListEnum;
  VGUIDListEnum.FCurrentIndex := FCurrentIndex;
  Result := S_OK;
end;

constructor TGUIDInterfaceListEnum.Create(AGUIDList: TGUIDInterfaceSet);
begin
  inherited Create;
  FGUIDList := AGUIDList;
  FCurrentIndex := 0;
end;

function TGUIDInterfaceListEnum.Next(
  celt: Longint;
  out rgelt;
  pceltFetched: PLongint
): HResult;
var
  i: integer;
  Vp: ^IInterface;
begin
  pceltFetched^ := min(celt, FGUIDList.Count - FCurrentIndex);
  Vp := @rgelt;
  if pceltFetched^ > 0 then begin
    for i := 0 to pceltFetched^ - 1 do begin
      Vp^ := FGUIDList.GetItem(FCurrentIndex + i);
      Inc(Vp);
    end;
    Inc(FCurrentIndex, pceltFetched^);
  end;
  if pceltFetched^ <> celt then begin
    Result := S_FALSE;
  end else begin
    Result := S_OK;
  end;
end;

function TGUIDInterfaceListEnum.Reset: HResult;
begin
  FCurrentIndex := 0;
  Result := S_OK;
end;

function TGUIDInterfaceListEnum.Skip(celt: Longint): HResult;
begin
  Inc(FCurrentIndex, celt);
  if FCurrentIndex > FGUIDList.FCount then begin
    Result := S_FALSE;
  end else begin
    Result := S_OK;
  end;
end;

{ TGUIDList }

function TGUIDInterfaceSet.Add(
  const AGUID: TGUID;
  const AInterface: IInterface
): IInterface;
var
  VIndex: Integer;
begin
  if (not FAllowNil) and (AInterface = nil) then begin
    raise Exception.Create(LoadResString(@SInterfaceIsNilError));
  end;
  if not Find(AGUID, VIndex) then begin
    Insert(VIndex, AGUID, AInterface);
    Result := AInterface;
  end else begin
    Result := FList^[VIndex].Obj;
  end;
end;

procedure TGUIDInterfaceSet.Delete(Index: Integer);
begin
  if (Index < 0) or (Index >= FCount) then begin
    Error(@SListIndexError, Index);
  end;
  FList^[Index].Obj := nil;
  Dec(FCount);
  if Index < FCount then begin
    System.Move(FList^[Index + 1], FList^[Index],
      (FCount - Index) * SizeOf(TInterfaceWithGUID));
  end;
end;

function TGUIDInterfaceSet.GetByGUID(const AGUID: TGUID): IInterface;
var
  VIndex: Integer;
begin
  if Find(AGUID, VIndex) then begin
    Result := FList^[VIndex].Obj;
  end else begin
    Result := nil;
  end;
end;

function TGUIDInterfaceSet.GetEnumUnknown: IEnumUnknown;
begin
  Result := TGUIDInterfaceListEnum.Create(Self);
end;

function TGUIDInterfaceSet.GetItem(Index: Integer): IInterface;
begin
  Result := FList^[Index].Obj;
end;

function TGUIDInterfaceSet.GetItemGUID(Index: Integer): TGUID;
begin
  Result := FList^[Index].GUID;
end;

procedure TGUIDInterfaceSet.Insert(
  Index: Integer;
  const AGUID: TGUID;
  const AObj: IInterface
);
begin
  if (Index < 0) or (Index > FCount) then begin
    Error(@SListIndexError, Index);
  end;
  if FCount = FCapacity then begin
    Grow;
  end;
  if Index < FCount then begin
    System.Move(FList^[Index], FList^[Index + 1],
      (FCount - Index) * SizeOf(TInterfaceWithGUID));
  end;
  FillChar(FList^[Index], SizeOf(TInterfaceWithGUID), 0);
  FList^[Index].GUID := AGUID;
  FList^[Index].Obj := AObj;
  Inc(FCount);
end;

procedure TGUIDInterfaceSet.Replace(
  const AGUID: TGUID;
  const AInterface: IInterface
);
var
  VIndex: Integer;
begin
  if (not FAllowNil) and (AInterface = nil) then begin
    raise Exception.Create(LoadResString(@SInterfaceIsNilError));
  end;
  if Find(AGUID, VIndex) then begin
    FList^[VIndex].Obj := AInterface;
  end else begin
    Insert(VIndex, AGUID, AInterface);
  end;
end;

procedure TGUIDInterfaceSet.SetCapacity(NewCapacity: Integer);
begin
  if (NewCapacity < FCount) or (NewCapacity > MaxInterfaceWithGUIDListSize) then begin
    Error(@SListCapacityError, NewCapacity);
  end;
  if NewCapacity <> FCapacity then begin
    ReallocMem(FList, NewCapacity * SizeOf(TInterfaceWithGUID));
    FCapacity := NewCapacity;
  end;
end;

procedure TGUIDInterfaceSet.SetCount(NewCount: Integer);
var
  I: Integer;
begin
  if (NewCount < 0) or (NewCount > MaxInterfaceWithGUIDListSize) then begin
    Error(@SListCountError, NewCount);
  end;
  if NewCount > FCapacity then begin
    SetCapacity(NewCount);
  end;
  if NewCount > FCount then begin
    FillChar(FList^[FCount], (NewCount - FCount) * SizeOf(TInterfaceWithGUID), 0);
  end else begin
    for I := FCount - 1 downto NewCount do begin
      Delete(I);
    end;
  end;
  FCount := NewCount;
end;

end.

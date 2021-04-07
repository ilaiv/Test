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

unit u_IDListBase;

interface

uses
  Windows,
  i_EnumID;

type
  TIDListBase = class(TInterfacedObject)
  protected
    FCount: Integer;
    FCapacity: Integer;
    FAllowNil: Boolean;
    procedure Grow; virtual;
    procedure SetCapacity(NewCapacity: Integer); virtual; abstract;
    procedure SetCount(NewCount: Integer); virtual; abstract;
    function GetCount: Integer;
    procedure Delete(Index: Integer); virtual; abstract;
    function GetItemId(Index: Integer): Integer; virtual; abstract;
    function Find(
      AId: Integer;
      var Index: Integer
    ): Boolean; virtual;
    function CompareID(const I1, I2: Integer): Integer; inline;
  protected
    class procedure Error(
      const Msg: string;
      Data: Integer
    ); overload; virtual;
    class procedure Error(
      Msg: PResStringRec;
      Data: Integer
    ); overload;

    // �������� ������� ID � ������
    function IsExists(AId: Integer): boolean; virtual;

    // �������� �������, ���� ��� � ����� Id, �� ������ �� ����� �����������
    procedure Remove(AId: Integer); virtual;

    // ������� ������
    procedure Clear; virtual;

    // ��������� ��������� ID
    function GetIDEnum(): IEnumID; virtual;
    property Capacity: Integer read FCapacity write SetCapacity;
    property Count: Integer read GetCount write SetCount;
  public
    constructor Create(
      AAllowNil: Boolean = False;
      ACapacity: Integer = 0
    ); overload;

    destructor Destroy; override;
  end;

resourcestring
  SListIndexError = 'List index out of bounds (%d)';
  SListCapacityError = 'List capacity out of bounds (%d)';
  SListCountError = 'List count out of bounds (%d)';

implementation

uses
  Classes,
  Math;

type
  TIDListEnum = class(TInterfacedObject, IEnumID)
  private
    FIDList: TIDListBase;
    FCurrentIndex: integer;
  private
    function Next(
      celt: LongWord;
      out rgelt: Integer;
      out pceltFetched: LongWord
    ): HResult; stdcall;
    function Skip(celt: LongWord): HResult; stdcall;
    function Reset: HResult; stdcall;
    function Clone(out ppenum: IEnumID): HResult; stdcall;
  public
    constructor Create(AGUIDList: TIDListBase);
  end;

{ TIDListEnum }

function TIDListEnum.Clone(out ppenum: IEnumID): HResult;
var
  VGUIDListEnum: TIDListEnum;
begin
  VGUIDListEnum := TIDListEnum.Create(FIDList);
  ppenum := VGUIDListEnum;
  VGUIDListEnum.FCurrentIndex := FCurrentIndex;
  Result := S_OK;
end;

constructor TIDListEnum.Create(AGUIDList: TIDListBase);
begin
  inherited Create;
  FIDList := AGUIDList;
  FCurrentIndex := 0;
end;

function TIDListEnum.Next(
  celt: LongWord;
  out rgelt: Integer;
  out pceltFetched: LongWord
): HResult;
var
  i: integer;
  VpID: PInteger;
begin
  pceltFetched := min(celt, FIDList.Count - FCurrentIndex);
  VpID := @rgelt;
  if pceltFetched > 0 then begin
    for i := 0 to pceltFetched - 1 do begin
      VpID^ := FIDList.GetItemId(FCurrentIndex + I);
      Inc(VpID);
    end;
    Inc(FCurrentIndex, pceltFetched);
  end;
  if pceltFetched <> celt then begin
    Result := S_FALSE;
  end else begin
    Result := S_OK;
  end;
end;

function TIDListEnum.Reset: HResult;
begin
  FCurrentIndex := 0;
  Result := S_OK;
end;

function TIDListEnum.Skip(celt: LongWord): HResult;
begin
  Inc(FCurrentIndex, celt);
  if FCurrentIndex > FIDList.FCount then begin
    Result := S_FALSE;
  end else begin
    Result := S_OK;
  end;
end;

{ TIDListBase }

procedure TIDListBase.Clear;
begin
  SetCount(0);
  SetCapacity(0);
end;

function TIDListBase.CompareID(const I1, I2: Integer): Integer;
begin
  if I1 > I2 then begin
    Result := 1;
  end else begin
    if I1 < I2 then begin
      Result := -1;
    end else begin
      Result := 0;
    end;
  end;
end;

constructor TIDListBase.Create(
  AAllowNil: Boolean;
  ACapacity: Integer
);
begin
  inherited Create;
  FAllowNil := AAllowNil;
  SetCapacity(ACapacity);
end;

destructor TIDListBase.Destroy;
begin
  Clear;
  inherited;
end;

{$IF CompilerVersion < 23}
function ReturnAddress: Pointer;
asm
  mov eax, [ebp+4]
end;
{$IFEND}

class procedure TIDListBase.Error(
  const Msg: string;
  Data: Integer
);
begin
  raise EListError.CreateFmt(Msg, [Data]) at ReturnAddress;
end;

class procedure TIDListBase.Error(
  Msg: PResStringRec;
  Data: Integer
);
begin
  raise EListError.CreateFmt(LoadResString(Msg), [Data]) at ReturnAddress;
end;

function TIDListBase.Find(
  AId: Integer;
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
    C := CompareID(GetItemId(I), AID);
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

function TIDListBase.GetCount: Integer;
begin
  Result := FCount;
end;

function TIDListBase.GetIDEnum: IEnumID;
begin
  Result := TIDListEnum.Create(Self);
end;

procedure TIDListBase.Grow;
var
  Delta: Integer;
begin
  if FCapacity > 64 then begin
    Delta := FCapacity div 4;
  end else begin
    if FCapacity > 8 then begin
      Delta := 16;
    end else begin
      Delta := 4;
    end;
  end;
  SetCapacity(FCapacity + Delta);
end;

function TIDListBase.IsExists(AId: Integer): boolean;
var
  VIndex: Integer;
begin
  Result := Find(AID, VIndex);
end;

procedure TIDListBase.Remove(AId: Integer);
var
  VIndex: Integer;
begin
  if Find(AID, VIndex) then begin
    Delete(VIndex);
  end;
end;

end.

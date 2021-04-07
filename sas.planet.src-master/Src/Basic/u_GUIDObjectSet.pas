unit u_GUIDObjectSet;

interface

uses
  i_GUIDSet,
  u_GUIDSet;

type
  TObjectWithGUID = record
    GUID: TGUID;
    Obj: TObject;
  end;

const
  MaxObjectWithGUIDListSize = Maxint div (sizeof(TObjectWithGUID) * 2);

type
  PObjectWithGUIDList = ^TObjectWithGUIDList;
  TObjectWithGUIDList = array[0..MaxObjectWithGUIDListSize - 1] of TObjectWithGUID;
  
type
  TGUIDObjectSet = class(TGUIDSetBase, IGUIDObjectSet)
  protected
    FList: PObjectWithGUIDList;
    procedure SetCapacity(NewCapacity: Integer); override;
    procedure SetCount(NewCount: Integer); override;
    procedure Delete(Index: Integer); override;
    procedure Insert(
      Index: Integer;
      const AGUID: TGUID;
      AObj: TObject
    );
    function GetItemGUID(Index: Integer): TGUID; override;
  public
    // ���������� �������. ���� ������ � ����� GUID ��� ����, �� ���������� �� �����
    // ���������� �������� ������
    function Add(
      const AGUID: TGUID;
      AObj: TObject
    ): TObject;

    // ��������� ������� �� GUID
    function GetByGUID(const AGUID: TGUID): TObject;

    // ������ ������������� ������� �����, ���� �����������, �� ������ ���������
    procedure Replace(
      const AGUID: TGUID;
      AObj: TObject
    );

    // �������� �� ���� ������ ���������� ��������
    function GetIsObjectOwner: Boolean;
  end;

resourcestring
  SObjectIsNilError = 'Object is nil';

implementation

uses
  SysUtils;

{ TGUIDList }

function TGUIDObjectSet.Add(
  const AGUID: TGUID;
  AObj: TObject
): TObject;
var
  VIndex: Integer;
begin
  if (not FAllowNil) and (AObj = nil) then begin
    raise Exception.Create(LoadResString(@SObjectIsNilError));
  end;
  if not Find(AGUID, VIndex) then begin
    Insert(VIndex, AGUID, AObj);
    Result := AObj;
  end else begin
    Result := FList^[VIndex].Obj;
  end;
end;

procedure TGUIDObjectSet.Delete(Index: Integer);
begin
  if (Index < 0) or (Index >= FCount) then begin
    Error(@SListIndexError, Index);
  end;
  FList^[Index].Obj := nil;
  Dec(FCount);
  if Index < FCount then begin
    System.Move(FList^[Index + 1], FList^[Index],
      (FCount - Index) * SizeOf(TObjectWithGUID));
  end;
end;

function TGUIDObjectSet.GetByGUID(const AGUID: TGUID): TObject;
var
  VIndex: Integer;
begin
  if Find(AGUID, VIndex) then begin
    Result := FList^[VIndex].Obj;
  end else begin
    Result := nil;
  end;
end;

function TGUIDObjectSet.GetIsObjectOwner: Boolean;
begin
  Result := False;
end;

function TGUIDObjectSet.GetItemGUID(Index: Integer): TGUID;
begin
  Result := FList^[Index].GUID;
end;

procedure TGUIDObjectSet.Insert(
  Index: Integer;
  const AGUID: TGUID;
  AObj: TObject
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
      (FCount - Index) * SizeOf(TObjectWithGUID));
  end;
  FillChar(FList^[Index], SizeOf(TObjectWithGUID), 0);
  FList^[Index].GUID := AGUID;
  FList^[Index].Obj := AObj;
  Inc(FCount);
end;

procedure TGUIDObjectSet.Replace(
  const AGUID: TGUID;
  AObj: TObject
);
var
  VIndex: Integer;
begin
  if (not FAllowNil) and (AObj = nil) then begin
    raise Exception.Create(LoadResString(@SObjectIsNilError));
  end;
  if Find(AGUID, VIndex) then begin
    FList^[VIndex].Obj := AObj;
  end else begin
    Insert(VIndex, AGUID, AObj);
  end;
end;

procedure TGUIDObjectSet.SetCapacity(NewCapacity: Integer);
begin
  if (NewCapacity < FCount) or (NewCapacity > MaxObjectWithGUIDListSize) then begin
    Error(@SListCapacityError, NewCapacity);
  end;
  if NewCapacity <> FCapacity then begin
    ReallocMem(FList, NewCapacity * SizeOf(TObjectWithGUID));
    FCapacity := NewCapacity;
  end;
end;

procedure TGUIDObjectSet.SetCount(NewCount: Integer);
var
  I: Integer;
begin
  if (NewCount < 0) or (NewCount > MaxObjectWithGUIDListSize) then begin
    Error(@SListCountError, NewCount);
  end;
  if NewCount > FCapacity then begin
    SetCapacity(NewCount);
  end;
  if NewCount > FCount then begin
    FillChar(FList^[FCount], (NewCount - FCount) * SizeOf(TObjectWithGUID), 0);
  end else begin
    for I := FCount - 1 downto NewCount do begin
      Delete(I);
    end;
  end;
  FCount := NewCount;
end;

end.

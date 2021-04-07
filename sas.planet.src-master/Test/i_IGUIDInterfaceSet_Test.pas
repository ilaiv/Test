unit i_IGUIDInterfaceSet_Test;

{

  Delphi DUnit Test Case
  ----------------------
}

interface

uses
  ActiveX,
  TestFramework,
  i_GUIDSet;

type
  // Test methods for interface IGUIDInterfaceSet

  TestIGUIDInterfaceSet = class(TTestCase)
  protected
    FGUIDList: IGUIDInterfaceSet;
  public
    procedure TearDown; override;
  published
    procedure TestAdd;
    procedure TestIsExists;
    procedure TestGetByGUID;
    procedure TestReplace;
    procedure TestRemove;
    procedure TestClear;
    procedure TestGetGUIDEnum;
  end;

implementation

uses
  SysUtils;

type
  ISimple = interface(IInterface)
    function GetGUID(): TGUID;
    function GetCounter(): integer;
    property Counter: integer read GetCounter;
  end;

  TSimple = class(TInterfacedObject, ISimple, IInterface)
  protected
    FGUID: TGUID;
  public
    constructor Create(AGUID: TGUID);
    function GetGUID(): TGUID;
    function GetCounter(): integer;
  end;

{ TSimple }

constructor TSimple.Create(AGUID: TGUID);
begin
  FGUID := AGUID;
end;

function TSimple.GetCounter: integer;
begin
  Result := FRefCount;
end;

function TSimple.GetGUID: TGUID;
begin
  Result := FGUID;
end;

const
  G1: TGUID = '{357CDEAB-14FE-449E-B282-A5B96094BE81}';
  G2: TGUID = '{357CDEAB-14FE-449E-B282-A5B96094BE82}';
  G3: TGUID = '{357CDEAB-14FE-449E-B282-A5B96094BE83}';
  G4: TGUID = '{357CDEAB-14FE-449E-B282-A5B96094BE84}';
  G5: TGUID = '{86EA601F-EA2D-4E26-BDBE-1C4F65444CA5}';
  G6: TGUID = '{F81CCA0A-D467-4962-A9F7-2A50B4BFDD46}';
  G7: TGUID = '{F81CCA0A-D467-4962-A9F7-2A50B4BFDD47}';


{ TestIGUIDInterfaceSet }

procedure TestIGUIDInterfaceSet.TearDown;
begin
  FGUIDList := nil;
end;

procedure TestIGUIDInterfaceSet.TestAdd;
var
  VSource: IInterface;
  VResult: IInterface;
begin
  VSource := TSimple.Create(G1);
  VResult := FGUIDList.Add(G1, VSource);
  Check(FGUIDList.Count = 1, '����� ���������� ������ ���� ���������: 1');
  Check(VResult = VSource, '����� ���������� ������� Add ������ ������� ����������� ������');
  FGUIDList.Add(G2, TSimple.Create(G2));
  Check(FGUIDList.Count = 2, '����� ���������� ������ ���� ���������: 2');
  FGUIDList.Add(G3, TSimple.Create(G3));
  Check(FGUIDList.Count = 3, '����� ���������� ������ ���� ���������: 3');
  FGUIDList.Add(G4, TSimple.Create(G4));
  Check(FGUIDList.Count = 4, '����� ���������� ������ ���� ���������: 4');
  FGUIDList.Add(G5, TSimple.Create(G5));
  Check(FGUIDList.Count = 5, '����� ���������� ������ ���� ���������: 5');
  FGUIDList.Add(G6, TSimple.Create(G6));
  Check(FGUIDList.Count = 6, '����� ���������� ������ ���� ���������: 6');

  VResult := FGUIDList.Add(G1, TSimple.Create(G2));
  Check(FGUIDList.Count = 6, '����� ���������� �������������� ���������� �������� �� ������');
  Check(VResult = VSource, '������ ������� ������ ������');

  FGUIDList.Add(G2, TSimple.Create(G3));
  Check(FGUIDList.Count = 6, '����� ���������� �������������� ���������� �������� �� ������');
  FGUIDList.Add(G3, TSimple.Create(G4));
  Check(FGUIDList.Count = 6, '����� ���������� �������������� ���������� �������� �� ������');
  FGUIDList.Add(G4, TSimple.Create(G5));
  Check(FGUIDList.Count = 6, '����� ���������� �������������� ���������� �������� �� ������');
  FGUIDList.Add(G5, TSimple.Create(G6));
  Check(FGUIDList.Count = 6, '����� ���������� �������������� ���������� �������� �� ������');
  FGUIDList.Add(G6, TSimple.Create(G1));
  Check(FGUIDList.Count = 6, '����� ���������� �������������� ���������� �������� �� ������');
end;

procedure TestIGUIDInterfaceSet.TestIsExists;
begin
  FGUIDList.Add(G6, TSimple.Create(G6));
  FGUIDList.Add(G1, TSimple.Create(G1));
  FGUIDList.Add(G5, TSimple.Create(G5));
  FGUIDList.Add(G2, TSimple.Create(G2));
  FGUIDList.Add(G4, TSimple.Create(G4));
  FGUIDList.Add(G3, TSimple.Create(G3));

  Check(FGUIDList.IsExists(G1), '����� �������� ������� �������� G1');
  Check(FGUIDList.IsExists(G2), '����� �������� ������� �������� G2');
  Check(FGUIDList.IsExists(G3), '����� �������� ������� �������� G3');
  Check(FGUIDList.IsExists(G4), '����� �������� ������� �������� G4');
  Check(FGUIDList.IsExists(G5), '����� �������� ������� �������� G5');
  Check(FGUIDList.IsExists(G6), '����� �������� ������� �������� G6');
  Check(not FGUIDList.IsExists(G7), '����� �������� ������� �������� G7');
end;

procedure TestIGUIDInterfaceSet.TestGetByGUID;
var
  VI: ISimple;
begin
  FGUIDList.Add(G6, TSimple.Create(G6));
  FGUIDList.Add(G1, TSimple.Create(G1));
  FGUIDList.Add(G5, TSimple.Create(G5));
  FGUIDList.Add(G2, TSimple.Create(G2));
  FGUIDList.Add(G4, TSimple.Create(G4));
  FGUIDList.Add(G3, TSimple.Create(G3));

  VI := ISimple(FGUIDList.GetByGUID(G1));
  Check(VI <> nil, '������� �� ������');
  Check(IsEqualGUID(VI.GetGUID, G1), '������ ��������� �������');

  VI := ISimple(FGUIDList.GetByGUID(G2));
  Check(VI <> nil, '������� �� ������');
  Check(IsEqualGUID(VI.GetGUID, G2), '������ ��������� �������');

  VI := ISimple(FGUIDList.GetByGUID(G3));
  Check(VI <> nil, '������� �� ������');
  Check(IsEqualGUID(VI.GetGUID, G3), '������ ��������� �������');

  VI := ISimple(FGUIDList.GetByGUID(G4));
  Check(VI <> nil, '������� �� ������');
  Check(IsEqualGUID(VI.GetGUID, G4), '������ ��������� �������');

  VI := ISimple(FGUIDList.GetByGUID(G5));
  Check(VI <> nil, '������� �� ������');
  Check(IsEqualGUID(VI.GetGUID, G5), '������ ��������� �������');

  VI := ISimple(FGUIDList.GetByGUID(G6));
  Check(VI <> nil, '������� �� ������');
  Check(IsEqualGUID(VI.GetGUID, G6), '������ ��������� �������');

  VI := ISimple(FGUIDList.GetByGUID(G7));
  Check(VI = nil, '������ �������, �������� ���� �� ������ ����');

end;

procedure TestIGUIDInterfaceSet.TestReplace;
var
  VI: ISimple;
begin
  FGUIDList.Add(G6, TSimple.Create(G6));
  FGUIDList.Add(G1, TSimple.Create(G1));
  FGUIDList.Add(G5, TSimple.Create(G5));
  FGUIDList.Add(G2, TSimple.Create(G2));
  FGUIDList.Add(G4, TSimple.Create(G4));
  FGUIDList.Add(G3, TSimple.Create(G3));

  FGUIDList.Replace(G1, TSimple.Create(G2));
  FGUIDList.Replace(G2, TSimple.Create(G3));
  FGUIDList.Replace(G3, TSimple.Create(G4));
  FGUIDList.Replace(G4, TSimple.Create(G5));
  FGUIDList.Replace(G5, TSimple.Create(G6));
  FGUIDList.Replace(G6, TSimple.Create(G1));

  VI := ISimple(FGUIDList.GetByGUID(G1));
  Check(VI <> nil, '������� �� ������');
  Check(IsEqualGUID(VI.GetGUID, G2), '������ ��������� �������');

  VI := ISimple(FGUIDList.GetByGUID(G2));
  Check(VI <> nil, '������� �� ������');
  Check(IsEqualGUID(VI.GetGUID, G3), '������ ��������� �������');

  VI := ISimple(FGUIDList.GetByGUID(G3));
  Check(VI <> nil, '������� �� ������');
  Check(IsEqualGUID(VI.GetGUID, G4), '������ ��������� �������');

  VI := ISimple(FGUIDList.GetByGUID(G4));
  Check(VI <> nil, '������� �� ������');
  Check(IsEqualGUID(VI.GetGUID, G5), '������ ��������� �������');

  VI := ISimple(FGUIDList.GetByGUID(G5));
  Check(VI <> nil, '������� �� ������');
  Check(IsEqualGUID(VI.GetGUID, G6), '������ ��������� �������');

  VI := ISimple(FGUIDList.GetByGUID(G6));
  Check(VI <> nil, '������� �� ������');
  Check(IsEqualGUID(VI.GetGUID, G1), '������ ��������� �������');

  VI := ISimple(FGUIDList.GetByGUID(G7));
  Check(VI = nil, '������ �������, �������� ���� �� ������ ����');
end;

procedure TestIGUIDInterfaceSet.TestRemove;
var
  VI: ISimple;
begin

  FGUIDList.Add(G6, TSimple.Create(G6));
  FGUIDList.Add(G1, TSimple.Create(G1));
  FGUIDList.Add(G5, TSimple.Create(G5));
  FGUIDList.Add(G2, TSimple.Create(G2));
  FGUIDList.Add(G4, TSimple.Create(G4));
  FGUIDList.Add(G3, TSimple.Create(G3));

  FGUIDList.Remove(G1);
  FGUIDList.Remove(G3);
  FGUIDList.Remove(G5);

  VI := ISimple(FGUIDList.GetByGUID(G1));
  Check(VI = nil, '������ �������, �������� ���� �� ������ ����');

  VI := ISimple(FGUIDList.GetByGUID(G2));
  Check(VI <> nil, '������� �� ������');
  Check(IsEqualGUID(VI.GetGUID, G2), '������ ��������� �������');

  VI := ISimple(FGUIDList.GetByGUID(G3));
  Check(VI = nil, '������ �������, �������� ���� �� ������ ����');

  VI := ISimple(FGUIDList.GetByGUID(G4));
  Check(VI <> nil, '������� �� ������');
  Check(IsEqualGUID(VI.GetGUID, G4), '������ ��������� �������');

  VI := ISimple(FGUIDList.GetByGUID(G5));
  Check(VI = nil, '������ �������, �������� ���� �� ������ ����');

  VI := ISimple(FGUIDList.GetByGUID(G6));
  Check(VI <> nil, '������� �� ������');
  Check(IsEqualGUID(VI.GetGUID, G6), '������ ��������� �������');

end;

procedure TestIGUIDInterfaceSet.TestClear;
var
  VEnum: IEnumGUID;
  VGUID: TGUID;
  I: Cardinal;
begin
  FGUIDList.Add(G6, TSimple.Create(G6));
  FGUIDList.Add(G1, TSimple.Create(G1));
  FGUIDList.Add(G5, TSimple.Create(G5));
  FGUIDList.Add(G2, TSimple.Create(G2));
  FGUIDList.Add(G4, TSimple.Create(G4));
  FGUIDList.Add(G3, TSimple.Create(G3));

  FGUIDList.Clear;
  Check(FGUIDList.Count = 0, '������ �� ������ ����� �������');

  VEnum := FGUIDList.GetGUIDEnum;
  Check(VEnum <> nil, '�������� �� �������');

  Check(VEnum.Next(1, VGUID, I) = S_FALSE, '������ ������� � ���������');
end;

procedure TestIGUIDInterfaceSet.TestGetGUIDEnum;
var
  VGUID: TGUID;
  I: Cardinal;
  VEnum: IEnumGUID;
begin
  FGUIDList.Add(G6, TSimple.Create(G6));
  FGUIDList.Add(G1, TSimple.Create(G1));
  FGUIDList.Add(G5, TSimple.Create(G5));
  FGUIDList.Add(G2, TSimple.Create(G2));
  FGUIDList.Add(G4, TSimple.Create(G4));
  FGUIDList.Add(G3, TSimple.Create(G3));

  VEnum := FGUIDList.GetGUIDEnum;
  Check(VEnum <> nil, '�������� �� �������');

  Check(VEnum.Next(1, VGUID, I) = S_OK, '������ ��������� GUID');
  Check(IsEqualGUID(VGUID, G1), '��������� �������.');
  Check(VEnum.Next(1, VGUID, I) = S_OK, '������ ��������� GUID');
  Check(IsEqualGUID(VGUID, G2), '��������� �������.');
  Check(VEnum.Next(1, VGUID, I) = S_OK, '������ ��������� GUID');
  Check(IsEqualGUID(VGUID, G3), '��������� �������.');
  Check(VEnum.Next(1, VGUID, I) = S_OK, '������ ��������� GUID');
  Check(IsEqualGUID(VGUID, G4), '��������� �������.');
  Check(VEnum.Next(1, VGUID, I) = S_OK, '������ ��������� GUID');
  Check(IsEqualGUID(VGUID, G5), '��������� �������.');
  Check(VEnum.Next(1, VGUID, I) = S_OK, '������ ��������� GUID');
  Check(IsEqualGUID(VGUID, G6), '��������� �������.');
  Check(VEnum.Next(1, VGUID, I) = S_FALSE, '������ ������� � ���������');
end;

end.

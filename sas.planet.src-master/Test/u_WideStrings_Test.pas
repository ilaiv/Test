unit u_WideStrings_Test;

{

  Delphi DUnit Test Case
  ----------------------
}

interface

uses
  SysUtils,
  TestFramework;

type
  TestTWideStringList = class(TTestCase)
  published
    procedure TestAdd;
  end;

implementation

uses
  cUnicode,
  WideStrings;

procedure TestTWideStringList.TestAdd;
var
  VList: TWideStringList;
  VIndex: Integer;
begin
  VList := TWideStringList.Create;
  try
    VList.Add(WideString('Test')+ WideLineSeparator);
    Check(WideCompareStr(VList[0], 'Test') <> 0, '����� ����������� ����������� �����.');
    Check((VList[0])[1] = WideChar('T'), '��������� ������ ������.');
    Check((VList[0])[5] = WideLineSeparator, '��������� ��������� ������.');
    VList[0] := 'Test';
    VList.Values['Test'] := 'Proba';
    Check(WideCompareStr(VList.Values['Test'], 'Proba') = 0, '�� ������� �������� �� �����');
    VList.AddObject('IntTest', TObject(10));
    VIndex := VList.IndexOf('IntTest');
    Check(VIndex >= 0, '�� ������� �� �����');
    Check(Integer(VList.Objects[VIndex]) = 10, '�� ����� ������� �� ��� ������, ������� ��������');
    VList.Delete(1);
    Check(VList.Count = 2,'����� �������� ������ ���� �������� 2 ������');
  finally
    FreeAndNil(VList);
  end;
end;


initialization
  RegisterTest(TestTWideStringList.Suite);
end.

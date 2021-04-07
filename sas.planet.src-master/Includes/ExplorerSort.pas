//  ****************************************************************************
//  * Project   : ������ "���������� ������ �� ������� "���������� Windows""
//  * Details   : http://alexander-bagel.blogspot.ru/2013/06/windows.html
//  * Purpose   : ���������� ��������� ����������
//  * Author    : ��������� (Rouse_) ������
//  * Version   : 1.0
//  * Home Page : http://rouse.drkb.ru
//  * Home Blog : http://alexander-bagel.blogspot.com/
//  ****************************************************************************

unit ExplorerSort;

interface

uses
  Windows,
  Classes;

function CompareStringOrdinal(const S1, S2: string): Integer;

function StringListCompare(List: TStringList; Index1, Index2: Integer): Integer;
function ListViewCompare(lParam1, lParam2, lParamSort: Integer): Integer stdcall;
function TreeViewCompare(lParam1, lParam2, lParamSort: LPARAM): Integer stdcall;

implementation

uses
  SysUtils,
  ComCtrls;

function StringListCompare(List: TStringList; Index1, Index2: Integer): Integer;
begin
  Result := CompareStringOrdinal(List.Strings[Index1], List.Strings[Index2]);
end;

function ListViewCompare(lParam1, lParam2, lParamSort: Integer): Integer stdcall;
begin
  Result := CompareStringOrdinal(TListItem(lParam1).Caption, TListItem(lParam2).Caption);
end;

function TreeViewCompare(lParam1, lParam2, lParamSort: LPARAM): Integer stdcall;
begin
  Result := CompareStringOrdinal(TTreeNode(lParam1).Text, TTreeNode(lParam2).Text);
end;

// =============================================================================
// CompareStringOrdinal ���������� ��� ������ �� ������� ����������, �.�.
// "����� ����� (3)" < "����� ����� (103)"
//
// ���������� ��������� ��������
// -1     - ������ ������ ������ ������
// 0      - ������ ������������
// 1      - ������ ������ ������ ������
// =============================================================================
function CompareStringOrdinal(const S1, S2: string): Integer;
 
  // ������� CharInSet ��������� ������� � Delphi 2009,
  // ��� ����� ������ ������ ��������� �� ������
{$IFNDEF UNICODE}
  function CharInSet(AChar: Char; ASet: TSysCharSet): Boolean;
  begin
    Result := AChar in ASet;
  end;
{$ENDIF}
var
  S1IsInt, S2IsInt: Boolean;
  S1Cursor, S2Cursor: PChar;
  S1Int, S2Int, Counter, S1IntCount, S2IntCount: Integer;
  SingleByte: Byte;
begin
  // �������� �� ������ ������
  if S1 = '' then
    if S2 = '' then
    begin
      Result := 0;
      Exit;
    end
    else
    begin
      Result := -1;
      Exit;
    end;
 
  if S2 = '' then
  begin
    Result := 1;
    Exit;
  end;
 
  S1Cursor := @AnsiLowerCase(S1)[1];
  S2Cursor := @AnsiLowerCase(S2)[1];
 
  while True do
  begin
    // �������� �� ����� ������ ������
    if S1Cursor^ = #0 then
      if S2Cursor^ = #0 then
      begin
        Result := 0;
        Exit;
      end
      else
      begin
        Result := -1;
        Exit;
      end;
 
    // �������� �� ����� ������ ������
    if S2Cursor^ = #0 then
    begin
      Result := 1;
      Exit;
    end;
 
    // �������� �� ������ ����� � ����� �������
    S1IsInt := CharInSet(S1Cursor^, ['0'..'9']);
    S2IsInt := CharInSet(S2Cursor^, ['0'..'9']);
    if S1IsInt and not S2IsInt then
    begin
      Result := -1;
      Exit;
    end;
    if not S1IsInt and S2IsInt then
    begin
      Result := 1;
      Exit;
    end;
 
    // ������������ ���������
    if not (S1IsInt and S2IsInt) then
    begin
      if S1Cursor^ = S2Cursor^ then
      begin
        Inc(S1Cursor);
        Inc(S2Cursor);
        Continue;
      end;
      if S1Cursor^ < S2Cursor^ then
      begin
        Result := -1;
        Exit;
      end
      else
      begin
        Result := 1;
        Exit;
      end;
    end;
 
    // ����������� ����� �� ����� ����� � ����������
    S1Int := 0;
    Counter := 1;
    S1IntCount := 0;
    repeat
      Inc(S1IntCount);
      SingleByte := Byte(S1Cursor^) - Byte('0');
      S1Int := S1Int * Counter + SingleByte;
      Inc(S1Cursor);
      Counter := 10;
    until not CharInSet(S1Cursor^, ['0'..'9']);
 
    S2Int := 0;
    Counter := 1;
    S2IntCount := 0;
    repeat
      SingleByte := Byte(S2Cursor^) - Byte('0');
      Inc(S2IntCount);
      S2Int := S2Int * Counter + SingleByte;
      Inc(S2Cursor);
      Counter := 10;
    until not CharInSet(S2Cursor^, ['0'..'9']);
 
    if S1Int = S2Int then
    begin
      if S1Int = 0 then
      begin
        if S1IntCount < S2IntCount then
        begin
          Result := -1;
          Exit;
        end;
        if S1IntCount > S2IntCount then
        begin
          Result := 1;
          Exit;
        end;
      end;
      Continue;
    end;
    if S1Int < S2Int then
    begin
      Result := -1;
      Exit;
    end
    else
    begin
      Result := 1;
      Exit;
    end;
  end;
end;

end.

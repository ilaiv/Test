{ **** UBPFD *********** by delphibase.endimus.com ****
>> �������� ��������� �������� ������ � �������������

�������� ������������ ����������� - ������� �������� ���� ����.
�������� ���������� ����������:

-DeleteAllFilesAndFolder - ���� TRUE �� �������� ����� �����������
������� ��� ��������� �������� faArchive ������ ����� ��� �����
����� ���(�) ���������;

-StopIfNotAllDeleted - ���� TRUE �� ������ ������� �����������
������������ ���� �������� ������ �������� ���� �� ������ ����� ��� �����;

-RemoveRoot - ���� TRUE, ��������� �� ������������� �������� �����.

�����������: FileCtrl, SysUtils
�����:       lipskiy, lipskiy@mail.ru, ICQ:51219290, �����-���������
Copyright:   ����������� ��������� (lipskiy)
����:        26 ������ 2002 �.
***************************************************** }

unit u_TreeFolderRemover;

interface

uses
  Windows,
  {$WARNINGS OFF}
  FileCtrl,
  {$WARNINGS ON}
  SysUtils;

function FullRemoveDir(Dir: string; DeleteAllFilesAndFolders,
  StopIfNotAllDeleted, RemoveRoot: boolean): Boolean;

implementation

{$WARNINGS OFF} // Disable specific to a platform warnings
function FullRemoveDir(Dir: string; DeleteAllFilesAndFolders,
  StopIfNotAllDeleted, RemoveRoot: boolean): Boolean;
var
  i: Integer;
  SRec: TSearchRec;
  FN: string;
begin
  Result := False;
  if not DirectoryExists(Dir) then
    exit;
  Result := True;
  // ��������� ���� � ����� � ������ ����� - "��� ����� � ����������"
  Dir := IncludeTrailingBackslash(Dir);
  i := FindFirst(Dir + '*', faAnyFile, SRec);
  try
    while i = 0 do
    begin
      // �������� ������ ���� � ����� ��� ����������
      FN := Dir + SRec.Name;
      // ���� ��� ����������
      if ((SRec.Attr and faDirectory) = faDirectory) then
      begin
        // ����������� ����� ���� �� ������� � ������ �������� �����
        if (SRec.Name <> '') and (SRec.Name <> '.') and (SRec.Name <> '..') then
        begin
          if DeleteAllFilesAndFolders then
            FileSetAttr(FN, faArchive);
          Result := FullRemoveDir(FN, DeleteAllFilesAndFolders,
            StopIfNotAllDeleted, True);
          if not Result and StopIfNotAllDeleted then
            exit;
        end;
      end
      else // ����� ������� ����
      begin
        if DeleteAllFilesAndFolders then
          FileSetAttr(FN, faArchive);
        Result := SysUtils.DeleteFile(FN);
        if not Result and StopIfNotAllDeleted then
          exit;
      end;
      // ����� ��������� ���� ��� ����������
      i := FindNext(SRec);
    end;
  finally
    SysUtils.FindClose(SRec);
  end;
  if not Result then
    exit;
  if RemoveRoot then // ���� ���������� ������� ������ - �������
    if not RemoveDir(Dir) then
      Result := false;
end;
{$WARNINGS ON}

// ������ �������������:
//
// FullRemoveDir('C:\a', true, true, true);
// ������ �������� ����� C:\a �� ���� � ����������,
// � � ����������� ��������� ����� c:\a

end.
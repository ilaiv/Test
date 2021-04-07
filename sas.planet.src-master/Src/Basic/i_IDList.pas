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
unit i_IDList;

interface

uses
  ActiveX,
  i_EnumID;

type
  IIDInterfaceList = interface(IInterface)
    ['{9AC37296-C3C6-4272-A829-F5DB3D702382}']
    // ���������� �������. ���� ������ � ����� ID ��� ����, �� ���������� �� �����
    // ���������� �������� ������
    function Add(
      AID: Integer;
      const AInterface: IInterface
    ): IInterface;

    // �������� ������� ID � ������
    function IsExists(AID: Integer): boolean;

    // ��������� ������� �� ID
    function GetByID(AID: Integer): IInterface;

    // ������ ������������� ������� �����, ���� �����������, �� ������ ���������
    procedure Replace(
      AID: Integer;
      const AInterface: IInterface
    );

    // �������� �������, ���� ��� � ����� GUID, �� ������ �� ����� �����������
    procedure Remove(AID: Integer);

    // ������� ������
    procedure Clear;

    // ��������� ��������� ID
    function GetIDEnum(): IEnumID;
    function GetEnumUnknown: IEnumUnknown;

    procedure SetCount(NewCount: Integer);
    function GetCount: Integer;
    property Count: Integer read GetCount write SetCount;
  end;

  IIDObjectList = interface(IInterface)
    ['{52DB5379-FCF5-4681-932E-6B09B141A607}']
    // ���������� �������. ���� ������ � ����� ID ��� ����, �� ���������� �� �����
    // ���� ������ �������� ���������� �������� � ���������� ������ �� ����� ���������, �� �� ����� ������
    // ���������� �������� ������
    function Add(
      AID: Integer;
      AObj: TObject
    ): TObject;

    // �������� ������� ID � ������
    function IsExists(AID: Integer): boolean;

    // ��������� ������� �� ID
    function GetByGUID(AID: Integer): TObject;

    // ������ ������������� ������� �����, ���� �����������, �� ������ ���������
    procedure Replace(
      AID: Integer;
      AObj: TObject
    );

    // �������� �������, ���� ��� � ����� ID, �� ������ �� ����� �����������
    procedure Remove(AID: Integer);

    // ������� ������
    procedure Clear;

    // ��������� ��������� ID
    function GetIDEnum(): IEnumID;

    // �������� �� ���� ������ ���������� ��������
    function GetIsObjectOwner: Boolean;

    procedure SetCount(NewCount: Integer);
    function GetCount: Integer;
    property Count: Integer read GetCount write SetCount;
  end;

implementation

end.

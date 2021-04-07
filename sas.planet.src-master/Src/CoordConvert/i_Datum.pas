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

unit i_Datum;

interface

uses
  t_Hash,
  t_GeoTypes,
  i_EnumDoublePoint,
  i_NotifierOperation;

type
  IDatum = interface
    ['{FF96E41C-41EC-4D87-BD1B-42F8E7CA3E15}']
    function GetHash: THashValue;
    property Hash: THashValue read GetHash;

    // ���������� ��� EPSG ��� ����� ������. ��� ������������� �������� � ��������� ����� ���������� 0
    function GetEPSG: integer; stdcall;
    property EPSG: Integer read GetEPSG;

    // ���������� ������ ��������.
    function GetSpheroidRadiusA: Double; stdcall;
    function GetSpheroidRadiusB: Double; stdcall;

    // ���������� �������� �� ������ ��������� ������������� ��������
    function IsSameDatum(const ADatum: IDatum): Boolean; stdcall;

    function CalcPolygonArea(
      const APoints: PDoublePointArray;
      const ACount: Integer;
      const ANotifier: INotifierOperation = nil;
      const AOperationID: Integer = 0
    ): Double;

    // ���������� ���������� (����� ������������� �����) ���������� ����� �����
    // ��������� ������� (� ������).
    function CalcDist(
      const AStart: TDoublePoint;
      const AFinish: TDoublePoint
    ): Double; overload;

    // ������ ��� ���������� ������ (��������) ������������� ������: ���������
    // ���������� ������� ����� ����� ������� �� ���������������� ����������� �
    // ������������ ���������� � ����������� ��������.
    function CalcDist(
      const AStart: TDoublePoint;
      const AFinish: TDoublePoint;
      out AInitialBearing: Double;
      out AFinalBearing: Double
    ): Double; overload;

    // ������ ��� ���������� ������ (������) ������������� ������: ��� ��
    // ��������, ���� ������ �� ��������� ����� � ��������� ����������� �
    // �����, �� ����������, ��������� ����������.
    function CalcFinishPosition(
      const AStart: TDoublePoint;
      const AInitialBearing: Double;
      const ADistance: Double
    ): TDoublePoint;

    // ��������� ���������� �������� ������� ����� ��������� �������
    function CalcMiddlePoint(
      const AStart: TDoublePoint;
      const AFinish: TDoublePoint
    ): TDoublePoint;

    // ���������� ������������� ����� ����� ������������� �����
    function GetLinePoints(
      const AStart: TDoublePoint;
      const AFinish: TDoublePoint;
      const APointCount: integer
    ): IEnumLonLatPoint;
  end;

implementation

end.

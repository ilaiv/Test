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

unit i_DebugInfoSubSystem;

interface

uses
  i_InterfaceListStatic,
  i_InternalPerformanceCounter;

type
  IDebugInfoSubSystem = interface
    ['{373EFDD9-7529-4E43-B3AF-2E8C90BA043D}']
    function GetRootCounterList: IInternalPerformanceCounterList;
    property RootCounterList: IInternalPerformanceCounterList read GetRootCounterList;

    function GetStaticDataList: IInterfaceListStatic;
  end;


implementation

end.

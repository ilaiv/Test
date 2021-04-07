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

unit i_BitmapPostProcessing;

interface

uses
  i_Bitmap32Static,
  i_Changeable;

type
  IBitmapPostProcessing = interface
    ['{3DBBF6CA-6AA3-4578-8D23-3E04D1D42C34}']
    function Process(const ABitmap: IBitmap32Static): IBitmap32Static;
  end;

  IBitmapPostProcessingChangeable = interface(IChangeable)
    ['{176AC2B3-0BE7-4383-B87A-8649C7F086EE}']
    function GetStatic: IBitmapPostProcessing;
  end;

implementation

end.

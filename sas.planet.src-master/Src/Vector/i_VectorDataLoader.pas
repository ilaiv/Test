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

unit i_VectorDataLoader;

interface

uses
  i_BinaryData,
  i_VectorDataFactory,
  i_ImportConfig,
  i_VectorItemSubset;

type
  TVectorLoadContext = record
    IdData: Pointer;
    MainInfoFactory: IVectorDataItemMainInfoFactory;
    PointParams: IImportPointParams;
    LineParams: IImportLineParams;
    PolygonParams: IImportPolyParams;
    procedure Init; inline;
  end;

type
  IVectorDataLoader = interface
    ['{F9986E7D-897C-4BD3-8A92-A9798BFB32FA}']
    function Load(
      const AContext: TVectorLoadContext;
      const AData: IBinaryData
    ): IVectorItemSubset;
  end;

implementation

{ TVectorLoadContext }

procedure TVectorLoadContext.Init;
begin
  IdData := nil;
  MainInfoFactory := nil;
  PointParams := nil;
  LineParams := nil;
  PolygonParams := nil;
end;

end.

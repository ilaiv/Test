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

unit i_MarkCategoryDBImpl;

interface

uses
  i_Notifier,
  i_Category,
  i_MarkCategoryList,
  i_MarkCategory;

type
  IMarkCategoryDBImpl = interface
    ['{7B54650B-BF85-4688-A493-0DED82DADFFD}']
    function GetFirstCategoryByName(const AName: string): IMarkCategory;
    function GetCategoryByNameCount(const AName: string): Integer;

    function UpdateCategory(
      const AOldCategory: IMarkCategory;
      const ANewCategory: IMarkCategory
    ): IMarkCategory;

    function UpdateCategoryList(
      const AOldCategory: IMarkCategoryList;
      const ANewCategory: IMarkCategoryList
    ): IMarkCategoryList;

    function IsCategoryFromThisDb(const ACategory: ICategory): Boolean;

    function GetCategoriesList: IMarkCategoryList;
    procedure SetAllCategoriesVisible(ANewVisible: Boolean);

    function GetChangeNotifier: INotifier;
    property ChangeNotifier: INotifier read GetChangeNotifier;
  end;

implementation

end.

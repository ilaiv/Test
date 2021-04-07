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

unit u_MarkDbByImpl;

interface

uses
  t_GeoTypes,
  i_Listener,
  i_Notifier,
  i_Category,
  i_MarkCategoryList,
  i_InterfaceListStatic,
  i_VectorItemSubset,
  i_MarkId,
  i_VectorDataItemSimple,
  i_MarkFactory,
  i_MarkDb,
  i_MarkSystemImplChangeable,
  u_BaseInterfacedObject;

type
  TMarkDbByImpl = class(TBaseInterfacedObject, IMarkDb)
  private
    FMarkSystemImpl: IMarkSystemImplChangeable;
    FNotifier: INotifier;

    FMarkFactory: IMarkFactory;
    FChangeNotifier: INotifier;
    FChangeNotifierInternal: INotifierInternal;
    FErrorNotifierInternal: INotifierInternal;
    FImplChangeListener: IListener;
    FDbImplChangeListener: IListener;
  private
    procedure OnImplChange;
    procedure OnDBImplChange;
  private
    function GetFirstMarkByName(
      const AName: string;
      const ACategory: ICategory
    ): IVectorDataItem;

    function GetMarkSubsetByCategoryList(
      const ACategoryList: IMarkCategoryList;
      const AIncludeHiddenMarks: Boolean
    ): IVectorItemSubset;
    function GetMarkSubsetByCategory(
      const ACategory: ICategory;
      const AIncludeHiddenMarks: Boolean
    ): IVectorItemSubset;
    function GetMarkSubsetByCategoryListInRect(
      const ARect: TDoubleRect;
      const ACategoryList: IMarkCategoryList;
      const AIncludeHiddenMarks: Boolean;
      const ALonLatSize: TDoublePoint
    ): IVectorItemSubset;
    function GetMarkSubsetByCategoryInRect(
      const ARect: TDoubleRect;
      const ACategory: ICategory;
      const AIncludeHiddenMarks: Boolean;
      const ALonLatSize: TDoublePoint
    ): IVectorItemSubset;
    function FindMarks(
      const ASearch: string;
      const AMaxCount: Integer;
      const AIncludeHiddenMarks: Boolean;
      const ASearchInDescription: Boolean
    ): IVectorItemSubset;

    function UpdateMark(
      const AOldMark: IVectorDataItem;
      const ANewMark: IVectorDataItem
    ): IVectorDataItem;
    function UpdateMarkList(
      const AOldMarkList: IInterfaceListStatic;
      const ANewMarkList: IInterfaceListStatic
    ): IInterfaceListStatic;

    function GetAllMarkIdList: IInterfaceListStatic;
    function GetMarkIdListByCategory(const ACategory: ICategory): IInterfaceListStatic;

    function GetMarkByID(const AMarkId: IMarkId): IVectorDataItem;

    procedure SetMarkVisibleByID(
      const AMark: IMarkId;
      AVisible: Boolean
    );
    procedure SetMarkVisible(
      const AMark: IVectorDataItem;
      AVisible: Boolean
    );

    procedure SetMarkVisibleByIDList(
      const AMarkList: IInterfaceListStatic;
      AVisible: Boolean
    );
    procedure ToggleMarkVisibleByIDList(const AMarkList: IInterfaceListStatic);

    function GetMarkVisibleByID(const AMark: IMarkId): Boolean;
    function GetMarkVisible(const AMark: IVectorDataItem): Boolean;
    procedure SetAllMarksInCategoryVisible(
      const ACategory: ICategory;
      ANewVisible: Boolean
    );

    function GetFactory: IMarkFactory;
    function GetChangeNotifier: INotifier;
  public
    constructor Create(
      const AMarkSystemImpl: IMarkSystemImplChangeable;
      const AMarkFactory: IMarkFactory;
      const AErrorNotifierInternal: INotifierInternal
    );
    destructor Destroy; override;
  end;

implementation

uses
  SysUtils,
  i_MarkSystemImpl,
  u_MarkSystemErrorHandler,
  u_Notifier,
  u_Synchronizer,
  u_ListenerByEvent;

{ TMarkDbByImpl }

constructor TMarkDbByImpl.Create(
  const AMarkSystemImpl: IMarkSystemImplChangeable;
  const AMarkFactory: IMarkFactory;
  const AErrorNotifierInternal: INotifierInternal
);
begin
  inherited Create;
  FMarkSystemImpl := AMarkSystemImpl;
  FMarkFactory := AMarkFactory;
  FErrorNotifierInternal := AErrorNotifierInternal;
  FChangeNotifierInternal :=
    TNotifierBase.Create(
      GSync.SyncVariable.Make(Self.ClassName + 'Notifier')
    );
  FChangeNotifier := FChangeNotifierInternal;
  FImplChangeListener := TNotifyNoMmgEventListener.Create(Self.OnImplChange);
  FDbImplChangeListener := TNotifyNoMmgEventListener.Create(Self.OnDbImplChange);

  FMarkSystemImpl.ChangeNotifier.Add(FImplChangeListener);
  OnDBImplChange;
end;

destructor TMarkDbByImpl.Destroy;
begin
  if Assigned(FNotifier) and Assigned(FDbImplChangeListener) then begin
    FNotifier.Remove(FDbImplChangeListener);
    FNotifier := nil;
  end;
  if Assigned(FMarkSystemImpl) and Assigned(FImplChangeListener) then begin
    FMarkSystemImpl.ChangeNotifier.Remove(FImplChangeListener);
    FMarkSystemImpl := nil;
  end;
  inherited;
end;

function TMarkDbByImpl.GetAllMarkIdList: IInterfaceListStatic;
var
  VImpl: IMarkSystemImpl;
begin
  Result := nil;
  try
    VImpl := FMarkSystemImpl.GetStatic;
    if VImpl <> nil then begin
      Result := VImpl.MarkDb.GetAllMarkIdList;
    end;
  except
    on E: Exception do begin
      Result := nil;
      CatchException(E, FErrorNotifierInternal);
    end;
  end;
end;

function TMarkDbByImpl.GetChangeNotifier: INotifier;
begin
  Result := FChangeNotifier;
end;

function TMarkDbByImpl.GetFactory: IMarkFactory;
begin
  Result := FMarkFactory;
end;

function TMarkDbByImpl.GetMarkByID(const AMarkId: IMarkId): IVectorDataItem;
var
  VImpl: IMarkSystemImpl;
begin
  Result := nil;
  try
    VImpl := FMarkSystemImpl.GetStatic;
    if VImpl <> nil then begin
      Result := VImpl.MarkDb.GetMarkByID(AMarkId);
    end;
  except
    on E: Exception do begin
      Result := nil;
      CatchException(E, FErrorNotifierInternal);
    end;
  end;
end;

function TMarkDbByImpl.GetFirstMarkByName(
  const AName: string;
  const ACategory: ICategory
): IVectorDataItem;
var
  VImpl: IMarkSystemImpl;
begin
  Result := nil;
  try
    VImpl := FMarkSystemImpl.GetStatic;
    if VImpl <> nil then begin
      Result := VImpl.MarkDb.GetFirstMarkByName(AName, ACategory);
    end;
  except
    on E: Exception do begin
      Result := nil;
      CatchException(E, FErrorNotifierInternal);
    end;
  end;
end;

function TMarkDbByImpl.GetMarkIdListByCategory(
  const ACategory: ICategory
): IInterfaceListStatic;
var
  VImpl: IMarkSystemImpl;
begin
  Result := nil;
  try
    VImpl := FMarkSystemImpl.GetStatic;
    if VImpl <> nil then begin
      Result := VImpl.MarkDb.GetMarkIdListByCategory(ACategory);
    end;
  except
    on E: Exception do begin
      Result := nil;
      CatchException(E, FErrorNotifierInternal);
    end;
  end;
end;

function TMarkDbByImpl.GetMarkSubsetByCategory(
  const ACategory: ICategory;
  const AIncludeHiddenMarks: Boolean
): IVectorItemSubset;
var
  VImpl: IMarkSystemImpl;
begin
  Result := nil;
  try
    VImpl := FMarkSystemImpl.GetStatic;
    if VImpl <> nil then begin
      Result := VImpl.MarkDb.GetMarkSubsetByCategory(ACategory, AIncludeHiddenMarks);
    end;
  except
    on E: Exception do begin
      Result := nil;
      CatchException(E, FErrorNotifierInternal);
    end;
  end;
end;

function TMarkDbByImpl.GetMarkSubsetByCategoryInRect(
  const ARect: TDoubleRect;
  const ACategory: ICategory;
  const AIncludeHiddenMarks: Boolean;
  const ALonLatSize: TDoublePoint
): IVectorItemSubset;
var
  VImpl: IMarkSystemImpl;
begin
  Result := nil;
  try
    VImpl := FMarkSystemImpl.GetStatic;
    if VImpl <> nil then begin
      Result := VImpl.MarkDb.GetMarkSubsetByCategoryInRect(ARect, ACategory, AIncludeHiddenMarks, ALonLatSize);
    end;
  except
    on E: Exception do begin
      Result := nil;
      CatchException(E, FErrorNotifierInternal);
    end;
  end;
end;

function TMarkDbByImpl.GetMarkSubsetByCategoryList(
  const ACategoryList: IMarkCategoryList;
  const AIncludeHiddenMarks: Boolean
): IVectorItemSubset;
var
  VImpl: IMarkSystemImpl;
begin
  Result := nil;
  try
    VImpl := FMarkSystemImpl.GetStatic;
    if VImpl <> nil then begin
      Result := VImpl.MarkDb.GetMarkSubsetByCategoryList(ACategoryList, AIncludeHiddenMarks);
    end;
  except
    on E: Exception do begin
      Result := nil;
      CatchException(E, FErrorNotifierInternal);
    end;
  end;
end;

function TMarkDbByImpl.GetMarkSubsetByCategoryListInRect(
  const ARect: TDoubleRect;
  const ACategoryList: IMarkCategoryList;
  const AIncludeHiddenMarks: Boolean;
  const ALonLatSize: TDoublePoint
): IVectorItemSubset;
var
  VImpl: IMarkSystemImpl;
begin
  Result := nil;
  try
    VImpl := FMarkSystemImpl.GetStatic;
    if VImpl <> nil then begin
      Result := VImpl.MarkDb.GetMarkSubsetByCategoryListInRect(ARect, ACategoryList, AIncludeHiddenMarks, ALonLatSize);
    end;
  except
    on E: Exception do begin
      Result := nil;
      CatchException(E, FErrorNotifierInternal);
    end;
  end;
end;

function TMarkDbByImpl.FindMarks(
  const ASearch: string;
  const AMaxCount: Integer;
  const AIncludeHiddenMarks: Boolean;
  const ASearchInDescription: Boolean
): IVectorItemSubset;
var
  VImpl: IMarkSystemImpl;
begin
  Result := nil;
  try
    VImpl := FMarkSystemImpl.GetStatic;
    if VImpl <> nil then begin
      Result := VImpl.MarkDb.FindMarks(ASearch, AMaxCount, AIncludeHiddenMarks, ASearchInDescription);
    end;
  except
    on E: Exception do begin
      Result := nil;
      CatchException(E, FErrorNotifierInternal);
    end;
  end;
end;

function TMarkDbByImpl.GetMarkVisible(const AMark: IVectorDataItem): Boolean;
var
  VImpl: IMarkSystemImpl;
begin
  Result := True;
  try
    VImpl := FMarkSystemImpl.GetStatic;
    if VImpl <> nil then begin
      Result := VImpl.MarkDb.GetMarkVisible(AMark);
    end;
  except
    on E: Exception do begin
      Result := True;
      CatchException(E, FErrorNotifierInternal);
    end;
  end;
end;

function TMarkDbByImpl.GetMarkVisibleByID(const AMark: IMarkId): Boolean;
var
  VImpl: IMarkSystemImpl;
begin
  Result := True;
  try
    VImpl := FMarkSystemImpl.GetStatic;
    if VImpl <> nil then begin
      Result := VImpl.MarkDb.GetMarkVisibleByID(AMark);
    end;
  except
    on E: Exception do begin
      Result := True;
      CatchException(E, FErrorNotifierInternal);
    end;
  end;
end;

procedure TMarkDbByImpl.OnImplChange;
var
  VImpl: IMarkSystemImpl;
begin
  try
    if FNotifier <> nil then begin
      FNotifier.Remove(FDbImplChangeListener);
      FNotifier := nil;
    end;
    VImpl := FMarkSystemImpl.GetStatic;
    if VImpl <> nil then begin
      FNotifier := VImpl.MarkDb.ChangeNotifier;
      FNotifier.Add(FDbImplChangeListener);
    end;
  except
    on E: Exception do begin
      CatchException(E, FErrorNotifierInternal);
    end;
  end;
end;

procedure TMarkDbByImpl.OnDbImplChange;
begin
  FChangeNotifierInternal.Notify(nil);
end;

procedure TMarkDbByImpl.SetAllMarksInCategoryVisible(
  const ACategory: ICategory;
  ANewVisible: Boolean
);
var
  VImpl: IMarkSystemImpl;
begin
  try
    VImpl := FMarkSystemImpl.GetStatic;
    if VImpl <> nil then begin
      VImpl.MarkDb.SetAllMarksInCategoryVisible(ACategory, ANewVisible);
    end;
  except
    on E: Exception do begin
      CatchException(E, FErrorNotifierInternal);
    end;
  end;
end;

procedure TMarkDbByImpl.SetMarkVisible(
  const AMark: IVectorDataItem;
  AVisible: Boolean
);
var
  VImpl: IMarkSystemImpl;
begin
  try
    VImpl := FMarkSystemImpl.GetStatic;
    if VImpl <> nil then begin
      VImpl.MarkDb.SetMarkVisible(AMark, AVisible);
    end;
  except
    on E: Exception do begin
      CatchException(E, FErrorNotifierInternal);
    end;
  end;
end;

procedure TMarkDbByImpl.SetMarkVisibleByID(
  const AMark: IMarkId;
  AVisible: Boolean
);
var
  VImpl: IMarkSystemImpl;
begin
  try
    VImpl := FMarkSystemImpl.GetStatic;
    if VImpl <> nil then begin
      VImpl.MarkDb.SetMarkVisibleByID(AMark, AVisible);
    end;
  except
    on E: Exception do begin
      CatchException(E, FErrorNotifierInternal);
    end;
  end;
end;

procedure TMarkDbByImpl.SetMarkVisibleByIDList(
  const AMarkList: IInterfaceListStatic;
  AVisible: Boolean
);
var
  VImpl: IMarkSystemImpl;
begin
  try
    VImpl := FMarkSystemImpl.GetStatic;
    if VImpl <> nil then begin
      VImpl.MarkDb.SetMarkVisibleByIDList(AMarkList, AVisible);
    end;
  except
    on E: Exception do begin
      CatchException(E, FErrorNotifierInternal);
    end;
  end;
end;

procedure TMarkDbByImpl.ToggleMarkVisibleByIDList(
  const AMarkList: IInterfaceListStatic
);
var
  VImpl: IMarkSystemImpl;
begin
  try
    VImpl := FMarkSystemImpl.GetStatic;
    if VImpl <> nil then begin
      VImpl.MarkDb.ToggleMarkVisibleByIDList(AMarkList);
    end;
  except
    on E: Exception do begin
      CatchException(E, FErrorNotifierInternal);
    end;
  end;
end;

function TMarkDbByImpl.UpdateMark(const AOldMark, ANewMark: IVectorDataItem): IVectorDataItem;
var
  VImpl: IMarkSystemImpl;
begin
  Result := nil;
  try
    VImpl := FMarkSystemImpl.GetStatic;
    if VImpl <> nil then begin
      Result := VImpl.MarkDb.UpdateMark(AOldMark, ANewMark);
    end;
  except
    on E: Exception do begin
      Result := nil;
      CatchException(E, FErrorNotifierInternal);
    end;
  end;
end;

function TMarkDbByImpl.UpdateMarkList(
  const AOldMarkList, ANewMarkList: IInterfaceListStatic
): IInterfaceListStatic;
var
  VImpl: IMarkSystemImpl;
begin
  Result := nil;
  try
    VImpl := FMarkSystemImpl.GetStatic;
    if VImpl <> nil then begin
      Result := VImpl.MarkDb.UpdateMarkList(AOldMarkList, ANewMarkList);
    end;
  except
    on E: Exception do begin
      Result := nil;
      CatchException(E, FErrorNotifierInternal);
    end;
  end;
end;

end.

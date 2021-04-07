{******************************************************************************}
{* SAS.Planet (SAS.�������)                                                   *}
{* Copyright (C) 2007-2015, SAS.Planet development team.                      *}
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

unit u_MarkDbImplORMHelper;

interface

{$I ..\MarkSystemORM.inc}

uses
  Types,
  Windows,
  Classes,
  SysUtils,
  mORMot,
  mORMotMongoDB,
  mORMotSQLite3,
  SynCommons,
  SynMongoDB,
  {$IFDEF ENABLE_DBMS}
  SynDB,
  {$ENDIF}
  t_GeoTypes,
  t_MarkSystemORM,
  i_GeometryLonLat,
  i_GeometryToStream,
  i_GeometryFromStream,
  i_MarkSystemImplORMClientProvider,
  u_MarkSystemORMModel,
  u_MarkDbImplORMCache;

type
  TMarkDbImplORMHelper = class
  private
    type
      TMarkWithCategoryID = record
        MarkID: TID;
        CategoryID: TID;
      end;
      TMarkWithCategoryIDDynArray = array of TMarkWithCategoryID;
  private
    FUserID: TID;
    FClient: TSQLRestClientDB;
    FCache: TSQLMarkDbCache;
    FIsReadOnly: Boolean;
    FGeometryWriter: IGeometryToStream;
    FGeometryReader: IGeometryFromStream;
    FClientType: TMarkSystemImplORMClientType;
    FClientProvider: IMarkSystemImplORMClientProvider;
    FSQLMarkClass: TSQLMarkClass;
    FSQLMarkName: RawUTF8;
  private
    function _GeomertryFromBlob(const ABlob: TSQLRawBlob): IGeometryLonLat;
    function _GeomertryToBlob(const AGeometry: IGeometryLonLat): TSQLRawBlob;
    function _AddMarkImage(const APicName: string): TID;
    procedure _ReadMarkImage(var AMarkRec: TSQLMarkRec);
    function _AddMarkAppearance(
      const AColor1, AColor2: Cardinal;
      const AScale1, AScale2: Integer
    ): TID;
    procedure _ReadMarkAppearance(var AMarkRec: TSQLMarkRec);
    function _FillPrepareMarkIdIndex(const ACategoryID: TID): Integer;
    procedure _FillPrepareMarkIdCache(const ACategoryID: TID);
    procedure _FillPrepareMarkGeometryCache(const ACategoryID: TID);
    procedure _FillPrepareMarkViewCache(const ACategoryID: TID);
    function _GetMarkIDArrayByRectSQL(
      const ACategoryIDArray: TIDDynArray;
      const ARect: TDoubleRect;
      const ALonSize: Cardinal;
      const ALatSize: Cardinal;
      const AReciveCategoryID: Boolean;
      out AIDArray: TMarkWithCategoryIDDynArray
    ): Integer;
    {$IFDEF ENABLE_DBMS}
    function _GetMarkIDArrayByRectDBMS(
      const ACategoryIDArray: TIDDynArray;
      const ARect: TDoubleRect;
      const ALonSize: Cardinal;
      const ALatSize: Cardinal;
      const AReciveCategoryID: Boolean;
      out AIDArray: TMarkWithCategoryIDDynArray
    ): Integer;
    {$ENDIF}
    function _GetMarkIDArrayByRectMongoDB(
      const ACategoryIDArray: TIDDynArray;
      const ARect: TDoubleRect;
      const ALonSize: Cardinal;
      const ALatSize: Cardinal;
      const AReciveCategoryID: Boolean;
      out AIDArray: TMarkWithCategoryIDDynArray
    ): Integer;
    function _GetMarkRecArrayByTextSQLite3(
      const ASearch: RawUTF8;
      const AMaxCount: Integer;
      const ASearchInDescription: Boolean;
      out ANameIDArray: TIDDynArray;
      out ADescIDArray: TIDDynArray
    ): Integer;
    function _GetMarkRecArrayByTextSQL(
      const ASearch: RawUTF8;
      const AMaxCount: Integer;
      const ASearchInDescription: Boolean;
      out ANameIDArray: TIDDynArray;
      out ADescIDArray: TIDDynArray
    ): Integer;
  public
    function DeleteMarkSQL(
      const AMarkID: TID
    ): Boolean;
    function InsertMarkSQL(
      var AMarkRec: TSQLMarkRec
    ): Boolean;
    function UpdateMarkSQL(
      const AOldMarkRec: TSQLMarkRec;
      var ANewMarkRec: TSQLMarkRec
    ): Boolean;
    function ReadMarkSQL(
      out AMarkRec: TSQLMarkRec;
      const AMarkID: TID;
      const ACategoryID: TID;
      const AMarkName: string
    ): Boolean;
    function UpdateMarkView(
      const AMarkID: TID;
      const ACategoryID: TID;
      const AVisible: Boolean;
      const AUseTransaction: Boolean
    ): Boolean;
    function SetMarksInCategoryVisibleSQL(
      const ACategoryID: TID;
      const AVisible: Boolean
    ): Boolean;
    function GetMarkRecArray(
      const ACategoryId: TID;
      const AIncludeHiddenMarks: Boolean;
      const AIncludeGeometry: Boolean;
      const AIncludeAppearance: Boolean;
      out AMarkRecArray: TSQLMarkRecDynArray
    ): Integer;
    function GetMarkRecArrayByRect(
      const ACategoryIDArray: TDynArray;
      const ARect: TDoubleRect;
      const AIncludeHiddenMarks: Boolean;
      const ALonLatSize: TDoublePoint;
      out AMarkRecArray: TSQLMarkRecDynArray
    ): Integer;
    function GetMarkRecArrayByText(
      const ASearchText: string;
      const AMaxCount: Integer;
      const AIncludeHiddenMarks: Boolean;
      const ASearchInDescription: Boolean;
      out AMarkRecArray: TSQLMarkRecDynArray
    ): Integer;
  public
    constructor Create(
      const AIsReadOnly: Boolean;
      const ACacheSizeMb: Cardinal;
      const AGeometryWriter: IGeometryToStream;
      const AGeometryReader: IGeometryFromStream;
      const AClientProvider: IMarkSystemImplORMClientProvider
    );
    destructor Destroy; override;
  public
    property IsReadOnly: Boolean read FIsReadOnly write FIsReadOnly;
  end;

implementation

uses
  Math,
  u_MarkSystemORMTools;

const
  cSQLMarkTableClass: array[TMarkSystemImplORMClientType] of TSQLMarkClass = (
    TSQLMark, TSQLMarkMongoDB, TSQLMarkDBMS, TSQLMarkDBMS);

  cSQLMarkTableName: array[TMarkSystemImplORMClientType] of RawUTF8 = (
    'Mark', 'MarkMongoDB', 'MarkDBMS', 'MarkDBMS');

{ TMarkDbImplORMHelper }

constructor TMarkDbImplORMHelper.Create(
  const AIsReadOnly: Boolean;
  const ACacheSizeMb: Cardinal;
  const AGeometryWriter: IGeometryToStream;
  const AGeometryReader: IGeometryFromStream;
  const AClientProvider: IMarkSystemImplORMClientProvider
);
begin
  Assert(AGeometryWriter <> nil);
  Assert(AGeometryReader <> nil);
  inherited Create;
  FIsReadOnly := AIsReadOnly;
  if ACacheSizeMb > 0 then begin
    FCache.Init(ACacheSizeMb*1024*1024);
  end else begin
    FCache.Init(1024*1024*1024); // 1 Gb
  end;
  FGeometryWriter := AGeometryWriter;
  FGeometryReader := AGeometryReader;
  FClientProvider := AClientProvider;
  FUserID := FClientProvider.UserID;
  FClient := FClientProvider.RestClient;
  FClientType := FClientProvider.RestClientType;
  FSQLMarkClass := cSQLMarkTableClass[FClientType];
  FSQLMarkName := cSQLMarkTableName[FClientType];
end;

destructor TMarkDbImplORMHelper.Destroy;
begin
  FClientProvider := nil;
  FCache.Done;
  inherited Destroy;
end;

function TMarkDbImplORMHelper._GeomertryFromBlob(
  const ABlob: TSQLRawBlob
): IGeometryLonLat;
var
  VStream: TRawByteStringStream;
begin
  Assert(ABlob <> '');
  VStream := TRawByteStringStream.Create(ABlob);
  try
    Result := FGeometryReader.Parse(VStream);
  finally
    VStream.Free;
  end;
end;

function TMarkDbImplORMHelper._GeomertryToBlob(
  const AGeometry: IGeometryLonLat
): TSQLRawBlob;
var
  VStream: TRawByteStringStream;
begin
  Assert(AGeometry <> nil);
  VStream := TRawByteStringStream.Create;
  try
    FGeometryWriter.Save(AGeometry, VStream);
    Result := VStream.DataString;
  finally
    VStream.Free;
  end;
end;

function TMarkDbImplORMHelper._AddMarkImage(const APicName: string): TID;
var
  VPicName: RawUTF8;
  VItem: PSQLMarkImageRow;
  VSQLMarkImage: TSQLMarkImage;
begin
  {$IF CompilerVersion < 33}
  Result := 0; // prevent compiler warning
  {$IFEND}
  if FCache.FMarkImage.Find(APicName, VItem) then begin
    // found in cache
    Result := VItem.ImageId;
  end else begin
    VPicName := StringToUTF8(APicName);
    VSQLMarkImage := TSQLMarkImage.Create(FClient, 'miName=?', [VPicName]);
    try
      if VSQLMarkImage.ID = 0 then begin
        VSQLMarkImage.FName := VPicName;
        // add to db
        CheckID( FClient.Add(VSQLMarkImage, True) );
      end;
      Result := VSQLMarkImage.ID;
      // add to cache
      FCache.FMarkImage.AddOrIgnore(Result, APicName);
    finally
      VSQLMarkImage.Free;
    end;
  end;
end;

procedure TMarkDbImplORMHelper._ReadMarkImage(var AMarkRec: TSQLMarkRec);
var
  VItem: PSQLMarkImageRow;
  VSQLMarkImage: TSQLMarkImage;
begin
  if AMarkRec.FGeoType = gtPoint then begin
    if AMarkRec.FPicId > 0 then begin
      if FCache.FMarkImage.Find(AMarkRec.FPicId, VItem) then begin
        // found in cache
        AMarkRec.FPicName := VItem.Name;
      end else begin
        // read from db
        VSQLMarkImage := TSQLMarkImage.Create(FClient, AMarkRec.FPicId);
        try
          CheckID(VSQLMarkImage.ID);
          AMarkRec.FPicName := UTF8ToString(VSQLMarkImage.FName);
          // add to cache
          FCache.FMarkImage.AddOrIgnore(AMarkRec);
        finally
          VSQLMarkImage.Free;
        end;
      end;
    end else begin
      AMarkRec.FPicName := '';
    end;
  end;
end;

function TMarkDbImplORMHelper._AddMarkAppearance(
  const AColor1, AColor2: Cardinal;
  const AScale1, AScale2: Integer
): TID;
var
  VItem: PSQLMarkAppearanceRow;
  VSQLMarkAppearance: TSQLMarkAppearance;
begin
  {$IF CompilerVersion < 33}
  Result := 0; // prevent compiler warning
  {$IFEND}
  if FCache.FMarkAppearance.Find(AColor1, AColor2, AScale1, AScale2, VItem) then begin
    // found in cache
    Result := VItem.AppearanceId;
  end else begin
    VSQLMarkAppearance := TSQLMarkAppearance.Create(
      FClient, 'maColor1=? AND maColor2=? AND maScale1=? AND maScale2=?',
      [Int64(AColor1), Int64(AColor2), AScale1, AScale2]
    );
    try
      if VSQLMarkAppearance.ID = 0 then begin
        VSQLMarkAppearance.FColor1 := AColor1;
        VSQLMarkAppearance.FColor2 := AColor2;
        VSQLMarkAppearance.FScale1 := AScale1;
        VSQLMarkAppearance.FScale2 := AScale2;
        // add to db
        CheckID( FClient.Add(VSQLMarkAppearance, True) );
      end;
      Result := VSQLMarkAppearance.ID;
      // add to cache
      FCache.FMarkAppearance.AddOrIgnore(Result, AColor1, AColor2, AScale1, AScale2);
    finally
      VSQLMarkAppearance.Free;
    end;
  end;
end;

procedure TMarkDbImplORMHelper._ReadMarkAppearance(var AMarkRec: TSQLMarkRec);
var
  VItem: PSQLMarkAppearanceRow;
  VSQLMarkAppearance: TSQLMarkAppearance;
begin
  if FCache.FMarkAppearance.Find(AMarkRec.FAppearanceId, VItem) then begin
    // found in cache
    AMarkRec.FColor1 := VItem.Color1;
    AMarkRec.FColor2 := VItem.Color2;
    AMarkRec.FScale1 := VItem.Scale1;
    AMarkRec.FScale2 := VItem.Scale2;
  end else begin
    // read from db
    VSQLMarkAppearance := TSQLMarkAppearance.Create(FClient, AMarkRec.FAppearanceId);
    try
      CheckID(VSQLMarkAppearance.ID);
      AMarkRec.FColor1 := VSQLMarkAppearance.FColor1;
      AMarkRec.FColor2 := VSQLMarkAppearance.FColor2;
      AMarkRec.FScale1 := VSQLMarkAppearance.FScale1;
      AMarkRec.FScale2 := VSQLMarkAppearance.FScale2;
      // add to cache
      FCache.FMarkAppearance.AddOrIgnore(AMarkRec);
    finally
      VSQLMarkAppearance.Free;
    end;
  end;
end;

function TMarkDbImplORMHelper.DeleteMarkSQL(const AMarkID: TID): Boolean;
var
  VTransaction: TTransactionRec;
  VIndex: PSQLMarkIdIndexRec;
begin
  Result := False;

  if FIsReadOnly then begin
    Exit;
  end;

  if not (AMarkID > 0) then begin
    Assert(False);
    Exit;
  end;

  StartTransaction(FClient, VTransaction, FSQLMarkClass);
  try
    // delete view for all Users if exists
    FClient.Delete(TSQLMarkView, FormatUTF8('mvMark=?', [], [AMarkID]));

    // delete rect
    if FClientType = ctSQLite3 then begin
      CheckDeleteResult( FClient.Delete(TSQLMarkRTree, AMarkID) );
    end;

    // delete name and desc
    CheckDeleteResult( FClient.Delete(TSQLMarkFTS, AMarkID) );

    // delete mark
    CheckDeleteResult( FClient.Delete(FSQLMarkClass, AMarkID) );

    // pic name and appearance are never deleted...

    CommitTransaction(FClient, VTransaction);
  except
    RollBackTransaction(FClient, VTransaction);
    raise;
  end;

  // delete from cache
  FCache.FMarkCache.Delete(AMarkID);
  FCache.FMarkGeometryCache.Delete(AMarkID);
  FCache.FMarkViewCache.Delete(AMarkID);
  if FCache.FMarkIdIndex.Find(AMarkID, VIndex) then begin
    FCache.FMarkIdIndex.Delete(AMarkID);
    FCache.FMarkIdByCategoryIndex.Delete(VIndex.CategoryId, AMarkID);
  end;

  Result := True;
end;

function TMarkDbImplORMHelper.InsertMarkSQL(var AMarkRec: TSQLMarkRec): Boolean;
var
  VRect: TDoubleRect;
  VIntRect: TRect;
  VGeometryBlob: TSQLRawBlob;
  VSQLMark: TSQLMark;
  VSQLMarkDBMS: TSQLMarkDBMS;
  VSQLMarkView: TSQLMarkView;
  VSQLMarkFTS: TSQLMarkFTS;
  VSQLMarkRTree: TSQLMarkRTree;
  VTransaction: TTransactionRec;
begin
  Result := False;

  if FIsReadOnly then begin
    Exit;
  end;

  AMarkRec.FMarkId := 0;

  VRect := AMarkRec.FGeometry.Bounds.Rect;
  VGeometryBlob := _GeomertryToBlob(AMarkRec.FGeometry);
  CalcGeometrySize(VRect, AMarkRec.FGeoLonSize, AMarkRec.FGeoLatSize);

  StartTransaction(FClient, VTransaction, FSQLMarkClass);
  try
    if AMarkRec.FPicName <> '' then begin
      AMarkRec.FPicId := _AddMarkImage(AMarkRec.FPicName);
    end else begin
      AMarkRec.FPicId := 0;
    end;

    AMarkRec.FAppearanceId := _AddMarkAppearance(
      AMarkRec.FColor1, AMarkRec.FColor2,
      AMarkRec.FScale1, AMarkRec.FScale2
    );

    VSQLMark := FSQLMarkClass.Create;
    try
      VSQLMark.FCategory := AMarkRec.FCategoryId;
      VSQLMark.FImage := AMarkRec.FPicId;
      VSQLMark.FAppearance := AMarkRec.FAppearanceId;

      VSQLMark.FName := StringToUTF8(AMarkRec.FName);
      VSQLMark.FDesc := StringToUTF8(AMarkRec.FDesc);

      VSQLMark.FGeoLonSize := AMarkRec.FGeoLonSize;
      VSQLMark.FGeoLatSize := AMarkRec.FGeoLatSize;
      VSQLMark.FGeoType := AMarkRec.FGeoType;
      VSQLMark.FGeoCount := AMarkRec.FGeoCount;

      if FClientType in [ctMongoDB, ctZDBC, ctODBC] then begin
        LonLatDoubleRectToRect(VRect, VIntRect);
        VSQLMarkDBMS := VSQLMark as TSQLMarkDBMS;
        VSQLMarkDBMS.FLeft := VIntRect.Left;
        VSQLMarkDBMS.FRight := VIntRect.Right;
        VSQLMarkDBMS.FTop := VIntRect.Top;
        VSQLMarkDBMS.FBottom := VIntRect.Bottom;
      end;

      // add mark to db
      CheckID( FClient.Add(VSQLMark, True) );
      AMarkRec.FMarkId := VSQLMark.ID;
      // add geometry blob to db
      CheckUpdateResult( FClient.UpdateBlob(FSQLMarkClass, AMarkRec.FMarkId, 'mGeoWKB', VGeometryBlob) );
      // add to cache
      FCache.FMarkCache.AddOrUpdate(AMarkRec);
      FCache.FMarkGeometryCache.AddOrUpdate(AMarkRec.FMarkId, Length(VGeometryBlob), AMarkRec.FGeometry);
      FCache.FMarkIdIndex.AddOrUpdate(AMarkRec);
      FCache.FMarkIdByCategoryIndex.Add(AMarkRec.FCategoryId, AMarkRec.FMarkId);
    finally
      VSQLMark.Free;
    end;

    VSQLMarkFTS := TSQLMarkFTS.Create;
    try
      VSQLMarkFTS.DocID := AMarkRec.FMarkId;
      VSQLMarkFTS.FName := StringToUTF8(SysUtils.AnsiLowerCase(AMarkRec.FName));
      VSQLMarkFTS.FDesc := StringToUTF8(SysUtils.AnsiLowerCase(AMarkRec.FDesc));
      // add name and desc to db (fts index)
      CheckID( FClient.Add(VSQLMarkFTS, True, True) );
      Assert(VSQLMarkFTS.ID = AMarkRec.FMarkId);
    finally
      VSQLMarkFTS.Free;
    end;

    if FClientType = ctSQLite3 then begin
      VSQLMarkRTree := TSQLMarkRTree.Create;
      try
        VSQLMarkRTree.IDValue := AMarkRec.FMarkId;
        VSQLMarkRTree.FLeft := VRect.Left;
        VSQLMarkRTree.FRight := VRect.Right;
        VSQLMarkRTree.FTop := VRect.Top;
        VSQLMarkRTree.FBottom := VRect.Bottom;
        // add rect to db (rtree index)
        CheckID( FClient.Add(VSQLMarkRTree, True, True) );
        Assert(VSQLMarkRTree.ID = AMarkRec.FMarkId);
      finally
        VSQLMarkRTree.Free;
      end;
    end;

    if not AMarkRec.FVisible then begin
      VSQLMarkView := TSQLMarkView.Create;
      try
        VSQLMarkView.FUser := FUserID;
        VSQLMarkView.FMark := AMarkRec.FMarkId;
        VSQLMarkView.FCategory := AMarkRec.FCategoryId;
        VSQLMarkView.FVisible := AMarkRec.FVisible;
        // add view to db
        CheckID( FClient.Add(VSQLMarkView, True) );
        AMarkRec.FViewId := VSQLMarkView.ID;
      finally
        VSQLMarkView.Free;
      end;
    end;
    // add view to cache
    FCache.FMarkViewCache.AddOrUpdate(AMarkRec);

    CommitTransaction(FClient, VTransaction);
  except
    RollBackTransaction(FClient, VTransaction);
    raise;
  end;

  Result := (AMarkRec.FMarkId > 0);
end;

function TMarkDbImplORMHelper.UpdateMarkSQL(
  const AOldMarkRec: TSQLMarkRec;
  var ANewMarkRec: TSQLMarkRec
): Boolean;
var
  VRect: TDoubleRect;
  VIntRect: TRect;
  VGeometryBlob: TSQLRawBlob;
  VSQLMark: TSQLMark;
  VSQLMarkDBMS: TSQLMarkDBMS;
  VSQLMarkFTS: TSQLMarkFTS;
  VSQLMarkRTree: TSQLMarkRTree;
  VTransaction: TTransactionRec;
  VUpdatePic: Boolean;
  VUpdateGeo: Boolean;
  VUpdateName: Boolean;
  VUpdateDesc: Boolean;
  VUpdateCategory: Boolean;
  VUpdateAppearance: Boolean;
  VUpdateIdIndex: Boolean;
  VFieldsBuilder: TCSVFieldsBuilder;
begin
  Result := False;

  CheckID(AOldMarkRec.FMarkId);

  ANewMarkRec.FMarkId := AOldMarkRec.FMarkId;

  if FIsReadOnly then begin
    if AOldMarkRec.FVisible <> ANewMarkRec.FVisible then begin
      // update view
      Result := UpdateMarkView(ANewMarkRec.FMarkId, ANewMarkRec.FCategoryId, ANewMarkRec.FVisible, False);
    end;
    Exit;
  end;

  VUpdatePic := (AOldMarkRec.FPicName <> ANewMarkRec.FPicName);
  VUpdateGeo := not ANewMarkRec.FGeometry.IsSameGeometry(AOldMarkRec.FGeometry);
  VUpdateName := (AOldMarkRec.FName <> ANewMarkRec.FName);
  VUpdateDesc := (AOldMarkRec.FDesc <> ANewMarkRec.FDesc);
  VUpdateCategory := (AOldMarkRec.FCategoryId <> ANewMarkRec.FCategoryId);

  VUpdateAppearance :=
    (AOldMarkRec.FColor1 <> ANewMarkRec.FColor1) or
    (AOldMarkRec.FColor2 <> ANewMarkRec.FColor2) or
    (AOldMarkRec.FScale1 <> ANewMarkRec.FScale1) or
    (AOldMarkRec.FScale2 <> ANewMarkRec.FScale2);

  VUpdateIdIndex := VUpdateAppearance or VUpdatePic or VUpdateCategory;

  if VUpdateGeo then begin
    VRect := ANewMarkRec.FGeometry.Bounds.Rect;
    VGeometryBlob := _GeomertryToBlob(ANewMarkRec.FGeometry);
    CalcGeometrySize(VRect, ANewMarkRec.FGeoLonSize, ANewMarkRec.FGeoLatSize);
  end;

  StartTransaction(FClient, VTransaction, FSQLMarkClass);
  try
    if VUpdateIdIndex then begin
      if ANewMarkRec.FPicName <> '' then begin
        ANewMarkRec.FPicId := _AddMarkImage(ANewMarkRec.FPicName);
      end else begin
        ANewMarkRec.FPicId := 0;
      end;

      ANewMarkRec.FAppearanceId := _AddMarkAppearance(
        ANewMarkRec.FColor1, ANewMarkRec.FColor2,
        ANewMarkRec.FScale1, ANewMarkRec.FScale2
      );
    end;

    VSQLMark := FSQLMarkClass.Create;
    try
      VFieldsBuilder.Clear;

      VSQLMark.IDValue := ANewMarkRec.FMarkId;

      if VUpdateCategory then begin
        VFieldsBuilder.Add('mCategory');
        VSQLMark.FCategory := ANewMarkRec.FCategoryId;
      end;
      if VUpdatePic then begin
        VFieldsBuilder.Add('mImage');
        VSQLMark.FImage := ANewMarkRec.FPicId;
      end;
      if VUpdateAppearance then begin
        VFieldsBuilder.Add('mAppearance');
        VSQLMark.FAppearance := ANewMarkRec.FAppearanceId;
      end;
      if VUpdateName then begin
        VFieldsBuilder.Add('mName');
        VSQLMark.FName := StringToUTF8(ANewMarkRec.FName);
      end;
      if VUpdateDesc then begin
        VFieldsBuilder.Add('mDesc');
        VSQLMark.FDesc := StringToUTF8(ANewMarkRec.FDesc);
      end;

      if VUpdateGeo then begin
        VFieldsBuilder.Add('mGeoLonSize');
        VFieldsBuilder.Add('mGeoLatSize');
        VFieldsBuilder.Add('mGeoType');
        VFieldsBuilder.Add('mGeoCount');
        VSQLMark.FGeoLonSize := ANewMarkRec.FGeoLonSize;
        VSQLMark.FGeoLatSize := ANewMarkRec.FGeoLatSize;
        VSQLMark.FGeoType := ANewMarkRec.FGeoType;
        VSQLMark.FGeoCount := ANewMarkRec.FGeoCount;
        if FClientType in [ctMongoDB, ctZDBC, ctODBC] then begin
          VFieldsBuilder.Add('mLeft');
          VFieldsBuilder.Add('mRight');
          VFieldsBuilder.Add('mTop');
          VFieldsBuilder.Add('mBottom');
          LonLatDoubleRectToRect(VRect, VIntRect);
          VSQLMarkDBMS := VSQLMark as TSQLMarkDBMS;
          VSQLMarkDBMS.FLeft := VIntRect.Left;
          VSQLMarkDBMS.FRight := VIntRect.Right;
          VSQLMarkDBMS.FTop := VIntRect.Top;
          VSQLMarkDBMS.FBottom := VIntRect.Bottom;
        end;
      end;

      if VFieldsBuilder.Count > 0 then begin
        // update mark
        CheckUpdateResult( FClient.Update(VSQLMark, VFieldsBuilder.Build) );
        // update cache
        if VUpdateName or VUpdateDesc or VUpdateGeo then begin
          FCache.FMarkCache.AddOrUpdate(ANewMarkRec);
        end;
        if VUpdateIdIndex then begin
          FCache.FMarkIdIndex.AddOrUpdate(ANewMarkRec);
          if VUpdateCategory then begin
            FCache.FMarkIdByCategoryIndex.Delete(AOldMarkRec.FCategoryId, ANewMarkRec.FMarkId);
            FCache.FMarkIdByCategoryIndex.Add(ANewMarkRec.FCategoryId, ANewMarkRec.FMarkId);
          end;
        end;
        Result := True;
      end;

      if VUpdateGeo then begin
        // update geometry blob
        CheckUpdateResult(
          FClient.UpdateBlob(FSQLMarkClass, VSQLMark.ID, 'mGeoWKB', VGeometryBlob)
        );
        // update cache
        FCache.FMarkGeometryCache.AddOrUpdate(
          ANewMarkRec.FMarkId, Length(VGeometryBlob), ANewMarkRec.FGeometry
        );
        Result := True;
      end;
    finally
      VSQLMark.Free;
    end;

    VSQLMarkFTS := TSQLMarkFTS.Create;
    try
      VFieldsBuilder.Clear;

      VSQLMarkFTS.DocID := ANewMarkRec.FMarkId;

      if VUpdateName then begin
        VFieldsBuilder.Add('mName');
        VSQLMarkFTS.FName := StringToUTF8(SysUtils.AnsiLowerCase(ANewMarkRec.FName));
      end;
      if VUpdateDesc then begin
        VFieldsBuilder.Add('mDesc');
        VSQLMarkFTS.FDesc := StringToUTF8(SysUtils.AnsiLowerCase(ANewMarkRec.FDesc));
      end;

      if VFieldsBuilder.Count > 0 then begin
        // update name / desc (fts index)
        CheckUpdateResult( FClient.Update(VSQLMarkFTS, VFieldsBuilder.Build) );
      end;
    finally
      VSQLMarkFTS.Free;
    end;

    if VUpdateGeo and (FClientType = ctSQLite3) then begin
      VSQLMarkRTree := TSQLMarkRTree.Create;
      try
        VSQLMarkRTree.IDValue := ANewMarkRec.FMarkId;
        VSQLMarkRTree.FLeft := VRect.Left;
        VSQLMarkRTree.FRight := VRect.Right;
        VSQLMarkRTree.FTop := VRect.Top;
        VSQLMarkRTree.FBottom := VRect.Bottom;
        // update rect (rtree index)
        CheckUpdateResult( FClient.Update(VSQLMarkRTree) );
      finally
        VSQLMarkRTree.Free;
      end;
    end;

    if (AOldMarkRec.FVisible <> ANewMarkRec.FVisible) or VUpdateCategory then begin
      // update view
      if UpdateMarkView(ANewMarkRec.FMarkId, ANewMarkRec.FCategoryId, ANewMarkRec.FVisible, False) then begin
        Result := True;
      end;
    end;

    CommitTransaction(FClient, VTransaction);
  except
    RollBackTransaction(FClient, VTransaction);
    raise;
  end;
end;

function TMarkDbImplORMHelper.ReadMarkSQL(
  out AMarkRec: TSQLMarkRec;
  const AMarkID: TID;
  const ACategoryID: TID;
  const AMarkName: string
): Boolean;
var
  VMarkID: TID;
  VSQLWhere: RawUTF8;
  VFieldsCSV: RawUTF8;
  VSQLMark: TSQLMark;
  VSQLMarkView: TSQLMarkView;
  VSQLBlobData: TSQLRawBlob;
  VIndexItem: PSQLMarkIdIndexRec;
  VCacheItem: PSQLMarkRow;
  VViewItem: PSQLMarkViewRow;
  VGeometry: IGeometryLonLat;
begin
  Assert( (AMarkID > 0) or (AMarkName <> '') );

  Result := False;

  AMarkRec := cEmptySQLMarkRec;

  VSQLMark := FSQLMarkClass.Create;
  try
    VSQLWhere := '';
    if AMarkID > 0 then begin
      VMarkID := AMarkID;
      if FCache.FMarkIdIndex.Find(VMarkID, VIndexItem) then begin
        // fill id's from cache
        AMarkRec.FMarkId := VMarkID;
        AMarkRec.FCategoryId := VIndexItem.CategoryId;
        AMarkRec.FPicId := VIndexItem.ImageId;
        AMarkRec.FAppearanceId := VIndexItem.AppearanceId;
        if not FCache.FMarkCache.Find(VIndexItem.MarkId, VCacheItem) then begin
          // get main params from db
          VFieldsCSV := 'mName,mDesc,mGeoType,mGeoCount';
          VSQLWhere := FormatUTF8('RowID=?', [], [VMarkID]);
          if FClient.Retrieve(VSQLWhere, VSQLMark, VFieldsCSV) then begin
            // fill main params from db
            AMarkRec.FName := UTF8ToString(VSQLMark.FName);
            AMarkRec.FDesc := UTF8ToString(VSQLMark.FDesc);
            AMarkRec.FGeoType := VSQLMark.FGeoType;
            AMarkRec.FGeoCount := VSQLMark.FGeoCount;
            // add to cache
            FCache.FMarkCache.AddOrUpdate(AMarkRec);
            VSQLWhere := '';
          end else begin
            DeleteMarkSQL(VMarkID);
            Exit;
          end;
        end else begin
          // fill main params from cache
          AMarkRec.FName := VCacheItem.Name;
          AMarkRec.FDesc := VCacheItem.Desc;
          AMarkRec.FGeoType := VCacheItem.GeoType;
          AMarkRec.FGeoCount := VCacheItem.GeoCount;
        end;
      end else begin
        VSQLWhere := FormatUTF8('RowID=?', [], [VMarkID]);
      end;
    end else if AMarkName <> '' then begin
      if ACategoryID > 0 then begin
        VSQLWhere := FormatUTF8('mName=? AND mCategory=?', [], [AMarkName, ACategoryID]);
      end else begin
        VSQLWhere := FormatUTF8('mName=?', [], [AMarkName]);
      end;
    end else begin
      Exit;
    end;
    if VSQLWhere <> '' then begin
      // get all from db
      VFieldsCSV := 'RowID,mCategory,mImage,mAppearance,mName,mDesc,mGeoType,mGeoCount';
      if FClient.Retrieve(VSQLWhere, VSQLMark, VFieldsCSV) then begin
        // fill id's from db
        VMarkID := VSQLMark.ID;
        AMarkRec.FMarkId := VMarkID;
        AMarkRec.FCategoryId := VSQLMark.FCategory;
        CheckID(AMarkRec.FCategoryId);
        AMarkRec.FPicId := VSQLMark.FImage; // = 0 is OK
        AMarkRec.FAppearanceId := VSQLMark.FAppearance;
        CheckID(AMarkRec.FAppearanceId);
        // fill main params from db
        AMarkRec.FName := UTF8ToString(VSQLMark.FName);
        AMarkRec.FDesc := UTF8ToString(VSQLMark.FDesc);
        AMarkRec.FGeoType := VSQLMark.FGeoType;
        AMarkRec.FGeoCount := VSQLMark.FGeoCount;
        // add to cache
        FCache.FMarkCache.AddOrUpdate(AMarkRec);
        FCache.FMarkIdIndex.AddOrUpdate(AMarkRec);
        FCache.FMarkIdByCategoryIndex.Add(AMarkRec.FCategoryId, AMarkRec.FMarkId);
      end else begin
        Exit;
      end;
    end;
  finally
    VSQLMark.Free;
  end;

  VMarkID := AMarkRec.FMarkId;

  // read geometry blob
  if FCache.FMarkGeometryCache.Find(VMarkID, VGeometry) then begin
    // found in cache
    AMarkRec.FGeometry := VGeometry;
  end else begin
    // read from db
    CheckRetrieveResult( FClient.RetrieveBlob(FSQLMarkClass, VMarkID, 'mGeoWKB', VSQLBlobData) );
    AMarkRec.FGeometry := _GeomertryFromBlob(VSQLBlobData);
    // add to cache
    FCache.FMarkGeometryCache.AddOrUpdate(VMarkID, Length(VSQLBlobData), AMarkRec.FGeometry);
  end;

  // read view
  if FCache.FMarkViewCache.Find(VMarkID, VViewItem) then begin
    // found in cache
    AMarkRec.FViewId := VViewItem.ViewId;
    AMarkRec.FVisible := VViewItem.Visible;
  end else begin
    if not FCache.FMarkViewCache.IsPrepared then begin
      // read from db
      VSQLMarkView := TSQLMarkView.Create(FClient, 'mvMark=? AND mvUser=?', [VMarkID, FUserID]);
      try
        if VSQLMarkView.ID > 0 then begin
          AMarkRec.FViewId := VSQLMarkView.ID;
          AMarkRec.FVisible := VSQLMarkView.FVisible;
        end else begin
          AMarkRec.FVisible := True;
        end;
      finally
        VSQLMarkView.Free;
      end;
    end;
    // add to cache
    FCache.FMarkViewCache.AddOrUpdate(AMarkRec);
  end;

  // read pic name
  _ReadMarkImage(AMarkRec);

  // read appearance
  _ReadMarkAppearance(AMarkRec);

  Result := True;
end;

function TMarkDbImplORMHelper.UpdateMarkView(
  const AMarkID: TID;
  const ACategoryID: TID;
  const AVisible: Boolean;
  const AUseTransaction: Boolean
): Boolean;
var
  VFind: Boolean;
  VItem: PSQLMarkViewRow;
  VCategory: TID;
  VUpdateCache: Boolean;
  VSQLWhere: RawUTF8;
  VSQLMarkView: TSQLMarkView;
  VTransaction: TTransactionRec;
  VFieldsBuilder: TCSVFieldsBuilder;
begin
  Assert(AMarkID > 0);

  Result := False;

  if AUseTransaction then begin
    StartTransaction(FClient, VTransaction, TSQLMarkView);
  end;
  try
    VSQLMarkView := TSQLMarkView.Create;
    try
      VUpdateCache := True;
      VFind := FCache.FMarkViewCache.Find(AMarkID, VItem);
      if VFind then begin
        VSQLMarkView.IDValue := VItem.ViewId;
        VSQLMarkView.FUser := FUserID;
        VSQLMarkView.FMark := VItem.MarkId;
        VSQLMarkView.FCategory := VItem.CategoryID;
        VSQLMarkView.FVisible := VItem.Visible;
        VUpdateCache := (VItem.CategoryID <> ACategoryID) or (VItem.Visible <> AVisible);
      end else if not (FCache.FMarkViewCache.IsPrepared or FCache.FMarkViewCache.IsCategoryPrepared(ACategoryID)) then begin
        VSQLWhere := FormatUTF8('mvMark=? AND mvUser=?', [], [AMarkID, FUserID]);
        VFind := FClient.Retrieve(VSQLWhere, VSQLMarkView, 'RowID,mvCategory,mvVisible');
      end;
      if not FIsReadOnly then begin
        if VFind and (VSQLMarkView.ID > 0) then begin
          VFieldsBuilder.Clear;
          if VSQLMarkView.FVisible <> AVisible then begin
            VFieldsBuilder.Add('mvVisible');
            VSQLMarkView.FVisible := AVisible;
          end;
          VCategory := VSQLMarkView.FCategory;
          CheckID(VCategory);
          if (ACategoryID > 0) and (VCategory <> ACategoryID) then begin
            VFieldsBuilder.Add('mvCategory');
            VSQLMarkView.FCategory := ACategoryID;
          end;
          if VFieldsBuilder.Count > 0 then begin
            // update db
            Result := FClient.Update(VSQLMarkView, VFieldsBuilder.Build);
            CheckUpdateResult(Result);
          end;
        end else if not AVisible then begin
          VSQLMarkView.FUser := FUserID;
          VSQLMarkView.FMark := AMarkID;
          VSQLMarkView.FCategory := ACategoryID;
          VSQLMarkView.FVisible := AVisible;
          // add to db
          CheckID( FClient.Add(VSQLMarkView, True) );
          Result := True;
        end;
      end else begin
        Result := True;
      end;
      if VUpdateCache then begin
        // update cache
        FCache.FMarkViewCache.AddOrUpdate(AMarkID, VSQLMarkView.ID, ACategoryID, AVisible);
      end;
    finally
      VSQLMarkView.Free;
    end;
    if AUseTransaction then begin
      CommitTransaction(FClient, VTransaction);
    end;
  except
    if AUseTransaction then begin
      RollBackTransaction(FClient, VTransaction);
    end;
    raise;
  end;
end;

function TMarkDbImplORMHelper.SetMarksInCategoryVisibleSQL(
  const ACategoryID: TID;
  const AVisible: Boolean
): Boolean;
var
  I: Integer;
  VCount: Integer;
  VArray: TIDDynArray;
  VTransaction: TTransactionRec;
begin
  Result := False;
  CheckID(ACategoryID);
  if _FillPrepareMarkIdIndex(ACategoryID) > 0 then begin
    _FillPrepareMarkViewCache(ACategoryID);
    if FCache.FMarkIdByCategoryIndex.Find(ACategoryID, VArray, VCount) then begin
      StartTransaction(FClient, VTransaction, TSQLMarkView);
      try
        // ToDo: 'UPDATE MarkView SET mvVisible=? WHERE mvCategory=? AND mvUser=?'
        for I := 0 to VCount - 1 do begin
          UpdateMarkView(VArray[I], ACategoryID, AVisible, False);
        end;
        CommitTransaction(FClient, VTransaction);
        Result := True;
      except
        RollBackTransaction(FClient, VTransaction);
        raise;
      end;
    end else begin
      Assert(False);
    end;
  end;
end;

function TMarkDbImplORMHelper._FillPrepareMarkIdIndex(const ACategoryID: TID): Integer;
var
  {$IFDEF DEBUG}
  Z: Integer;
  {$ENDIF}
  I, J, K: Integer;
  VCount: Integer;
  VList: TSQLTableJSON;
  VByCategory: Boolean;
  VArray: TIDDynArray;
  VMarkIdArray: TIDDynArray;
  VMarkIdRows: TSQLMarkIdIndexRecDynArray;
  VCategory: TID;
  VCurrCategory: TID;
begin
  Result := 0;

  VByCategory := ACategoryID > 0;

  if VByCategory then begin
    if FCache.FMarkIdByCategoryIndex.Find(ACategoryID, VArray, VCount) then begin
      Result := VCount;
      Exit;
    end;
    VList := FClient.ExecuteList(
      [FSQLMarkClass],
      FormatUTF8(
        'SELECT RowID,mImage,mAppearance FROM % WHERE mCategory=?',
        [FSQLMarkName], [ACategoryID]
      )
    );
  end else begin
    if FCache.FMarkIdIndex.IsPrepared then begin
      Result := FCache.FMarkIdIndex.Count;
      Exit;
    end;
    VList := FClient.ExecuteList(
      [FSQLMarkClass],
      FormatUTF8(
        'SELECT RowID,mImage,mAppearance,mCategory FROM % ORDER BY mCategory',
        [FSQLMarkName], []
      )
    );
  end;
  if Assigned(VList) then
  try
    VCount := VList.RowCount;
    SetLength(VMarkIdArray, VCount);
    SetLength(VMarkIdRows, VCount);
    K := 0;
    VCurrCategory := 0;
    if not VByCategory then begin
      // Enshure that result is sorted by Category
      // (MongoDB 3.2 issue: http://www.sasgis.org/mantis/view.php?id=2970)
      VList.SortFields(3, True, nil, sftID);
    end;
    for I := 0 to VCount - 1 do begin
      J := I + 1;
      VMarkIdRows[I].MarkId := VList.GetAsInt64(J, 0);
      VMarkIdRows[I].ImageId := VList.GetAsInt64(J, 1);
      VMarkIdRows[I].AppearanceId := VList.GetAsInt64(J, 2);
      VMarkIdArray[I] := VMarkIdRows[I].MarkId;
      if VByCategory then begin
        VCategory := ACategoryID;
      end else begin
        VCategory := VList.GetAsInt64(J, 3);
        if VCurrCategory = 0 then begin
          VCurrCategory := VCategory;
        end;
        if VCurrCategory = VCategory then begin
          Inc(K);
        end else if VCurrCategory < VCategory then begin
          if K > 0 then begin
            {$IFDEF DEBUG}
            Assert(I-K >= 0);
            for Z := I - K to I - 1 do begin
              Assert(VMarkIdRows[Z].CategoryId = VCurrCategory);
            end;
            if I > K then begin
              Assert(VMarkIdRows[I-K-1].CategoryId < VCurrCategory);
            end;
            {$ENDIF}
            FCache.FMarkIdByCategoryIndex.AddPrepared(VCurrCategory, VMarkIdArray, I-K, K);
            K := 0;
          end;
          VCurrCategory := VCategory;
          Inc(K);
        end else begin
          Assert(False, 'List not ordered by Category!');
        end;
      end;
      VMarkIdRows[I].CategoryId := VCategory;
    end;
    if VByCategory then begin
      FCache.FMarkIdIndex.AddArray(VMarkIdRows);
      FCache.FMarkIdByCategoryIndex.AddPrepared(ACategoryID, VMarkIdArray, 0, VCount);
    end else begin
      FCache.FMarkIdIndex.AddPrepared(VMarkIdRows);
    end;
    Result := VCount;
  finally
    VList.Free;
  end;
end;

procedure TMarkDbImplORMHelper._FillPrepareMarkIdCache(const ACategoryID: TID);
var
  I, J: Integer;
  VCount: Integer;
  VList: TSQLTableJSON;
  VArray: TSQLMarkRowDynArray;
begin
  if ACategoryID > 0 then begin
    if FCache.FMarkCache.IsCategoryPrepared(ACategoryID) then begin
      Exit;
    end;
    VList := FClient.ExecuteList(
      [FSQLMarkClass],
      FormatUTF8(
        'SELECT RowID,mName,mDesc,mGeoType,mGeoCount FROM % WHERE mCategory=?',
        [FSQLMarkName], [ACategoryID]
      )
    );
  end else begin
    if FCache.FMarkCache.IsPrepared then begin
      Exit;
    end;
    VList := FClient.ExecuteList(
      [FSQLMarkClass],
      RawUTF8('SELECT RowID,mName,mDesc,mGeoType,mGeoCount FROM ') + FSQLMarkName
    );
  end;
  if Assigned(VList) then
  try
    VCount := VList.RowCount;
    SetLength(VArray, VCount);
    for I := 0 to VCount - 1 do begin
      J := I + 1;
      VArray[I].MarkId := VList.GetAsInt64(J, 0);
      VArray[I].Name := VList.GetString(J, 1);
      VArray[I].Desc := VList.GetString(J, 2);
      VArray[I].GeoType := TSQLGeoType(VList.GetAsInteger(J, 3));
      VArray[I].GeoCount := VList.GetAsInteger(J, 4);
    end;
    FCache.FMarkCache.AddPrepared(ACategoryID, VArray);
  finally
    VList.Free;
  end;
end;

procedure TMarkDbImplORMHelper._FillPrepareMarkGeometryCache(const ACategoryID: TID);
var
  I, J: Integer;
  VCount: Integer;
  VList: TSQLTableJSON;
  VArray: TSQLMarkGeometryRecDynArray;
  VBlob: TSQLRawBlob;
begin
  if ACategoryID > 0 then begin
    if FCache.FMarkGeometryCache.IsCategoryPrepared(ACategoryID) then begin
      Exit;
    end;
    VList := FClient.ExecuteList(
      [FSQLMarkClass],
      FormatUTF8('SELECT RowID,mGeoWKB FROM % WHERE mCategory=?', [FSQLMarkName], [ACategoryID])
    );
  end else begin
    if FCache.FMarkGeometryCache.IsPrepared then begin
      Exit;
    end;
    VList := FClient.ExecuteList(
      [FSQLMarkClass],
      RawUTF8('SELECT RowID,mGeoWKB FROM ') + FSQLMarkName
    );
  end;
  if Assigned(VList) then
  try
    VCount := VList.RowCount;
    SetLength(VArray, VCount);
    for I := 0 to VCount - 1 do begin
      J := I + 1;
      VArray[I].MarkId := VList.GetAsInt64(J, 0);
      VBlob := VList.GetBlob(J, 1);
      VArray[I].Geometry := _GeomertryFromBlob(VBlob);
      VArray[I].Size := Length(VBlob);
    end;
    FCache.FMarkGeometryCache.AddPrepared(ACategoryID, VArray);
  finally
    VList.Free;
  end;
end;

procedure TMarkDbImplORMHelper._FillPrepareMarkViewCache(const ACategoryID: TID);
var
  I, J: Integer;
  VCount: Integer;
  VList: TSQLTableJSON;
  VRows: TSQLMarkViewRowDynArray;
begin
  if ACategoryID > 0 then begin
    if FCache.FMarkViewCache.IsCategoryPrepared(ACategoryID) then begin
      Exit;
    end;
    VList := FClient.ExecuteList(
      [TSQLMarkView, FSQLMarkClass],
      FormatUTF8(
        'SELECT RowID,mvMark,mvVisible ' +
        'FROM MarkView ' +
        'WHERE mvCategory=? AND mvUser=?',
        [], [ACategoryID, FUserID]
      )
    );
  end else begin
    if FCache.FMarkViewCache.IsPrepared then begin
      Exit;
    end;
    VList := FClient.ExecuteList(
      [TSQLMarkView],
      FormatUTF8(
        'SELECT RowID,mvMark,mvVisible,mvCategory FROM MarkView WHERE mvUser=?',
        [], [FUserID]
      )
    );
  end;
  if Assigned(VList) then
  try
    VCount := VList.RowCount;
    SetLength(VRows, VCount);
    for I := 0 to VCount - 1 do begin
      J := I + 1;
      VRows[I].ViewId := VList.GetAsInt64(J, 0);
      VRows[I].MarkId := VList.GetAsInt64(J, 1);
      VRows[I].Visible := (VList.GetAsInteger(J, 2) <> 0);
      if ACategoryID > 0 then begin
        VRows[I].CategoryId := ACategoryID;
      end else begin
        VRows[I].CategoryId := VList.GetAsInt64(J, 3);
      end;
    end;
    FCache.FMarkViewCache.AddPrepared(ACategoryID, VRows);
  finally
    VList.Free;
  end;
end;

function TMarkDbImplORMHelper.GetMarkRecArray(
  const ACategoryId: TID;
  const AIncludeHiddenMarks: Boolean;
  const AIncludeGeometry: Boolean;
  const AIncludeAppearance: Boolean;
  out AMarkRecArray: TSQLMarkRecDynArray
): Integer;

  function FillMarkRec(var AMarkRec: TSQLMarkRec; const AIndexRec: PSQLMarkIdIndexRec): Boolean;
  var
    VCacheItem: PSQLMarkRow;
    VViewItem: PSQLMarkViewRow;
    VGeometry: IGeometryLonLat;
  begin
    Result := False;

    AMarkRec.FMarkId := AIndexRec.MarkId;
    AMarkRec.FCategoryId := AIndexRec.CategoryId;
    AMarkRec.FPicId := AIndexRec.ImageId;
    AMarkRec.FAppearanceId := AIndexRec.AppearanceId;

    if not FCache.FMarkCache.Find(AIndexRec.MarkId, VCacheItem) then begin
      Assert(False);
      Exit;
    end;

    AMarkRec.FName := VCacheItem.Name;
    AMarkRec.FDesc := VCacheItem.Desc;
    AMarkRec.FGeoType := VCacheItem.GeoType;
    AMarkRec.FGeoCount := VCacheItem.GeoCount;

    if FCache.FMarkViewCache.Find(AIndexRec.MarkId, VViewItem) then begin
      AMarkRec.FViewId := VViewItem.ViewId;
      AMarkRec.FVisible := VViewItem.Visible;
      if not AIncludeHiddenMarks then begin
        if not AMarkRec.FVisible then begin
          Exit;
        end;
      end;
    end;

    if AIncludeGeometry then begin
      if FCache.FMarkGeometryCache.Find(AIndexRec.MarkId, VGeometry) then begin
        AMarkRec.FGeometry := VGeometry;
      end else begin
        Assert(False);
        Exit;
      end;
    end;

    if AIncludeAppearance then begin
      _ReadMarkImage(AMarkRec);
      _ReadMarkAppearance(AMarkRec);
    end;

    Result := True;
  end;

var
  I, J: Integer;
  VCount: Integer;
  VIdCount: Integer;
  VRows: TSQLMarkIdIndexRecDynArray;
  VArray: TIDDynArray;
  VIndexRec: PSQLMarkIdIndexRec;
begin
  J := 0;

  VCount := _FillPrepareMarkIdIndex(ACategoryId);
  if VCount > 0 then begin
    _FillPrepareMarkIdCache(ACategoryId);
    _FillPrepareMarkViewCache(ACategoryId);
    if AIncludeGeometry then begin
      _FillPrepareMarkGeometryCache(ACategoryId);
    end;

    SetLength(AMarkRecArray, VCount);

    if ACategoryId > 0 then begin
      if FCache.FMarkIdByCategoryIndex.Find(ACategoryId, VArray, VIdCount) then begin
        Assert(VCount >= VIdCount);
        for I := 0 to VIdCount - 1 do begin
          if FCache.FMarkIdIndex.Find(VArray[I], VIndexRec) then begin
            AMarkRecArray[J] := cEmptySQLMarkRec;
            if FillMarkRec(AMarkRecArray[J], VIndexRec) then begin
              Inc(J);
            end;
          end;
        end;
      end else begin
        Assert(False);
      end;
    end else begin
      VRows := FCache.FMarkIdIndex.Rows;
      for I := 0 to FCache.FMarkIdIndex.Count - 1 do begin
        AMarkRecArray[J] := cEmptySQLMarkRec;
        if FillMarkRec(AMarkRecArray[J], @VRows[I]) then begin
          Inc(J);
        end;
      end;
    end;
    SetLength(AMarkRecArray, J);
  end;

  Result := J;
end;

function TMarkDbImplORMHelper._GetMarkIDArrayByRectSQL(
  const ACategoryIDArray: TIDDynArray;
  const ARect: TDoubleRect;
  const ALonSize: Cardinal;
  const ALatSize: Cardinal;
  const AReciveCategoryID: Boolean;
  out AIDArray: TMarkWithCategoryIDDynArray
): Integer;
var
  I: Integer;
  VLen: Integer;
  VSQLSelect: RawUTF8;
  VSelectedRows: RawUTF8;
  VCategoryWhere: RawUTF8;
  VList: TSQLTableJSON;
begin
  Result := 0;

  VLen := Length(ACategoryIDArray);

  if AReciveCategoryID then begin
    VSelectedRows := FormatUTF8('%.RowID,%.mCategory', [FSQLMarkName,FSQLMarkName], []);
  end else begin
    VSelectedRows := FormatUTF8('%.RowID', [FSQLMarkName], []);
  end;

  if VLen = 1 then begin
    if ACategoryIDArray[0] <= 0 then begin
      VCategoryWhere := '';
      Assert(False);
    end else begin
      VCategoryWhere := FormatUTF8('AND %.mCategory=? ',[FSQLMarkName],[ACategoryIDArray[0]]);
    end;
  end else if VLen > 1 then begin
    VCategoryWhere := Int64DynArrayToCSV(TInt64DynArray(ACategoryIDArray));
    VCategoryWhere := FormatUTF8('AND %.mCategory IN (%) ', [FSQLMarkName, VCategoryWhere]);
  end else begin
    VCategoryWhere := '';
  end;

  VSQLSelect :=
    FormatUTF8(
      'SELECT % FROM %,MarkRTree ' +
      'WHERE %.RowID=MarkRTree.RowID ' + VCategoryWhere +
      'AND mLeft<=? AND mRight>=? AND mBottom<=? AND mTop>=? ' +
      'AND (%.mGeoType=? OR %.mGeoLonSize>=? OR %.mGeoLatSize>=?);',
      [VSelectedRows,FSQLMarkName,FSQLMarkName,FSQLMarkName,FSQLMarkName,FSQLMarkName],
      [ARect.Right,ARect.Left,ARect.Top,ARect.Bottom,Integer(gtPoint),Int64(ALonSize),Int64(ALatSize)]
    );

  VList := FClient.ExecuteList([FSQLMarkClass, TSQLMarkRTree], VSQLSelect);
  if Assigned(VList) then
  try
    VLen := VList.RowCount;
    SetLength(AIDArray, VLen);
    for I := 0 to VLen - 1 do begin
      AIDArray[I].MarkID := VList.GetAsInt64(I+1, 0);
      if AReciveCategoryID then begin
        AIDArray[I].CategoryID := VList.GetAsInt64(I+1, 1);
      end;
    end;
    Result := VLen;
  finally
    VList.Free;
  end;
end;

{$IFDEF ENABLE_DBMS}
function TMarkDbImplORMHelper._GetMarkIDArrayByRectDBMS(
  const ACategoryIDArray: TIDDynArray;
  const ARect: TDoubleRect;
  const ALonSize: Cardinal;
  const ALatSize: Cardinal;
  const AReciveCategoryID: Boolean;
  out AIDArray: TMarkWithCategoryIDDynArray
): Integer;
var
  I: Integer;
  VLen: Integer;
  VIntRect: TRect;
  VSQLSelect: RawUTF8;
  VSelectedRows: RawUTF8;
  VCategoryWhere: RawUTF8;
  VList: TSQLTableJSON;
  VRows: ISQLDBRows;
  VJsonBuffer: RawUTF8;
  VProps: TSQLDBConnectionProperties;
begin
  LonLatDoubleRectToRect(ARect, VIntRect);

  VLen := Length(ACategoryIDArray);

  if AReciveCategoryID then begin
    VSelectedRows := RawUTF8('ID,mCategory');
  end else begin
    VSelectedRows := RawUTF8('ID');
  end;

  if VLen = 1 then begin
    if ACategoryIDArray[0] <= 0 then begin
      VCategoryWhere := '';
      Assert(False);
    end else begin
      VCategoryWhere := FormatUTF8('mCategory=? AND ',[],[ACategoryIDArray[0]]);
    end;
  end else if VLen > 1 then begin
    VCategoryWhere := Int64DynArrayToCSV(TInt64DynArray(ACategoryIDArray));
    VCategoryWhere := FormatUTF8('mCategory IN (%) AND ', [VCategoryWhere]);
  end else begin
    VCategoryWhere := '';
  end;

  VSQLSelect :=
    FormatUTF8(
      'SELECT % FROM Mark ' +
      'WHERE ' + VCategoryWhere +
      'mLeft<=? AND mRight>=? AND mBottom<=? AND mTop>=? ' +
      'AND (mGeoType=? OR mGeoLonSize>=? OR mGeoLatSize>=?);',
      [VSelectedRows],
      [VIntRect.Right,VIntRect.Left,VIntRect.Top,VIntRect.Bottom,Integer(gtPoint),Int64(ALonSize),Int64(ALatSize)]
    );

  VProps :=
    FClient.Server.Model.Props[FSQLMarkClass].ExternalDB.ConnectionProperties as TSQLDBConnectionProperties;

  VRows := VProps.ExecuteInlined(VSQLSelect, True);

  VJsonBuffer := VRows.FetchAllAsJSON(False); // ToDo: use VRows.Step

  VList := TSQLTableJSON.Create('', Pointer(VJsonBuffer), Length(VJsonBuffer));
  try
    VLen := VList.RowCount;
    SetLength(AIDArray, VLen);
    for I := 0 to VLen - 1 do begin
      AIDArray[I].MarkID := VList.GetAsInt64(I+1, 0);
      if AReciveCategoryID then begin
        AIDArray[I].CategoryID := VList.GetAsInt64(I+1, 1);
      end;
    end;
    Result := VLen;
  finally
    VList.Free;
  end;
end;
{$ENDIF}

function TMarkDbImplORMHelper._GetMarkIDArrayByRectMongoDB(
  const ACategoryIDArray: TIDDynArray;
  const ARect: TDoubleRect;
  const ALonSize: Cardinal;
  const ALatSize: Cardinal;
  const AReciveCategoryID: Boolean;
  out AIDArray: TMarkWithCategoryIDDynArray
): Integer;
var
  I, J: Integer;
  VLen: Integer;
  VIntRect: TRect;
  VSelectedRows: RawUTF8;
  VCategoryWhere: RawUTF8;
  VCollection: TMongoCollection;
  VArray: TVariantDynArray;
begin
  LonLatDoubleRectToRect(ARect, VIntRect);

  VLen := Length(ACategoryIDArray);

  if AReciveCategoryID then begin
    VSelectedRows := RawUTF8('_id,mCategory');
  end else begin
    VSelectedRows := RawUTF8('_id');
  end;

  if VLen = 1 then begin
    if ACategoryIDArray[0] <= 0 then begin
      VCategoryWhere := '';
      Assert(False);
    end else begin
      VCategoryWhere := '{mCategory:' + Int64ToUtf8(ACategoryIDArray[0]) + '},';
    end;
  end else if VLen > 1 then begin
    VCategoryWhere :=
      Int64DynArrayToCSV(
        TInt64DynArray(ACategoryIDArray), '{mCategory:{$in:[',']}},'
      );
  end else begin
    VCategoryWhere := '';
  end;

  VCollection :=
    (FClient.Server.StaticDataServer[FSQLMarkClass] as TSQLRestStorageMongoDB).Collection;

  VCollection.FindDocs(
    PUTF8Char('{$and:[' +
      '{$and:[{mLeft:{$lte:?}},{mRight:{$gte:?}},{mBottom:{$lte:?}},{mTop:{$gte:?}}]},' +
      VCategoryWhere +
      '{$or:[{mGeoType:?},{mGeoLonSize:{$gte:?}},{mGeoLatSize:{$gte:?}}]}' +
    ']}'),
    [VIntRect.Right, VIntRect.Left, VIntRect.Top, VIntRect.Bottom, Integer(gtPoint), Int64(ALonSize), Int64(ALatSize)],
    VArray, VSelectedRows
  );

  J := 0;
  SetLength(AIDArray, Length(VArray));
  for I := 0 to Length(VArray) - 1 do begin
    AIDArray[J].MarkID := DocVariantData(VArray[I]).I['_id'];
    if AIDArray[J].MarkID > 0 then begin
      if AReciveCategoryID then begin
        AIDArray[J].CategoryID := DocVariantData(VArray[I]).I['mCategory'];
        CheckID(AIDArray[J].CategoryID);
      end;
      Inc(J);
    end;
  end;
  SetLength(AIDArray, J);
  Result := J;
end;

function TMarkDbImplORMHelper.GetMarkRecArrayByRect(
  const ACategoryIDArray: TDynArray;
  const ARect: TDoubleRect;
  const AIncludeHiddenMarks: Boolean;
  const ALonLatSize: TDoublePoint;
  out AMarkRecArray: TSQLMarkRecDynArray
): Integer;
const
  cMaxArrayLen = 128;
var
  I: Integer;
  VCount: Integer;
  VId: TID;
  VMarksCount: Integer;
  VLonSize, VLatSize: Cardinal;
  VFilterByCategory: Boolean;
  VIDArray: TMarkWithCategoryIDDynArray;
  VCategoryIDArray: TIDDynArray;
begin
  LonLatSizeToInternalSize(ALonLatSize, VLonSize, VLatSize);

  VFilterByCategory := (ACategoryIDArray.Count >= cMaxArrayLen);

  if VFilterByCategory then begin
    Finalize(VCategoryIDArray);
    if not ACategoryIDArray.Sorted then begin
      ACategoryIDArray.Compare := SortDynArrayInt64;
      ACategoryIDArray.Sort;
    end;
  end else begin
    ACategoryIDArray.Slice(VCategoryIDArray, cMaxArrayLen);
  end;

  // search mark id's
  case FClientType of
    ctMongoDB: begin
      VCount := _GetMarkIDArrayByRectMongoDB(
        VCategoryIDArray,
        ARect,
        VLonSize,
        VLatSize,
        VFilterByCategory,
        VIDArray
      );
    end;
    ctSQLite3: begin
      VCount := _GetMarkIDArrayByRectSQL(
        VCategoryIDArray,
        ARect,
        VLonSize,
        VLatSize,
        VFilterByCategory,
        VIDArray
      );
    end;
    {$IFDEF ENABLE_DBMS}
    ctZDBC, ctODBC: begin
      VCount := _GetMarkIDArrayByRectDBMS(
        VCategoryIDArray,
        ARect,
        VLonSize,
        VLatSize,
        VFilterByCategory,
        VIDArray
      );
    end;
    {$ENDIF}
  else
    begin
      Assert(False);
      Result := 0;
      Exit;
    end;
  end;

  Assert(Length(VIDArray) >= VCount);

  // read marks data
  VMarksCount := 0;
  SetLength(AMarkRecArray, VCount);
  for I := 0 to VCount - 1 do begin
    if VFilterByCategory then begin
      VId := VIDArray[I].CategoryID;
      Assert(VId > 0);
      if not (ACategoryIDArray.Find(VId) >= 0) then begin
        Continue;
      end;
    end;
    VId := VIDArray[I].MarkID;
    if VId > 0 then begin
      if ReadMarkSQL(AMarkRecArray[VMarksCount], VId, 0, '') then begin
        if not AIncludeHiddenMarks then begin
          if not AMarkRecArray[VMarksCount].FVisible then begin
            Continue;
          end;
        end;
        Inc(VMarksCount);
      end;
    end;
  end;
  SetLength(AMarkRecArray, VMarksCount);
  Result := VMarksCount;
end;

function TMarkDbImplORMHelper._GetMarkRecArrayByTextSQLite3(
  const ASearch: RawUTF8;
  const AMaxCount: Integer;
  const ASearchInDescription: Boolean;
  out ANameIDArray: TIDDynArray;
  out ADescIDArray: TIDDynArray
): Integer;
var
  VLimit: RawUTF8;
  VSQLWhere: RawUTF8;
begin
  Result := 0;

  VLimit := '';

  if AMaxCount > 0 then begin
    VLimit := StringToUTF8(' LIMIT ' + IntToStr(AMaxCount));
  end;

  VSQLWhere := RawUTF8('mName MATCH ') + ASearch + VLimit;

  if FClient.FTSMatch(TSQLMarkFTS, VSQLWhere, ANameIDArray) then begin
    Inc(Result, Length(ANameIDArray));
  end;

  if not ASearchInDescription or ( (AMaxCount > 0) and (Result >= AMaxCount) ) then begin
    Exit;
  end;

  VSQLWhere := RawUTF8('mDesc MATCH ') + ASearch + VLimit;

  if FClient.FTSMatch(TSQLMarkFTS, VSQLWhere, ADescIDArray) then begin
    Inc(Result, Length(ADescIDArray));
  end;
end;

function TMarkDbImplORMHelper._GetMarkRecArrayByTextSQL(
  const ASearch: RawUTF8;
  const AMaxCount: Integer;
  const ASearchInDescription: Boolean;
  out ANameIDArray: TIDDynArray;
  out ADescIDArray: TIDDynArray
): Integer;
var
  VLimit: RawUTF8;
  VSQLSelect: RawUTF8;
  VList: TSQLTableJSON;
begin
  Result := 0;

  VLimit := '';

  if AMaxCount > 0 then begin
    VLimit := StringToUTF8(' LIMIT ' + IntToStr(AMaxCount));
  end;

  VSQLSelect := RawUTF8('SELECT RowID FROM MarkFTS WHERE mName LIKE ') + ASearch + VLimit;

  VList := FClient.ExecuteList([TSQLMarkFTS], VSQLSelect);
  if Assigned(VList) then
  try
    VList.GetRowValues(0, TInt64DynArray(ANameIDArray));
    Inc(Result, Length(ANameIDArray));
  finally
    VList.Free;
  end;

  if not ASearchInDescription or ( (AMaxCount > 0) and (Result >= AMaxCount) ) then begin
    Exit;
  end;

  if AMaxCount > 0 then begin
    VLimit := StringToUTF8(' LIMIT ' + IntToStr(AMaxCount - Result));
  end;

  VSQLSelect := RawUTF8('SELECT RowID FROM MarkFTS WHERE mDesc LIKE ') + ASearch + VLimit;

  VList := FClient.ExecuteList([TSQLMarkFTS], VSQLSelect);
  if Assigned(VList) then
  try
    VList.GetRowValues(0, TInt64DynArray(ADescIDArray));
    Inc(Result, Length(ADescIDArray));
  finally
    VList.Free;
  end;
end;

function TMarkDbImplORMHelper.GetMarkRecArrayByText(
  const ASearchText: string;
  const AMaxCount: Integer;
  const AIncludeHiddenMarks: Boolean;
  const ASearchInDescription: Boolean;
  out AMarkRecArray: TSQLMarkRecDynArray
): Integer;

  function MergeArrUnique(const A, B: TIDDynArray; out C: TIDDynArray): Integer;
  var
    I, J, R: Integer;
    P: PInt64Array;
    VArr1, VArr2: TIDDynArray;
  begin
    I := Length(A);
    J := Length(B);
    SetLength(C, I+J);
    if I >= J then begin
      VArr1 := A;
      VArr2 := B;
    end else begin
      VArr1 := B;
      VArr2 := A;
    end;
    J := Length(VArr1);
    R := J - 1;
    P := PInt64Array(VArr1);
    QuickSortInt64(P, 0, R);
    MoveFast(VArr1[0], C[0], J * SizeOf(VArr1[0]));
    for I := 0 to Length(VArr2) - 1 do begin
      if FastFindInt64Sorted(P, R, VArr2[I]) < 0 then begin
        C[J] := VArr2[I];
        Inc(J);
      end;
    end;
    SetLength(C, J);
    P := PInt64Array(C);
    QuickSortInt64(P, 0, J-1);
    Result := J;
  end;

var
  I, J, K: Integer;
  VSearch: RawUTF8;
  VIDArray: TIDDynArray;
  VNameIDArray: TIDDynArray;
  VDescIDArray: TIDDynArray;
begin
  Result := 0;

  SetLength(VNameIDArray, 0);
  SetLength(VDescIDArray, 0);

  VSearch := StringToUTF8('''' + SysUtils.AnsiLowerCase(ASearchText) + '''');

  // search mark id's
  case FClientType of
    ctSQLite3: begin
      J := _GetMarkRecArrayByTextSQLite3(
        VSearch,
        AMaxCount,
        ASearchInDescription,
        VNameIDArray,
        VDescIDArray
      );
    end;
  else
    J := _GetMarkRecArrayByTextSQL(
      VSearch,
      AMaxCount,
      ASearchInDescription,
      VNameIDArray,
      VDescIDArray
    );
  end;

  // read marks data
  if J > 0 then begin
    I := Length(VNameIDArray);
    J := Length(VDescIDArray);

    if (I > 0) and (J > 0) then begin
      K := MergeArrUnique(VNameIDArray, VDescIDArray, VIDArray);
    end else if I > 0 then begin
      K := I;
      VIDArray := VNameIDArray;
    end else if J > 0 then begin
      K := J;
      VIDArray := VDescIDArray;
    end else begin
      K := 0;
    end;

    J := 0;
    SetLength(AMarkRecArray, K);
    for I := 0 to K - 1 do begin
      if VIDArray[I] > 0 then begin
        if ReadMarkSQL(AMarkRecArray[J], VIDArray[I], 0, '') then begin
          if not AIncludeHiddenMarks then begin
            if not AMarkRecArray[J].FVisible then begin
              Continue;
            end;
          end;
          Inc(J);
        end;
      end;
    end;
    SetLength(AMarkRecArray, J);
    Result := J;
  end;
end;

end.

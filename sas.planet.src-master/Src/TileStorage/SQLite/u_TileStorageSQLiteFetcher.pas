unit u_TileStorageSQLiteFetcher;

interface

uses
  Windows,
  Classes,
  SQLite3Handler,
  t_TileStorageSQLiteHandler,
  i_MapVersionInfo,
  i_MapVersionListStatic,
  i_TileInfoBasic,
  i_TileStorageSQLiteHandler,
  i_TileStorageSQLiteHolder,
  i_TileStorageSQLiteFetcher,
  u_TileStorageSQLiteHandler,
  u_BaseInterfacedObject;

type
  TTileStorageSQLiteFetcher = class(TBaseInterfacedObject, ITileStorageSQLiteFetcher)
  private
    FTileStorageSQLiteHandler: ITileStorageSQLiteHandler;
    FSQLite3DbHandlerPtr: PSQLite3DbHandler;
    FStmtData: TSQLite3StmtData;
    FSingleVersionToScan: IMapVersionInfo;
    FLastSelectedVersion: IMapVersionInfo;
    FInoreTNE: Boolean;
    FPrepared: Boolean;
  protected
    function GetSQL_SelectEntire: AnsiString; virtual; abstract;
    procedure CallbackEnum(
      const AHandler: PSQLite3DbHandler;
      const ACallbackPtr: Pointer;
      const AStmtData: PSQLite3StmtData
    ); virtual; abstract;
    procedure InitObjIface(
      const ATileStorageSQLiteHolder: ITileStorageSQLiteHolder;
      const ADBFilename: string;
      const AUseVersionFieldInDB: Boolean;
      out AObj: TTileStorageSQLiteHandler
    ); virtual;
    procedure InternalClose;
    procedure InternalOpen;
  protected
    { ITileStorageSQLiteFetcher }
    function Opened: Boolean;
    function Fetch(var ATileInfo: TTileInfo): Boolean; virtual;
  public
    constructor Create(
      const ATileStorageSQLiteHolder: ITileStorageSQLiteHolder;
      const ADBFilename: string;
      const ASingleVersionToScan: IMapVersionInfo;
      const AUseVersionFieldInDB: Boolean;
      const AInoreTNE: Boolean
    );
    destructor Destroy; override;
  end;

  TTileStorageSQLiteFetcherComplex = class(TTileStorageSQLiteFetcher)
  private
    FTileStorageSQLiteHolder: ITileStorageSQLiteHolder;
    FUseVersionFieldInDB: Boolean;
    FTBColInfoPtr: PTBColInfo;
    FAllVersions: IMapVersionListStatic;
    FEnumVersionIndex: Integer;
  protected
    function Fetch(var ATileInfo: TTileInfo): Boolean; override;
  protected
    function GetSQL_SelectEntire: AnsiString; override;
    procedure CallbackEnum(
      const AHandler: PSQLite3DbHandler;
      const ACallbackPtr: Pointer;
      const AStmtData: PSQLite3StmtData
    ); override;
    procedure InitObjIface(
      const ATileStorageSQLiteHolder: ITileStorageSQLiteHolder;
      const ADBFilename: string;
      const AUseVersionFieldInDB: Boolean;
      out AObj: TTileStorageSQLiteHandler
    ); override;
  end;

implementation

uses
  SysUtils,
  DateUtils,
  AlSqlite3Wrapper,
  c_TileStorageSQLite,
  u_TileStorageSQLiteFunc;

{ TTileStorageSQLiteFetcher }

constructor TTileStorageSQLiteFetcher.Create(
  const ATileStorageSQLiteHolder: ITileStorageSQLiteHolder;
  const ADBFilename: string;
  const ASingleVersionToScan: IMapVersionInfo;
  const AUseVersionFieldInDB: Boolean;
  const AInoreTNE: Boolean
);
var
  VObj: TTileStorageSQLiteHandler;
begin
  inherited Create;
  FPrepared := False;
  FSingleVersionToScan := ASingleVersionToScan;
  FInoreTNE := AInoreTNE;

  // make object and store as interface
  VObj := nil;
  InitObjIface(
    ATileStorageSQLiteHolder,
    ADBFilename,
    AUseVersionFieldInDB,
    VObj
  );

  // init
  FStmtData.Init;

  // open
  InternalOpen;
end;

destructor TTileStorageSQLiteFetcher.Destroy;
begin
  InternalClose;
  FTileStorageSQLiteHandler := nil;
  inherited;
end;

function TTileStorageSQLiteFetcher.Fetch(var ATileInfo: TTileInfo): Boolean;
begin
  Result := FPrepared and FSQLite3DbHandlerPtr^.FetchPrepared(@FStmtData, CallbackEnum, @ATileInfo);
end;

procedure TTileStorageSQLiteFetcher.InitObjIface(
  const ATileStorageSQLiteHolder: ITileStorageSQLiteHolder;
  const ADBFilename:string;
  const AUseVersionFieldInDB: Boolean;
  out AObj: TTileStorageSQLiteHandler
);
begin
  Assert(AObj <> nil);
  FSQLite3DbHandlerPtr := AObj.SQLite3DbHandlerPtr;
  FTileStorageSQLiteHandler := AObj;
end;

procedure TTileStorageSQLiteFetcher.InternalClose;
begin
  if FPrepared then begin
    FPrepared := False;
    FSQLite3DbHandlerPtr^.ClosePrepared(@FStmtData);
  end;
end;

procedure TTileStorageSQLiteFetcher.InternalOpen;
var
  VSQLText: AnsiString;
begin
  InternalClose;
  VSQLText := GetSQL_SelectEntire;
  FPrepared := (Length(VSQLText) > 0) and FSQLite3DbHandlerPtr^.PrepareStatement(@FStmtData, VSQLText);
end;

function TTileStorageSQLiteFetcher.Opened: Boolean;
begin
  Result := (FTileStorageSQLiteHandler <> nil) and FTileStorageSQLiteHandler.Opened;
end;

{ TTileStorageSQLiteFetcherComplex }

procedure TTileStorageSQLiteFetcherComplex.CallbackEnum(
  const AHandler: PSQLite3DbHandler;
  const ACallbackPtr: Pointer;
  const AStmtData: PSQLite3StmtData
);
var
  VTemp: Int64;
  VBlobSize: Integer;
  VOriginalTileSize: Integer;
  VColType: Integer;
  VVersionStr: string;
  VContentType: AnsiString;
begin
  // x,y,s,d[,v][,c][,b]
  with PTileInfo(ACallbackPtr)^ do begin
    FTile.X := AStmtData^.ColumnInt(0);
    FTile.Y := AStmtData^.ColumnInt(1);
    // original size (in bytes)
    VOriginalTileSize := AStmtData^.ColumnInt(2);
    FSize := VOriginalTileSize;
    // time (in unix seconds)
    VTemp := AStmtData^.ColumnInt64(3);
    FLoadDate := UnixToDateTime(VTemp);
    // others
    FVersionInfo := nil;
    FContentType := nil;
    FData := nil;
  end;

  // version
  case FTBColInfoPtr^.ModeV of
    vcm_Text: begin
      // version as TEXT without conversion
      VVersionStr := AStmtData^.ColumnAsString(4);
    end;
    vcm_Int: begin
      // get version as field 4
      VColType := AStmtData^.ColumnType(4);
      case VColType of
        SQLITE_NULL: begin
          // null value - empty version
          VVersionStr := cDefaultVersionAsStrValue;
        end;
        SQLITE_INTEGER: begin
          // version as integer
          VTemp := AStmtData^.ColumnInt64(4);
          if VTemp = cDefaultVersionAsIntValue then begin
            VVersionStr := cDefaultVersionAsStrValue;
          end else begin
            VVersionStr := IntToStr(VTemp);
          end;
        end;
      else
        begin
          // SQLITE_FLOAT, SQLITE_BLOB, SQLITE_TEXT
          VVersionStr := AStmtData^.ColumnAsString(4);
        end;
      end;
    end;
  end;

  // �������� ������ ��� ������ �������
  if Assigned(FLastSelectedVersion) and SameText(FLastSelectedVersion.StoreString, VVersionStr) then begin
    // ������ ��� ����
    PTileInfo(ACallbackPtr)^.FVersionInfo := FLastSelectedVersion;
  end else begin
    // ������ ���� �������
    PTileInfo(ACallbackPtr)^.FVersionInfo := FTileStorageSQLiteHolder.GetVersionInfo(VVersionStr);
  end;

  // check if TNE
  with PTileInfo(ACallbackPtr)^ do begin
    if VOriginalTileSize <= 0 then begin
      // TNE
      FInfoType := titTneExists;
      Exit;
    end else begin
      // tile
      FInfoType := titExists;
    end;
  end;

  // content-type
  if FTBColInfoPtr^.HasC then begin
    // get content_type (FieldIndex = 4 + Ord(FTBColInfo.HasV)
    VContentType := AStmtData^.ColumnAsAnsiString(4 + Ord(FTBColInfoPtr^.ModeV <> vcm_None));
  end else begin
    // use default content_type
    VContentType := '';
  end;

  // treat as tile
  with PTileInfo(ACallbackPtr)^ do begin
    // content_type
    FContentType := FTileStorageSQLiteHolder.GetContentTypeInfo(VContentType);

    // tile body
    VColType := 4 + Ord(FTBColInfoPtr^.ModeV <> vcm_None) + Ord(FTBColInfoPtr^.HasC);
    VBlobSize := AStmtData^.ColumnBlobSize(VColType);
    // if no BLOB - treat as TNE
    if VBlobSize <= 0 then begin
      // TNE
      FInfoType := titTneExists;
    end else begin
      // tile
      FData := CreateTileBinaryData(
        VOriginalTileSize,
        VBlobSize,
        AStmtData^.ColumnBlobData(VColType)
      );
    end;
  end;
end;

function TTileStorageSQLiteFetcherComplex.Fetch(var ATileInfo: TTileInfo): Boolean;
begin
  Result := inherited Fetch(ATileInfo);
  if Result then begin
    Exit;
  end;

  // �������� ��������� ������� - ��������� ������ ���������
  repeat
    InternalOpen;
    // ��������, ������ ������ ������ � ��������
    if not FPrepared then begin
      Exit;
    end;
    // � ���, ����� ��� ����
    if Opened then begin
      // ��������...
      Result := inherited Fetch(ATileInfo);
      // ...��������
      if Result then begin
        Exit;
      end;
    end;
  until False;
end;

function TTileStorageSQLiteFetcherComplex.GetSQL_SelectEntire: AnsiString;
var
  VWhere: AnsiString;
  VSelectTileInfo: TSelectTileInfoComplex;
begin
  // x,y,s,d[,v][,c][,b]
  if FInoreTNE then begin
    VWhere := 's>0 and b is not null';
  end else begin
    VWhere := '';
  end;
  Result := 'SELECT x,y,s,d';

  // ������� �� ������ ����� � ��
  if FUseVersionFieldInDB and (FTBColInfoPtr^.ModeV <> vcm_None) then begin
    Result := Result + ',v';
    // ���� ��������� ���� ������
    // ����� ����� ���������� ������, ��� ��� ������ ������ ���� ��������
    if Assigned(FSingleVersionToScan) then begin
      // ���������� ���������� ������ - ������ � � �����
      // ���� ���
      FLastSelectedVersion := FSingleVersionToScan;
      FSingleVersionToScan := nil;
    end else if Assigned(FAllVersions) and (FEnumVersionIndex < FAllVersions.Count) then begin
      // ����� ��� ������ �� ������ �� ������� - ���� ���������
      FLastSelectedVersion := FAllVersions.Item[FEnumVersionIndex];
      Inc(FEnumVersionIndex);
    end else begin
      // ������ ������ ������
      Result := '';
      Exit;
    end;

    // ������ ������
    ParseSQLiteDBVersion(
      FUseVersionFieldInDB,
      FTBColInfoPtr^.ModeV,
      FLastSelectedVersion,
      VSelectTileInfo
    );

    if Length(VWhere) > 0 then begin
      VWhere := VWhere + ' AND ';
    end;

    VWhere := VWhere +
      VersionFieldIsEqual(
        VSelectTileInfo.RequestedVersionIsInt,
        FTBColInfoPtr^.ModeV,
        VSelectTileInfo.RequestedVersionToDB
      );
  end;
  if FTBColInfoPtr^.HasC then begin
    Result := Result + ',c'; // ���� ��������� ���� ContextType
  end;
  Result := Result + ',b FROM t';
  if Length(VWhere) > 0 then begin
    Result := Result + ' WHERE ' + VWhere;
  end;
end;

procedure TTileStorageSQLiteFetcherComplex.InitObjIface(
  const ATileStorageSQLiteHolder: ITileStorageSQLiteHolder;
  const ADBFilename: string;
  const AUseVersionFieldInDB: Boolean;
  out AObj: TTileStorageSQLiteHandler
);
var
  VObj: TTileStorageSQLiteHandlerComplex;
begin
  Assert(AObj = nil);

  VObj :=
    TTileStorageSQLiteHandlerComplex.Create(
      ATileStorageSQLiteHolder,
      ADBFilename,
      FSingleVersionToScan,
      AUseVersionFieldInDB
    );

  AObj := VObj;

  FTileStorageSQLiteHolder := ATileStorageSQLiteHolder;
  FUseVersionFieldInDB := AUseVersionFieldInDB;
  FEnumVersionIndex := 0;

  if Assigned(FSingleVersionToScan) then begin
    // �������� ������ �� ����� ��������� ������
    FAllVersions := nil;
  end else begin
    // �������� �� ������ ���� ������ � ��
    FAllVersions := VObj.GetListOfVersions(nil);
  end;
  FTBColInfoPtr := VObj.GetTBColInfoPtr;

  inherited;
end;

end.

unit t_TileStorageSQLite;

interface

uses
  Types,
  i_BinaryData,
  i_TileInfoBasic,
  i_MapVersionInfo,
  i_ContentTypeInfo,
  u_TileRectInfoShort; // for TArrayOfTileInfoShortInternal

type
  TGetTileInfoItem = (
    gtiiLoadDate,
    gtiiSize,
    gtiiBody,
    gtiiContentType
  );
  TGetTileInfoModeSQLite = set of TGetTileInfoItem;

  TDeleteTileAllData = record
    DXY: TPoint;
    DZoom: Byte;
    DVersionInfo: IMapVersionInfo;
  end;
  PDeleteTileAllData = ^TDeleteTileAllData;

  TSaveTileFlag = (
    stfKeepExisting,
    stfSkipIfSameAsPrev
  );
  TSaveTileFlags = set of TSaveTileFlag;

  TSaveTileAllData = record
    SXY: TPoint;
    SZoom: Byte;
    SVersionInfo: IMapVersionInfo;
    SLoadDate: TDateTime;
    SContentType: IContentTypeInfoBasic;
    SData: IBinaryData;
    SSaveTileFlags: TSaveTileFlags;
  end;
  PSaveTileAllData = ^TSaveTileAllData;

  TGetTileInfo = record
    GTilePos: TPoint;
    GZoom: Byte;
    GVersion: IMapVersionInfo;
    GShowOtherVersions: Boolean;
    GMode: TGetTileInfoModeSQLite;
  end;
  PGetTileInfo = ^TGetTileInfo;

  TTileInfoShortEnumData = record
    DestRect: TRect;
    DestZoom: Byte;
    RectVersionInfo: IMapVersionInfo;
    RectCount: TPoint;
    RectItems: TArrayOfTileInfoShortInternal;
  end;
  PTileInfoShortEnumData = ^TTileInfoShortEnumData;

  TGetTileResult = record
    // ���������
    GTileInfo: ITileInfoBasic;
    // �������������� ���������, ������� ���������, �� ������� �������� �� �������������
    GExtraMode: TGetTileInfoModeSQLite;
  end;
  PGetTileResult = ^TGetTileResult;

implementation

end.

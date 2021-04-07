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

unit u_MarkSystemORMModel;

interface

uses
  mORMot,
  SynCommons;

type
  // ������ �������������
  TSQLUser = class(TSQLRecord)
  public
    FName: RawUTF8;
  published
    property uName: RawUTF8 read FName write FName;
  end;

  // ���������
  TSQLCategory = class(TSQLRecord)
  public
    FName: RawUTF8;
  published
    property cName: RawUTF8 read FName write FName;
  end;

  // ��������� ��������� ��������� �� �������������
  TSQLCategoryView = class(TSQLRecord)
  public
    FUser: TID;
    FCategory: TID;
    FVisible: Boolean;
    FMinZoom: Byte;
    FMaxZoom: Byte;
  published
    property cvUser: TID read FUser write FUser;
    property cvCategory: TID read FCategory write FCategory;
    property cvVisible: Boolean read FVisible write FVisible;
    property cvMinZoom: Byte read FMinZoom write FMinZoom;
    property cvMaxZoom: Byte read FMaxZoom write FMaxZoom;
  end;

  // ���� ��������� ��� �����
  TSQLGeoType = (gtUndef=0, gtPoint, gtLine, gtPoly);

  // ���� � ��������� ��� �����
  TSQLMarkImage = class(TSQLRecord)
  public
    FName: RawUTF8;
  published
    property miName: RawUTF8 read FName write FName;
  end;

  TSQLMarkAppearance = class(TSQLRecord)
  public
    FColor1: Cardinal;
    FColor2: Cardinal;
    FScale1: Integer;
    FScale2: Integer;
  published
    property maColor1: Cardinal read FColor1 write FColor1;
    property maColor2: Cardinal read FColor2 write FColor2;
    property maScale1: Integer read FScale1 write FScale1;
    property maScale2: Integer read FScale2 write FScale2;
  end;

  // �����
  TSQLMark = class(TSQLRecord)
  public
    FCategory: TID;
    FImage: TID;
    FAppearance: TID;
    FName: RawUTF8;
    FDesc: RawUTF8;
    FGeoType: TSQLGeoType;
    FGeoCount: Cardinal;
    FGeoLonSize: Cardinal;
    FGeoLatSize: Cardinal;
    FGeoWKB: TSQLRawBlob;
  published
    property mCategory: TID read FCategory write FCategory;
    property mImage: TID read FImage write FImage;
    property mAppearance: TID read FAppearance write FAppearance;
    property mName: RawUTF8 read FName write FName;
    property mDesc: RawUTF8 read FDesc write FDesc;
    property mGeoType: TSQLGeoType read FGeoType write FGeoType;
    property mGeoCount: Cardinal read FGeoCount write FGeoCount;
    property mGeoLonSize: Cardinal read FGeoLonSize write FGeoLonSize;
    property mGeoLatSize: Cardinal read FGeoLatSize write FGeoLatSize;
    property mGeoWKB: TSQLRawBlob read FGeoWKB write FGeoWKB;
  end;

  TSQLMarkClass = class of TSQLMark;

  TSQLMarkDBMS = class(TSQLMark)
  public
    FLeft, FRight, FBottom, FTop: Integer;
  published
    property mLeft: Integer read FLeft write FLeft;
    property mRight: Integer read FRight write FRight;
    property mBottom: Integer read FBottom write FBottom;
    property mTop: Integer read FTop write FTop;
  end;

  TSQLMarkMongoDB = class(TSQLMarkDBMS);

  // ��������� ��������� ����� �� �������������
  TSQLMarkView = class(TSQLRecord)
  public
    FUser: TID;
    FMark: TID;
    FCategory: TID;
    FVisible: Boolean;
  published
    property mvUser: TID read FUser write FUser;
    property mvMark: TID read FMark write FMark;
    property mvCategory: TID read FCategory write FCategory;
    property mvVisible: Boolean read FVisible write FVisible;
  end;

  // ������ �� ��������������� ��������������, ��� �������� ������ ���������
  TSQLMarkRTree = class(TSQLRecordRTree)
  public
    FLeft, FRight, FBottom, FTop: Double;
  published
    // X or Longitude coordinates in range [-180..180]
    property mLeft: Double read FLeft write FLeft;         // min_dimension1
    property mRight: Double read FRight write FRight;      // max_dimension1
    // Y or Latitude coordinates in range [-90..90]
    property mBottom: Double read FBottom write FBottom;   // min_dimension2
    property mTop: Double read FTop write FTop;            // max_dimension2
  end;

  // ������ �� ����� � �������� �����, ��� �������� ���������� ������
  // - ��� ����������� �������� ������������ � ��������, ������� ����� ����
  //   �� � AnsiLowerCase
  TSQLMarkFTS = class(TSQLRecordFTS4)
  public
    FName: RawUTF8;
    FDesc: RawUTF8;
  published
    property mName: RawUTF8 read FName write FName; // ��� ����� � AnsiLowerCase
    property mDesc: RawUTF8 read FDesc write FDesc; // �������� ����� � AnsiLowerCase
  end;

function CreateModelSQLite3: TSQLModel;
function CreateModelDBMS: TSQLModel;
function CreateModelMongoDB: TSQLModel;

implementation

function CreateModelSQLite3: TSQLModel;
begin
  Result :=
    TSQLModel.Create(
      [
        TSQLUser,
        TSQLCategory,
        TSQLCategoryView,
        TSQLMarkImage,
        TSQLMark,
        TSQLMarkView,
        TSQLMarkAppearance,
        TSQLMarkFTS,
        TSQLMarkRTree
      ]
    );
end;

function CreateModelDBMS: TSQLModel;
begin
  Result :=
    TSQLModel.Create(
      [
        TSQLUser,
        TSQLCategory,
        TSQLCategoryView,
        TSQLMarkImage,
        TSQLMarkDBMS,
        TSQLMarkView,
        TSQLMarkAppearance,
        TSQLMarkFTS
      ]
    );
end;

function CreateModelMongoDB: TSQLModel;
begin
  Result :=
    TSQLModel.Create(
      [
        TSQLUser,
        TSQLCategory,
        TSQLCategoryView,
        TSQLMarkImage,
        TSQLMarkMongoDB,
        TSQLMarkView,
        TSQLMarkAppearance,
        TSQLMarkFTS
      ]
    );
end;

end.

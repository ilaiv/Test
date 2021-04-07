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

unit u_ContentTypeManagerBase;

interface

uses
  Classes,
  i_BitmapTileSaveLoad,
  i_ContentTypeInfo,
  i_ContentConverter,
  i_ContentTypeManager,
  i_StringListStatic,
  u_ContentTypeListByKey,
  u_ContentConverterMatrix,
  u_BaseInterfacedObject;

type
  TContentTypeManagerBase = class(
    TBaseInterfacedObject,
    IContentTypeManager,
    IContentTypeManagerBitmap
  )
  private
    FExtList: TContentTypeListByKey;
    FTypeList: TContentTypeListByKey;
    FBitmapExtList: TContentTypeListByKey;
    FBitmapTypeList: TContentTypeListByKey;
    FKmlExtList: TContentTypeListByKey;
    FKmlTypeList: TContentTypeListByKey;
    FConverterMatrix: TContentConverterMatrix;
  protected
    procedure AddByType(
      const AInfo: IContentTypeInfoBasic;
      const AType: AnsiString
    );
    procedure AddByExt(
      const AInfo: IContentTypeInfoBasic;
      const AExt: AnsiString
    );
    property ExtList: TContentTypeListByKey read FExtList;
    property TypeList: TContentTypeListByKey read FTypeList;
    property BitmapExtList: TContentTypeListByKey read FBitmapExtList;
    property BitmapTypeList: TContentTypeListByKey read FBitmapTypeList;
    property KmlExtList: TContentTypeListByKey read FKmlExtList;
    property KmlTypeList: TContentTypeListByKey read FKmlTypeList;
    property ConverterMatrix: TContentConverterMatrix read FConverterMatrix;
  private
    function GetInfo(const AType: AnsiString): IContentTypeInfoBasic;
    function GetInfoByExt(const AExt: AnsiString): IContentTypeInfoBasic;
    function GetIsBitmapType(const AType: AnsiString): Boolean;
    function GetIsBitmapExt(const AExt: AnsiString): Boolean;
    function GetBitmapLoaderByFileName(const AFileName: string): IBitmapTileLoader;
    function GetIsKmlType(const AType: AnsiString): Boolean;
    function GetIsKmlExt(const AExt: AnsiString): Boolean;
    function GetConverter(const ATypeSource, ATypeTarget: AnsiString): IContentConverter;
    function GetKnownExtList: IStringListStatic;
  public
    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses
  SysUtils,
  ALString,
  ALStringList,
  u_StringListStatic,
  u_StrFunc;

procedure TContentTypeManagerBase.AddByExt(
  const AInfo: IContentTypeInfoBasic;
  const AExt: AnsiString
);
begin
  Assert(IsAscii(AExt));
  FExtList.Add(AExt, AInfo);
  if Supports(AInfo, IContentTypeInfoBitmap) then begin
    FBitmapExtList.Add(AExt, AInfo);
  end else if Supports(AInfo, IContentTypeInfoVectorData) then begin
    FKmlExtList.Add(AExt, AInfo);
  end;
end;

procedure TContentTypeManagerBase.AddByType(
  const AInfo: IContentTypeInfoBasic;
  const AType: AnsiString
);
begin
  Assert(IsAscii(AType));
  FTypeList.Add(AType, AInfo);
  if Supports(AInfo, IContentTypeInfoBitmap) then begin
    FBitmapTypeList.Add(AType, AInfo);
  end else if Supports(AInfo, IContentTypeInfoVectorData) then begin
    FKmlTypeList.Add(AType, AInfo);
  end;
end;

constructor TContentTypeManagerBase.Create;
begin
  inherited Create;
  FExtList := TContentTypeListByKey.Create;
  FTypeList := TContentTypeListByKey.Create;
  FBitmapExtList := TContentTypeListByKey.Create;
  FBitmapTypeList := TContentTypeListByKey.Create;
  FKmlExtList := TContentTypeListByKey.Create;
  FKmlTypeList := TContentTypeListByKey.Create;
  FConverterMatrix := TContentConverterMatrix.Create;
end;

destructor TContentTypeManagerBase.Destroy;
begin
  FreeAndNil(FExtList);
  FreeAndNil(FTypeList);
  FreeAndNil(FBitmapExtList);
  FreeAndNil(FBitmapTypeList);
  FreeAndNil(FKmlExtList);
  FreeAndNil(FKmlTypeList);
  FreeAndNil(FConverterMatrix);
  inherited;
end;

function TContentTypeManagerBase.GetKnownExtList: IStringListStatic;
var
  VList: TStringList;
  VEnum: TALStringsEnumerator;
begin
  VEnum := FExtList.GetEnumerator;
  try
    VList := TStringList.Create;
    try
      while VEnum.MoveNext do begin
        VList.Add(VEnum.Current);
      end;
    finally
      Result := TStringListStatic.CreateWithOwn(VList);
    end;
  finally
    VEnum.Free;
  end;
end;

function TContentTypeManagerBase.GetBitmapLoaderByFileName(
  const AFileName: string
): IBitmapTileLoader;
var
  VExt: string;
  VExtAscii: AnsiString;
  VContentType: IContentTypeInfoBasic;
  VContentTypeBitmap: IContentTypeInfoBitmap;
begin
  Result := nil;
  VExt := ExtractFileExt(AFileName);
  if IsAscii(VExt) then begin
    VExtAscii := StringToAsciiSafe(VExt);
    VExtAscii := AlLowerCase(VExtAscii);
    VContentType := GetInfoByExt(VExtAscii);
    if Assigned(VContentType) then begin
      if Supports(VContentType, IContentTypeInfoBitmap, VContentTypeBitmap) then begin
        Result := VContentTypeBitmap.GetLoader;
      end;
    end;
  end;
end;

function TContentTypeManagerBase.GetConverter(
  const ATypeSource, ATypeTarget: AnsiString): IContentConverter;
begin
  Assert(IsAscii(ATypeSource));
  Assert(IsAscii(ATypeTarget));
  Result := FConverterMatrix.Get(ATypeSource, ATypeTarget);
end;

function TContentTypeManagerBase.GetInfo(
  const AType: AnsiString): IContentTypeInfoBasic;
begin
  Assert(IsAscii(AType));
  Result := FTypeList.Get(AType);
end;

function TContentTypeManagerBase.GetInfoByExt(
  const AExt: AnsiString
): IContentTypeInfoBasic;
begin
  Assert(IsAscii(AExt));
  Result := FExtList.Get(AExt);
end;

function TContentTypeManagerBase.GetIsBitmapExt(const AExt: AnsiString): Boolean;
begin
  Assert(IsAscii(AExt));
  Result := FBitmapExtList.Get(AExt) <> nil;
end;

function TContentTypeManagerBase.GetIsBitmapType(const AType: AnsiString): Boolean;
begin
  Assert(IsAscii(AType));
  Result := FBitmapTypeList.Get(AType) <> nil;
end;

function TContentTypeManagerBase.GetIsKmlExt(const AExt: AnsiString): Boolean;
begin
  Assert(IsAscii(AExt));
  Result := FKmlExtList.Get(AExt) <> nil;
end;

function TContentTypeManagerBase.GetIsKmlType(const AType: AnsiString): Boolean;
begin
  Assert(IsAscii(AType));
  Result := FKmlTypeList.Get(AType) <> nil;
end;

end.

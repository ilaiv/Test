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

unit u_KmzInfoSimpleParser;

interface

uses
  Classes,
  i_BinaryData,
  i_VectorItemSubset,
  i_ArchiveReadWriteFactory,
  i_VectorDataLoader,
  u_BaseInterfacedObject;

type
  TKmzInfoSimpleParser = class(TBaseInterfacedObject, IVectorDataLoader)
  private
    FKmlParser: IVectorDataLoader;
    FArchiveReadFactory: IArchiveReaderFactory;
    function LoadFromStreamInternal(
      const AContext: TVectorLoadContext;
      AStream: TStream
    ): IVectorItemSubset;
  private
    function Load(
      const AContext: TVectorLoadContext;
      const AData: IBinaryData
    ): IVectorItemSubset;
  public
    constructor Create(
      const AKmlParser: IVectorDataLoader;
      const AArchiveReadFactory: IArchiveReaderFactory
    );
  end;

implementation

uses
  SysUtils,
  i_ArchiveReadWrite,
  u_StreamReadOnlyByBinaryData;

{ TKmzInfoSimpleParser }

constructor TKmzInfoSimpleParser.Create(
  const AKmlParser: IVectorDataLoader;
  const AArchiveReadFactory: IArchiveReaderFactory
);
begin
  inherited Create;
  FKmlParser := AKmlParser;
  FArchiveReadFactory := AArchiveReadFactory;
end;

function TKmzInfoSimpleParser.Load(
  const AContext: TVectorLoadContext;
  const AData: IBinaryData
): IVectorItemSubset;
var
  VStream: TStreamReadOnlyByBinaryData;
begin
  Result := nil;
  VStream := TStreamReadOnlyByBinaryData.Create(AData);
  try
    Result := LoadFromStreamInternal(AContext, VStream);
  finally
    VStream.Free;
  end;
end;

function TKmzInfoSimpleParser.LoadFromStreamInternal(
  const AContext: TVectorLoadContext;
  AStream: TStream
): IVectorItemSubset;
var
  VZip: IArchiveReader;
  VItemsCount: Integer;
  VData: IBinaryData;
  VIndex: Integer;
  I: Integer;
  VFileName: string;
begin
  Result := nil;
  VZip := FArchiveReadFactory.BuildByStream(AStream);
  VItemsCount := VZip.GetItemsCount;
  if VItemsCount > 0 then begin
    VData := VZip.GetItemByName('doc.kml');
    if VData = nil then begin
      VIndex := 0;
      for I := 0 to VItemsCount - 1 do begin
        if LowerCase(ExtractFileExt(VZip.GetItemNameByIndex(I))) = '.kml' then begin
          VIndex := I;
          Break;
        end;
      end;
      VData := VZip.GetItemByIndex(VIndex, VFileName);
    end;

    Result := FKmlParser.Load(AContext, VData);
  end;
end;

end.

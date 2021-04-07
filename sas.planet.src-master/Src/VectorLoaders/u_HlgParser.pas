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

unit u_HlgParser;

interface

uses
  i_BinaryData,
  i_VectorDataLoader,
  i_GeometryLonLatFactory,
  i_VectorItemSubset,
  i_VectorDataFactory,
  i_VectorItemSubsetBuilder,
  u_BaseInterfacedObject;

type
  THlgParser = class(TBaseInterfacedObject, IVectorDataLoader)
  private
    FVectorItemSubsetBuilderFactory: IVectorItemSubsetBuilderFactory;
    FVectorDataFactory: IVectorDataFactory;
    FVectorGeometryLonLatFactory: IGeometryLonLatFactory;
  private
    function Load(
      const AContext: TVectorLoadContext;
      const AData: IBinaryData
    ): IVectorItemSubset;
  public
    constructor Create(
      const AVectorItemSubsetBuilderFactory: IVectorItemSubsetBuilderFactory;
      const AVectorDataFactory: IVectorDataFactory;
      const AVectorGeometryLonLatFactory: IGeometryLonLatFactory
    );
  end;

implementation

uses
  Classes,
  IniFiles,
  Encodings,
  i_ConfigDataProvider,
  i_GeometryLonLat,
  i_VectorDataItemSimple,
  u_ConfigProviderHelpers,
  u_StreamReadOnlyByBinaryData,
  u_ConfigDataProviderByIniFile;

{ THlgParser }

constructor THlgParser.Create(
  const AVectorItemSubsetBuilderFactory: IVectorItemSubsetBuilderFactory;
  const AVectorDataFactory: IVectorDataFactory;
  const AVectorGeometryLonLatFactory: IGeometryLonLatFactory
);
begin
  inherited Create;
  FVectorItemSubsetBuilderFactory := AVectorItemSubsetBuilderFactory;
  FVectorDataFactory := AVectorDataFactory;
  FVectorGeometryLonLatFactory := AVectorGeometryLonLatFactory;
end;

function THlgParser.Load(
  const AContext: TVectorLoadContext;
  const AData: IBinaryData
): IVectorItemSubset;
var
  VIniFile: TMemIniFile;
  VIniStrings: TStringList;
  VIniStream: TStream;
  VHLGData: IConfigDataProvider;
  VPolygonSection: IConfigDataProvider;
  VPolygon: IGeometryLonLatPolygon;
  VItem: IVectorDataItem;
  VList: IVectorItemSubsetBuilder;
begin
  Result := nil;
  VPolygon := nil;
  VHLGData := nil;
  if AData <> nil then begin
    VIniStream := TStreamReadOnlyByBinaryData.Create(AData);
    try
      VIniStream.Position := 0;
      VIniStrings := TStringList.Create;
      try
        LoadStringsFromStream(VIniStrings, VIniStream);
        VIniFile := TMemIniFile.Create('');
        try
          VIniFile.SetStrings(VIniStrings);
          VHLGData := TConfigDataProviderByIniFile.CreateWithOwn(VIniFile);
          VIniFile := nil;
        finally
          VIniFile.Free;
        end;
      finally
        VIniStrings.Free;
      end;
    finally
      VIniStream.Free;
    end;
  end;
  if VHLGData <> nil then begin
    VPolygonSection := VHLGData.GetSubItem('HIGHLIGHTING');
    if VPolygonSection <> nil then begin
      VPolygon := ReadPolygon(VPolygonSection, FVectorGeometryLonLatFactory);
    end;
  end;
  if VPolygon <> nil then begin
    VItem :=
      FVectorDataFactory.BuildItem(
        AContext.MainInfoFactory.BuildMainInfo(AContext.IdData, '', ''),
        nil,
        VPolygon
      );
    VList := FVectorItemSubsetBuilderFactory.Build;
    VList.Add(VItem);
    Result := VList.MakeStaticAndClear;
  end;
end;

end.

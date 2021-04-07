﻿{******************************************************************************}
{* SAS.Planet (SAS.Планета)                                                   *}
{* Copyright (C) 2007-2016, SAS.Planet development team.                      *}
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

unit u_XmlInfoSimpleParser;

interface

uses
  Classes,
  SysUtils,
  i_BinaryData,
  i_VectorDataFactory,
  i_VectorItemSubsetBuilder,
  i_VectorItemSubset,
  i_GeometryLonLatFactory,
  i_VectorDataLoader,
  i_MarkPicture,
  i_AppearanceOfMarkFactory,
  u_VectorItemTreeImporterXML,
  u_BaseInterfacedObject;

type
  TXMLInfoSimpleParser = class(TBaseInterfacedObject, IVectorDataLoader)
  private
    FMarkPictureList: IMarkPictureList;
    FAppearanceOfMarkFactory: IAppearanceOfMarkFactory;
    FVectorGeometryLonLatFactory: IGeometryLonLatFactory;
    FVectorDataFactory: IVectorDataFactory;
    FVectorItemSubsetBuilderFactory: IVectorItemSubsetBuilderFactory;
    FImporter: IVectorItemTreeImporterXMLInternal;
  private
    function Load(
      const AContext: TVectorLoadContext;
      const AData: IBinaryData
    ): IVectorItemSubset;
  public
    constructor Create(
      const AMarkPictureList: IMarkPictureList;
      const AAppearanceOfMarkFactory: IAppearanceOfMarkFactory;
      const AVectorGeometryLonLatFactory: IGeometryLonLatFactory;
      const AVectorDataFactory: IVectorDataFactory;
      const AVectorItemSubsetBuilderFactory: IVectorItemSubsetBuilderFactory
    );
  end;

implementation

uses
  i_VectorItemTree,
  u_StreamReadOnlyByBinaryData;

{ TXmlInfoSimpleParser }

constructor TXmlInfoSimpleParser.Create(
  const AMarkPictureList: IMarkPictureList;
  const AAppearanceOfMarkFactory: IAppearanceOfMarkFactory;
  const AVectorGeometryLonLatFactory: IGeometryLonLatFactory;
  const AVectorDataFactory: IVectorDataFactory;
  const AVectorItemSubsetBuilderFactory: IVectorItemSubsetBuilderFactory
);
begin
  inherited Create;
  FMarkPictureList := AMarkPictureList;
  FAppearanceOfMarkFactory := AAppearanceOfMarkFactory;
  FVectorGeometryLonLatFactory := AVectorGeometryLonLatFactory;
  FVectorDataFactory := AVectorDataFactory;
  FVectorItemSubsetBuilderFactory := AVectorItemSubsetBuilderFactory;

  FImporter :=
    TVectorItemTreeImporterXML.Create(
      True,
      FMarkPictureList,
      FAppearanceOfMarkFactory,
      nil,
      FVectorGeometryLonLatFactory,
      FVectorDataFactory,
      FVectorItemSubsetBuilderFactory
    );
end;

procedure AddSubTree(
  const ASubsetBuilder: IVectorItemSubsetBuilder;
  const ATree: IVectorItemTree
);
var
  I: Integer;
  VSubset: IVectorItemSubset;
  VSubTree: IVectorItemTree;
begin
  if Assigned(ATree) then begin
    VSubset := ATree.Items;
    if Assigned(VSubset) then begin
      for I := 0 to VSubset.Count - 1 do begin
        ASubsetBuilder.Add(VSubset.Items[I]);
      end;
    end;
    for I := 0 to ATree.SubTreeItemCount - 1 do begin
      VSubTree := ATree.GetSubTreeItem(I);
      AddSubTree(ASubsetBuilder, VSubTree);
    end;
  end;
end;

function TXmlInfoSimpleParser.Load(
  const AContext: TVectorLoadContext;
  const AData: IBinaryData
): IVectorItemSubset;
var
  VTree: IVectorItemTree;
  VStream: TStreamReadOnlyByBinaryData;
  VSubsetBuilder: IVectorItemSubsetBuilder;
begin
  VStream := TStreamReadOnlyByBinaryData.Create(AData);
  try
    VTree := FImporter.LoadFromStream(AContext, VStream);
    if VTree.SubTreeItemCount = 0 then begin
      Result := VTree.Items;
    end else begin
      VSubsetBuilder := FVectorItemSubsetBuilderFactory.Build;
      AddSubTree(VSubsetBuilder, VTree);
      Result := VSubsetBuilder.MakeStaticAndClear;
    end;
  finally
    VStream.Free;
  end;
end;

end.

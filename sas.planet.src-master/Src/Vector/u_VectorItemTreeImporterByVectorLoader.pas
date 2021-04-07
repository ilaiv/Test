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

unit u_VectorItemTreeImporterByVectorLoader;

interface

uses
  Classes,
  i_NotifierOperation,
  i_VectorDataLoader,
  i_VectorDataFactory,
  i_VectorItemTreeImporter,
  i_VectorItemTree,
  u_BaseInterfacedObject;

type
  TVectorItemTreeImporterByVectorLoader = class(TBaseInterfacedObject, IVectorItemTreeImporter)
  private
    FVectorDataItemMainInfoFactory: IVectorDataItemMainInfoFactory;
    FLoader: IVectorDataLoader;
  private
    function ProcessImport(
      AOperationID: Integer;
      const ACancelNotifier: INotifierOperation;
      const AFileName: string;
      const AConfig: IInterface
    ): IVectorItemTree;
  public
    constructor Create(
      const AVectorDataItemMainInfoFactory: IVectorDataItemMainInfoFactory;
      const ALoader: IVectorDataLoader
    );
  end;

implementation

uses
  SysUtils,
  i_BinaryData,
  i_ImportConfig,
  i_VectorItemSubset,
  u_VectorItemTree,
  u_BinaryDataByMemStream;

{ TVectorItemTreeImporterByVectorLoader }

constructor TVectorItemTreeImporterByVectorLoader.Create(
  const AVectorDataItemMainInfoFactory: IVectorDataItemMainInfoFactory;
  const ALoader: IVectorDataLoader
);
begin
  inherited Create;
  FVectorDataItemMainInfoFactory := AVectorDataItemMainInfoFactory;
  FLoader := ALoader;
end;

function TVectorItemTreeImporterByVectorLoader.ProcessImport(
  AOperationID: Integer;
  const ACancelNotifier: INotifierOperation;
  const AFileName: string;
  const AConfig: IInterface
): IVectorItemTree;
var
  VMemStream: TMemoryStream;
  VData: IBinaryData;
  VConfig: IImportConfig;
  VContext: TVectorLoadContext;
  VVectorData: IVectorItemSubset;
begin
  Result := nil;
  VMemStream := TMemoryStream.Create;
  try
    VMemStream.LoadFromFile(AFileName);
    VData := TBinaryDataByMemStream.CreateWithOwn(VMemStream);
    VMemStream := nil;
    VContext.Init;
    VContext.MainInfoFactory := FVectorDataItemMainInfoFactory;
    if Supports(AConfig, IImportConfig, VConfig) then begin
      VContext.PointParams := VConfig.PointParams;
      VContext.LineParams := VConfig.LineParams;
      VContext.PolygonParams := VConfig.PolyParams;
    end;
    VVectorData := FLoader.Load(VContext, VData);
    Result := TVectorItemTree.Create('', VVectorData, nil);
  finally
    VMemStream.Free;
  end;
end;

end.

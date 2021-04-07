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

unit u_PredicateByStaticSampleList;

interface

uses
  i_IDList,
  i_BinaryData,
  i_BinaryDataListStatic,
  i_PredicateByBinaryData,
  u_BaseInterfacedObject;

type
  TPredicateByStaticSampleList = class(TBaseInterfacedObject, IPredicateByBinaryData)
  private
    FListBySize: IIDInterfaceList;
    function CalcHash(const AData: IBinaryData): Integer;
    function CompareData(const AData1, AData2: IBinaryData): Boolean;
    procedure AppendSample(const ASample: IBinaryData);
  private
    function Check(const AData: IBinaryData): Boolean;
  public
    constructor Create(
      const ABinaryDataList: IBinaryDataListStatic
    );
  end;

implementation

uses
  SysUtils,
  libcrc32,
  u_IDInterfaceList,
  u_BinaryDataListStatic;

{ TPredicateByStaticList }

constructor TPredicateByStaticSampleList.Create(
  const ABinaryDataList: IBinaryDataListStatic
);
var
  i: Integer;
  VSample: IBinaryData;
begin
  Assert(ABinaryDataList <> nil);
  inherited Create;
  FListBySize := TIDInterfaceList.Create;
  for i := 0 to ABinaryDataList.Count - 1 do begin
    VSample := ABinaryDataList.Item[i];
    if VSample.Size > 0 then begin
      AppendSample(VSample);
    end;
  end;
end;

procedure TPredicateByStaticSampleList.AppendSample(const ASample: IBinaryData);
var
  VHash: Integer;
  VBySize: IInterface;
  VHashList: IIDInterfaceList;
  VByHash: IInterface;
  VSample: IBinaryData;
  VSampleList: IBinaryDataListStatic;
  VSampleListNew: IBinaryDataListStatic;
  i: Integer;
  VExists: Boolean;
begin
  VHash := CalcHash(ASample);
  VBySize := FListBySize.GetByID(ASample.Size);
  if Supports(VBySize, IIDInterfaceList, VHashList) then begin
    VByHash := VHashList.GetByID(VHash);
    if VByHash <> nil then begin
      if Supports(VByHash, IBinaryData, VSample) then begin
        if not CompareData(VSample, ASample) then begin
          VSampleListNew := TBinaryDataListStatic.CreateByTwoItems(VSample, ASample);
          VHashList.Replace(VHash, VSampleListNew);
        end;
      end else if Supports(VByHash, IBinaryDataListStatic, VSampleList) then begin
        VExists := False;
        for i := 0 to VSampleList.Count - 1 do begin
          VSample := VSampleList.Item[i];
          if CompareData(VSample, ASample) then begin
            VExists := True;
            Break;
          end;
        end;
        if not VExists then begin
          VSampleListNew := TBinaryDataListStatic.CreateBySource(VSampleList, ASample);
          VHashList.Replace(VHash, VSampleListNew);
        end;
      end;
    end else begin
      VHashList.Add(VHash, ASample);
    end;
  end else begin
    VHashList := TIDInterfaceList.Create;
    VHashList.Add(VHash, ASample);
    FListBySize.Add(ASample.Size, VHashList);
  end;
end;

function TPredicateByStaticSampleList.CompareData(const AData1,
  AData2: IBinaryData): Boolean;
begin
  Assert(AData1 <> nil);
  Assert(AData2 <> nil);
  Assert(AData1.Size > 0);
  Assert(AData1.Size = AData2.Size);
  Result := CompareMem(AData1.Buffer, AData2.Buffer, AData1.Size);
end;

function TPredicateByStaticSampleList.CalcHash(
  const AData: IBinaryData): Integer;
begin
  Assert(AData <> nil);
  Assert(AData.Size > 0);
  Result := Integer(crc32(0, AData.Buffer, AData.Size));
end;

function TPredicateByStaticSampleList.Check(const AData: IBinaryData): Boolean;
var
  VBySize: IInterface;
  VByHash: IInterface;
  VHashList: IIDInterfaceList;
  VSampleList: IBinaryDataListStatic;
  VSample: IBinaryData;
  VHash: Integer;
  i: Integer;
begin
  Result := False;
  VBySize := FListBySize.GetByID(AData.Size);
  if Supports(VBySize, IIDInterfaceList, VHashList) then begin
    VHash := CalcHash(AData);
    VByHash := VHashList.GetByID(VHash);
    if VByHash <> nil then begin
      if Supports(VByHash, IBinaryData, VSample) then begin
        Result := CompareData(AData, VSample);
      end else if Supports(VByHash, IBinaryDataListStatic, VSampleList) then begin
        for i := 0 to VSampleList.Count - 1 do begin
          VSample := VSampleList.Item[i];
          if CompareData(AData, VSample) then begin
            Result := True;
            Break;
          end;
        end;
      end;
    end;
  end;
end;

end.

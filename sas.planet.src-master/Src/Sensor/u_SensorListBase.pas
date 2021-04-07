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

unit u_SensorListBase;

interface

uses
  ActiveX,
  i_GUIDSet,
  i_SensorList,
  u_ChangeableBase;

type
  TSensorListBase = class(TChangeableBase, ISensorList)
  private
    FList: IGUIDInterfaceSet;
  private
    function GetGUIDEnum: IEnumGUID;
    function Get(const AGUID: TGUID): ISensorListEntity;
  protected
    procedure Add(const AItem: ISensorListEntity);
  public
    constructor Create;
  end;

implementation

uses
  u_GUIDInterfaceSet,
  u_ReadWriteSyncAbstract;

{ TSensorListBase }

constructor TSensorListBase.Create;
begin
  inherited Create(TSynchronizerFake.Create);
  FList := TGUIDInterfaceSet.Create(False);
end;

procedure TSensorListBase.Add(const AItem: ISensorListEntity);
begin
  if not FList.IsExists(AItem.GUID) then begin
    FList.Add(AItem.GUID, AItem);
  end;
end;

function TSensorListBase.Get(const AGUID: TGUID): ISensorListEntity;
begin
  Result := ISensorListEntity(FList.GetByGUID(AGUID));
end;

function TSensorListBase.GetGUIDEnum: IEnumGUID;
begin
  Result := FList.GetGUIDEnum;
end;

end.

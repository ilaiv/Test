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

unit u_MarkPictureListSimple;

interface

uses
  Classes,
  SysUtils,
  i_HashFunction,
  i_PathConfig,
  i_ContentTypeManager,
  i_MarkPicture,
  i_MarkPictureConfig,
  i_BitmapTileSaveLoad,
  u_BaseInterfacedObject;

type
  TMarkPictureListSimple = class(TBaseInterfacedObject, IMarkPictureList, IMarkPictureListInternal)
  private
    FHashFunction: IHashFunction;
    FCS: IReadWriteSync;
    FBaseList: TStringList;
    FRuntimeList: TStringList;
    FRuntimeFailList: TStringList;
    FBasePath: IPathConfig;
    FMediaDataPath: IPathConfig;
    FContentTypeManager: IContentTypeManagerBitmap;
    FMarkPictureConfig: IMarkPictureConfig;
    procedure Clear;
    function _GetFromRuntimeList(AIndex: Integer): IMarkPicture;
    function _TryAddToRuntimeList(const AValue: string): Integer;
  private
    { IMarkPictureList }
    procedure LoadList;

    function GetCount: Integer;

    function Get(AIndex: Integer): IMarkPicture;
    function GetName(AIndex: Integer): string;
    function GetIndexByName(const AValue: string): Integer;

    function GetDefaultPicture: IMarkPicture;
    function FindByName(const AValue: string): IMarkPicture;
    function FindByNameOrDefault(const AValue: string): IMarkPicture;
  public
    constructor Create(
      const AHashFunction: IHashFunction;
      const AMarkPictureConfig: IMarkPictureConfig;
      const ABasePath: IPathConfig;
      const AMediaDataPath: IPathConfig;
      const AContentTypeManager: IContentTypeManagerBitmap
    );
    destructor Destroy; override;
  end;

implementation

uses
  StrUtils,
  t_Hash,
  t_GeoTypes,
  c_MarkPictureAnchor,
  c_InternalBrowser,
  u_Synchronizer,
  u_MarkPictureSimple;

procedure GetFilesList(
  const APath, AMask: string;
  var AList: TStringList
);
const
  cFileMask = '*.*';
var
  VRec: TSearchRec;
  VPath: string;
begin
  VPath := IncludeTrailingPathDelimiter(APath);
  if FindFirst(VPath + cFileMask, faAnyFile - faDirectory, VRec) = 0 then begin
    try
      repeat
        if AnsiPos(ExtractFileExt(VRec.Name), AMask) > 0 then begin
          AList.Add(VPath + VRec.Name);
        end;
      until FindNext(VRec) <> 0;
    finally
      FindClose(VRec);
    end;
  end;
  if FindFirst(VPath + cFileMask, faDirectory, VRec) = 0 then begin
    try
      repeat
        if ((VRec.Attr and faDirectory) <> 0) and (VRec.Name <> '.') and (VRec.Name <> '..') then begin
          GetFilesList(VPath + VRec.Name, AMask, AList);
        end; // recursion
      until FindNext(VRec) <> 0;
    finally
      FindClose(VRec);
    end;
  end;
end;

procedure ListSetUp(AList: TStringList);
begin
  AList.Sorted := False; // http://www.sasgis.org/mantis/view.php?id=2747
  AList.CaseSensitive := False;
  AList.Duplicates := dupIgnore;
end;

{ TMarkPictureListSimple }

constructor TMarkPictureListSimple.Create(
  const AHashFunction: IHashFunction;
  const AMarkPictureConfig: IMarkPictureConfig;
  const ABasePath: IPathConfig;
  const AMediaDataPath: IPathConfig;
  const AContentTypeManager: IContentTypeManagerBitmap
);
begin
  Assert(AMarkPictureConfig <> nil);

  inherited Create;
  FMarkPictureConfig := AMarkPictureConfig;
  FHashFunction := AHashFunction;
  FBasePath := ABasePath;
  FMediaDataPath := AMediaDataPath;
  FContentTypeManager := AContentTypeManager;

  FCS := GSync.SyncStd.Make(Self.ClassName);
  FBaseList := TStringList.Create;
  FRuntimeList := TStringList.Create;
  FRuntimeFailList := TStringList.Create;

  ListSetUp(FBaseList);
  ListSetUp(FRuntimeList);
  ListSetUp(FRuntimeFailList);
end;

destructor TMarkPictureListSimple.Destroy;
begin
  Clear;
  FreeAndNil(FBaseList);
  FreeAndNil(FRuntimeList);
  FreeAndNil(FRuntimeFailList);
  inherited;
end;

procedure TMarkPictureListSimple.Clear;
var
  I: Integer;
begin
  if Assigned(FBaseList) then begin
    for I := 0 to FBaseList.Count - 1 do begin
      IInterface(Pointer(FBaseList.Objects[I]))._Release;
    end;
    FBaseList.Clear;
  end;

  if Assigned(FRuntimeList) then begin
    for I := 0 to FRuntimeList.Count - 1 do begin
      IInterface(Pointer(FRuntimeList.Objects[I]))._Release;
    end;
    FRuntimeList.Clear;
  end;
end;

procedure TMarkPictureListSimple.LoadList;
const
  cExtList: array [0..2] of string = ('.png', '.jpg', '.jpeg');
var
  I: Integer;
  VFilesList: TStringList;
  VLoader: IBitmapTileLoader;
  VPicture: IMarkPicture;
  VFullName: string;
  VShortName: string;
  VPath: string;
  VHash: THashValue;
  VAnchor: TDoublePoint;
begin
  inherited;
  Clear;

  VPath := IncludeTrailingPathDelimiter(FBasePath.FullPath);
  VFilesList := TStringList.Create;
  try
    GetFilesList(VPath, '.png;.jpg;.jpeg', VFilesList);

    for I := 0 to VFilesList.Count - 1 do begin
      VLoader := nil;

      VFullName := VFilesList.Strings[I];
      VShortName := StringReplace(VFullName, VPath, '', [rfIgnoreCase]);
      VLoader := FContentTypeManager.GetBitmapLoaderByFileName(VFullName);

      if not Assigned(VLoader) then begin
        Continue;
      end;

      VAnchor := FMarkPictureConfig.GetAnchor(VFullName);
      VHash := FHashFunction.CalcHashByString(VFullName);

      VPicture :=
        TMarkPictureSimple.Create(
          VHash,
          VFullName,
          VShortName,
          VLoader,
          VAnchor
        );
      VPicture._AddRef;

      FBaseList.AddObject(VShortName, TObject(Pointer(VPicture)));
    end;
  finally
    VFilesList.Free;
  end;
end;

function TMarkPictureListSimple.FindByName(
  const AValue: string
): IMarkPicture;
var
  VIndex: Integer;
  VTryLoadPictureInRuntime: Boolean;
begin
  Result := nil;

  if AValue <> '' then begin
    VIndex := FBaseList.IndexOf(AValue);
    if VIndex >= 0 then begin
      Result := IMarkPicture(Pointer(FBaseList.Objects[VIndex]));
    end else begin
      VTryLoadPictureInRuntime := False;

      FCS.BeginRead;
      try
        VIndex := FRuntimeList.IndexOf(AValue);
        if VIndex >= 0 then begin
          Result := _GetFromRuntimeList(VIndex);
        end else begin
          VIndex := FRuntimeFailList.IndexOf(AValue);
          if VIndex < 0 then begin
            VTryLoadPictureInRuntime := True;
          end;
        end;
      finally
        FCS.EndRead;
      end;

      if VTryLoadPictureInRuntime then begin
        FCS.BeginWrite;
        try
          VIndex := _TryAddToRuntimeList(AValue);
          if VIndex >= 0 then begin
            Result := _GetFromRuntimeList(VIndex);
          end;
        finally
          FCS.EndWrite;
        end;
      end;
    end;
  end;
end;

function TMarkPictureListSimple.FindByNameOrDefault(
  const AValue: string
): IMarkPicture;
begin
  Result := FindByName(AValue);
  if not Assigned(Result) then begin
    Result := GetDefaultPicture;
  end;
end;

function TMarkPictureListSimple.Get(AIndex: Integer): IMarkPicture;
begin
  if AIndex < FBaseList.Count then begin
    Result := IMarkPicture(Pointer(FBaseList.Objects[AIndex]));
  end else begin
    Dec(AIndex, FBaseList.Count);
    FCS.BeginRead;
    try
      Assert(AIndex < FRuntimeList.Count);
      Result := _GetFromRuntimeList(AIndex);
    finally
      FCS.EndRead;
    end;
  end;
end;

function TMarkPictureListSimple.GetCount: Integer;
begin
  Result := FBaseList.Count;
end;

function TMarkPictureListSimple.GetDefaultPicture: IMarkPicture;
begin
  Result := nil;
  if FBaseList.Count > 0 then begin
    Result := IMarkPicture(Pointer(FBaseList.Objects[0]));
  end;
end;

function TMarkPictureListSimple.GetIndexByName(const AValue: string): Integer;
begin
  Result := FBaseList.IndexOf(AValue);
  if Result < 0 then begin
    FCS.BeginRead;
    try
      Result := FRuntimeList.IndexOf(AValue);
    finally
      FCS.EndRead;
    end;
    if Result >= 0 then begin
      Inc(Result, FBaseList.Count);
    end;
  end;
  if Result < 0 then begin
    FCS.BeginWrite;
    try
      Result := _TryAddToRuntimeList(AValue);
    finally
      FCS.EndWrite;
    end;
    if Result >= 0 then begin
      Inc(Result, FBaseList.Count);
    end;
  end;
end;

function TMarkPictureListSimple.GetName(AIndex: Integer): string;
begin
  if AIndex < FBaseList.Count then begin
    Result := FBaseList.Strings[AIndex];
  end else begin
    Dec(AIndex, FBaseList.Count);
    FCS.BeginRead;
    try
      Assert(AIndex < FRuntimeList.Count);
      Result := FRuntimeList.Strings[AIndex];
    finally
      FCS.EndRead;
    end;
  end;
end;

function TMarkPictureListSimple._GetFromRuntimeList(AIndex: Integer): IMarkPicture;
begin
  Result := IMarkPicture(Pointer(FRuntimeList.Objects[AIndex]));
end;

function TMarkPictureListSimple._TryAddToRuntimeList(const AValue: string): Integer;
var
  VLoader: IBitmapTileLoader;
  VPicture: IMarkPicture;
  VFullName: string;
  VShortName: string;
  VHash: THashValue;
begin
  Result := -1;

  if FRuntimeFailList.IndexOf(AValue) >= 0 then begin
    Exit;
  end;

  if StartsText(CMediaDataInternalURL, AValue) then begin
    VFullName := StringReplace(
      AValue,
      CMediaDataInternalURL,
      IncludeTrailingPathDelimiter(FMediaDataPath.FullPath),
      [rfIgnoreCase]
    );
    if not FileExists(VFullName) then begin
      VFullName := '';
    end;
    VShortName := AValue;
  end else if FileExists(AValue) then begin
    VFullName := AValue;
    VShortName := VFullName;
  end else begin
    VFullName := '';
  end;

  if VFullName <> '' then begin
    try
      VLoader := FContentTypeManager.GetBitmapLoaderByFileName(VFullName);
      if not Assigned(VLoader) then begin
        FRuntimeFailList.Add(AValue);
        Assert(False, 'GetLoaderByExt failed for file: ' + VFullName);
        Exit;
      end;

      VHash := FHashFunction.CalcHashByString(VFullName);
      VPicture := TMarkPictureSimple.Create(
        VHash,
        VFullName,
        VShortName,
        VLoader,
        cPicAnchorCenter
      );
      VPicture._AddRef;
      Result := FRuntimeList.AddObject(VShortName, TObject(Pointer(VPicture)));
    except
      on E: Exception do begin
        FRuntimeFailList.Add(AValue);
        Assert(False, E.ClassName + ': ' + E.Message);
      end;
    end;
  end else begin
    FRuntimeFailList.Add(AValue);
  end;
end;

end.

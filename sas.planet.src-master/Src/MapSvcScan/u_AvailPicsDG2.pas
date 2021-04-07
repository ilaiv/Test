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

unit u_AvailPicsDG2;

interface

uses
  SysUtils,
  Classes,
  i_InetConfig,
  i_ProjectionSet,
  i_MapSvcScanStorage,
  i_MapSvcScanConfig,
  i_DownloadResult,
  i_DownloadRequest,
  u_DownloadRequest,
  u_AvailPicsAbstract;

type
  TAvailPicsdg2 = class(TAvailPicsByKey)
  private
    FMapSvcScanConfig: IMapSvcScanConfig;
  public
    constructor Create(
      const AProjectionSet: IProjectionSet;
      const ATileInfoPtr: PAvailPicsTileInfo;
      const AMapSvcScanStorage: IMapSvcScanStorage;
      const AMapSvcScanConfig: IMapSvcScanConfig
    );

    procedure AfterConstruction; override;

    function ContentType: String; override;

    function ParseResponse(const AResultOk: IDownloadResultOk): Integer; override;

    function GetRequest(const AInetConfig: IInetConfig): IDownloadRequest; override;
  end;


implementation

uses
  IniFiles,
  ALString,
  xmldom,
  i_PathConfig,
  i_ConfigDataProvider,
  u_XmlLoaderByVSAGPS,
  u_StreamReadOnlyByBinaryData,
  u_GeoToStrFunc,
  u_ConfigDataProviderByIniFile;

function SkipNodeByLCName(const ANodeNameLC: String): Boolean;

begin
  Result := False;

  if (ANodeNameLC = 'agedays') then begin
    Inc(Result);
    Exit;
  end;

  if (ANodeNameLC = 'copyright') then begin
    Inc(Result);
    Exit;
  end;

  // asset*
  if (Length(ANodeNameLC) > 5) and (Copy(ANodeNameLC, 1, 5) = 'asset') then begin
    Inc(Result);
    Exit;
  end;

  // perPixel*
  if (Length(ANodeNameLC) > 8) and (Copy(ANodeNameLC, 1, 8) = 'perpixel') then begin
    Inc(Result);
    Exit;
  end;

  // *Unit
  if (Length(ANodeNameLC) > 4) and (Copy(ANodeNameLC, Length(ANodeNameLC) - 3, 4) = 'unit') then begin
    Inc(Result);
    Exit;
  end;
end;

procedure ReplaceOneNodeName(const ASL: TStrings; const AOldName, ANewName: String);
var
  i: Integer;
begin
  // only if new name not found
  if (ASL.IndexOfName(ANewName) >= 0) then
    Exit;
  // get old name index
  i := ASL.IndexOfName(AOldName);
  if (i < 0) then
    Exit;
  ASL[i] := ANewName + ASL.NameValueSeparator + ASL.ValueFromIndex[i];
end;

procedure ReplaceNodeNames(const ASL: TStrings);
begin
  ReplaceOneNodeName(ASL, 'groundSampleDistance', 'Resolution');
  ReplaceOneNodeName(ASL, 'productType', 'Color');
  ReplaceOneNodeName(ASL, 'companyName', 'Provider');
  ReplaceOneNodeName(ASL, 'geometry', 'VposList');
  ReplaceOneNodeName(ASL, 'acquisitionDate', 'Date');
end;

{ TAvailPicsDG2 }

constructor TAvailPicsdg2.Create(
  const AProjectionSet: IProjectionSet;
  const ATileInfoPtr: PAvailPicsTileInfo;
  const AMapSvcScanStorage: IMapSvcScanStorage;
  const AMapSvcScanConfig: IMapSvcScanConfig
);
begin
  Assert(AMapSvcScanConfig <> nil);
  inherited Create(AProjectionSet, ATileInfoPtr, AMapSvcScanStorage);
  FMapSvcScanConfig := AMapSvcScanConfig;
end;

procedure TAvailPicsdg2.AfterConstruction;
begin
  inherited;
//  FDefaultKey := '/b42d085,`5cd,353/,7`6b,a0ca6644ce/4';
  FDefaultKey := '6`d/6dc6,c`1c,3c54,`b/3,711/a1/b0a82';

end;

function TAvailPicsdg2.ContentType: String;
begin
  Result := 'text/xml';
end;

function TAvailPicsdg2.ParseResponse(const AResultOk: IDownloadResultOk): Integer;
var
  VStream: TStreamReadOnlyByBinaryData;
  VDOMDocument: IDOMDocument;
  VNode: IDOMNode;
  VPlacemarkNode: IDOMNode;
  VSubNode: IDOMNode;
  VGeometryNode: IDOMNode;
  VNodeName: String;
  VNodeText: String;

  VDate, VfeatureId, VlegacyId: String;
  //VSampleDistance, VcompanyName : String;
  //Vsource, VproductType, VdataLayer : String;
  VposList: String;
  VAddResult: Boolean;
  VParams: TStrings;
  VItemIdentifier: String;
  VItemExisting: Boolean;
  VItemFetched: TDateTime;
begin
  Result := 0;

  if (not Assigned(FTileInfoPtr.AddImageProc)) then
    Exit;

  VStream := TStreamReadOnlyByBinaryData.Create(AResultOk.Data);
  try
    if (0 = VStream.Size) then
      Exit;

    if not LoadXmlDomDocFromStream(VDOMDocument, VStream) then
      Exit;

    // wfs:FeatureCollection
    VNode := VDOMDocument.firstChild;
    if (nil = VNode) then
      Exit;
    VNode := VNode.nextSibling;
    if (nil = VNode) then
      Exit;

    // gml:featureMembers
    VPlacemarkNode := VNode.firstChild;
    // DigitalGlobe:FinishedFeature
    VPlacemarkNode := VPlacemarkNode.firstChild;
    while Assigned(VPlacemarkNode) do begin
      // check name
      if VPlacemarkNode.nodeName = 'DigitalGlobe:FinishedFeature' then begin
        // found
        VParams := TStringList.Create;
        try
          VposList := '';
          VSubNode := VPlacemarkNode.firstChild;
          while Assigned(VSubNode) do begin
            // get name and text for every node
            VNodeName := VSubNode.nodeName;
            VNodeName := StringReplace(VNodeName, 'DigitalGlobe:', '', []);
            // check for geometry
            if SameText(VNodeName, 'geometry') then begin
              // get geometry
              VGeometryNode := VSubNode.firstChild;
              // gml:Polygon -> gml:exterior -> gml:LinearRing -> gml:posList
              while (VGeometryNode.firstChild <> nil) do begin
                VGeometryNode := VGeometryNode.firstChild;
              end;
              if (VGeometryNode <> nil) then begin
                // #text
                VNodeText := VGeometryNode.nodeValue;
                VGeometryNode := nil;
              end else begin
                VNodeText := '';
              end;
            end else if SkipNodeByLCName(LowerCase(VNodeName)) then begin
              // skipped tags
              VNodeText := '';
            end else begin
              // common tag
              VNodeText := GetXmlNodeText(VSubNode);
            end;

            // add only with values (but skip 'false')
            if (0 < Length(VNodeText)) and (VNodeText <> 'false') then begin
              VParams.Values[VNodeName] := VNodeText;
            end;

            // next
            VSubNode := VSubNode.nextSibling;
          end;

          // prepare date
          VDate := GetDateCaptionFromParams(VParams);

          if (0 < Length(VDate)) then begin
            // has date
            VlegacyId := VParams.Values['legacyId'];
            VfeatureId := VParams.Values['featureId'];

            // add urls
            if (0 < Length(VlegacyId)) then begin
              VParams.Values['IMAGE_FILE_URL'] := 'https://browse.digitalglobe.com/imagefinder/showBrowseImage?catalogId=' + VlegacyId + '&imageHeight=1024&imageWidth=1024';
              VParams.Values['METADATA_URL'] := 'https://browse.digitalglobe.com/imagefinder/showBrowseMetadata?buffer=1.0&catalogId=' + VlegacyId + '&imageHeight=natres&imageWidth=natres';
            end;

            // replace some node names
            ReplaceNodeNames(VParams);

            VItemIdentifier := VfeatureId;
            if (Length(VItemIdentifier) <= 16) then begin
              VItemIdentifier := VItemIdentifier + '_' + VlegacyId;
            end;

            VItemExisting := ItemExists(FBaseStorageName, VItemIdentifier, @VItemFetched);
            StoreImageDate(VItemIdentifier, VDate);

            VAddResult := FTileInfoPtr.AddImageProc(
              Self,
              VDate,
              'DigitalGlobe',
              VItemExisting,
              VItemFetched,
              VParams
            );
            if VAddResult then begin
              Inc(Result);
            end;
          end;
        finally
          FreeAndNil(VParams);
        end;
      end;
      // next
      VPlacemarkNode := VPlacemarkNode.nextSibling;
    end;
  finally
    VStream.Free;
  end;
end;

function TAvailPicsdg2.GetRequest(const AInetConfig: IInetConfig): IDownloadRequest;
var
  VLink: AnsiString;
  key: AnsiString;
  i: integer;
  VConfigPath: IPathConfig;
  VIniFileName: string;
  VIniFile: TMeminiFile;
  VConfig: IConfigDataProvider;
  VSectionDG2: IConfigDataProvider;
begin
  Key:= FDefaultKey;
  for i := 1 to Length(Key) do begin
    Key[i] := AnsiChar(Ord(Key[i]) + 1);
  end;

  VConfigPath := FMapSvcScanConfig.Path;
  VIniFileName := IncludeTrailingPathDelimiter(VConfigPath.FullPath) + 'MapSvcScan.ini';

  if FileExists(VIniFileName) then begin
    VIniFile := TMeminiFile.Create(VIniFileName);
    VConfig := TConfigDataProviderByIniFile.CreateWithOwn(VIniFile);
    VSectionDG2 := VConfig.GetSubItem('DG2');
    if VSectionDG2 <> nil then
      key := VSectionDG2.ReadAnsiString('key', key);
  end;

  // zoom 15 - 256x256
  // zoom 14 - 512x512
  // etc
  i := 256;
  if FTileInfoPtr.Zoom<14 then begin
    i := i shl (14-FTileInfoPtr.Zoom);
  end;
  VLink := ALIntToStr(i);

  VLink  := 'https://services.digitalglobe.com/catalogservice/wfsaccess?WIDTH=' + VLink + '&HEIGHT=' + VLink + '&CONNECTID=' + Key +
            '&MAXFEATURES=500&SERVICE=WFS&REQUEST=GetFeature&TYPENAME=DigitalGlobe:FinishedFeature&VERSION=1.1.0&BBOX='+
            RoundExAnsi(FTileInfoPtr.TileRect.Bottom, 8) + ','+
            RoundExAnsi(FTileInfoPtr.TileRect.Left, 8) + ','+
            RoundExAnsi(FTileInfoPtr.TileRect.Top, 8) + ','+
            RoundExAnsi(FTileInfoPtr.TileRect.Right, 8);

 Result := TDownloadRequest.Create(
           VLink,
           '',
           AInetConfig.GetStatic
           );

end;

end.

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

unit u_AvailPicsRosCosmos;

interface

uses
  SysUtils,
  Classes,
  XMLIntf,
  XMLDoc,
  i_InetConfig,
  i_ProjectionSet,
  i_DownloadResult,
  i_DownloadRequest,
  i_MapSvcScanConfig,
  i_MapSvcScanStorage,
  i_DownloaderFactory,
  u_DownloadRequest,
  u_AvailPicsAbstract,
  u_BinaryData;

type
  TAvailPicsRC = class(TAvailPicsAbstract)
  private
    FIdRepository: Integer;
    FSatName: string;
    FMapSvcScanConfig: IMapSvcScanConfig;
    function MakeSignInPostString: AnsiString; // ������������ Post ������ ��� ������������� �� ����
    function MakePostString: AnsiString;
    function LonLatToMeterRosCosmos: AnsiString;
  public
    function ContentType: String; override;
    function ParseResponse(const AResultOk: IDownloadResultOk): Integer; override;
    function GetRequest(const AInetConfig: IInetConfig): IDownloadRequest; override;
  end;

  TAvailPicsRosCosmosID = (rcRES_DK1=1, rcCanopus_PSS=2, rcMeteor_M1=3, rcCanopus_MSS=4);
  TAvailPicsRosCosmos = array [TAvailPicsRosCosmosID] of TAvailPicsRC;

procedure GenerateAvailPicsRC(
  var ARCs: TAvailPicsRosCosmos;
  const ADownloaderFactory: IDownloaderFactory;
  const ATileInfoPtr: PAvailPicsTileInfo;
  const AProjectionSet: IProjectionSet;
  const AMapSvcScanConfig: IMapSvcScanConfig;
  const AMapSvcScanStorage: IMapSvcScanStorage
);

implementation

uses
  Forms,
  Windows,
  ALString,
  t_GeoTypes,
  i_BinaryData,
  i_ProjectionType,
  i_Downloader,
  i_NotifierOperation,
  u_NotifierOperation,
  u_GeoToStrFunc;

procedure GenerateAvailPicsRC(
  var ARCs: TAvailPicsRosCosmos;
  const ADownloaderFactory: IDownloaderFactory;
  const ATileInfoPtr: PAvailPicsTileInfo;
  const AProjectionSet: IProjectionSet;
  const AMapSvcScanConfig: IMapSvcScanConfig;
  const AMapSvcScanStorage: IMapSvcScanStorage
);
var
  j: TAvailPicsRosCosmosID;
begin
  for j := Low(TAvailPicsRosCosmosID) to High(TAvailPicsRosCosmosID) do begin
    if (nil=ARCs[j]) then begin
      ARCs[j] := TAvailPicsRC.Create(AProjectionSet, ATileInfoPtr, AMapSvcScanStorage, ADownloaderFactory);
      ARCs[j].FMapSvcScanConfig := AMapSvcScanConfig;
      // switch by repository
      case Ord(j) of
      // ������ ��1
      1: begin
          ARCs[j].FBaseStorageName := 'RC_RES';
          ARCs[j].FIdRepository :=16;
          ARCs[j].FSatName := 'Resurs-DK';
         end;
      // ������� � (���)  �� ������
      2: begin
          ARCs[j].FBaseStorageName := 'RC_CANP';
          ARCs[j].FIdRepository :=147;
          ARCs[j].FSatName := 'Canopus-B_PSS';
         end;
      // ������ �1
      3: begin
          ARCs[j].FBaseStorageName := 'RC_MET';
          ARCs[j].FIdRepository :=39;
          ARCs[j].FSatName := 'Meteor-M1';
         end;
      // ������� � (���) ������� ������
      4: begin
          ARCs[j].FBaseStorageName := 'RC_CANM';
          ARCs[j].FIdRepository :=148;
          ARCs[j].FSatName := 'Canopus-B_MSS';
         end;
      else
        ARCs[j].FIdRepository := 0;
      end;

    end;
  end;
end;

{ TAvailPicsRC }

function TAvailPicsRC.LonLatToMeterRosCosmos: AnsiString;
const
  c_Roscosmos_Precision = 6;
var
  VProjectionType: IProjectionType;
  VLonLatPoint: TDoublePoint;
  VLonLatMetr: TDoublePoint;
  VStartingPoint: AnsiString;
begin
  // ��������� BBox �� LonLat � ����� � ����� ��������� ������ ������ ��� �������
  VProjectionType := FLocalConverter.Projection.ProjectionType;

  // TopLeft
  VLonLatPoint := FTileInfoPtr^.TileRect.TopLeft;
  VLonLatMetr := VProjectionType.LonLat2Metr(VLonLatPoint);
  Result := RoundExAnsi(VLonLatMetr.X, c_Roscosmos_Precision) + ' '+RoundExAnsi(VLonLatMetr.Y, c_Roscosmos_Precision);
  VStartingPoint := Result;

  // TopRight
  VLonLatPoint.X := FTileInfoPtr.TileRect.Right;
  VLonLatMetr := VProjectionType.LonLat2Metr(VLonLatPoint);
  Result := Result + ',' + RoundExAnsi(VLonLatMetr.X, c_Roscosmos_Precision) + ' '+RoundExAnsi(VLonLatMetr.Y, c_Roscosmos_Precision);

  // BottomRight
  VLonLatPoint.Y := FTileInfoPtr.TileRect.Bottom;
  VLonLatMetr := VProjectionType.LonLat2Metr(VLonLatPoint);
  Result := Result + ',' + RoundExAnsi(VLonLatMetr.X, c_Roscosmos_Precision) + ' '+RoundExAnsi(VLonLatMetr.Y, c_Roscosmos_Precision);

  // BottomLeft
  VLonLatPoint.X := FTileInfoPtr.TileRect.Left;
  VLonLatMetr := VProjectionType.LonLat2Metr(VLonLatPoint);
  Result := Result + ',' + RoundExAnsi(VLonLatMetr.X, c_Roscosmos_Precision) + ' '+RoundExAnsi(VLonLatMetr.Y, c_Roscosmos_Precision);

  // TopLeft
  Result := Result + ',' + VStartingPoint;
end;


function TAvailPicsRC.MakePostString: AnsiString;
begin
  Result := 'scaleLevel='+ ALIntToStr(FTileInfoPtr.Zoom) +
            '&idRepository=' + ALIntToStr(FIdRepository) +
            '&screenGeometry=POLYGON((' +
            LonLatToMeterRosCosmos +
            '))&visibleIds=&onlyVisible=0';
end;


function TAvailPicsRC.MakeSignInPostString: AnsiString;
begin
  Result := 'username='+ AnsiString(FMapSvcScanConfig.RosCosmosUserName) +
            '&password='+ AnsiString(FMapSvcScanConfig.RosCosmosPassword) +
            '&login=%D0%92%D0%BE%D0%B9%D1%82%D0%B8';
end;

function TAvailPicsRC.ContentType: String;
begin
  Result := 'text/html';
end;

function TAvailPicsRC.ParseResponse(const AResultOk: IDownloadResultOk): Integer;
var
  XMLDocument: TXMLDocument;
  Node: IXMLNode;
  PlacemarkNode: IXMLNode;
  VDate,
  VPosList,
  VId,
  VDateTime,
  VGeometry,
  VSurvayDate: String;
  VAddResult: Boolean;
  i: Integer;
  VParams: TStrings;
  VMemoryStream: TMemoryStream;
  VItemExists: Boolean;
  VItemFetched: TDateTime;
begin
  Result := 0;
  if (not Assigned(FTileInfoPtr.AddImageProc)) then
    Exit;

  VMemoryStream := TMemoryStream.Create;
  try
    //VMemoryStream.Position:=0;
    VMemoryStream.SetSize(AResultOk.Data.Size);
    CopyMemory(VMemoryStream.Memory, AResultOk.Data.Buffer, AResultOk.Data.Size);
    if (nil=VMemoryStream.Memory) or (0=VMemoryStream.Size) then
      Exit;

    XMLDocument := TXMLDocument.Create(Application);
    XMLDocument.LoadFromStream(VMemoryStream);
    FreeAndNil(VMemoryStream);

    Node := XMLDocument.DocumentElement; // Geoportal
    if (nil=Node) then
      Exit;
    if (0=Node.ChildNodes.Count) then
      Exit;
    Node := Node.ChildNodes[0];  // Covering Elements
    if (nil=Node) then
      Exit;
    if (0=Node.ChildNodes.Count) then
      Exit;
    Node := Node.ChildNodes[0];  // NewElements

    // TODO: make without FOR!
    if (Node <> nil) and (Node.ChildNodes.Count > 0) then
    for i := 0 to Node.ChildNodes.Count - 1 do begin
      PlacemarkNode := Node.ChildNodes[i];
      if PlacemarkNode.NodeName = 'Element' then begin

        VId := PlacemarkNode.GetAttribute('id');

        VDateTime := PlacemarkNode.GetAttribute('dateTime');
        VGeometry := PlacemarkNode.GetAttribute('geometry');

        // Converting PolyGon from Meter to LonLat
        //VGeometry := MetrToLonLatRosCosmos(VGeometry);
        VSurvayDate := PlacemarkNode.GetAttribute('survaydate');

        try
          VParams := TStringList.Create;
          VDate := GetDateForCaption(VSurvayDate);
          VParams.Values['id'] := VId;
          VParams.Values['dateTime'] := VDateTime;
          VParams.Values['order'] := PlacemarkNode.GetAttribute('order');
          VParams.Values['geometry'] := VGeometry;
          VParams.Values['filename'] := PlacemarkNode.GetAttribute('filename');
          VParams.Values['satellite'] := PlacemarkNode.GetAttribute('satellite');
          VParams.Values['resolution'] := PlacemarkNode.GetAttribute('resolution');
          VParams.Values['survaydate'] := VSurvayDate;
          VParams.Values['minScale'] := PlacemarkNode.GetAttribute('minScale');
          VParams.Values['maxScale'] := PlacemarkNode.GetAttribute('maxScale');
          VParams.Values['idRepository'] := IntToStr(FIdRepository);
          VParams.Values['satName'] := FSatName;
          VParams.Values['ProviderName'] := 'RosCosmos';
          VParams.Values['Provider'] := 'geoportal.ntsomz.ru';

          // ��������� ��� ������ (������ �����)
          VPosList := VDateTime + ' [' + Vid + '] ';

          // ��� ������ � ��������� �� ����� ������������� �� ������������ ��� ��������
          VItemExists := ItemExists(FBaseStorageName, (VPosList + FSatName), @VItemFetched);

          // � ������ ����� � ������������ ������ ��������
          VPosList := VPosList + VParams.Values['satellite'];
          VAddResult := FTileInfoPtr.AddImageProc(
            Self,
            VDate,
            VposList,
            VItemExists,
            VItemFetched,
            VParams);

          FreeAndNil(VParams);

          if VAddResult then begin
            Inc(Result);
          end;

         except
          if (nil<>VParams) then begin
            try
              VParams.Free;
            except

            end;
            VParams := nil;
          end;
        end;
      end;
    end;
  finally
    FreeAndNil(VMemoryStream);
  end;
end;

function TAvailPicsRC.GetRequest(const AInetConfig: IInetConfig): IDownloadRequest;

var
  VPostData: IBinaryData;
  VPostdataStr: Ansistring;
  VDownloader: IDownloader;
  VPostRequest: IDownloadPostRequest; // POST
  VHeader: Ansistring;
  VLink: Ansistring;
  VResult: IDownloadResult;
  VCancelNotifier: INotifierOperation;
  VResultWithRespond: IDownloadResultWithServerRespond;
begin

  VLink := 'http://geoportal.ntsomz.ru/index.php/enter';

  VHeader :='User-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.17 (KHTML, like Gecko) Chrome/24.0.1312.52 Safari/537.17'+#$D#$A+
    'Host: geoportal.ntsomz.ru'+#$D#$A+
    'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'+#$D#$A+
    'Accept-Language: ru-RU,ru;q=0.8,en-US;q=0.6,en;q=0.4'+#$D#$A+
    'Referer: http://geoportal.ntsomz.ru/index.php/enter'+#$D#$A+
    'Connection: Keep-Alive'+#$D#$A+
    'Content-type: application/x-www-form-urlencoded'+#$D#$A+
    'Accept-Charset: windows-1251,utf-8;q=0.7,*;q=0.3'+#$D#$A+
    'Accept-Encoding: identity';

  // ��������� ������ ������� �� ������������� �� �����
  VPostdataStr := MakeSignInPostString;

  VPostData := TBinaryData.CreateByAnsiString(VPostdataStr);
  VPostRequest := TDownloadPostRequest.Create(
                   Vlink,
                   VHeader,
                   VPostData,
                   AInetConfig.GetStatic
                  );

  VDownloader := FDownloaderFactory.BuildDownloader(TRUE, True, False, nil);
  VCancelNotifier := TNotifierOperationFake.Create;
  VResult := VDownloader.DoRequest(
              VPostRequest,
              VCancelNotifier,
              VCancelNotifier.CurrentOperation
             );
   if not Supports(VResult, IDownloadResultWithServerRespond, VResultWithRespond) then Exit;

   // ��������� ������ ������� �� ��������� ������ �������
   VPostDataStr := MakePostString;

   VPostData := TBinaryData.CreateByAnsiString(VPostdataStr);

   VHeader :=
      'User-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.17 (KHTML, like Gecko) Chrome/24.0.1312.52 Safari/537.17'+#$D#$A+
      'Host: geoportal.ntsomz.ru'+#$D#$A+
      'Accept: */*'+#$D#$A+
      'Accept-Language: ru-RU,ru;q=0.8,en-US;q=0.6,en;q=0.4'+#$D#$A+
      'Referer: http://geoportal.ntsomz.ru/assets/js/gp/main.swf'+#$D#$A+
      'Connection: Keep-Alive'+#$D#$A+
      'Content-type: application/x-www-form-urlencoded'+#$D#$A+
      'Accept-Charset: windows-1251,utf-8;q=0.7,*;q=0.3'+#$D#$A+
      //'Accept-Encoding: identity';
      //������ ����� � ����������������� ���� ��� ��������
      'Accept-Encoding: gzip, deflate';

   Result := TDownloadPostRequest.Create(
                'http://geoportal.ntsomz.ru/assets/js/gp/scripts/getCoveringElements.php',
                VHeader,
                VPostData,
                AInetConfig.GetStatic
                 );


end;


end.


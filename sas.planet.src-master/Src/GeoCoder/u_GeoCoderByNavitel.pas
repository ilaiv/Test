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

unit u_GeoCoderByNavitel;

interface

uses
  Classes,
  i_InterfaceListSimple,
  i_NotifierOperation,
  i_LocalCoordConverter,
  i_DownloadRequest,
  i_DownloadResult,
  u_GeoCoderBasic;

type
  TGeoCoderByNavitel = class(TGeoCoderBasic)
  protected
    function PrepareRequest(
      const ASearch: string;
      const ALocalConverter: ILocalCoordConverter
    ): IDownloadRequest; override;
    function ParseResultToPlacemarksList(
      const ACancelNotifier: INotifierOperation;
      AOperationID: Integer;
      const AResult: IDownloadResultOk;
      const ASearch: string;
      const ALocalConverter: ILocalCoordConverter
    ): IInterfaceListSimple; override;
  public
  end;

implementation

uses
  SysUtils,
  ALString,
  RegExprUtils,
  t_GeoTypes,
  i_GeoCoder,
  i_VectorDataItemSimple,
  i_Projection,
  u_InterfaceListSimple,
  u_ResStrings,
  u_GeoToStrFunc;

{ TGeoCoderByNavitel }

function NavitelType(VType: integer): string;
begin
case VType of
  1: Result := '';
  2: Result := '��. ';
  3: Result := '������ ';
  5: Result := '���. ';
  6: Result := '��-� ';
  7: Result := '��-�� ';
  8: Result := '����� ';
  9: Result := '���������� ';
  10: Result := '���������� ';
  11: Result := '���������� ';
  13: Result := '���������� ';
  18: Result := '���������� ';
  20: Result := '������ ';
  24: Result := '����� ';
  27: Result := '���������� ';
  30: Result := '�. ';
  31: Result := '�. ';
  32: Result := '�. ';
  33: Result := '�. ';
  34: Result := '�-� ';
  35: Result := '�.�. ';
  36: Result := '';
  37: Result := '������� ';
  38: Result := '�. ';
  39: Result := '�.�. ';
  40: Result := '���. ';
  41: Result := '�. ';
  42: Result := '�/� ';
  43: Result := '';
  44: Result := '�. ';
  45: Result := '';
  46: Result := '��� ';
  47: Result := '�. ';
  48: Result := '�. ';
  49: Result := '�. ';
  50: Result := '';
  51: Result := '�/� ';
  52: Result := '�.�. ';
  53: Result := '�.�. ';
  54: Result := '�. ';
  55: Result := '�. ';
  56: Result := '�. ';
  57: Result := '�.�. ';
  60: Result := '�. ';
  81: Result := '��. ';
  80: Result := '��. ';
  82: Result := '��. ';
  86: Result := '��. ';
  88: Result := '��. ';
  29: Result := '��. ';
  15: Result := '��-�� ';
  84: Result := '��-�� ';
  85: Result := '��-�� ';
  12: Result := '��-� ';
  87: Result := '��-� ';
  83: Result := '���������� ';
  58: Result := '����. ';
  59: Result := '���. ';
  61: Result := '���. ';
  62: Result := '�.�. ';
  63: Result := '�. ';
  64: Result := '';
  65: Result := '�. ';
  66: Result := '���� ';
  67: Result := '����. ';
  68: Result := '�. ';
  69: Result := '�.�. ';
  70: Result := '';
  71: Result := '�. ';
  72: Result := '�. ';
  73: Result := '';
  74: Result := '';
  75: Result := '�.�. ';
  76: Result := '�. ';
  77: Result := '�.�. ';
  78: Result := '�.���. ';
  79: Result := '�/� ';
  89: Result := '���������� ������� ';
  90: Result := '��������� �������� ';
  91: Result := '��������� ������� ';
  92: Result := '��������� ����������� ';
  93: Result := '������� ����� ';
  94: Result := '��������������� ������� ��� ��������� ';
  95: Result := '��������������� ������ ';
  96: Result := '������� ������������� ������ ';
  97: Result := '��������� ��������� ';
  98: Result := '���� ';
  99: Result := '�������� ';
  100: Result := '������ ������ ';
  101: Result := '������������ ���� ';
  102: Result := '������������ ���� ';
  103: Result := '�������������� ���� ';
  104: Result := '������ ';
  105: Result := '�������� ';
  106: Result := '������ ';
  107: Result := '�������� ';
  108: Result := '���� ��� ';
  109: Result := '�/� ������� �� ���������� ';
  110: Result := '����� ';
  111: Result := '���� ';
  112: Result := '���������� ';
  113: Result := '����-������ ';
  114: Result := '�/� ������� ��� ��������� ';
  115: Result := '���������� ���������� ';
  116: Result := '������� ����� ';
  117: Result := '���������������� ������� ';
  118: Result := '������ ������� ��������� ';
  119: Result := '����������� ������� ��������� ';
  120: Result := '�������� ';
  121: Result := '�������������� ';
  122: Result := '����: Result := ����� ';
  123: Result := '���������: Result := ��������� ';
  124: Result := '���������� ';
  125: Result := '������ ';
  126: Result := '������ ������� ������� ';
  127: Result := '������ ����������� ';
  128: Result := '������ ������ ';
  129: Result := '������ ����� ';
  130: Result := '������ ������ ';
  131: Result := '����������� ������� ';
  132: Result := '�������� ';
  187: Result := '����� ';
  133: Result := '��������� �������� ';
  135: Result := '���������� ������ ';
  137: Result := '���������� ';
  139: Result := '���������: Result := �/� ����� ';
  141: Result := '��������-���� ';
  143: Result := '������� ������� ';
  145: Result := '������� ������� ����� ';
  134: Result := '��������� ������������ ';
  136: Result := '�������� ';
  138: Result := '������������ ';
  140: Result := '���������� ����� ������� Wi-Fi ';
  142: Result := '����� ';
  144: Result := '������������ ������� ';
  146: Result := '������� ������� ������� ';
  147: Result := '������� ��������� ������� ';
  148: Result := '���������� � ������������� ������ ';
  149: Result := '��������� ������� ';
  150: Result := '������� �������� ';
  151: Result := '��������� ������� ';
  152: Result := '��������� ������� ';
  153: Result := '���������� ';
  154: Result := '������������ ';
  155: Result := '������������ ������� ';
  156: Result := '���� ';
  157: Result := '�������� � ��������������� ';
  158: Result := '����������� ������� ';
  159: Result := '�������� (������������ �����) ';
  160: Result := '�������� (��������� �����) ';
  161: Result := '�������� (������) ';
  162: Result := '�������� (��������� �����) ';
  163: Result := '�������� (����������: Result := �����: Result := ��������) ';
  164: Result := '�������� (����������������� �����) ';
  165: Result := '�������� �������� ������� ';
  166: Result := '�������� (����������� �����) ';
  167: Result := '�������� (������������ �����) ';
  168: Result := '�������� ';
  169: Result := '�������� (������������) ';
  170: Result := '�������� (�����) ';
  171: Result := '������� (������������ �������) ';
  172: Result := '���� ';
  173: Result := '�������� (����������� �����) ';
  174: Result := '�������� (�������� �����) ';
  175: Result := '�������� (���������� ��������� �����) ';
  176: Result := '����������� ������� �������� ';
  177: Result := '��������� ';
  178: Result := '����� ��� ������ ';
  179: Result := '����� � ��������� ';
  180: Result := '������� ';
  181: Result := '��������� �����: Result := ��� ������ ';
  182: Result := '������ ��������: Result := ������ ';
  183: Result := '���� ';
  184: Result := '����� ';
  185: Result := '���������� ';
  186: Result := '��������������������� ';
  188: Result := '����/��� ';
  190: Result := '������� ';
  192: Result := '���������� ��� ';
  194: Result := '��������������� ��������� ';
  196: Result := '���/������ ���� ';
  198: Result := '������ ';
  200: Result := '������ �����/������ ';
  202: Result := '����� ';
  189: Result := '�������/�������� ';
  191: Result := '��� ';
  193: Result := '����/������/�������� ';
  195: Result := '����� ';
  197: Result := '��������� ';
  199: Result := '�����-���� ';
  201: Result := '�������-����� ';
  203: Result := '������� ';
  204: Result := '��������/������-����� ';
  205: Result := '���������� �������� ';
  206: Result := '�������� ������ ';
  207: Result := '��������� ';
  208: Result := '����������������� ������� ';
  209: Result := '�������� ����� ';
  210: Result := '�������� ����� ';
  211: Result := '������ ';
  212: Result := '������ ������������� ������ ';
  213: Result := '������ ';
  214: Result := '������ ��� ���� � ���� ';
  215: Result := '������ ';
  216: Result := '������������������ ������� ';
  217: Result := '����������/�� ';
  218: Result := '������ ';
  219: Result := '��� ';
  220: Result := '������ ����������� ';
  221: Result := '���������� ';
  222: Result := '���������� ';
  223: Result := '�������� ��������� ';
  224: Result := '���� ';
  225: Result := '����������� ';
  226: Result := '�������/��������� ��������� ���������� ';
  227: Result := '������ �����: Result := �������: Result := ��� ';
  228: Result := '��������� ������: Result := ��������� ';
  229: Result := '����������� ';
  230: Result := '���� ������: Result := ���������� ��� �������� ';
  231: Result := '�������� ';
  232: Result := '��������� ';
  233: Result := '����� ����� Garmin ';
  234: Result := '������ ���� (���������: Result := ���������) ';
  235: Result := '������-������ ';
  236: Result := '����� ����� ';
  237: Result := '���� ������� ';
  238: Result := '����� ';
  239: Result := '������������ ������ ';
  240: Result := '������� ���������� ';
  241: Result := '��������� ������������� ���������� ';
  242: Result := '��������������� ��� ���������� ������ ';
  243: Result := '��������� ������� ';
  244: Result := '�������� ';
  245: Result := '����� ';
  246: Result := '��� ';
  247: Result := '��������� ��� ���������� ������������ ����������� ';
  248: Result := '����������� ����� ';
  249: Result := '��������������� ���������� ';
  251: Result := '�����-���� ';
  253: Result := '�������: Result := ��������� ';
  255: Result := '��� ';
  257: Result := '��� ';
  259: Result := '������� ';
  261: Result := '����� ��� ������� ';
  263: Result := '���������� ';
  265: Result := '������ ';
  267: Result := '�������� ���� ';
  269: Result := '�������� ��� ';
  250: Result := '�������� ����� ';
  252: Result := '����� ��� ������� ';
  254: Result := '�������� ��� ��� ';
  256: Result := '�������� ';
  258: Result := '�������� ������ ';
  260: Result := '���� ';
  262: Result := '�������� ';
  264: Result := '����������� ';
  266: Result := '��� ';
  268: Result := '������� ';
  270: Result := '������ ���� ';
  271: Result := '����� ��� ������� ';
  272: Result := '�����: Result := ������� ';
  273: Result := '��������� ���� ';
  274: Result := '������� ���� ';
  275: Result := '������������ ������ ';
  276: Result := '�������� ';
  277: Result := '������� �������� ';
  278: Result := '������� �������� ';
  279: Result := '����� �������� ';
  280: Result := '����������� �������� ';
  281: Result := '�������� ';
  282: Result := '������������ ����� ';
  283: Result := '������� ';
  284: Result := '����� ��� �������� ';
  285: Result := '������� ���� (������ �������) ';
  286: Result := '������� ���� (������� �����������) ';
  287: Result := '���������������� ';
  288: Result := '��� ';
  289: Result := '������� ������� ';
  290: Result := '������� ������ ';
  291: Result := '������������� ���������� ';
  292: Result := '���� ';
  293: Result := '������ ';
  294: Result := '�������� ';
  295: Result := '����/������/�������� ';
  296: Result := '������������ ������ ';
  297: Result := '�����������: Result := ���������: Result := ������� ';
  298: Result := '������� ';
  299: Result := '�������� ';
  300: Result := '�������: Result := ���������� ';
  301: Result := '��������� ';
  302: Result := '������� ������ ';
  303: Result := '�����: Result := ������ ';
  304: Result := '������������� ����� ';
  305: Result := '���� ';
  306: Result := '����� ';
  307: Result := '����� ';
  308: Result := '�����: Result := ����� ';
  309: Result := '������ ����� ';
  310: Result := '������/��������� ������� ';
  311: Result := '�������� ����: Result := ������: Result := ������� ';
  312: Result := '����������� ����� ';
  313: Result := '���������� ';
  314: Result := '������ ����������� ';
  315: Result := '������: Result := �������� ����� ';
  316: Result := '�������� ������ ';
  317: Result := '����� ';
  318: Result := '�������� ���� ';
  319: Result := '������������� ����� ';
  320: Result := '������ ';
  321: Result := '����� ';
  322: Result := '������� ';
  323: Result := '������ ';
  324: Result := '������ ';
  325: Result := '������ ';
  326: Result := '������ ';
  327: Result := '����� ';
  328: Result := '������ ';
  329: Result := '������������� ';
  330: Result := '���� ';
  331: Result := '������ ';
  332: Result := '����� ';
  333: Result := '������ ';
  334: Result := '��������� �������� ������ ';
  335: Result := '���� ';
  336: Result := '�����: Result := ������� ';
  337: Result := '��������� ';
  338: Result := '����� ';
  339: Result := '������: Result := ����� ';
  340: Result := '��� ';
  341: Result := '���� ';
  342: Result := '������ ';
  343: Result := '����� ';
  344: Result := '��� ';
  345: Result := '������: Result := �������� ';
  346: Result := '����� ������ ';
  347: Result := '�������� ';
  348: Result := '���� ';
  349: Result := '�����: Result := ������� ';
  350: Result := '������� ';
  351: Result := '����� ';
  352: Result := '���������� ';
  353: Result := '������ ';
  354: Result := '����� ';
  355: Result := '����� ';
  356: Result := '������� ����� ��� ���� ';
  357: Result := '������ ';
  358: Result := '��� ';
  359: Result := '���� ';
  360: Result := '�������� ����� ';
  361: Result := '��������� ';
  362: Result := '�������� ';
  363: Result := '������� ���� (������� �����������) ';
  364: Result := '������� ���� (������ �������) ';
  365: Result := '������� ���� (����� ����) ';
  366: Result := '������������ ���� ����� ';
  367: Result := '������������ ���� ������� ';
  368: Result := '������������ ���� ������ ';
  369: Result := '������������ ���� ������ ';
  370: Result := '������������ ���� ������ ';
  371: Result := '������������ ���� �������� ';
  372: Result := '������������ ���� ������������ ';
  373: Result := '���������� ���� ';
  374: Result := '���������� ���� ����� ';
  375: Result := '���������� ���� ������� ';
  376: Result := '���������� ���� ������ ';
  377: Result := '���������� ���� ������ ';
  378: Result := '���������� ���� ��������� ';
  380: Result := '���������� ���� ����� ';
  379: Result := '���������� ���� ���������� ';
  381: Result := '���������� ���� ������������ ';
  382: Result := '������� ���� ';
  383: Result := '����������� ';
  384: Result := '������ ';
  385: Result := '�������� ';
  386: Result := '����� ��� �������� ';
  387: Result := '�������� ';
  388: Result := '���������� ������������ ��� �������� ';
  389: Result := '�������� ';
  390: Result := '������������ ���� ';
  391: Result := '����������: Result := ���������� ';
  392: Result := '�������-���������� ������ ';
  393: Result := '������: Result := ������������� ���������� ';
  394: Result := '������������ ���� ';
  395: Result := '������������ ���� ';
  396: Result := '������������ ���� ';
  397: Result := '��������� ���� ';
  398: Result := '���� ��� ������ ';
  399: Result := '���������� �������� ';
  400: Result := '�������� ';
  401: Result := '��������������� ���� ';
  402: Result := '��������������� ���� ';
  403: Result := '��������������� ���� ';
  404: Result := '���������� ����� ';
  405: Result := '����� ';
  406: Result := '������ ';
  407: Result := '���������� ';
  408: Result := '��������� ������� ';
  409: Result := '�������� ��������� ';
  410: Result := '�������� ������������� ';
  411: Result := '�������� ������������� ����������� ';
  412: Result := '����� ';
  413: Result := '���������� ';
  414: Result := '����� ';
  415: Result := '������� ';
  416: Result := '������� ';
  417: Result := '��������������� ����� ';
  418: Result := '��������������� ������� ';
  419: Result := '��������������� ��������� ';
  420: Result := '��������������� ���� ';
  421: Result := '������� ';
  422: Result := '������ ';
  423: Result := '���������� ';
  424: Result := '�������� ��������� ';
  425: Result := '������ ';
  426: Result := '���������� '
  else  Result := '';
  end;
end;

function TGeoCoderByNavitel.ParseResultToPlacemarksList(
  const ACancelNotifier: INotifierOperation;
  AOperationID: Integer;
  const AResult: IDownloadResultOk;
  const ASearch: string;
  const ALocalConverter: ILocalCoordConverter
): IInterfaceListSimple;
var
  VLatStr, VLonStr: AnsiString;
  VSName, VFullDesc: string;
  VDescStr: AnsiString;
  VNavitel_ID, VNavitel_Type, VPlace_Id: AnsiString;
  i, j, Vii, Vjj: integer;
  VPoint: TDoublePoint;
  VPlace: IVectorDataItem;
  VList: IInterfaceListSimple;
  VFormatSettings: TALFormatSettings;
  vCurPos: integer;
  vCurChar: AnsiString;
  vBrLevel: integer;
  VBuffer: AnsiString;
  VStr: AnsiString;
  VDesc: string;
  VRequest: IDownloadRequest;
  VResult: IDownloadResult;
  VResultOk: IDownloadResultOk;
begin
  VFullDesc := '';
  VDescStr := '';
  vBrLevel := 1;
  if AResult.Data.Size <= 0 then begin
    raise EParserError.Create(SAS_ERR_EmptyServerResponse);
  end;

  SetLength(Vstr, AResult.Data.Size);
  Move(AResult.Data.Buffer^, Vstr[1], AResult.Data.Size);

  VStr := ALStringReplace(VStr, #$0A, '', [rfReplaceAll]);
  VFormatSettings.DecimalSeparator := '.';
  VList := TInterfaceListSimple.Create;

  vCurPos := 1;
  while (vCurPos<length(VStr)) do begin
    inc (vCurPos);
    vCurChar := copy(VStr, vCurPos, 1);
    VBuffer := VBuffer + vCurChar;
    if vCurChar='[' then Inc(vBrLevel);
    if vCurChar=']' then begin
      dec(vBrLevel);
      if vBrLevel=1 then  begin
        //[848692, ["Москва"], 72, 857666, null],
        //[817088, ["Новая Москва"], 32, null, ["Шкотовский р-н", "Приморский край", "Россия"]],
        VDescStr := '';
        VSName := '';
        VFullDesc := '';
        i := ALPosEx('[', VBuffer, 1);
        j := ALPosEx(',', VBuffer, 1);
        VNavitel_ID := Copy(VBuffer, i + 1, j - (i + 1));
        j := 1;
        i := ALPosEx('[', VBuffer, 1);
        if i>0  then begin
          j := ALPosEx(',', VBuffer, i + 1);
          VRequest :=
            PrepareRequestByURL(
              'http://maps.navitel.su/webmaps/searchTwoStepInfo?id=' + (Copy(VBuffer, i + 1, j - (i + 1)))
            );
          VResult := Downloader.DoRequest(VRequest, ACancelNotifier, AOperationID);
          if Supports(VResult, IDownloadResultOk, VResultOk) then begin
            SetLength(VDescStr, VResultOk.Data.Size);
            Move(VResultOk.Data.Buffer^, VDescStr[1], VResultOk.Data.Size);
            Vii := 1;
            Vjj := ALPosEx(',', VDescStr, Vii + 1 );
            VLonStr := Copy(VDescStr, Vii + 1, Vjj - (Vii + 1));
            Vii := Vjj;
            Vjj := ALPosEx(',', VDescStr, Vii + 1 );
            VLatStr := Copy(VDescStr, Vii + 1, Vjj - (Vii + 1));
            VFullDesc := '';
          end else begin
            Exit;
          end;
        end;
        i:= j + 1;
        j := ALPosEx(']', VBuffer, i);
        VSName := Utf8ToAnsi(Copy(VBuffer, i + 3, j - (i + 4)));
        j := ALPosEx(',', VBuffer, j + 1);
        i := j + 1;
        j := ALPosEx(',', VBuffer, j + 1);
        VNavitel_Type := Copy(VBuffer, i + 1, j - (i + 1));
        VSName := NavitelType(ALStrToInt(VNavitel_Type )) + VSName;
        i := j + 1;
        j := ALPosEx(',', VBuffer, i + 1);
        VPlace_Id := Copy(VBuffer, i + 1, j - (i + 1));
        if VPlace_Id <> 'null' then begin
          VRequest := PrepareRequestByURL('http://maps.navitel.su/webmaps/searchById?id=' + (VPlace_Id));
          VResult := Downloader.DoRequest(VRequest, ACancelNotifier, AOperationID);
          //http://maps.navitel.su/webmaps/searchById?id=812207
          if Supports(VResult, IDownloadResultOk, VResultOk) then begin
            SetLength(VDescStr, VResultOk.Data.Size);
            Move(VResultOk.Data.Buffer^, VDescStr[1], VResultOk.Data.Size);
            VDescStr := RegExprReplaceMatchSubStr(VDescStr, '[0-9]','');
            VDescStr := ALStringReplace(VDescStr, #$0A, '', [rfReplaceAll]);
            VDescStr := ALStringReplace(VDescStr, #$0D, '', [rfReplaceAll]);
            VDescStr := ALStringReplace(VDescStr, '[', '', [rfReplaceAll]);
            VDescStr := ALStringReplace(VDescStr, ']', '', [rfReplaceAll]);
            VDescStr := ALStringReplace(VDescStr, 'null', '', [rfReplaceAll]);
            VDescStr := ALStringReplace(VDescStr, ', ', '', [rfReplaceAll]);
            VDescStr := ALStringReplace(VDescStr, '""', '","', [rfReplaceAll]);
            VDesc := Utf8ToAnsi(VDescStr);
          end else begin
            Exit;
          end;
        end else begin
           i := ALPosEx('[', VBuffer, j + 1);
           if i > j + 1 then begin
             j := ALPosEx(']', VBuffer, i);
             VDesc := Utf8ToAnsi(Copy(VBuffer, i + 1, j - (i + 1)));
          end;
        end;

        try
          VPoint.Y := ALStrToFloat(VLatStr, VFormatSettings);
          VPoint.X := ALStrToFloat(VLonStr, VFormatSettings);
        except
          raise EParserError.CreateFmt(SAS_ERR_CoordParseError, [VLatStr, VLonStr]);
        end;
        VPlace := PlacemarkFactory.Build(VPoint, VSName, VDesc, VFullDesc, 4);
        VList.Add(VPlace);

        VBuffer := '';
      end;
    end;
  end;

  Result := VList;
end;

function TGeoCoderByNavitel.PrepareRequest(
  const ASearch: string;
  const ALocalConverter: ILocalCoordConverter
): IDownloadRequest;
var
  VSearch: String;
  VProjection: IProjection;
  VMapRect: TDoubleRect;
  VLonLatRect: TDoubleRect;
begin
  VSearch := ASearch;
  VProjection := ALocalConverter.Projection;
  VMapRect := ALocalConverter.GetRectInMapPixelFloat;
  VProjection.ValidatePixelRectFloat(VMapRect);
  VLonLatRect := VProjection.PixelRectFloat2LonLatRect(VMapRect);

  //http://maps.navitel.su/webmaps/searchTwoStep?s=%D0%BD%D0%BE%D0%B2%D0%BE%D1%82%D0%B8%D1%82%D0%B0%D1%80%D0%BE%D0%B2%D1%81%D0%BA%D0%B0%D1%8F&lon=38.9739197086479&lat=45.2394838066316&z=11
  //http://maps.navitel.su/webmaps/searchTwoStepInfo?id=842798

  //http://maps.navitel.su/webmaps/searchTwoStep?s=%D0%BC%D0%BE%D1%81%D0%BA%D0%B2%D0%B0&lon=37.6&lat=55.8&z=6
  //http://maps.navitel.su/webmaps/searchTwoStepInfo?id=848692
  Result := PrepareRequestByURL(
   'http://maps.navitel.su/webmaps/searchTwoStep?s=' + URLEncode(AnsiToUtf8(VSearch)) +
   '&lon=' + R2AnsiStrPoint(ALocalConverter.GetCenterLonLat.x) + '&lat=' + R2AnsiStrPoint(ALocalConverter.GetCenterLonLat.y) +
   '&z=' + ALIntToStr(VProjection.Zoom));
end;

end.

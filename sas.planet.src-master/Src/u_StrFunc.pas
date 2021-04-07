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

unit u_StrFunc;

interface

uses
  SysUtils;

function GetAfter(const SubStr, Str: AnsiString): AnsiString; inline;
function GetBefore(const SubStr, Str: AnsiString): AnsiString; inline;
function GetBetween(const Str, After, Before: AnsiString): AnsiString; inline;

function SetHeaderValue(const AHeaders, AName, AValue: AnsiString): AnsiString;
function GetHeaderValue(const AHeaders, AName: AnsiString): AnsiString;
function DeleteHeaderEntry(const AHeaders, AName: AnsiString): AnsiString;

{$IFDef UNICODE}
function IsAscii(const P: PChar; const Len: Integer): Boolean; overload; inline;
function IsAscii(const s: string): Boolean; overload; inline;
{$ENDIF}
function IsAscii(const P: PAnsiChar; const Len: Integer): Boolean; overload; inline;
function IsAscii(const s: AnsiString): Boolean; overload; inline;

function StringToAsciiSafe(const s: string): AnsiString; inline;
function AsciiToStringSafe(const s: AnsiString): string; inline;

function IsAnsi(const s: string): Boolean; inline;

function StringToAnsiSafe(const s: string): AnsiString; inline;

type
  TStrLenAFunc = function(const S: PAnsiChar): Cardinal;
  TStrLCopyAFunc = function(Dest: PAnsiChar; const Source: PAnsiChar; MaxLen: Cardinal): PAnsiChar;
  TStrICompAFunc = function(const S1, S2: PAnsiChar): Integer;
  TTextToFloatAFunc = function(Buffer: PAnsiChar; var Value; ValueType: TFloatValue;
    const AFormatSettings: TFormatSettings): Boolean;
  TLowerCaseAFunc = function(const S: AnsiString): AnsiString;

var
  StrLenA: TStrLenAFunc;
  StrLCopyA: TStrLCopyAFunc;
  StrICompA: TStrICompAFunc;
  TextToFloatA: TTextToFloatAFunc;
  LowerCaseA: TLowerCaseAFunc;

implementation

uses
  {$IF CompilerVersion >= 23}
  AnsiStrings,
  {$IFEND}
  ALString,
  RegExpr;

function GetAfter(const SubStr, Str: AnsiString): AnsiString;
var
  I: Integer;
begin
  I := Pos(SubStr, Str);
  if I > 0 then begin
    Result := Copy(Str, I + Length(SubStr), Length(Str));
  end else begin
    Result := '';
  end;
end;

function GetBefore(const SubStr, Str: AnsiString): AnsiString;
var
  I: Integer;
begin
  I := Pos(SubStr, Str);
  if I > 0 then begin
    Result := Copy(Str, 1, I - 1);
  end else begin
    Result := '';
  end;
end;

function GetBetween(const Str, After, Before: AnsiString): AnsiString;
begin
  Result := GetBefore(Before, GetAfter(After, Str));
end;

function SetHeaderValue(const AHeaders, AName, AValue: AnsiString): AnsiString;
var
  VRegExpr: TRegExpr;
begin
  if AHeaders <> '' then begin
    VRegExpr := TRegExpr.Create;
    try
      VRegExpr.Expression := '(?i)' + AName + ':(\s+|)(.*?)(\r\n|$)';
      if VRegExpr.Exec(AHeaders) then begin
        Result := ALStringReplace(AHeaders, VRegExpr.Match[2], AValue, [rfIgnoreCase]);
      end else begin
        Result := AName + ': ' + AValue + #13#10 + AHeaders;
      end;
    finally
      VRegExpr.Free;
    end;
  end else begin
    Result := AName + ': ' + AValue + #13#10;
  end;
end;

function GetHeaderValue(const AHeaders, AName: AnsiString): AnsiString;
var
  VRegExpr: TRegExpr;
begin
  if AHeaders <> '' then begin
    VRegExpr := TRegExpr.Create;
    try
      VRegExpr.Expression := '(?i)' + AName + ':(\s+|)(.*?)(\r\n|$)';
      if VRegExpr.Exec(AHeaders) then begin
        Result := VRegExpr.Match[2];
      end else begin
        Result := '';
      end;
    finally
      VRegExpr.Free;
    end;
  end else begin
    Result := '';
  end;
end;

function DeleteHeaderEntry(const AHeaders, AName: AnsiString): AnsiString;
var
  VRegExpr: TRegExpr;
begin
  if AHeaders <> '' then begin
    VRegExpr := TRegExpr.Create;
    try
      VRegExpr.Expression := '(?i)' + AName + ':(\s+|)(.*?)(\r\n|$)';
      if VRegExpr.Exec(AHeaders) then begin
        Result := ALStringReplace(AHeaders, VRegExpr.Match[0], '', []);
      end else begin
        Result := AHeaders;
      end;
    finally
      VRegExpr.Free;
    end;
  end else begin
    Result := '';
  end;
end;

{$IFDEF UNICODE}
function IsAscii(const s: string): Boolean; overload;
var
  VLen: Integer;
begin
  VLen := Length(s);
  if VLen > 0 then begin
    Result := IsAscii(PChar(s), VLen);
  end else begin
    Result := True;
  end;
end;

function IsAscii(const P: PChar; const Len: Integer): Boolean;
var
  I: Integer;
begin
  Result := False;
  if P <> nil then begin
    for I := 0 to Len - 1 do begin
      if Ord(P[I]) > 127 then begin
        Exit;
      end;
    end;
  end;
  Result := True;
end;
{$ENDIF}

function IsAscii(const P: PAnsiChar; const Len: Integer): Boolean;
var
  I: Integer;
begin
  Result := False;
  if P <> nil then begin
    for I := 0 to Len - 1 do begin
      if Ord(P[I]) > 127 then begin
        Exit;
      end;
    end;
  end;
  Result := True;
end;

function IsAscii(const s: AnsiString): Boolean;
var
  VLen: Integer;
begin
  VLen := Length(s);
  if VLen > 0 then begin
    Result := IsAscii(PAnsiChar(s), VLen);
  end else begin
    Result := True;
  end;
end;


function StringToAsciiSafe(const s: string): AnsiString;
begin
  if IsAscii(s) then begin
    Result := AnsiString(s);
  end else begin
    raise Exception.CreateFmt('String "%s" contain non-ascii characters!', [s]);
  end;
end;

function AsciiToStringSafe(const s: AnsiString): string;
begin
  if IsAscii(s) then begin
    Result := string(s);
  end else begin
    raise Exception.CreateFmt('String "%s" contain non-ascii characters!', [s]);
  end;
end;

{$IFDEF UNICODE}
function IsAnsi(const s: string): Boolean;
var
  VAnsi: AnsiString;
  VStr: string;
begin
  VAnsi := AnsiString(s);
  VStr := string(VAnsi);
  Result := VStr = s;
end;
{$ELSE}
function IsAnsi(const s: string): Boolean;
begin
  Result := True;
end;
{$ENDIF}

function StringToAnsiSafe(const s: string): AnsiString;
begin
  {$IFDEF UNICODE}
  Result := AnsiString(s);
  if string(Result) <> s then begin
    raise Exception.CreateFmt('String "%s" contain non-ansi characters!', [s]);
  end;
  {$ELSE}
  Result := s;
  {$ENDIF}
end;

initialization
  {$If CompilerVersion < 33}
  StrLenA := SysUtils.StrLen;
  StrLCopyA := SysUtils.StrLCopy;
  StrICompA := SysUtils.StrIComp;
  TextToFloatA := SysUtils.TextToFloat;
  {$ELSE}
  StrLenA := AnsiStrings.StrLen;
  StrLCopyA := AnsiStrings.StrLCopy;
  StrICompA := AnsiStrings.StrIComp;
  TextToFloatA := AnsiStrings.TextToFloat;
  {$IFEND}

  {$If CompilerVersion < 23}
  LowerCaseA := SysUtils.LowerCase;
  {$ELSE}
  LowerCaseA := AnsiStrings.LowerCase;
  {$IFEND}
end.

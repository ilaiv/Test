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

unit u_ExternalTerrainAPI;

interface

uses
  Windows;

function FindElevationInPlain(
  const AFile: THandle;
  const AStripIndex, AColumnIndex: LongInt;
  const ALinesCount, ASamplesCount: LongInt;
  out AElevationData: SmallInt
): Boolean;

procedure SwapInWord(const AWordPtr: PWord);
procedure SwapInDWord(const ADWordPtr: PDWord);

procedure CalcOffsetsInBounds(
  const ASasLon, ASasLat: Double;
  const ABounds: TRect;
  const ALinesCount, ASamplesCount: LongInt;
  out AStripIndex, AColumnIndex: LongInt
);

//-----------------------------------------------------------

type
  // Native NT API (for simplicity and performance)
  NTSTATUS = LongInt;
  PVOID = Pointer;

  LARGE_INTEGER = Int64;
  PLARGE_INTEGER = ^LARGE_INTEGER;

  IO_STATUS_BLOCK=record
    Status: DWORD;
    Information: ULONG;
  end;
  PIO_STATUS_BLOCK=^IO_STATUS_BLOCK;

  PIO_APC_ROUTINE = procedure(
    ApcContext: PVOID;
    IoStatusBlock: PIO_STATUS_BLOCK;
    Reserved: ULONG); stdcall;

  function NtReadFile(
    FileHandle: THandle; { IN }
    EventHandle: THandle; { IN OPTIONAL }
    UserApcRoutine: PIO_APC_ROUTINE; { IN OPTIONAL }
    UserApcContext: PVOID; { IN OPTIONAL}
    IoStatusBlock: PIO_STATUS_BLOCK; { OUT }
    Buffer: PVOID; { OUT }
    Length: ULONG; { IN }
    ByteOffset: PLARGE_INTEGER; { IN OPTIONAL }
    FileLockKey: PULONG { IN OPTIONAL }
  ): NTSTATUS; stdcall; external 'ntdll.dll';

const
  STATUS_SUCCESS = $00000000;
  //STATUS_BUFFER_TOO_SMALL = $C0000023;

// read any buffer at any pos
function NtReadFromFile(
  const AFile: THandle;
  const ABuf: Pointer;
  const ALen: LongWord;
  const AOffset: LARGE_INTEGER
): Boolean;

//-----------------------------------------------------------

type
  TTiffHeader = packed record
    ByteOrder: Word;  // 'II' (4949.H) or 'MM' (4D4D.H)
    type_: Word;      // 42
    IFDOffset: DWORD; // offset of first IFD
  end;
  PTiffHeader = ^TTiffHeader;

const
  c_TIFF_II = $4949;
  // byte order is always from the least significant byte to the most significant byte,
  // for both 16-bit and 32-bit integers This is called little-endian byte order
  c_42_II = $002A; // 42


  c_TIFF_MM = $4D4D;
  // format, byte order is always from most significant to least significant,
  // for both 16-bit and 32-bit integers. This is called big-endian byte order
  c_42_MM = $2A00; // 42

type
  // 4.6.2 IFD Structure
  // The IFD used in this standard consists of:
  // a 2-byte count (number of fields),
  // 12-byte field Interoperability arrays,
  // and 4-byte offset to the next IFD, in conformance with TIFF Rev. 6.0.
  TIFD_12 = packed record
    tag: Word;     // Bytes 0-1 Tag
    type_: Word;      // Bytes 2-3 Type
    count: DWORD;  // Bytes 4-7 Count
    offset: DWORD; // Bytes 8-11 Value Offset
  end;
  PIFD_12 = ^TIFD_12;

  TIFD_NN = packed record
    number_of_fields: Word;
    items: array of TIFD_12;
    offset_to_next: DWORD;
  end;
  PIFD_NN = ^TIFD_NN;

function FindElevationInTiff(
  const AFile: THandle;
  const AStripIndex, AColumnIndex: LongInt;
  const ALinesCount, ASamplesCount: LongInt;
  out AElevationData: SmallInt
): Boolean;


implementation

{.$DEFINE DUMP_TIFF_TAGS}

{$IFDEF DUMP_TIFF_TAGS}
uses
  SysUtils;
{$ENDIF}

procedure SwapInWord(const AWordPtr: PWord);
var w: Word;
begin
  w := ((AWordPtr^ and $00ff) shl 8)
       OR
       ((AWordPtr^ and $ff00) shr 8);
  AWordPtr^ := w;
end;

procedure SwapInDWord(const ADWordPtr: PDWord);
var d: DWord;
begin
  d := ((ADWordPtr^ and $000000ff) shl 24)
       OR
       ((ADWordPtr^ and $0000ff00) shl 8)
       OR
       ((ADWordPtr^ and $00ff0000) shr 8)
       OR
       ((ADWordPtr^ and $ff000000) shr 24);
  ADWordPtr^ := d;
end;

function NtReadFromFile(
  const AFile: THandle;
  const ABuf: Pointer;
  const ALen: LongWord;
  const AOffset: LARGE_INTEGER
): Boolean;
var
  VStatus: NTSTATUS;
  VRead_IOSB: IO_STATUS_BLOCK;
begin
  VStatus := NtReadFile(AFile, 0, nil, nil, @VRead_IOSB, ABuf, ALen, @AOffset, nil);
  // check status and how many bytes actually read
  Result := (STATUS_SUCCESS=VStatus) and (ALen = VRead_IOSB.Information);
end;

function FindElevationInPlain(
  const AFile: THandle;
  const AStripIndex, AColumnIndex: LongInt;
  const ALinesCount, ASamplesCount: LongInt;
  out AElevationData: SmallInt
): Boolean;
var
  VOffset: LARGE_INTEGER;
begin
  // The data are stored in row major order (all the data for row 1, followed by all the data for row 2, etc.).
  VOffset := AStripIndex;
  VOffset := VOffset * ASamplesCount;
  VOffset := VOffset + AColumnIndex;
  VOffset := VOffset * SizeOf(AElevationData);
  Result := NtReadFromFile(AFile, @AElevationData, SizeOf(AElevationData), VOffset);
end;

procedure CalcOffsetsInBounds(
  const ASasLon, ASasLat: Double;
  const ABounds: TRect;
  const ALinesCount, ASamplesCount: LongInt;
  out AStripIndex, AColumnIndex: LongInt
);
begin
  AStripIndex  := Round((1-(ASasLat-ABounds.Bottom)/(ABounds.Top-ABounds.Bottom))*(ALinesCount-1));
  AColumnIndex := Round((ASasLon-ABounds.Left)/(ABounds.Right-ABounds.Left)*(ASamplesCount-1));
end;

function CheckTiffHeader(const ATiffHeader: TTiffHeader): Boolean;
begin
  Result := ((ATiffHeader.ByteOrder=c_TIFF_II) and (ATiffHeader.type_=c_42_II))
            OR
            ((ATiffHeader.ByteOrder=c_TIFF_MM) and (ATiffHeader.type_=c_42_MM));
end;

function GetTiffDWORD(const AByteOrder: Word; const ASource: DWORD): DWORD;
begin
  if (AByteOrder=c_TIFF_MM) then begin
    // revert
    Result := ASource;
    SwapInDWord(@Result);
  end else begin
    // common
    Result := ASource;
  end;
end;

function GetTiffWORD(const AByteOrder: Word; const ASource: WORD): WORD;
begin
  if (AByteOrder=c_TIFF_MM) then begin
    // revert
    Result := ASource;
    SwapInWord(@Result);
  end else begin
    // common
    Result := ASource;
  end;
end;

function FindElevationInTiff(
  const AFile: THandle;
  const AStripIndex, AColumnIndex: LongInt;
  const ALinesCount, ASamplesCount: LongInt;
  out AElevationData: SmallInt
): Boolean;
var
  I: Integer;
  VTiffHeader: TTiffHeader;
  VStripsPerImage: DWORD;
  VOffset: LARGE_INTEGER;
  VNumberOfIFDs: Word;
  VCurrentTag, VStripOffsetsTag: TIFD_12;
  VImageWidth, VImageLength: DWORD;
  VOffsetsSize: LongWord;
  VOffsetsBuffer: Pointer;
begin
  // read header
  Result := NtReadFromFile(AFile, @VTiffHeader, SizeOf(VTiffHeader), 0);
  if not Result then
    Exit;

  // check header
  Result := CheckTiffHeader(VTiffHeader);
  if not Result then
    Exit;

  VOffset := GetTiffDWORD(VTiffHeader.ByteOrder, VTiffHeader.IFDOffset);

  // get number of IFDs
  Result := NtReadFromFile(AFile, @VNumberOfIFDs, SizeOf(VNumberOfIFDs), VOffset);
  if not Result then
    Exit;

  VNumberOfIFDs := GetTiffWORD(VTiffHeader.ByteOrder, VNumberOfIFDs);
  VOffset := VOffset + SizeOf(VNumberOfIFDs);

  VImageWidth := 0;
  VImageLength := 0;
  VStripsPerImage := 0;
  FillChar(VStripOffsetsTag, SizeOf(VStripOffsetsTag), 0);

  if VNumberOfIFDs > 0 then begin
    for I := 0 to VNumberOfIFDs - 1 do begin
      // get IFD
      Result := NtReadFromFile(AFile, @VCurrentTag, SizeOf(VCurrentTag), VOffset);
      if not Result then
        Exit;

      case VCurrentTag.tag of
        $100: begin
          // ImageWidth (SHORT or LONG)
          VImageWidth := VCurrentTag.offset;
        end;
        $101: begin
          // ImageLength (SHORT or LONG)
          VImageLength := VCurrentTag.offset;
        end;
        $111: begin
          // StripOffsets
          VStripOffsetsTag := VCurrentTag;
          VStripsPerImage := VStripOffsetsTag.count;
        end;
      end;

      VOffset := VOffset + SizeOf(VCurrentTag);

      {$IFDEF DUMP_TIFF_TAGS}
      OutputDebugString(
        PChar(
          'tag: ' + IntToStr(VCurrentTag.tag) + ' ' +
          'type: ' + IntToStr(VCurrentTag.type_) + ' ' +
          'count: ' + IntToStr(VCurrentTag.count) + ' ' +
          'offset: ' + IntToStr(VCurrentTag.offset) + ' ' +
          'offset: 0x' + IntToHex(VCurrentTag.offset, 8)
        )
      );
      {$ENDIF}
    end;
  end;

  Result := False;

  if (ASamplesCount = Integer(VImageWidth)) and (ALinesCount = Integer(VImageLength)) then begin
    if VStripsPerImage = 1 then begin
      VOffset := VStripOffsetsTag.offset;
      VOffset := VOffset + AStripIndex * ASamplesCount;
      VOffset := VOffset + AColumnIndex;
      VOffset := VOffset * SizeOf(AElevationData);
      Result := NtReadFromFile(AFile, @AElevationData, SizeOf(AElevationData), VOffset);
    end else if VStripsPerImage = Cardinal(ALinesCount) then begin
      // copy offsets for every strip
      // 3 = SHORT 16-bit (2-byte) unsigned integer
      // 4 = LONG 32-bit (4-byte) unsigned integer
      // may be as SHORT ...
      VOffsetsSize := VStripOffsetsTag.count*2;
      if (VStripOffsetsTag.type_=4) then begin
        // ... or as LONG
        VOffsetsSize := VOffsetsSize * 2;
      end;

      VOffsetsBuffer := HeapAlloc(GetProcessHeap, 0, VOffsetsSize);
      if (VOffsetsBuffer<>nil) then
      try
        VOffset := VStripOffsetsTag.offset;
        Result := NtReadFromFile(AFile, VOffsetsBuffer, VOffsetsSize, VOffset);
        if (not Result) then
          Exit;

        // done
        if (VStripOffsetsTag.type_=4) then begin
          // as LONG
          VOffset := PLongWord(INT_PTR(VOffsetsBuffer)+AStripIndex*SizeOf(DWORD))^;
          VOffset := VOffset + AColumnIndex*SizeOf(AElevationData);
          Result := NtReadFromFile(AFile, @AElevationData, SizeOf(AElevationData), VOffset);
        end else begin
          // as SHORT
          VOffset := PWord(INT_PTR(VOffsetsBuffer)+AStripIndex*SizeOf(WORD))^;
          VOffset := VOffset + AColumnIndex*SizeOf(AElevationData);
          Result := NtReadFromFile(AFile, @AElevationData, SizeOf(AElevationData), VOffset);
        end;
      finally
        HeapFree(GetProcessHeap, 0, VOffsetsBuffer);
      end;
    end;
  end;
end;

end.

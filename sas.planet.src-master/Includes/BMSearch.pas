unit BMSearch;

(* -------------------------------------------------------------------

����� ������ ������� Boyer-Moore.

��� - ���� �� ����� ������� ���������� ������ ������.
See a description in:

R. Boyer � S. Moore.
������� �������� ������ ������.
Communications of the ACM 20, 1977, �������� 762-772
------------------------------------------------------------------- *)

interface

type
{$IFDEF WINDOWS}

  size_t = Word;
{$ELSE}

  size_t = LongInt;
{$ENDIF}

type
  TSearchBM = class(TObject)
  private
    FJumpTable: array[AnsiChar] of Byte; { ������� ��������� }
    FShift_1: integer;
    FPatternString: AnsiString;
    FPattern: PAnsiChar;
    FPatternLen: size_t;

    procedure Prepare(Pattern: PAnsiChar; PatternLen: size_t);
  public
    constructor Create(const Pattern: AnsiString);
    function Search(Text: PAnsiChar; TextLen: size_t): PAnsiChar;
  end;

implementation

uses SysUtils;

(* -------------------------------------------------------------------
���������� ������� ���������
------------------------------------------------------------------- *)

constructor TSearchBM.Create(const Pattern: AnsiString);
begin
  FPatternString := Pattern;
  Prepare(PAnsiChar(FPatternString), Length(FPatternString));
end;

procedure TSearchBM.Prepare(Pattern: PAnsiChar; PatternLen: size_t);
var
  i: integer;
  c, lastc: AnsiChar;
begin
  FPattern := Pattern;
  FPatternLen := PatternLen;
  { ������ �������� ���������� �� ������ �� 256 �������� }
  Assert(FPatternLen < 255);
  Assert(FPatternLen > 0);

  { 2. ���������� ������� ��������� }

  for c := #0 to #255 do
    FJumpTable[c] := FPatternLen;

  for i := FPatternLen - 1 downto 0 do
  begin
    c := FPattern[i];
    if FJumpTable[c] >= FPatternLen - 1 then
      FJumpTable[c] := FPatternLen - 1 - i;
  end;

  FShift_1 := FPatternLen - 1;
  lastc := Pattern[FPatternLen - 1];

  for i := FPatternLen - 2 downto 0 do
    if FPattern[i] = lastc then
    begin
      FShift_1 := FPatternLen - 1 - i;
      break;
    end;

  if FShift_1 = 0 then
    FShift_1 := 1;
end;

{ ����� ���������� ������� & �������� ������ ������ }

function TSearchBM.Search(Text: PAnsiChar; TextLen: size_t): PAnsiChar;
var

  shift, m1, j: integer;
  jumps: size_t;
begin

  result := nil;

  if TextLen < 1 then
    exit;

  m1 := FPatternLen - 1;
  shift := 0;
  jumps := 0;

  { ����� ���������� ������� }

  while jumps <= TextLen do
  begin
    Inc(Text, shift);
    shift := FJumpTable[Text^];
    while shift <> 0 do
    begin
      Inc(jumps, shift);
      if jumps > TextLen then
        exit;

      Inc(Text, shift);
      shift := FJumpTable[Text^];
    end;

    { ���������� ������ ������ FPatternLen - 1 �������� }

    if jumps >= m1 then
    begin
      j := 0;
      while FPattern[m1 - j] = (Text - j)^ do
      begin
        Inc(j);
        if j = FPatternLen then
        begin
          result := Text - m1;
          exit;
        end;
      end;
    end;

    shift := FShift_1;
    Inc(jumps, shift);
  end;
end;

end.
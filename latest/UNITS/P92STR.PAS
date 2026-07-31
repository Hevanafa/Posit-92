{
  String utility unit
  Part of Posit-92 game engine
}

unit P92STR;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

interface

function Split(text, delim: string; var output: array of string): word;
function Contains(const source, searchStr: string): boolean;
function StartsWith(const source, searchStr: string): boolean;
function EndsWith(const source, searchStr: string): boolean;
function ReplaceAll(const source, searchStr, replaceStr: string): string;
function TrimStart(const txt: string): string;
function TrimEnd(const txt: string): string;
function Trim(const txt: string): string;
function Lower(const txt: string): string;
function Upper(const txt: string): string;
function PadStart(const source: string; const targetLen: integer; const padChar: char): string;


implementation

{ returns the number of elements }
function Split(text, delim: string; var output: array of string): word;
var
  i, p, startPos: integer;
  delimLen: integer;
  token: string;
  result: word;
begin
  result := 0;
  i := 1;
  startPos := 1;
  delimLen := length(delim);

  while i <= length(text) do begin
    p := pos(delim, copy(text, i, length(text) - i + 1));
    if p = 0 then break;

    token := copy(text, startPos, i+p-2-startPos+1);
    output[result] := token;
    inc(result);
    Split := result;
    if result > high(output) then exit;

    i:=i+p-1+delimLen;
    startPos := i
  end;

  { add the final token }
  token := copy(text, startPos, length(text) - startPos + 1);
  if (token <> '') and (result <= high(output)) then begin
    output[result] := token;
    inc(result)
  end;
  Split := result
end;

function Contains(const source, searchStr: string): boolean;
begin
  Contains := pos(searchStr, source) > 0
end;

function StartsWith(const source, searchStr: string): boolean;
begin
  StartsWith := copy(source, 1, length(searchStr)) = searchStr
end;

function EndsWith(const source, searchStr: string): boolean;
begin
  EndsWith := copy(source, length(source) - length(searchStr) + 1, length(searchStr)) = searchStr
end;

function ReplaceAll(const source, searchStr, replaceStr: string): string;
var
  result: string;
  i, foundPos, searchLen: integer;
begin
  result := '';
  i := 1;
  searchLen := length(searchStr);

  while i <= length(source) do begin
    foundPos := pos(searchStr, copy(source, i, length(source) - i + 1));
    if foundPos = 0 then begin
      result := result + copy(source, i, length(source) - i + 1);
      break
    end else begin
      result := result + copy(source, i, foundPos - 1) + replaceStr;
      inc(i, foundPos + searchLen - 1)
    end;
  end;

  ReplaceAll := result
end;


function TrimStart(const txt: string): string;
var
  a, len: integer;
begin
  len := length(txt);
  a:=1;
  while (a <= len) and (txt[a] = ' ') do
    inc(a);
  TrimStart := copy(txt, a, len - a + 1)
end;

function TrimEnd(const txt: string): string;
var
  a: integer;
begin
  a := length(txt);
  while (a>0) and (txt[a] = ' ') do
    dec(a);
  TrimEnd := copy(txt, 1, a)
end;

function Trim(const txt: string): string;
begin
  Trim := TrimEnd(TrimStart(txt));
end;

{ Similar to Lua & Python's str.lower() }
function Lower(const txt: string): string;
var
  a: integer;
  result: string;
begin
  result := txt;
  for a:=1 to length(result) do
    if ('A' <= result[a]) and (result[a] <= 'Z') then
      result[a] := chr(ord(result[a]) + 32);
  Lower := result
end;

{ Similar to Lua & Python's str.lower() }
function Upper(const txt: string): string;
var
  a: integer;
  result: string;
begin
  result := txt;
  for a:=1 to length(result) do
    if ('a' <= result[a]) and (result[a] <= 'z') then
      result[a] := chr(ord(result[a]) - 32);
  Upper := result
end;

function PadStart(const source: string; const targetLen: integer; const padChar: char): string;
var
  result: string;
begin
  if targetLen <= length(source) then begin
    PadStart := source;
    exit
  end;

  result := source;

  while length(result) < targetLen do
    result := padChar + result;

  PadStart := result
end;

end.

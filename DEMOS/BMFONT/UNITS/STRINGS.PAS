unit Strings;

interface

function split(text, delim: string; var output: array of string): word;
function contains(const source, searchStr: string): boolean;
function startsWith(const source, searchStr: string): boolean;
function endsWith(const source, searchStr: string): boolean;
function replaceAll(const source, searchStr, replaceStr: string): string;
function trimStart(const txt: string): string;
function trimEnd(const txt: string): string;
function trim(const txt: string): string;
function lower(const txt: string): string;
function upper(const txt: string): string;


implementation

{ returns the number of elements }
function split(text, delim: string; var output: array of string): word;
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
    split := result;
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
  split := result
end;

function contains(const source, searchStr: string): boolean;
begin
  contains := pos(searchStr, source) > 0
end;

function startsWith(const source, searchStr: string): boolean;
begin
  startsWith := copy(source, 1, length(searchStr)) = searchStr
end;

function endsWith(const source, searchStr: string): boolean;
begin
  endsWith := copy(source, length(source) - length(searchStr) + 1, length(searchStr)) = searchStr
end;

function replaceAll(const source, searchStr, replaceStr: string): string;
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

  replaceAll := result
end;


function trimStart(const txt: string): string;
var
  a, len: integer;
begin
  len := length(txt);
  a:=1;
  while (a <= len) and (txt[a] = ' ') do
    inc(a);
  trimStart := copy(txt, a, len - a + 1)
end;

function trimEnd(const txt: string): string;
var
  a: integer;
begin
  a := length(txt);
  while (a>0) and (txt[a] = ' ') do
    dec(a);
  trimEnd := copy(txt, 1, a)
end;

function trim(const txt: string): string;
begin
  trim := trimEnd(trimStart(txt));
end;

{ Similar to Lua & Python's str.lower() }
function lower(const txt: string): string;
var
  a: integer;
  result: string;
begin
  result := txt;
  for a:=1 to length(result) do
    if ('A' <= result[a]) and (result[a] <= 'Z') then
      result[a] := chr(ord(result[a]) + 32);
  lower := result
end;

{ Similar to Lua & Python's str.lower() }
function upper(const txt: string): string;
var
  a: integer;
  result: string;
begin
  result := txt;
  for a:=1 to length(result) do
    if ('a' <= result[a]) and (result[a] <= 'z') then
      result[a] := chr(ord(result[a]) - 32);
  upper := result
end;

end.

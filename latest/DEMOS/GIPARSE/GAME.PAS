
uses
  CRT, DOS,
  Logger, Timing,
  Strings;

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


function fileExists(const filename: string): boolean;
var
  f: file;
begin
  {$I-} { Turn off runtime error 2: IO error halt }
  assign(f, filename);
  reset(f);
  fileExists := (IOResult = 0);
  close(f)  { Safe, even if the file isn't open }
  {$I+}
end;


procedure INIT;
begin
  randomize;
  initLogger;
  initDeltaTime;
end;


var
  t: text;
  line: string;
begin
  INIT;

  if not fileExists('GAMEINFO.TXT') then begin
    writeLn('GAMEINFO.TXT doesn''t exist!');
    halt(1)
  end;

  assign(t, 'GAMEINFO.TXT');
  reset(t);

  {
  writeLn(lower('GameInfo.TXT'));
  writeLn(upper('gameinfo.txt'));
  }

  while not eof(t) do begin
    readLn(t, line);
    { lower(line);
    writeLn(line);
    writeLn('Trimmed:');
    writeLn(trimStart(line)); }
    if startsWith(trimStart(line), 'title') then
      writeLn(line);
  end;

  close(t);

  readLn;
  closeLogger
end.

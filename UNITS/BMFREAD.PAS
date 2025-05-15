
uses crt, dos;

type
  PBMFontGlyph = ^TBMFontGlyph;
  TBMFontGlyph = record
    id: word;
    x, y, width, height: word;
    xoffset, yoffset: integer;
    xadvance: integer;
    { page, chnl: byte; }
  end;
  TBMFont = array[32..127] of PBMFontGlyph;

var
  font: TBMFont;


{
function replaceAll(const source, searchStr, replaceStr: string): string;
var
  startPos, matchPos, searchLen: integer;
  result: string;
begin
  result := '';
  startPos := 1;
  searchLen := length(searchStr);

  while startPos <= length(source) do begin
    matchPos := pos(searchStr, copy(source, startPos, length(source) - startPos + 1));
    if matchPos = 0 then break;

    { if found }
{    result := result + copy(source, startPos, length(source) - startPos + 1) + replaceStr;
    inc(startPos, matchPos - startPos + 1)
  end;

  replaceAll := result
end;}

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


function parseInt(const text: string): integer;
var
  result, parseResult: integer;
begin
  val(text, result, parseResult);
  if parseResult <> 0 then begin
    writeLn('Error parsing to integer:', text);
    parseInt := 0
  end else
    parseInt := result;
end;


procedure loadBMFont(filename: string; var output: TBMFont);
var
  a, b: integer;
  f: text;
  line: string;
  skipLine: boolean;
  pairs: array[0..11] of string;
  pairCount: word;
  kv: array[0..1] of string;
  key, value: string;
  glyphID, parseResult, tempI32: integer;
begin
{ TODO: initialise the output array }
  for a:=low(output) to high(output) do begin
    if output[a] <> nil then begin
      freeMem(output[a], sizeOf(TBMFont));
      output[a] := nil;
    end;
  end;

  assign(f, filename);
  reset(f);
  a := 0;
  skipLine := false;

  while not eof(f) do begin
    readln(f, line);
    skipLine := false;
    { writeLn('Line ', a, ': ', line); }

    while contains(line, '  ') do
      line := replaceAll(line, '  ', ' ');

    if startsWith(line, 'char') then begin
      { assign glyph info }
      pairCount := split(line, ' ', pairs);
      for b:=0 to pairCount-1 do begin
        split(pairs[b], '=', kv);
        key := kv[0]; value := kv[1];

        { case-of can't be used with strings in TP7 }
        if key = 'id' then begin
          glyphID := parseInt(value);
          New(font[tempI32]);
          if (low(font) <= glyphID) and (glyphID <= high(font)) then begin
            { writeLn('ID:', glyphID); }
            font[glyphID]^.id := glyphID
          end else begin
            { writeLn('Skipped glyph ', glyphID); }
            { when out of bounds }
            skipLine := true;
            break
          end;
        end
        else if key = 'x' then font[glyphID]^.x := parseInt(value)
        else if key = 'y' then font[glyphID]^.y := parseInt(value)
        else if key = 'width' then font[glyphID]^.width := parseInt(value)
        else if key = 'height' then font[glyphID]^.height := parseInt(value)
        else if key = 'xoffset' then font[glyphID]^.xoffset := parseInt(value)
        else if key = 'yoffset' then font[glyphID]^.yoffset := parseInt(value)
        else if key = 'xadvance' then font[glyphID]^.xadvance := parseInt(value);
      end;

      { writeLn(line); }
    end;

    inc(a)
    { if a>=10 then break; }
  end;
  close(f)
end;

var
  f: file;
  a: integer;
  source: string;
begin
  loadBMFont('COMMOD64.FNT', font);
  for a := low(font) to high(font) do
    if font[a] <> nil then
      writeLn('id:',font[a]^.id);
  {
  source := 'hello world    a     b       c';
  writeLn(source);
  while contains(source, '  ') do
    source := replaceAll(source, '  ', ' ');
  writeLn(source);
  }
  readLn
end.
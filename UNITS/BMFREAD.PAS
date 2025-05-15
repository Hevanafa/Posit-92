
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
  TBMFont = object
    glyphs: array[32..127] of PBMFontGlyph;
    filename: string;
    lineHeight: word;
  end;

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


procedure freeBMFont(var font: TBMFont);
var
  a: word;
begin
  for a:=low(font.glyphs) to high(font.glyphs) do begin
    if font.glyphs[a] <> nil then begin
      dispose(font.glyphs[a]);
      font.glyphs[a] := nil
    end;
  end;
end;


procedure loadBMFont(const filename: string; var output: TBMFont);
var
  a, b: integer;
  f: text;
  line: string;
  skipLine: boolean;
  pairs: array[0..11] of string;
  pairCount: word;
  kv: array[0..1] of string; { key-value pair }
  key, value: string;  { separated key-value pair }
  g: PBMFontGlyph;
  glyphID, parseResult, tempI32: integer;
begin
  freeBMFont(output);
  for a:=low(output.glyphs) to high(output.glyphs) do
    output.glyphs[a] := nil;

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

    if startsWith(line, 'common') then begin
      pairCount := split(line, ' ', pairs);
      for b:=0 to pairCount-1 do begin
        split(pairs[b], '=', kv);
        if kv[0] = 'lineHeight' then
          font.lineHeight := parseInt(kv[1]);
      end;
    end;

    if startsWith(line, 'page') then begin
      pairCount := split(line, ' ', pairs);
      for b:=0 to pairCount-1 do begin
        split(pairs[b], '=', kv);
        if kv[0] = 'file' then font.filename := kv[1];
      end;
    end;

    if startsWith(line, 'char') then begin
      { assign glyph info }
      pairCount := split(line, ' ', pairs);
      for b:=0 to pairCount-1 do begin
        split(pairs[b], '=', kv);
        key := kv[0]; value := kv[1];

        { case-of can't be used with strings in TP7 }
        if key = 'id' then begin
          glyphID := parseInt(value);

          if (low(font.glyphs) <= glyphID) and (glyphID <= high(font.glyphs)) then begin
            { writeLn('ID:', glyphID); }
            New(g);
            g^.id := glyphID;
            font.glyphs[glyphID] := g
          end else begin
            { writeLn('Skipped glyph ', glyphID); }
            { when out of bounds }
            skipLine := true;
            break
          end;
        end
        else if key = 'x' then font.glyphs[glyphID]^.x := parseInt(value)
        else if key = 'y' then font.glyphs[glyphID]^.y := parseInt(value)
        else if key = 'width' then font.glyphs[glyphID]^.width := parseInt(value)
        else if key = 'height' then font.glyphs[glyphID]^.height := parseInt(value)
        else if key = 'xoffset' then font.glyphs[glyphID]^.xoffset := parseInt(value)
        else if key = 'yoffset' then font.glyphs[glyphID]^.yoffset := parseInt(value)
        else if key = 'xadvance' then font.glyphs[glyphID]^.xadvance := parseInt(value);
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
  writeLn('Filename:', font.filename);
  writeLn('Line height:', font.lineHeight);
  {
  for a := low(font) to high(font) do
    if font[a] <> nil then
      writeLn('id:',font[a]^.id);
  }


  {
  source := 'hello world    a     b       c';
  writeLn(source);
  while contains(source, '  ') do
    source := replaceAll(source, '  ', ' ');
  writeLn(source);
  }
  readLn
end.
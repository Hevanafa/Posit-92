unit BMFont;

interface

uses Bitmap;

type
  PBMFontGlyph = ^TBMFontGlyph;
  TBMFontGlyph = record
    id: word;
    x, y, width, height: word;  { 2, 4, 6, 8 }
    xoffset, yoffset: integer;  { 10, 12 }
    xadvance: integer; { 14 }
    { page, chnl: byte; }
  end;

  PBMFont = ^TBMFont;
  TBMFont = record
    glyphs: array[32..127] of PBMFontGlyph;
    filename: string;  { 384 }
    lineHeight: word;  { 640 }
    bitmap: PBitmap;  { 642 }
  end;

procedure LoadBMFont(var font: PBMFont; const filename: string);
procedure FreeBMFont(var font: PBMFont);

procedure PrintBMFont(const font: PBMFont; const text: string; x, y: integer; const transparencyKey: byte);

function MeasureBMFont(const font: PBMFont; const text: string): integer;

implementation

uses Conv, Logger, Panic, Strings, VGA;

procedure LoadBMFont(var font: PBMFont; const filename: string);
var
  b: integer;
  f: text;

  count: word;
  line: string;
  pairs: array[0..11] of string;
  pairCount: word;
  kv: array[0..1] of string; { key-value pair }
  key, value: string;  { separated key-value pair }

  tempGlyph: TBMFontGlyph;
  glyphID, parseResult, tempI32: integer;
begin
  if font <> nil then
    writeLog('loadBMFont: font isn''t nil!');

  { getMem(font, sizeof(TBMFont)); }
  new(font);

  if font = nil then
    panicHalt('loadBMFont: Out of memory!');

  for b:=low(font^.glyphs) to high(font^.glyphs) do
    font^.glyphs[b] := nil;
  font^.bitmap := nil;

  assign(f, filename);
  {$I-} reset(f); {$I+}
  if IOResult <> 0 then
    panicHalt('loadBMFont: Couldn''t find "' + filename + '"!');

  count := 0;

  while not eof(f) do begin
    readln(f, line);

    while contains(line, '  ') do
      line := replaceAll(line, '  ', ' ');

    if startsWith(line, 'common') then begin
      pairCount := split(line, ' ', pairs);
      for b:=0 to pairCount-1 do begin
        split(pairs[b], '=', kv);
        if kv[0] = 'lineHeight' then
          font^.lineHeight := parseInt(kv[1]);
      end;
    end;

    if startsWith(line, 'page') then begin
      pairCount := split(line, ' ', pairs);
      for b:=0 to pairCount-1 do begin
        split(pairs[b], '=', kv);
        if kv[0] = 'file' then
          font^.filename := replaceAll(kv[1], '"', '');
      end;
    end;

    if startsWith(line, 'char') then begin
      { Parse the whole line first, then check bounds }
      glyphID := -1;
      fillChar(tempGlyph, sizeof(TBMFontGlyph), 0);

      { assign glyph info }
      pairCount := split(line, ' ', pairs);

      for b:=0 to pairCount-1 do begin
        split(pairs[b], '=', kv);
        key := kv[0]; value := kv[1];

        { case-of can't be used with strings in TP7 }
        if key = 'id' then begin
          glyphID := parseInt(value);

          { writeLog('ID:' + i32str(glyphID)); }
          tempGlyph.id := glyphID;
        end
        else if key = 'x' then tempGlyph.x := parseInt(value)
        else if key = 'y' then tempGlyph.y := parseInt(value)
        else if key = 'width' then tempGlyph.width := parseInt(value)
        else if key = 'height' then tempGlyph.height := parseInt(value)
        else if key = 'xoffset' then tempGlyph.xoffset := parseInt(value)
        else if key = 'yoffset' then tempGlyph.yoffset := parseInt(value)
        else if key = 'xadvance' then tempGlyph.xadvance := parseInt(value);
      end;

      if (low(font^.glyphs) <= tempGlyph.id) and
          (tempGlyph.id <= high(font^.glyphs)) then begin
        new(font^.glyphs[tempGlyph.id]);
        font^.glyphs[tempGlyph.id]^ := tempGlyph;
        writeLog('Applied ID ' + i32str(tempGlyph.id));
        inc(count);
      end;
    end;
  end;
  close(f);

  loadBMP(font^.bitmap, font^.filename);
  writeLog('Loaded ' + i32str(count) + ' glyphs');
end;


procedure FreeBMFont(var font: PBMFont);
var
  a, count: word;
begin
  if font = nil then exit;

  count:=0;
  for a:=low(font^.glyphs) to high(font^.glyphs) do begin
    if font^.glyphs[a] <> nil then begin
      writeLog('Freeing glyph ' + i32str(a) + '...');

      dispose(font^.glyphs[a]);
      font^.glyphs[a] := nil;
      inc(count)
    end;
  end;
  freeBMP(font^.bitmap);
  {
  font^.filename := '';
  font^.lineHeight := 0;
  }
  dispose(font);
  font := nil;

  writeLog('Freed ' + i32str(count) + ' glyphs')
end;


procedure PrintBMFont(const font: PBMFont; const text: string; x, y: integer; const transparencyKey: byte);
var
  a, row, col, dx, dy: integer;
  ch: char;
  g: PBMFontGlyph;
  srcX, srcY: word;
  colour: byte;
begin
  if font = nil then exit;

  dx := x;
  for a:=1 to length(text) do begin
    ch := text[a];
    if (ord(ch) < low(font^.glyphs)) or (ord(ch) > high(font^.glyphs)) then continue;

    g := font^.glyphs[ord(ch)];
    if g = nil then continue;

    for row := 0 to g^.height - 1 do begin
      for col := 0 to g^.width - 1 do begin
        srcX := g^.x + col;
        srcY := g^.y + row;
        colour := font^.bitmap^.data[srcY * font^.bitmap^.width + srcX];

        if colour <> transparencyKey then
          pset(dx + g^.xoffset + col, y + g^.yoffset + row, colour);
      end;
    end;

    inc(dx, g^.xadvance)
  end;
end;


function MeasureBMFont(const font: PBMFont; const text: string): integer;
var
  a: integer;
  ch: char;
  glyph: PBMFontGlyph;
  result: integer;
begin
  if font = nil then begin
    MeasureBMFont := 0;
    exit
  end;

  result := 0;

  for a:=1 to length(text) do begin
    ch := text[a];
    if (low(font^.glyphs) <= ord(ch)) and (ord(ch) <= high(font^.glyphs)) then begin
      glyph := font^.glyphs[ord(ch)];
      if glyph <> nil then
        inc(result, glyph^.xadvance);
    end;
  end;

  MeasureBMFont := result
end;

end.

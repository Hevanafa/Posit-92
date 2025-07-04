unit BMFont;

interface

uses Bitmap;

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
    bitmap: PBitmap;
    
    function textWidth(const text: string): integer;
  end;

procedure loadBMFont(var output: TBMFont; const filename: string);
procedure freeBMFont(var font: TBMFont);
procedure printBMFont(const font: TBMFont; const text: string; x, y: integer; const transparencyKey: byte);

implementation

uses Conv, Logger, Panic, Strings, VGA;

procedure loadBMFont(var output: TBMFont; const filename: string);
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
  for a:=low(output.glyphs) to high(output.glyphs) do
    output.glyphs[a] := nil;

  assign(f, filename);
  {$I-} reset(f); {$I+}
  if IOResult <> 0 then
    panicHalt('loadBMFont: Couldn''t find "' + filename + '"!');

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
          output.lineHeight := parseInt(kv[1]);
      end;
    end;

    if startsWith(line, 'page') then begin
      pairCount := split(line, ' ', pairs);
      for b:=0 to pairCount-1 do begin
        split(pairs[b], '=', kv);
        if kv[0] = 'file' then
          output.filename := replaceAll(kv[1], '"', '');
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

          if (low(output.glyphs) <= glyphID) and (glyphID <= high(output.glyphs)) then begin
            { writeLn('ID:', glyphID); }
            New(g);
            g^.id := glyphID;
            output.glyphs[glyphID] := g
          end else begin
            { writeLn('Skipped glyph ', glyphID); }
            { when out of bounds }
            skipLine := true;
            break
          end;
        end
        else if key = 'x' then output.glyphs[glyphID]^.x := parseInt(value)
        else if key = 'y' then output.glyphs[glyphID]^.y := parseInt(value)
        else if key = 'width' then output.glyphs[glyphID]^.width := parseInt(value)
        else if key = 'height' then output.glyphs[glyphID]^.height := parseInt(value)
        else if key = 'xoffset' then output.glyphs[glyphID]^.xoffset := parseInt(value)
        else if key = 'yoffset' then output.glyphs[glyphID]^.yoffset := parseInt(value)
        else if key = 'xadvance' then output.glyphs[glyphID]^.xadvance := parseInt(value);
      end;
    end;

    inc(a)
  end;
  close(f);

  loadBMP(output.bitmap, output.filename)
end;

procedure freeBMFont(var font: TBMFont);
var
  a, count: word;
begin
  count:=0;
  for a:=low(font.glyphs) to high(font.glyphs) do begin
    if font.glyphs[a] <> nil then begin
      dispose(font.glyphs[a]);
      font.glyphs[a] := nil;
      inc(count)
    end;
  end;
  freeBMP(font.bitmap);
  font.filename := '';
  font.lineHeight := 0;

  writeLog('Freed ' + i32str(count) + ' glyphs')
end;


procedure printBMFont(const font: TBMFont; const text: string; x, y: integer; const transparencyKey: byte);
var
  a, row, col, dx, dy: integer;
  ch: char;
  g: PBMFontGlyph;
  srcX, srcY: word;
  colour: byte;
begin
  dx := x;
  for a:=1 to length(text) do begin
    ch := text[a];
    if (ord(ch) < low(font.glyphs)) or (ord(ch) > high(font.glyphs)) then continue;

    g := font.glyphs[ord(ch)];
    if g = nil then continue;

    for row := 0 to g^.height - 1 do begin
      for col := 0 to g^.width - 1 do begin
        srcX := g^.x + col;
        srcY := g^.y + row;
        colour := font.bitmap^.data[srcY * font.bitmap^.width + srcX];

        if colour <> transparencyKey then
          pset(dx + g^.xoffset + col, y + g^.yoffset + row, colour);
      end;
    end;

    inc(dx, g^.xadvance)
  end;
end;

function TBMFont.textWidth(const text: string): integer;
var
  a: integer;
  ch: char;
  glyph: PBMFontGlyph;
  result: integer;
begin
  result := 0;

  for a:=1 to length(text) do begin
    ch := text[a];
    if (low(glyphs) <= ord(ch)) and (ord(ch) <= high(glyphs)) then begin
      glyph := glyphs[ord(ch)];
      if glyph <> nil then
        inc(result, glyph^.xadvance);
    end;
  end;

  textWidth := result
end;

end.

unit BMFont;

interface

uses Bitmap;

type
  ui8 = byte;
  i8 = shortint;
  i16 = integer;
  ui16 = word;

  PBMFontGlyph = ^TBMFontGlyph;
  TBMFontGlyph = record
    id: ui16;
    x, y, width, height: ui16;  { 2, 4, 6, 8 }
    xoffset, yoffset: i16;  { 10, 12 }
    xadvance: i16; { 14 }
    { page, chnl: byte; }
  end;

  PBMFont = ^TBMFont;
  TBMFont = record
    glyphs: array[32..127] of PBMFontGlyph;
    filename: string;  { 384 }
    lineHeight: word;  { 640 }
    bitmap: PBitmap;  { 642 }
  end;

procedure loadBMFont(var font: PBMFont; const filename: string);
procedure freeBMFont(var font: PBMFont);

procedure printBMFont(const font: PBMFont; const text: string; x, y: integer; const transparencyKey: byte);
procedure pascalPrintBMFont(const font: PBMFont; const text: string; x, y: integer; const transparencyKey: byte);
procedure asmPrintBMFont(const font: PBMFont; const text: string; x, y: integer; const transparencyKey: byte);

function measureBMFont(const font: PBMFont; const text: string): integer;

implementation

uses Conv, Logger, Panic, Strings, VGA;

procedure loadBMFont(var font: PBMFont; const filename: string);
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
        inc(count);
      end;
    end;
  end;
  close(f);

  loadBMP(font^.bitmap, font^.filename);
  writeLog('Loaded ' + i32str(count) + ' glyphs');
end;


procedure freeBMFont(var font: PBMFont);
var
  a, count: word;
begin
  if font = nil then exit;

  count:=0;
  for a:=low(font^.glyphs) to high(font^.glyphs) do begin
    if font^.glyphs[a] <> nil then begin
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


procedure printBMFont(const font: PBMFont; const text: string; x, y: integer; const transparencyKey: byte);
begin
  pascalPrintBMFont(font, text, x, y, transparencyKey)
end;


procedure pascalPrintBMFont(const font: PBMFont; const text: string; x, y: integer; const transparencyKey: byte);
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

procedure asmPrintBMFont(const font: PBMFont; const text: string; x, y: integer; const transparencyKey: byte);
var
  a, row, col: integer;
  destX, destY: integer;
  ch: char;
  g: PBMFontGlyph;
  srcX, srcY: word;
  colour: byte;

  width: word;
begin
  if font = nil then exit;
  if x >= 320 then exit;
  if y >= 200 then exit;

  destX := x; destY := y;
  for a:=1 to length(text) do begin
    ch := text[a];
    if (ord(ch) < low(font^.glyphs)) or (ord(ch) > high(font^.glyphs)) then continue;

    g := font^.glyphs[ord(ch)];
    if g = nil then continue;

asm
{ for (row = 0; row < g^.height; row++)}
@row_init:
  mov row, 0

@row_condition:
  les si, g
  { g^.height }
  mov ax, es:[si+8]
  cmp row, ax
  jg @row_end

@row_loop:

  { for (col = 0; col < g^.width; col++) }
  @col_init:
    mov col, 0

  @col_condition:
    les si, g
    { g^.width }
    mov ax, es:[si+6]
    cmp col, ax
    jg @col_end

  @col_loop:
    les si, g

    { srcX := g^.x + col; }
    mov ax, es:[si+2]
    add ax, col
    mov srcX, ax

    { srcY := g^.y + row; }
    mov ax, es:[si+4]
    add ax, row
    mov srcY, ax

    { get pixel from:
      font^.bitmap^.data[
        srcY * font^.bitmap^.width + srcX]
    }
    les si, font
    { Jump to font^.bitmap }
    add si, 642
    mov bx, es:[si]
    { font^.bitmap^.width }
    mov dx, es:[si + 2]

    { Assign ES:SI to TBitmap }
    mov es, dx
    mov si, bx

    mov ax, es:[si]
    mov width, ax

    { data offset: srcY * font^.bitmap^.width + srcX }
    mov bx, srcY
    mul bx
    add ax, srcX

    add ax, 4
    add si, ax
    mov al, es:[si]
    mov colour, al
    cmp al, transparencyKey
    je @col_next

    { Check bounds }
    les si, g

    mov ax, destY
    add si, 12
    add ax, es:[si]
    add ax, row
    cmp ax, 0
    jl @row_next
    cmp ax, 200
    jge @skip

    mov ax, destX
    sub si, 2
    add ax, es:[si]
    add ax, col
    cmp ax, 0
    jl @col_next
    cmp ax, 320
    jge @row_next

    { Calculate offset }
    { y + g^.yoffset + row }
    les si, g

    mov ax, destY
    add si, 12
    add ax, es:[si]
    add ax, row
    mov bx, 320
    mul bx

    { destX + g^.xoffset + col }
    add ax, destX
    sub si, 2
    add ax, es:[si]
    add ax, col
    mov bx, ax

    les di, surface
    add di, bx
    mov al, colour
    mov es:[di], al

  @col_next:
    inc col
    jmp @col_condition

  @col_end:

@row_next:
  inc row
  jmp @row_condition

@row_end:
@skip:
end;

    inc(destX, g^.xadvance)
  end;
end;


function measureBMFont(const font: PBMFont; const text: string): integer;
var
  a: integer;
  ch: char;
  glyph: PBMFontGlyph;
  result: integer;
begin
  if font = nil then begin
    measureBMFont := 0;
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

  measureBMFont := result
end;

end.

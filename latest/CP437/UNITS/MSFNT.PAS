{
  Microsoft FNT (Windows Bitmap Font) utility unit
  Part of Posit-92 game framework

  Supports both monospaced and proportional Microsoft FNT
  files as used in Windows 95 and prior
}

unit MSFNT;

interface

type
  TMSFontHeader = record
    version: word;
    size: longInt;  { size of file }
    copyright: array[0..59] of char; { copyright notice }

    typ,  { type field (originally dfType) }
    points, { point size }
    vertRes, { vertical resolution }
    horizRes, { horizontal resolution }
    ascent,
    internalLeading,
    externalLeading: word;

    italic,
    underline,
    strikeout: byte;

    weight: word;
    charset: byte; { character set }

    pixWidth,  { 0 for proportional fonts }
    pixHeight: word;
    pitchAndFamily: byte;

    avgWidth,
    maxWidth: word;

    firstChar,  { first character in the font }
    lastChar,  { last charcode in the font }
    defaultChar,  { the default glyph if there's no available glyph }
    breakChar: byte;

    widthBytes: word;  { Width of row in bytes (This is always even ??) }

    device,  { unused }
    face: longInt;  { face name, the absolute byte offset in the file }
    bitsPointer,
    bitsOffset: longInt; { where the bitmap data starts }
    reserved: byte;
  end;

  PMSFontGlyph = ^TMSFontGlyph;
  TMSFontGlyph = record
    width, height: byte;
    bitmapData: array[0..0] of byte;
  end;

  PMSFont = ^TMSFont;
  TMSFont = record
    header: TMSFontHeader;
    glyphs: array[0..255] of PMSFontGlyph;
  end;

procedure loadMSFont(var output: PMSFont; const filename: string);
procedure freeMSFont(var font: PMSFont);
procedure testMSFontDisplay(const font: PMSFont; const ch: char);
procedure printMSFont(
  const font: PMSFont;
  const text: string;
  const x, y: integer;
  const colour: byte);
function measureMSFont(const font: PMSFont; const text: string): word;


implementation

uses Conv, Maths, Panic, VGA;

procedure loadMSFont(var output: PMSFont; const filename: string);
var
  fntFile: file;
  c, charIndex: word;
  bitsWidth, charoffset: word;
  charHeight: word;
  size: integer;

begin
  assign(fntFile, filename);
  {$I-} reset(fntFile, 1); {$I+}
  if IOResult <> 0 then
    panicHalt('loadMSFont: Cannot open file ' + filename);

  if output = nil then begin
    getMem(output, sizeof(TMSFont));
    for c:=0 to high(output^.glyphs) do
      output^.glyphs[c] := nil;
  end;

  blockRead(fntFile, output^.header, sizeof(TMSFontHeader));
  charHeight := output^.header.pixHeight;

{$IFDEF DEBUG}
  writeLog('--- Begin loadMSFont "' + filename + '"');
  writeLog('Copyright string: "', output^.header.copyright, '"');
  writeLog('Pixel height: ', output^.header.pixHeight);
{$ENDIF}

  for charIndex := output^.header.firstChar to output^.header.lastChar do begin
    seek(fntFile,  sizeof(TMSFontHeader) + (charIndex - output^.header.firstChar) * 4);
    blockRead(fntFile, bitsWidth, 2);
    blockRead(fntFile, charOffset, 2);

    { writeLn(charIndex, ' - width: ', bitsWidth, ' offset: ', charOffset); }

    size := sizeof(TMSFontGlyph) + ceil(bitsWidth / 8) * charHeight - 1;
    getMem(output^.glyphs[charIndex], size);
    if output^.glyphs[charIndex] = nil then begin
      writeLn('Unable to getMem with the size ', size, '!');
      exit
    end;

    with output^ do begin
      glyphs[charIndex]^.width := bitsWidth;
      glyphs[charIndex]^.height := charHeight;
    end;

    seek(fntFile, charOffset);
    blockRead(fntFile, output^.glyphs[charIndex]^.bitmapData, ceil(bitsWidth / 8) * charHeight);
  end;

  close(fntFile)
end;

{ This test can only be done in text mode }
procedure testMSFontDisplay(const font: PMSFont; const ch: char);
var
  a, b: word;
  glyph: PMSFontGlyph;
  currentByte, bitMask: byte;
begin
  if font = nil then begin
    panicHalt('testMSFontDisplay: font is nil!');
    exit
  end;

  { Test char sizes }
  {
  for b:=0 to 15 do begin
    for a:=0 to 15 do begin
      if font^.glyphs[b * 15 + a] = nil then
        write('nil ')
      else
        write('[' +
          i32str(font^.glyphs[b * 15 + a]^.width) + ', ' +
          i32str(font^.glyphs[b * 15 + a]^.height) + '] ');
    end;
    writeLn
  end;
  }

  if font^.glyphs[ord(ch)] = nil then begin
    panicHalt('testMSFontDisplay glyph ' + i32str(ord(ch)) + ' is nil!');
    exit
  end;

  { Display the char }
  glyph := font^.glyphs[ord(ch)];
  for b:=0 to glyph^.height - 1 do begin
    for a:=0 to glyph^.width - 1 do begin
      currentByte := glyph^.bitmapData[b + glyph^.height * (a div 8)];
      bitMask := 1 shl (7 - (a mod 8));

      if (currentByte and bitMask) <> 0 then
        write('#')
      else
        write('.');
    end;
    writeLn
  end;
end;

procedure freeMSFont(var font: PMSFont);
var
  a: word;
begin
  if font = nil then exit;

  for a:=0 to high(font^.glyphs) do
    if font^.glyphs[a] <> nil then begin
      freeMem(font^.glyphs[a], sizeof(font^.glyphs[a]));
      font^.glyphs[a] := nil
    end;

  freeMem(font, sizeof(TMSFont));
  font := nil
end;

procedure printMSFont(
  const font: PMSFont;
  const text: string;
  const x, y: integer;
  const colour: byte);
var
  a, b, c, left: word;
  charcode, currentByte, bitMask: byte;
  glyph: PMSFontGlyph;
begin
  if font = nil then begin
    panicHalt('printMSFont: font is nil!');
    exit
  end;

  left := 0;
  for c:=1 to length(text) do begin
    charcode := ord(text[c]);

    if font^.glyphs[charcode] = nil then
      glyph := font^.glyphs[font^.header.defaultChar]
    else
      glyph := font^.glyphs[charcode];

    for b:=0 to glyph^.height - 1 do
      for a:=0 to glyph^.width - 1 do begin
        currentByte := glyph^.bitmapData[b + glyph^.height * (a div 8)];
        bitMask := 1 shl (7 - (a mod 8));

        if (currentByte and bitMask) <> 0 then
          asmPset(x + left + a, y + b, colour);
      end;

    inc(left, font^.glyphs[charcode]^.width)
  end;
end;

function measureMSFont(const font: PMSFont; const text: string): word;
var
  a, result, width: word;
  charcode: byte;
begin
  if font = nil then begin
    panicHalt('measureMSFont: font is nil!');
    exit
  end;

  result := 0;
  for a:=1 to length(text) do begin
    charcode := ord(text[a]);

    if font^.glyphs[charcode] = nil then
      width := font^.glyphs[font^.header.defaultChar]^.width
    else
      width := font^.glyphs[charcode]^.width;

    inc(result, width)
  end;
  
  measureMSFont := result
end;

end.
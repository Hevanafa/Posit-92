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


implementation

uses Maths;

procedure loadMSFont(var output: PMSFont; const filename: string);
var
  fntFile: file;
  a, b, charIndex: word;
  bitsWidth, charoffset: word;
  charHeight: word;
  size: integer;

begin
  assign(fntFile, filename);
  {$I-} reset(fntFile, 1); {$I+}
  if IOResult <> 0 then begin
    writeLn('loadMSFont: Cannot open file ', filename);
    exit
  end;

  if output = nil then begin
    getMem(output, sizeof(TMSFont));
    for a:=0 to high(output^.glyphs) do
      output^.glyphs[a] := nil;
  end;

  blockRead(fntFile, output^.header, sizeof(TMSFontHeader));
  { writeLn('Test read'); }
  writeLn('Copyright string: "', output^.header.copyright, '"');
  writeLn('Pixel height: ', output^.header.pixHeight);
  charHeight := output^.header.pixHeight;

  for charIndex := output^.header.firstChar to output^.header.lastChar do begin
    seek(fntFile,  sizeof(TMSFontHeader) + (charIndex - output^.header.firstChar) * 4);
    blockRead(fntFile, bitsWidth, 2);
    blockRead(fntFile, charOffset, 2);

    size := sizeof(TMSFontGlyph) + ceil(bitsWidth / 8) * charHeight - 1;
    getMem(output^.glyphs[a], size);
    with output^ do begin
      glyphs[a]^.width := bitsWidth;
      glyphs[a]^.height := charHeight;
    end;

    seek(fntFile, charOffset);
    blockRead(fntFile, output^.glyphs[a]^.bitmapData, ceil(bitsWidth / 8) * charHeight);
  end;

  close(fntFile)
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

end.
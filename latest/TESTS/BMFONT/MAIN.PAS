program BMFont;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

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
    glyphs: array[0..255] of TBMFontGlyph;  { <-- This guarantees availability }
    { glyphs: array[0..255] of PBMFontGlyph; }
    { filename: string; }
    lineHeight: word;
    bitmap: pointer; { PBitmap; }
  end;

begin
  writeln('Size of TBMFontGlyph:', SizeOf(TBMFontGlyph));
  writeln('Size of TBMFont:', SizeOf(TBMFont));
end.

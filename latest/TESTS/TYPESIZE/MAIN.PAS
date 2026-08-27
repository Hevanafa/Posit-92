uses
  P92BMFON, P92TEX;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

begin
  writeln('Size of TBMFontGlyph:', SizeOf(TBMFontGlyph));
  writeln('Size of TBMFont:', SizeOf(TBMFont));

  writeln('Size of TTexture:', sizeof(TTexture));

  readln
end.

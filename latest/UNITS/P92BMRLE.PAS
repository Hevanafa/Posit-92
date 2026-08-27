unit P92BMRLE;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

interface

uses P92TEX, P92PANIC;

type
  PRLETexture = ^TRLETexture;
  TRLETexture = record
    width, height: word;
    dataSize: word;
    data: PByteArray;
  end;

{
  Convert from TTexture to TRLETexture
  Currently there's no way to convert a RLE bitmap back to a TTexture
}
procedure ConvertToRLE(const src: TTexture; var dest: TRLETexture);

procedure FreeRLETexture(var tex: TRLETexture);

procedure SprRLEOpaque(const tex: TRLETexture; const x, y: integer);
procedure SprRLE(const tex: TRLETexture; const x, y: integer; const transparencyKey: byte);
procedure UnsafeSprRLE(const tex: TRLETexture; const x, y: integer);


implementation

uses P92CONV, P92LOG, P92VGA;

procedure ConvertToRLE(const src: TTexture; var dest: TRLETexture);
var
  a, b, offset: word;
  count, colour: byte;
  writePos: word;
begin
  { Pass 1 }
  writePos := 0;
  offset := 0;

  count := 0;
  colour := src.data^[0];

  for b:=0 to src.height-1 do begin
    { write(b, ': '); }

    { for a:=0 to src^.width-1 do begin }
    a := 0;
    while true do begin
      if a >= src.width then break;

      { offset := b * src^.width + a; }

      if colour = src.data^[offset] then
        inc(count)
      else begin
        { Different pixel in the same scanline }
        { write('[', count, ', ', colour, '], '); }
        inc(writePos, 2);

        count := 1;
        colour := src.data^[offset];
      end;

      inc(a);
      inc(offset)
    end;

    { Change of scanline }
    { writeLn('[', count, ', ', colour, '],'); }
    inc(writePos, 2);

    { Reset the counter }
    count := 0;
    { Note: This doesn't handle offset overflow }
    colour := src.data^[offset];
  end;

  writeLog('Pass 1 writePos: ' + i32str(writePos));

  getMem(dest.data, writePos);
  dest.width := src.width;
  dest.height := src.height;
  dest.dataSize := writePos;


  { Pass 2 }
  writePos := 0;
  offset := 0;

  count := 0;
  colour := src.data^[0];

  for b:=0 to src.height-1 do begin
    a := 0;
    while true do begin
      if a >= src.width then break;

      if colour = src.data^[offset] then
        inc(count)
      else begin
        { Different pixel in the same scanline }
        dest.data^[writePos] := count;
        dest.data^[writePos+1] := colour;
        inc(writePos, 2);

        count := 1;
        colour := src.data^[offset];
      end;

      inc(a);
      inc(offset)
    end;

    { Change of scanline }
    dest.data^[writePos] := count;
    dest.data^[writePos+1] := colour;
    inc(writePos, 2);

    { Reset the counter }
    count := 0;
    colour := src.data^[offset];
  end;

  writeLog('Pass 2 writePos: ' + i32str(writePos));
end;

procedure FreeRLETexture(var tex: TRLETexture);
begin
  Freemem(tex.data, tex.dataSize);
end;

procedure SprRLEOpaque(const tex: TRLETexture; const x, y: integer);
var
  a: integer;
  left: integer; { similar to top & left coords like in a terminal }
  readPos: integer;
  destX, destY: integer;
  count, colour: byte;
begin
  if (y >= VGAHeight) or (x >= VGAWidth) then exit;

  destX := x; destY := y;
  readPos := 0;
  left := 0;

  while readPos < tex.dataSize do begin
    count := tex.data^[readPos];
    colour := tex.data^[readPos+1];

    if destY >= 0 then begin
      for a:=1 to count do begin
        if (destX + left < 0) or
          (destX + left >= VGAWidth) then begin
          inc(left);
          continue
        end;

        surface^[destY * VGAWidth + destX + left] := colour;
        inc(left)
      end;
    end else
      inc(left, count);

    if left >= tex.width then begin
      left := 0;
      inc(destY)
    end;

    if destY >= VGAHeight then break;

    inc(readPos, 2)
  end;
end;


procedure SprRLE(const tex: TRLETexture; const x, y: integer; const transparencyKey: byte);
var
  { Not yet using longint for prototyping }
  a: integer;
  left: integer;
  readPos, destX, destY: integer;
  count, colour: byte;
begin
  if (y >= VGAHeight) or (x >= VGAWidth) then exit;

  destX := x; destY := y;
  readPos := 0; left := 0;

  while readPos < tex.dataSize do begin
    count := tex.data^[readPos];
    colour := tex.data^[readPos+1];

    if colour <> transparencyKey then begin
      if destY >= 0 then begin
        for a:=1 to count do begin
          if (destX + left < 0) or
            (destX + left >= VGAWidth) then begin
            inc(left);
            continue
          end;

          surface^[destY * VGAWidth + destX + left] := colour;
          inc(left)
        end;
      end else
        inc(left, count);
    end else
      inc(left, count);

    if left >= tex.width then begin
      left := 0;
      inc(destY)
    end;

    if destY >= VGAHeight then break;

    inc(readPos, 2)
  end;
end;


procedure UnsafeSprRLE(const tex: TRLETexture; const x, y: integer);
var
  { Not yet using longint for prototyping }
  a: integer;
  destX, destY: integer;
  readPos, left: integer;
  count, colour: byte;
begin
  destX := x; destY := y;

  left := 0;
  readPos := 0;

  while readPos < tex.dataSize do begin
    count := tex.data^[readPos];
    colour := tex.data^[readPos+1];

    { Dangerous: no bounds check }
    for a:=1 to count do
      surface^[destY * VGAWidth + destX + left + a - 1] := colour;
    
    inc(left, count);

    if left >= tex.width then begin
      left := 0;
      inc(destY)
    end;

    inc(readPos, 2);
  end;
end;

end.

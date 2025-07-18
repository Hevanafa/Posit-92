unit BMPRLE;

interface

uses Bitmap, Panic;

type
  PRLEBitmap = ^TRLEBitmap;
  TRLEBitmap = record
    width, height: word;
    dataSize: word;
    data: array[0..0] of byte;
  end;

procedure convertToRLE(const src: PBitmap; var output: PRLEBitmap);
{ Currently there's no way to convert a RLE bitmap back to a PBitmap }

procedure freeRLEBitmap(var image: PRLEBitmap);

procedure blitRLE(const image: PRLEBitmap; const x, y: integer);
procedure blitRLE2(const image: PRLEBitmap; const x, y: integer; const transparencyKey: byte);
procedure blitRLEUnsafe(const image: PRLEBitmap; const x, y: integer);
{ Missing assembly version }

implementation

uses Conv, Logger, VGA;

{ PBitmap to TRLEBitmap conversion }
procedure convertToRLE(const src: PBitmap; var output: PRLEBitmap);
var
  a, b, offset: word;
  count, colour: byte;
  writePos: word;
begin
  if src = nil then panicHalt('convertToRLE: src is nil!');

  { Pass 1 }
  writePos := 0;
  offset := 0;

  count := 0;
  colour := src^.data[0];

  for b:=0 to src^.height-1 do begin
    { write(b, ': '); }

    { for a:=0 to src^.width-1 do begin }
    a := 0;
    while true do begin
      if a >= src^.width then break;

      { offset := b * src^.width + a; }

      if colour = src^.data[offset] then
        inc(count)
      else begin
        { Different pixel in the same scanline }
        { write('[', count, ', ', colour, '], '); }
        inc(writePos, 2);

        count := 1;
        colour := src^.data[offset];
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
    colour := src^.data[offset];
  end;

  writeLog('Pass 1 writePos: ' + i32str(writePos));

  getMem(output, sizeof(TRLEBitmap) + writePos);
  output^.width := src^.width;
  output^.height := src^.height;
  output^.dataSize := writePos;


  { Pass 2 }
  writePos := 0;
  offset := 0;

  count := 0;
  colour := src^.data[0];

  for b:=0 to src^.height-1 do begin
    a := 0;
    while true do begin
      if a >= src^.width then break;

      if colour = src^.data[offset] then
        inc(count)
      else begin
        { Different pixel in the same scanline }
        output^.data[writePos] := count;
        output^.data[writePos+1] := colour;
        inc(writePos, 2);

        count := 1;
        colour := src^.data[offset];
      end;

      inc(a);
      inc(offset)
    end;

    { Change of scanline }
    output^.data[writePos] := count;
    output^.data[writePos+1] := colour;
    inc(writePos, 2);

    { Reset the counter }
    count := 0;
    colour := src^.data[offset];
  end;

  writeLog('Pass 2 writePos: ' + i32str(writePos));
end;

procedure freeRLEBitmap(var image: PRLEBitmap);
begin
  if image = nil then exit;
  freeMem(image, sizeof(TRLEBitmap) + image^.dataSize);
  image := nil
end;

procedure blitRLE(const image: PRLEBitmap; const x, y: integer);
var
  { Not yet using longint for prototyping }
  a: integer;
  left: integer; { similar to top & left coords like in a terminal }
  readPos, destX, destY: integer;
  count, colour: byte;
begin
  if image = nil then exit;
  if y >= 200 then exit;
  if x >= 320 then exit;

  destX := x; destY := y;
  readPos := 0; left := 0;

  while readPos < image^.dataSize do begin
    count := image^.data[readPos];
    colour := image^.data[readPos+1];

    if destY >= 0 then begin
      for a:=1 to count do begin
        if (destX + left < 0) or
          (destX + left >= 320) then begin
          inc(left);
          continue
        end;

        surface^[destY * 320 + destX + left] := colour;
        inc(left)
      end;
    end else
      inc(left, count);

    if left >= image^.width then begin
      left := 0;
      inc(destY)
    end;

    if destY >= 200 then break;

    inc(readPos, 2)
  end;
end;


procedure blitRLE2(const image: PRLEBitmap; const x, y: integer; const transparencyKey: byte);
var
  { Not yet using longint for prototyping }
  a: integer;
  left: integer;
  readPos, destX, destY: integer;
  count, colour: byte;
begin
  if image = nil then exit;
  if y >= 200 then exit;
  if x >= 320 then exit;

  destX := x; destY := y;
  readPos := 0; left := 0;

  while readPos < image^.dataSize do begin
    count := image^.data[readPos];
    colour := image^.data[readPos+1];

    if colour <> transparencyKey then begin
      if destY >= 0 then begin
        for a:=1 to count do begin
          if (destX + left < 0) or
            (destX + left >= 320) then begin
            inc(left);
            continue
          end;

          surface^[destY * 320 + destX + left] := colour;
          inc(left)
        end;
      end else
        inc(left, count);
    end else
      inc(left, count);

    if left >= image^.width then begin
      left := 0;
      inc(destY)
    end;

    if destY >= 200 then break;

    inc(readPos, 2)
  end;
end;


procedure blitRLEUnsafe(const image: PRLEBitmap; const x, y: integer);
var
  { Not yet using longint for prototyping }
  a: integer;
  destX, destY: integer;
  readPos, left: integer;
  count, colour: byte;
begin
  if image = nil then exit;

  destX := x; destY := y;

  left := 0;
  readPos := 0;
  while readPos < image^.dataSize do begin
    count := image^.data[readPos];
    colour := image^.data[readPos+1];

    { Dangerous: no bounds check }
    for a:=1 to count do
      surface^[destY * 320 + destX + left + a - 1] := colour;
    
    inc(left, count);

    if left >= image^.width then begin
      left := 0;
      inc(destY)
    end;

    inc(readPos, 2);
  end;
end;

end.
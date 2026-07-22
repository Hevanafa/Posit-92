{ 1-bit BMP support }

unit MonoBMP;

interface

type
  PMonoBitmap = ^TMonoBitmap;
  TMonoBitmap = record
    width, height, bytesWidth: word;
    data: array[0..0] of byte;
  end;

procedure loadMonoBMP(var output: PMonoBitmap; const filename: string);
procedure sprMonoSlow(const image: PMonoBitmap; const x, y: integer);
procedure sprMono(
  const image: PMonoBitmap;
  const x, y: integer;
  const tint: byte);
procedure freeMonoBMP(var image: PMonoBitmap);


implementation

uses Conv, Logger, Panic, VGA;

const DEBUG = true;

procedure loadMonoBMP(var output: PMonoBitmap; const filename: string);
const
  start = $3E;
var
  f: file;
  buffer: array[1..256] of byte;
  bytesW, bytesRead: word;
  a, b: integer;
  w, h, size: integer;
  { Sanitisation }
  lastUsedByte, unusedBits: integer;
  { Used in debugging }
  s: string;

begin
  assign(f, filename);
  {$I-} reset(f, 1); {$I+} { record size is 1 --> binary mode }
  if IOResult <> 0 then
    panicHalt('loadMonoBMP: Couldn''t find "' + filename + '"!');

  seek(f, $12); blockRead(f, w, 2);
  seek(f, $16); blockRead(f, h, 2);

  { Should've been ceil instead of round }
  bytesW := round((w div 8) / 4 + 0.5) * 4;
  { Assuming the bitmap always has a size }
  if (w <= 4) and (bytesW = 0) then
    bytesW := 4;

  size := sizeOf(TMonoBitmap) + (bytesW * h) - 1;
  getMem(output, size);

  output^.width := w;
  output^.height := h;
  output^.bytesWidth := bytesW;

  if debug then begin
    with output^ do begin
      writeLog('Width:' + i32str(width));
      writeLog('Height:' + i32str(height));
      writeLog('Bytes width:' + i32str(bytesWidth));
    end;
    writeLog('Start:' + i32str(start));
  end;

  s := '';

  for b:=0 to h-1 do begin
    seek(f, start + (b * output^.bytesWidth));
    blockRead(f, buffer, output^.bytesWidth);

    { if output^.width < 8 then begin }
      { Edge case: less than 8 pixels }
      { unusedBits := 8 - output^.width;
      buffer[1] := buffer[1] and ($FF shl unusedBits)
    end else begin
    }
      lastUsedByte := output^.width div 8;
      unusedBits := 8 - (output^.width mod 8);

      if debug then begin
        writeLog('Last used byte: ' + i32str(lastUsedByte));
        writeLog('Unused bits: ' + i32str(unusedBits));
      end;

      { Sanitise the partial byte }
      { Buffer is 1-indexed }
      if output^.width mod 8 > 0 then
        buffer[lastUsedByte + 1] := buffer[lastUsedByte + 1] and ($FF shl unusedBits);

      { Zero out full padding bytes }
      for a:=lastUsedByte+2 to output^.bytesWidth do
        buffer[a] := 0;
   { end; }


    { debug last bytes of buffer }
    writeLog('Buffer on line ' + i32str(b));
    s:='';
    for a:=(output^.width div 8)+1 to output^.bytesWidth do begin
      s:=s+i8hexStr(buffer[a])+' '
    end;
    writeLog(s);

    if debug then
      writeLog('Finished reading line ' + i32str(b));

    { debug buffer lines }

    if debug then begin
      writeLog('Buffer line ' + i32str(b));
      s := '';

      for a:=low(buffer) to low(buffer) + output^.bytesWidth - 1 do
        s:=s + i8hexStr(buffer[a]) + ' ';
      writeLog(s);
    end;

    { bottom to top }
    Move(
      buffer[1],
      output^.data[(h-b-1) * output^.bytesWidth],
      output^.bytesWidth);

    {
    writeLog('After move row ' + i32str(b));
    s:='';
    if debug then begin
      for a:=0 to output^.bytesWidth do
        s := s + i8hexStr(output^.data[(h-b-1) * output^.bytesWidth + a]) + ' ';
      writeLog(s);
    end;
    }
  end;

  close(f)
end;


{ Assume bit value of 0 is transparent }
procedure sprMonoSlow(const image: PMonoBitmap; const x, y: integer);
var
  row, col, bitIndex: integer;
  byteIndex: integer;
  b: byte;
begin
  if image = nil then exit;
  for row:=0 to image^.height - 1 do begin
    byteIndex := row * image^.bytesWidth;
    for col:=0 to image^.width - 1 do begin
      bitIndex:=7-(col mod 8);
      b := image^.data[byteIndex + (col div 8)];
      if ((b shr bitIndex) and 1) = 1 then
        asmPset(x + col, y + row, 15);
    end;
  end;
end;


{ Assume bit value of 0 is transparent }
procedure sprMono(
  const image: PMonoBitmap;
  const x, y: integer;
  const tint: byte);
var
  row, byteCol: integer;
  screenX: integer;
  b: byte;
begin
  if image = nil then exit;

  for row := 0 to image^.height - 1 do begin
    screenX := x;

    for byteCol := 0 to image^.bytesWidth - 1 do begin
      b := image^.data[row * image^.bytesWidth + byteCol];

      if b <> 0 then begin
        if (b and $80) <> 0 then asmPset(screenX + 0, y + row, tint);
        if (b and $40) <> 0 then asmPset(screenX + 1, y + row, tint);
        if (b and $20) <> 0 then asmPset(screenX + 2, y + row, tint);
        if (b and $10) <> 0 then asmPset(screenX + 3, y + row, tint);

        if (b and $08) <> 0 then asmPset(screenX + 4, y + row, tint);
        if (b and $04) <> 0 then asmPset(screenX + 5, y + row, tint);
        if (b and $02) <> 0 then asmPset(screenX + 6, y + row, tint);
        if (b and $01) <> 0 then asmPset(screenX + 7, y + row, tint);
      end;

      inc(screenX, 8)
    end;
  end;
end;


procedure freeMonoBMP(var image: PMonoBitmap);
begin
  if image = nil then exit;
  freeMem(image, sizeOf(TMonoBitmap) + (image^.bytesWidth * image^.height) - 1);
  image := nil  { avoids dangling pointer }
end;

end.

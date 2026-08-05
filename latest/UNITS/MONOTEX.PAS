{
  1-bit BMP support unit
  Part of Posit-92 game engine
}

unit MonoTex;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

interface

uses P92VGA;

type
  PMonoTexture = ^TMonoTexture;
  TMonoTexture = record
    width, height, bytesWidth: word;
    data: PByteArray;
  end;

{ Requires a 1-bpp bitmap file }
procedure LoadMonoTex(var tex: TMonoTexture; const filename: string);
procedure FreeMonoTex(var tex: TMonoTexture);

procedure SprMonoSlow(const tex: TMonoTexture; const x, y: integer);

procedure SprMono(
  const tex: TMonoTexture;
  const x, y: integer;
  const tint: byte);


implementation

uses Conv, Logger, Maths, Panic, MonoVGA;

const DEBUG = true;

procedure LoadMonoTex(var tex: TMonoTexture; const filename: string);
const
  Start = $3E;
var
  f: file;
  buffer: array[1..256] of byte;
  bytesWidth, bytesRead: word;
  a, b: integer;
  w, h, size: integer;
  { Sanitisation }
  lastUsedByte, unusedBits: integer;
  { Used in debugging }
  s: string;

begin
  if assigned(tex.data) then begin
    WriteLog('Warning: LoadMonoTex: output.data is already assigned');
    WriteLog('when attempting to load ' + filename);
  end;

  assign(f, filename);
  {$I-} reset(f, 1); {$I+} { record size is 1 --> binary mode }
  if IOResult <> 0 then
    panicHalt('loadMonoBMP: Couldn''t find "' + filename + '"!');

  seek(f, $12); blockRead(f, w, 2);
  seek(f, $16); blockRead(f, h, 2);

  bytesWidth := ceil((w div 8) / 4) * 4;
  { Assuming that the bitmap always has a size }
  if (w <= 4) and (bytesWidth = 0) then
    bytesWidth := 4;

  size := bytesWidth * h;
  GetMem(tex.data, size);

  tex.width := w;
  tex.height := h;
  tex.bytesWidth := bytesWidth;

  if debug then begin
    writeLog('Width:' + i32str(tex.width));
    writeLog('Height:' + i32str(tex.height));
    writeLog('Bytes width:' + i32str(tex.bytesWidth));
    writeLog('Start:' + i32str(Start));
  end;

  s := '';

  for b:=0 to h-1 do begin
    seek(f, Start + (b * tex.bytesWidth));
    blockRead(f, buffer, tex.bytesWidth);

    lastUsedByte := tex.width div 8;
    unusedBits := 8 - (tex.width mod 8);

    if debug then begin
      writeLog('Last used byte: ' + i32str(lastUsedByte));
      writeLog('Unused bits: ' + i32str(unusedBits));
    end;

    { Sanitise the partial byte }
    { Buffer is 1-indexed }
    if tex.width mod 8 > 0 then
      buffer[lastUsedByte + 1] := buffer[lastUsedByte + 1] and ($FF shl unusedBits);

    { Zero out full padding bytes }
    for a:=lastUsedByte+2 to tex.bytesWidth do
      buffer[a] := 0;

    { Debug last bytes of buffer }
    {
    writeLog('Buffer on line ' + i32str(b));

    s:='';
    for a:=(tex.width div 8)+1 to tex.bytesWidth do begin
      s:=s+i8hexStr(buffer[a])+' '
    end;
    writeLog(s);

    if debug then
      writeLog('Finished reading line ' + i32str(b));
    }

    { Debug buffer lines }
    {
    if debug then begin
      writeLog('Buffer line ' + i32str(b));
      s := '';

      for a:=low(buffer) to low(buffer) + tex.bytesWidth - 1 do
        s:=s + i8hexStr(buffer[a]) + ' ';
      writeLog(s);
    end;
    }

    { bottom to top }
    Move(
      buffer[1],
      tex.data^[(h-b-1) * tex.bytesWidth],
      tex.bytesWidth);

    {
    writeLog('After move row ' + i32str(b));
    s:='';
    if debug then begin
      for a:=0 to tex^.bytesWidth do
        s := s + i8hexStr(tex^.data[(h-b-1) * tex^.bytesWidth + a]) + ' ';
      writeLog(s);
    end;
    }
  end;

  close(f)
end;


{ Assume bit value of 0 is transparent }
procedure SprMonoSlow(const tex: TMonoTexture; const x, y: integer);
var
  row, col, bitIndex: word;
  byteIndex: word;
  b: byte;
begin
  for row:=0 to tex.height - 1 do begin
    byteIndex := row * tex.bytesWidth;

    for col:=0 to tex.width - 1 do begin
      bitIndex:=7-(col mod 8);
      b := tex.data^[byteIndex + (col div 8)];
      if ((b shr bitIndex) and 1) = 1 then
        asmPset(x + col, y + row, 15);
    end;
  end;
end;


{ Assume bit value of 0 is transparent }
procedure SprMono(
  const tex: TMonoTexture;
  const x, y: integer;
  const tint: byte);
var
  row, byteCol: integer;
  screenX: integer;
  b: byte;
begin
  for row := 0 to tex.height - 1 do begin
    screenX := x;

    for byteCol := 0 to tex.bytesWidth - 1 do begin
      b := tex.data^[row * tex.bytesWidth + byteCol];

      if b <> 0 then begin
        if (b and $80) <> 0 then PSet1BPP(screenX + 0, y + row, tint);
        if (b and $40) <> 0 then PSet1BPP(screenX + 1, y + row, tint);
        if (b and $20) <> 0 then PSet1BPP(screenX + 2, y + row, tint);
        if (b and $10) <> 0 then PSet1BPP(screenX + 3, y + row, tint);

        if (b and $08) <> 0 then PSet1BPP(screenX + 4, y + row, tint);
        if (b and $04) <> 0 then PSet1BPP(screenX + 5, y + row, tint);
        if (b and $02) <> 0 then PSet1BPP(screenX + 6, y + row, tint);
        if (b and $01) <> 0 then PSet1BPP(screenX + 7, y + row, tint);
      end;

      inc(screenX, 8)
    end;
  end;
end;


procedure FreeMonoTex(var tex: TMonoTexture);
begin
  if assigned(tex.data) then begin
    freemem(tex.data, tex.bytesWidth * tex.height);
    tex.data := nil
  end;

  tex.bytesWidth := 0;
  tex.width := 0;
  tex.height := 0
end;

end.

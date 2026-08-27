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

procedure SprMonoBaseRef(const tex: TMonoTexture; const x, y: integer);
procedure SprMono8(const tex: TMonoTexture; const x, y: integer);


implementation

uses P92CONV, P92LOG, P92MATHS, Panic, MonoVGA;

const DEBUG = true;

procedure LoadMonoTex(var tex: TMonoTexture; const filename: string);
var
  f: file;
  bytesWidth, bytesRead: word;
  a, b: integer;

  bpp: word;
  dataOffset: longint;
  w, h, size: longint;

  { Sanitisation }
  rowStart: word;
  lastUsedByte, unusedBits: integer;
begin
  if assigned(tex.data) then begin
    WriteLog('Warning: LoadMonoTex: output.data is already assigned');
    WriteLog('when attempting to load ' + filename);
  end;

  assign(f, filename);
  {$I-} reset(f, 1); {$I+} { record size is 1 --> binary mode }
  if IOResult <> 0 then
    PanicHalt('LoadMonoBMP: Couldn''t find "' + filename + '"!');

  seek(f, $1C); BlockRead(f, bpp, 2);
  if bpp <> 1 then
    PanicHalt('LoadMonoBMP: "' + filename + '" is not 1-bpp');

  seek(f, $0A);  BlockRead(f, dataOffset, 4);
  seek(f, $12);  BlockRead(f, w, 4);
  seek(f, $16);  BlockRead(f, h, 4);

  bytesWidth := ((w + 31) div 32) * 4;

  size := bytesWidth * h;
  GetMem(tex.data, size);

  tex.width := w;
  tex.height := h;
  tex.bytesWidth := bytesWidth;

  if debug then begin
    writeLog('Width:' + i32str(tex.width));
    writeLog('Height:' + i32str(tex.height));
    writeLog('Bytes width:' + i32str(tex.bytesWidth));
    writeLog('Start:' + i32str(dataOffset));
  end;

  for b:=0 to h-1 do begin
    seek(f, dataOffset + (b * tex.bytesWidth));
    rowStart := (h-b-1) * tex.bytesWidth;

    { Fill from bottom to top }
    BlockRead(f, tex.data^[rowStart], tex.bytesWidth);

    lastUsedByte := tex.width div 8;
    unusedBits := 8 - (tex.width mod 8);

    if debug then begin
      writeLog('Last used byte: ' + i32str(lastUsedByte));
      writeLog('Unused bits: ' + i32str(unusedBits));
    end;

    { Sanitise the partial byte }
    if tex.width mod 8 > 0 then
      tex.data^[rowStart + lastUsedByte] := tex.data^[rowStart + lastUsedByte] and ($FF shl unusedBits);

    { Zero out full padding bytes }
    for a := rowStart + lastUsedByte + 1 to rowStart + tex.bytesWidth - 1 do
      tex.data^[a] := 0;
  end;

  close(f)
end;


{ Assume bit value of 0 is transparent }
procedure SprMonoBaseRef(const tex: TMonoTexture; const x, y: integer);
var
  row, col, bitIndex: word;
  byteIndex: word;
  b: byte;
begin
  for row:=0 to tex.height - 1 do begin
    byteIndex := row * tex.bytesWidth;

    for col:=0 to tex.width - 1 do begin
      bitIndex := 7 - (col mod 8);
      b := tex.data^[byteIndex + (col div 8)];

      if ((b shr bitIndex) and 1) = 1 then
        PSet1BPP(x + col, y + row, 15);
    end;
  end;
end;


{ Assume bit value of 0 is transparent }
procedure SprMono8(const tex: TMonoTexture; const x, y: integer);
const
  bit = 1;
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
        if (b and $80) <> 0 then PSet1BPP(screenX + 0, y + row, bit);
        if (b and $40) <> 0 then PSet1BPP(screenX + 1, y + row, bit);
        if (b and $20) <> 0 then PSet1BPP(screenX + 2, y + row, bit);
        if (b and $10) <> 0 then PSet1BPP(screenX + 3, y + row, bit);

        if (b and $08) <> 0 then PSet1BPP(screenX + 4, y + row, bit);
        if (b and $04) <> 0 then PSet1BPP(screenX + 5, y + row, bit);
        if (b and $02) <> 0 then PSet1BPP(screenX + 6, y + row, bit);
        if (b and $01) <> 0 then PSet1BPP(screenX + 7, y + row, bit);
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

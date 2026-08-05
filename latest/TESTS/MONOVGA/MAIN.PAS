
uses
  Conv, Timing, P92VGA;

const
  Palette: array[0..1] of Byte = ($00, $46);

var
  { Lookup table }
  LUT: array[0..255, 0..7] of byte;

procedure InitLUT;
var
  a: word;
  bit: byte;
begin
  for a:=0 to 255 do
    for bit := 7 downto 0 do
      if (a and (1 shl bit)) <> 0 then
        LUT[a][7 - bit] := palette[1]
      else
        LUT[a][7 - bit] := palette[0];
end;

procedure Cls1BPP(const colour: byte);
begin
  FillChar(surface^, VGAWidth * VGAHeight div 8, colour)
end;

procedure PSet1BPP(const x, y: integer; const bit: byte);
var
  offset: word;
  mask: byte;
begin
  offset := (y * (VGAWidth div 8)) + (x div 8);
  mask := 1 shl (7 - x mod 8);

  if bit <> 0 then
    surface^[offset] := surface^[offset] or mask
  else
    surface^[offset] := surface^[offset] and not mask;
end;

procedure Print1BPP(const text: string; const x, y: integer; const bit: byte);
var
  idx: integer;
  ch: char;
  xOffset: integer;
  row, col: word;
  mask: byte;
begin
  xOffset := 0;

  for idx := 1 to length(text) do begin
    ch := text[idx];

    for row := 0 to 7 do begin
      mask := BorrowCGAFont^[ord(ch), row];

      if mask = 0 then continue;

      for col := 0 to 7 do
        if (mask and ($80 shr col)) <> 0 then
          PSet1BPP(x + xOffset + col, y + row, bit);
    end;

    inc(xOffset, 8);
  end;
end;

procedure Present1BPP;
var
  src, dest: word;
begin
  dest := 0;

  for src := 0 to (VGAWidth * VGAHeight div 8) - 1 do begin
    move(LUT[surface^[src]], mem[$A000:dest], 8);
    inc(dest, 8)
  end;
end;

procedure AsmPresent1BPP;
var
  surfacePtr: PByteArray;
  src: word;
  b: byte;
begin
  surfacePtr := surface;

  for src := 0 to (VGAWidth * VGAHeight div 8) - 1 do begin
    b := surfacePtr^[src];

    asm
      push es

      mov ax, $A000
      mov es, ax
      xor di, di

      xor bh, bh
      mov bl, [b]
      shl bx, 1
      shl bx, 1
      shl bx, 1

      mov si, offset LUT
      add si, bx

      { 4x movsw = 8 bytes }
      movsw
      movsw
      movsw
      movsw

      pop es
    end;
  end;
end;

procedure AsmPresent1BPP_2;
var
  surfacePtr: PByteArray;
  surfaceSegment: word;
begin
  surfacePtr := surface;

  asm
    push ds
    mov dx, ds

    mov ax, word ptr [surfacePtr + 2]
    mov [surfaceSegment], ax

    { push es }

    mov ax, $A000
    mov es, ax
    xor di, di

    mov si, word ptr [surfacePtr]

    mov cx, 8000  { vgawidth * vgaheight div 8 }

  @loop:
    mov ds, [surfaceSegment]
    lodsb
    mov ds, dx

    xor ah, ah
    mov bx, ax
    shl bx, 1
    shl bx, 1
    shl bx, 1
    add bx, offset LUT

    mov ax, [bx]
    stosw
    mov ax, [bx + 2]
    stosw
    mov ax, [bx + 4]
    stosw
    mov ax, [bx + 6]
    stosw

    dec cx
    jnz @loop

    pop ds
  end;
end;

procedure Present100;
var
  startTick, endTick: double;
  a: word;
begin
  startTick := GetTimer;

  { Without LUT: 6.8057s
    With LUT: 2.0417s
    AsmPresent: 1.1704s
    AsmPresent_2: 0.9346s }
  for a:=1 to 100 do
    AsmPresent1BPP;
    { AsmPresent1BPP_2; }

  endTick := GetTimer;

  Print1BPP('100 present ops done in ' + F32Str(endTick - startTick) + 's', 0, 0, $00);

  Present1BPP;
end;

begin
  LoadCGAFont;

  InitBuffer(320, 200);
  InitMode13h;

  InitLUT;

  Cls1BPP($FF);

  { PSet1BPP(32, 10, 0); }
  Print1BPP('Hello from MONOVGA!', 8, 8, 0);

  { Present1BPP; }
  Present100;

  readln;

  FreeBuffer;
  InitModeText;
end.

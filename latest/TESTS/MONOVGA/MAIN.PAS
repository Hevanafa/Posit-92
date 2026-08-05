
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

procedure Print1BPP(const text: string; const x, y: integer; const bit: byte); forward;

procedure Cls1BPP(const colour: byte);
begin
  FillChar(surface^, VGAWidth * VGAHeight div 8, colour)
end;

procedure PSet1BPP(const x, y: integer; const bit: byte);
var
  offset: word;
  mask: byte;
begin
  { Bounds check }
  if (x < 0) or (x >= VGAWidth)
    or (y < 0) or (y >= VGAHeight) then exit;

  offset := (y * (VGAWidth div 8)) + (x div 8);
  mask := 1 shl (7 - x mod 8);

  if bit <> 0 then
    surface^[offset] := surface^[offset] or mask
  else
    surface^[offset] := surface^[offset] and not mask;
end;

procedure AsmPSet1BPP(const x, y: integer; bit: byte);
var
  offset: word;
  mask: byte;
begin
  { Bounds check }
  if (x < 0) or (x >= VGAWidth)
    or (y < 0) or (y >= VGAHeight) then exit;

  bit := bit and 1;

  asm
    mov ax, y
    mov bx, ax
    shl ax, 6
    shl bx, 4
    add ax, bx
    mov bx, x
    mov cx, bx
    shr bx, 3
    add bx, ax
    mov offset, bx

    { build mask }
    and cx, 7  { x mod 8 }
    mov ch, 7
    sub ch, cl  { 7 - (x mod 8) }
    mov cl, ch
    mov al, 1
    shl al, cl

    les di, surface
    add di, ofs
    mov ah, al
    not ah
    and ah, es:[di]

    mov bl, bit
    neg bl
    and al, bl
    or al, ah
    mov es:[di], al
  end;
end;

procedure PSet10000;
var
  a: word;
  startTick, endTick: double;
begin
  startTick := GetTimer;

  { 0.0673s }
  for a:=1 to 10000 do
    AsmPSet1BPP(random(VGAWidth + 10) - 5, random(VGAHeight + 10) - 5, 1);

  endTick := GetTimer;

  Print1BPP('10000 operations done in ' + F32Str(endTick - startTick) + 's', 0, 0, 1)
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
  src, dest: word;
  b: byte;
begin
  surfacePtr := surface;
  dest := 0;

  for src := 0 to (VGAWidth * VGAHeight div 8) - 1 do begin
    b := surfacePtr^[src];

    asm
      push es

      mov ax, $A000
      mov es, ax
      mov di, [dest]

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

      mov [dest], di

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
    AsmPresent: 1.3009s, 1.1956s }
  for a:=1 to 100 do
    AsmPresent1BPP;

  { AsmPresent_2: 0.9346s }
  { for a:=1 to 100 do
    AsmPresent1BPP_2; }

  endTick := GetTimer;

  Print1BPP('100 present ops done in ' + F32Str(endTick - startTick) + 's', 0, 0, 1);

  Present1BPP;
end;

begin
  LoadCGAFont;

  InitBuffer(320, 200);
  InitMode13h;

  InitLUT;

  Cls1BPP($00);

  { PSet1BPP(32, 10, 0); }
  { Print1BPP('Hello from MONOVGA!', 8, 8, 1); }

  PSet10000;

  Present1BPP;
  { Present100; }

  readln;

  FreeBuffer;
  InitModeText;
end.

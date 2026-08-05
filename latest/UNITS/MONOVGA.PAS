unit MonoVGA;

interface

type
  TPalettePair = array[0..1] of byte;

{ procedure SetPalette(pal: TPalettePair); }
procedure Cls1BPP(const bit: byte);
procedure PSet1BPP(const x, y: integer; bit: byte);
procedure Print1BPP(const text: string; const x, y: integer; const bit: byte);
procedure Present1BPP;


implementation

uses P92VGA;

const
  palette: TPalettePair = ($00, $46);
var
  { Lookup table, assigned by InitLUT with palette colours }
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

procedure PascalPresent1BPP; forward;
procedure AsmPresent1BPP; forward;

{
procedure SetPalette(pal: TPalettePair);
begin
  palette := pal
end;
}


procedure Cls1BPP(const bit: byte);
begin
  if (bit and 1) = 1 then
    FillChar(surface^, VGAWidth * VGAHeight div 8, $FF)
  else
    FillChar(surface^, VGAWidth * VGAHeight div 8, $00)
end;

procedure PSet1BPP(const x, y: integer; bit: byte);
var
  offset: word;
  mask: byte;
begin
  { Bounds check }
  if (x < 0) or (x >= VGAWidth)
    or (y < 0) or (y >= VGAHeight) then exit;

  offset := (y * (VGAWidth div 8)) + (x div 8);
  mask := 1 shl (7 - x mod 8);
  bit := bit and 1;

  if bit <> 0 then
    surface^[offset] := surface^[offset] or mask
  else
    surface^[offset] := surface^[offset] and not mask;
end;

procedure AsmPSet1BPP(const x, y: integer; bit: byte);
var
  bufOffset: word;
  mask: byte;
begin
  { Bounds check }
  if (x < 0) or (x >= VGAWidth)
    or (y < 0) or (y >= VGAHeight) then exit;

  bit := bit and 1;

  bufOffset := (y * (VGAWidth div 8)) + (x div 8);

  asm
    { Load AL with `mask` }
    mov cx, x
    and cx, 7
    mov al, 7
    sub al, cl
    mov cl, al
    mov al, 1
    shl al, cl

    les di, surface
    add di, bufOffset
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
begin
  PascalPresent1BPP;
  { AsmPresent1BPP }
end;

procedure PascalPresent1BPP;
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

begin
  InitLUT
end.


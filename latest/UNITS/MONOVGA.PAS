unit MonoVGA;

interface

procedure Present1BPP;


implementation

uses P92VGA;

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


procedure AsmPresent1BPP; forward;

procedure Present1BPP;
begin
  AsmPresent1BPP
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
end;

end.


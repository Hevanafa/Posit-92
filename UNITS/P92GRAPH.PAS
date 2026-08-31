{
  Drawing primitives
  Part of Posit-92 game engine
}

unit P92GRAPH;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

interface

procedure Circ(const cx, cy, radius: integer; const colour: byte);
procedure PascalCirc(const cx, cy, radius: integer; const colour: byte);
procedure AsmCircUnsafe(const cxi, cyi, radius: integer; const colour: byte);
procedure AsmCirc(const cxi, cyi, radius: integer; const colour: byte);

procedure CircFill(const cx, cy, radius: integer; const colour: byte);
procedure PascalCircFill(const cx, cy, radius: integer; const colour: byte);
procedure AsmCircFill(const cxi, cyi, radius: integer; const colour: byte);

{ Optimised horizontal line procedure based on HLineBase }
procedure HLine(const x0, x1, y: integer; const colour: byte);

{ Optimised vertical line procedure based on VLineBase }
procedure VLine(const x, y0, y1: integer; const colour: byte);

procedure Line(const x0, y0, x1, y1: integer; const colour: byte);
procedure PascalLine(x1, y1, x2, y2: integer; const colour: byte);
procedure AsmLine(x0, y0, x1, y1: integer; const colour: byte);

{ Forward calls to HLine and VLine }
procedure Rect(const x0, y0, x1, y1: integer; const colour: byte);

{ Forward calls to HLine }
procedure RectFill(const x0, y0, x1, y1: integer; const colour: byte);

procedure CircFillDither(const cx, cy, radius: integer; const colour: byte);

procedure RectFillDither(const x0, y0, x1, y1: integer; const colour: byte);
procedure RectFillDitherBase(x0, y0, x1, y1: integer; const colour: byte);
procedure AsmRectFillDither(const x0, y0, x1, y1: integer; const colour: byte);

procedure Tri(const x0, y0, x1, y1, x2, y2: integer; const colour: byte);
procedure TriFill(x0, y0, x1, y1, x2, y2: integer; const colour: byte);


implementation

uses P92MATHS, P92VGA;


procedure Circ(const cx, cy, radius: integer; const colour: byte);
begin
  AsmCirc(cx, cy, radius, colour)
end;

procedure PascalCirc(const cx, cy, radius: integer; const colour: byte);
var
  x, y, p: integer;
begin
  x := 0;
  y := radius;
  p := 3 - 2 * radius;

  while x <= y do begin
    AsmPset(cx + x, cy + y, colour);
    AsmPset(cx - x, cy + y, colour);
    AsmPset(cx + x, cy - y, colour);
    AsmPset(cx - x, cy - y, colour);
    AsmPset(cx + y, cy + x, colour);
    AsmPset(cx - y, cy + x, colour);
    AsmPset(cx + y, cy - x, colour);
    AsmPset(cx - y, cy - x, colour);

    if p < 0 then
      p := p+4 * x+6
    else begin
      p := p+4 * (x-y)+10;
      dec(y);
    end;
    inc(x);
  end;
end;

{ Unsafe: No bounds check (faster) }
procedure AsmCircUnsafe(const cxi, cyi, radius: integer; const colour: byte);
var
  x, y, p: integer;
begin
  x := 0;
  y := radius;
  p := 3 - 2 * radius;

  while x <= y do begin
asm
  { AsmPset(cxi + x, cyi + y, colour); }

  { Pset }
  { Offset: y * 320 + x }
  mov ax, cyi
  add ax, y
  mov bx, 320
  mul bx      { ax = ax * bx }
  add ax, cxi
  add ax, x
  mov bx, ax

  les di, surface
  add di, bx
  mov al, colour
  mov es:[di], al

  { AsmPset(cxi - x, cyi + y, colour); }
  sub di, x
  sub di, x
  mov es:[di], al

  { AsmPset(cxi + x, cyi - y, colour); }
  mov ax, cyi
  sub ax, y
  mov bx, 320
  mul bx
  add ax, cxi
  add ax, x
  mov bx, ax

  les di, surface  { reset ES:DI to surface }
  add di, bx
  mov al, colour
  mov es:[di], al

  { AsmPset(cxi - x, cyi - y, colour); }
  sub di, x
  sub di, x
  mov es:[di], al
end;


asm
  { AsmPset(cxi + y, cyi + x, colour); }
  mov ax, cyi
  add ax, x
  mov bx, 320
  mul bx
  add ax, cxi
  add ax, y
  mov bx, ax

  les di, surface  { reset ES:DI to surface }
  add di, bx
  mov al, colour
  mov es:[di], al

  { AsmPset(cxi - y, cyi + x, colour); }
  sub di, y
  sub di, y
  mov es:[di], al

  { AsmPset(cxi + y, cyi - x, colour); }
  mov ax, cyi
  sub ax, x
  mov bx, 320
  mul bx
  add ax, cxi
  add ax, y
  mov bx, ax

  les di, surface  { reset ES:DI to surface }
  add di, bx
  mov al, colour
  mov es:[di], al

  { AsmPset(cxi - y, cyi - x, colour); }
  sub di, y
  sub di, y
  mov es:[di], al
end;

    if p < 0 then
      p := p+4 * x+6
    else begin
      p := p+4 * (x-y)+10;
      dec(y);
    end;
    inc(x);
  end;
end;


procedure AsmCirc(const cxi, cyi, radius: integer; const colour: byte);
var
  x, y, p: integer;
begin
  x := 0;
  y := radius;
  p := 3 - 2 * radius;

  while x <= y do begin
asm
  { Note: Check coordinates first before plotting }
  
  mov ax, cyi
  add ax, y
  cmp ax, 200
  jge @segment_3

@segment_1:
  mov ax, cxi
  add ax, x
  cmp ax, 320
  jge @segment_2

  { AsmPset(cxi + x, cyi + y, colour); }
  mov ax, cyi
  add ax, y
  mov bx, 320
  mul bx      { ax = ax * bx }
  add ax, cxi
  add ax, x
  mov bx, ax

  les di, surface
  add di, bx
  mov al, colour
  mov es:[di], al

@segment_2:
  mov ax, cxi
  sub ax, x
  cmp ax, 0
  jl @segment_3

  { AsmPset(cxi - x, cyi + y, colour); }
  mov ax, cyi
  add ax, y
  mov bx, 320
  mul bx      { ax = ax * bx }
  add ax, cxi
  sub ax, x
  mov bx, ax

  les di, surface
  add di, bx
  mov al, colour
  mov es:[di], al


@segment_3:
  mov ax, cyi
  sub ax, y
  cmp ax, 0
  jl @skip

  mov ax, cxi
  add ax, x
  cmp ax, 320
  jge @segment_4

  { AsmPset(cxi + x, cyi - y, colour); }
  mov ax, cyi
  sub ax, y
  mov bx, 320
  mul bx
  add ax, cxi
  add ax, x
  mov bx, ax

  les di, surface  { reset ES:DI to surface }
  add di, bx
  mov al, colour
  mov es:[di], al

@segment_4:
  mov ax, cxi
  sub ax, x
  cmp ax, 0
  jl @skip

  { AsmPset(cxi - x, cyi - y, colour); }
  mov ax, cyi
  sub ax, y
  mov bx, 320
  mul bx
  add ax, cxi
  sub ax, x
  mov bx, ax

  les di, surface  { reset ES:DI to surface }
  add di, bx
  mov al, colour
  mov es:[di], al

@skip:
end;


asm
  { Note: Check coordinates first before plotting }
  mov ax, cyi
  add ax, x
  cmp ax, 200
  jge @segment_3

@segment_1:
  mov ax, cxi
  add ax, y
  cmp ax, 320
  jge @segment_2

  { AsmPset(cxi + y, cyi + x, colour); }
  mov ax, cyi
  add ax, x
  mov bx, 320
  mul bx
  add ax, cxi
  add ax, y
  mov bx, ax

  les di, surface  { reset ES:DI to surface }
  add di, bx
  mov al, colour
  mov es:[di], al

@segment_2:
  mov ax, cxi
  sub ax, y
  cmp ax, 0
  jl @segment_3

  { AsmPset(cxi - y, cyi + x, colour); }
  mov ax, cyi
  add ax, x
  mov bx, 320
  mul bx
  add ax, cxi
  sub ax, y
  mov bx, ax

  les di, surface  { reset ES:DI to surface }
  add di, bx
  mov al, colour
  mov es:[di], al


@segment_3:
  mov ax, cyi
  sub ax, x
  cmp ax, 0
  jl @skip

  mov ax, cxi
  add ax, y
  cmp ax, 320
  jge @segment_4

  { AsmPset(cxi + y, cyi - x, colour); }
  mov ax, cyi
  sub ax, x
  mov bx, 320
  mul bx
  add ax, cxi
  add ax, y
  mov bx, ax

  les di, surface  { reset ES:DI to surface }
  add di, bx
  mov al, colour
  mov es:[di], al

@segment_4:
  mov ax, cxi
  sub ax, y
  cmp ax, 0
  jl @skip

  { AsmPset(cxi - y, cyi - x, colour); }
  mov ax, cyi
  sub ax, x
  mov bx, 320
  mul bx
  add ax, cxi
  sub ax, y
  mov bx, ax

  les di, surface  { reset ES:DI to surface }
  add di, bx
  mov al, colour
  mov es:[di], al

@skip:
end;

    if p < 0 then
      p := p+4 * x+6
    else begin
      p := p+4 * (x-y)+10;
      dec(y);
    end;
    inc(x);
  end;
end;


procedure CircFill(const cx, cy, radius: integer; const colour: byte);
begin
  AsmCircFill(cx, cy, radius, colour)
end;

procedure PascalCircFill(const cx, cy, radius: integer; const colour: byte);
var
  x, y, p: integer;
  a: integer;
begin
  x := 0;
  y := radius;
  p := 3 - 2 * radius;

  while x <= y do begin
    for a:=cx-x to cx+x do begin
      AsmPset(a, cy + y, colour);
      AsmPset(a, cy - y, colour)
    end;
    for a:=cx-y to cx+y do begin
      AsmPset(a, cy + x, colour);
      AsmPset(a, cy - x, colour)
    end;

    if p < 0 then
      p := p+4 * x+6
    else begin
      p := p+4 * (x-y)+10;
      dec(y)
    end;

    inc(x)
  end;
end;

procedure AsmCircFill(const cxi, cyi, radius: integer; const colour: byte);
var
  x, y, p: integer;
  startX, endX: word;
  a: integer;
  reps: word;
  rem: byte;
begin
  x := 0;
  y := radius;
  p := 3 - 2 * radius;

  while x <= y do begin
    startX := cxi - x;
    endX := cxi + x;
    if startX < 0 then startX := 0;
    if endX >= 320 then endX := 319;

    reps := (1 + endX - startX) div 2;
    rem := (1 + endX - startX) and 1;

asm
  mov ax, cyi
  add ax, y
  cmp ax, 200
  jge @segment_2

@segment_1:
  { HLine(startX, endX, cyi + y, colour); }
  { Start offset: y * 320 + x }
  mov ax, cyi
  add ax, y
  mov bx, 320
  mul bx      { ax = ax * bx }
  add ax, startX
  mov bx, ax

  les di, surface
  add di, bx

  mov ah, colour
  mov al, colour
  cld
  mov cx, reps
  rep stosw

  test rem, 1
  jz @segment_2
  mov es:[di], al

@segment_2:
  mov ax, cyi
  sub ax, y
  cmp ax, 0
  jl @skip

  { HLine(startX, endX, cyi - y, colour); }
  { Start offset: y * 320 + x }
  mov ax, cyi
  sub ax, y
  mov bx, 320
  mul bx      { ax = ax * bx }
  add ax, startX
  mov bx, ax

  les di, surface
  add di, bx

  mov ah, colour
  mov al, colour
  cld
  mov cx, reps
  rep stosw

  test rem, 1
  jz @skip
  mov es:[di], al
@skip:
end;


    startX := cxi - y;
    endX := cxi + y;
    if startX < 0 then startX := 0;
    if endX >= 320 then endX := 319;

    reps := (1 + endX - startX) div 2;
    rem := (1 + endX - startX) and 1;

asm
  mov ax, cyi
  add ax, x
  cmp ax, 200
  jge @segment_2

@segment_1:
  { HLine(startX, endX, cyi + x, colour); }
  { Start offset: y * 320 + x }
  mov ax, cyi
  add ax, x
  mov bx, 320
  mul bx      { ax = ax * bx }
  add ax, startX
  mov bx, ax

  les di, surface
  add di, bx

  mov ah, colour
  mov al, colour
  cld
  mov cx, reps
  rep stosw

  test rem, 1
  jz @skip
  mov es:[di], al

@segment_2:
  mov ax, cyi
  sub ax, x
  cmp ax, 0
  jl @skip

  { HLine(startX, endX, cyi - x, colour); }
  { Start offset: y * 320 + x }
  mov ax, cyi
  sub ax, x
  mov bx, 320
  mul bx      { ax = ax * bx }
  add ax, startX
  mov bx, ax

  les di, surface
  add di, bx

  mov ah, colour
  mov al, colour
  cld
  mov cx, reps
  rep stosw

  test rem, 1
  jz @skip
  mov es:[di], al

@skip:
end;

    if p < 0 then
      p := p+4 * x+6
    else begin
      p := p+4 * (x-y)+10;
      dec(y)
    end;

    inc(x)
  end;
end;


procedure Line(const x0, y0, x1, y1: integer; const colour: byte);
begin
  if x0 = x1 then
    VLine(x0, y0, y1, colour)
  else if y0 = y1 then
    HLine(x0, x1, y0, colour)
  else
    AsmLine(x0, y0, x1, y1, colour);
end;

procedure PascalLine(x1, y1, x2, y2: integer; const colour: byte);
var
  dx, dy, sx, sy, err, e2: integer;
begin
  dx := abs(x2 - x1);
  dy := abs(y2 - y1);

  if x1 < x2 then sx := 1 else sx := -1;
  if y1 < y2 then sy := 1 else sy := -1;

  err := dx - dy;

  while (x1 <> x2) or (y1 <> y2) do begin
    AsmPset(x1, y1, colour);
    e2 := 2 * err;

    if e2 > -dy then begin
      err := err - dy;
      x1 := x1 + sx;
    end;

    if e2 < dx then begin
      err := err + dx;
      y1 := y1 + sy;
    end;
  end;

  AsmPset(x1, y1, colour)
end;

procedure AsmLine(x0, y0, x1, y1: integer; const colour: byte);
var
  dxi, dyi, sx, sy, err, e2: integer;
begin
  dxi := abs(x1 - x0);
  dyi := abs(y1 - y0);

  if x0 < x1 then sx := 1 else sx := -1;
  if y0 < y1 then sy := 1 else sy := -1;

asm
  { err := dxi - dyi; }
  mov ax, dxi
  sub ax, dyi
  mov err, ax

{ while (x0 <> x1) or (y0 <> y1) do begin }
@loop_condition:
  mov ax, x1
  cmp x0, ax
  jne @loop

  mov ax, y1
  cmp y0, ax
  jne @loop

  jmp @loop_done

@loop:
  { AsmPset(x0, y0, colour); }

  { Pset }
  { Offset: y * 320 + x }
  mov ax, y0
  mov bx, 320
  mul bx      { ax = ax * bx }
  add ax, x0
  mov bx, ax

  les di, surface
  mov al, colour
  mov es:[di+bx], al

  { e2 := 2 * err; }
  mov ax, 2
  mul err
  mov e2, ax

  { if e2 > -dyi then begin }
  mov bx, dyi
  neg bx
  cmp e2, bx
  jle @skip_e2_check

  { err := err - dyi; }
  mov ax, err
  sub ax, dyi
  mov err, ax

  { x0 := x0 + sx; }
  mov ax, x0
  add ax, sx
  mov x0, ax

  { end; }
@skip_e2_check:

  { if e2 < dxi then begin }
  mov ax, dxi
  cmp e2, ax
  jge @skip

  { err := err + dxi; }
  mov ax, err
  add ax, dxi
  mov err, ax

  { y0 := y0 + sy; }
  mov ax, y0
  add ax, sy
  mov y0, ax
  { end; }

@skip:

@loop_next:
  jmp @loop_condition

@loop_done:
end;
  { end; } { end while }


{ AsmPset(x0, y0, colour) }
asm
  { Pset }
  { Offset: y * 320 + x }
  mov ax, y0
  mov bx, 320
  mul bx      { ax = ax * bx }
  add ax, x0
  mov bx, ax

  les di, surface
  mov al, colour
  mov es:[di+bx], al
end;

end;


procedure HLineBase(x0, x1, y: integer; const colour: byte);
var
  x: integer;
begin
  if x1 < x0 then begin
    x := x0; x0 := x1; x1 := x
  end;

  for x := x0 to x1 do
    AsmPset(x, y, colour);
end;

procedure HLine(const x0, x1, y: integer; const colour: byte);
var
  startX, endX: integer;
  baseOffset: word;
begin
  { Handle early exits }
  if word(y) >= VGAHeight then exit;
  if (x0 < 0) and (x1 < 0) then exit;
  if (x0 >= VGAWidth) and (x1 >= VGAWidth) then exit;

  if x0 <= x1 then begin
    startX := x0;
    endX := x1
  end else begin
    startX := x1;
    endX := x0
  end;

  if startX < 0 then startX := 0;
  if endX > VGAWidth then endX := VGAWidth - 1;

  { Inline AsmPSet }
  baseOffset := y * VGAWidth + startX;

  { FillChar(surface^[baseOffset], endX - startX + 1, colour); }

asm
  les di, surface
  add di, baseOffset

  mov cx, endX
  sub cx, startX
  inc cx  { cx = pixel count }

  mov al, colour

  { First implementation with stosb }

  { cld }  { Make sure the direction is forward }
  { rep stosb }

  { Second impl with stosw }
  mov ah, al  { load ax with the colour }
  cld
  shr cx, 1   { CX = word count; CF = odd remainder}
  rep stosw
  adc cx, cx  { load CX with CF if there's a remainder }
  rep stosb
end;
end;


procedure VLineBase(x, y0, y1: integer; const colour: byte);
var
  temp, a: integer;
begin
  if (x < 0) or (x >= VGAWidth) then exit;
  if y0 > y1 then begin
    temp := y0; y0 := y1; y1 := temp
  end;
  if y0 >= VGAHeight then exit;

  for a:=y0 to y1 do
    AsmPset(x, a, colour);
end;

procedure VLine(const x, y0, y1: integer; const colour: byte);
var
  startY, endY, y: integer;
  baseOffset: word;
begin
  { Handle clipping }
  if (x < 0) or (x >= VGAWidth) then exit;

  if y0 <= y1 then begin
    startY := y0;
    endY := y1;
  end else begin
    startY := y1;
    endY := y0
  end;

  if (endY < 0) or (startY >= VGAHeight) then exit;

  if startY < 0 then startY := 0;

  if endY >= VGAHeight then
    endY := VGAHeight - 1;

  baseOffset := startY * VGAWidth + x;

asm
  push es

  les di, surface
  add di, baseOffset

  mov al, colour

  mov cx, endY
  sub cx, startY
  inc cx

  mov bx, VGAWidth

@loop:
  mov es:[di], al
  add di, bx
  dec cx
  jnz @loop

  pop es
end;
end;


procedure Rect(const x0, y0, x1, y1: integer; const colour: byte);
begin
  HLine(x0, x1, y0, colour);
  HLine(x0, x1, y1, colour);
  VLine(x0, y0, y1, colour);
  VLine(x1, y0, y1, colour);
end;


procedure RectFill(const x0, y0, x1, y1: integer; const colour: byte);
var
  startY, endY, y: integer;
begin
  { Handle clipping }
  startY := y0;
  endY := y1;

  if startY > endY then begin
    startY := y1;
    endY := y0;
  end;

  if startY < 0 then startY := 0;
  if endY >= VGAHeight then
    endY := VGAHeight - 1;

  if startY > endY then exit;

  for y:= startY to endY do
    HLine(x0, x1, y, colour);
end;


procedure CircFillDither(const cx, cy, radius: integer; const colour: byte);
var
  x, y, p: integer;
  a: integer;
begin
  x := 0;
  y := radius;
  p := 3 - 2 * radius;

  while x <= y do begin
    for a:=cx-x to cx+x do begin
      if ((a + cy + y) and 1) = 1 then
        AsmPset(a, cy + y, colour);

      if ((a + cy - y) and 1) = 1 then
        AsmPset(a, cy - y, colour);
    end;
    for a:=cx-y to cx+y do begin
      if ((a + cy + x) and 1) = 1 then
        AsmPset(a, cy + x, colour);
      if ((a + cy - x) and 1) = 1 then
        AsmPset(a, cy - x, colour);
    end;

    if p < 0 then
      p := p+4 * x+6
    else begin
      p := p+4 * (x-y)+10;
      dec(y)
    end;

    inc(x)
  end;
end;

procedure RectFillDitherBase(x0, y0, x1, y1: integer; const colour: byte);
var
  a, b, temp: integer;
begin
  if x0 > x1 then begin
    temp := x0; x0 := x1; x1 := temp
  end;
  if y0 > y1 then begin
    temp := y0; y0 := y1; y1 := temp
  end;

  x0:=trunc(Max(x0, 0));   y0:=trunc(Max(y0,0));
  x1:=trunc(Min(x1, 319)); y1:=trunc(Min(y1,199));

  for b:=y0 to y1 do
    for a:=x0 to x1 do
      if (a+b) and 1 = 1 then
        surface^[b*320+a] := colour;
end;

procedure RectFillDither(const x0, y0, x1, y1: integer; const colour: byte);
var
  startX, endX, startY, endY: integer;
  a, b: integer;
  rowOffset: word;
begin
  if x0 < x1 then begin
    startX := x0; endX := x1
  end else begin
    startX := x1; endX := x0
  end;

  if y0 < y1 then begin
    startY := y0; endY := y1
  end else begin
    startY := y1; endY := y0
  end;

  if startX < 0 then startX := 0;
  if endX >= VGAWidth then endX := VGAWidth - 1;
  if startY < 0 then startY := 0;
  if endY >= VGAHeight then endY := VGAHeight - 1;

  if (startY >= VGAHeight) or (endY < 0)
    or (startX >= VGAWidth) or (endX < 0) then exit;

  { TODO: Handle inline asm }

  for b := startY to endY do begin
    rowOffset := b * VGAWidth;

    if ((startX + b) and 1) = 1 then
      a := startX
    else
      a := startX + 1;

    while a <= endX do begin
      surface^[rowOffset + a] := colour;
      inc(a, 2)
    end;
  end;
end;

procedure AsmRectFillDither(const x0, y0, x1, y1: integer; const colour: byte);
var
  x, y, temp: integer;
  startX, endX, startY, endY: integer;
begin
  startX := x0; endX := x1;
  startY := y0; endY := y1;

  if x0 > x1 then begin
    startX := x1; endX := x0
  end;
  if y0 > y1 then begin
    startY := y1; endY := y0
  end;

  if startX < 0 then startX := 0;
  if endX >= 320 then endX := 319;
  if startY < 0 then startY := 0;
  if endY >= 200 then endY := 199;

asm
{ for (y = startY; y <= endY; y++) }
@y_init:
  mov ax, startY
  mov y, ax

@y_condition:
  mov ax, endY
  cmp y, ax
  jg @y_done

@y_loop:

{ for (x = startX; x <= endX; x += 2) }
@x_init:
  mov ax, startX

  { if (y and 1) = 1 then inc(x); }
  test y, 1
  jz @skip_inc
  inc ax

@skip_inc:  
  mov x, ax

@x_condition:
  mov ax, endX
  cmp x, ax
  jg @x_done

@x_loop:
  { Pset }
  { Offset: y * 320 + x }
  mov ax, y
  mov bx, 320
  mul bx      { ax = ax * bx }
  add ax, x
  mov bx, ax

  les di, surface
  mov al, colour
  mov es:[di+bx], al

@x_next:
  inc x; inc x
  jmp @x_condition

@x_done:

@y_next:
  inc y
  jmp @y_condition

@y_done:

@done:
end;

end;


procedure Tri(const x0, y0, x1, y1, x2, y2: integer; const colour: byte);
begin
  Line(x0, y0, x1, y1, colour);
  Line(x1, y1, x2, y2, colour);
  Line(x2, y2, x0, y0, colour);
end;


procedure TriFill(x0, y0, x1, y1, x2, y2: integer; const colour: byte);
const
  FIX_SHIFT = 8;
  FIX_SCALE = 1 shl FIX_SHIFT;
var
  y, tmp, dx1, dx2, sx1, sx2, dy1, dy2: integer;
  xStart, xEnd: integer;
begin
  { Sort vertices }
  if y0>y1 then begin
    tmp:=y0; y0:=y1; y1:=tmp;
    tmp:=x0; x0:=x1; x1:=tmp
  end;
  if y0>y2 then begin
    tmp:=y0; y0:=y2; y2:=tmp;
    tmp:=x0; x0:=x2; x2:=tmp
  end;
  if y1>y2 then begin
    tmp:=y1; y1:=y2; y2:=tmp;
    tmp:=x1; x1:=x2; x2:=tmp
  end;

  { First half }
  dy1:=y1 - y0; dy2:=y2 - y0;
  if dy1 > 0 then dx1:=((x1-x0) * FIX_SCALE) div dy1 else dx1 := 0;
  if dy2 > 0 then dx2:=((x2-x0) * FIX_SCALE) div dy2 else dx2 := 0;
  sx1:=x0 * FIX_SCALE; sx2:=x0*FIX_SCALE;
  for y:=y0 to y1-1 do begin
    xStart := sx1 shr FIX_SHIFT;
    xEnd := sx2 shr FIX_SHIFT;
    if xStart > xEnd then begin tmp:=xStart; xStart:=xEnd; xEnd:=tmp; end;
    while xStart <= xEnd do begin
      AsmPset(xStart, y, colour);
      inc(xStart);
    end;
    inc(sx1, dx1); inc(sx2, dx2)
  end;

  { Second half }
  dy1:=y2-y1;
  if dy1 > 0 then dx1:=((x2-x1) * FIX_SCALE) div dy1 else dx1:=0;
  sx1:=x1 * FIX_SCALE;
  for y:=y1 to y2 do begin
    xStart := sx1 shr FIX_SHIFT;
    xEnd := sx2 shr FIX_SHIFT;
    if xStart > xEnd then begin tmp:=xStart; xStart:=xEnd; xEnd:=tmp; end;
    while xStart <= xEnd do begin
      AsmPset(xStart, y, colour);
      inc(xStart);
    end;
    inc(sx1, dx1); inc(sx2, dx2)
  end;
end;

end.

{
  Primitives
  Part of Posit-92 game framework
}

unit Graphics;

interface

procedure circ(const cx, cy, radius: integer; const colour: byte);
procedure pascalCirc(const cx, cy, radius: integer; const colour: byte);
procedure asmCircUnsafe(const cxi, cyi, radius: integer; const colour: byte);
procedure asmCirc(const cxi, cyi, radius: integer; const colour: byte);

procedure circfill(const cx, cy, radius: integer; const colour: byte);
procedure pascalCircfill(const cx, cy, radius: integer; const colour: byte);
procedure asmCircfill(const cxi, cyi, radius: integer; const colour: byte);

procedure circFillDither(const cx, cy, radius: integer; const colour: byte);

procedure hline(const x0, x1, y: integer; const colour: byte);
procedure pascalHline(x0, x1, y: integer; const colour: byte);
procedure asmHline(const x0, x1, y: integer; const colour: byte);
procedure asmHline2(const x0, x1, y: integer; const colour: byte);


procedure vline(const x, y0, y1: integer; const colour: byte);
procedure pascalVline(x, y0, y1: integer; const colour: byte);
procedure asmVline(const x, y0, y1: integer; const colour: byte);
procedure asmVline2(const x, y0, y1: integer; const colour: byte);

procedure line(const x0, y0, x1, y1: integer; const colour: byte);
procedure pascalLine(x1, y1, x2, y2: integer; const colour: byte);
procedure asmLine(x0, y0, x1, y1: integer; const colour: byte);

procedure rect(x0, y0, x1, y1: integer; const colour: byte);
procedure pascalRect(x0, y0, x1, y1: integer; const colour: byte);
procedure asmRect(const x0, y0, x1, y1: integer; const colour: byte);

procedure rectfill(const x0, y0, x1, y1: integer; const colour: byte);
procedure pascalRectfill(x0, y0, x1, y1: integer; const colour: byte);
procedure asmRectfill(const x0, y0, x1, y1: integer; const colour: byte);
procedure asmRectfill2(const x0, y0, x1, y1: integer; const colour: byte);

procedure rectfillDither(const x0, y0, x1, y1: integer; const colour: byte);
procedure pascalRectfillDither(x0, y0, x1, y1: integer; const colour: byte);
procedure asmRectfillDither(const x0, y0, x1, y1: integer; const colour: byte);

procedure tri(const x0, y0, x1, y1, x2, y2: integer; const colour: byte);
procedure trifill(x0, y0, x1, y1, x2, y2: integer; const colour: byte);


implementation

uses Maths, VGA;


procedure circ(const cx, cy, radius: integer; const colour: byte);
begin
  asmCirc(cx, cy, radius, colour)
end;

procedure pascalCirc(const cx, cy, radius: integer; const colour: byte);
var
  x, y, p: integer;
begin
  x := 0;
  y := radius;
  p := 3 - 2 * radius;

  while x <= y do begin
    asmPset(cx + x, cy + y, colour);
    asmPset(cx - x, cy + y, colour);
    asmPset(cx + x, cy - y, colour);
    asmPset(cx - x, cy - y, colour);
    asmPset(cx + y, cy + x, colour);
    asmPset(cx - y, cy + x, colour);
    asmPset(cx + y, cy - x, colour);
    asmPset(cx - y, cy - x, colour);

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
procedure asmCircUnsafe(const cxi, cyi, radius: integer; const colour: byte);
var
  x, y, p: integer;
begin
  x := 0;
  y := radius;
  p := 3 - 2 * radius;

  while x <= y do begin
asm
  { asmPset(cxi + x, cyi + y, colour); }

  { PSET }
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

  { asmPset(cxi - x, cyi + y, colour); }
  sub di, x
  sub di, x
  mov es:[di], al

  { asmPset(cxi + x, cyi - y, colour); }
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

  { asmPset(cxi - x, cyi - y, colour); }
  sub di, x
  sub di, x
  mov es:[di], al
end;


asm
  { asmPset(cxi + y, cyi + x, colour); }
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

  { asmPset(cxi - y, cyi + x, colour); }
  sub di, y
  sub di, y
  mov es:[di], al

  { asmPset(cxi + y, cyi - x, colour); }
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

  { asmPset(cxi - y, cyi - x, colour); }
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


procedure asmCirc(const cxi, cyi, radius: integer; const colour: byte);
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

  { asmPset(cxi + x, cyi + y, colour); }
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

  { asmPset(cxi - x, cyi + y, colour); }
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

  { asmPset(cxi + x, cyi - y, colour); }
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

  { asmPset(cxi - x, cyi - y, colour); }
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

  { asmPset(cxi + y, cyi + x, colour); }
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

  { asmPset(cxi - y, cyi + x, colour); }
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

  { asmPset(cxi + y, cyi - x, colour); }
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

  { asmPset(cxi - y, cyi - x, colour); }
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


procedure circfill(const cx, cy, radius: integer; const colour: byte);
begin
  asmCircfill(cx, cy, radius, colour)
end;

procedure pascalCircfill(const cx, cy, radius: integer; const colour: byte);
var
  x, y, p: integer;
  a: integer;
begin
  x := 0;
  y := radius;
  p := 3 - 2 * radius;

  while x <= y do begin
    for a:=cx-x to cx+x do begin
      asmPset(a, cy + y, colour);
      asmPset(a, cy - y, colour)
    end;
    for a:=cx-y to cx+y do begin
      asmPset(a, cy + x, colour);
      asmPset(a, cy - x, colour)
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

procedure asmCircfill(const cxi, cyi, radius: integer; const colour: byte);
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
  { hline(startX, endX, cyi + y, colour); }
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

  { hline(startX, endX, cyi - y, colour); }
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
  { hline(startX, endX, cyi + x, colour); }
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

  { hline(startX, endX, cyi - x, colour); }
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


procedure circfillDither(const cx, cy, radius: integer; const colour: byte);
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
        asmPset(a, cy + y, colour);

      if ((a + cy - y) and 1) = 1 then
        asmPset(a, cy - y, colour);
    end;
    for a:=cx-y to cx+y do begin
      if ((a + cy + x) and 1) = 1 then
        asmPset(a, cy + x, colour);
      if ((a + cy - x) and 1) = 1 then
        asmPset(a, cy - x, colour);
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


procedure line(const x0, y0, x1, y1: integer; const colour: byte);
begin
  if x0 = x1 then
    vline(x0, y0, y1, colour);
  else if y0 = y1 then
    hline(x0, x1, y0, colour)
  else
    asmLine(x0, y0, x1, y1, colour);
end;

procedure pascalLine(x1, y1, x2, y2: integer; const colour: byte);
var
  dx, dy, sx, sy, err, e2: integer;
begin
  dx := abs(x2 - x1);
  dy := abs(y2 - y1);

  if x1 < x2 then sx := 1 else sx := -1;
  if y1 < y2 then sy := 1 else sy := -1;

  err := dx - dy;

  while (x1 <> x2) or (y1 <> y2) do begin
    asmPset(x1, y1, colour);
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

  asmPset(x1, y1, colour)
end;

procedure asmLine(x0, y0, x1, y1: integer; const colour: byte);
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
  { asmPset(x0, y0, colour); }

  { PSET }
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


{ asmPset(x0, y0, colour) }
asm
  { PSET }
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


procedure hline(const x0, x1, y: integer; const colour: byte);
begin
  asmHline2(x0, x1, y, colour)
end;

procedure pascalHline(x0, x1, y: integer; const colour: byte);
var
  x: integer;
begin
  if x1 < x0 then begin
    x := x0; x0 := x1; x1 := x
  end;

  for x := x0 to x1 do
    asmPset(x, y, colour);
end;

procedure asmHline(const x0, x1, y: integer; const colour: byte); assembler;
var
  x: integer;
asm
  cmp y, 0
  jl @done
  cmp y, 200
  jge @done

  { Swap if x1 < x0 }
  mov ax, x0
  cmp x1, ax
  jge @skip_swap

  mov bx, x1
  mov x0, bx
  mov x1, ax

@skip_swap:

  { for (x = x0; x <= x1; x++) }
@x_init:
  mov ax, x0
  mov x, ax

@x_condition:
  mov ax, x1
  cmp x, ax
  jg @done

@x_loop:
  { Bounds check }
  cmp x, 0
  jl @x_next
  cmp x, 320
  jge @done

  { PSET }
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
  inc x
  jmp @x_condition

@done:
end;


procedure asmHline2(const x0, x1, y: integer; const colour: byte);
var
  x: integer;
  startX, endX: integer;
  reps: word;
  rem: byte;
begin
  if y < 0 then exit;
  if y >= 200 then exit;

  startX := x0; endX := x1;

  if startX > endX then begin
    startX := x1; endX := x0
  end;

  { Edge cases }
  if startX < 0 then startX := 0;
  if endX >= 320 then endX := 319;
  reps := (1 + endX - startX) div 2;
  rem := (1 + endX - startX) and 1;

asm
  { for (x = x0; x <= x1; x++) }
  mov ax, startX
  mov x, ax

@x_loop:
  { PSET }
  { Start offset: y * 320 + x }
  mov ax, y
  mov bx, 320
  mul bx      { ax = ax * bx }
  add ax, x
  mov bx, ax

  les di, surface
  add di, bx

  mov ah, colour
  mov al, colour
  cld
  mov cx, reps
  rep stosw

  test rem, 1
  jz @done
  mov es:[di], al

@done:
end;

end;


procedure vline(const x, y0, y1: integer; const colour: byte);
begin
  asmVline2(x, y0, y1, colour)
end;

procedure pascalVline(x, y0, y1: integer; const colour: byte);
var
  temp, a: integer;
begin
  if (x < 0) or (x >= 320) then exit;
  if y0 > y1 then begin
    temp := y0; y0 := y1; y1 := temp
  end;
  if y0 >= 200 then exit;

  for a:=y0 to y1 do begin
    if (a < 0) then continue;
    asmPset(x, a, colour)
  end;
end;

procedure asmVline(const x, y0, y1: integer; const colour: byte);
var
  yStart, yEnd, y: integer;
begin
  if y0 > y1 then begin
    yStart := y1; yEnd := y0
  end else begin
    yStart := y0; yEnd := y1
  end;

asm
  { Check bounds }
  cmp x, 0
  jl @skip
  cmp x, 320
  jge @skip
  cmp yStart, 200
  jge @skip

{ for (y = yStart; y <= yEnd; y++) }
@y_start:
  mov ax, yStart
  mov y, ax
  
@y_condition:
  mov ax, yEnd
  cmp y, ax
  jg @y_end

@y_loop:
  cmp y, 0
  jl @y_next

  { PSET }
  { Offset: y * 320 + x }
  mov ax, y
  mov bx, 320
  mul bx      { ax = ax * bx }
  add ax, x
  mov bx, ax

  les di, surface
  mov al, colour
  mov es:[di+bx], al

@y_next:
  inc y
  jmp @y_condition

@y_end:
@skip:
end;

end;

procedure asmVline2(const x, y0, y1: integer; const colour: byte);
var
  yStart, yEnd, y: integer;
begin
  if x < 0 then exit;
  if x >= 320 then exit;

  if y0 > y1 then begin
    yStart := y1; yEnd := y0
  end else begin
    yStart := y0; yEnd := y1
  end;

  if yStart < 0 then yStart := 0;
  if yEnd >= 200 then yEnd := 199;

asm
{ for (y = yStart; y <= yEnd; y++) }
@y_start:
  mov ax, yStart
  mov y, ax
  
@y_condition:
  mov ax, yEnd
  cmp y, ax
  jg @y_end

@y_loop:
  { PSET }
  { Offset: y * 320 + x }
  mov ax, y
  mov bx, 320
  mul bx      { ax = ax * bx }
  add ax, x
  mov bx, ax

  les di, surface
  mov al, colour
  mov es:[di+bx], al

@y_next:
  inc y
  jmp @y_condition

@y_end:
end;

end;


procedure rect(x0, y0, x1, y1: integer; const colour: byte);
begin
  pascalRect(x0, y0, x1, y1, colour)
end;

procedure pascalRect(x0, y0, x1, y1: integer; const colour: byte);
var
  a, b, temp: integer;
begin
  if x0 > x1 then begin
    temp := x0; x0 := x1; x1 := temp
  end;
  if y0 > y1 then begin
    temp := y0; y0 := y1; y1 := temp
  end;
  for b:=y0 to y1 do begin
    asmPset(x0, b, colour);
    asmPset(x1, b, colour)
  end;
  for a:=x0 to x1 do begin
    asmPset(a, y0, colour);
    asmPset(a, y1, colour)
  end;
end;

procedure asmRect(const x0, y0, x1, y1: integer; const colour: byte);
var
  xStart, xEnd, yStart, yEnd: integer;
  x, y: integer;
begin
  if y0 > y1 then begin
    yStart := y1; yEnd := y0
  end else begin
    yStart := y0; yEnd := y1
  end;
  if yStart >= 200 then exit;

  if x0 > x1 then begin
    xStart := x1; xEnd := x0
  end else begin
    xStart := x0; xEnd := x1
  end;
  if xStart >= 320 then exit;

asm

{ for (y = yStart; y <= yEnd; y++) }
@y_init:
  mov ax, yStart
  mov y, ax

@y_condition:
  mov ax, yEnd
  cmp y, ax
  jg @y_done

@y_loop:

@x_left:
  cmp xStart, 0
  jl @skip_x_left

  { PSET }
  { Offset: y * 320 + x }
  mov ax, y
  mov bx, 320
  mul bx
  add ax, xStart
  mov bx, ax

  les di, surface
  mov al, colour
  mov es:[di+bx], al

@skip_x_left:

@x_right:
  cmp xEnd, 320
  jge @skip_x_right

  { PSET }
  { Offset: y * 320 + x }
  mov ax, y
  mov bx, 320
  mul bx
  add ax, xEnd
  mov bx, ax

  les di, surface
  mov al, colour
  mov es:[di+bx], al

@skip_x_right:
@y_next:
  inc y
  jmp @y_condition

@y_done:


{ for (x = xStart; x <= xEnd; x++)}
@x_init:
  mov ax, xStart
  mov x, ax

@x_condition:
  mov ax, xEnd
  cmp x, ax
  jg @x_done

@x_loop:
  cmp x, 0
  jl @x_next

@y_top:
  cmp yStart, 0
  jl @skip_y_top

  { PSET }
  { Offset: y * 320 + x }
  mov ax, yStart
  mov bx, 320
  mul bx      { ax = ax * bx }
  add ax, x
  mov bx, ax

  les di, surface
  mov al, colour
  mov es:[di+bx], al

@skip_y_top:

@y_bottom:
  cmp yEnd, 200
  jge @skip_y_bottom

  { PSET }
  { Offset: y * 320 + x }
  mov ax, yEnd
  mov bx, 320
  mul bx      { ax = ax * bx }
  add ax, x
  mov bx, ax

  les di, surface
  mov al, colour
  mov es:[di+bx], al

@skip_y_bottom:

@x_next:
  inc x
  jmp @x_condition

@x_done:

@skip:
end;

end;


procedure rectfill(const x0, y0, x1, y1: integer; const colour: byte);
begin
  asmRectfill2(x0, y0, x1, y1, colour)
end;

procedure pascalRectfill(x0, y0, x1, y1: integer; const colour: byte);
var
  a, b, temp: integer;
begin
  if x0 > x1 then begin
    temp := x0; x0 := x1; x1 := temp
  end;
  if y0 > y1 then begin
    temp := y0; y0 := y1; y1 := temp
  end;
  for b:=y0 to y1 do
    hline(x0, x1, b, colour);
end;

procedure asmRectfill(const x0, y0, x1, y1: integer; const colour: byte);
var
  x, y,
  startX, endX,
  startY, endY: integer;
begin
  if y0 > y1 then begin
    startY := y1; endY := y0
  end else begin
    startY := y0; endY := y1
  end;

  if x0 > x1 then begin
    startX := x1; endX := x0
  end else begin
    startX := x0; endX := x1
  end;

asm
@y_init:
  { for (y = y0; y <= y1; y++) }
  mov ax, startY
  mov y, ax

@y_condition:
  mov ax, y
  cmp ax, endY
  jg @y_done

@y_loop:
  cmp y, 0
  jl @y_next
  cmp y, 200
  jge @y_done

  { for (x = x0; x <= x1; x++) }
@x_init:
  mov ax, startX
  mov x, ax

@x_condition:
  mov ax, endX
  cmp x, ax
  jg @x_done

@x_loop:
  { Bounds check }
  cmp x, 0
  jl @x_next
  cmp x, 320
  jge @x_done

  { PSET }
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
  inc x
  jmp @x_condition

@x_done:

@y_next:
  inc y
  jmp @y_condition

@y_done:
end;
end;


procedure asmRectfill2(const x0, y0, x1, y1: integer; const colour: byte);
var
  x, y,
  startX, endX,
  startY, endY: integer;
  reps: word;
  rem: byte;
begin
  if y0 > y1 then begin
    startY := y1; endY := y0
  end else begin
    startY := y0; endY := y1
  end;

  if x0 > x1 then begin
    startX := x1; endX := x0
  end else begin
    startX := x0; endX := x1
  end;

  if startY < 0 then startY := 0;
  if endY >= 200 then endY := 199;
  if startX < 0 then startX := 0;
  if endX >= 320 then endX := 319;
  reps := (1 + endX - startX) div 2;
  rem := (1 + endX - startX) and 1;

asm
@y_init:
  { for (y = y0; y <= y1; y++) }
  mov ax, startY
  mov y, ax

@y_condition:
  mov ax, y
  cmp ax, endY
  jg @y_done

@y_loop:

  { for (x = x0; x <= x1; x++) }
@x_init:
  mov ax, startX
  mov x, ax

@x_loop:
  { PSET }
  { Start offset: y * 320 + x }
  mov ax, y
  mov bx, 320
  mul bx      { ax = ax * bx }
  add ax, x
  mov bx, ax

  les di, surface
  add di, bx
  cld
  mov cx, reps
  mov ah, colour
  mov al, colour
  rep stosw

  test rem, 1
  jz @x_next
  mov es:[di], al

@x_next:

@y_next:
  inc y
  jmp @y_condition

@y_done:
end;
end;


procedure rectfillDither(const x0, y0, x1, y1: integer; const colour: byte);
begin
  asmRectfillDither(x0, y0, x1, y1, colour)
end;

procedure pascalRectfillDither(x0, y0, x1, y1: integer; const colour: byte);
var
  a, b, temp: integer;
begin
  if x0 > x1 then begin
    temp := x0; x0 := x1; x1 := temp
  end;
  if y0 > y1 then begin
    temp := y0; y0 := y1; y1 := temp
  end;

  x0:=trunc(max(x0, 0));   y0:=trunc(max(y0,0));
  x1:=trunc(min(x1, 319)); y1:=trunc(min(y1,199));

  for b:=y0 to y1 do
    for a:=x0 to x1 do
      if (a+b) and 1 = 1 then
        surface^[b*320+a] := colour;
end;

procedure asmRectfillDither(const x0, y0, x1, y1: integer; const colour: byte);
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
  { PSET }
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


procedure tri(const x0, y0, x1, y1, x2, y2: integer; const colour: byte);
begin
  line(x0, y0, x1, y1, colour);
  line(x1, y1, x2, y2, colour);
  line(x2, y2, x0, y0, colour);
end;


procedure trifill(x0, y0, x1, y1, x2, y2: integer; const colour: byte);
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
      asmPset(xStart, y, colour);
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
      asmPset(xStart, y, colour);
      inc(xStart);
    end;
    inc(sx1, dx1); inc(sx2, dx2)
  end;
end;



end.

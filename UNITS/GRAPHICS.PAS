{
  Primitives
  Part of Posit-92 game framework
}

unit Graphics;

interface

procedure circ(const cx, cy, radius: integer; const colour: byte);
procedure circfill(const cx, cy, radius: integer; const colour: byte);
procedure circFillDither(const cx, cy, radius: integer; const colour: byte);
procedure hline(x0, x1, y: integer; const colour: byte);
procedure asmHline(x0, x1, y: integer; const colour: byte);
procedure line(x1, y1, x2, y2: integer; const colour: byte);
procedure rect(x0, y0, x1, y1: integer; const colour: byte);
procedure rectfill(x0, y0, x1, y1: integer; const colour: byte);
procedure asmRectfill(x0, y0, x1, y1: integer; const colour: byte);
procedure rectfillDither(x0, y0, x1, y1: integer; const colour: byte);
procedure tri(const x0, y0, x1, y1, x2, y2: integer; const colour: byte);
procedure trifill(x0, y0, x1, y1, x2, y2: integer; const colour: byte);


implementation

uses VGA;

procedure circ(const cx, cy, radius: integer; const colour: byte);
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

procedure circfill(const cx, cy, radius: integer; const colour: byte);
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

procedure line(x1, y1, x2, y2: integer; const colour: byte);
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


procedure hline(x0, x1, y: integer; const colour: byte);
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

  { for x := x0 to x1 }
  mov ax, x0
  mov x, ax

@loop_begin:
  { Bounds check }
  cmp x, 0
  jl @loop_end
  cmp x, 320
  jge @done

  { Calculate offset: y * 320 + x }
  mov ax, y
  mov bx, 320
  mul bx      { ax = ax * bx }
  add ax, x
  mov bx, ax

  les di, surface
  mov al, colour
  mov es:[di+bx], al

@loop_end:
  inc x
  mov ax, x1
  cmp x, ax
  jg @done
  jmp @loop_begin

@done:
end;

procedure rect(x0, y0, x1, y1: integer; const colour: byte);
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


procedure rectfill(x0, y0, x1, y1: integer; const colour: byte);
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

procedure asmRectfill(x0, y0, x1, y1: integer; const colour: byte);
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
asm
  { asmHline }
  cmp b, 0
  jl @done
  cmp b, 200
  jge @done

  { for a := x0 to x1 }
  mov ax, x0
  mov a, ax

@a_loop_begin:
  { Bounds check }
  cmp a, 0
  jl @loop_end
  cmp a, 320
  jge @done

  { Calculate offset: y * 320 + x }
  mov ax, b
  mov bx, 320
  mul bx      { ax = ax * bx }
  add ax, a
  mov bx, ax

  les di, surface
  mov al, colour
  mov es:[di+bx], al

@a_loop_end:
  inc a
  mov ax, x1
  cmp a, ax
  jg @done
  jmp @a_loop_begin

@done:
end;
end;

procedure rectfillDither(x0, y0, x1, y1: integer; const colour: byte);
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

{
  Drawing primitives
  Part of Posit-92 game engine
}

unit P92GRAPH;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

interface

procedure Circ(const cx, cy, radius: integer; const colour: byte);

{ Optimised circle fill with HLine calls }
procedure CircFill(const cx, cy, radius: integer; const colour: byte);

{ Optimised horizontal line procedure based on HLineBase }
procedure HLine(const x0, x1, y: integer; const colour: byte);

{ Optimised vertical line procedure based on VLineBase }
procedure VLine(const x, y0, y1: integer; const colour: byte);

procedure Line(const x0, y0, x1, y1: integer; const colour: byte);

{ Forward calls to HLine and VLine }
procedure Rect(const x0, y0, x1, y1: integer; const colour: byte);

{ Forward calls to HLine }
procedure RectFill(const x0, y0, x1, y1: integer; const colour: byte);

procedure CircFillDither(const cx, cy, radius: integer; const colour: byte);

{ Optimised dithered rectangle fill based on RectFillDitherBase }
procedure RectFillDither(const x0, y0, x1, y1: integer; const colour: byte);

procedure Tri(const x0, y0, x1, y1, x2, y2: integer; const colour: byte);
procedure TriFill(x0, y0, x1, y1, x2, y2: integer; const colour: byte);


implementation

uses P92MATHS, P92VGA;


procedure CircBase(const cx, cy, radius: integer; const colour: byte);
var
  x, y, p: integer;
begin
  x := 0;
  y := radius;
  p := 3 - 2 * radius;

  while x <= y do begin
    AsmPSet(cx + x, cy + y, colour);
    AsmPSet(cx - x, cy + y, colour);
    AsmPSet(cx + x, cy - y, colour);
    AsmPSet(cx - x, cy - y, colour);
    AsmPSet(cx + y, cy + x, colour);
    AsmPSet(cx - y, cy + x, colour);
    AsmPSet(cx + y, cy - x, colour);
    AsmPSet(cx - y, cy - x, colour);

    if p < 0 then
      p := p+4 * x+6
    else begin
      p := p+4 * (x-y)+10;
      dec(y);
    end;
    inc(x);
  end;
end;


procedure Circ(const cx, cy, radius: integer; const colour: byte);
begin
  CircBase(cx, cy, radius, colour)
end;


procedure CircFillBase(const cx, cy, radius: integer; const colour: byte);
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

procedure CircFill(const cx, cy, radius: integer; const colour: byte);
var
  x, y, p: integer;
  a: integer;
begin
  x := 0;
  y := radius;
  p := 3 - 2 * radius;

  while x <= y do begin
    hline(cx - x, cx + x, cy + y, colour);
    hline(cx - x, cx + x, cy - y, colour);

    hline(cx - y, cx + y, cy + x, colour);
    hline(cx - y, cx + y, cy - x, colour);

    if p < 0 then
      p := p+4 * x+6
    else begin
      p := p+4 * (x-y)+10;
      dec(y)
    end;

    inc(x)
  end;
end;


procedure LineBase(x1, y1, x2, y2: integer; const colour: byte);
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

procedure Line(const x0, y0, x1, y1: integer; const colour: byte);
begin
  if x0 = x1 then
    VLine(x0, y0, y1, colour)
  else if y0 = y1 then
    HLine(x0, x1, y0, colour)
  else
    LineBase(x0, y0, x1, y1, colour);
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
    startX := x0; endX := x1
  end else begin
    startX := x1; endX := x0
  end;

  if startX < 0 then startX := 0;
  if endX > VGAWidth then endX := VGAWidth - 1;

  { Inline AsmPSet }
  baseOffset := y * VGAWidth + startX;

  { FillChar(backBuffer^[baseOffset], endX - startX + 1, colour); }

asm
  les di, backBuffer
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
    startY := y0; endY := y1
  end else begin
    startY := y1; endY := y0
  end;

  if (endY < 0) or (startY >= VGAHeight) then exit;

  if startY < 0 then startY := 0;

  if endY >= VGAHeight then
    endY := VGAHeight - 1;

  baseOffset := startY * VGAWidth + x;

asm
  push es

  les di, backBuffer
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
        backBuffer^[b*320+a] := colour;
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

  for b := startY to endY do begin
    rowOffset := b * VGAWidth;

    if ((startX + b) and 1) = 1 then
      a := startX
    else
      a := startX + 1;

    asm
  push es
  les di, backBuffer

  add di, rowOffset
  add di, a

  mov cx, endX
  sub cx, a
  jb @done
  shr cx, 1
  inc cx

  mov al, colour
  cld

@dither:
  stosb
  inc di  { skip 1 pixel }
  loop @dither

@done:
  pop es
    end;

  {
    while a <= endX do begin
      backBuffer^[rowOffset + a] := colour;
      inc(a, 2)
    end;
  }
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
  FixShift = 16;
  FixScale = 1 shl FixShift;
var
  y, tmp: integer;
  dx1, dx2, sx1, sx2, dy1, dy2: longint;
  startX, endX: longint;
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
  dy1 := y1 - y0;
  dy2 := y2 - y0;

  if dy1 > 0 then
    dx1 := ((x1-x0) * FixScale) div dy1
  else
    dx1 := 0;

  if dy2 > 0 then
    dx2:=((x2-x0) * FixScale) div dy2
  else
    dx2 := 0;

  sx1 := x0 * FixScale;
  sx2 := x0 * FixScale;

  for y := y0 to y1-1 do begin
    startX := sx1 shr FixShift;
    endX := sx2 shr FixShift;

    HLine(startX, endX, y, colour);

    inc(sx1, dx1);
    inc(sx2, dx2)
  end;

  { Second half }
  dy1 := y2 - y1;

  if dy1 > 0 then
    dx1 := ((x2-x1) * FixScale) div dy1
  else
    dx1 := 0;

  sx1 := x1 * FixScale;

  for y := y1 to y2 do begin
    startX := sx1 shr FixShift;
    endX := sx2 shr FixShift;

    HLine(startX, endX, y, colour);

    inc(sx1, dx1);
    inc(sx2, dx2)
  end;
end;

end.


uses
  Conv, Timing, P92VGA;

const
  Palette: array[0..1] of Byte = ($00, $46);

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
  b: byte;
  bit: integer;
begin
  dest := 0;

  for src := 0 to (VGAWidth * VGAHeight div 8) - 1 do begin
    b := surface^[src];

    for bit := 7 downto 0 do begin
      if (b and (1 shl bit)) <> 0 then
        Mem[$A000:dest] := Palette[1]
      else
        Mem[$A000:dest] := Palette[0];

      inc(dest)
    end;
  end;
end;

procedure Present100;
var
  startTick, endTick: double;
  a: word;
begin
  startTick := GetTimer;

  { 6.8057s }
  for a:=1 to 100 do
    Present1BPP;

  endTick := GetTimer;

  Print1BPP('100 present ops done in ' + F32Str(endTick - startTick) + 's', 0, 0, $00);

  Present1BPP;
end;

begin
  LoadCGAFont;

  InitBuffer(320, 200);
  InitMode13h;

  Cls1BPP($FF);

  { PSet1BPP(32, 10, 0); }
  Print1BPP('Hello from MONOVGA!', 8, 8, 0);

  { Present1BPP; }
  Present100;

  readln;

  FreeBuffer;
  InitModeText;
end.

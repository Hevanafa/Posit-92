
uses
  P92VGA;

const
  Palette: array[0..1] of Byte = ($00, $46);

procedure Cls1BPP(const colour: byte);
begin
  FillChar(surface^, VGAWidth * VGAHeight div 8, colour)
end;

procedure PSet1BPP(const x, y: integer; const bit: byte);
var
  offset: word;
begin
  offset := x div 8 + y;
  surface^[offset] := surface^[offset] and (bit shl (x mod 8));
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

begin
  LoadCGAFont;

  InitBuffer(320, 200);
  InitMode13h;

  Cls1BPP($FF);
  { print('Hello from MonoVGA!', 8, 8, $07); }

  PSet1BPP(32, 10, 0);
  Present1BPP;

  readln;

  FreeBuffer;
  InitModeText;
end.

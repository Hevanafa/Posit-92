
const
  PageSize = 16000;

var
  drawPage: word;
  drawOffset: word;

procedure InitMode13h; assembler;
asm
  mov ax, 0013h
  int 10h
end;

procedure InitModeText; assembler;
asm
  mov ax, 0003h
  int 10h
end;

{
  Start the unchained mode 13h
  TODO: Explain the magic numbers
}
procedure InitModeY;
begin
  port[$3C4] := $04;
  port[$3C5] := $06;

  port[$3D4] := $14;
  port[$3D5] := $00;

  port[$3D4] := $17;
  port[$3D5] := $E3;

  port[$3C4] := $02;
  port[$3C5] := $0F;

  FillChar(mem[$A000:0000], $FFFF, $0F);
end;

procedure WaitVSync;
begin
  while (port[$3DA] and $08) <> 0 do; { wait for retrace to end }
  while (port[$3DA] and $08) = 0 do;  { wait for next retrace }
end;

procedure FlipPage;
var
  startAddr: word;
begin
  startAddr := drawPage * PageSize;

  WaitVSync;

  { Set the CRTC start address }
  port[$3D4] := $0C;
  port[$3D5] := hi(startAddr);
  port[$3D4] := $0D;
  port[$3D5] := lo(startAddr);

  drawPage := drawPage xor 1;
  drawOffset := drawPage * PageSize;
end;

{ ModeYPSet }
procedure PSet(const x, y: integer; const colour: byte);
const
  SequencerIndexReg = $3C4;
  SequencerDataReg = $3C5;
  MapMask = $02;
  PlaneMask: array[0..3] of byte = (1, 2, 4, 8);
var
  offset: word;
begin
  port[SequencerIndexReg] := MapMask;
  port[SequencerDataReg] := PlaneMask[x and 3];  { 1 shl (x and 3); }

  offset := drawOffset + y * 80 + x shr 2;  { This is the same as x div 4 }
  mem[$A000:offset] := colour
end;

begin
  drawPage := 0;

  InitMode13h;
  InitModeY;

  PSet(160, 100, 14);
  PSet(161, 100, 14);
  PSet(162, 100, 12);
  PSet(163, 100, 12);

  FlipPage;

  readln;
  InitModeText;
end.

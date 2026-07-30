
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
  Requres InitMode13h call
}
procedure InitModeY;
const
  SequencerIndexReg = $3C4;
  SequencerDataReg = $3C5;
  { CRT Controller index and data ports }
  CRTCIndexReg = $3D4;
  CRTCDataReg = $3D5;

  { Sequencer magic numbers }
  MemoryMode = $04;
  MapMask = $02;
  { CRTC magic numbers }
  UnderlineLocation = $14;
  CRTCModeControl = $17;
begin
  port[SequencerIndexReg] := MemoryMode;
  port[SequencerDataReg] := $06;

  { Turning this off switches from DWord addressing to byte addressing }
  port[CRTCIndexReg] := UnderlineLocation;
  port[CRTCDataReg] := $00;

  { $E3 = 0b1110_0011
    The key here is bit 6 set, which selects byte mode addressing that
    works together with the previous register to fully linearise
    the CRTC address counter accross planes }
  port[CRTCIndexReg] := CRTCModeControl;
  port[CRTCDataReg] := $E3;

  { This enables all four planes for writing: 0b1111 }
  port[SequencerIndexReg] := MapMask;
  port[SequencerDataReg] := $0F;

  { Fill all the surface with white }
  FillChar(mem[$A000:0000], $FFFF, $0F);
end;

procedure WaitVSync;
const
  InputStatusReg1 = $3DA;
  VSyncBit = $08;
begin
  { wait for retrace to end }
  while (port[InputStatusReg1] and VSyncBit) <> 0 do;

  { wait for next retrace to begin }
  while (port[InputStatusReg1] and VSyncBit) = 0 do;
end;

procedure FlipPage;
const
  CRTCIndexReg = $3D4;
  CRTCDataReg = $3D5;
  StartAddrHigh = $0C;
  StartAddrLow = $0D;
var
  startAddr: word;
begin
  startAddr := drawPage * PageSize;

  WaitVSync;

  { Set the CRTC start address }
  port[CRTCIndexReg] := StartAddrHigh;
  port[CRTCDataReg] := hi(startAddr);
  port[CRTCIndexReg] := StartAddrLow;
  port[CRTCDataReg] := lo(startAddr);

  drawPage := drawPage xor 1;  { Flips the page from 0 to 1, and vice versa }
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
  if (y < 0) or (y >= 200) or (x < 0) or (x >= 320) then exit;

  port[SequencerIndexReg] := MapMask;
  port[SequencerDataReg] := PlaneMask[x and 3];  { 1 shl (x and 3); }

  offset := drawOffset + y * 80 + x shr 2;  { This is the same as x div 4 }
  mem[$A000:offset] := colour
end;

procedure AsmPSet(const x, y: integer; const colour: byte); assembler;
asm
  { TODO: Check bounds }


  mov dx, 03C4h

  { This enables all 4 planes: 0Fh
    and also assigns the MapMask: 02h}
{ mov ax, 0F02h
  out dx, ax }

  mov al, 02h
  out dx, al

  { Assign PlaneMask }
  mov dx, 03C5h

  { Solve for 1 shl (x and 3), then write to Port[$03C5] }
  mov cx, x
  and cx, 03h  { x and 3 }
  { 1 shl (x and 3). In 8086, the count must be in `cl` }
  mov al, 01h
  shl al, cl
  out dx, al

  { PSet }
  push es
  mov ax, 0A000h
  mov es, ax

  mov di, [drawOffset]

  { Solve for y * 80, then add to DI }
  mov cx, y
  mov ax, cx
  mov cx, 80
  mul cx
  add di, ax

  { Solve for x shr 2, then add to DI }
  mov bx, x
  mov ax, bx
  mov cl, 2
  shr ax, cl  { `shr ax, 2` requires 286 instructions enabled }
  add di, ax

  mov al, colour
  mov es:[di], al
  pop es
end;


var
  a: word;
begin
  drawPage := 0;

  InitMode13h;
  InitModeY;

  for a:=1 to 10 do
    AsmPSet(160 + a, 100, $0C);

  {
  AsmPSet(161, 100, 14);
  AsmPSet(162, 100, 12);
  AsmPSet(163, 100, 12);
  }

  FlipPage;

  readln;
  InitModeText;
end.

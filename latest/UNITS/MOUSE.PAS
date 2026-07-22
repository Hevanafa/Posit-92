unit Mouse;

interface

uses Bitmap;

var
  cursor: PBitmap;
  mouseX, mouseY: word;
  mouseButton: byte;

procedure LoadCursor;
procedure FreeCursor;

procedure InitMouse;
procedure UpdateMouse;
procedure DebugMouse;
procedure DrawMouse;
procedure ResetMouse;


implementation

uses DOS, Conv, Logger, VGA;

var
  mouseInitialised: boolean;

procedure LoadCursor;
begin
  loadBMP(cursor, 'CURSOR.BMP')
end;

procedure FreeCursor;
begin
  freeBMP(cursor)
end;

procedure InitMouse;
var
  Regs: Registers;
begin
  if mouseInitialised then exit;

  regs.ax := 0;
  Intr($33, regs);
  if regs.ax = 0 then begin
    WriteLog('No mouse driver is found!');
    readLn;
    halt
  end else
    WriteLog('Mouse initialised.');

  mouseInitialised := true
end;


procedure UpdateMouse;
var
  Regs: Registers;
begin
  if not mouseInitialised then exit;
  regs.ax := 3;
  intr($33, regs);
  mouseX := regs.cx div 2;
  mouseY := regs.dx;
  mouseButton := regs.bx;
end;

procedure DebugMouse;
begin
  if not mouseInitialised then begin
    Print('Mouse has not been initialised!', 0, 0, 15);
    exit
  end;

  Print('Mouse: {x:' + i32str(mouseX) + ', y:' + i32str(mouseY) + '}', 0, 0, 15);
  Print('Buttons: ' + i32str(mouseButton), 0, 8, 15);
end;


procedure DrawMouse;
var
  Regs: Registers;
begin
  if not mouseInitialised then exit;
  spr(cursor, mouseX, mouseY, 13);
end;

{
  Must be called before initTextMode
  to prevent 20302 runtime error
}
procedure ResetMouse;
var
  Regs: Registers;
begin
  if not mouseInitialised then exit;

  { Hide mouse cursor }
  regs.ax := 2;
  intr($33, regs);
  { Reset mouse driver to default state }
  regs.ax := 0;
  intr($33, regs);

  FreeCursor;
  mouseInitialised := false
end;


end.

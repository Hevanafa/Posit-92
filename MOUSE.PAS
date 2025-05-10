unit Mouse;

interface

uses Bitmap;

var
  cursor: PBitmap;
  mouseX, mouseY: word;
  mouseButton: byte;

procedure loadCursor;
procedure freeCursor;
procedure initMouse;
procedure updateMouse;
procedure debugMouse;
procedure drawMouse;
procedure resetMouse;


implementation

uses DOS, Conv, Logger, VGA;

var
  mouseInitialised: boolean;

procedure loadCursor;
begin
  loadBMP(cursor, 'CURSOR.BMP')
end;

procedure freeCursor;
begin
  freeBMP(cursor)
end;

procedure initMouse;
var
  Regs: Registers;
begin
  if mouseInitialised then exit;

  regs.ax := 0;
  Intr($33, regs);
  if regs.ax = 0 then begin
    writeLog('No mouse driver is found!');
    readLn;
    halt
  end else
    writeLog('Mouse initialised.');

  loadCursor;
  mouseInitialised := true
end;


procedure updateMouse;
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

procedure debugMouse;
begin
  if not mouseInitialised then begin
    print('Mouse has not been initialised!', 0, 0, 15);
    exit
  end;

  print('Mouse: {x:' + i32str(mouseX) + ', y:' + i32str(mouseY) + '}', 0, 0, 15);
  print('Buttons: ' + i32str(mouseButton), 0, 8, 15);
end;


procedure drawMouse;
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
procedure resetMouse;
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

  freeCursor;
  mouseInitialised := false
end;


end.

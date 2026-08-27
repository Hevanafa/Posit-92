unit P92MOUSE;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

interface

uses P92TEX;

const
  MouseButtonNone = 0;
  MouseButtonLeft = 1;
  MouseButtonRight = 2;
  MouseButtonBoth = 3;

var
  cursor: TTexture;
  mouseX, mouseY: integer;
  mouseButton: byte;

procedure LoadCursor;
procedure FreeCursor;

procedure InitMouse;
procedure UpdateMouse;
procedure DebugMouse;
procedure DrawMouse;
procedure ResetMouse;


implementation

uses
  DOS,
  P92CONV, P92LOG, P92PANIC, P92VGA;

var
  isMouseInitialised: boolean;

procedure LoadCursor;
begin
  LoadTex(cursor, 'CURSOR.BMP')
end;

procedure FreeCursor;
begin
  FreeTex(cursor)
end;

procedure InitMouse;
var
  Regs: Registers;
begin
  if isMouseInitialised then exit;

  regs.ax := 0;
  Intr($33, regs);

  if regs.ax = 0 then
    PanicHalt('No mouse driver is found!')
  else
    WriteLog('Mouse has been initialised');

  isMouseInitialised := true
end;


procedure UpdateMouse;
var
  Regs: Registers;
begin
  if not isMouseInitialised then exit;

  regs.ax := 3;
  intr($33, regs);
  mouseX := regs.cx div 2;
  mouseY := regs.dx;
  mouseButton := regs.bx;
end;

procedure DebugMouse;
begin
  if not isMouseInitialised then begin
    Print('Mouse has not been initialised!', 0, 0, 15);
    exit
  end;

  Print('Mouse: {x:' + I32Str(mouseX) + ', y:' + I32Str(mouseY) + '}', 0, 0, 15);
  Print('Buttons: ' + I32Str(mouseButton), 0, 8, 15);
end;


procedure DrawMouse;
begin
  if not isMouseInitialised then exit;

  VGASpr(cursor, mouseX, mouseY);
end;

{
  Must be called before initTextMode
  to prevent 20302 runtime error
}
procedure ResetMouse;
var
  regs: Registers;
begin
  if not isMouseInitialised then exit;

  { Hide mouse cursor }
  regs.ax := 2;
  intr($33, regs);

  { Reset mouse driver to default state }
  regs.ax := 0;
  intr($33, regs);

  FreeCursor;
  isMouseInitialised := false
end;

begin
  isMouseInitialised := false;
end.

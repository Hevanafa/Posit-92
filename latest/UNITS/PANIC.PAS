unit Panic;

interface

procedure PanicHalt(const msg: string);

implementation

uses P92Core, Keyboard, Mouse, VGA;

procedure PanicHalt(const msg: string);
begin
  ResetKeyHandler;
  ResetMouse;
  InitModeText;
  WriteLn(msg);
  Halt(1)
end;

end.

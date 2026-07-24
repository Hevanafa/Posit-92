unit Panic;

{$J-}

interface

procedure PanicHalt(const msg: string);

implementation

uses P92Core, Keyboard, Mouse, VGA;

procedure PanicHalt(const msg: string);
begin
  ResetKeyHandler;
  ResetMouse;
  InitTextMode;
  WriteLn(msg);
  Halt(1)
end;

end.

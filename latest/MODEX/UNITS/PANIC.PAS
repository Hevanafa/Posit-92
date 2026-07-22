unit Panic;

interface

procedure panicHalt(const msg: string);

implementation

uses ModeX, XMouse;

procedure panicHalt(const msg: string);
begin
  { resetKeyHandler; }
  resetMouse;
  initTextMode;
  writeLn(msg);
  halt(1)
end;

end.

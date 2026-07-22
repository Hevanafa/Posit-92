unit Panic;

interface

procedure panicHalt(const msg: string);

implementation

uses Keyboard, NokiaVGA;

procedure panicHalt(const msg: string);
begin
  resetKeyHandler;
  initTextMode;
  writeLn(msg);
  halt(1)
end;

end.

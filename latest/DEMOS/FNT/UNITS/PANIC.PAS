unit Panic;

interface

procedure panicHalt(const msg: string);

implementation

uses VGA;

procedure panicHalt(const msg: string);
begin
  initTextMode;
  writeLn(msg);
  halt(1)
end;

end.

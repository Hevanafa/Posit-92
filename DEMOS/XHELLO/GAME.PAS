{
  Bare minimum Posit-92 application in Mode X
  Part of Posit-92 game framework
}

uses
  CRT,
  ModeX, Logger;

var
  done: boolean;

procedure INIT;
begin
  initLogger;
  initModeX;
  loadFont;

  randomize;
end;


procedure update;
begin
  if keyPressed then if readKey = #27 then done := true;
end;


procedure draw;
begin
  cls($7D);
  print('Hello world!', 160-48, 120, 15);
end;

var
  a, b: integer;
begin
  INIT;
  done := false;

  repeat
    update;
    draw;
    flipPages
  until done;

  closeLogger;
  initTextMode
end.

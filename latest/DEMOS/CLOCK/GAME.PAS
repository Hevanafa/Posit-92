
uses
  CRT, DOS,
  Conv, Logger, Timing, VGA;

var
  done: boolean;

procedure INIT;
begin
  randomize;
  initLogger;
  initVGAMode;
  loadFont;
  initBuffer;
  initDeltaTime;
end;


procedure update;
var
  a: integer;
begin
  updateDeltaTime;
  if keyPressed then
    if readKey = #27 then done := true;
end;


function getHours: byte;
begin
  getHours := trunc(timer) div 3600
end;

function getMinutes: byte;
begin
  getMinutes := trunc(timer) mod 3600 div 60
end;

function getSeconds: byte;
begin
  getSeconds := trunc(timer) mod 60
end;

function format2Digits(const value: integer): string;
begin
  if value < 10 then
    format2Digits := '0' + i32str(value)
  else
    format2Digits := i32str(value);
end;


procedure draw;
var
  a: integer;
  s: string;
begin
  cls($7D);
  print(
    format2Digits(getHours) + ':' +
    format2Digits(getMinutes) + ':' +
    format2Digits(getSeconds), 160-32, 96, 15);
  print('Esc - Exit', 0, 191, 15);
  flush
end;


begin
  INIT;
  done := false;

  repeat
    update;
    draw
  until done;

  freeBuffer;
  closeLogger;
  initTextMode
end.


uses
  CRT, DOS,
  P92Core, Conv, Keyboard, Logger, Timing, VGA;

function GetHours: byte;
begin
  GetHours := trunc(timer) div 3600
end;

function GetMinutes: byte;
begin
  GetMinutes := trunc(timer) mod 3600 div 60
end;

function GetSeconds: byte;
begin
  GetSeconds := trunc(timer) mod 60
end;

function Format2Digits(const value: integer): string;
begin
  if value < 10 then
    Format2Digits := '0' + i32str(value)
  else
    Format2Digits := i32str(value);
end;


procedure Update; far;
var
  a: integer;
begin
  if IsKeyDown(SC_ESCAPE) then SignalDone;
end;

procedure Draw; far;
var
  a: integer;
  s: string;
begin
  cls($7D);

  print(
    Format2Digits(GetHours) + ':' +
    Format2Digits(GetMinutes) + ':' +
    Format2Digits(GetSeconds), 160-32, 96, 15);

  print('Esc - Exit', 0, 191, 15);
end;


var
  appConfig: TP92AppConfig;
begin
  DefaultP92AppConfig(appConfig);

  appConfig.LoadDefaultCursor := false;
  @appConfig.Update := @Update;
  @appConfig.Draw := @Draw;

  P92Start(appConfig)
end.



uses
  CRT, DOS,
  P92Core, Conv, Logger, Timing, P92VGA;

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
begin
  if KeyPressed and (ReadKey = #27) then SignalDone;
end;

procedure Draw; far;
var
  s: string;
begin
  cls($7D);

  s := Format2Digits(GetHours) + ':' +
    Format2Digits(GetMinutes) + ':' +
    Format2Digits(GetSeconds);
  Print(s, (VGAWidth - length(s) * 8) div 2, 96, 15);

  Print('Esc - Exit', 0, 191, 15);
end;


var
  appConfig: TP92AppConfig;
begin
  DefaultP92AppConfig(appConfig);

  appConfig.LoadDefaultCursor := false;
  appConfig.EnableKeyHandler := false;

  @appConfig.Update := @Update;
  @appConfig.Draw := @Draw;

  P92Start(appConfig)
end.


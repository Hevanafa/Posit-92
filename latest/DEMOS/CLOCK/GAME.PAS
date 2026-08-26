
uses
  CRT, DOS,
  P92Core, Conv, P92LOG, Timing, P92VGA;

{ t: time of the day in seconds, obtained from GetTimer }
function GetHours(const t: double): byte;
begin
  GetHours := trunc(t) div 3600
end;

{ t: time of the day in seconds, obtained from GetTimer }
function GetMinutes(const t: double): byte;
begin
  GetMinutes := trunc(t) mod 3600 div 60
end;

{ t: time of the day in seconds, obtained from GetTimer }
function GetSeconds(const t: double): byte;
begin
  GetSeconds := trunc(t) mod 60
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
  year, month, day, dayOfWeek: word;
  now: double;
begin
  now := GetTimer;

  cls($7D);

  GetDate(year, month, day, dayOfWeek);

  s := Format2Digits(day) + '-' +
    Format2Digits(month) + '-' +
    Format2Digits(year);

  print(s, (VGAWidth - length(s) * 8) div 2, 88, 15);

  s := Format2Digits(GetHours(now)) + ':' +
    Format2Digits(GetMinutes(now)) + ':' +
    Format2Digits(GetSeconds(now));

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


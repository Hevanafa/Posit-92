{
  CGA font effects demo
  Part of Posit-92 game engine
  Referenced from https://blinry.org/50-tic80-carts/
}

uses
  CRT,
  P92Core, VGA;

procedure PrintOutline(const t: string; const x, y: integer; const colour, outline: byte);
var
  dx, dy: integer;
begin
  for dy:=-1 to 1 do
    for dx:=-1 to 1 do
      Print(t, x+dx, y+dy, outline);

  Print(t, x, y, colour)
end;

procedure PrintShadow(const t: string; const x, y: integer; const colour, shadow: byte);
begin
  Print(t, x+2, y+2, shadow);
  Print(t, x, y, colour)
end;

{ Modified from VGA }
procedure PrintStripes(const text: string; const x, y: integer);
var
  row, col, idx: integer;
  pos: integer;
  mask, colour: byte;
begin
  for idx := 1 to length(text) do begin
    if (idx < 0) or (idx > 127) then continue;

    for row := 0 to 7 do begin
      mask := BorrowCGAFont^[ord(text[idx]), row];
      colour := row + 8;
      for col := 0 to 7 do
        if (mask and (1 shl (7 - col))) <> 0 then begin
          pset((idx-1) * 8 + x + col, y + row, colour);
          end;
    end;
  end;
end;


procedure Update; far;
begin
  if keyPressed and (ReadKey = #27) then SignalDone;
end;


procedure Draw; far;
var
  a: integer;
begin
  cls($7D);

  PrintOutline('Outline!', 50, 50, 0, $0B);
  PrintShadow('Shadow!', 50, 70, $2A, 0);
  PrintStripes('Stripes!', 50, 90);
end;


var
  appConfig: TP92AppConfig;
begin
  DefaultP92AppConfig(appConfig);

  appConfig.EnableKeyHandler := false;
  appConfig.LoadDefaultCursor := false;

  @appConfig.Update := @Update;
  @appConfig.Draw := @Draw;

  P92Start(appConfig)
end.


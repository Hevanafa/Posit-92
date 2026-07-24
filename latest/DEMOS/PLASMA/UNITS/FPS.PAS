unit FPS;

interface

procedure initFPSCounter;
procedure incrementFPS;
procedure drawFPS;


implementation

uses Timing, Conv, VGA;

var
  nowFPS, lastFPS: integer;
  lastFPSTime: double; { in seconds }

procedure initFPSCounter;
begin
  nowFPS := 0;
  lastFPS := 0;
  lastFPSTime := getTimer;
end;

procedure incrementFPS;
begin
  nowFPS := nowFPS + 1;
  if Timer - lastFPSTime >= 1.0 then begin
    lastFPSTime := Timer;
    lastFPS := nowFPS;
    nowFPS := 1
  end;
end;

procedure drawFPS;
begin
  print('FPS:' + i32str(lastFPS), 240, 0, $0E);
end;


end.
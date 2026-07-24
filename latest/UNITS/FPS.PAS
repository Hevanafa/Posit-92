unit FPS;

interface

procedure InitFPSCounter;
procedure IncrementFPS;
procedure DrawFPS;


implementation

uses
{$IFDEF P92_MODEX}
  ModeX,
{$ELSE}
  VGA,
{$ENDIF}
  Timing, Conv;

var
  nowFPS, lastFPS: integer;
  lastFPSTime: double; { in seconds }

procedure InitFPSCounter;
begin
  nowFPS := 0;
  lastFPS := 0;
  lastFPSTime := getTimer;
end;

procedure IncrementFPS;
begin
  nowFPS := nowFPS + 1;
  if Timer - lastFPSTime >= 1.0 then begin
    lastFPSTime := Timer;
    lastFPS := nowFPS;
    nowFPS := 1
  end;
end;

procedure DrawFPS;
begin
  Print('FPS:' + i32str(lastFPS), 240, 0, $0E)
end;


end.

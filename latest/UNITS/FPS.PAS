unit FPS;

{$IFDEF FPC}
{$MODE TP}
{$ENDIF}

interface

procedure InitFPSCounter;
procedure IncrementFPS;
procedure DrawFPS;


implementation

uses
{$IFDEF P92_MODEX}
  ModeX,
{$ELSE}
  P92VGA,
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
  Print('FPS:' + I32Str(lastFPS), 240, 0, $0E)
end;


end.

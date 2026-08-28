{
  FPS utility unit
  Part of Posit-92 game engine
}

unit P92FPS;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

interface

procedure InitFPSCounter;
procedure IncrementFPS;
procedure DrawFPS;
function GetLastFPS: integer;


implementation

uses
{$IFDEF P92_MODE_X}
  P92MODEX,
{$ELSE}
  P92VGA,
{$ENDIF}
  P92TIME, P92CONV;

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

function GetLastFPS: integer;
begin
  GetLastFPS := lastFPS
end;


end.

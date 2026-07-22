unit P92Core;

{$IFDEF FPC}
{$MODE TP}
{$ENDIF}

interface

type
  TP92AppConfig = record
    { Callbacks }
    OnPreload: procedure;
    OnReady: procedure;
    Update: procedure;
    Draw: procedure;
    OnCleanup: procedure;
  end;


procedure DefaultP92AppConfig(var config: TP92AppConfig);
procedure P92Start(const config: TP92AppConfig);


implementation

procedure P92Start;
begin
  Randomize;

  InitLogger;
  InitVGAMode;
  LoadFont;
  InitBuffer;
  InitDeltaTime;
  InitKeyHandler;
  InitMouse;

  OnPreload;
end;

function DefaultP92AppConfig: TP92AppConfig;
var
  result: TP92AppConfig;
begin
  with result do begin
    OnPreload := nil;
  end;
end;

procedure P92Start(config: TP92AppConfig);
begin

end;



end.


unit P92Core;

{$IFDEF FPC}
{$MODE TP}
{$ENDIF}

interface

type
  TP92Callback = procedure;

  TP92AppConfig = record
    { Callbacks }
    OnPreload: TP92Callback;
    OnReady: TP92Callback;
    Update: TP92Callback;
    Draw: TP92Callback;
    OnCleanup: TP92Callback;
  end;


procedure DefaultP92AppConfig(var config: TP92AppConfig);
procedure P92Start(const config: TP92AppConfig);


implementation

uses
  Logger, Timing, Keyboard, Mouse, VGA;

procedure DefaultP92AppConfig(var config: TP92AppConfig);
begin
  @config.OnPreload := nil;
  @config.OnReady := nil;
  @config.Update := nil;
  @config.Draw := nil;
  @config.OnCleanup := nil;
end;

procedure P92Start(const config: TP92AppConfig);
begin
  Randomize;

  InitLogger;
  InitVGAMode;
  LoadFont;
  InitBuffer;
  InitDeltaTime;
  InitKeyHandler;
  InitMouse;

  if @config.OnPreload <> nil then
    config.OnPreload;

  { TODO: OnReady }
  { TODO: Move the game loop here }
  { TODO: OnCleanup}
end;


end.


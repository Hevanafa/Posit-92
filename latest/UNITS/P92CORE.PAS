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


procedure SignalDone;

procedure DefaultP92AppConfig(var config: TP92AppConfig);
procedure P92Start(const config: TP92AppConfig);


implementation

uses
  FPS, Logger, Timing, Keyboard, Mouse, VGA;

var
  done: boolean;

procedure SignalDone;
begin
  done := true
end;

procedure DefaultP92AppConfig(var config: TP92AppConfig);
begin
  @config.OnPreload := nil;
  @config.OnReady := nil;
  @config.Update := nil;
  @config.Draw := nil;
  @config.OnCleanup := nil;
end;

procedure P92Init;
begin
  Randomize;

  initLogger;
  initVGAMode;
  loadFont;
  initBuffer;
  initDeltaTime;

  initKeyHandler;
  initMouse;

  initFPSCounter;
end;

procedure P92Cleanup;
begin
  ResetMouse;
  ResetKeyHandler;
  FreeBuffer;
  CloseLogger;
  InitTextMode;
end;

procedure P92Update;
begin
  UpdateDeltaTime;
  UpdateMouse;
  incrementFPS;
end;

procedure P92Draw;
begin
  { no-op }
end;

procedure P92AfterDraw;
begin
  drawFPS;

  Flush
end;

procedure P92Start(const config: TP92AppConfig);
var
  now,
  nextUpdateTick,
  nextDrawTick: double;
begin
  P92Init;

  if @config.OnPreload <> nil then
    config.OnPreload;

  if @config.OnReady <> nil then
    config.OnReady;

  now := GetTimer;
  nextUpdateTick := now;
  nextDrawTick := now;

  repeat
    now := GetTimer;
    incrementFPS;

    if now >= nextUpdateTick then begin
      nextUpdateTick := now + 1.0 / 20.0;

      P92Update;
      config.Update
    end;

    if now >= nextDrawTick then begin
      nextDrawTick := now + 1.0 / 60.0;

      P92Draw;
      config.Draw;
      P92AfterDraw
    end;
  until done;

{
  done := false;

  repeat
    P92Update;
    config.Update;

    P92Draw;
    config.Draw;
    P92AfterDraw;
  until done;
}

  if @config.OnCleanup <> nil then
    config.OnCleanup;

  P92Cleanup
end;


end.


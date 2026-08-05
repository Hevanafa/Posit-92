
uses
  CRT, DOS,
  P92Core, Conv, Logger, FPS, P92KBD, P92Mouse, Timing, P92VGA,
  MonoTex, MonoVGA;

var
  { Asset variables }
  cursor: TMonoTexture;
  playdate: TMonoTexture;

  { Game state variables }
  done: boolean;
  t: double;


procedure OnPreload; far;
begin
  LoadMonoTex(cursor, 'CUR1BPP.BMP');
  LoadMonoTex(playdate, 'PLAYDATE.BMP');
end;

procedure OnCleanup; far;
begin
  FreeMonoTex(cursor);
  FreeMonoTex(playdate);
end;

procedure OnReady; far;
begin
  t := 0.0
end;

procedure DrawMouseMono;
begin
  SprMono(cursor, mouseX, mouseY, $0C)
end;


procedure Update; far;
begin
  if IsKeyDown(SC_ESCAPE) then done := true; { SignalDone; }

  t:=t+DeltaTime;
end;


procedure Draw; far;
begin
  Cls1BPP($00);

  { SprMono(playdate, 9, 4, 15); }
  { debugMouse; }

  { PSet1BPP(10, 10, 1); }
  Print1BPP('Hello from 1BPP!', (VGAWidth - 152) div 2, 100, 1);
  Print1BPP('FPS:' + I32Str(GetLastFPS), 240, 0, 1);

  DrawMouseMono;
end;


begin
  LoadCGAFont;

  InitBuffer(320, 200);
  InitMode13h;

  InitKeyHandler;
  InitMouse;

  InitDeltaTime;
  InitFPSCounter;

  OnPreload;
  OnReady;

  done := false;

  repeat
    UpdateDeltaTime;
    IncrementFPS;
    UpdateMouse;

    { User code }
    Update;
    Draw;

    { After draw }
    Present1BPP;
  until done;

  OnCleanup;

  ResetKeyHandler;
  ResetMouse;
  FreeBuffer;
  InitModeText;
end.

{
var
  appConfig: TP92AppConfig;
begin
  DefaultP92AppConfig(appConfig);

  appConfig.LoadDefaultCursor := false;
  @appConfig.OnPreload := @OnPreload;
  @appConfig.OnReady := @OnReady;
  @appConfig.Update := @Update;
  @appConfig.Draw := @Draw;
  @appConfig.OnCleanup := @OnCleanup;

  P92Start(appConfig)
end.
}


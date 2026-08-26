
uses
  CRT, DOS,
  P92Core, Conv, P92LOG, FPS, P92KBD, P92Mouse, Timing, P92VGA,
  MonoTex, MonoVGA;

var
  { Asset variables }
  imgCursor: TMonoTexture;
  imgDosuEXE: array[0..1] of TMonoTexture;

  { Game state variables }
  done: boolean;
  t: double;


procedure OnPreload; far;
begin
  LoadMonoTex(imgCursor, 'CUR1BPP.BMP');
  LoadMonoTex(imgDosuEXE[0], 'DOSU_1.BMP');
  LoadMonoTex(imgDosuEXE[1], 'DOSU_2.BMP');
end;

procedure OnCleanup; far;
begin
  FreeMonoTex(imgCursor);
  FreeMonoTex(imgDosuEXE[0]);
  FreeMonoTex(imgDosuEXE[1]);
end;

procedure OnReady; far;
begin
  t := 0.0
end;

procedure DrawMouseMono;
begin
  SprMono8(imgCursor, mouseX, mouseY)
end;


procedure Update; far;
begin
  if IsKeyDown(SC_ESCAPE) then done := true; { SignalDone; }

  t:=t+DeltaTime;
end;


procedure Draw; far;
begin
  Cls1BPP($00);

  if frac(t * 1.5) >= 0.5 then
    SprMonoBaseRef(imgDosuEXE[1], 148, 76)
  else
    SprMonoBaseRef(imgDosuEXE[0], 148, 76);

  { PSet1BPP(10, 10, 1); }
  Print1BPP('Hello from 1BPP!', VGAWidth div 2 - 64, 120, 1);
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


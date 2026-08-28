
uses
  CRT, DOS,
  P92CORE, P92CONV, P92LOG, P92FPS, P92KBD, P92MOUSE, P92TIME, P92VGA,
  P92MONO, P92MNTEX;

var
  { Asset variables }
  texCursor: TMonoTexture;
  texDosuEXE: array[0..1] of TMonoTexture;

  { Game state variables }
  done: boolean;
  t: double;


procedure OnPreload; far;
begin
  LoadMonoTex(texCursor, 'CUR1BPP.BMP');
  LoadMonoTex(texDosuEXE[0], 'DOSU_1.BMP');
  LoadMonoTex(texDosuEXE[1], 'DOSU_2.BMP');
end;

procedure OnCleanup; far;
begin
  FreeMonoTex(texCursor);
  FreeMonoTex(texDosuEXE[0]);
  FreeMonoTex(texDosuEXE[1]);
end;

procedure OnReady; far;
begin
  t := 0.0
end;

procedure DrawMouseMono;
begin
  SprMono8(texCursor, GetMouseX, GetMouseY)
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
    SprMonoBaseRef(texDosuEXE[1], 148, 76)
  else
    SprMonoBaseRef(texDosuEXE[0], 148, 76);

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


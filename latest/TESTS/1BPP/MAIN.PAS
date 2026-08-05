
uses
  CRT, DOS,
  P92Core, Conv, Logger, FPS, P92KBD, P92Mouse, Timing, P92VGA,
  MonoTex, MonoVGA;

var
  { Asset variables }
  cursor: TMonoTexture;
  playdate: TMonoTexture;

  { Game state variables }
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

procedure drawMouseMono;
begin
  SprMono(cursor, mouseX, mouseY, $0C)
end;


procedure Update; far;
begin
  if isKeyDown(SC_ESCAPE) then SignalDone;

  t:=t+DeltaTime;
end;


procedure Draw; far;
begin
  cls($7D);

  SprMono(playdate, 9, 4, 15);
  print('Hello world!', 160-48, 136, $7D);
  debugMouse;
  drawMouseMono;
end;

var
  done: boolean;
begin
  LoadCGAFont;

  InitBuffer(320, 200);
  InitMode13h;

  InitDeltaTime;
  InitFPSCounter;

  done := false;

  repeat
    { Update }
    UpdateDeltaTime;
    IncrementFPS;

    if KeyPressed and (ReadKey = #27) then done := true;

    { Draw }
    Cls1BPP($00);

    { PSet1BPP(10, 10, 1); }
    Print1BPP('Hello from MONOVGA!', (VGAWidth - 152) div 2, 100, 1);

    Print1BPP('FPS:' + I32Str(GetLastFPS), 240, 0, 1);

    Present1BPP;
  until done;

  { Benchmarking procedures }
  { PSet10000; }
  { Present100; }

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


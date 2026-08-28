{
  Mode X demo
  Part of Posit-92 game engine

  Requires P92_MODE_X custom directive enabled in Turbo Pascal:
  1. Options menu > Compiler...
  2. Conditional defines

  Also, all the TPU files must be cleaned up first
  since stale units may have the version without P92_MODE_X enabled
}

{$DEFINE DEBUG}

uses
  CRT,
  P92CORE, P92FPS, P92MOUSE, P92CONV, P92LOG, P92TIME, P92TEX, P92MODEX; { , XBitmap }

var
  { Asset variables }
  imgCursor: TTexture;
  imgSpecimenP92: array[0..1] of TTexture;

  { Game state variables }
  t: double;

procedure OnPreload; far;
begin
  LoadTex(imgCursor, 'CURSOR.BMP');
  LoadTex(imgSpecimenP92[0], 'IMG\SPP92_1.BMP');
  LoadTex(imgSpecimenP92[1], 'IMG\SPP92_2.BMP');
end;

procedure OnCleanup; far;
begin
  FreeTex(imgCursor);
  FreeTex(imgSpecimenP92[0]);
  FreeTex(imgSpecimenP92[1]);
end;

procedure OnReady; far;
begin
  t := 0.0;
end;

procedure Update; far;
begin
  if keyPressed and (readKey = #27) then SignalDone;

  t := t + DeltaTime;
end;

procedure Draw; far;
begin
  cls($7D);

  { print('getTimer:' + f32str(getTimer), 0, 20, 15); }
  if frac(t * 1.5) >= 0.5 then
    Spr(imgSpecimenP92[0], 148, 76)
  else
    Spr(imgSpecimenP92[1], 148, 76);

  Print('Hello from Mode X!', 160-72, 120, 15);

  spr(imgCursor, GetMouseX, GetMouseY);
end;


var
  appConfig: TP92AppConfig;
begin
  DefaultP92AppConfig(appConfig);

  appConfig.EnableKeyHandler := false;
  appConfig.LoadDefaultCursor := false;
  appConfig.WaitMode := P92WaitVSync;

  @appConfig.OnPreload := @OnPreload;
  @appConfig.OnReady := @OnReady;
  @appConfig.Update := @Update;
  @appConfig.Draw := @Draw;

  P92Start(appConfig)
end.


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
  P92Core, P92Mouse, Conv, Logger, Timing, P92TEX, ModeX; { , XBitmap }

var
  imgCursor: TTexture;
  imgSpecimenP92: array[0..1] of TTexture;

procedure OnPreload; far;
begin
  LoadTex(imgCursor, 'CURSOR.BMP');
  LoadTex(imgSpecimenP92[0], 'IMG\SPP92_1.BMP');
  LoadTex(imgSpecimenP92[1], 'IMG\SPP92_2.BMP');
end;

procedure Update; far;
begin
  if keyPressed and (readKey = #27) then SignalDone;
end;

procedure Draw; far;
begin
  cls($7D);

  { print('getTimer:' + f32str(getTimer), 0, 20, 15); }
  spr(imgSpecimenP92[0], 100, 100);

  Print('Top area', 0, 20, 15);
  Print('Hello world!', 160-48, 120, 15);

  spr(imgCursor, mouseX, mouseY);
end;


var
  appConfig: TP92AppConfig;
begin
  DefaultP92AppConfig(appConfig);

  appConfig.EnableKeyHandler := false;
  appConfig.LoadDefaultCursor := false;
  appConfig.WaitMode := P92WaitVSync;

  @appConfig.Update := @Update;
  @appConfig.Draw := @Draw;

  P92Start(appConfig)
end.


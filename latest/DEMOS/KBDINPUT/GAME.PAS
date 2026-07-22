program Game;

uses
  CRT, DOS,
  P92Core,
  Logger, Keyboard, Mouse, Timing, VGA,
  Bitmap;

var
  { Asset variables }
  DosuEXE: array[0..1] of PBitmap;

  { Game state variables }
  t: double;


procedure OnPreload; far;
begin
  LoadBMP(dosuEXE[0], 'IMG/DOSU_1.BMP');
  LoadBMP(dosuEXE[1], 'IMG/DOSU_2.BMP');
end;

procedure OnReady; far;
begin
  { Init game state here }
  t := 0.0;
end;

procedure OnCleanup; far;
begin
  { Free all the resources here }
  FreeBMP(dosuEXE[0]);
  FreeBMP(dosuEXE[1]);
end;

procedure Update; far;
begin
  if IsKeyDown(SC_ESCAPE) then SignalDone;

  t := t + DeltaTime
end;

procedure Draw; far;
var
  a: integer;
begin
  Cls($7D);

  { TODO: Your drawing code here }

  if frac(t * 1.5) >= 0.5 then
    Spr(dosuEXE[0], 148, 76, 13)
  else
    Spr(dosuEXE[1], 148, 76, 13);

  Print('Hello world!', 160-48, 120, 15);

  DrawMouse;
end;


var
  appConfig: TP92AppConfig;
begin
  DefaultP92AppConfig(appConfig);

  @appConfig.OnPreload := @OnPreload;
  @appConfig.OnReady := @OnReady;
  @appConfig.Update := @Update;
  @appConfig.Draw := @Draw;
  @appConfig.OnCleanup := @OnCleanup;

  P92Start(appConfig)
end.


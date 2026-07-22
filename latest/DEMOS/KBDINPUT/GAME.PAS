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
  done: boolean;
  t: double;


procedure OnPreload;
begin
  LoadBMP(dosuEXE[0], 'IMG/DOSU_1.BMP');
  LoadBMP(dosuEXE[1], 'IMG/DOSU_2.BMP');
end;

procedure OnReady;
begin
  { Init game state here }
  t := 0.0;
end;

procedure OnCleanup;
begin
  { Free all the resources here }
  FreeBMP(dosuEXE[0]);
  FreeBMP(dosuEXE[1]);
end;

procedure Update;
var
  a: integer;
begin
  UpdateDeltaTime;
  UpdateMouse;

  { TODO: Your Update code here }

  if IsKeyDown(SC_ESCAPE) then done := true;
  t:=t+dt
end;

procedure Draw;
var
  a: integer;
begin
  Cls($7D);

  { TODO: Your drawing code here }

  if (trunc(t * 1.5) and 1) = 0 then
    Spr(dosuEXE[0], 148, 76, 13)
  else
    Spr(dosuEXE[1], 148, 76, 13);

  Print('Hello world!', 160-48, 120, 15);

  DrawMouse;

  Flush
end;


var
  appConfig: TP92AppConfig;

begin
  DefaultP92AppConfig(appConfig);

  @appConfig.OnPreload := @OnPreload;
  @appConfig.OnReady := @OnReady;
  @appConfig.OnCleanup := @OnCleanup;

  P92Start(appConfig);

  done := false;

  repeat
    Update;
    Draw;
  until done;
end.

program Game;

uses
  CRT, DOS,
  Logger, Keyboard, Mouse, Timing, VGA,
  Bitmap;
  { Conv, FPS, Graphics, PCS; }

const
  K_ESC = $01;
var
  done: boolean;
  t: double;
  DosuEXE: array[0..1] of PBitmap;
  { TODO: More of your game state here }


procedure INIT;
begin
  Randomize;

  InitLogger;
  InitVGAMode;
  LoadFont;
  InitBuffer;
  InitDeltaTime;
  InitKeyHandler;
  InitMouse;

  { TODO: Your init code here }

  loadBMP(dosuEXE[0], 'IMG/DOSU_1.BMP');
  loadBMP(dosuEXE[1], 'IMG/DOSU_2.BMP');
end;


procedure update;
var
  a: integer;
begin
  UpdateDeltaTime;
  UpdateMouse;

  { TODO: Your update code here }

  if IsKeyDown(K_ESC) then done := true;
  t:=t+dt
end;


procedure draw;
var
  a: integer;
begin
  Cls($7D);

  { TODO: Your drawing code here }

  if (trunc(t * 1.5) and 1) = 0 then
    spr(dosuEXE[0], 148, 76, 13)
  else
    spr(dosuEXE[1], 148, 76, 13);

  Print('Hello world!', 160-48, 120, 15);

  DrawMouse;

  Flush
end;


var
  a: integer;

begin
  INIT;
  done := false;

  repeat
    update;
    draw;
  until done;

  { TODO: Your cleanup code here }
  freeBMP(dosuEXE[0]);
  freeBMP(dosuEXE[1]);

  ResetMouse;
  ResetKeyHandler;
  FreeBuffer;
  CloseLogger;
  InitTextMode
end.

program Game;

uses
  CRT, DOS,
  Logger, Keyboard, Mouse, Timing, VGA,
  Bitmap;
  { Conv, FPS, Graphics, PCS; }

var
  { Game state variables }
  done: boolean;
  t: double;
  DosuEXE: array[0..1] of PBitmap;


procedure Init;
begin
  Randomize;

  InitLogger;
  InitVGAMode;
  LoadFont;
  InitBuffer;
  InitDeltaTime;
  InitKeyHandler;
  InitMouse;

  { TODO: Your Init code here }

  LoadBMP(dosuEXE[0], 'IMG/DOSU_1.BMP');
  LoadBMP(dosuEXE[1], 'IMG/DOSU_2.BMP');
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
  a: integer;

begin
  Init;
  done := false;

  repeat
    Update;
    Draw;
  until done;

  { Cleanup code here }
  FreeBMP(dosuEXE[0]);
  FreeBMP(dosuEXE[1]);

  ResetMouse;
  ResetKeyHandler;
  FreeBuffer;
  CloseLogger;
  InitTextMode
end.


uses
  CRT, DOS,
  Logger, Conv, Bitmap,
  P92KBD, P92Mouse,
  Timing, P92VGA;

var
  { Asset variables }
  DosuEXE: array[0..1] of PBitmap;

  { Game state variables }
  done: boolean;
  t: double;


procedure INIT;
begin
  InitLogger;
  InitMode13h;
  Vert400;
  LoadCGAFont;
  InitBuffer(320, 200);
  InitDeltaTime;

  initKeyHandler;
  initMouse;

  { TODO: Your init code here }

  randomize;

  loadBMP(dosuEXE[0], 'IMG/DOSU_1.BMP');
  loadBMP(dosuEXE[1], 'IMG/DOSU_2.BMP');
end;


procedure Update;
var
  a: integer;
begin
  updateDeltaTime;
  updateMouse;

  { TODO: Your Update code here }

  if isKeyDown(SC_ESCAPE) then done := true;
  t:=t+ DeltaTime;
end;


procedure Draw;
var
  a: integer;
begin
  cls($7D);

  { TODO: Your drawing code here }

  if (trunc(t * 1.5) and 1) = 0 then
    spr(dosuEXE[0], 148, 76)
  else
    spr(dosuEXE[1], 148, 76);

  print('Hello world!', 160-48, 120, 15);
  print('Mouse: ' + i32str(mouseX) + ', ' + i32str(mouseY), 0, 8, 15);

  doubleFlush;
  drawMouse
end;


var
  a: integer;

begin
  INIT;
  done := false;

  repeat
    Update;
    Draw;
  until done;

  { TODO: Your cleanup code here }
  freeBMP(dosuEXE[0]);
  freeBMP(dosuEXE[1]);

  ResetMouse;
  ResetKeyHandler;
  FreeBuffer;
  CloseLogger;
  InitModeText
end.

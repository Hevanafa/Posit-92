
uses
  CRT, DOS,
  P92LOG, P92CONV, P92KBD, P92MOUSE, P92TEX, P92TIME, P92VGA;

var
  { Asset variables }
  texDosuEXE: array[0..1] of TTexture;

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

  LoadTex(texDosuEXE[0], 'IMG/DOSU_1.BMP');
  LoadTex(texDosuEXE[1], 'IMG/DOSU_2.BMP');
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
    spr(texDosuEXE[0], 148, 76)
  else
    spr(texDosuEXE[1], 148, 76);

  print('Hello world!', 160-48, 120, 15);
  print('Mouse: ' + i32str(GetMouseX) + ', ' + i32str(GetMouseY), 0, 8, 15);

  { DoubleFlush; }
  PresentMode13h;
  { drawMouse }
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
  FreeTex(texDosuEXE[0]);
  FreeTex(texDosuEXE[1]);

  ResetMouse;
  ResetKeyHandler;
  FreeBuffer;
  CloseLogger;
  InitModeText
end.

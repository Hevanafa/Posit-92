
uses
  CRT,
  P92Core, Bitmap, Conv, Logger, Keyboard, Mouse, VGA;

var
  { Asset variables }
  kenneyTinytown: PBitmap;

  { Game state variables }
  lastX, lastY: integer;
  colour: byte;


function PGet(const x, y: integer): byte;
var
  offset: integer;
begin
  if (x < 0) or (x >= 320) or (y < 0) or (y >= 200) then begin
    PGet := 0;
    exit
  end;
  offset := y * 320 + x;
  PGet := Mem[$A000:offset]
end;

procedure OnPreload; far;
begin
  loadBMP(kenneyTinytown, 'IMG/TINYTOWN.BMP');
end;

procedure OnReady; far;
begin
  lastX := -1;
  lastY := -1;
  colour := $FF;
end;

procedure Update; far;
var
  a: integer;
  ch: char;
begin
  if IsKeyDown(SC_ESCAPE) then SignalDone;

  if (lastX <> mouseX) or (lastY <> mouseY) then begin
    lastX := mouseX;
    lastY := mouseY;
    colour := PGet(mouseX, mouseY);
  end;
end;


procedure Draw; far;
begin
  cls($7D);  
  
  drawBMP(kenneyTinytown);
  print('Colour: ' + i32str(colour), 4, 4, 15);
end;


var
  appConfig: TP92AppConfig;
begin
  DefaultP92AppConfig(appConfig);

  @appConfig.OnPreload := @OnPreload;
  @appConfig.OnReady := @OnReady;
  @appConfig.Update := @Update;
  @appConfig.Draw := @Draw;

  P92Start(appConfig)
end.


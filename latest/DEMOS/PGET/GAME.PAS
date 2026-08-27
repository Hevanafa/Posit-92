
uses
  CRT,
  P92Core, P92TEX, P92CONV, P92LOG, P92KBD, P92MOUSE, P92VGA;

var
  { Asset variables }
  imgKenneyTinytown: TTexture;

  { Game state variables }
  lastX, lastY: integer;
  colour: byte;


function PGet(const x, y: integer): byte;
var
  offset: integer;
begin
  if (word(x) >= VGAWidth) or (word(y) >= VGAHeight) then begin
    PGet := 0;
    exit
  end;
  offset := y * 320 + x;

  { PGet := Mem[$A000:offset] }
  PGet := surface^[offset]
end;

procedure OnPreload; far;
begin
  LoadTex(imgKenneyTinytown, 'IMG/TINYTOWN.BMP');
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
  
  spr(imgKenneyTinytown, 0, 0);

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


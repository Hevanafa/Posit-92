{
  Signal Hunt demo
  Part of Posit-92 game engine

  This demo is created to demonstrate the pattern with camera, similar to
  PICO-8's hidden camera variables

  Test games made with this using 386DX (4595 cycles/ms) CPU speed
}

{DEFINE DEBUG}
{DEFINE UNCAPPED}

uses
  CRT, DOS,
  P92CORE, P92CONV, P92FPS, P92GRAPH, P92LOG, P92MATHS, P92KBD, P92STR, P92TIME,
  P92TEX, P92BMFON, P92VGA,
  Camera;

const
  SC_UP = $48;
  SC_DOWN = $50;
  SC_LEFT = $4B;
  SC_RIGHT = $4D;

  { Softkey keys }
  SC_RETURN = $1C;
  SC_Z = $2C;

  { C keys }
  SC_ESC = $01;
  SC_X = $2D;

var
  startTick, t: double;
  lastSoftKey: boolean;
  isSoftKey: boolean;

  nokiaFont, p8Font: TBMFont;
  imgRadio, imgSignal: TTexture;
  imgPlayer, imgPlayerWalk: TTexture;

  isMenu: boolean;
  radioCount: word;

  palette: array[0..1] of byte;
  playerX, playerY: integer;
  radioX, radioY: integer;


procedure ClearVGAMem; assembler;
asm
  push es

  { Assign ES:DI to $A000:0000 }
  mov ax, $A000
  mov es, ax
  xor di, di

  xor ax, ax  { reset AX to 0 }
  mov cx, 32000
  cld
  rep stosw

  pop es
end;


procedure RandomiseRadio;
begin
  radioX := 10 + random(64);
  radioY := 10 + random(28);
end;


procedure OnPreload; far;
begin
  LoadBMFont(nokiaFont, 'FONTS\NOKIA.TXT');
  LoadBMFont(p8Font, 'FONTS\P8.TXT');

  LoadTex(imgRadio, 'IMG\RADIO.BMP');
  LoadTex(imgSignal, 'IMG\SIGNAL.BMP');
  LoadTex(imgPlayer, 'IMG\PSTAND.BMP');
  LoadTex(imgPlayerWalk, 'IMG\PWALK.BMP');

  { randomize; }
  palette[0] := 98;
  palette[1] := 8;
end;

procedure OnReady; far;
begin
  radioCount := 0;
  RandomiseRadio;

  playerX := 42;
  playerY := 24;

  { TODO: There can be the art around the border}
  startTick := getTimer;

  clearVGAMem;
end;

procedure Update; far;
begin
  if isKeyDown(SC_ESC) or isKeyDown(SC_X) then SignalDone;

  if isKeyDown(SC_UP) then dec(playerY);
  if isKeyDown(SC_DOWN) then inc(playerY);
  if isKeyDown(SC_LEFT) then dec(playerX);
  if isKeyDown(SC_RIGHT) then inc(playerX);
  isSoftKey := isKeyDown(SC_RETURN) or isKeyDown(SC_Z);

  if lastSoftKey <> isSoftKey then begin
    lastSoftKey := isSoftKey;

    if isSoftKey then
      isMenu := not isMenu;
  end;

  { TODO: Z or Enter - Soft key }
  { TODO: playerX or Escape - C button }

  SetCameraX(playerX - 40);  { 42 - 4 / 2 }
  SetCameraY(playerY - 21);  { 24 - 6 / 2 }

  if i32power(radioX - playerX, 2) + i32power(radioY - playerY, 2) <= 25 then begin
    inc(radioCount);
    RandomiseRadio
  end;
  
  t := getTimer - startTick
end;

procedure DrawFPS;
begin
  PrintBMFont(p8Font, 'FPS:' + i32str(GetLastFPS), 55, 0)
end;

procedure PrintP8(const txt: string; const x, y: integer);
begin
  PrintBMFont(p8Font, txt, x, y)
end;

procedure PrintNokia(const txt: string; const x, y: integer);
begin
  PrintBMFont(nokiaFont, txt, x, y)
end;


procedure Draw; far;
var
  w: word;
  a: byte;
begin
  Cls(palette[0]);

  if isMenu then begin
    PrintBMFont(nokiaFont, 'Game Menu', 0, 0);

    { nokiaFlushX2; }
    PresentMode13h;
    exit
  end;

  { Radio }
  { pascalSpr(imgRadio, radioX, radioY, 13); }
  if trunc(t * 16) shr 1 and 1 = 1 then
    PSetWithCamera(radioX, radioY, palette[1]);

  { Player }
  { pascalRect(playerX, playerY, playerX + 1, playerY + 1, palette[1]); }

  SprWithCamera(imgPlayer, playerX, playerY);

  { HUD }
  Spr(imgSignal, 0, 0);

  w := MeasureBMFont(nokiaFont, 'Menu');
  PrintNokia('Menu', (84 - w) shr 1, 38);
  PrintNokia(padStart(i32str(radioCount), 4, '0'), 0, 6);

  if isSoftKey then
    PrintP8('Softkey is pressed!', 4, 4);

  DrawFPS;

  { flush }
  { nokiaFlushX2 }
  PresentMode13h
end;


{
var
  now, nextGameTick: double;
begin
  INIT;

  nextGameTick := getTimer;

  x := 42; y := 24;

  isMenu := false;
  done := false;
}
{$IFDEF UNCAPPED}
  repeat
    update;
    draw
  until done;

{$ELSE}
{
  repeat
    now := getTimer;
    if now >= nextGameTick then begin
      nextGameTick := now + 1.0 / TARGET_FPS;
      update;
      draw
    end
  until done;
}
{$ENDIF}
{
  freeBMP(imgRadio);
  freeBMP(imgSignal);
  freeBMP(imgPlayer);
  freeBMP(imgPlayerWalk);

  freeBMFont(nokiaFont);
  freeBMFont(p8Font);

  resetKeyHandler;
  freeBuffer;
  closeLogger;
  initTextMode
end.
}


var
  appConfig: TP92AppConfig;
begin
  DefaultP92AppConfig(appConfig);

  appConfig.BufferWidth := 84;
  appConfig.BufferHeight := 48;

  @appConfig.OnPreload := @OnPreload;
  @appConfig.OnReady := @OnReady;
  @appConfig.Update := @Update;
  @appConfig.Draw := @Draw;
  { TODO: }
  { @appConfig.OnCleanup := @OnCleanup; }

  P92Start(appConfig)
end.


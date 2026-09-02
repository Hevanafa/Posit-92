{
  Immediate GUI demo
  Part of Posit-92 game engine

  The P92_IMGUI custom directive has to be included
}

program Game;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

uses
  CRT, DOS,
  P92CORE, P92LOG, P92CONV, P92BMFON, P92IMGUI, P92STR, P92TEX, P92TIME, P92VGA,
  P92KBD, P92MOUSE, P92PANIC;

var
  { Asset variables }
  fontP92Sans: TBMFont;
  texSpecimenP92: array[0..1] of TTexture;
  texCursor, texHand: TTexture;
  texButtonNormal, texButtonHovered, texButtonPressed: TTexture;

  { Game state variables }
  t: double;
  clicks: integer;
  testCheckboxState: boolean;
  testSliderState: integer;


procedure ReplaceColour(var tex: TTexture; const oldColour, newColour: byte);
var
  a, b: word;
  offset: word;
begin
  for b:=0 to tex.height - 1 do
    for a:=0 to tex.width - 1 do begin
      offset := b * tex.width + a;

      if tex.data^[offset] = oldColour then
        tex.data^[offset] := newColour;
    end;
end;

procedure DrawMouse;
begin
  if HasHoveredWidget then
    spr(texHand, GetMouseX - 5, GetMouseY - 1)
  else
    spr(texCursor, GetMouseX, GetMouseY);
end;

procedure OnPreload; far;
begin
  LoadBMFont(fontP92Sans, 'FONTS\P92SANS.TXT');

  LoadTex(texCursor, 'CURSOR.BMP');
  LoadTex(texHand, 'HAND.BMP');

  LoadTex(texSpecimenP92[0], 'IMG/SPP92_1.BMP');
  LoadTex(texSpecimenP92[1], 'IMG/SPP92_2.BMP');

  LoadTex(texButtonNormal, 'IMG\IMGUI\BUTTON_N.BMP');
  LoadTex(texButtonHovered, 'IMG\IMGUI\BUTTON_H.BMP');
  LoadTex(texButtonPressed, 'IMG\IMGUI\BUTTON_P.BMP');

  ReplaceColour(fontP92Sans.texture, $0F, $00);
end;

procedure OnReady; far;
begin
  { Init game state variables here }
  clicks := 0;

  testCheckboxState := false;
  testSliderState := 50;

  t := 0.0;
end;

procedure OnCleanup; far;
begin
  { Free all the resources here }
  FreeTex(texSpecimenP92[0]);
  FreeTex(texSpecimenP92[1]);
end;

procedure Update; far;
begin
  { Handle inputs here }
  if IsKeyDown(SC_ESCAPE) then SignalDone;

  { Handle game state updates here }

  t := t + DeltaTime
end;

procedure Draw; far;
begin
  Cls($4F);

  if frac(t * 1.5) >= 0.5 then
    Spr(texSpecimenP92[0], 148, 76)
  else
    Spr(texSpecimenP92[1], 148, 76);

  CentredLabel('Hello world!', VGAWidth div 2, 120);

  if Button('Clicks: ' + i32str(clicks), 10, 10) then
    inc(clicks);

  if ImageButton(10, 50, @texButtonNormal, @texButtonHovered, @texButtonPressed) then
    inc(clicks);

  if ImageButton(50, 50, @texButtonNormal, @texButtonHovered, @texButtonPressed) then
    inc(clicks);

  Checkbox('Checkbox!', 10, 80, testCheckboxState);

  if testCheckboxState then
    TextLabel('The light is on!', 10, 95);

  Checkbox('', 80, 80, testCheckboxState);

  if IsWidgetHovered then
    TextLabel('This checkbox is hovered', 90, 80);

  Slider(
    10, 100, 80,
    testSliderState, 0, 100);

  CentredLabel(i32str(testSliderState), 50, 120);

  DrawMouse
end;


var
  appConfig: TP92AppConfig;
begin
  DefaultP92AppConfig(appConfig);

  appConfig.DefaultBMFont := @fontP92Sans;

  appConfig.LoadDefaultCursor := false;

  @appConfig.OnPreload := @OnPreload;
  @appConfig.OnReady := @OnReady;
  @appConfig.Update := @Update;
  @appConfig.Draw := @Draw;
  @appConfig.OnCleanup := @OnCleanup;

  P92Start(appConfig)
end.

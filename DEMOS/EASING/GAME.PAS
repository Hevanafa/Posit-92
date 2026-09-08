program Game;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

uses
  CRT, DOS,
  P92CORE, P92EASE, P92LOG, P92GRAPH, P92BMFON, P92CONV, P92KBD, P92MOUSE, P92MATHS, P92STR, P92TEX, P92TIME, P92VGA;

type
  TEasingDemo = (
    EDLinear,
    EDInQuad,
    EDOutQuad
  );

var
  { Key state variables }
  lastSpacebar: boolean;
  lastLeft, lastRight: boolean;

  { Asset variables }
  fontRegular, fontBold: TBMFont;
  texSpecimenP92: array[0..1] of TTexture;

  { Game state variables }
  actualDemo: TEasingDemo;
  t: double;
  clickTick: double;


procedure PrintDefault(const text: string; const x, y: integer);
begin
  PrintBMFont(fontRegular, text, x, y)
end;

procedure PrintBold(const text: string; const x, y: integer);
begin
  PrintBMFont(fontBold, text, x, y)
end;

function GetDemoName(const ease: TEasingDemo): string;
var
  result: string;
begin
  case ease of
  EDLinear:
    result := 'EaseLinear (Lerp)';
  EDInQuad:
    result := 'EaseInQuad';
  EDOutQuad:
    result := 'EaseOutQuad';
  else
    result := 'Unknown easing ' + I32Str(ord(ease));
  end;

  GetDemoName := result
end;

procedure OnPreload; far;
begin
  { Load assets here }
  LoadBMFont(fontRegular, 'FONTS\P92SAN8R.TXT');
  LoadBMFont(fontBold, 'FONTS\P92SAN8B.TXT');

  LoadTex(texSpecimenP92[0], 'IMG/SPP92_1.BMP');
  LoadTex(texSpecimenP92[1], 'IMG/SPP92_2.BMP');
end;

procedure OnCleanup; far;
begin
  FreeTex(texSpecimenP92[0]);
  FreeTex(texSpecimenP92[1]);

  FreeBMFont(fontBold);
  FreeBMFont(fontRegular);
end;


procedure OnReady; far;
begin
  { Init game state variables here }
  t := 0.0;
  clickTick := 0.0;
  actualDemo := low(TEasingDemo);
end;

procedure Update; far;
begin
  { Handle inputs here }
  if IsKeyDown(SC_ESCAPE) then SignalDone;

  if lastSpacebar <> IsKeyDown(SC_SPACE) then begin
    lastSpacebar := IsKeyDown(SC_SPACE);

    if lastSpacebar then
      clickTick := t;
  end;

  if lastLeft <> IsKeyDown(SC_LEFT) then begin
    lastLeft := IsKeyDown(SC_LEFT);

    if lastLeft then begin
      { The pattern with a typed enum is "check before"
        Because it inherently uses `Byte`, rather than `Integer` }
      if actualDemo = low(TEasingDemo) then
        actualDemo := high(TEasingDemo)
      else
        dec(actualDemo);

      clickTick := t;
    end;
  end;

  if lastRight <> IsKeyDown(SC_RIGHT) then begin
    lastRight := IsKeyDown(SC_RIGHT);

    if lastRight then begin
      if actualDemo = high(TEasingDemo) then
        actualDemo := low(TEasingDemo)
      else
        inc(actualDemo);

      clickTick := t;
    end;
  end;

  { Handle game state updates here }

  t := t + DeltaTime
end;

procedure Draw; far;
const
  StartX = 100;
  EndX = 220;
var
  perc, lerpVal: double;
  x: integer;
  normalisedT: double;
begin
  Cls($4F);

  normalisedT := clamp(t - clickTick, 0.0, 3.0);
  perc := GetPerc(clickTick, 3.0, t);

  case actualDemo of
  EDInQuad:
    lerpVal := trunc(LerpEased(StartX, EndX, perc, EaseInQuad));
  EDOutQuad:
    lerpVal := trunc(LerpEased(StartX, EndX, perc, EaseOutQuad));
  else
    lerpVal := trunc(lerp(StartX, EndX, perc));
  end;

  HLine(StartX, EndX, 80, $00);

  x := trunc(lerpVal - texSpecimenP92[0].width / 2);

  if frac(t * 1.5) >= 0.5 then
    Spr(texSpecimenP92[0], x, 64)
  else
    Spr(texSpecimenP92[1], x, 64);

  PrintDefault('t: ' + F32Str(normalisedT), 120, 120);
  PrintDefault('value: ' + F32Str(lerpVal), 120, 128);

  { Header }

  PrintBold('Easing Demo', 10, 10);
  PrintDefault('Part of Posit-92 game engine', 10, 20);

  PrintDefault('< ' + GetDemoName(actualDemo) + ' >', 10, 40);

  PrintDefault('ESC - exit demo', 10, VGAHeight - fontRegular.lineHeight * 2);
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

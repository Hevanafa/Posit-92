{
  Game Launcher demo
  Part of Posit-92 game engine

  Doesn't really serve games
}


uses
  CRT, DOS,
  P92CORE, P92CONV, P92FPS, P92GRAPH, P92LOG, P92MOUSE,
  P92TIME, P92VGA, P92TEX, P92BMFON, P92MATHS;

var
  { Asset variables }
  texLogo, texArrows, texEnter, texPreview: TTexture;
  fontP92Sans: TBMFont;

  { Game state variables }
  startTime, nextGameTick, t: double;
  loops: word;
  menuItems: array [0..49] of string;
  menuCount: integer;
  firstIdx, selectedIdx: integer;


function Format2Digits(const value: integer): string;
begin
  if value < 10 then
    format2Digits := '0' + i32str(value)
  else
    format2Digits := i32str(value);
end;

function GetClockStr: string;
var
  t: longint;
  h, m, s: word;
  tempStr, result: string;
begin
  t := trunc(timer) mod (24 * 3600);
  h := t div 3600;
  m := t mod 3600 div 60;
  s := t mod 60;

  getClockStr := i32str(h) +
    ':' + format2Digits(m) +
    ':' + format2Digits(s);
end;


procedure PrintOutline(const txt: string; const x, y: integer; const colour, outline: byte);
begin
  PrintBMFontTint(fontP92Sans, txt, x-1, y, outline);
  PrintBMFontTint(fontP92Sans, txt, x+1, y, outline);
  PrintBMFontTint(fontP92Sans, txt, x, y-1, outline);
  PrintBMFontTint(fontP92Sans, txt, x, y+1, outline);
  PrintBMFont(fontP92Sans, txt, x, y)
end;


procedure OnPreload; far;
begin
  LoadBMFont(fontP92Sans, 'FONTS\P92SANS.TXT');

  LoadTex(texLogo, 'IMG\LOGO.BMP');
  LoadTex(texArrows, 'IMG\ARROWS.BMP');
  LoadTex(texEnter, 'IMG\ENTER.BMP');
  LoadTex(texPreview, 'IMG\EXAMPLE.BMP');
end;

procedure OnCleanup; far;
begin
  FreeTex(texLogo);
  FreeTex(texArrows);
  FreeTex(texEnter);
  FreeTex(texPreview);

  FreeBMFont(fontP92Sans);
end;

procedure OnReady; far;
var
  a: word;
begin
  startTime := getTimer;

  selectedIdx := 0;
  firstIdx := -2;
  menuCount := 30;

  for a:=0 to menuCount-1 do
    menuItems[a] := 'Menu item ' + i32str(a);
end;


procedure DrawMenuBox;
var
  s: string;
  a, w, maxDisplayed: integer;
begin
  rectfillDither(8, 32, 144, 184, 196);
  rect(8, 32, 144, 184, 15);

  { Menu box }
  maxDisplayed := trunc(min(12, menuCount));

  for a:=0 to maxDisplayed - 1 do begin
    if (0 <= firstIdx + a) and
      (firstIdx + a < firstIdx + maxDisplayed) and
      (firstIdx + a < menuCount) then begin
      s := menuItems[firstIdx + a];

      if selectedIdx = firstIdx + a then begin
        rectfill(9, 33 + a * 12, 142, 33 + (a+1) * 12, 127);
        PrintBMFont(fontP92Sans, s, 13, 33 + a * 12)
      end else
        PrintBMFont(fontP92Sans, s, 13, 33 + a * 12);
    end;
  end;

  s := i32str(1 + selectedIdx) + ' / ' + i32str(menuCount);
  w := MeasureBMFont(fontP92Sans, s);
  PrintBMFont(fontP92Sans, s, 138 - w, 172);
end;

procedure DrawDescriptionBox;
begin
  { Desc box }
  rectfillDither(152, 134, 311, 197, 196);
  rect(152, 134, 311, 197, 15);

  { TODO: Update with the actual content }

  PrintBMFont(fontP92Sans, 'Author: Hevanafa', 155, 137);
  PrintBMFont(fontP92Sans, 'Lorem Ipsum will uncover many', 155, 157);
  PrintBMFont(fontP92Sans, 'web sites still in their infancy.', 155, 169);
  PrintBMFont(fontP92Sans, 'Various versions have evolved', 155, 181);
end;


procedure Update; far;
var
  ch: char;
  relativeIdx: integer;
begin
  if keyPressed then begin
    ch := readKey;

    case ord(ch) of
      0: begin
        ch := readKey;  { read extended code }
        case ord(ch) of
          72: begin
            dec(selectedIdx);
            { AdlibDrv.startMelody; }
          end;
          80: begin
            inc(selectedIdx);
            { AdlibDrv.startMelody; }
          end;
        end;

        { Optional: Handle page up/down keys }

        { Handle wrapping }
        if selectedIdx < 0 then
          selectedIdx := menuCount - 1;
        if selectedIdx >= menuCount then
          selectedIdx := 0;

        { Handle scroll }
        relativeIdx := selectedIdx - firstIdx;

        if relativeIdx >= 9 then firstIdx := selectedIdx - 9;
        if relativeIdx < 2  then firstIdx := selectedIdx - 2;
      end;
      27: SignalDone;
    end;
  end;
end;


procedure Draw; far;
var
  s: string;
  w: integer;
begin
  cls($00);

  { TODO: Background }

  DrawMenuBox;
  DrawDescriptionBox;

  PrintOutline(menuItems[selectedIdx], 152, 119, 15, 0);

  { Header }
  spr(texLogo, 8, 4);
  spr(texPreview, 152, 32);

  s := getClockStr;

  w := MeasureBMFont(fontP92Sans, s);
  PrintBMFont(fontP92Sans, s, 320-8-w, 10);

  { Footer }
  spr(texArrows, 8, 187);
  PrintBMFont(fontP92Sans, 'NAVIGATE', 24, 185);
  spr(texEnter, 90, 187);
  PrintBMFont(fontP92Sans, 'OPEN', 107, 185);
end;


var
  appConfig: TP92AppConfig;
begin
  DefaultP92AppConfig(appConfig);

  appConfig.EnableKeyHandler := false;

  @appConfig.OnPreload := @OnPreload;
  @appConfig.OnReady := @OnReady;
  @appConfig.Update := @Update;
  @appConfig.Draw := @Draw;
  @appConfig.OnCleanup := @OnCleanup;

  P92Start(appConfig)
end.


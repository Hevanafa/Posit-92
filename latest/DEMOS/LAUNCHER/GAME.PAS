
uses
  CRT, DOS,
  P92Core, P92CONV, FPS, Graphics, Logger, P92Mouse,
  Timing, P92VGA, Bitmap, P92BMFON, P92MATHS,
  Bobbing;

var
  { Asset variables }
  imgLogo, imgArrows, imgEnter, imgPreview: PBitmap;
  font: TBMFont;

  { Game state variables }
  startTime, nextGameTick, t: double;
  loops: word;
  menuItems: array [0..49] of string;
  menuCount: integer;
  firstIdx, selectedIdx: integer;


procedure rectfillDither(x0, y0, x1, y1: integer; const colour: byte);
var
  a, b, temp: integer;
begin
  if x0 > x1 then begin
    temp := x0; x0 := x1; x1 := temp
  end;
  if y0 > y1 then begin
    temp := y0; y0 := y1; y1 := temp
  end;

  x0:=trunc(max(x0, 0));   y0:=trunc(max(y0,0));
  x1:=trunc(min(x1, 319)); y1:=trunc(min(y1,199));

  for b:=y0 to y1 do
    for a:=x0 to x1 do
      if (a+b) and 1 = 1 then
        surface^[b*320+a] := colour;
end;


function format2Digits(const value: integer): string;
begin
  if value < 10 then
    format2Digits := '0' + i32str(value)
  else
    format2Digits := i32str(value);
end;

function getClockStr: string;
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


procedure printOutline(const txt: string; const x, y: integer; const colour, outline: byte);
begin
  PrintBMFontTint(@font, txt, x-1, y, outline);
  PrintBMFontTint(@font, txt, x+1, y, outline);
  PrintBMFontTint(@font, txt, x, y-1, outline);
  PrintBMFontTint(@font, txt, x, y+1, outline);
  PrintBMFont(@font, txt, x, y)
end;


procedure OnPreload; far;
var
  a: integer;
begin
  loadBMP(imgLogo, 'IMG\LOGO.BMP');
  loadBMP(imgArrows, 'IMG\ARROWS.BMP');
  loadBMP(imgEnter, 'IMG\ENTER.BMP');
  loadBMP(imgPreview, 'IMG\EXAMPLE.BMP');

  DefaultBMFont(font);
  LoadBMFont(font, 'FONTS\ARIAL10.FNT');
end;

procedure OnCleanup; far;
begin
  freeBMFont(font);
  freeBMP(imgLogo);
  freeBMP(imgArrows);
  freeBMP(imgEnter);
  freeBMP(imgPreview);
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


procedure drawMenuBox;
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
        PrintBMFont(@font, s, 13, 33 + a * 12)
      end else
        PrintBMFont(@font, s, 13, 33 + a * 12);
    end;
  end;

  s := i32str(1 + selectedIdx) + ' / ' + i32str(menuCount);
  w := MeasureBMFont(@font, s);
  PrintBMFont(@font, s, 138 - w, 172);
end;

procedure drawDescriptionBox;
begin
  { Desc box }
  rectfillDither(152, 134, 311, 197, 196);
  rect(152, 134, 311, 197, 15);

  { TODO: Update with the actual content }

  PrintBMFont(@font, 'Author: Hevanafa', 155, 137);
  PrintBMFont(@font, 'Lorem Ipsum will uncover many', 155, 157);
  PrintBMFont(@font, 'web sites still in their infancy.', 155, 169);
  PrintBMFont(@font, 'Various versions have evolved', 155, 181);
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

  { BG }
  { DrawBobbingGrid((getTimer - startTime) * 3); }

  drawMenuBox;
  drawDescriptionBox;

  printOutline(menuItems[selectedIdx], 152, 119, 15, 0);

  { Header }
  spr(imgLogo, 8, 4);
  spr(imgPreview, 152, 32);

  s := getClockStr;

  w := MeasureBMFont(@font, s);
  PrintBMFont(@font, s, 320-8-w, 10);

  { Footer }
  spr(imgArrows, 8, 187);
  PrintBMFont(@font, 'NAVIGATE', 24, 185);
  spr(imgEnter, 90, 187);
  PrintBMFont(@font, 'OPEN', 107, 185);
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


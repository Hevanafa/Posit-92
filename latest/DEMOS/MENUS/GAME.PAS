
uses
  CRT, DOS,
  P92Core, AdLib, Conv, FPS, Logger, Maths, Mouse, Timing, VGA,
  Bitmap, BMFont, Graphics;

var
  { Asset variables }
  font: PBMFont;

  { Game state variables }
  t: double;
  menuItems: array[0..99] of string;
  menuCount: integer;
  selectedIdx, firstIdx: integer;


procedure OnPreload; far;
begin
  LoadBMFont(font, 'FONTS\ARIAL10.FNT');
end;

procedure OnCleanup; far;
begin
  FreeBMFont(font);
end;

procedure OnReady; far;
var
  a: integer;
begin
  selectedIdx := 0;
  firstIdx := -2;
  menuCount := 100;

  for a:=0 to 99 do
    menuItems[a] := 'Menu item ' + i32str(a);
end;


procedure Update; far;
var
  a, relativeIdx: integer;
  ch: char;
begin
  { if isKeyDown(K_ESC) then done := true; }
  if KeyPressed then begin
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

  t := t + DeltaTime;
end;


procedure PrintOutline(const txt: string; const x, y: integer; const colour, outline: byte);
begin
  printBMFont(font, txt, x-1, y, outline);
  printBMFont(font, txt, x+1, y, outline);
  printBMFont(font, txt, x, y-1, outline);
  printBMFont(font, txt, x, y+1, outline);
  printBMFont(font, txt, x, y, colour);
end;


procedure Draw; far;
var
  a, w: integer;
  s: string;
  maxDisplayed: integer;
begin
  cls($01);

  rectfillDither(8, 32, 144, 184, 196);
  rect(8, 32, 144, 184, 15);

  PrintOutline(menuItems[selectedIdx], 152, 119, 15, 0);

  { Menu box }
  maxDisplayed := trunc(min(12, menuCount));

  for a:=0 to maxDisplayed - 1 do begin
    if (0 <= firstIdx + a) and
      (firstIdx + a < firstIdx + maxDisplayed) and
      (firstIdx + a < menuCount) then begin
      s := menuItems[firstIdx + a];

      if selectedIdx = firstIdx + a then begin
        rectfill(9, 33 + a * 12, 142, 33 + (a+1) * 12, 127);
        printBMFont(font, s, 13, 33 + a * 12, 11)
      end else
        printBMFont(font, s, 13, 33 + a * 12, 7);
    end;
  end;

  s := i32str(1 + selectedIdx) + ' / ' + i32str(menuCount);
  w := measureBMFont(font, s);
  printBMFont(font, s, 138 - w, 172, 7);

  { Desc box }
  rectfillDither(152, 134, 311, 197, 196);
  rect(152, 134, 311, 197, 15);

  printBMFont(font, 'Author: Hevanafa', 155, 137, 15);
  printBMFont(font, 'Lorem Ipsum will uncover many', 155, 157, 15);
  printBMFont(font, 'web sites still in their infancy.', 155, 169, 15);
  printBMFont(font, 'Various versions have evolved', 155, 181, 15);
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


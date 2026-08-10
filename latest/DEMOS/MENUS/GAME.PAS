
uses
  CRT, DOS,
  P92Core, Conv, FPS, Maths, Timing, P92VGA, P92Mouse, P92TEX, BMFont, P92STR, Graphics;

const
  MenuCount = 50;
var
  { Asset variables }
  font, outlineFont: TBMFont;

  { Game state variables }
  t: double;
  menuItems: array[0..MenuCount - 1] of string;
  selectedIdx, firstIdx: integer;


procedure OnPreload; far;
var
  a: word;
begin
  LoadBMFont(font, 'FONTS\DROID11.TXT');
  LoadBMFont(outlineFont, 'FONTS\DROID11.TXT');

  { Replace white pixels with black }
  for a:=0 to outlineFont.texture.width * outlineFont.texture.height - 1 do
    if outlineFont.texture.data^[a] = 15 then
      outlineFont.texture.data^[a] := 0;
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

  for a:=0 to high(menuItems) do
    menuItems[a] := 'Menu item ' + upper(I8HexStr(a));
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
  PrintBMFont(outlineFont, txt, x-1, y);
  PrintBMFont(outlineFont, txt, x+1, y);
  PrintBMFont(outlineFont, txt, x, y-1);
  PrintBMFont(outlineFont, txt, x, y+1);
  PrintBMFont(font, txt, x, y);
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
        PrintBMFont(font, s, 13, 33 + a * 12)
      end else
        PrintBMFont(font, s, 13, 33 + a * 12);
    end;
  end;

  s := i32str(1 + selectedIdx) + ' / ' + i32str(menuCount);
  w := measureBMFont(font, s);
  PrintBMFont(font, s, 138 - w, 172);

  { Desc box }
  rectfillDither(152, 134, 311, 197, 196);
  rect(152, 134, 311, 197, 15);

  PrintBMFont(font, 'Author: Hevanafa', 155, 137);
  PrintBMFont(font, 'Lorem Ipsum will uncover many', 155, 157);
  PrintBMFont(font, 'web sites still in their infancy.', 155, 169);
  PrintBMFont(font, 'Various versions have evolved', 155, 181);
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


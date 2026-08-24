program Game;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

uses
  CRT, DOS,
  P92Core, Logger, Conv, Graphics, BMFont, P92STR, P92TEX, Timing, P92VGA,
  P92KBD, P92Mouse;

const
  PaletteTop = 32;
  PaletteLeft = 12;

var
  { Asset variables }
  P92Sans: TBMFont;
  SpecimenP92: array[0..1] of TTexture;

  { Game state variables }
  hoverRow, hoverCol: integer;
  selectedRow, selectedCol: integer;
  selectedR, selectedG, selectedB: byte;

  lastMouseLeft: boolean;
  t: double;


procedure PrintDefault(const text: string; const x, y: integer);
begin
  PrintBMFont(P92Sans, text, x, y)
end;

{ r, g, b: 0..255, not the original mapping of 0..63 }
procedure GetVGAColour(const index: byte; var r, g, b: byte);
begin
  port[$3C7] := index;
  r := port[$3C9]; r := (r shl 2) or (r shr 4);
  g := port[$3C9]; g := (g shl 2) or (g shr 4);
  b := port[$3C9]; b := (b shl 2) or (b shr 4);
end;


procedure OnPreload; far;
begin
  LoadBMFont(P92Sans, 'FONTS\P92SANS.TXT');
  LoadTex(SpecimenP92[0], 'IMG/SPP92_1.BMP');
  LoadTex(SpecimenP92[1], 'IMG/SPP92_2.BMP');
end;

procedure OnCleanup; far;
begin
  FreeBMFont(P92Sans);
  FreeTex(SpecimenP92[0]);
  FreeTex(SpecimenP92[1]);
end;

procedure OnReady; far;
begin
  { Init game state variables here }
  t := 0.0;

  hoverRow := -1;
  hoverCol := -1;
  selectedRow := -1;
  selectedCol := -1;
end;


procedure UpdateHovered;
var
  row, col: integer;
begin
  if mouseX < PaletteLeft then
    hoverCol := -1
  else begin
    col := (mouseX - PaletteLeft) div 8;

    if col <= 15 then
      hoverCol := col
    else
      hoverCol := -1;
  end;

  if mouseY < PaletteTop then
    hoverRow := -1
  else begin
    row := (mouseY - PaletteTop) div 8;

    if row <= 15 then
      hoverRow := row
    else
      hoverRow := -1;
  end;
end;

procedure Update; far;
begin
  if IsKeyDown(SC_ESCAPE) then SignalDone;

  { Handle game state updates here }

  UpdateHovered;

  if lastMouseLeft <> ((mouseButton and MouseButtonLeft) <> 0) then begin
    lastMouseLeft := ((mouseButton and MouseButtonLeft) <> 0);

    if lastMouseLeft then begin
      selectedRow := hoverRow;
      selectedCol := hoverCol;

      if (selectedRow <> -1) and (selectedCol <> -1) then
        GetVGAColour(
          selectedRow * 16 + selectedCol,
          selectedR, selectedG, selectedB);
    end;
  end;

  t := t + DeltaTime
end;

procedure Draw; far;
var
  now: double;
  row, col: integer;
  top, right, bottom, left: integer;
  idx: integer;
begin
  now := GetTimer;

  Cls($4F);

  PrintDefault('Mode 13h Palette', 12, 8);

  if frac(t * 1.5) >= 0.5 then
    Spr(SpecimenP92[0], 148, 76)
  else
    Spr(SpecimenP92[1], 148, 76);

  for row:=0 to 15 do begin
    top := PaletteTop + row * 8;
    bottom := PaletteTop + (row + 1) * 8 - 1;

    for col:=0 to 15 do begin
      left := PaletteLeft + col * 8;
      right := PaletteLeft + (col + 1) * 8 - 1;

      rectfill(
        left, top, right, bottom,
        row * 16 + col);

      if (hoverRow = row) and (hoverCol = col) then begin
        if (trunc(frac(now) * 4) and 1 > 0) then
          Rect(left, top, right, bottom, $0F)
        else
          Rect(left, top, right, bottom, $00);
      end;

      if (selectedRow = row) and (selectedCol = col) then begin
        if (trunc(frac(now) * 4) and 1 > 0) then
          Rect(left, top, right, bottom, $00)
        else
          Rect(left, top, right, bottom, $0F);
      end;
    end;
  end;

  { PrintDefault('Row: ' + I32Str(hoverRow), 160, 120);
  PrintDefault('Col: ' + I32Str(hoverCol), 160, 136); }

  if (hoverRow <> -1) and (hoverCol <> -1) then begin
    idx := hoverRow * 16 + hoverCol;
    PrintDefault('Index: ' + I32Str(idx) + ' ($' + I8HexStr(idx) + ')', 160, 100);
  end;

  if (selectedRow <> -1) and (selectedCol <> -1) then begin
    idx := selectedRow * 16 + selectedCol;

    PrintDefault('Selection', 160, 120);

    PrintDefault(
      'Index: ' + I32Str(idx) + ' ($' + I8HexStr(idx) + ')',
      160, 120 + P92Sans.lineHeight);

    { TODO: output G and B }
    PrintDefault('R=' + I32Str(selectedR), 160, 120 + P92Sans.lineHeight * 2);
  end
  else begin
    PrintDefault('Click any colour', 160, 64);
    PrintDefault('on the palette to inspect', 160, 64 + P92Sans.lineHeight);
  end;
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

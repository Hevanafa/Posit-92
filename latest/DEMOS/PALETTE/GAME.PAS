program Game;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

uses
  CRT, DOS,
  P92Core, Logger, Conv, Graphics, BMFont, P92STR, P92TEX, Timing, P92VGA,
  P92KBD, P92Mouse;

const
  PaletteTop = 20;
  PaletteLeft = 12;

var
  { Asset variables }
  P92Sans: TBMFont;
  SpecimenP92: array[0..1] of TTexture;

  { Game state variables }
  hoverRow, hoverCol: integer;
  t: double;


procedure PrintDefault(const text: string; const x, y: integer);
begin
  PrintBMFont(P92Sans, text, x, y)
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
end;


procedure UpdateSelection;
var
  row, col: integer;
begin
  col := (mouseX - PaletteLeft) div 8;
  row := (mouseY - PaletteTop) div 8;

  hoverCol := col;
  hoverRow := row;
end;

procedure Update; far;
begin
  if IsKeyDown(SC_ESCAPE) then SignalDone;

  { Handle game state updates here }

  UpdateSelection;

  t := t + DeltaTime
end;

procedure Draw; far;
var
  row, col: integer;
begin
  Cls($4F);

  PrintDefault('Mode 13h Palette', 12, 8);

  if frac(t * 1.5) >= 0.5 then
    Spr(SpecimenP92[0], 148, 76)
  else
    Spr(SpecimenP92[1], 148, 76);

  for row:=0 to 15 do begin
    for col:=0 to 15 do begin
      rectfill(
        PaletteLeft + col * 8,
        PaletteTop + row * 8,
        PaletteLeft + (col + 1) * 8 -1,
        PaletteTop + (row + 1) * 8 -1,
        row * 16 + col)
    end;
  end;

  PrintDefault('Row: ' + I32Str(hoverRow), 160, 120);
  PrintDefault('Col: ' + I32Str(hoverCol), 160, 136);
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

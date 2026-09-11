program Game;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

uses
  CRT, DOS,
  P92CORE, P92CONV, P92KBD, P92MOUSE, P92TEX, P92TIME, P92VGA;

type
  TTileState = (
    TileStateClose,
    TileStateOpen
  );

const
  BoardCols = 9;
  BoardRows = 9;

var
  { Asset variables }
  texSpecimenP92: array[0..1] of TTexture;
  texOpenTile, texCloseTile, texPressedTile: TTexture;
  texFlag, texMine: TTexture;

  { Game state variables }
  gameTime: double;

  mineNumbers: array[0..80] of byte;
  mines: array[0..80] of boolean;
  tileStates: array[0..80] of TTileState;


function GetTileMine(const row, col: integer): boolean;
begin
  GetTileMine := false;

  if (row < 0) or (row >= BoardRows) or (col < 0) or (col >= BoardCols) then exit;

  GetTileMine := mines[row * BoardCols + col]
end;

{ Load assets here }
procedure OnPreload; far;
begin
  LoadTex(texSpecimenP92[0], 'IMG\SPP92_1.BMP');
  LoadTex(texSpecimenP92[1], 'IMG\SPP92_2.BMP');

  LoadTex(texOpenTile, 'IMG\OPEN.BMP');
  LoadTex(texCloseTile, 'IMG\CLOSE.BMP');
  LoadTex(texPressedTile, 'IMG\PRESSED.BMP');

  LoadTex(texFlag, 'IMG\FLAG.BMP');
  LoadTex(texMine, 'IMG\MINE.BMP');
end;

{ Free all the resources here }
procedure OnCleanup; far;
begin
  FreeTex(texSpecimenP92[0]);
  FreeTex(texSpecimenP92[1]);
end;

{ Init game state variables here }
procedure OnReady; far;
var
  a, b: integer;
  c, d: integer;
  count: integer;
  idx: word;
begin
  gameTime := 0.0;

  RandSeed := 255;

  fillchar(mineNumbers, sizeof(mineNumbers), 0);
  FillChar(mines, sizeof(mines), 0);
  FillChar(tileStates, sizeof(tileStates), TileStateOpen);

  for a:=1 to 10 do
    mines[random(10) * 9 + random(10)] := true;

  for b:=0 to BoardRows - 1 do
    for a:=0 to BoardCols - 1 do begin
      count := 0;

      for d:=-1 to 1 do
        for c:=-1 to 1 do begin
          if (c=0) and (d=0) then continue;

          if GetTileMine(b + d, c + a) then
            inc(count);
        end;

      mineNumbers[b * BoardCols + a] := count;
    end;
end;

{ Handle game state updates here }
procedure Update; far;
begin
  if IsKeyDown(SC_ESCAPE) then SignalDone;

  gameTime := gameTime + DeltaTime
end;

{ Render logic }
procedure Draw; far;
var
  s: string;
  idx: integer;
  a, b: word;
  x, y: integer;
begin
  Cls($4F);

  if frac(gameTime * 1.5) >= 0.5 then
    Spr(texSpecimenP92[0], 148, 76)
  else
    Spr(texSpecimenP92[1], 148, 76);

  Print('Hello world!', 160-48, 120, 15);

  for b:=0 to BoardRows - 1 do
    for a:=0 to BoardCols - 1 do begin
      idx := b * BoardCols + a;

      x := 10 + a * 9;
      y := 10 + b * 9;

      case tileStates[idx] of
        TileStateClose:
          spr(texCloseTile, x, y);
        TileStateOpen: begin
          spr(texOpenTile, x, y);

          if mines[idx] then
            spr(texMine, x, y)
          else
            if mineNumbers[idx] > 0 then
              print(i32str(mineNumbers[idx]), x + 1, y, $0F);
        end;
      end;
    end;

  s := 'Seed: ' + i32str(RandSeed);
  print(s, VGAWidth - length(s) * 8, VGAHeight - 8, $08)
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

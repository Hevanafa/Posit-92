program Game;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

uses
  CRT, DOS,
  P92CORE, P92CONV, P92KBD, P92MOUSE, P92TEX, P92TIME, P92VGA;

type
  TGameState = (
    GameStateNotStarted,
    GameStatePlaying,
    GameStateOver
  );
  TTileState = (
    TileStateClose,
    TileStateOpen
  );

const
  BoardCols = 9;
  BoardRows = 9;
  StartingMineCount = 10;

  BoardTop = 30;
  BoardLeft = 10;

var
  { Asset variables }
  texSpecimenP92: array[0..1] of TTexture;
  texOpenTile, texCloseTile, texPressedTile: TTexture;
  texFlag, texMine: TTexture;

  { Game state variables }
  actualGameState: TGameState;
  gameTime: double;

  lastLeftMouse: boolean;
  mineCounter: integer;
  mineNumbers: array[0..80] of byte;
  mines: array[0..80] of boolean;
  tileStates: array[0..80] of TTileState;


function GetTileMine(const row, col: integer): boolean;
begin
  GetTileMine := false;

  if (row < 0) or (row >= BoardRows) or (col < 0) or (col >= BoardCols) then exit;

  GetTileMine := mines[row * BoardCols + col]
end;

function GetMineNumberColour(const count: integer): integer;
var
  result: integer;
begin
  case count of
    1: result := $09;
    2: result := $0A;
    3: result := $0C;
    4: result := $05;
    5: result := $04;
    6: result := $03;
    7: result := $00;
    8: result := $07;
    else
      result := $00;
  end;

  GetMineNumberColour := result
end;


procedure RevealAllMines;
var
  a, b: integer;
  idx: integer;
begin
  for b:=0 to BoardRows - 1 do
    for a:=0 to BoardCols - 1 do begin
      idx := b * BoardCols + a;

      if mines[idx] then
        tileStates[idx] := TileStateOpen;
    end;
end;

procedure FloodFill(const row, col: integer);
var
  idx: integer;
  a, b: integer;
begin
  if (row < 0) or (row >= BoardRows)
    or (col < 0) or (col >= BoardCols) then exit;

  idx := row * BoardCols + col;

  if tileStates[idx] <> TileStateClose then exit;

  { Assign then take a step }
  tileStates[idx] := TileStateOpen;

  if mineNumbers[idx] > 0 then exit;

  for b:=-1 to 1 do
    for a:=-1 to 1 do begin
      if (b=0) and (a=0) then continue;

      FloodFill(row + b, col + a);
    end;
end;

procedure AttemptReveal(const row, col: integer);
var
  idx: integer;
begin
  if actualGameState = GameStateOver then exit;

  if (row < 0) or (row >= BoardRows)
    or (col < 0) or (col >= BoardCols) then exit;

  idx := row * BoardCols + col;

  if tileStates[idx] = TileStateOpen then exit;

  if mines[idx] then begin
    actualGameState := GameStateOver;
    RevealAllMines;
    exit
  end;

  if mineNumbers[idx] > 0 then
    tileStates[idx] := TileStateOpen
  else
    FloodFill(row, col);
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
  actualGameState := GameStateNotStarted;
  gameTime := 0.0;

  lastLeftMouse := false;
  RandSeed := 255;

  FillChar(mineNumbers, sizeof(mineNumbers), 0);
  FillChar(mines, sizeof(mines), 0);
  FillChar(tileStates, sizeof(tileStates), TileStateClose);

  for a:=1 to StartingMineCount do
    mines[random(10) * 9 + random(10)] := true;

  mineCounter := StartingMineCount;

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
var
  isLeftMousePressed: boolean;
  row, col: integer;
  idx: integer;
begin
  if IsKeyDown(SC_ESCAPE) then SignalDone;

  isLeftMousePressed := (GetMouseButton and MouseButtonLeft <> 0);

  if lastLeftMouse <> isLeftMousePressed then begin
    lastLeftMouse := isLeftMousePressed;

    if lastLeftMouse then begin
      row := (GetMouseY - BoardTop) div 9;
      col := (GetMouseX - BoardLeft) div 9;

      AttemptReveal(row, col);
    end;
  end;

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

  for b:=0 to BoardRows - 1 do begin
    y := BoardTop + b * 9;

    for a:=0 to BoardCols - 1 do begin
      idx := b * BoardCols + a;

      x := BoardLeft + a * 9;

      case tileStates[idx] of
        TileStateClose:
          spr(texCloseTile, x, y);
        TileStateOpen: begin
          spr(texOpenTile, x, y);

          if mines[idx] then
            spr(texMine, x, y)
          else
            if mineNumbers[idx] > 0 then
              print(i32str(mineNumbers[idx]), x + 1, y, GetMineNumberColour(mineNumbers[idx]));
        end;
      end;
    end;
  end;

  print('Mines: ' + I32Str(mineCounter), 10, 10, $0F);

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

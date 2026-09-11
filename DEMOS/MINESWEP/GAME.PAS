program Game;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

uses
  CRT, DOS,
  P92CORE, P92CONV, P92KBD, P92MOUSE, P92TEX, P92TIME, P92VGA;

type
  TGameState = (
    GameStateNotStarted,
    GameStatePlaying,
    GameStateLose,
    GameStateWin
  );

  TTileState = (
    TileStateClose,
    TileStateOpen,
    TileStateFlagged
  );

  TTile = record
    hasMine: boolean;
    mineNumber: byte;
    tileState: TTileState;
  end;

const
  BoardCols = 9;
  BoardRows = 9;
  StartingMineCount = 10;

  BoardTop = 60;
  BoardLeft = 60;

var
  { Asset variables }
  texSpecimenP92: array[0..1] of TTexture;
  texOpenTile, texCloseTile, texPressedTile: TTexture;
  texFlag, texMine: TTexture;

  { Game state variables }
  actualGameState: TGameState;
  gameTime: double;

  lastLeftMouse, lastRightMouse: boolean;
  mineCounter: integer;
  tiles: array[0..BoardRows * BoardCols] of TTile;


function IsGameOver: boolean;
begin
  IsGameOver := (actualGameState = GameStateWin) or (actualGameState = GameStateLose)
end;

function GetTileMine(const row, col: integer): boolean;
begin
  GetTileMine := false;

  if (row < 0) or (row >= BoardRows) or (col < 0) or (col >= BoardCols) then exit;

  GetTileMine := tiles[row * BoardCols + col].hasMine;
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

function GetMouseRow: integer;
var
  y: integer;
begin
  y := GetMouseY - BoardTop;

  if (y < 0) or (y >= BoardRows * 9) then begin
    GetMouseRow := -1;
    exit
  end;

  GetMouseRow := y div 9;
end;

function GetMouseCol: integer;
var
  x: integer;
begin
  x := GetMouseX - BoardLeft;

  if (x < 0) or (x >= BoardCols * 9) then begin
    GetMouseCol := -1;
    exit
  end;

  GetMouseCol := x div 9;
end;

function GetOpenTileCount: integer;
var
  result: integer;
  a, b: word;
begin
  result := 0;

  for b:=0 to BoardRows - 1 do
    for a:=0 to BoardCols - 1 do
      if tiles[b * BoardCols + a].tileState = TileStateOpen then
        inc(result);

  GetOpenTileCount := result
end;

procedure RevealAllMines;
var
  a, b: integer;
  idx: integer;
begin
  for b:=0 to BoardRows - 1 do
    for a:=0 to BoardCols - 1 do begin
      idx := b * BoardCols + a;

      if tiles[idx].hasMine then
        tiles[idx].tileState := TileStateOpen;
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

  if tiles[idx].tileState <> TileStateClose then exit;

  { Assign then take a step }
  tiles[idx].tileState := TileStateOpen;

  if tiles[idx].mineNumber > 0 then exit;

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
  if IsGameOver then exit;

  if (row < 0) or (row >= BoardRows)
    or (col < 0) or (col >= BoardCols) then exit;

  idx := row * BoardCols + col;

  if tiles[idx].tileState <> TileStateClose then exit;

  if tiles[idx].hasMine then begin
    actualGameState := GameStateLose;
    RevealAllMines;
    exit
  end;

  if tiles[idx].mineNumber > 0 then
    tiles[idx].tileState := TileStateOpen
  else
    FloodFill(row, col);

  if GetOpenTileCount = BoardRows * BoardCols - StartingMineCount then
    actualGameState := GameStateWin;
end;

procedure AttemptFlag(const row, col: integer);
var
  idx: integer;
begin
  if IsGameOver then exit;

  if (row < 0) or (row >= BoardRows)
    or (col < 0) or (col >= BoardCols) then exit;

  idx := row * BoardCols + col;

  if tiles[idx].tileState = TileStateOpen then exit;

  case tiles[idx].tileState of
    TileStateClose: begin
      tiles[idx].tileState := TileStateFlagged;
      dec(mineCounter);
    end;

    TileStateFlagged: begin
      tiles[idx].tileState := TileStateClose;
      inc(mineCounter);
    end;
  end;
end;

procedure InitBoard(const seed: longint);
var
  a, b: integer;
  c, d: integer;
  count: integer;
  idx: word;
begin
  RandSeed := seed;
  actualGameState := GameStateNotStarted;
  gameTime := 0.0;

  lastLeftMouse := false;
  lastRightMouse := false;

  RandSeed := 255;

  FillChar(tiles, sizeof(tiles), 0);

  for a:=1 to StartingMineCount do
    tiles[random(10) * 9 + random(10)].hasMine := true;

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

      tiles[b * BoardCols + a].mineNumber := count;
    end;
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
begin
  InitBoard(255);
end;

{ Handle game state updates here }
procedure Update; far;
var
  isLeftMousePressed: boolean;
  isRightMousePressed: boolean;
  row, col: integer;
  idx: integer;
begin
  if IsKeyDown(SC_ESCAPE) then SignalDone;

  isLeftMousePressed := (GetMouseButton and MouseButtonLeft <> 0);
  isRightMousePressed := (GetMouseButton and MouseButtonRight <> 0);

  if lastLeftMouse <> isLeftMousePressed then begin
    lastLeftMouse := isLeftMousePressed;

    if not lastLeftMouse then
      AttemptReveal(GetMouseRow, GetMouseCol);
  end;

  if lastRightMouse <> isRightMousePressed then begin
    lastRightMouse := isRightMousePressed;

    if lastRightMouse then
      AttemptFlag(GetMouseRow, GetMouseCol);
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

      case tiles[idx].tileState of
        TileStateClose:
          spr(texCloseTile, x, y);

        TileStateOpen: begin
          spr(texOpenTile, x, y);

          if tiles[idx].hasMine then
            spr(texMine, x, y)
          else
            if tiles[idx].mineNumber > 0 then
              print(
                i32str(tiles[idx].mineNumber),
                x + 1, y,
                GetMineNumberColour(tiles[idx].mineNumber));
        end;

        TileStateFlagged: begin
          spr(texCloseTile, x, y);
          spr(texFlag, x, y);
        end;
      end;
    end;
  end;

  if actualGameState = GameStateWin then
    print('You win!', 80, 10, $0F)
  else if actualGameState = GameStateLose then
    print('You lose!', 80, 10, $0F)
  else
    print('Mines: ' + I32Str(mineCounter), 80, 10, $0F);

  { Debug row & col }
  { print('Row: ' + i32str(GetMouseRow) + ', Col: ' + I32Str(GetMouseCol), 10, 30, $0F); }

  s := 'Seed: ' + i32str(RandSeed);
  print(s, VGAWidth - length(s) * 8 - 8, VGAHeight - 16, $08)
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

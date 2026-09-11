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

  tileNumbers: array[0..80] of byte;
  mines: array[0..80] of boolean;
  tileStates: array[0..80] of TTileState;


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
  a: word;
begin
  gameTime := 0.0;

  RandSeed := 255;

  fillchar(tileNumbers, sizeof(tileNumbers), 0);
  FillChar(mines, sizeof(mines), 0);
  FillChar(tileStates, sizeof(tileStates), TileStateClose);

  for a:=1 to 10 do
    mines[random(10) * 9 + random(10)] := true;
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
  a, b: word;
begin
  Cls($4F);

  if frac(gameTime * 1.5) >= 0.5 then
    Spr(texSpecimenP92[0], 148, 76)
  else
    Spr(texSpecimenP92[1], 148, 76);

  Print('Hello world!', 160-48, 120, 15);

  for b:=0 to BoardRows - 1 do
    for a:=0 to BoardCols - 1 do begin
      case tileStates[b * BoardCols + a] of
        TileStateClose:
          spr(texCloseTile, 10 + a * 9, 10 + b * 9);
        TileStateOpen:
          spr(texOpenTile, 10 + a * 9, 10 + b * 9);
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

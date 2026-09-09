program Game;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

uses
  CRT, DOS,
  P92CORE, P92LOG, P92ANIMS, P92KBD, P92MOUSE, P92STR, P92TEX, P92TIME, P92VGA;

var
  { Asset variables }
  texSpecimenP92: array[0..1] of TTexture;
  texSlimeGirl: TTexture;
  animSlimeGirl: TSprAnim;

  { Game state variables }

  gameTime: double;

  { use gameTime }
  startTick: double;
  frameIdx: integer;


{ Load assets here }
procedure OnPreload; far;
begin
  LoadTex(texSpecimenP92[0], 'IMG\SPP92_1.BMP');
  LoadTex(texSpecimenP92[1], 'IMG\SPP92_2.BMP');

  LoadTex(texSlimeGirl, 'IMG\SLIMEGRL.BMP');
end;

{ Free all the resources here }
procedure OnCleanup; far;
begin
  FreeTex(texSpecimenP92[0]);
  FreeTex(texSpecimenP92[1]);

  FreeTex(texSlimeGirl);
end;

{ Init game state variables here }
procedure OnReady; far;
begin
  gameTime := 0.0;

  InitSprAnim(animSlimeGirl, texSlimeGirl, 5, 16, 16, 0.1);
  startTick := gameTime;
  frameIdx := 0;
end;

procedure Update; far;
var
  now: double;
begin
  now := GetTimer;

  { Handle inputs here }
  if IsKeyDown(SC_ESCAPE) then SignalDone;

  { Handle game state updates here }
  UpdateSprAnim(animSlimeGirl, gameTime, startTick, frameIdx);

  gameTime := gameTime + DeltaTime
end;

procedure Draw; far;
begin
  Cls($4F);

  if frac(gameTime * 1.5) >= 0.5 then
    Spr(texSpecimenP92[0], 148, 76)
  else
    Spr(texSpecimenP92[1], 148, 76);

  { spr(texSlimeGirl, 10, 10); }
  DrawSprAnim(animSlimeGirl, 188, 80, frameIdx);

  Print('Hello world!', 160-48, 120, 15);
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

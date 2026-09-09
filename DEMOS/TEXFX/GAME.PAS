program Game;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

uses
  CRT, DOS,
  P92CORE, P92KBD, P92MOUSE, P92TEX, P92TEXFX, P92TIME, P92VGA;

var
  { Asset variables }
  { texDosuEXE: array[0..1] of TTexture; }
  texSpecimenP92: array[0..1] of TTexture;

  { Game state variables }
  gameTime: double;


{ Load assets here }
procedure OnPreload; far;
begin
  LoadTex(texSpecimenP92[0], 'IMG/SPP92_1.BMP');
  LoadTex(texSpecimenP92[1], 'IMG/SPP92_2.BMP');
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
  gameTime := 0.0;
end;

{ Handle game state updates here }
procedure Update; far;
begin
  if IsKeyDown(SC_ESCAPE) then SignalDone;

  gameTime := gameTime + DeltaTime
end;

{ Render logic }
procedure Draw; far;
begin
  Cls($4F);

  if frac(gameTime * 1.5) >= 0.5 then
    Spr(texSpecimenP92[0], 148, 76)
  else
    SprShadow(texSpecimenP92[1], 148, 76, $07);

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

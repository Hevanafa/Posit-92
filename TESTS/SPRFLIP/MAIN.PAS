{
  SprFlipped tests
  Part of Posit-92 game engine

  All the tests here are using DOSBox-X, 20000 cycles per second
}

{$IFDEF FPC}{$MODE TP}{$ENDIF}

uses
  P92CORE, P92TEX, P92CONV, P92GRAPH, P92TIME, P92VGA;

var
  texTabby: TTexture;

procedure OnPreload; far;
begin
  LoadTex(texTabby, 'cat.bmp');
end;

procedure OnCleanup; far;
begin
  FreeTex(texTabby);
end;

procedure DrawOnce; far;
var
  startTick: double;
  a: integer;
  s: string;
begin
{ Singular sprites }
{
  cls($7D);

  spr(texTabby,
    (VGAWidth - texTabby.width) div 2,
    (VGAHeight - texTabby.height) div 2);

  SprFlipped(texTabby, 144, 128, SprFlipHorizontal);
  SprFlipped(texTabby, 176, 128, SprFlipVertical);
  SprFlipped(texTabby, 208, 128, SprFlipBoth);
}

  { Benchmark }
  cls($00);
  startTick := GetTimer;

  for a:=1 to 1000 do begin
    { Original: 2.3945s
      After row-level opt: 1.6550s }
    { SprFlipped(texTabby, random(VGAWidth + 20) - 40, random(VGAHeight + 20) - 40, SprFlipHorizontal); }

    { Original: 2.3968s
      After row-level opt: 1.6557s }
    { SprFlipped(texTabby, random(VGAWidth + 20) - 40, random(VGAHeight + 20) - 40, SprFlipVertical); }

    { Original: 2.6996s
      After row-level opt: 1.9632s }
    SprFlipped(texTabby, random(VGAWidth + 20) - 40, random(VGAHeight + 20) - 40, SprFlipBoth);
  end;

  s := '1000 operations done in ' + F32Str(GetTimer - startTick) + 's';
  rectfill(0, VGAHeight - 16, Length(s) * 8 - 1, VGAHeight - 9, 0);
  Print(s, 0, VGAHeight - 16, $0F)
end;

var
  appConfig: TP92AppConfig;
begin
  DefaultP92AppConfig(appConfig);

  appConfig.EnableKeyHandler := false;
  appConfig.LoadDefaultCursor := false;

  @appConfig.OnPreload := @OnPreload;
  @appConfig.DrawOnce := @DrawOnce;
  @appConfig.OnCleanup := @OnCleanup;

  P92Start(appConfig)
end.

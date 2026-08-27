{
  CGA Print test project
  Part of Posit-92 game engine
}

uses
  P92Core, P92CONV, Graphics, Timing, P92VGA;

procedure DrawOnce; far;
var
  a: word;
  startTick: double;
  s: string;
begin
  cls($00);
  startTick := GetTimer;

  { Original: 1.2273s
    After row-level optimisation: 1.0526s, 0.9419s
    Using base offset: 0.5576s, 0.4929s
    Using col loop with inline assembly: 0.3064s, 0.3087s, 0.2966s }
  for a:=1 to 1000 do
    print('Hello world!', random(VGAWidth + 40) - 20, random(VGAHeight + 40) - 20, $0F);

  { 0.8966s }
  { for a:=1 to 1000 do
    AsmPrint('Hello world!', random(VGAWidth + 40) - 20, random(VGAHeight + 40) - 20, $0F); }

  s := '1000 operations done in ' + F32Str(GetTimer - startTick) + 's';
  RectFill(0, VGAHeight - 16, length(s) * 8, VGAHeight - 8, $00);
  print(s, 0, VGAHeight - 16, $0F);
end;

var
  appConfig: TP92AppConfig;
begin
  DefaultP92AppConfig(appConfig);

  appConfig.LoadDefaultCursor := false;

  { @appConfig.OnPreload := @OnPreload;
  @appConfig.OnReady := @OnReady; }
  { @appConfig.Update := @Update;
  @appConfig.Draw := @Draw; }
  @appConfig.DrawOnce := @DrawOnce;
  { @appConfig.OnCleanup := @OnCleanup; }

  P92Start(appConfig)
end.


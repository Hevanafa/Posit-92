
uses
  CRT, DOS,
  P92Core, BMFont, Logger, Keyboard, Mouse, Timing, VGA, Bitmap,
  Story;

var
  { Asset variables }
  DosuEXE: array[0..1] of PBitmap;
  font: PBMFont;

  { Game state variables }
  t: double;
  lastSpace: boolean;


procedure OnPreload; far;
begin
  loadBMP(dosuEXE[0], 'IMG/DOSU_1.BMP');
  loadBMP(dosuEXE[1], 'IMG/DOSU_2.BMP');
  loadBMFont(font, 'FONTS\FGB12.FNT');
end;

procedure OnCleanup; far;
begin
  freeBMP(dosuEXE[0]);
  freeBMP(dosuEXE[1]);
end;

procedure OnReady; far;
begin
  StoryMan.init(font);
  StoryMan.startPage(1);
  lastSpace := false;
end;

procedure Update; far;
var
  a: integer;
begin
  if isKeyDown(SC_ESCAPE) then SignalDone;

  if StoryMan.isStory then begin
    if lastSpace <> isKeyDown(SC_SPACE) then begin
      lastSpace := isKeyDown(SC_SPACE);
      if lastSpace then
        StoryMan.tryNextPage;
    end;

    StoryMan.update;
  end;

  t:=t + DeltaTime
end;


procedure Draw; far;
var
  a: integer;
begin
  cls($7D);

  StoryMan.draw;
  StoryMan.drawDebug;
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


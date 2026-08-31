
uses
  CRT, DOS,
  P92CORE, P92BMFON, P92LOG, P92KBD, P92MOUSE, P92TIME, P92VGA, P92TEX,
  Story;

var
  { Asset variables }
  texDosuEXE: array[0..1] of TTexture;
  fontP92Sans: TBMFont;
  mgrStory: TStoryManager;

  { Game state variables }
  t: double;
  lastSpace: boolean;
  activePage: word;


procedure InitPage(const pageNum: word);
var
  lines: TQuoteLines;
  lineCount: word;
begin
  activePage := pageNum;

  case pageNum of
    1: begin
      lines[0] := 'Hello world!';
      lineCount := 1;
    end;
    2: begin
      lines[0] := 'This is the second page!';
      lines[1] := 'Second line of the second page!';
      lines[2] := 'Third line of the second page!';
      lineCount := 3;
    end;
    3: begin
      lines[0] := 'This is the third page!';
      lines[1] := 'Second line of the third page!';
      lines[2] := 'Third line of the third page!';
      lineCount := 3;
    end;
    else
      mgrStory.SetIsStory(false);
  end;

  mgrStory.StartPage(lines, lineCount);
end;

procedure OnPreload; far;
begin
  LoadTex(texDosuEXE[0], 'IMG/DOSU_1.BMP');
  LoadTex(texDosuEXE[1], 'IMG/DOSU_2.BMP');

  LoadBMFont(fontP92Sans, 'FONTS\P92SANS.TXT');
end;

procedure OnCleanup; far;
begin
  mgrStory.Done;

  FreeTex(texDosuEXE[0]);
  FreeTex(texDosuEXE[1]);
end;

procedure OnReady; far;
begin
  mgrStory.Init(@fontP92Sans);
  mgrStory.StartPage(1);

  InitPage(1);

  lastSpace := false;
end;

procedure Update; far;
var
  a: integer;
begin
  if isKeyDown(SC_ESCAPE) then SignalDone;

  if mgrStory.isStory then begin
    if lastSpace <> isKeyDown(SC_SPACE) then begin
      lastSpace := isKeyDown(SC_SPACE);
      if lastSpace then
        mgrStory.TryNextPage;
    end;

    mgrStory.Update;
  end;

  t:=t + DeltaTime
end;


procedure Draw; far;
var
  a: integer;
begin
  cls($7D);

  mgrStory.Draw;
  mgrStory.DrawDebug;
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


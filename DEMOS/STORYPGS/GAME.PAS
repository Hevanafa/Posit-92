
uses
  CRT, DOS,
  P92CORE, P92BMFON, P92LOG, P92KBD, P92MOUSE, P92TIME, P92VGA, P92TEX,
  UStory;

var
  { Asset variables }
  texDosuEXE: array[0..1] of TTexture;
  fontP92Sans: TBMFont;
  mgrStory: TStoryManager;

  { Game state variables }
  t: double;
  lastSpace: boolean;

  isStory: boolean;
  activePage: word;

procedure InitPage(const pageNum: word); forward;

procedure NextPage;
begin
  inc(activePage);
  InitPage(activePage)
end;

procedure TryNextPage;
begin
  if mgrStory.IsEndOfPage then
    NextPage
  else
    mgrStory.SkipPage;
end;

procedure InitPage(const pageNum: word);
var
  lines: TQuoteLines;
  lineCount: word;
begin
  activePage := pageNum;

  case pageNum of
    1: begin
      lines[0] := 'The happiness of your life';
      lines[1] := 'depends upon the quality';
      lines[2] := 'of your thoughts';
      lineCount := 3;
    end;
    2: begin
      lines[0] := 'The best revenge is to be';
      lines[1] := 'unlike him who performed the injury';
      lineCount := 2;
    end;
    3: begin
      lines[0] := 'This is the third page!';
      lines[1] := 'Second line of the third page!';
      lines[2] := 'Third line of the third page!';
      lineCount := 3;
    end;
    else
      isStory := false;
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

  InitPage(1);

  isStory := true;

  lastSpace := false;
end;

procedure Update; far;
var
  a: integer;
begin
  if isKeyDown(SC_ESCAPE) then SignalDone;

  if isStory then begin
    if lastSpace <> isKeyDown(SC_SPACE) then begin
      lastSpace := isKeyDown(SC_SPACE);

      if lastSpace then begin
        if mgrStory.IsEndOfPage then
          NextPage
        else
          TryNextPage;
      end;
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

  if isStory then begin
    mgrStory.Draw;
    mgrStory.DrawDebug;
  end else
    Print('Press Esc to exit', 0, VGAHeight - 8, 15);
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



uses
  CRT, DOS,
  P92CORE, P92BMFON, P92LOG, P92KBD, P92MOUSE, P92TIME, P92VGA, P92TEX, P92IMGUI, P92Geom,
  UStory;

var
  { Asset variables }
  mgrStory: TStoryManager;
  fontP92Sans: TBMFont;

  texDosuEXE: array[0..1] of TTexture;
  texMarcus: TTexture;

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

  mgrStory.SetPortrait(nil);
  mgrStory.SetSpeaker('');

  case pageNum of
    1: begin
      lines[0] := 'The happiness of your life';
      lines[1] := 'depends upon the quality';
      lines[2] := 'of your thoughts';
      lineCount := 3;

      mgrStory.SetPortrait(@texMarcus);
      mgrStory.SetSpeaker('Marcus Aurelius');
    end;
    2: begin
      lines[0] := 'The best revenge is to be';
      lines[1] := 'unlike him who performed the injury';
      lineCount := 2;

      mgrStory.SetPortrait(@texMarcus);
      mgrStory.SetSpeaker('Marcus Aurelius');
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


function LabelButton(const caption: string; const x, y, width, height: integer): boolean;
var
  zone: TZone;
  thisWidgetID: integer;
  buttonColour: word;
begin
  zone.x := x;
  zone.y := y;
  zone.width := width;
  zone.height := height;

  { Update logic }
  thisWidgetID := GetNextWidgetID;
  IncNextWidgetID;

  if IsMousePointInZone(zone) then begin
    SetHotWidget(thisWidgetID);

    if mouseJustPressed then
      activeWidget := thisWidgetID;
  end;

  { Render logic }
  if activeWidget = thisWidgetID then
    buttonColour := ButtonPressColour
  else if hotWidget = thisWidgetID then
    buttonColour := ButtonHoverColour
  else
    buttonColour := ButtonIdleColour;

  RectFill(trunc(zone.x), trunc(zone.y), trunc(zone.x + zone.width), trunc(zone.y + zone.height), buttonColour);
  Rect(trunc(zone.x), trunc(zone.y), trunc(zone.x + zone.width), trunc(zone.y + zone.height), ButtonIdleColour);

  UnderlinedLabel(caption, trunc(zone.x + 4), trunc(zone.y + 4));

  if mouseJustReleased and (hotWidget = thisWidgetID) and (activeWidget = thisWidgetID) then
    { activeWidget = -1 }  { Index reset is handled at the end of draw }
    Button := true
  else
    Button := false;
end;


procedure OnPreload; far;
begin
  LoadTex(texDosuEXE[0], 'IMG/DOSU_1.BMP');
  LoadTex(texDosuEXE[1], 'IMG/DOSU_2.BMP');

  LoadBMFont(fontP92Sans, 'FONTS\P92SANS.TXT');

  LoadTex(texMarcus, 'IMG/MARCUS_A.BMP');
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
    { mgrStory.DrawDebug; }

    if mgrStory.IsEndOfPage then begin
      if LabelButton('NEXT >', 100, 100, 64, 32) then
        TryNextPage;
    end;
  end else
    Print('Press Esc to exit', 0, VGAHeight - 8, 15);
end;


var
  appConfig: TP92AppConfig;
begin
  DefaultP92AppConfig(appConfig);

  appConfig.DefaultBMFont := @fontP92Sans;

  @appConfig.OnPreload := @OnPreload;
  @appConfig.OnReady := @OnReady;
  @appConfig.Update := @Update;
  @appConfig.Draw := @Draw;
  @appConfig.OnCleanup := @OnCleanup;

  P92Start(appConfig)
end.


unit Story;

interface

uses BMFont;

type
  TStoryManager = object
    isStory: boolean;
    font: PBMFont;
    procedure startPage(const page: word);
    procedure nextPage;
    procedure tryNextPage;
    procedure init(const fontPtr: PBMFont);
    procedure update;
    procedure draw;
    procedure drawDebug;
  end;

var
  StoryMan: TStoryManager;


implementation

uses Conv, Timing, VGA;

const
  charInterval = 0.016;

var
  lines: array[0..3] of string;
  lineCount: word;
  activePage, storyRow, storyCol: integer;
  elapsed: double;

procedure TStoryManager.startPage(const page: word);
begin
  isStory := true;
  activePage := page;
  storyRow := 0; storyCol := 1;
  elapsed := 0;

  case page of
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
      isStory := false;
  end;
end;

procedure TStoryManager.nextPage;
begin
  inc(activePage);
  startPage(activePage)
end;

procedure TStoryManager.tryNextPage;
begin
  if storyRow >= lineCount then
    nextPage
  else
    storyRow := lineCount;
end;

procedure TStoryManager.init(const fontPtr: PBMFont);
begin
  isStory := false;
  storyRow := 0;
  storyCol := 1;
  elapsed := 0;
  self.font := fontPtr
end;

procedure TStoryManager.update;
begin
  if not isStory then exit;

  if storyRow < lineCount then begin
    elapsed := elapsed + dt;
    if elapsed >= charInterval then begin
      elapsed := 0;
      inc(storyCol)
    end;

    if storyCol > length(lines[storyRow]) then begin
      storyCol := 1;
      inc(storyRow);
    end;
  end;
end;

procedure TStoryManager.draw;
var
  a: integer;
begin
  if not isStory then exit;

  { Render full text }
  for a:=0 to storyRow - 1 do
    font^.print(lines[a], 0, font^.lineHeight * a, 15);

  { Render partially }
  if storyRow < lineCount then
    font^.print(
      copy(lines[storyRow], 1, storyCol),
      0, storyRow * font^.lineHeight,
      15);
end;


procedure TStoryManager.drawDebug;
begin
  if not isStory then
    print('isStory is false', 0, 0, 15)
  else
    print('col:' + i32str(storyCol) + ', row:' + i32str(storyRow), 0, 0, 15);
end;

end.

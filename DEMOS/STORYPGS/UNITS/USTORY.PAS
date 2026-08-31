unit UStory;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

interface

uses P92BMFON;

type
  TQuoteLines = array[0..3] of string;

  PStoryManager = ^TStoryManager;

  { TStoryManager }

  TStoryManager = object
    isStory: boolean;

    procedure StartPage(const lines: TQuoteLines; const lineCount: word);

    function IsEndOfPage: boolean;
    procedure NextPage;
    procedure TryNextPage;

    constructor Init(aFont: PBMFont);
    destructor Done; virtual;

    procedure Update;
    procedure Draw;
    procedure DrawDebug;
  private
    fFont: PBMFont;

    fLines: TQuoteLines;
    fLineCount: word;
  end;


implementation

uses P92CONV, P92TIME, P92VGA;

const
  charInterval = 0.016;

var
  storyRow, storyCol: integer;
  elapsed: double;

procedure TStoryManager.StartPage(const lines: TQuoteLines; const lineCount: word);
begin
  isStory := true;

  fLines := lines;
  fLineCount := lineCount;

  storyRow := 0; storyCol := 1;
  elapsed := 0;
end;

function TStoryManager.IsEndOfPage: boolean;
begin
  IsEndOfPage := storyRow >= fLineCount
end;

constructor TStoryManager.Init(aFont: PBMFont);
begin
  isStory := false;

  storyRow := 0;
  storyCol := 1;
  elapsed := 0;
  fFont := aFont
end;

destructor TStoryManager.Done;
begin
  if assigned(fFont) then
    fFont := nil;
end;

procedure TStoryManager.Update;
begin
  if not isStory then exit;

  if storyRow < lineCount then begin
    elapsed := elapsed + DeltaTime;
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

procedure TStoryManager.Draw;
const
  Top = 100;
var
  a: integer;
begin
  if not isStory then exit;

  { Render full text }
  for a:=0 to storyRow - 1 do
    PrintBMFont(fFont^, lines[a], 10, Top + fFont^.lineHeight * a);

  { Render partially }
  if storyRow < lineCount then
    PrintBMFont(
      fFont^,
      copy(lines[storyRow], 1, storyCol),
      10,
      Top + storyRow * fFont^.lineHeight);
end;


procedure TStoryManager.DrawDebug;
begin
  if not isStory then
    print('isStory is false', 0, 0, 15)
  else
    print('col:' + i32str(storyCol) + ', row:' + i32str(storyRow), 0, 0, 15);
end;

end.

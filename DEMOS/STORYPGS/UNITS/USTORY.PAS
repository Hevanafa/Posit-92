unit UStory;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

interface

uses P92BMFON;

type
  TQuoteLines = array[0..3] of string;

  PStoryManager = ^TStoryManager;

  { TStoryManager }

  TStoryManager = object
    procedure StartPage(const lines: TQuoteLines; const lineCount: word);
    function IsEndOfPage: boolean;
    procedure SkipPage;

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
  fLines := lines;
  fLineCount := lineCount;

  storyRow := 0; storyCol := 1;
  elapsed := 0;
end;

function TStoryManager.IsEndOfPage: boolean;
begin
  IsEndOfPage := storyRow >= fLineCount
end;

procedure TStoryManager.SkipPage;
begin
  storyRow := fLineCount;
  storyCol := 1;
end;

constructor TStoryManager.Init(aFont: PBMFont);
begin
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
  if storyRow < fLineCount then begin
    elapsed := elapsed + DeltaTime;

    if elapsed >= charInterval then begin
      elapsed := 0;
      inc(storyCol)
    end;

    if storyCol > length(fLines[storyRow]) then begin
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
  { Render full text }
  for a:=0 to storyRow - 1 do
    PrintBMFont(
      fFont^, fLines[a],
      10, Top + fFont^.lineHeight * a);

  { Render partially }
  if storyRow < fLineCount then
    PrintBMFont(
      fFont^,
      copy(fLines[storyRow], 1, storyCol),
      10,
      Top + storyRow * fFont^.lineHeight);
end;


procedure TStoryManager.DrawDebug;
begin
  {
  if not isStory then
    print('isStory is false', 0, 0, 15)
  else
  }
  Print('col:' + i32str(storyCol) + ', row:' + i32str(storyRow), 0, 0, 15);
end;

end.

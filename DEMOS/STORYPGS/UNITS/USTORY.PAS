unit UStory;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

interface

uses P92BMFON, P92TEX;

type
  TQuoteLines = array[0..3] of string;

  PStoryManager = ^TStoryManager;

  { TStoryManager }

  TStoryManager = object
    procedure StartPage(const lines: TQuoteLines; const lineCount: word);
    procedure SetPortrait(const tex: PTexture);
    procedure SetSpeaker(const name: string);

    function IsEndOfPage: boolean;
    procedure SkipPage;

    constructor Init(aFont: PBMFont);
    destructor Done; virtual;

    procedure Update;
    procedure Draw;
    procedure DrawDebug;
  private
    fFont: PBMFont;
    fPortrait: PTexture;

    fSpeakerName: string;
    fLines: TQuoteLines;
    fLineCount: word;
  end;


implementation

uses P92CONV, P92TIME, P92VGA;

const
  { in seconds }
  CharInterval = 0.016;

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

procedure TStoryManager.SetPortrait(const tex: PTexture);
begin
  fPortrait := tex
end;

procedure TStoryManager.SetSpeaker(const name: string);
begin
  fSpeakerName := name
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

  fFont := aFont;
  fPortrait := nil;
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

    if elapsed >= CharInterval then begin
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
  s: string;
  w: word;
begin
  if assigned(fPortrait) then begin
    spr(fPortrait^, (VGAWidth - fPortrait^.width) div 2, 8);
  end;

  { Render full text }
  for a:=0 to storyRow - 1 do begin
    w := MeasureBMFont(ffont^, fLines[a]);

    PrintBMFont(
      fFont^,
      fLines[a],
      (VGAWidth - w) div 2,
      Top + fFont^.lineHeight * a);
  end;

  { Render partially }
  if storyRow < fLineCount then begin
    s := copy(fLines[storyRow], 1, storyCol);
    w := MeasureBMFont(ffont^, s);

    PrintBMFont(
      fFont^,
      s,
      (VGAWidth - w) div 2,
      Top + storyRow * fFont^.lineHeight);
  end;

  { Render the name }
  if IsEndOfPage then begin
    s := '- ' + fSpeakerName;
    w := MeasureBMFont(fFont^, s);

    PrintBMFont(
      fFont^,
      s,
      (VGAWidth - w) div 2,
      top + (fLineCount + 1) * ffont^.lineHeight)
  end;
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

unit P92IMGUI;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

interface

{$IFDEF P92_IMGUI}
uses BMFont;

{ Required: Called before UpdateMouse }
procedure UpdateGUILastMouseButton;

{ Required: Called after UpdateMouse }
procedure UpdateGUIMousePoint;

{ Required: Called at the end of update routine }
procedure ResetWidgetIndices;

{ Required: Must be placed at the end of the draw routine }
procedure ResetActiveWidget;

procedure GuiSetFont(font: TBMFont);
function GuiMeasureText(const text: string): word;

procedure InitImmediateGUI(font: TBMFont);

{ Widgets }

procedure TextLabel(const text: string; const x, y: integer);

{$ENDIF}


implementation

{$IFDEF P92_IMGUI}
uses
  P92Geom, P92Mouse;

var
  { Immediate GUI }
  { Additional mouse variables }
  mousePoint: TPoint;
  lastMouseButton: integer;
  mouseJustPressed, mouseJustReleased: boolean;

  {
  activeWidget is the "memory" of what the user clicked on
  activeWidget must survive across frames
  }
  hotWidget, activeWidget, nextWidgetID: integer;
  { Used by SliderDrag }
  lastActiveWidget: integer;

  activeFont: TBMFont;


procedure UpdateGUILastMouseButton;
begin
  lastMouseButton := mouseButton
end;

procedure UpdateGUIMousePoint;
begin
  mousePoint.x := mouseX;
  mousePoint.y := mouseY;

  mouseJustPressed := (mouseButton <> MouseButtonNone) and (lastMouseButton = MouseButtonNone);
  mouseJustReleased := (mouseButton = MouseButtonNone) and (lastMouseButton <> MouseButtonNone)
end;

procedure ResetWidgetIndices;
begin
  hotWidget := -1;
  { Important: Do not reset activeWidget on each frame }
  { activeWidget := -1; }
  nextWidgetID := 0;
end;

procedure ResetActiveWidget;
begin
  lastActiveWidget := activeWidget;
  if mouseJustReleased and (activeWidget >= 0) then activeWidget := -1;
end;

procedure GuiSetFont(font: TBMFont);
begin
  activeFont := font
end;

function GuiMeasureText(const text: string): word;
begin
  { AssertFontSet; }
  GuiMeasureText := MeasureBMFont(activeFont, text)
end;


procedure InitImmediateGUI(font: TBMFont);
begin
  hotWidget := -1;
  activeWidget := -1;
  nextWidgetID := 0;
  lastActiveWidget := -1;

  mousePoint.x := 0;
  mousePoint.y := 0;

  GuiSetFont(font);
end;

{ Begin widgets }

procedure TextLabel(const text: string; const x, y: integer);
begin
  { AssertFontSet; }
  PrintBMFont(activeFont, text, x, y)
end;

{$ENDIF}

end.

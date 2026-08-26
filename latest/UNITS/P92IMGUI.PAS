unit P92IMGUI;

interface

{$IFDEF P92_IMGUI}
procedure ResetWidgetIndices;
{$ENDIF}


implementation

{$IFDEF P92_IMGUI}
uses
  BMFont;

var
  { Immediate GUI }
  { Additional mouse variables }
  mousePoint: TPoint;
  lastMouseButton: smallint;
  mouseJustPressed, mouseJustReleased: boolean;

  {
  activeWidget is the "memory" of what the user clicked on
  activeWidget must survive across frames
  }
  hotWidget, activeWidget, nextWidgetID: smallint;
  { Used by SliderDrag }
  lastActiveWidget: smallint;

  isFontSet: boolean;
  activeFont: TBMFont;


procedure UpdateGUILastMouseButton;
begin
  lastMouseButton := mouseButton
end;

procedure ResetWidgetIndices;
begin
  hotWidget := -1;
  { Important: Do not reset activeWidget on each frame }
  { activeWidget := -1; }
  nextWidgetID := 0;
end;

procedure InitImmediateGUI(useDefaultFont: boolean);
begin
  hotWidget := -1;
  activeWidget := -1;
  nextWidgetID := 0;
  lastActiveWidget := -1;

  mousePoint.x := 0;
  mousePoint.y := 0;

  if useDefaultFont then
    GuiSetFont(GetDefaultFontHandle);
end;
{$ENDIF}

end.

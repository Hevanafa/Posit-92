unit P92IMGUI;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

interface

{$IFDEF P92_IMGUI}
{ Required: Called before UpdateMouse }
procedure UpdateGUILastMouseButton;

{ Required: Called after UpdateMouse }
procedure UpdateGUIMousePoint;

{ Required: Called at the end of update routine }
procedure ResetWidgetIndices;

{ Required: Must be placed at the end of the draw routine }
procedure ResetActiveWidget;
{$ENDIF}


implementation

{$IFDEF P92_IMGUI}
uses
  BMFont, P92Geom;

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

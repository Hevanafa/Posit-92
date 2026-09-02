{
  Immediate GUI unit
  Part of Posit-92 game engine

  Contains a subset of the WASM version

  Key widgets:
  - TextLabel
  - Button
  - ImageButton

  Naming pattern:
  [Widget][Attribute/Behaviour]
}

unit P92IMGUI;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

interface

{$IFDEF P92_IMGUI}
uses P92BMFON, P92TEX, P92GEOM;

{ Interaction helpers }

function GetHotWidget: integer;
procedure SetHotWidget(const widgetID: integer);
function GetActiveWidget: integer;
procedure SetActiveWidget(const widgetID: integer);
function GetNextWidgetID: integer;
procedure IncNextWidgetID;

function GetMouseJustPressed: boolean;
function GetMouseJustReleased: boolean;
function IsMousePointInZone(const zone: TZone): boolean;

{ Can be used with drawMouse }
function HasHoveredWidget: boolean;

{ Required: Called before UpdateMouse }
procedure UpdateGUILastMouseButton;

{ Required: Called after UpdateMouse }
procedure UpdateGUIMousePoint;

{ Required: Called at the end of update routine }
procedure ResetWidgetIndices;

{ Required: Must be placed at the end of the draw routine }
procedure ResetActiveWidget;

procedure GuiSetFont(font: PBMFont);
function GuiMeasureText(const text: string): word;

procedure InitImmediateGUI(font: PBMFont);

{ Widgets }

procedure TextLabel(const text: string; const x, y: integer);
procedure CentredLabel(const text: string; const cx, y: integer);
procedure UnderlinedLabel(const text: string; const x, y: integer; const lineColour: byte);

function Button(const caption: string; const x, y: integer): boolean;
function ButtonSized(const caption: string; const x, y, width, height: integer): boolean;

function ImageButton(
  const x, y: integer;
  texNormal, texHovered, texPressed: PTexture
): boolean;

{$ENDIF}


implementation

{$IFDEF P92_IMGUI}
uses
  P92MOUSE, P92PANIC, P92GRAPH;

const
  ButtonPressColour = $91;  {145}
  ButtonHoverColour = $49;  {73}
  ButtonIdleColour = $02;

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

  activeFont: PBMFont;

function GetHotWidget: integer;
begin
  GetHotWidget := hotWidget
end;

procedure SetHotWidget(const widgetID: integer);
begin
  hotWidget := widgetID
end;

function GetActiveWidget: integer;
begin
  GetActiveWidget := activeWidget
end;

procedure SetActiveWidget(const widgetID: integer);
begin
  activeWidget := widgetID
end;

function GetNextWidgetID: integer;
begin
  GetNextWidgetID := nextWidgetID
end;

procedure IncNextWidgetID;
begin
  inc(nextWidgetID)
end;

function GetMouseJustPressed: boolean;
begin
  GetMouseJustPressed := mouseJustPressed
end;

function GetMouseJustReleased: boolean;
begin
  GetMouseJustReleased := mouseJustReleased
end;

function IsMousePointInZone(const zone: TZone): boolean;
begin
  IsMousePointInZone := PointInZone(mousePoint, zone)
end;

function HasHoveredWidget: boolean;
begin
  HasHoveredWidget := hotWidget > -1
end;

procedure UpdateGUILastMouseButton;
begin
  lastMouseButton := GetMouseButton
end;

procedure UpdateGUIMousePoint;
begin
  mousePoint.x := GetMouseX;
  mousePoint.y := GetMouseY;

  mouseJustPressed := (GetMouseButton <> MouseButtonNone) and (lastMouseButton = MouseButtonNone);
  mouseJustReleased := (GetMouseButton = MouseButtonNone) and (lastMouseButton <> MouseButtonNone)
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

procedure AssertFontSet;
begin
  if not assigned(activeFont) then
    PanicHalt('P92IMGUI: AssertFontSet: activeFont is unset!');
end;

procedure GuiSetFont(font: PBMFont);
begin
  activeFont := font
end;

function GuiMeasureText(const text: string): word;
begin
  AssertFontSet;
  GuiMeasureText := MeasureBMFont(activeFont^, text)
end;


procedure InitImmediateGUI(font: PBMFont);
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
  AssertFontSet;
  PrintBMFont(activeFont^, text, x, y)
end;

procedure CentredLabel(const text: string; const cx, y: integer);
var
  w: integer;
begin
  AssertFontSet;

  w := MeasureBMFont(activeFont^, text);
  PrintBMFont(activeFont^, text, cx - w shr 1, y)
end;

procedure UnderlinedLabel(const text: string; const x, y: integer; const lineColour: byte);
var
  w: integer;
begin
  AssertFontSet;

  w := MeasureBMFont(activeFont^, text);
  line(x, y + activeFont^.lineHeight - 1, x + w, y + activeFont^.lineHeight - 1, lineColour);

  PrintBMFont(activeFont^, text, x, y)
end;

function Button(const caption: string; const x, y: integer): boolean;
const
  Padding = 4;
var
  w: integer;
begin
  w := MeasureBMFont(activeFont^, caption);
  Button := ButtonSized(caption, x, y, w + Padding * 2, activeFont^.lineHeight + Padding * 2)
end;

function ButtonSized(const caption: string; const x, y, width, height: integer): boolean;
const
  Padding = 4;
var
  zone: TZone;
  thisWidgetID: integer;
  buttonColour: word;
begin
  AssertFontSet;

  zone.x := x;
  zone.y := y;
  zone.width := width;
  zone.height := height;

  { Update logic }
  thisWidgetID := nextWidgetID;
  inc(nextWidgetID);

  if pointInZone(mousePoint, zone) then begin
    hotWidget := thisWidgetID;

    if mouseJustPressed then activeWidget := thisWidgetID;
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
  TextLabel(caption, trunc(zone.x + Padding), trunc(zone.y + Padding));

  if mouseJustReleased and (hotWidget = thisWidgetID) and (activeWidget = thisWidgetID) then
    { activeWidget = -1 }  { Index reset is handled at the end of draw }
    ButtonSized := true
  else
    ButtonSized := false;
end;

function ImageButton(
  const x, y: integer;
  texNormal, texHovered, texPressed: PTexture
): boolean;
var
  zone: TZone;
  thisWidgetID: integer;
  texture: PTexture;
begin
  zone.x := x;
  zone.y := y;
  zone.width := texNormal^.width;
  zone.height := texNormal^.height;

  { Update logic }
  thisWidgetID := nextWidgetID;
  inc(nextWidgetID);

  if pointInZone(mousePoint, zone) then begin
    hotWidget := thisWidgetID;

    if mouseJustPressed then activeWidget := thisWidgetID;
  end;

  { Render logic }
  if activeWidget = thisWidgetID then
    texture := texPressed
  else if hotWidget = thisWidgetID then
    texture := texHovered
  else
    texture := texNormal;

  spr(texture^, x, y);

  if mouseJustReleased and (hotWidget = thisWidgetID) and (activeWidget = thisWidgetID) then
    { activeWidget = -1 }  { Index reset is handled at the end of draw }
    ImageButton := true
  else
    ImageButton := false;
end;

{$ENDIF}

begin
{$IFDEF P92_IMGUI}
  activeFont := nil
{$ENDIF}
end.

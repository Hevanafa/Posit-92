{
  Geometry unit
  Part of Posit-92 game engine
  Hevanafa

  Contains primitive types: point, zone, physics body & circle
}

unit P92Geom;

{$IFDEF FPC}
{$MODE TP}
{$H-}  { Use ShortStrings }
{$J-}  { Don't allow assignments to typed consts }
{$ENDIF}

interface

type
  PPoint = ^TPoint;
  TPoint = record
    x, y: double;
  end;

  TPointInt = record
    x, y: integer;
  end;

  TZone = record
    x, y: double;
    width, height: double;
  end;

  { was TRect, split into 2: TZone and TPhysicsBody }
  TPhysicsBody = record
    x, y: double;
    width, height: double;
    vx, vy: double;
  end;

  TCircle = record
    cx, cy, radius: double;
    vx, vy: double;
  end;

procedure DrawZone(const zone: TZone; const colour: byte);
procedure DrawPhysicsBody(const body: TPhysicsBody; const colour: byte);
procedure DrawCircleZone(const zone: TCircle; const colour: byte);

function GetDist(const a, b: TPoint): double;

function GetZoneCX(const zone: TZone): double;
function GetZoneCY(const zone: TZone): double;
function GetZoneDist(const a, b: TZone): double;
procedure GetZoneCPoint(const zone: TZone; var result: TPoint);

procedure GetPhysicsCPoint(const body: TPhysicsBody; var result: TPoint);
function GetPhysicsBodyCX(const body: TPhysicsBody): double;
function GetPhysicsBodyCY(const body: TPhysicsBody): double;

{
function NewPoint(const x, y: double): TPoint;
function NewZone(const x, y, width, height: double): TZone;
function PhysicsBodyToZone(const body: TPhysicsBody): TZone;
}

function ZoneIntersects(const self, other: TZone): boolean;
function CircleIntersects(const self, other: TCircle): boolean;
function CircleZoneIntersects(const circ: TCircle; const zone: TZone): boolean;
function PointInCircle(const p: TPoint; const circ: TCircle): boolean;
function PointInZone(const p: TPoint; const zone: TZone): boolean;


implementation

uses P92MATHS, P92GRAPH;

procedure DrawZone(const zone: TZone; const colour: byte);
begin
  Rect(trunc(zone.x), trunc(zone.y), trunc(zone.x + zone.width), trunc(zone.y + zone.height), colour)
end;

procedure DrawPhysicsBody(const body: TPhysicsBody; const colour: byte);
begin
  Rect(trunc(body.x), trunc(body.y), trunc(body.x + body.width), trunc(body.y + body.height), colour)
end;

procedure DrawCircleZone(const zone: TCircle; const colour: byte);
begin
  Circ(trunc(zone.cx), trunc(zone.cy), trunc(zone.radius), colour)
end;

function GetDist(const a, b: TPoint): double;
var
  dx, dy: double;
begin
  dx := b.x - a.x;
  dy := b.y - a.y;
  GetDist := dx * dx + dy * dy
end;

function GetZoneCX(const zone: TZone): double;
begin
  GetZoneCX := trunc(zone.x + zone.width / 2)
end;

function GetZoneCY(const zone: TZone): double;
begin
  GetZoneCY := trunc(zone.y + zone.height / 2)
end;

function GetZoneDist(const a, b: TZone): double;
var
  x, y: double;
begin
  x := GetZoneCX(b) - GetZoneCX(a);
  y := GetZoneCY(b) - GetZoneCY(a);
  GetZoneDist := x * x + y * y
end;

procedure GetZoneCPoint(const zone: TZone; var result: TPoint);
begin
  result.x := GetZoneCX(zone);
  result.y := GetZoneCY(zone);
end;


procedure GetPhysicsCPoint(const body: TPhysicsBody; var result: TPoint);
begin
  result.x := GetPhysicsBodyCX(body);
  result.y := GetPhysicsBodyCY(body);
end;

function GetPhysicsBodyCX(const body: TPhysicsBody): double;
begin
  GetPhysicsBodyCX := trunc(body.x + body.width / 2)
end;

function GetPhysicsBodyCY(const body: TPhysicsBody): double;
begin
  GetPhysicsBodyCY := trunc(body.y + body.height / 2)
end;

{
function NewPoint(const x, y: double): TPoint;
begin
  NewPoint.x := x;
  NewPoint.y := y;
end;

function NewZone(const x, y, width, height: double): TZone;
begin
  NewZone.x := x;
  NewZone.y := y;
  NewZone.width := width;
  NewZone.height := height;
end;

function PhysicsBodyToZone(const body: TPhysicsBody): TZone;
begin
  with PhysicsBodyToZone do begin
    x := body.x;
    y := body.y;
    width := body.width;
    height := body.height;
  end;
end;
}

function ZoneIntersects(const self, other: TZone): boolean;
begin
  ZoneIntersects := (other.x < self.x + self.width)
    and (self.x < other.x + other.width)
    and (other.y < self.y + self.height)
    and (self.y < other.y + other.height)
end;

{ Distance isn't square rooted }
function CircleIntersects(const self, other: TCircle): boolean;
var
  dx, dy, dist, radiusSum: double;
begin
  dx := other.cx - self.cx;
  dy := other.cy - self.cy;

  radiusSum := self.radius + other.radius;

  dist := dx * dx + dy * dy;
  CircleIntersects := dist < radiusSum * radiusSum
end;

{ Distance isn't square rooted }
function CircleZoneIntersects(const circ: TCircle; const zone: TZone): boolean;
var
  closestX, closestY: double;
  dx, dy, dist: double;
begin
  closestX := clamp(circ.cx, zone.x, zone.x + zone.width);
  closestY := clamp(circ.cy, zone.y, zone.y + zone.height);

  dx := circ.cx - closestX;
  dy := circ.cy - closestY;
  dist := dx * dx + dy * dy;

  CircleZoneIntersects := dist < circ.radius * circ.radius
end;

function PointInCircle(const p: TPoint; const circ: TCircle): boolean;
var
  dx, dy, dist: double;
begin
  dx := p.x - circ.cx;
  dy := p.y - circ.cy;
  dist := dx * dx + dy * dy;

  PointInCircle := dist < circ.radius * circ.radius
end;

function PointInZone(const p: TPoint; const zone: TZone): boolean;
begin
  PointInZone := (p.x >= zone.x)
    and (p.x < zone.x + zone.width)
    and (p.y >= zone.y)
    and (p.y < zone.y + zone.height)
end;


end.

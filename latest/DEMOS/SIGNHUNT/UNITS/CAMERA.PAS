unit Camera;

interface

uses P92TEX;

function GetCameraX: integer;
procedure SetCameraX(const value: integer);
function GetCameraY: integer;
procedure SetCameraY(const value: integer);

procedure SprWithCamera(const tex: TTexture; const x, y: integer);
procedure PSetWithCamera(const x, y: integer; const colour: byte);


implementation

{ uses NokiaVGA; }
uses P92VGA;

var
  cameraX, cameraY: integer;

function GetCameraX:integer;
begin
  GetCameraX := cameraX
end;

procedure SetCameraX(const value:integer);
begin
  cameraX := value
end;

function GetCameraY:integer;
begin
  GetCameraY := cameraY
end;

procedure SetCameraY(const value:integer);
begin
  cameraY := value
end;

procedure SprWithCamera(const tex: TTexture; const x, y: integer);
begin
  Spr(tex, x - cameraX, y - cameraY)
end;

procedure PSetWithCamera(const x, y: integer; const colour: byte);
begin
  AsmPSet(x - cameraX, y - cameraY, colour)
end;

begin
  cameraX := 0;
  cameraY := 0;
end.

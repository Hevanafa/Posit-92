unit Camera;

interface

uses P92TEX;

procedure SprWithCamera(const tex: TTexture; const x, y: integer);
procedure PSetWithCamera(const x, y: integer; const colour: byte);


implementation

{ uses NokiaVGA; }
uses P92VGA;

var
  cameraX, cameraY: integer;

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

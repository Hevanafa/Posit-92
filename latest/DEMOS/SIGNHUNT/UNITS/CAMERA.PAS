unit Camera;

interface

uses P92TEX;

var
  cameraX, cameraY: integer;

procedure initCamera;
procedure sprWithCamera(const tex: TTexture; const x, y: integer);
procedure psetWithCamera(const x, y: integer; const colour: byte);


implementation

{ uses NokiaVGA; }
uses P92VGA;

procedure initCamera;
begin
  cameraX := 0;
  cameraY := 0;
end;

procedure sprWithCamera(const tex: TTexture; const x, y: integer);
begin
  Spr(tex, x - cameraX, y - cameraY)
end;

procedure psetWithCamera(const x, y: integer; const colour: byte);
begin
  AsmPSet(x - cameraX, y - cameraY, colour)
end;

end.

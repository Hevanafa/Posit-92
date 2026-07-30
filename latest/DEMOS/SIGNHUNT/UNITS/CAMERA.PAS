unit Camera;

interface

uses Bitmap;

var
  cameraX, cameraY: integer;

procedure initCamera;
procedure sprWithCamera(const image: PBitmap; const x, y: integer; const transparencyKey: byte);
procedure psetWithCamera(const x, y: integer; const colour: byte);


implementation

uses NokiaVGA;

procedure initCamera;
begin
  cameraX := 0;
  cameraY := 0;
end;

procedure sprWithCamera(const image: PBitmap; const x, y: integer; const transparencyKey: byte);
begin
  pascalSpr(image, x - cameraX, y - cameraY, transparencyKey)
end;

procedure psetWithCamera(const x, y: integer; const colour: byte);
begin
  pset(x - cameraX, y - cameraY, colour)
end;

end.
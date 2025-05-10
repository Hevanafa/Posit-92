{
  This keyboard implementation should work with
  DOSBox's default settings
}

unit Keyboard;

interface

procedure initKeyHandler;
procedure resetKeyHandler;
{
  Scancode lists:
  https://www.freepascal.org/docs-html/rtl/keyboard/kbdscancode.html
  https://www.freebasic.net/wiki/GfxScancodes
}
function isKeyDown(scancode: byte): boolean;


implementation

uses DOS;

const
  NUM_KEYS = 128;

var
  { pressed keys }
  keys: array[0..NUM_KEYS - 1] of boolean;
  oldKeyHandler: pointer;

procedure keyHandler; interrupt;
var
  scancode: byte;
  isBreak: boolean;
begin
  scancode := Port[$60];
  isBreak := (scancode and $80) <> 0;
  scancode := scancode and $7F; { mask break bit }

  if scancode < NUM_KEYS then
    keys[scancode] := not isBreak;

  { acknowledge interrupt }
  Port[$20] := $20
end;

procedure initKeyHandler;
begin
  getIntVec($09, oldKeyHandler);
  setIntVec($09, @keyHandler)
end;

procedure resetKeyHandler;
begin
  setIntVec($09, oldKeyHandler)
end;

function isKeyDown(scancode: byte): boolean;
begin
  isKeyDown := keys[scancode]
end;


end.


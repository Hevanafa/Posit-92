{
  This keyboard implementation should work with
  DOSBox's default settings
}

unit Keyboard;

interface

const
  SC_ESCAPE = $01;
  SC_1 = $02;
  SC_2 = $03;
  SC_3 = $04;
  SC_4 = $05;
  SC_5 = $06;
  SC_6 = $07;
  SC_7 = $08;
  SC_8 = $09;
  SC_9 = $0A;
  SC_0 = $0B;
  SC_MINUS = $0C;
  SC_EQUALS = $0D;
  SC_BACKSPACE = $0E;
  SC_TAB = $0F;

  SC_Q = $10;
  SC_W = $11;
  SC_E = $12;
  SC_R = $13;
  SC_T = $14;
  SC_Y = $15;
  SC_U = $16;
  SC_I = $17;
  SC_O = $18;
  SC_P = $19;
  SC_LEFT_BRACKET  = $1A;
  SC_RIGHT_BRACKET = $1B;
  SC_ENTER = $1C;
  SC_LEFT_CONTROL  = $1D;

  SC_A = $1E;
  SC_S = $1F;
  SC_D = $20;
  SC_F = $21;
  SC_G = $22;
  SC_H = $23;
  SC_J = $24;
  SC_K = $25;
  SC_L = $26;
  SC_SEMICOLON = $27;
  SC_APOSTROPHE = $28;
  SC_BACKQUOTE = $29;

  SC_LEFT_SHIFT = $2A;
  SC_BACKSLASH = $2B;

  SC_Z = $2C;
  SC_X = $2D;
  SC_C = $2E;
  SC_V = $2F;
  SC_B = $30;
  SC_N = $31;
  SC_M = $32;
  SC_COMMA = $33;
  SC_PERIOD = $34;
  SC_SLASH = $35;
  SC_RIGHT_SHIFT = $36;
  SC_KP_ASTERISK = $37;
  SC_LEFT_ALT = $38;
  SC_SPACE = $39;

  SC_CAPSLOCK = $3A;

  SC_F1 = $3B;
  SC_F2 = $3C;
  SC_F3 = $3D;
  SC_F4 = $3E;
  SC_F5 = $3F;
  SC_F6 = $40;
  SC_F7 = $41;
  SC_F8 = $42;
  SC_F9 = $43;
  SC_F10 = $44;

  SC_NUMLOCK = $45;
  SC_SCROLLLOCK = $46;

  { NumLock OFF }
  SC_HOME = $47;
  SC_UP = $48;
  SC_PAGEUP = $49;
  SC_LEFT = $4B;
  SC_CENTER = $4C;
  SC_RIGHT = $4D;
  SC_END = $4F;
  SC_DOWN = $50;
  SC_PAGEDOWN = $51;
  SC_INSERT = $52;
  SC_DELETE = $53;

  { NumLock ON }
  SC_KP_7 = $47;
  SC_KP_8 = $48;
  SC_KP_9 = $49;
  SC_KP_MINUS = $4A;
  SC_KP_4 = $4B;
  SC_KP_5 = $4C;
  SC_KP_6 = $4D;
  SC_KP_PLUS = $4E;
  SC_KP_1 = $4F;
  SC_KP_2 = $50;
  SC_KP_3 = $51;
  SC_KP_0 = $52;
  SC_KP_PERIOD = $53;

  SC_SYSREQ = $54;
  { $55 and $56 are unused }
  SC_F11 = $57;
  SC_F12 = $58;

procedure InitKeyHandler;

{ Must be called before returning to text mode, otherwise all keys will be stuck in polling mode }
procedure ResetKeyHandler;

{
  Scancode lists:
  https://www.freepascal.org/docs-html/rtl/keyboard/kbdscancode.html
  https://www.freebasic.net/wiki/GfxScancodes
}
function IsKeyDown(scancode: byte): boolean;


implementation

uses DOS;

const
  NUM_KEYS = 128;

var
  { pressed keys }
  keys: array[0..NUM_KEYS - 1] of boolean;
  oldKeyHandler: pointer;
  keyboardInitialised: boolean;

procedure KeyHandler; interrupt;
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

procedure InitKeyHandler;
begin
  if keyboardInitialised then exit;
  GetIntVec($09, oldKeyHandler);
  SetIntVec($09, @KeyHandler);
  keyboardInitialised := true
end;

procedure ResetKeyHandler;
begin
  if not keyboardInitialised then exit;
  SetIntVec($09, oldKeyHandler);
  keyboardInitialised := false
end;

function IsKeyDown(scancode: byte): boolean;
begin
  if not keyboardInitialised then begin
    IsKeyDown := false;
    exit
  end;
  IsKeyDown := keys[scancode]
end;

end.


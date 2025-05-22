{ Common conversion utility unit }

unit Conv;

interface

function i32str(const value: Longint): string;
function f32str(const value: double): string;
function i16HexStr(const value: word): string;
function i8HexStr(const value: byte): string;
function parseInt(const text: string): integer;

implementation

function i32str(const value: longInt): string;
var
  result: string;
begin
  str(value, result);
  i32str := result
end;

function f32str(const value: double): string;
var
  result: string;
begin
  str(value:0:4, result);
  f32str := result
end;

function i16HexStr(const value: word): string;
const
  digits: array[0..15] of char = '0123456789ABCDEF';
var
  result: string;
  a: byte;
begin
  result:='';
  for a := 3 downto 0 do
    result:=result + digits[(value shr (a * 4)) and $F];
  i16hexStr := result
end;

function i8HexStr(const value: byte): string;
const
  digits: array[0..15] of char = '0123456789ABCDEF';
begin
  i8HexStr := digits[(value shr 4) and $F] + digits[value and $F];
end;

function parseInt(const text: string): integer;
var
  result, parseResult: integer;
begin
  val(text, result, parseResult);
  if parseResult <> 0 then begin
    writeLn('Error parsing to integer:', text);
    parseInt := 0
  end else
    parseInt := result;
end;


end.

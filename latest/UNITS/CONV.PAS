{ Common conversion utility unit }

{$IFDEF FPC}
{$MODE TP}
{$ENDIF}

unit Conv;

interface

function I32Str(const value: Longint): string;
function F32Str(const value: double): string;
function I16HexStr(const value: word): string;
function I8HexStr(const value: byte): string;
function BoolStr(const value: boolean): string;
function ParseInt(const text: string): integer;

implementation

function I32Str(const value: longInt): string;
var
  result: string;
begin
  str(value, result);
  I32Str := result
end;

function F32Str(const value: double): string;
var
  result: string;
begin
  str(value:0:4, result);
  F32Str := result
end;

function I16HexStr(const value: word): string;
const
  digits: array[0..15] of char = '0123456789ABCDEF';
var
  result: string;
  a: byte;
begin
  result:='';
  for a := 3 downto 0 do
    result:=result + digits[(value shr (a * 4)) and $F];
  I16HexStr := result
end;

function I8HexStr(const value: byte): string;
const
  digits: array[0..15] of char = '0123456789ABCDEF';
begin
  I8HexStr := digits[(value shr 4) and $F] + digits[value and $F];
end;

function BoolStr(const value: boolean): string;
begin
  if value then
    BoolStr := 'true'
  else
    BoolStr := 'false'
end;

function ParseInt(const text: string): integer;
var
  result, parseResult: integer;
begin
  val(text, result, parseResult);
  if parseResult <> 0 then begin
    writeLn('Error parsing to integer:', text);
    ParseInt := 0
  end else
    ParseInt := result;
end;


end.

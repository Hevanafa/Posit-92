{ Common conversion utility unit }

unit Conv;

interface

function i32str(const value: Longint): string;
function f32str(const value: double): string;
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

{ Common conversion utility unit }

unit Conv;

interface

function i32str(value: Longint): string;
function f32str(value: double): string;

implementation

function i32str(value: longInt): string;
var
  result: string;
begin
  str(value, result);
  i32str := result
end;

function f32str(value: double): string;
var
  result: string;
begin
  str(value:0:4, result);
  f32str := result
end;


end.

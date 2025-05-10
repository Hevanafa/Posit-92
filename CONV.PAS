{ Common conversion utility unit }

unit Conv;

interface

function i32str(value: Longint): string;


implementation

function i32str(value: Longint): string;
var
  result: string;
begin
  str(value, result);
  i32str := result
end;


end.

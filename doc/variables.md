
Data types in Turbo Pascal are as follows:
byte: `0..255`
shortint: `-128..127`
word: `0..65535`
integer: `-32768..32767`
longint: `-2147483648..2147483647`
boolean: 8-bit for either `true` or `false`

single: 4-byte floating-point precision
real: 6-byte floating-point precision
double: 8-byte

You'd need the FPU enabled in DOSBox config to get the hardware acceleration for floating point

`char`: 1 byte character representation
`string`: 1st byte for the length, the rest 255 for the string content
`PChar`: pointer to a null-terminated string

Data types can be aliased after the `type` keyword

Example:
```pascal
type
  ui8 = byte;
  i8 = shortint;
  ui16 = word;
  i16 = integer;
  ui32 = longword;
  i32 = longint;

  float = single;
```

Type coercion can be done with this pattern: `[TypeName]([sourceData])`
Example:
```pascal
{ double to integer, floor }
begin
  floored := trunc(yourDoubleValue);
  rounded := round(yourDoubleValue);
  ceiled := trunc(yourDoubleValue + 1);
end;
```

Array syntax
```pascal
var
  numbers = array[0..9] of integer;
```

Record syntax
```pascal
type
  ColourEnum = (cBlack, cOrange, cCow, cWhite);
  cat = record
    name: string;
    colour: ColourEnum;
  end;
```

More information can be read here:
https://wiki.freepascal.org/Data_type

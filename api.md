
This file documents all of the available API's in this game framework


### Bitmap

- `loadBMP(var output: PBitmap; filename: string);`

Loads a BMP file.

The format has to be an indexed 256 colour BMP, which pallette you can get from either Aseprite or Photoshop


- `drawBMP(image: PBitmap);`

Blits a `PBitmap` ignoring any transparency.


- `freeBMP(var image: PBitmap);`

Frees a `PBitmap`, also assigns `image` to `nil`.


- `spr(image: PBitmap; x, y: integer; transparencyKey: byte);`

Blits a `PBitmap` with the transparency key.

The transparency key is one of the 256 colours supported by the VGA display.


- `bitmapInfo(image: PBitmap);`

Used for debugging -- prints out `PBitmap` information


### Conv

Common conversion utility unit

- `function i32str(value: Longint): string;`

Converts a 32-bit integer to string


- `function f32str(value: double): string;`

Converts a number to string with 4 decimals


### Logger

- `initLogger`

This is required to start the Logger utility.


- `writeLog(const msg: string)`

Writes a line of message into the log file.


- `closeLogger`



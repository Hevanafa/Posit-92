
This file documents all of the available API's in this game framework


### Bitmap

- `procedure loadBMP(var output: PBitmap; filename: string)`

Loads a BMP file.

The format has to be an indexed 256 colour BMP, which pallette you can get from either Aseprite or Photoshop


- `procedure drawBMP(image: PBitmap)`

Blits a `PBitmap` ignoring any transparency.


- `procedure freeBMP(var image: PBitmap)`

Frees a `PBitmap`, also assigns `image` to `nil`.


- `procedure spr(image: PBitmap; x, y: integer; transparencyKey: byte)`

Blits a `PBitmap` with the transparency key.

The transparency key is one of the 256 colours supported by the VGA display.


- `procedure bitmapInfo(image: PBitmap)`

Used for debugging -- prints out `PBitmap` information


### Conv

Common conversion utility unit

- `function i32str(value: Longint): string`

Converts a 32-bit integer to string


- `function f32str(value: double): string`

Converts a number to string with 4 decimals


### Logger

- `procedure initLogger`

This is required to start the Logger utility.


- `procedure writeLog(const msg: string)`

Writes a line of message into the log file.


- `procedure closeLogger`


### Mouse

- `mouseX, mouseY: word`

- `mouseButton: byte`

Contains either one of these values:
- 0: No mouse button is pressed
- 1: Left button is pressed
- 2: Right button is pressed
- 3: Both buttons


- `procedure initMouse`

Must be called first before using the mouse.


- `procedure updateMouse`

Updates the mouse position & button by interrupts.


- `procedure debugMouse`

Shows the mouse coordinates on screen and the buttons pressed.


- `procedure drawMouse`

Draws the mouse cursor. You can change it in `loadCursor` in `MOUSE.PAS`.  The bitmap has to be an indexed bitmap that uses the VGA colour table.


- `procedure resetMouse`

Must be called before returning to screen mode 00h, otherwise the mouse control will be stuck & Runtime error 20302 happens.

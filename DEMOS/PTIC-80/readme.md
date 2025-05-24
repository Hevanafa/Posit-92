# Posit + TIC-80

This is a demo that emulates a different screen size while still in VGA mode

If you want a different screen size, change these in `VGA.PAS`:
- `TByteArray` high bound
- `bufferSize` depending on the pixel density
- `PSET`: change the 240 and 136 numbers depending on the pixel density
- `offset` in `tic80Flush`
- The third parameter of `Move` in `tic80Flush`
- `tic80Flush`: Rename this

Some screen sizes that you can emulate:
- **TIC-80: 240x136** (default)
- **PICO-8:** 128x128
- **Game Boy Color:** 160x144
- **Game Boy Advance:** 240x160
- **Nokia 3310:** 84x48

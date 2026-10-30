# New DOS project guide

This document is more of a guideline rather than rigid rules

## Copying the boilerplate

1. Copy the latest boilerplate: `DEMOS\SIMPLE`

   This directory will be the root of your new project
2. Copy the `UNITS` folder, rename it as `ENGINE` in your project
3. Create a new `UNITS` folder. This is where your custom units will live
4. Copy Turbo Pascal 7.0 into your new project, at the root, name the folder as `TP` or `TP7`

The project structure should look more or less like this:

```text
- IMG\
- ENGINE\
- UNITS\
- TP\
- GAME.PAS
- PROJECT.LPI (optional)
```

If you see `PROJECT.LPI`, you can edit the game using Lazarus IDE as a fancy autocomplete, while the compiler itself still uses Turbo Pascal

## Setting up unit paths

After copying the boilerplate manually, the next step is to edit the unit search paths

1. Open Turbo Pascal 7
2. Click the Options menu (or `Alt+O`)
3. Then click (D)irectories

Then, inside the Directories popup, press `Alt+U` to focus on the **Unit directories** field

Now change it to the new project structure, something like this:

```
C:\TP\UNITS;ENGINE;UNITS
```

The order is as follows:
- Turbo Pascal 7 units
- Posit-92 units
- User-defined units

Think of it more like "The units get more specific use cases the further it's on the right"

## `Double` type usage

Posit-92 uses `double` all the time because it's faster, considering the use of FPU (floating point unit)

This must be enabled in the Turbo Pascal IDE:
- in the **Options --> Compiler**, then
- under **Numeric processing**, enable 8087/80287
- Click OK or simply press ENTER

After pressing OK, don't forget to save your config by clicking the **Options** menu, then click **Save**, or shorter: `Alt+O, then S`

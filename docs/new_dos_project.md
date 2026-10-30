# New DOS project guide

This document is more of a guideline rather than rigid rules


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

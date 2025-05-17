# Demo Guide

The term **browser** in this document refers to the Demo Browser program


## Rules when creating a demo

- The user must be able to exit the program, i.e. using the **Esc** key or a button that says **Exit**
- All sounds must be deactivated at the end of a demo
- All used units must be included due to how the dependency management is still manual and also because the API's can change anytime
- Include the header as described in the section below
- The DOSBox configuration especially the CPU type & cycles, and the sound cards used, if available
- `GAMEINFO.TXT` must be included to be detectable by the browser


## Pascal header

Example comment at the top of a demo file:

```pascal
{
  Plasma demo
  Author: Hevanafa
  Date: 17-05-2025
  Description: Part of Posit-92 demos
}
```


## GAMEINFO.TXT

The browser will scan for GAMEINFO.TXT files in each folder

Example content:

```
Title: game title
Author: game developer, email, and so on
Site: website link
License: MIT License (change this to your choice)
Version: 0.1
Date: 17-05-2025
Screenshot: PREVIEW.BMP
Executable: GAME.EXE
```

If there's no screenshot or the file doesn't exist in the same directory as GAMEINFO.TXT, the browser will show `No preview` text in the middle like on this picture:

(TODO: Add the example)

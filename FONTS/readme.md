P92 Sans font data must be synchronised with the WASM version

The files in this folder is only serving as the source of truth within Posit-92 DOS

The order is like this:

- Posit-92 (WASM): source of truth
- Posit-92 (DOS): copy of above, with these key colours:
  - $0F: glyph
  - $0D: transparency key

The font in the DOS version is simply a copy, but with the format of an indexed bitmap

(Temporary 07-09-2026)

The canon for **P92 Sans 8px** is in DOS as for now

![regular font preview](./P92_Sans_8px_preview.png)

![bold font preview](./P92_Sans_8px_Bold_preview.png)
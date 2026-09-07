This document contains the usual, handful DOSBox-X config that I use

```ini
[cpu]
core = normal
cputype = pentium
cycles = max 50%

[dosbox]
machine = vgaonly
memsize = 16
```

When using the plain DOSBox, it's more or less the same, just a different config key

As for js-dos, the order is like this:

```text
DOSBOX
machine: vgaonly

CPU
core: normal
cputype: 386
cycles: max

SDL
autolock: no

MIXER
rate: 44100
nosound: no

AUTOEXEC
GAME.EXE
```

The `cycles` field can be changed later to `max 50%`

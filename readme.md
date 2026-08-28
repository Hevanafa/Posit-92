# ![Posit-92](./posit-92_logo.png) **Posit-92**

![preview 1](./preview_1.png)

![preview 2](./preview_2.png)

_"Not retro for nostalgia. Retro for power."_

A handcrafted game framework for Turbo Pascal 7.0.  Inspired by the raw speed, minimalism and creativity of pre-2000 tools.

Rainfall demo ([YouTube](https://www.youtube.com/watch?v=GJOnGodk5AU)):

![demo preview](./demo_preview.png)

Games that I've made are available on my itch.io page:

https://hevanafa.itch.io/

## Requirements

- Turbo Pascal 7.0
- DOS or a DOS emulator such as DOSBox-X
- Perl (at least v5.38.2) for the dev helper scripts
- Optional: Lazarus IDE with FPC configured with the **msdos-i8086** target

## Getting started

Clone this project without the commit history:

```powershell
git clone --depth 1 https://github.com/Hevanafa/Posit-92.git
```

### Creating a project

1. Copy the latest boilerplate: `DEMOS\SIMPLE`

   This directory will be the root of your new project
2. Copy the `UNITS` folder, rename it as `SHARED` in your project
3. Create a new `UNITS` folder. This is where your custom units will live
4. Copy Turbo Pascal 7.0 into your new project, at the root

The project structure should look more or less like this:

```text
- IMG\
- SHARED\
- UNITS\
- TP\
- CURSOR.BMP
- PROJECT.LPI
- GAME.PAS
```

### Compiling

1. Open your copy of Turbo Pascal:
   `TP\BIN\TPX.EXE`
2. Open `GAME.PAS`
3. Build all units with **Compile menu > Build**
4. Run `GAME.EXE` with **Ctrl+F9**
   1. Or, if you're on DOSBox-X, **Run menu > Run**

You should see a screen like this:

![preview](./preview_2.png)

### Configuring custom directives

(TODO)

## Recommended emulator settings

For general use, change the `cycles` to `12010`, which is the speed of a 486DX CPU

For test projects, set the `cycles` to `20000`

As for the memory size, make it at least 4 MB

## Project structure

- `DEMOS` - Example Posit-92 programmes
- `UNITS` - Posit-92 engine units
- `TESTS` - Test programmes

## Credits and Inspirations

The name comes from **Positron** and **1992** (the year in which TP7 was released), combined to resemble an isotope like Uranium-235 because it sounds cool  `:D`

My goal is to create a framework that resembles a fantasy computer, that is similar in spirit to **PICO-8** and **TIC-80**, but built around TP7.  Why? I believe it's fast enough & easier than C, added with inline assembly, it's **even closer to metal**

I'm also inspired by:

- [LoveDOS](https://github.com/rxi/lovedos) (also, the working fork with the audio working: https://github.com/SuperIlu/lovedos), and
- [TempleOS](http://www.templeos.org/)

[**This project has nothing to do with QAnon and I oppose QAnon completely.**](https://github.com/mfeq/mfeq/blob/master/doc/QAnon.md)

# Modular Font Editor Q

**Modular Font Editor Q** (MFEQ) is an open source modular font editor. It attempts to apply the Unix adage that each program should do one thing and do it well to a GUI font editor.

MFEQ is still very alpha, and many parts are missing. You can help!

**[Why MFEQ?](https://github.com/mfeq/mfeq/blob/master/doc/Why.md)**

## Planned modules

* [`Qglif`](https://github.com/mfeq/Qglif) (.glif editor w/Spiro support)
* `Qdesignspace` (design space XML creator/editor)
* `Qtransform` (transform, skew glyphs w/CLI options / GUI)
* `Qfontview` (a launcher for Qglif that displays all glyphs)
* `Qinterpolate` (an interpolation confirmer / tester)
* `Qmetadata` (UFO metadata)
* `Qkern` (kerning editor)
* `Qmetrics` (load UFO file into HarfBuzz and output typed text)
* `Qstroke` (use @skef's work to stroke glyphs provided on command line)
* `Qopentype` (OpenType layout editor based on @simoncozens' ideas)

## Planned libraries

* libglifparser (a .glif parser, right now vendorized in Qglif)
* libskef (port of @skef's &laquo;Expand Stroke&raquo; feature to a reusable C API)

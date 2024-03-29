# Modular Font Editor K

<img src="https://raw.githubusercontent.com/MFEK/docs/master/blob/logo.png" width="250">

**Modular Font Editor K** (MFEK) is an open source modular font editor. It attempts to apply the Unix adage that each program should do one thing and do it well to a GUI font editor.

MFEK is still very alpha, and many parts are missing. You can help!

**[Why MFEK?](https://github.com/MFEK/docs/blob/master/doc/Why.md)**

To pull all modules, why not use this script?

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/MFEK/docs/master/blob/pull_all_modules.sh)"

To see who wrote an MFEK module, check its `AUTHORS` file. The two main authors of MFEK are Fredrick R. Brennan (@ctrlcctrlv) and Matthew Blanchard (@MatthewBlanchard).

## Current roadmap as of 2021-11-02
![Current roadmap as of 2021-11-02](https://raw.githubusercontent.com/MFEK/docs/master/roadmap/roadmap.png)
### Roadmap key
* Dotted line around module name — module not started.
* Dashed line around module name — module started, yet far from completion.
* No line around module name — module is still far from being begun, and may indeed be unnecessary and never be begun.
* A bold black arrow represents a program calling a program.
* A red arrow represents a program including a library.
* A black arrow represents a library including a library.
* All libraries and programs are assumed to be in Rust unless noted otherwise.

## Modular programs

* [`MFEKglif`](https://github.com/MFEK/glif) (.glif editor w/planned Spiro support)
* [`MFEKpathops`](https://github.com/MFEK/pathops) (applies different kinds of operations to .glif paths)
* [`MFEKstroke`](https://github.com/MFEK/stroke) (applies different kinds of strokes to .glif files with open contours)
* [`MFEKmetadata`](https://github.com/MFEK/metadata) (UFO metadata querier)
* [`MFEKabout`](https://github.com/MFEK/about) (MFEK's about screen)

### Planned

* `MFEKufo` (a launcher for MFEKglif that displays all glyphs)
* `MFEKdesignspace` (design space XML creator/editor)
* `MFEKmetrics` (load UFO file into HarfBuzz and output typed text, edit horizontal/vertical kerning and bearings, test interpolation)
* `MFEKopentype` (OpenType layout editor based on @simoncozens' ideas)
* `MFEKexport` (frontend to fontmake)

#### Far off

* `MFEKpshints` (Add PostScript hints to glyphs and test them)
* `MFEKtruetype` (basically would be an open source version of Visual TrueType (VTT))

## Libraries

* [`glifparser.rlib`](https://github.com/MFEK/glifparser.rlib) (a .glif parser)
  * [`integer-or-float.rlib`](https://github.com/MFEK/integer_or_float.rlib) (implements a .glif data type)
  * <sub><sup>(We need this because Norad has no support for `<lib>` in `.glif` files, and due to how they went about implementing Norad, fixing that is trickier than having my own glyph parser. Furthermore, as I plan to support Spiro, B-Splines, etc., through UFO format extensions, I should have one anyway.)</sup></sub>
* [`icu-data.rlib`](https://github.com/MFEK/icu-data.rlib) (Unicode ICU data without C libicu, currently only encodings)
* [`ipc.rlib`](https://github.com/MFEK/ipc.rlib) (_very_ basic inter-process communication functions)
* [`math.rlib`](https://github.com/MFEK/math.rlib) (implements algorithms for MFEKstroke: Pattern-Along-Path, Variable/Constant Width Stroke, etc.)
* [`spiro.rlib`](https://github.com/MFEK/spiro.rlib) (a Rust implementation of Raph Levien's [Spiro](https://github.com/raphlinus/spiro) curve type)
* [`feaparser.rlib`](https://github.com/MFEK/feaparser.rlib) (an OpenType Feature File Format [`.fea`] parser)
* [`glifrenderer.rlib`](https://github.com/MFEK/glifrenderer.rlib) (a Skia renderer focused on rendering font glyphs in a pleasing way)

### Planned

* libskef (Port of @skef's &laquo;Expand Stroke&raquo; feature to a reusable C API. Will likely also require `SplineSet` type from FontForge.)

## Flow

MFEK's inter-process communication (IPC) will be minimal. UFO is the format, and most of the time, MFEK modules are going to be starting with just what's on the disk. We can put the planned MFEK modules onto a linear spectrum between _forms_ and _canvases_. The quintessential form is MFEKdesignspace: it is purely a form. The user inputs the names of their UFO masters, their axes, instances, and rules, and out comes a rigidly hierarchical `.designspace` file for consumption by `fontmake` and MFEKinterpolate. As a form, once it's filled out, it's done. We may need to go back and add more rules or instances or what have you, but it's essentially one run and done. Meanwhile, the quintessential canvas is MFEKglif: the user draws their glyphs and can spend as long as they want doing so, and will likely have multiple MFEKglif instances running in parallel. As long as you're working on the font, MFEKglif will probably be open most of the time.

MFEKstroke is an interesting example because it's in between. The user needs to fill out a form, yes, the stroke parameters &mdash; but she also needs to see what the glyph will look like with the parameters, and tweak them to her heart's content to get the best output. However, once parameters are chosen, it becomes almost pure form. It is both form and canvas, as is MFEKinterpolate. MFEKopentype and MFEKkern, meanwhile, have some form elements, but are more canvas than form.

Most of our IPC can just be `system` calls (launching new processes). At our most advanced, we watch a file or directory for changes and reconcile accordingly.

Let's consider we want to make a cursive font. Here is how we would proceed, according to my vision:

* Run MFEKmetadata. When it gets no argument, or the argument of a non-existent directory, it assumes we want a new font. So, we fill out a form.
* We then run MFEKufo and see empty squares. Clicking `A` launches MFEKglif with the command line `MFEKglif glyphs/A_.glif`.
  * MFEKglif calls MFEKmetadata as `MFEKmetadata metrics`. MFEKmetadata returns on stdout the em-size, ascender, descender, and x-height and cap-height if known based on the UFO metadata. MFEKglif draws guidelines.
* We start drawing our `A`. We decide to make it a single stroke. We press Ctrl-Shift-E, and MFEKglif launches MFEKstroke, saves the state of the glyph in the undoes list, and begins monitoring `A_.glif` for changes.
* MFEKstroke, likewise, monitors `A_.glif`. If written out, it changes its display. Perhaps auto-saving of every action can be optionally considered. How daring are we? Will our `.glif` file's `<lib>` contain undoes? Perhaps!
* The user settles on a stroke and presses Stroke. MFEKstroke writes and exits. MFEKglif dutifully reads from the disk.
* And so on for the basic Latin. It's come time to add an OpenType table. Launch `MFEKopentype`, which will build the font and use HarfBuzz to display it, and auto-update as the user writes their OpenType Layout code. This could be FEA, but it also could be Simon Cozens' [FEZ](https://github.com/simoncozens/fez), a higher level FEA-like syntax. MFEKopentype must be more conservative and only reload the font upon saving of any glyph, not every small action in MFEKglif.
* Finally, we have something we think servicable. In MFEKufo we press Generate, which calls MFEKexport. We're not writing a TrueType generator here, it's a simple form that calls `fontmake` with appropriate arguments.

Notice that while MFEK grows in size, we can offload one or more steps to FontForge/`fontmake` scripts. So even with only one or two programs, MFEK is immediately useful&mdash;we don't need the entire thing done to start using it in production. In fact, I plan to make fonts while I work on MFEK, and use less and less of FontForge over time.

But our goal is not to totally abandon FontForge, or AFDKO, or fontmake. No, rather, we want a new GUI. But to build our modular font editor, we'll take the good parts out of everything. FontForge is great at dealing with legacy formats: we can imagine a MFEKconvert based on a C library sourced from FontForge code, which calls either that, fontmake, or AFDKO, based on the type of conversion requested.

## Code of Conduct (CoC)

See [`CODE_OF_CONDUCT.md`](https://github.com/MFEK/docs/blob/master/CODE_OF_CONDUCT.md). The MFEK CoC there, last updated 17<sup>th</sup> November 2021, is that of the whole organization and all of the repositories and communication channels under its umbrella.

## Thanks to…

* Matthew Blanchard;
* Caleb Maclennan;
* Dave Crossland;
* Simon Cozens;
* Eli Heuer;
* Georg Duffner (for EB Garamond ExtraBold, used in our logo);
* All organization members, module authors and contributors;
* All developers of open source font-related software and fonts!

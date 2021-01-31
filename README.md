# Modular Font Editor K

<img src="https://raw.githubusercontent.com/MFEK/docs/master/blob/logo.png" width="250">

**Modular Font Editor K** (MFEK) is an open source modular font editor. It attempts to apply the Unix adage that each program should do one thing and do it well to a GUI font editor.

MFEK is still very alpha, and many parts are missing. You can help!

**[Why MFEK?](https://github.com/MFEK/docs/blob/master/doc/Why.md)**

## Modular programs

* [`MFEKglif`](https://github.com/MFEK/glif) (.glif editor w/Spiro support)
* [`MFEKstroke`](https://github.com/MFEK/stroke) (currently only supports pattern-along-path. Needs import of functions from FontForge)
* [`MFEKmetadata`](https://github.com/MFEK/metadata) (UFO metadata querier)
  * <sub><sup>(Right now only helps draw ascender/descender in MFEKglif.)</sup></sub>

### Planned

* `MFEKdesignspace` (design space XML creator/editor)
* `MFEKtransform` (transform, skew glyphs w/CLI options / GUI)
* `MFEKfontview` (a launcher for MFEKglif that displays all glyphs)
* `MFEKinterpolate` (an interpolation confirmer / tester)
* `MFEKkern` (kerning editor)
* `MFEKmetrics` (load UFO file into HarfBuzz and output typed text)
* `MFEKopentype` (OpenType layout editor based on @simoncozens' ideas)
* `MFEKexport` (frontend to fontmake)

## Libraries

* [libglifparser](https://github.com/MFEK/glifparser) (a .glif parser)
  * <sub><sup>(We need this because Norad has no support for `<lib>` in `.glif` files, and due to how they went about implementing Norad, fixing that is trickier than having my own glyph parser. Furthermore, as I plan to support Spiro, B-Splines, etc., through UFO format extensions, I should have one anyway.)</sup></sub>
* [MFEK Norad](https://github.com/MFEK/norad) (general UFO parser based on upstream Norad tweaked to play nice with `libglifparser`)
* [MFEK IPC](https://github.com/MFEK/ipc) (_very_ basic inter-process communication functions)

### Planned

* libskef (port of @skef's &laquo;Expand Stroke&raquo; feature to a reusable C API)
* spiro-rs (port of libspiro to Rust, probably will be done via `bindgen`)

# Flow

MFEK's inter-process communication (IPC) will be minimal. UFO is the format, and most of the time, MFEK modules are going to be starting with just what's on the disk. We can put the planned MFEK modules onto a linear spectrum between _forms_ and _canvases_. The quintessential form is MFEKdesignspace: it is purely a form. The user inputs the names of their UFO masters, their axes, instances, and rules, and out comes a rigidly hierarchical `.designspace` file for consumption by `fontmake` and MFEKinterpolate. As a form, once it's filled out, it's done. We may need to go back and add more rules or instances or what have you, but it's essentially one run and done. Meanwhile, the quintessential canvas is MFEKglif: the user draws their glyphs and can spend as long as they want doing so, and will likely have multiple MFEKglif instances running in parallel. As long as you're working on the font, MFEKglif will probably be open most of the time.

MFEKstroke is an interesting example because it's in between. The user needs to fill out a form, yes, the stroke parameters &mdash; but she also needs to see what the glyph will look like with the parameters, and tweak them to her heart's content to get the best output. However, once parameters are chosen, it becomes almost pure form. It is both form and canvas, as is MFEKinterpolate. MFEKopentype and MFEKkern, meanwhile, have some form elements, but are more canvas than form.

Most of our IPC can just be `system` calls (launching new processes). At our most advanced, we watch a file or directory for changes and reconcile accordingly.

Let's consider we want to make a cursive font. Here is how we would proceed, according to my vision:

* Run MFEKmetadata. When it gets no argument, or the argument of a non-existent directory, it assumes we want a new font. So, we fill out a form.
* We then run MFEKfontview and see empty squares. Clicking `A` launches MFEKglif with the command line `MFEKglif glyphs/A_.glif`.
  * MFEKglif calls MFEKmetadata as `MFEKmetadata metrics`. MFEKmetadata returns on stdout the em-size, ascender, descender, and x-height and cap-height if known based on the UFO metadata. MFEKglif draws guidelines.
* We start drawing our `A`. We decide to make it a single stroke. We press Ctrl-Shift-E, and MFEKglif launches MFEKstroke, saves the state of the glyph in the undoes list, and begins monitoring `A_.glif` for changes.
* MFEKstroke, likewise, monitors `A_.glif`. If written out, it changes its display. Perhaps auto-saving of every action can be optionally considered. How daring are we? Will our `.glif` file's `<lib>` contain undoes? Perhaps!
* The user settles on a stroke and presses Stroke. MFEKstroke writes and exits. MFEKglif dutifully reads from the disk.
* And so on for the basic Latin. It's come time to add an OpenType table. Launch `MFEKopentype`, which will build the font and use HarfBuzz to display it, and auto-update as the user writes their OpenType Layout code. This could be FEA, but it also could be Simon Cozens' FEE, an extended FEA syntax. MFEKopentype must be more conservative and only reload the font upon saving of any glyph, not every small action in MFEKglif.
* Finally, we have something we think servicable. In MFEKfontview we press Generate, which calls MFEKexport. We're not writing a TrueType generator here, it's a simple form that calls `fontmake` with appropriate arguments.

Notice that while MFEK grows in size, we can offload one or more steps to FontForge/`fontmake` scripts. So even with only one or two programs, MFEK is immediately useful&mdash;we don't need the entire thing done to start using it in production. In fact, I plan to make fonts while I work on MFEK, and use less and less of FontForge over time.

But our goal is not to totally abandon FontForge, or AFDKO, or fontmake. No, rather, we want a new GUI. But to build our modular font editor, we'll take the good parts out of everything. FontForge is great at dealing with legacy formats: we can imagine a MFEKconvert based on a C library sourced from FontForge code, which calls either that, fontmake, or AFDKO, based on the type of conversion requested.

## Thanks to…

* Matthew Blanchard;
* Caleb Maclennan;
* Eli Heuer;
* Georg Duffner (for EB Garamond ExtraBold, used in our logo);
* All organization members and module authors and contributors!
* All developers of open source font software and fonts!

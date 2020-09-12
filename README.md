[**This project has nothing to do with QAnon and I oppose QAnon completely.**](https://github.com/mfeq/mfeq/blob/master/doc/QAnon.md)

# Modular Font Editor Q

**Modular Font Editor Q** (MFEQ) is an open source modular font editor. It attempts to apply the Unix adage that each program should do one thing and do it well to a GUI font editor.

MFEQ is still very alpha, and many parts are missing. You can help!

**[Why MFEQ?](https://github.com/mfeq/mfeq/blob/master/doc/Why.md)**

## Modular programs

* [`Qglif`](https://github.com/mfeq/Qglif) (.glif editor w/Spiro support)
* [`Qmetadata`](https://github.com/mfeq/Qmetadata) (UFO metadata querier)
  * <sub><sup>(Right now only helps draw ascender/descender in Qglif.)</sup></sub>


### Planned

* `Qdesignspace` (design space XML creator/editor)
* `Qtransform` (transform, skew glyphs w/CLI options / GUI)
* `Qfontview` (a launcher for Qglif that displays all glyphs)
* `Qinterpolate` (an interpolation confirmer / tester)
* `Qkern` (kerning editor)
* `Qmetrics` (load UFO file into HarfBuzz and output typed text)
* `Qstroke` (use @skef's work to stroke glyphs provided on command line)
* `Qopentype` (OpenType layout editor based on @simoncozens' ideas)
* `Qexport` (frontend to fontmake)

## Libraries

* [libglifparser](https://github.com/mfeq/glifparser) (a .glif parser)
  * <sub><sup>(We need this because Norad has no support for `<lib>` in `.glif` files, and due to how they went about implementing Norad, fixing that is trickier than having my own glyph parser. Furthermore, as I plan to support Spiro, B-Splines, etc., through UFO format extensions, I should have one anyway.)</sup></sub>
* [MFEQ Norad](https://github.com/mfeq/norad) (general UFO parser based on upstream Norad tweaked to play nice with `libglifparser`)
* [MFEQ IPC](https://github.com/mfeq/norad) (_very_ basic inter-process communication functions)

### Planned

* libskef (port of @skef's &laquo;Expand Stroke&raquo; feature to a reusable C API)
* spiro-rs (port of libspiro to Rust, probably will be done via `bindgen`)

# Flow

MFEQ's inter-process communication (IPC) will be minimal. UFO is the format, and most of the time, MFEQ modules are going to be starting with just what's on the disk. We can put the planned MFEQ modules onto a linear spectrum between _forms_ and _canvases_. The quintessential form is Qdesignspace: it is purely a form. The user inputs the names of their UFO masters, their axes, instances, and rules, and out comes a rigidly hierarchical `.designspace` file for consumption by `fontmake` and Qinterpolate. As a form, once it's filled out, it's done. We may need to go back and add more rules or instances or what have you, but it's essentially one run and done. Meanwhile, the quintessential canvas is Qglif: the user draws their glyphs and can spend as long as they want doing so, and will likely have multiple Qglif instances running in parallel. As long as you're working on the font, Qglif will probably be open most of the time.

Qstroke is an interesting example because it's in between. The user needs to fill out a form, yes, the stroke parameters &mdash; but she also needs to see what the glyph will look like with the parameters, and tweak them to her heart's content to get the best output. However, once parameters are chosen, it becomes almost pure form. It is both form and canvas, as is Qinterpolate. Qopentype and Qkern, meanwhile, have some form elements, but are more canvas than form.

Most of our IPC can just be `system` calls (launching new processes). At our most advanced, we watch a file or directory for changes and reconcile accordingly.

Let's consider we want to make a cursive font. Here is how we would proceed, according to my vision:

* Run Qmetadata. When it gets no argument, or the argument of a non-existent directory, it assumes we want a new font. So, we fill out a form.
* We then run Qfontview and see empty squares. Clicking `A` launches Qglif with the command line `Qglif glyphs/A_.glif`.
  * Qglif calls Qmetadata as `Qmetadata metrics`. Qmetadata returns on stdout the em-size, ascender, descender, and x-height and cap-height if known based on the UFO metadata. Qglif draws guidelines.
* We start drawing our `A`. We decide to make it a single stroke. We press Ctrl-Shift-E, and Qglif launches Qstroke, saves the state of the glyph in the undoes list, and begins monitoring `A_.glif` for changes.
* Qstroke, likewise, monitors `A_.glif`. If written out, it changes its display. Perhaps auto-saving of every action can be optionally considered. How daring are we? Will our `.glif` file's `<lib>` contain undoes? Perhaps!
* The user settles on a stroke and presses Stroke. Qstroke writes and exits. Qglif dutifully reads from the disk.
* And so on for the basic Latin. It's come time to add an OpenType table. Launch `Qopentype`, which will build the font and use HarfBuzz to display it, and auto-update as the user writes their OpenType Layout code. This could be FEA, but it also could be Simon Cozens' FEE, an extended FEA syntax. Qopentype must be more conservative and only reload the font upon saving of any glyph, not every small action in Qglif.
* Finally, we have something we think servicable. In Qfontview we press Generate, which calls Qexport. We're not writing a TrueType generator here, it's a simple form that calls `fontmake` with appropriate arguments.

Notice that while MFEQ grows in size, we can offload one or more steps to FontForge/`fontmake` scripts. So even with only one or two programs, MFEQ is immediately useful&mdash;we don't need the entire thing done to start using it in production. In fact, I plan to make fonts while I work on MFEQ, and use less and less of FontForge over time.

But our goal is not to totally abandon FontForge, or AFDKO, or fontmake. No, rather, we want a new GUI. But to build our modular font editor, we'll take the good parts out of everything. FontForge is great at dealing with legacy formats: we can imagine a Qconvert based on a C library sourced from FontForge code, which calls either that, fontmake, or AFDKO, based on the type of conversion requested.

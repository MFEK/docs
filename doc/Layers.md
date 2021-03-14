# MFEKglif: towards layers and history

Layers were particularly difficult to add to MFEKglif because of the way the UFO standard handles layers. However, I think I finally have an implementation model that will work, for both the definition of layers and the definition of history (undoes and redoes).

## Layers in the UFO standard

In the UFO standard, each `.glif` file is a layer unto itself. The `glyphs` directory actually refers to the "Foreground" ("Fore") layer in FontForge, and the UFO standard dictates that _new_ `glyphs` directories ought to be made for each of the layers in the font according to the data in `<UFO root>/layercontents.plist`. For example:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN"
"http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<array>
  <array>
    <string>public.default</string>
    <string>glyphs</string>
  </array>
  <array>
    <string>Sketches</string>
    <string>glyphs.S_ketches</string>
  </array>
  <array>
    <string>public.background</string>
    <string>glyphs.public.background</string>
  </array>
</array>
</plist>
```

would refer to a UFO font with three glyphs directories in the root: `glyphs`, `glyphs.S_ketches`, and `glyphs.public.background`.

There are only two defined layer keys in the standard (though all beginning in `public.` are reserved): `public.default`, for `glyphs`, and `public.background`, for the Background layer found in many font editors.

Layer properties are defined _inside_ the `glyphs` directories in `layerinfo.plist` files. In UFO3, only `color` is reserved. Example:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>color</key>
    <string>0,1,1,0.7</string>
  </dict>
</plist>
```

Besides this, a `lib` `<key>` can contain font editor-specific data.

## Layers in MFEKglif

This way of doing things will not work well for MFEKglif. For one thing, `.glif` files can be unattached and not always part of a parent UFO. Therefore, we need our own layers format. Layers are how they are in the UFO standard because UFO is expected to be used to generate OpenType fonts, and in the OpenType format, each output layer is defined as a specific glyph. For example, in an emoji font with two colors, you'd have for example `Yellow`, `Black`, `White` and `Red`. Then, from `glyphs.Y_ellow`, `glyphs.B_lack`, etc., the OpenType font would actually have four glyphs for each defined glyph in the font editor.

So, I think the best way to handle this is much like we've already done by having `MFEKstroke` convert a variable width stroked (VWS) path into a normal `.glif` `<outline>` of `<contour>`'s. I've come up with a format which will use the `<lib>` for holding the other layers, and then have a program which will make the actually `fontmake`-compilable UFO with `glyphs` directories for each layer. I call making the `fontmake`-compilable UFO “Reconciliaton” (see § Reconciliation).

MFEKglif already can detect if it is being called with the path to a detached `.glif` file or a `.glif` file inside of a `glyphs` directory in a parent UFO. It should further make sure that it is always either being run on one of these two, and not a glyph layer created by other software, which could cause all sorts of collission issues. If the user tries to run e.g. `MFEKglif A.ufo/glyphs.public.background/A_.glif`, MFEKglif should refuse to do that and exit non-0.

## MFEKglif's format

On startup, the first thing is to immediately figure out which contours are in each layer. All of the contours outside of the `<lib>` are part of the mandatory `Foreground` layer, and a glyph file cannot have zero layers.

The `<lib>` section will have a new element called `<gliflayers>` which will contain `<gliflayer>` elements which may contain any number of `<contour>`, `<anchor>`, and `<image>` elements.

The order of the `<gliflayer>` elements is important, and defines the render Z-order.  Earlier layers are rendered above later layers.

### `<gliflayer>` attributes

1. `name` ⇒ **String**: Display name of the layer. Must be unique.
2. `outputtable` ⇒ **Boolean**: Whether this layer should be output during reconciliation. User should have control of this, default to `false`.
3. `color` _(optional)_ ⇒ **32-bit unsigned integer**: The color of the contours in the layer. One byte each for R, G, B, and A.
4. `dirname` ⇒ **fn() -> String**: Hidden from the user. Generates by concatenating the string `glyphs.MFEKglif.` plus the `name` with its capital letters followed by underscores. So, for `Sketches`, `dirname` is `glyphs.MFEKglif.S_ketches`. However, for the layer with `mandatory` set to `true` it is always `public.default`.
5. `mandatory` ⇒ **Boolean**: Only `true` for a single layer, the default (but renamable) `Foreground`.

## History

The `<lib>` section will have a `<histories>` section containing a `<history>` for each layer. `<history>` will have a `layer` attribute equal to the `dirname`, one `<history>` per layer. (This is for human readability, the `<history>` elements are in the same order as the `<gliflayer>`'s.) `<history>` contains any number of `<gliflayer>`'s. The first `<gliflayer>` is the most recent revision, working backwards. `<history>` has an attribute `redoes`, which is an unsigned integer representing the number of following `<gliflayer>` elements which are actually forward in time, but have been undone by the user. It should usually be `0`, only appearing when the user undoes an action and then saves without doing any other action which would cause redoes to be lost.

## Reconciliation

It is a fact that most of the time this system will work just fine and users will not care if their non-`Foreground` layers get written, because they are for prototyping/storage of images and not for writing into the final font.

However, with the increasing importance of color fonts, it is important to have a program which can split our `.glif` format into the standard `.glif` format. This program should receive a `.ufo` directory as an argument, and not be called by MFEKglif itself, even via IPC, but in future by MFEKufo (the font overview program I envision which will pop MFEKglif instances when users open glyphs just by calling `system`).

So, given a UFO directory, the reconciliation process is such:

1. Read in `<UFO root>/layercontents.plist`. Determine what layers are already defined for this UFO.
2. If non-`public.default` layers are defined, iterate through all of their glyphs and make sure that none of them are ones that we would split. (None of them contain `<glyphlayers>` in `<lib>`.) If they do, print a helpful message and return non-0. (The user likely got into this situation because they thought they could get around MFEKglif refusing to edit another software's layer by just moving files around, not understanding the clobbering issue.)
3. In the `glyphs` (`public.default`) directory, figure out all the unique `outputtable` `dirname`'s requested. For example, one glyph in a color (emoji) font might have a `Blue` layer, while another one might have a `Red` but no `Blue`.
4. Make sure that there is no mismatch between `outputtable` for a given `dirname`. If there is, tell the user and return non-0. (Example message: “Layer Blue in glyph ‹A› is set as "do not output", but layer Blue in glyph ‹a› is set to "output". Cannot continue, please fix the layer properties in MFEKglif.”)
5. Create empty directories for all the `dirname`'s.
6. Using the `<gliflayer>` `color` attribute, write out a `layerinfo.plist` for the list of `dirname`'s. If there's no color set, write an empty `layerinfo.plist`.
7. Copy `contents.plist`.
8. For each `dirname`, open each glyph in `glyphs` and determine if it has the current `dirname` in its `gliflayers`. If it does, copy the contents of its `<gliflayer>` into a new `.glif` file with those contents in the document root as normal. _If there is no `dirname` in `gliflayers`_, write an empty `.glif`.

## Wrapping up: a note on images

The UFO standard [reads](https://unifiedfontobject.org/versions/ufo3/glyphs/glif/#image)…

> ### image: An image reference.↩
> 
> This optional element represents an image element in a glyph. It may occur at most once.

We're ignoring this. We'll put as many images as we please in a `.glif`. The reason it's like this is because it is actually possible to store images in an OpenType font, and again, UFO is mostly focused on creating OpenType fonts from XML data.

At the time of reconciliation, we can warn the user that subsequent images will either be ignored or can cause errors in some software. But, there's no reason for this arbitrary limitation for a font editor; indeed it's useful to have multiple images in one layer at times.
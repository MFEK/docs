# Why?
### Why MFEK?

My [Modular Font Editor K](https://github.com/MFEK/docs) project, despite its roadmap, has mystified
some. Why work on it at all, and if I insist, why not work on the Runebender project?

I aim to explain myself.

Many have tried to replace FontForge&mdash;all have failed. I might fail, in fact, history says I
probably will. Yet, the current state of affairs is so bad I feel I must try.

# Updates to the status quo since this was written
(Update May 2021: _This prospectus of the project was written in September 2020. Since then some
things have changed, including the degree to which we collaborate with the Runebender project; while
we don't contribute to Runebender itself, we do contribute to a few of its libraries like `kurbo`
and `norad`._)

(Update November 2021: _Our collaboration with the Rust ecosystem mentioned earlier in the year has
continued thankfully, and `norad`, `flo_curves` and other crates have even made changes with our
project in mind._ ♥)

# Why we need a new free software font editor
Progress on FontForge has ground to a halt, and often I felt I was the only one interested in
continuing to make progress. It's not hard to understand why this has happened. Maintaining
FontForge is _hard_. Adding new features to it is harder. It is written in a language fewer and
fewer people know and requires C skills fewer and fewer people have.

Many of FontForge's problems are technical: the biggest difficulty is UI. It uses a custom toolkit,
which despite earnest attempts, I highly doubt it's ever going anywhere. Getting anything done in it
is very difficult and sometmimes nigh impossible.

This is not where the custom code ends. It has custom code for reading and writing fonts, parsing
feature file syntax, stroking paths, building OpenType layout, and even _rendering text_. The
MetricsView as we call it does not show the output of HarfBuzz; indeed, by default, it doesn't even
rasterize with FreeType, but uses a custom rasterizer.

All of the custom undocumented code is so vexing as to lead one to despair. The man who understood
it all is gone, and as reading undocumented code is so much harder than writing it, we are in a
state of deadlock.

Some of the other problems are social. I admit that at the beginning of my becoming more active on
the FontForge bug tracker I was unaccustomed to being in such a role; as I made more and more
contributions my voice suddenly became not just my opinion but authoritative. We had a contentious
battle on the FontForge tracker over licensing and the meaning of the headers in most files, which
alienated a contributor who had previously done a lot. Sometimes I still think they're mad at me: I
won't mention who but I'm sorry to them and won't be pushing further on a relicensing, though
obviously I'm not in a position to tell the owners of the repository what they ought to do.

Another big problem that a new project doesn't face is dealing with legacy code. We can't just start
ripping all the custom stuff out of FontForge. We will break people's workflows, build scripts, and
fonts. I can't rip out the MetricsView and replace it with HarfBuzz as much as I'd like to: people
probably rely on its output. So, what, we should maintain two ways of showing the user how their
font will look? That will make maintainership harder, not easier.

Let me give you an example: COLR/CPAL, an emoji (color) font format. I was so ready to work on this.
But working on it is going to be a nightmare. ~~I'm still willing to do it for pay of course, but~~
The UI elements alone are trying.  Then we get into the fact that FontForge uses its own custom
rasterizer to generate glyphs in the FontView, and so that needs either a total rewrite, or a
replacement with FreeType. It of course doesn't support color or layering. So am I to integrate a
library, or for some reason write a color font rasterizer when many exist? And let's not even get
into all the UI niggles in the CharView this will introduce; we don't use Skia but rather just call
random Cairo commands. Oh, and there's also a non-Cairo version of the CharView, which must not be
broken without possible conflict as if we deprecate building _sans_ Cairo this will break someone's
build!

# Why Runebender is not the new free software font editor we need (in my opinion)

First of all, I have no problem with authors of Runebender and wish them all the success in the
world. This success however has not come yet, FontForge remains dominant. At the time I founded the
MFEK project, Runebender had no commits to it for two months. I was told that actually commits are
happening ... to the UI layer of Runebender. Incredibly, Runebender has an entirely new UI toolkit,
their version of FontForge's GDraw (hopefully without any of its flaws), they call it Druid. That's
not all, they also have an entirely new path rasterizer, called Piet.

In fact, Runebender is another hive of custom code everywhere, for reasons I do not find logical.
[As I've written in the past, regarding
Alacritty,](https://gist.github.com/ctrlcctrlv/978b3ee4f55d4b4ec415a985e01cb1c9) which was a highly
controversial blog post, Rust projects overly aim towards perfect code. I reject this philosophy.

[At the time, I replied to criticism of me on
Reddit](https://www.reddit.com/r/rust/comments/ewgczz/rust_maintainer_perfectionism_or_the_tragedy_of/)
thus:

> > I don't think it's surprising that people who make hobby projects in a language that has
> > correctness as a core design goal would have an attitude of wanting to assure correctness, even
> > at the cost of development velocity. Not everyone wants to move fast and break things.
>
> Sure, that's certainly one way to look at it. It helps to remember though that correctness isn't
> free, and isn't a feature of the language, (although features of the language help create more
> correct programs,) but is in its higher forms, once the Rust compiler and borrow checker are happy
> with the code, highly subjective.

I don't think it's a big problem to use C(++) in Rust. I don't really know that I agree with the
philosophy that a Rust application should be _entirely_ Rust.  For me one of the benefits of Rust is
that I can quickly and safely wrap popular C APIs. I benefit from the work Google puts into Chromium
by using Skia. I benefit from the huge user community of Dear Imgui, including such illustrious
software as SHADERed.

There simply are not enough hours in the day for me to write a font editor, _and_ a GUI toolkit,
_and_ a path rasterizer, and keep those things well maintained while working on my font editor. But,
@raphlinus and @cymr are much better programmers than me, so maybe they can do it. Let's see, I
guess.

That is to say, Rust is the perfect tool for the job, it's the Rust users that are the trouble. ;-)

But, more than this, I've decided that the entire way we're going about this problem is wrong. We
think there should be one program called "font editor", in this case Runebender, and it should do
everything that Glyphsapp does on Apple, and that's that. And so, until "font editor" is production
ready, it's useless in real world fonts. So, no one uses it in their projects, and there's no
_practical_ reason to continue developing it besides hobby, there's no font that you can't make
today that you can make because "font editor" exists. I know of no popular open source font in which
Runebender played a significant, or any, role in its development. 

So let's look at where we really stand in the world of open source fonts. We stand in a fragmented
landscape, and people keep coming along with _massive_ projects &mdash; TruFont, Runebender &mdash;
to unify this fragmented landscape, and failing. Meanwhile, as FontForge can do less and less of
what we need in modern fonts (emoji fonts, `rand` feature, OpenType Variations), we get more and
more fragmented, and "font editor" needs to do more and more.

So, "font editor" is just becoming proprietary, Glyphsapp. _This is intolerable._ Open source fonts
should not need proprietary software to build. Glyphsapp is very powerful which is why it is
dangerous. And can we blame its users? I can't.

I made a modern font recently, [Noto Sans Tagalog](https://github.com/ctrlcctrlv/Noto-Sans-Tagalog)
v3. (Disclosure: Project financially supported by Google. No one at Google or Google itself
necessarily agrees with my views on font editors, obviously.) And all the flaws of FontForge came
tumbling out. Its custom auto-hinter is basically useless, only supports PostScript when industry
best practice is TTF hints, so that needs to be disabled.

So what did I do here? I used FontForge just to draw my glyphs. I wrote a designspace XML file. I
wrote a script which called on ttfautohint to do the industry best practice hinting. I used fontmake
to smush it all together. I built my modern font only in free software, a fact of which I am proud,
but also sad at how hard it was.

But I also see opportunity. We need a solution that uses the benefits of open source software
instead of its weaknesses. So, I propose, we need a modular solution, not a monolith. We don't need
"font editor". What we need are ways to test a UFO font with a nice UI, to write OpenType Layout
code, to draw glyphs. We need font editor**s**, that is to say, modular interoperable programs,
interoperable also with Glyphs and FontForge via the UFO format, each program doing one job, and
some day, hopefully, we will have enough programs that we no longer need FontForge, but only some
parts of it I and others will be splitting off into C libraries.

We instead of fighting futilely the fragmentation, embrace it. We embrace that font editing is not
one skill: it's many skills and tasks. There's no real reason the program that's doing the
auto-hinting needs to be doing the kerning and generating the OpenType tables. The UFO paradigm is
at the end of the day _correct_, we just need a full throated embrace of it. We need to stop writing
"font editor" and start writing font editors.

[See the roadmap.](https://github.com/mfeq/mfeq/#planned-modules)

----

Fred Brennan

3 September 2020

<!-- vim: textwidth=100
-->

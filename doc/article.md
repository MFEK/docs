![sample](https://user-images.githubusercontent.com/310356/111370352-7f961980-866e-11eb-9efd-ea3c0a8de3da.png)

https://www.youtube.com/watch?v=JDKT5HZ0qvs

Check out Fredrick's youtube for a live demonstration!

# Variable Width Stroking

I spent a good deal of time over the last month and change trying to put together a variable width stroker. I had a few objectives in mind:

* Realtime
* Stable (inputs close to each other should give visually similar results)
* Easy to Use

The first thing I did was look for existing implementations and documentation on how others have accomplished this. I took a look through Inkscape's Powerstroke implementation,
and a found an implementation in R which ended up coming in handy later, but wasn't hugely helpful as I could not make heads or tail of R. There didn't seem to be a good place that
layed out the process in a language I knew or a blog post, so I'm going to walk you through it here.

## Overview

Here's a really stripped down overview of the overall procedure.

```python
    contour = [bezier1, bezier2, ...]
    left_collection = []
    right_collection = []

    for bezier in contour
        # we'll discuss offset below
        left_bezier = offset(bezier, |t| -> normal_offset, |t| -> tangent_offset)
        right_bezier = offset(bezier, |t| -> normal_offset, |t| -> tangent_offset))

        left_collection.push(left_bezier)
        right_collection.push(right_bezier)


    flipped_right = map(flip_bezier, right_collection).reverse()
    merged_collection = glyph_builder(left_collection)

    # we'll be talking about cap_to below
    merged_collection.cap_to(flipped_right.first().first_point())
    merged_collection.append(flipped_right)
    merged_collection.cap_to(merged_collection.first().first_point())

    # discussed in Mind the gap!
    merged_collection.fix_path()
    glyph = merged_collection.build()
  
```

## Offsetting the curves

One of the main problems you have to deal with for a good VWS implementation is offsetting your curves. For my application I wanted to be able to specify an offset at the start and end of the bezier curve.

In my search I found a library called flo_curves: https://github.com/Logicalshift/flo_curves and it had an offset implementation in the language I was already using!
It also provided high quality primitives for things like Points, Lines and Bezier curves. I'm going to describe the broad strokes of how the offset function we use from flo_curves works here.

![base_curve](https://user-images.githubusercontent.com/310356/111370342-7efd8300-866e-11eb-8365-c930d8bd042f.PNG)

### Splitting at features

The first step of this algorithm is to split the curves at loops and cusps. This paper cited in Flo_curves source code explains how to find these features far better than I ever could: https://graphics.pixar.com/people/derose/publications/CubicClassification/paper.pdf

![split_curve](https://user-images.githubusercontent.com/310356/111370339-7e64ec80-866e-11eb-827a-239e0a57ca1d.PNG)

### Sampling the curve

The next part of the algorithm is pretty easy. For each of the curves from the split you're going to to sample it an arbitrary amount of times, and then offset the samples.

You're going to want to evaluate the bezier at the given time t, and calculate the normalized tangent and perpendicular directions at that point. 

![sampled_curve](https://user-images.githubusercontent.com/310356/111370341-7e64ec80-866e-11eb-9fb3-aa9ba51cd0e3.PNG)

Here our normal is in light blue, and tangent in light green.

*BEWARE*, a very common pitfall with getting tangents and normals with bezier curves is that curves with colocated handles have strange curvatures as t approaches 0 and 1. This can be solved by simply offsetting your evaluations by f64::epsilon and -f64::epsilon when t == 0 or 1 respectively.

For each sample point you're going to offset along the normal by how thick you want that side of the stroke to be, and you're going to offset along the tangent to change the 'angle of the stroke'. I'll explain how you calculate the tangent offset later in this document.

![sampled_offset_curve](https://user-images.githubusercontent.com/310356/111461613-cda13080-86f3-11eb-90cb-70bad2bf6f7e.PNG)

### Fitting a curve to the samples

After you've sampled the curve and offset those samples you're going to fit a curve to those sampled points. The algorithm used in flo_curves is Philip J Schnieder's from Graphic Gems 1990. 

This stack overflow thread has implementations in both C and C#: https://stackoverflow.com/questions/5525665/smoothing-a-hand-drawn-curve

![fit_curve](https://user-images.githubusercontent.com/310356/111370347-7efd8300-866e-11eb-97bb-f49b6b234add.PNG)

## Mind the gaps!

![discontinuity](https://user-images.githubusercontent.com/310356/111370345-7efd8300-866e-11eb-9617-342bc4c3b0b3.PNG)

The end of one bezier and the start of the next isn't always going to line up, especially at corners close to 90 degrees. We're gonna end up with a gap. You can identify these by looping through each bezier and checking if it's end point matches the next's start point. IF it's within some small amount (I used 0.001) then you merge the two. If not you generate a join. There's a few types of caps and I'm gonna go over how I solved each.

### Bevel

![bevel](https://user-images.githubusercontent.com/310356/111370343-7efd8300-866e-11eb-9449-f30656a65811.PNG)

Create a line from the end of the last bazier to the beginning of the next one. This is the trivial case.

### Miter

![miter-join](https://user-images.githubusercontent.com/310356/111370350-7f961980-866e-11eb-8c8c-de9f4fd74055.PNG)

For a miter join you're gonna want to shoot rays from the start/end of the lines in the direction of their tangent. You will have to flip one so they're both heading the same direction. The point at which these two rays intersect is the point of your miter. You then just line to that point and then the start of the next bezier. You'll probably want to put a reasonable limit on miter and if the intersection is X units away default to a bevel. You could also leave this limit to the user.

### Round

![round_join](https://user-images.githubusercontent.com/310356/111375167-54162d80-8674-11eb-929c-b16904649d24.PNG)

This one is a bit more complicated. You can find the perfect ellipse segment that runs through both points like Inkscape's implementation, but while searching for a solution for this one I found a method that's almost as simple as a miter join and gives perfectly serviceable results.

You find the intersection point just like a miter join, and then you employ this piece of psuedo-code magic:

```python

#if there's no intersection radius is equal to 2/3 the disntance from from to to.
radius = distance(from, to) * (2/3)

#if there is an intersection then radius is equal to the minimum distance from either of our points to the intersection
min(distance(from, intersection), distance(to, intersection))

angle = acos(dot(from, to))
dist_along_tangent = radius*(4/(3*(1/cos(angle/2) + 1)))
arc = Bezier.from_points(
    from,
    from + from_tangent * dist_along_tangents,
    to + to_tangent * dist_along_tangents,
    to
)
```

I didn't come up with this, but I genuinely can not find the source of it. The ratio in dist_along_tangents gives really decent ellipse segments for most inputs. The only issue this method has is at extreme angles where the intersection is far into the distance. For these cases I check how far the intersection is from the midpoint of from and to. If it's distance is greater than the distance to from from to (I am so sorry) we discard it. 

### Inside joins

When the bezier curves overlap instead of failing to meet you're going to want to fall back to a bezel. We rely on a Skia Simplify call to remove internal geometry, but you could do so by clipping the beziers where they intersect. I think this would be a fair bit slower in some cases though as you would need to backtrack along the path looking for intersections.

## Put a cap on it

![cap](https://user-images.githubusercontent.com/310356/111393770-ca745900-868f-11eb-9276-a33c15c60e2a.PNG)

We've offset all of our curves and collected them into left and right collections. The next thing we need to do is stitch them up into one closed contour. If we're stroking a closed contour we can skip this step and just output the left and right sides as seperate contours since they are already closed.

If we've got an open contour closing it is actually really easy. You can literally use the exact procedure used for Round joins for Round caps. Butt and Square are trivial.

## Getting angular with the editor

Finding the normal offset for a given mouse postion from a VWS control handle is easy. It's the dot product of the normal and the mouse position both in coordinates relative to the vws control point.

Where things get a bit trickier is the tangent offset. You could do the same as you're doing for the normal, but you're going to end up with weird lopsided handles on your VWS ribs!

![unaligned](https://user-images.githubusercontent.com/310356/111393779-cea07680-868f-11eb-85be-39ca08445fc2.PNG)

You can fix this issue by scaling the shorter side's tangent offset like this:

![aligned](https://user-images.githubusercontent.com/310356/111393781-cfd1a380-868f-11eb-99d3-f2d03b34ea31.PNG)
```
scaled_tangent_offset = short_handle/max(left_offset, right_offset)
final_tangent = tangent * vws_handle.tangent_offset * scaled_tangent_offset
```
## Offset closures

I very much glossed over the contents of the closures in the outline above. Those closures take time t and return a normal or tangent offset respectively.

The thing is if you just give ever yvws handle an offset and lerp between those you're gonna end up with pretty heavy discontinuities where they meet.

I highly suggest you use either cosine or cubic interpolation within those functions. Cosine is easy to implement and pretty much eliminates the problem.

## Wrapping up

There's more I could cover here, but I think I gave a pretty good overview on how this is accomplished. Big thanks to Logicalshift for his awesome library. Thanks to Fredrick for giving me the time to work on such a cool problem. I was bussing tables only a few months ago and he gave me a great opportunity. Thanks to coolfontguy69 for suggesting the tangent offsets.
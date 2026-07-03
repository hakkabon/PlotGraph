# PlotGraph — Methodology

This document describes the two non-obvious algorithms in `PlotGraph`: how
"nice" axis tick spacing is chosen, and how data coordinates are mapped to
screen coordinates. It's the rendering analogue of
[`DataFitting`'s METHODOLOGY.md](https://github.com/hakkabon/DataFitting) —
there's no statistical fitting here, just coordinate geometry.

## 1. "Nice numbers" axis tick selection (`PlotRange.swift`)

Given a data range `[minPoint, maxPoint]`, naively dividing it into, say, 10
ticks produces awkward spacing like `7.3, 14.6, 21.9, ...`. `PlotRange`
instead implements the well-known **"nice numbers for graph labels"**
algorithm (originally described by Paul Heckbert, *Graphics Gems*, 1990):
round the tick spacing to the nearest of `{1, 2, 5, 10} × 10ⁿ`, then snap the
axis endpoints outward to multiples of that spacing.

**Step 1 — rough tick spacing.** Divide the raw span by the desired number
of ticks (`maxTicks`, default 10) to get a rough spacing, then round it to a
"nice" number using `approximate(x:round:)`:

```
exponent = floor(log10(x))
f        = x / 10^exponent        // fractional part, in [1, 10)
```

`f` is then snapped to the nearest of `1, 2, 5, 10` (using slightly
different thresholds depending on whether you're rounding the *span itself*
— `round: false`, which takes the *ceiling* candidate so the axis is never
narrower than the data — or rounding the *tick delta* — `round: true`, which
rounds to the *nearest* candidate for cleaner-looking numbers):

```
round: false (ceiling)   f ≤ 1 → 1,  f ≤ 2 → 2,  f ≤ 5 → 5,  else → 10
round: true  (nearest)   f < 1.5 → 1, f < 3 → 2, f < 7 → 5,  else → 10
```

**Step 2 — snap the endpoints.** With a nice `delta`, the axis min/max are
snapped outward (never inward — the axis always fully contains the data):

```
min = floor(minPoint / delta) * delta
max = ceil(maxPoint / delta) * delta
```

For example, data spanning `[3, 94]` with `maxTicks = 10` yields a rough
delta of `~10.1`, which rounds to `10`; the axis then snaps to `[0, 100]`
with ticks at `0, 10, 20, ..., 100`.

**Degenerate case.** If `minPoint == maxPoint` (a single value or perfectly
flat series), the raw span is `0`, and `log10(0)` is `-∞` — left
unguarded, this propagates `NaN` through the rest of the calculation. The
fixed version in this package substitutes a span of `1` in that case so a
flat series still gets a sensible (if arbitrary) axis range instead of
producing `NaN` ticks.

## 2. Data-to-screen coordinate transform (`PlotView.setTransform(for:)`)

`PlotView` draws everything — axis lines, gridlines, tick marks, data
points, and connecting lines — through a single `CGAffineTransform` that
maps a data-space point `(x, y)` to a screen-space point, computed once per
series via `setTransform(for:)` and reused for every draw call
(`p.applying(t)`).

**Scale.** The plot area is the view's bounds minus `insets` on each side.
The scale factor per axis is:

```
scale.x = plotAreaWidth  / dataRange.x
scale.y = plotAreaHeight / dataRange.y
```

**Flip.** Screen coordinates grow downward, but chart y-values grow upward,
so the transform's `d` component is `-scale.y` (a vertical flip) —
equivalent to reflecting the y-axis before scaling.

**Translation.** The transform's `tx`/`ty` position the data's minimum
point (`minX`, `minY`) at the plot area's bottom-left corner (accounting for
the flip):

```
tx = insets.left - (minX / dataRange.x) * plotAreaWidth
ty = insets.top + plotAreaHeight + (minY / dataRange.y) * plotAreaHeight
```

Put together, the full transform is:

```
CGAffineTransform(a: scale.x, b: 0, c: 0, d: -scale.y, tx: tx, ty: ty)
```

which is the standard 2D affine transform matrix

```
| a  b  0 |     | scale.x    0       0 |
| c  d  0 |  =  |    0    -scale.y   0 |
| tx ty 1 |     |   tx       ty      1 |
```

applied as `screen = (x·a + y·c + tx, x·b + y·d + ty)` — i.e. independent
scale-and-flip per axis, then translate.

**Important caveat.** This transform is computed once, from the *first*
plotted series' range (`plotObjects[0]`), and reused for every subsequent
series (see `layoutSubviews()`, which contains the comment *"This is
problematic if several unrelated plot objects are plotted"*). If you plot
multiple series with meaningfully different data ranges, only the first
series' range fully fits the visible axes; later series will be scaled and
positioned using axes sized for the first series, and may be clipped or
appear compressed. Setting `min`/`max` explicitly to a range that covers
all your series before plotting is the current workaround (see the main
README).

## 3. Point markers (`CGPath+Extensions.swift`)

Non-circular/square markers (`triangle`, `prism`, `star`) are drawn as
regular polygons inscribed in the marker's bounding rect, using the
standard parametric construction: for `n` sides, points are placed at
angles `k · (2π/n)` for `k = 0, 1, ..., n-1` around the center, at radius
`rect.width / 2`, starting from the top (12 o'clock) and proceeding
clockwise (`sin` for x, `cos` for y — note this is swapped from the usual
trigonometric convention because the starting angle is measured from the
top rather than from the positive x-axis). `triangle` (3 sides) and `prism`
(4 sides, i.e. a diamond) are the same construction with a different side
count; `star` uses a similar but distinct construction for a 5-pointed star
(connecting every second vertex of a regular pentagon, the standard
{5/2} star-polygon construction).

# PlotGraph

A lightweight `UIView`-based XY chart renderer for iOS. Given one or more
series of `(x, y)` points, it draws axes with automatically-chosen "nice"
tick spacing, gridlines, connecting lines, and per-point markers (circles,
crosses, squares, triangles, stars, "prisms").

This is a rendering library, not a fitting/statistics library — pair it with
[`DataFitting`](https://github.com/hakkabon/DataFitting) if you want to plot
a regression, LOESS, or kernel-smoothed curve alongside raw data (fit first
with `DataFitting`, then hand the resulting points to `PlotGraph`).

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/hakkabon/PlotGraph.git", from: "1.0.1"),
]
```

Requires iOS (UIKit). This is not a cross-platform package.

## Quick start

```swift
import PlotGraph

let plotView = PlotView(frame: someRect)
view.addSubview(plotView)

let data = PlotData(
    xs: [0, 1, 2, 3, 4, 5],
    ys: [0, 1, 4, 9, 16, 25],
    pointStyle: .circle
)

plotView.annotation = PlotView.Annotation(title: "y = x²", y: "y", x: "x")
plotView.plot(data: data, lineColor: .systemBlue, lineStyle: .solid)
```

`PlotView` lays out and redraws automatically on bounds changes
(`contentMode = .redraw`); you don't need to call `setNeedsDisplay()`
yourself after `plot(data:lineColor:lineStyle:)`.

### Multiple series

```swift
plotView.plot(data: seriesA, lineColor: .systemBlue)
plotView.plot(data: seriesB, lineColor: .systemRed)
```

**Caveat:** the axis transform (scale + origin) is currently computed from
only the *first* series added. If later series have a very different x/y
range than the first, they'll be drawn using axes that don't fit them well.
Plot the series with the widest range first, or explicitly set `min`/`max`
(below) to a range that covers all your data before plotting.

### Explicit axis bounds

By default, axis bounds are derived from your data. You can widen them
explicitly:

```swift
plotView.min = (x: -1, y: -1)
plotView.max = (x: 10, y: 30)
```

Bounds are only ever extended outward from the data's own min/max — setting
`min`/`max` to a value *inside* the data's range has no effect (existing
data is never clipped).

### Point styles

```swift
public enum PointStyle {
    case none, cross, circle, prism, square, star, triangle
}
```

### Reading CSV data

```swift
let rows = readCSV(from: "samples", extension: "csv")   // looks in Bundle.main by default
let extract = Extract(data: rows)
let xValues = extract[0].compactMap { $0.double }
let yValues = extract[1].compactMap { $0.double }
let data = PlotData(xs: xValues, ys: yValues)
```

`readCSV` returns each field as raw `Data`; call `.double`, `.float`,
`.integer`, or `.string` on a field depending on what you know that column
contains — the reader itself doesn't track per-column types. Pass a
`bundle:` argument if your CSV lives outside the main app bundle (e.g. in a
test target's resource bundle).

## Styling

Most visual properties are `@IBInspectable` and can be set either in code or
via Interface Builder / a storyboard:

- `axisColor`, `gridColor`, `showGridLines`
- `lineWidth`, `axisLineWidth`, `pointScale`
- `annotationFont`, `annotationTextColor`, `axisFont`
- `insets` — margin reserved around the plot area for axis labels/annotations

See [METHODOLOGY.md](METHODOLOGY.md) for how axis tick spacing and the
data-to-screen coordinate transform are computed.

## Known limitations

- Axis transform is derived from the first plotted series only (see above).
- `draw(_:)` and the axis-transform code assume at least one series has been
  plotted; an empty chart draws nothing rather than an empty axis frame.
- `readCSV` splits on any newline and on `,`; it doesn't handle quoted
  fields containing commas or embedded newlines (not a full RFC 4180 CSV
  parser).
- No support for log-scaled axes, secondary/dual axes, or legends.

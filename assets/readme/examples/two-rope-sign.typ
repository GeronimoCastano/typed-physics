// typst compile --root . --ppi 300 assets/readme/examples/two-rope-sign.typ assets/readme/examples/two-rope-sign.png
#import "../../../src/lib.typ": *
#set page(width: 17cm, height: auto, margin: 12pt, fill: none)
#set text(font: "New Computer Modern", size: 11pt)

// A plum-and-raspberry family: a lilac sign, graphite ropes, and tensions in rose.
#let look = (
  surface-fill: rgb("#F6F3F8"),
  hatch-stroke: 0.6pt + rgb("#8C6FA3"),
  surface-stroke: 0.9pt + rgb("#4A3A5C"),
  body-fill: rgb("#EFE5F5"),
  body-stroke: 0.9pt + rgb("#5B2D6E"),
  annotation-color: rgb("#6B5B7A"),
  rope-stroke: 1pt + rgb("#3D3D4A"),
  force-colors: (
    weight: rgb("#5B2D6E"),
    tension: rgb("#A23B72"),
  ),
  scale: 1.2,
)

// The sign hangs below a point on the ceiling, and both ropes meet at its top
// centre, so the two tensions and the weight act through one point.
#let s = situation(
  ceiling("roof", length: 6.4, height: 4.6),
  wall("wall", side: left, height: 4.6),
  block("S", mass: $m$, hanging: (on: "roof", at: 50%), drop: 2.4,
    size: (1.8, 1.1)),
  rope("cord-ceiling", from: (on: "roof", at: 86%), to: "S.top"),
  rope("cord-wall", from: (on: "wall", at: 84%), to: "S.top"),
  style: look,
)

#std.block(
  width: 100%,
  fill: white,
  stroke: 0.6pt + luma(215),
  radius: 8pt,
  inset: 18pt,
)[
  #text(size: 10pt)[*Problem.* A sign of mass $m$ hangs from two ropes tied at
  its top centre: one makes an angle $theta_1$ with the ceiling, and the other
  makes an angle $theta_2$ with the wall. Find the tension in each rope.]

  #v(0.9em)

  #grid(
    columns: (10.2cm, 1fr),
    column-gutter: 0.8em,
    align: top,
    [
      #scene(s,
        labels: "name",
        angles: "none",
        annotations: (
          angle-mark(from: (on: "roof", reversed: true), to: "cord-ceiling",
            radius: 0.9, label: $theta_1$),
          angle-mark(from: (on: "wall", reversed: true), to: "cord-wall",
            radius: 1.0, label: $theta_2$),
          dimension(from: (on: "roof", at: 50%), to: "S.top",
            orientation: "vertical", side: "right", offset: 3, label: $h$),
        ),
      )
    ],
    [
      #text(size: 9pt, fill: luma(110))[Free body]
      #linebreak()
      #fbd(s, "S", axes: false, style: (scale: 0.8))
    ],
  )
]

// typst compile --root . --ppi 300 assets/readme/examples/pendulum-release.typ assets/readme/examples/pendulum-release.png
#import "../../../src/lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: 17cm, height: auto, margin: 12pt, fill: none)
#set text(font: "New Computer Modern", size: 11pt)

// An ochre-and-slate accent family, distinct from the warm and teal figures.
#let look = (
  surface-fill: rgb("#EEF2F5"),
  hatch-stroke: 0.6pt + rgb("#64748B"),
  surface-stroke: 0.9pt + rgb("#334155"),
  body-fill: rgb("#F6E7C8"),
  body-stroke: 0.9pt + rgb("#5C3D0E"),
  annotation-color: rgb("#475569"),
  annotation-stroke: 0.7pt,
  velocity-color: rgb("#B7791F"),
)

#let string-length = 4.4
#let release-angle = 50deg

#let s = situation(
  ceiling("roof", length: 8, height: 6.5),
  pendulum("release", from: (on: "roof", at: 50%), length: string-length,
    angle: release-angle, radius: 0.3, angle-label: none),
  pendulum("bottom", from: (on: "roof", at: 50%), length: string-length,
    angle: 0deg, radius: 0.3, angle-label: none),
  style: look,
)

// The angle label sits on the bisector of the swept angle, inside the arc.
#let theta-label-radius = 0.55
#let theta-label-direction = release-angle / 2

#std.block(
  width: 100%,
  fill: white,
  stroke: 0.6pt + luma(215),
  radius: 8pt,
  inset: 18pt,
)[
  #align(center)[
    #cetz.canvas({
      import cetz.draw: content, line
      draw(s, labels: "none", angles: "none",
        annotations: (
          brace(from: (on: "release.pivot", offset: (0.1, -0.3)),
            to: (on : "release.bob", offset: (-0.3, 0.1)),
            side: "left", offset: 0.3, label: $L$),
          dimension(from: "bottom.bob", to: "release.bob",
            orientation: "vertical", side: "right", offset: 1.5, label: $h$),
          arrow(from: "bottom.bob", to: (on: "bottom.bob", offset: (-2.0, 0)),
            label: $v$, color : blue),
        ))
      line("release.pivot", (rel: (0, -4.0), to: "release.pivot"),
        stroke: (paint: rgb("#64748B"), thickness: 0.6pt, dash: "dashed"))
      content((rel: (theta-label-radius * calc.sin(theta-label-direction),
          -theta-label-radius * calc.cos(theta-label-direction)),
        to: "release.pivot"),
        text(fill: rgb("#475569"))[$theta$])
      content((rel: (-2.5, -2.5), to: "release.bob"),
        box(fill: white, stroke: 0.6pt + rgb("#475569"), radius: 2pt,
          inset: 4pt, text(fill: rgb("#475569"), size: 9pt)[
            $v^2 = 2 g L (1 - cos theta)$ at the bottom]))
    })
  ]
]

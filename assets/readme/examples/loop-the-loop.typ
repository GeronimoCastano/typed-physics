// typst compile --root . --ppi 300 assets/readme/examples/loop-the-loop.typ assets/readme/examples/loop-the-loop.png
#import "../../../src/lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: 17cm, height: auto, margin: 12pt, fill: none)
#set text(font: "New Computer Modern", size: 11pt)

// A cool teal accent family on a pale surface.
#let look = (
  surface-fill: rgb("#EAF5F5"),
  hatch-stroke: 0.6pt + rgb("#2B8A8A"),
  surface-stroke: 0.9pt + rgb("#1C5E5E"),
  body-fill: rgb("#CDEBEA"),
  body-stroke: 0.9pt + rgb("#17494A"),
  annotation-color: rgb("#4F7F80"),
  velocity-color: rgb("#0B7285"),
  velocity-length: 0.6,
)

#let loop-radius = 2.5

#let s = situation(
  ramp("drop", angle: 50deg, length: 8.6, facing: left),
  ground("floor", length: 2.4, from: "drop.foot"),
  arc("loop", radius: loop-radius, start-angle: -90deg, end-angle: 270deg,
    side: "inside", from: "floor.end"),
  ground("exit", length: 2.2, from: "loop.end"),
  ball("release", mass: 1, on: "drop", at: 88%, radius: 0.3),
  ball("top", mass: 1, on: "loop", at: 50%, radius: 0.3),
  velocity(on: "top", magnitude: $v$, angle: 180deg, label: none),
  style: look,
)

#std.block(
  width: 100%,
  fill: white,
  stroke: 0.6pt + luma(215),
  radius: 8pt,
  inset: 18pt,
)[
  #align(center)[
    #cetz.canvas({
      import cetz.draw: content
      draw(s, labels: "none", angles: "none",
        annotations: (
          dimension(from: "drop.apex", to: "drop.foot",
            orientation: "vertical", side: "left", offset: 0.9, label: $h$),
          dimension(from: "loop.start", to: (on: "loop", at: 50%),
            orientation: "vertical", side: "right", offset: 3.2, extensions: false, label: $2R$),
          arrow(from: (on: "loop.start", offset: (0, loop-radius)),
            to: (on: "loop", at: 75%),
            label: $R$, label-position: "center"),
        ))
      content((rel: (-0.45, -0.38), to: "top.center"),
        text(fill: rgb("#4F7F80"), size: 9pt)[$v$])
      content((rel: (3.6, 0.2), to: "drop.apex"),
        box(fill: white, stroke: 0.6pt + rgb("#4F7F80"), radius: 2pt,
          inset: 4pt, text(fill: rgb("#4F7F80"), size: 9pt)[
            $v^2 = 2g(h - 2R)$ at the top]))
    })
  ]
]

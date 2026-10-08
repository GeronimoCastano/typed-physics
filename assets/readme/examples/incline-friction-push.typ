// typst compile --root . --ppi 300 assets/readme/examples/incline-friction-push.typ assets/readme/examples/incline-friction-push.png
#import "../../../src/lib.typ": *
#set page(width: 17cm, height: auto, margin: 12pt, fill: none)
#set text(font: "New Computer Modern", size: 11pt)

// One accent family: rust, sage, and crimson on a warm surface.
#let look = (
  surface-fill: rgb("#FBF1E9"),
  hatch-stroke: 0.6pt + rgb("#B2683C"),
  body-fill: rgb("#FBE0CC"),
  body-stroke: 0.9pt + rgb("#6E3517"),
  annotation-color: rgb("#8A7567"),
  force-colors: (
    weight: rgb("#9C4221"),
    normal: rgb("#2F7D5B"),
    friction: rgb("#C2255C"),
    applied: rgb("#6741D9"),
    component: rgb("#9C4221"),
  ),
  force-length: 1.2,
)

#let s = situation(
  ground("floor", length: 1.5),
  ramp("incline", angle: 30deg, length: 6, from: "floor.end"),
  block("A", mass: 4, on: "incline", at: 40%, size: 1.1,
    mu: (s: 0.300, k: 0.220)),
  force(on: "A", magnitude: 60, angle: 10deg, label: $F$),
  style: look,
)

#std.block(
  width: 100%,
  fill: white,
  stroke: 0.6pt + luma(215),
  radius: 8pt,
  inset: 18pt,
)[
  #text(size: 10pt)[*Problem.* A 4 kg block on a 30° incline, with
  $mu_s = 0.300$ and $mu_k = 0.220$, is pushed up the slope by a 60 N force
  at 10° above the horizontal. Does it slide, and what are its acceleration
  and normal force?]

  #v(0.9em)

  #grid(
    columns: (9.4cm, 1fr),
    column-gutter: 1.1em,
    [
      #scene(s,
        labels: "name",
        angles: "none",
        annotations: (
          angle-mark(from: "floor", to: "incline", radius: 1.1),
          dimension(from: "incline.apex", to: "incline.base",
            orientation: "vertical", side: "right", offset: 0.8,
            label: $h$),
        ),
      )
      #v(0.4em)
      #grid(
        columns: (1fr, 1fr),
        column-gutter: 0.6em,
        align: top,
        [#text(size: 9pt, fill: luma(110))[Free body]
          #linebreak()
          #fbd(s, "A", axes: false, style: (scale: 0.8))],
        [#text(size: 9pt, fill: luma(110))[Weight, resolved]
          #linebreak()
          #components(s, "A", style: (scale: 0.8))],
      )
    ],
    [
      #set text(size: 10pt)
      #text(weight: "bold")[Solution]

      #v(0.5em)
      Regime: #solve(s, "A", find: "regime") (kinetic friction)

      #v(0.5em)
      Friction: #solve(s, "A", find: "friction")

      #v(0.5em)
      #rect(
        width: 100%,
        fill: rgb("#FBF1E9"),
        stroke: 0.6pt + rgb("#B2683C"),
        radius: 4pt,
        inset: 8pt,
      )[
        Normal force: #solve(s, "A", find: "normal") \
        Acceleration: #solve(s, "A", find: "acceleration")
      ]
    ],
  )
]

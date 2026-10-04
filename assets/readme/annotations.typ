// typst compile --root . --ppi 300 assets/readme/annotations.typ assets/readme/annotations.png
#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 12pt)
#set text(font: "New Computer Modern", size: 11pt)

#let s = situation(
  ground("floor", length: 9),
  ramp("incline", angle: 32deg, length: 4.6, from: "floor.end"),
  block("A", mass: 2, on: "floor", at: 26%),
  pulley("P", at: (on: "floor", at: 58%, offset: (0, 2.4))),
  rope("cord", from: "A.top", to: "P.left"),
)

#scene(
  s,
  angles: "none",
  annotations: (
    angle-mark(from: "floor", to: "incline", label: $theta$, radius: 1.1),
    axis(at: (on: "floor", at: 8%, offset: (0, 2.4)), length: 0.7),
    dimension(
      from: "A.right",
      to: "incline.foot",
      orientation: "horizontal",
      label: $d$,
    ),
    brace(from: "incline.foot", to: "incline.apex", label: $ell$, offset: 0.3),
    callout(at: "P.center", label: [frictionless], direction: "north"),
    arrow(
      from: "A.left",
      to: (on: "A.left", offset: (-1.4, 0)),
      label: $v_0$,
      label-position: "center",
    ),
  ),
)

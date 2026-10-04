// typst compile --root . --ppi 300 assets/readme/incline.typ assets/readme/incline.png
#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 12pt)
#set text(font: "New Computer Modern", size: 11pt)

#let s = situation(
  ramp("incline", angle: 32deg, length: 8),
  block("A", mass: 25, on: "incline", at: 45%, size: 1.25, symbol: $m$),
  force(on: "A", magnitude: $F$, angle: 32deg),
)

#scene(
  s,
  labels: "both",
  angles: "both",
  annotations: (
    dimension(
      from: "incline.apex",
      to: "incline.base",
      orientation: "vertical",
      side: "right",
      label: $h$,
    ),
  ),
)

// typst compile --root . --ppi 300 assets/readme/ground.typ assets/readme/ground.png
#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 12pt)
#set text(font: "New Computer Modern", size: 11pt)

#let pushed = situation(
  ground(length: 7, mu: (s: 0.30, k: 0.20)),
  block("crate", mass: 12, on: "ground", at: 45%),
  force(on: "crate", magnitude: 40, angle: 0deg),
)

#table(
  columns: 2,
  column-gutter: 2.5em,
  align: center + horizon,
  stroke: none,
  [*`scene(pushed)`*], [*`fbd(pushed, "crate")`*],
  scene(pushed, labels: "both"), fbd(pushed, "crate"),
)

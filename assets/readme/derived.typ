// typst compile --root . --ppi 300 assets/readme/derived.typ assets/readme/derived.png
#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 12pt)
#set text(font: "New Computer Modern", size: 11pt)

#let s = situation(
  ramp("incline", angle: 30deg, length: 7),
  block("A", mass: 4, on: "incline", at: 55%, mu: (s: 0.40, k: 0.30)),
)

#table(
  columns: 2,
  column-gutter: 2.5em,
  align: center + horizon,
  stroke: none,
  [*`fbd(s, "A")`*], [*`components(s, "A")`*],
  fbd(s, "A"), components(s, "A"),
)

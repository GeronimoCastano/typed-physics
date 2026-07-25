// typst compile --root . --ppi 300 assets/readme/solution.typ assets/readme/solution.png
#import "../../src/lib.typ": *
#set page(width: 15cm, height: auto, margin: 12pt)
#set text(font: "New Computer Modern", size: 11pt)

#let s = situation(
  ramp("incline", angle: 30deg, length: 7),
  block("A", mass: 4, on: "incline", at: 55%, mu: (s: 0.40, k: 0.30)),
)

#steps(s)

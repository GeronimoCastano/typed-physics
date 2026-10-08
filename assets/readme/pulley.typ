// typst compile --root . --ppi 300 assets/readme/pulley.typ assets/readme/pulley.png
#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 12pt)
#set text(font: "New Computer Modern", size: 11pt)

#let s = situation(
  ramp("incline", angle: 30deg, length: 7),
  pulley("P", at: "incline.apex", radius: 0.5),
  block("A", mass: 4, on: "incline", at: 55%, size: 1, mu: (s: 0.300, k: 0.220)),
  block("B", mass: 4, hanging: "P.right", drop: 2, size: 1),
  rope("cord", from: "A.uphill", to: "B.top", over: "P"),
)

#grid(
  columns: (auto, auto, auto),
  column-gutter: 0.8cm,
  align: center,
  scene(s, labels: "both", frictions: true),
  fbd(s, "A"),
  fbd(s, "B"),
)

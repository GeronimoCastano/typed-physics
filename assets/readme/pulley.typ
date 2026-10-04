// typst compile --root . --ppi 300 assets/readme/pulley.typ assets/readme/pulley.png
#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 12pt)
#set text(font: "New Computer Modern", size: 11pt)

#let s = situation(
  ground("floor", length: 8, mu: (s: 0.300, k: 0.220)),
  block("A", mass: 4, on: "floor", at: 55%, size: 1.2),
  pulley("wheel", at: "floor.end", radius: 0.55),
  block("B", mass: 3, hanging: "wheel.right", drop: 1.6, size: 1.2),
  rope("cord", from: "A.right", to: "B.top", over: "wheel"),
)

#grid(
  columns: (auto, auto, auto),
  column-gutter: 0.8cm,
  align: center,
  scene(s, labels: "both", frictions: true),
  fbd(s, "A"),
  fbd(s, "B"),
)

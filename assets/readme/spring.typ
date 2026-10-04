// typst compile --root . --ppi 300 assets/readme/spring.typ assets/readme/spring.png
#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 12pt)
#set text(font: "New Computer Modern", size: 11pt)

#let s = situation(
  ground("floor", length: 10),
  wall("wall", side: left, height: 2.4),
  block("A", on: "floor", at: 22%, size: 1.2),
  block("B", on: "floor", at: 62%, size: 1.5),
  spring("s", from: (on: "wall"), to: "A.left", coils: 7),
  velocity(on: "A", angle: 0deg, label: $v_0$),
)

#scene(
  s,
  annotations: (
    dimension(
      from: "A.right",
      to: "B.left",
      orientation: "horizontal",
      side: "above",
      label: $d$,
    ),
  ),
)

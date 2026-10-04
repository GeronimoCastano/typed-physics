// typst compile --root . --ppi 300 assets/readme/beam.typ assets/readme/beam.png
#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 12pt)
#set text(font: "New Computer Modern", size: 11pt)

#let s = situation(
  rod("beam", length: 9, label: none),
  support("A", at: "beam.start", kind: "pin"),
  support("B", at: "beam.end", kind: "roller"),
  force(on: "beam", at: 30%, magnitude: $P_1$, angle: -90deg, label: $P_1$),
  force(on: "beam", at: 62%, magnitude: $P_2$, angle: -90deg, label: $P_2$),
  torque(on: "beam", at: 80%, direction: "clockwise", radius: 0.5, label: $M_0$),
)

#scene(
  s,
  annotations: (
    dimension(
      from: "beam.start",
      to: (on: "beam", at: 30%),
      side: "below",
      offset: 1.15,
      label: $a$,
    ),
    dimension(
      from: (on: "beam", at: 30%),
      to: (on: "beam", at: 62%),
      side: "below",
      offset: 1.15,
      label: $b$,
    ),
    dimension(
      from: "beam.start",
      to: "beam.end",
      side: "below",
      offset: 2.3,
      label: $L$,
    ),
  ),
)

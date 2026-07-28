#import "../../src/lib.typ": *

#let symbolic = situation(
  ramp("incline", angle: 30deg, length: 6),
  block(
    "A",
    mass: $m$,
    on: "incline",
    mu: (s: $mu_s$, k: $mu_k$),
  ),
)
#let symbolic-result = results(symbolic)
#assert(symbolic-result.status == "undetermined")

#let numeric = situation(
  ramp("incline", angle: 30deg, length: 6),
  block("A", mass: 4, on: "incline", mu: 0.2),
)
#let numeric-result = results(numeric)
#assert(numeric-result.status == "solved")

#let multiple = situation(
  ground(length: 8),
  block("A", mass: 2, on: "ground", at: 30%),
  block("B", mass: 3, on: "ground", at: 70%),
)
#assert(results(multiple, "A").status == "solved")
#assert(results(multiple, "B").status == "solved")

#let drawing-only = situation(
  ground(length: 6),
  disk("D", on: "ground"),
)
#scene(drawing-only)

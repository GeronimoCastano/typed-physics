#import "../src/lib.typ": *

#set page(paper: "a4", margin: 1.4cm)
#set text(font: "New Computer Modern", size: 11pt)

// `block` is the package's body constructor, so the layout helper reaches for
// Typst's own through `std`.
#let section(title, body) = std.block(below: 1.4em)[
  #strong(title)
  #v(0.4em)
  #body
]

= typed-physics visual test

== Block on a rough incline

#let incline-situation = situation(
  ramp("incline", angle: 30deg, length: 7),
  block("A", mass: 4, on: "incline", at: 55%, mu: (s: 0.40, k: 0.30)),
)

#section("Scene", scene(incline-situation))

#section("Scene with mass labels and the angle shown both ways", scene(
  incline-situation,
  labels: "both",
  angles: "both",
))

#section("Free-body diagram (arrows in proportion, axes follow the surface)", fbd(incline-situation, "A"))

#section("Weight resolved into the surface's axes", components(incline-situation, "A"))

#section("Solution", solve(incline-situation))

#section("Steps (same equations, with the substitution shown)", steps(incline-situation))

#section("Force table", force-table(incline-situation, "A"))

#pagebreak()

== The same block on a gentler slope

The declaration changes in one place; every view follows.

#let gentle = situation(
  ramp("incline", angle: 15deg, length: 7),
  block("A", mass: 4, on: "incline", at: 55%, mu: (s: 0.40, k: 0.30)),
)

#section("Scene", scene(gentle))

#section("Solution — the same block now stays put", solve(gentle))

#section("Free-body diagram of a body that is not sliding", fbd(gentle, "A"))

#pagebreak()

== Level ground

#let pushed = situation(
  ground(length: 7, mu: (s: 0.30, k: 0.20)),
  block("crate", mass: 12, on: "ground", at: 40%),
  force(on: "crate", magnitude: 40, angle: 0deg),
)

#section("Scene with an applied load", scene(pushed, labels: "both"))

#section("Free-body diagram", fbd(pushed, "crate"))

#section("Solution", steps(pushed))

#section("Blocks in contact on a frictionless floor", {
  let pair = situation(
    ground(length: 7, mu: 0),
    block("m1", mass: 2, on: "ground", at: 35%),
    block("m2", mass: 3, on: "ground", touching: "m1", side: right),
    force(on: "m1", magnitude: 10, angle: 0deg),
  )
  scene(pair, labels: "mass")
})

#pagebreak()

== Environment pieces

#section("Ground, wall, and ceiling", {
  let room = situation(
    ground(length: 6),
    wall("left-wall", side: left, height: 3.4),
    wall("right-wall", side: right, height: 3.4),
    ceiling(length: 6, height: 3.4),
    block("box", mass: 5, on: "ground", at: 50%),
  )
  scene(room, labels: "mass")
})

#section("Steeper ramps, same declaration", grid(
  columns: 3,
  column-gutter: 0.6em,
  ..(20deg, 40deg, 60deg).map(slope => scene(
    situation(
      ramp("incline", angle: slope, length: 4),
      block("A", mass: 2, on: "incline", at: 60%, size: 0.8, mu: 0.35),
    ),
    style: (scale: 0.8),
  ))
))

#pagebreak()

== Symbolic situations

#section("A symbolic mass and coefficients keep the closed form", {
  let symbolic = situation(
    ramp("incline", angle: 30deg, length: 6),
    block("A", mass: $m$, on: "incline", at: 50%, mu: (s: $mu_s$, k: $mu_k$)),
  )
  stack(
    spacing: 1em,
    scene(symbolic, labels: "mass"),
    components(symbolic, "A"),
    solve(symbolic, assume: "sliding"),
  )
})

#section("Without an assumed regime, the package refuses to guess", {
  let symbolic = situation(
    ramp("incline", angle: 30deg, length: 6),
    block("A", mass: $m$, on: "incline", at: 50%, mu: (s: $mu_s$, k: $mu_k$)),
  )
  solve(symbolic)
})

#section("An assumed regime is reported as assumed, not as checked", {
  let s = situation(
    ramp("incline", angle: 30deg, length: 6),
    block("A", mass: 4, on: "incline", at: 50%, mu: 0.5),
  )
  stack(spacing: 0.8em, solve(s), solve(s, assume: "sliding"))
})

#pagebreak()

== Styling

#section("Style overrides reach every view", {
  let s = situation(
    ramp("incline", angle: 35deg, length: 6),
    block("A", mass: 3, on: "incline", at: 50%, mu: 0.2),
    style: (body-fill: rgb("#FFE3E3"), surface-fill: rgb("#FFF9DB"), scale: 0.9),
  )
  stack(
    dir: ltr,
    spacing: 1.5em,
    scene(s),
    fbd(s, "A", style: (force-colors: (weight: black, normal: black, friction: black))),
  )
})

#section("A body with no friction declared slides on any slope", {
  let s = situation(
    ramp("incline", angle: 20deg, length: 5),
    block("A", mass: 2, on: "incline", at: 50%),
  )
  stack(spacing: 0.8em, fbd(s, "A"), solve(s))
})

#pagebreak()

== Drawing on top of a scene

#section("Named anchors on every body and surface", {
  cetz.canvas({
    import cetz.draw: circle, content, line
    draw(incline-situation)
    circle("A.center", radius: 0.06, fill: red, stroke: none)
    line("A.center", (rel: (1.6, 1.2)), stroke: 0.6pt + red)
    content((rel: (0.1, 0.1), to: ()), text(size: 8pt, fill: red)[A.center])
    circle("incline.apex", radius: 0.06, fill: red, stroke: none)
    content((rel: (0.55, 0.2), to: "incline.apex"), text(size: 8pt, fill: red)[incline.apex])
  })
})

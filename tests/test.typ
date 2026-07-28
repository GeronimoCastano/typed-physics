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

#section("Every quantity the solver found", stack(
  spacing: 0.6em,
  solve(incline-situation, find: "normal"),
  solve(incline-situation, find: "friction"),
  solve(incline-situation),
))

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

#section("Solution", stack(
  spacing: 0.6em,
  solve(pushed, find: "normal"),
  solve(pushed, find: "friction"),
  solve(pushed),
))

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

#pagebreak()

== Grouping in rendered expressions

#section(
  "A normal force that negates a sum keeps its parentheses",
  {
    // An angled push makes the normal force the negation of a two-term sum,
    // which is the only place the renderer has to bracket a subexpression.
    let s = situation(
      ground(length: 6, mu: (s: 0.50, k: 0.40)),
      block("crate", mass: 12, on: "ground", at: 45%),
      force(on: "crate", magnitude: 40, angle: -25deg),
    )
    // N = 12(9.81) + 40 sin 25° = 135 N, so the crate stays put:
    // f_req = 40 cos 25° = 36.3 N fits inside mu_s N = 67.3 N.
    stack(spacing: 0.8em, scene(s), solve(s, find: "normal"), solve(s))
  },
)

#pagebreak()

== Scene labels and declared symbols

#section("Coefficients and surface lengths drawn in the scene", {
  let s = situation(
    ramp("incline", angle: 30deg, length: 7),
    block("A", mass: 4, on: "incline", at: 55%, mu: (s: 0.40, k: 0.30)),
  )
  scene(s, labels: "both", angles: "both", frictions: true, lengths: true)
})

#section("The same on level ground, with one coefficient", {
  let s = situation(
    ground(length: 7, mu: 0.35),
    block("crate", mass: 12, on: "ground", at: 45%),
  )
  scene(s, labels: "both", frictions: true, lengths: true)
})

#section("Symbols the author declared, in the figure and in the algebra", {
  let s = situation(
    ramp("incline", angle: 30deg, length: 6, symbol: $alpha$),
    block("A", mass: 4, on: "incline", at: 55%, symbol: $m_1$, mu: 0.2),
  )
  stack(
    spacing: 0.8em,
    scene(s, labels: "both", angles: "both"),
    solve(s, find: "normal"),
    solve(s),
  )
})

#pagebreak()

== One answer at a time

#let answer-situation = situation(
  ramp("incline", angle: 30deg, length: 6),
  block("A", mass: 4, on: "incline", at: 55%, mu: (s: 0.40, k: 0.30)),
)

#section("solve() states the quantity asked for", {
  // N = 34.0 N, f_k = 10.2 N, a = 2.36 m/s² down the incline.
  stack(
    spacing: 0.6em,
    solve(answer-situation),
    solve(answer-situation, find: "normal"),
    solve(answer-situation, find: "friction"),
    solve(answer-situation, find: "regime"),
  )
})

#section("A body that stays put answers with its regime", {
  let s = situation(
    ramp("incline", angle: 15deg, length: 6),
    block("A", mass: 4, on: "incline", at: 55%, mu: (s: 0.40, k: 0.30)),
  )
  stack(spacing: 0.6em, solve(s), solve(s, find: "friction"))
})

#pagebreak()

== Styling one element at a time

#section("Each element carries its own style, the situation carries the rest", {
  let s = situation(
    ramp(
      "incline",
      angle: 30deg,
      length: 7,
      style: surface-style(
        fill: rgb("#FFF9DB"),
        hatch-stroke: 0.6pt + rgb("#E67700"),
      ),
    ),
    block(
      "A",
      mass: 4,
      on: "incline",
      at: 22%,
      mu: 0.3,
      style: block-style(fill: rgb("#D3F9D8"), stroke: 1pt + rgb("#2B8A3E")),
    ),
    block("B", mass: 2, on: "incline", at: 70%, mu: 0.3),
    force(
      on: "B",
      magnitude: 12,
      angle: 30deg,
      style: force-style(color: rgb("#C2255C"), length: 1.9),
    ),
  )
  stack(dir: ltr, spacing: 1.2em, scene(s), fbd(s, "A"))
})

#section("A styled force keeps its color into the free-body diagram", {
  let s = situation(
    ground(length: 5, mu: 0.25),
    block("crate", mass: 8, on: "ground", at: 50%),
    force(
      on: "crate",
      magnitude: 30,
      angle: 0deg,
      style: force-style(color: rgb("#C2255C")),
    ),
  )
  stack(dir: ltr, spacing: 1.2em, scene(s), fbd(s, "crate"))
})

#section("Symbolic gravity stays symbolic through every equation", {
  let s = situation(
    gravity: $g$,
    ramp("incline", angle: 30deg, length: 6),
    block("A", mass: 4, on: "incline", at: 55%, mu: (s: 0.40, k: 0.30)),
  )
  stack(
    spacing: 0.8em,
    fbd(s, "A"),
    solve(s, find: "normal", assume: "sliding"),
    solve(s, assume: "sliding"),
  )
})

#pagebreak()

== Forces drawn on the body in place

#section("The same arrows the free-body diagram draws, left where the body sits", {
  let s = situation(
    ramp("incline", angle: 30deg, length: 7),
    block("A", mass: 4, on: "incline", at: 55%, mu: (s: 0.40, k: 0.30)),
  )
  stack(dir: ltr, spacing: 1.2em, scene(s, forces: "A"), fbd(s, "A"))
})

#section("Every body at once, on level ground", {
  let s = situation(
    ground(length: 8, mu: 0.2),
    block("m1", mass: 2, on: "ground", at: 30%),
    block("m2", mass: 3, on: "ground", at: 65%),
    force(on: "m1", magnitude: 8, angle: 0deg),
  )
  scene(s, forces: true)
})

#section("A surface length is written, not measured", {
  let s = situation(
    ramp("incline", angle: 25deg, length: 6),
    block("A", mass: 3, on: "incline", at: 50%),
  )
  scene(s, lengths: true, angles: "both")
})

#pagebreak()

== Numbers as far as they reach

#section("Everything numeric gives a number", {
  // a = g(sin 30° - 0.30 cos 30°) = 2.36 m/s².
  let s = situation(
    ramp("incline", angle: 30deg, length: 6),
    block("A", mass: 4, on: "incline", mu: (s: 0.40, k: 0.30)),
  )
  stack(spacing: 0.6em, solve(s), solve(s, find: "normal"))
})

#section("A symbolic coefficient leaves only that coefficient standing", {
  // N = 4(9.81) cos 30° = 34.0 N is known whichever way the block goes, and
  // a = 9.81 sin 30° - mu_k (9.81) cos 30° = 4.90 - 8.50 mu_k.
  let s = situation(
    ramp("incline", angle: 30deg, length: 6),
    block("A", mass: 4, on: "incline", mu: (s: $mu_s$, k: $mu_k$)),
  )
  stack(
    spacing: 0.6em,
    solve(s, find: "normal"),
    solve(s, assume: "sliding"),
    solve(s, find: "friction", assume: "sliding"),
  )
})

#section("Everything symbolic gives the closed form", {
  let s = situation(
    gravity: $g$,
    ramp("incline", angle: 30deg, length: 6, symbol: $theta$),
    block("A", mass: $m$, on: "incline", mu: (s: $mu_s$, k: $mu_k$)),
  )
  stack(spacing: 0.6em, solve(s, find: "normal"), solve(s, assume: "sliding"))
})

#pagebreak()

== Stated quantities, not sentences

#let stated = situation(
  ramp("incline", angle: 30deg, length: 6),
  block("A", mass: 4, on: "incline", mu: (s: 0.40, k: 0.30)),
)

#section("Every quantity, and the direction words turned off", {
  // N = 34.0 N, f_k = 10.2 N, a = 2.36 m/s².
  stack(
    spacing: 0.6em,
    solve(stated, find: "normal"),
    solve(stated, find: "friction"),
    solve(stated, find: "acceleration"),
    solve(stated, find: "acceleration", direction: false),
    [regime: #solve(stated, find: "regime")],
  )
})

#section("An author's own sentence, in their own words", {
  let answer = results(stated)
  [
    El bloque desliza con una aceleración de
    #calc.round(answer.acceleration.value, digits: 2) m/s², porque la fricción
    requerida #calc.round(answer.required.value, digits: 1) N supera
    #calc.round(answer.available.value, digits: 1) N.
  ]
})

#section("A frictionless contact states a friction of zero", {
  let s = situation(
    ramp("incline", angle: 20deg, length: 5),
    block("A", mass: 2, on: "incline"),
  )
  stack(spacing: 0.6em, solve(s, find: "friction"), solve(s))
})

#pagebreak()

== Surfaces that meet

#section("A ramp between two flats, each placed from the one before", {
  let s = situation(
    ground("approach", length: 4),
    ramp("incline", angle: 25deg, length: 4, from: "approach"),
    ground("shelf", length: 2.5, from: "incline.apex"),
    block("A", mass: 2, on: "approach", at: 40%),
    block("B", mass: 1, on: "incline", at: 55%),
    block("C", mass: 1, on: "shelf", at: 50%),
  )
  scene(s)
})

#section("A valley: two ramps facing each other", {
  let s = situation(
    ramp("left-slope", angle: 30deg, length: 4, facing: left),
    ground("floor", length: 3, from: "left-slope.foot"),
    ramp("right-slope", angle: 30deg, length: 4, from: "floor"),
    ball("b", mass: 1, on: "floor", at: 50%, radius: 0.35),
  )
  scene(s)
})

#section("A wall stands at the edge of everything placed before it", {
  let s = situation(
    ground("floor", length: 4),
    ramp("incline", angle: 20deg, length: 3, from: "floor"),
    wall(side: right, height: 3),
    block("A", mass: 2, on: "floor", at: 40%),
  )
  scene(s)
})

#pagebreak()

== Bodies that are not squares

#section("A rectangle, a ball, and a point", {
  let s = situation(
    ground(length: 7, mu: 0.3),
    block("crate", mass: 6, on: "ground", at: 25%, size: (1.6, 0.9)),
    ball("b", mass: 2, on: "ground", at: 55%, radius: 0.45),
    point-mass("p", mass: 1, on: "ground", at: 82%),
  )
  stack(spacing: 0.8em, scene(s, labels: "both"), scene(s, forces: true))
})

#section("A ball on a slope carries the same forces a block would", {
  // N = 2(9.81) cos 25° = 17.8 N, and the ball slides because
  // f_req = 2(9.81) sin 25° = 8.29 N exceeds mu_s N = 3.56 N.
  let s = situation(
    ramp("incline", angle: 25deg, length: 5),
    ball("b", mass: 2, on: "incline", at: 55%, radius: 0.45, mu: 0.2),
  )
  stack(
    dir: ltr,
    spacing: 1.2em,
    scene(s, forces: "b"),
    fbd(s, "b"),
    solve(s, find: "normal"),
  )
})

#pagebreak()

== Motion the author states

#section("A velocity is drawn in its own colour, and never as a force", {
  let s = situation(
    ground(length: 6, mu: 0.25),
    block("A", mass: 3, on: "ground", at: 35%),
    velocity(on: "A", magnitude: 5, angle: 0deg, label: $v_0$),
    force(on: "A", magnitude: 10, angle: 90deg),
  )
  stack(dir: ltr, spacing: 1.2em, scene(s), fbd(s, "A"))
})

#pagebreak()

== Connectors

#section("A hanging mass on a rope, and the tension the diagram knows about", {
  let s = situation(
    ceiling(length: 5, height: 3.2),
    block("B", mass: 2, hanging: (on: "ceiling", at: 50%), drop: 1.6),
    rope(from: (on: "ceiling", at: 50%), to: "B.top"),
  )
  stack(dir: ltr, spacing: 1.5em, scene(s), fbd(s, "B"))
})

#section("A block on a table pulled by a hanging mass over a pulley", {
  let s = situation(
    ground(length: 7, mu: 0.2),
    ceiling(length: 7, height: 3.6),
    pulley("P", at: (on: "ceiling", at: 72%), radius: 0.4),
    block("A", mass: 4, on: "ground", at: 30%),
    block("B", mass: 2, hanging: "P.right", drop: 1.4),
    rope(from: "A.top", to: "B.top", over: "P"),
  )
  scene(s)
})

#section("A spring between a wall and a block", {
  let s = situation(
    ground(length: 6),
    wall(side: left, height: 2),
    block("A", mass: 3, on: "ground", at: 60%),
    spring(from: (on: "wall", at: 25%), to: "A.left", coils: 7),
  )
  scene(s)
})

#pagebreak()

== Composed surface hatching

#section("A valley shares one continuous foundation hatch", {
  let s = situation(
    ramp("left-slope", angle: 30deg, length: 4, facing: left),
    ground("floor", length: 3, from: "left-slope.foot"),
    ramp("right-slope", angle: 30deg, length: 4, from: "floor"),
    ball("b", mass: 1, on: "floor", radius: 0.35),
  )
  scene(s)
})

#section("A shelf hatch stays outside the ramp it continues", {
  let s = situation(
    ground("approach", length: 4),
    ramp("incline", angle: 25deg, length: 4, from: "approach"),
    ground("shelf", length: 2.5, from: "incline.apex"),
    block("A", mass: 2, on: "approach", at: 40%),
    block("B", mass: 1, on: "incline", at: 55%),
    block("C", mass: 1, on: "shelf", at: 50%),
  )
  scene(s)
})

#pagebreak()

== Components drawn in the scene

#section("Force arrows and weight components share one body", {
  let s = situation(
    ramp("incline", angle: 30deg, length: 9, mu: 0.25),
    block("A", mass: 4, on: "incline", at: 62%),
  )
  scene(
    s,
    forces: "A",
    components: "A",
    labels: "none",
    angles: "none",
  )
})

#pagebreak()

== Individual annotation placement

#section("Body and angle labels accept raw offsets and rotations", {
  let s = situation(
    ramp("incline", angle: 30deg, length: 9),
    block("A", mass: 4, on: "incline", at: 48%),
    block("B", mass: 2, on: "incline", at: 76%),
  )
  scene(
    s,
    labels: (
      mode: "name",
      overrides: (
        (on: "A", offset: (0.35, 0.3), rotation: -12deg),
        (on: "B", visible: false),
      ),
    ),
    angles: (
      mode: "both",
      overrides: (
        (
          on: "incline",
          offset: (0.28, 0.18),
          rotation: 10deg,
        ),
      ),
    ),
  )
})

#pagebreak()

== Mass symbols without values

#section("One body can show only its mass symbol", {
  let s = situation(
    ground(length: 7),
    block("A", mass: 4, on: "ground", at: 32%),
    block("B", mass: 2, on: "ground", at: 70%),
  )
  scene(
    s,
    labels: (
      mode: "mass",
      overrides: (
        (on: "A", mode: "symbol"),
      ),
    ),
  )
})

#pagebreak()

== Curved supports

#section("A disk follows the inside of a loop-the-loop", {
  let s = situation(
    ground("approach", length: 2.5),
    arc(
      "loop",
      radius: 2,
      start-angle: -90deg,
      end-angle: 270deg,
      side: "inside",
      from: "approach.end",
    ),
    disk(
      "car",
      mass: 1,
      on: "loop",
      at: 18%,
      radius: 0.28,
      orientation: 35deg,
    ),
  )
  scene(s, labels: "name")
})

#section("A ball follows the outside of a circular hill", {
  let s = situation(
    arc(
      "hill",
      radius: 2,
      start-angle: 180deg,
      end-angle: 0deg,
      side: "outside",
    ),
    ball("H", on: "hill", at: 50%, radius: 0.28),
  )
  scene(s)
})

#pagebreak()

== Rotating bodies

#section("Disks and rings can show radial orientation marks", {
  let s = situation(
    ground(length: 8),
    disk(
      "disk",
      mass: 3,
      on: "ground",
      at: 28%,
      radius: 0.58,
      radius-mark: true,
      orientation: 25deg,
      label: $D$,
    ),
    ring(
      "ring",
      mass: 2,
      on: "ground",
      at: 70%,
      radius: 0.58,
      radius-mark: true,
      orientation: 125deg,
      label: $H$,
    ),
    torque(on: "disk", direction: "counterclockwise", label: $tau_1$),
    torque(on: "ring", direction: "clockwise", label: $tau_2$),
  )
  scene(s, labels: "name")
})

#pagebreak()

== Rigid-body drawing vocabulary

#section("A simply supported beam carries a point load and a couple", {
  let s = situation(
    rod("beam", length: 6, thickness: 0.18, mass: 12, label: none),
    support("A", at: "beam.start", kind: "pin"),
    support("B", at: "beam.end", kind: "roller"),
    force(on: "beam", at: 55%, magnitude: 20, angle: -90deg, label: $P$),
    torque(
      on: "beam",
      at: 78%,
      direction: "clockwise",
      radius: 0.48,
      label: $M$,
    ),
  )
  scene(s, labels: "name")
})

#section("A pivot and fixed support attach to rod anchors", {
  let s = situation(
    rod("lever", length: 5, angle: 8deg),
    pivot("fulcrum", at: (on: "lever", at: 48%)),
    rod("cantilever", from: "lever.end", length: 2.5, angle: 90deg),
    support(
      "fixed-end",
      at: "cantilever.end",
      kind: "fixed",
      angle: 90deg,
    ),
  )
  scene(s)
})

#pagebreak()

== Pendulums

#section("A simple pendulum carries its own construction angle", {
  let s = situation(
    ceiling(length: 5, height: 4),
    pendulum(
      "bob",
      from: (on: "ceiling", at: 50%),
      length: 2.8,
      angle: 24deg,
      mass: 1.5,
      radius: 0.28,
    ),
  )
  scene(s, labels: "both")
})

#pagebreak()

== Curved hatch priority and angular motion

#section("Ground hatches take priority where a loop meets its approach", {
  let s = situation(
    ground("approach", length: 2.5),
    arc(
      "loop",
      radius: 2,
      start-angle: -90deg,
      end-angle: 270deg,
      side: "inside",
      from: "approach.end",
    ),
    disk(
      "C",
      on: "loop",
      at: 18%,
      radius: 0.3,
      orientation: 35deg,
    ),
    angular-velocity(
      on: "C",
      direction: "clockwise",
      radius: 0.52,
      start-angle: 220deg,
      end-angle: 140deg,
      label: $omega$,
    ),
  )
  scene(s)
})

#section("Angular arrows distinguish clockwise and counterclockwise motion", {
  let s = situation(
    ground(length: 8),
    disk("D", on: "ground", at: 28%, radius: 0.58, label: $D$),
    ring("H", on: "ground", at: 70%, radius: 0.58, label: $H$),
    angular-velocity(on: "D", direction: "clockwise", label: $omega_D$),
    angular-velocity(
      on: "H",
      direction: "counterclockwise",
      start-angle: 40deg,
      end-angle: 140deg,
      label: $omega_H$,
    ),
  )
  scene(s)
})

#pagebreak()

== Optional disk and ring radius marks

#section("Radius marks can be disabled", {
  let s = situation(
    ground(length: 7),
    disk(
      "plain-disk",
      on: "ground",
      at: 30%,
      radius: 0.6,
      radius-mark: false,
      label: $D$,
    ),
    ring(
      "plain-ring",
      on: "ground",
      at: 70%,
      radius: 0.6,
      radius-mark: false,
      label: $H$,
    ),
  )
  scene(s)
})

#pagebreak()

== Support seating and cardinal radius-mark labels

#section("Pin and roller supports meet the lower face of a rod", {
  let s = situation(
    rod("beam", length: 7, thickness: 0.22, label: none),
    support("pin", at: "beam.start", kind: "pin"),
    support("roller", at: "beam.end", kind: "roller"),
    force(on: "beam", at: 50%, magnitude: 20, angle: -90deg, label: $P$),
  )
  scene(s)
})

#section("Diagonal spokes use cardinal label positions and reach the rim", {
  let s = situation(
    ground(length: 12),
    disk(
      "upper-right",
      on: "ground",
      at: 15%,
      radius: 0.55,
      orientation: 35deg,
      label: $A$,
    ),
    disk(
      "upper-left",
      on: "ground",
      at: 38%,
      radius: 0.55,
      orientation: 120deg,
      label: $B$,
    ),
    ring(
      "lower-left",
      on: "ground",
      at: 62%,
      radius: 0.55,
      radius-mark: true,
      orientation: 215deg,
      label: $C$,
    ),
    ring(
      "lower-right",
      on: "ground",
      at: 85%,
      radius: 0.55,
      radius-mark: true,
      orientation: 300deg,
      label: $D$,
    ),
  )
  scene(s)
})

#pagebreak()

== Shape-specific radius-mark defaults

#section("Disks show the mark while rings keep a clean open centre", {
  let s = situation(
    ground(length: 8),
    disk("disk-default", on: "ground", at: 28%, radius: 0.62, label: $D$),
    ring("ring-default", on: "ground", at: 70%, radius: 0.62, label: $H$),
  )
  scene(s)
})

#pagebreak()

== Configurable dimension annotations

#section("A centered spring length interrupts its horizontal dimension line", {
  let s = situation(
    ground(length: 7),
    wall(side: left, height: 2),
    block("A", on: "ground", at: 72%, size: 1),
    spring(
      "coil",
      from: (on: "wall", at: 25%),
      to: "A.left",
      coils: 7,
    ),
  )
  scene(
    s,
    dimensions: dimension(
      from: "coil.start",
      to: "coil.end",
      offset: 0.75,
      side: "above",
      label: $L_0$,
      label-position: "center",
    ),
  )
})

#section("A diagonal ramp dimension accepts custom arrows and colour", {
  let s = situation(
    ramp("incline", angle: 28deg, length: 5),
    block("B", on: "incline", at: 55%),
  )
  scene(
    s,
    dimensions: dimension(
      from: "incline.foot",
      to: "incline.apex",
      offset: 1.1,
      side: "above",
      label: [ramp length],
      label-position: "above",
      arrows: "both",
      arrow-tip: "triangle",
      stroke: 1pt,
      color: rgb("#C92A2A"),
    ),
  )
})

#section("A vertical dimension can use raw points and a one-ended arrow", {
  let s = situation(
    ground(length: 2),
    wall(side: left, height: 3),
  )
  scene(
    s,
    dimensions: dimension(
      from: (0, 0),
      to: (0, 3),
      offset: 0.65,
      side: "left",
      label: $h$,
      label-position: "below",
      arrows: "end",
      extensions: false,
    ),
  )
})

#section("Centered gaps grow with label content and text size", {
  let s = situation(ground(length: 6))
  scene(
    s,
    dimensions: (
      dimension(
        from: (0, 0.65),
        to: (6, 0.65),
        offset: 0,
        label: $L$,
        text: (size: 8pt),
        extensions: false,
      ),
      dimension(
        from: (0, 1.35),
        to: (6, 1.35),
        offset: 0,
        label: [long reference length],
        text: (size: 12pt),
        extensions: false,
      ),
    ),
  )
})

#pagebreak()

== Collision-aware dimension projections

#section("Dashed projections stop before body outlines", {
  let s = situation(
    ground(length: 9),
    block("A", on: "ground", at: 24%),
    block("B", on: "ground", at: 76%),
  )
  scene(
    s,
    dimensions: dimension(
      from: "A.center",
      to: "B.center",
      offset: 1.35,
      side: "above",
      label: $L$,
    ),
  )
})

#pagebreak()

== Axis-aligned dimension orientations

#section("A ramp's vertical rise and horizontal run use axis projections", {
  let s = situation(
    ramp("incline", angle: 28deg, length: 5),
    ground(length: 6),
  )
  scene(
    s,
    dimensions: (
      dimension(
        from: "incline.apex",
        to: "ground",
        orientation: "vertical",
        side: "right",
        offset: 0.75,
        label: $h$,
      ),
      dimension(
        from: "incline.foot",
        to: "incline.apex",
        orientation: "horizontal",
        side: "above",
        offset: 0.7,
        label: $b$,
      ),
    ),
  )
})

#pagebreak()

== Stroke-aware arrow boundaries

#section("Incoming and outgoing arrows clear a body's visible outline", {
  let s = situation(
    ground(length: 6),
    block(
      "A",
      on: "ground",
      at: 50%,
      size: 1.3,
      style: block-style(stroke: 4pt + rgb("#212529")),
    ),
    force(
      on: "A",
      magnitude: 10,
      angle: 0deg,
      label: $F$,
      style: force-style(stroke: 3pt),
    ),
    velocity(
      on: "A",
      angle: 0deg,
      label: $v_0$,
      style: force-style(stroke: 3pt),
    ),
  )
  scene(s)
})

#section("A load terminates at the outside face of a rod", {
  let s = situation(
    rod(
      "beam",
      length: 6,
      thickness: 0.35,
      label: none,
      style: block-style(stroke: 4pt + rgb("#212529")),
    ),
    force(
      on: "beam",
      at: 50%,
      magnitude: 12,
      angle: -90deg,
      label: $P$,
      style: force-style(stroke: 3pt),
    ),
  )
  scene(s)
})

#pagebreak()

== Exact diagonal arrow contact

#section("Diagonal tips and bases meet a thick rectangular outline", {
  let s = situation(
    ground(length: 7),
    block(
      "A",
      on: "ground",
      at: 50%,
      size: 1.5,
      style: block-style(stroke: 7pt + rgb("#212529")),
    ),
    force(
      on: "A",
      magnitude: 10,
      angle: -28deg,
      label: $F$,
      style: force-style(stroke: 5pt),
    ),
    velocity(
      on: "A",
      angle: 28deg,
      label: $v$,
      style: force-style(stroke: 5pt),
    ),
  )
  scene(s)
})

#section("An oblique load meets the stroked face of a rod", {
  let s = situation(
    rod(
      "beam",
      length: 6,
      thickness: 0.45,
      label: none,
      style: block-style(stroke: 7pt + rgb("#212529")),
    ),
    force(
      on: "beam",
      at: 50%,
      magnitude: 12,
      angle: -60deg,
      label: $P$,
      style: force-style(stroke: 5pt),
    ),
  )
  scene(s)
})

#section("In-place forces emerge from the exact outline of a tilted body", {
  let s = situation(
    ramp("incline", angle: 28deg, length: 6, mu: 0.3),
    block(
      "A",
      mass: 2,
      on: "incline",
      at: 48%,
      size: 1.4,
      style: block-style(stroke: 7pt + rgb("#212529")),
    ),
  )
  scene(
    s,
    forces: "A",
    labels: "none",
    style: (
      force-stroke: 5pt,
      force-length: 1.25,
    ),
  )
})

#section("Round bodies use the outside radius of their stroke", {
  let s = situation(
    ground(length: 6),
    ball(
      "C",
      on: "ground",
      at: 50%,
      radius: 0.75,
      style: block-style(stroke: 7pt + rgb("#212529")),
    ),
    force(
      on: "C",
      magnitude: 10,
      angle: -25deg,
      label: $F$,
      style: force-style(stroke: 5pt),
    ),
    velocity(
      on: "C",
      angle: 25deg,
      label: $v$,
      style: force-style(stroke: 5pt),
    ),
  )
  scene(s)
})

== Validation audit positive regressions

#section("Symbolic and underdetermined mechanics remain drawable", {
  let s = situation(
    ramp("symbolic-incline", angle: 30deg, length: 6),
    block(
      "symbolic-body",
      mass: $m$,
      on: "symbolic-incline",
      mu: (s: $mu_s$, k: $mu_k$),
    ),
  )
  let symbolic-result = results(s)
  assert(symbolic-result.status == "undetermined")
  scene(s, forces: "symbolic-body", components: "symbolic-body")
})

#section("Selected bodies in a valid multi-body situation still solve", {
  let s = situation(
    ground("validation-floor", length: 8),
    block("L", mass: 2, on: "validation-floor", at: 30%),
    block("R", mass: 3, on: "validation-floor", at: 70%),
  )
  assert(results(s, "L").status == "solved")
  assert(results(s, "R").status == "solved")
  scene(s, forces: ("L", "R"))
})



Hello.

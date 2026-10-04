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

#pagebreak()

== Semantic electrical circuit diagrams

#let e = electricity

#section("A series-parallel circuit is laid out from connectivity", {
  let circuit = e.dc-circuit(
    e.voltage-source("V", voltage: 12),
    e.series(
      e.resistor("R1", resistance: 4),
      e.parallel(
        e.resistor("R2", resistance: 6),
        e.resistor("R3", resistance: 3),
      ),
    ),
  )
  e.diagram(circuit)
})

#section("Nested branches remain coordinate-free", {
  let circuit = e.dc-circuit(
    e.voltage-source("supply", voltage: 9),
    e.parallel(
      e.series(
        e.resistor("R1", resistance: 2),
        e.resistor("R2", resistance: 5),
      ),
      e.resistor("R3", resistance: 8),
      e.series(
        e.resistor("R4", resistance: 3),
        e.parallel(
          e.resistor("R5", resistance: 6),
          e.resistor("R6", resistance: 12),
        ),
      ),
    ),
  )
  e.diagram(circuit, style: (scale: 0.82))
})

#pagebreak()

== Routed branches shape a parallel network

#section("A direct branch beside a two-resistor path over the top", {
  let circuit = e.dc-circuit(
    e.voltage-source("V", voltage: 12),
    e.parallel(
      e.resistor("R1", resistance: 10, route: "direct"),
      e.series(
        e.resistor("R2", resistance: 20),
        e.resistor("R3", resistance: 30),
        route: "over",
      ),
    ),
  )
  e.diagram(circuit)
})

#section("The same topology uses the orthogonal layout by default", {
  let circuit = e.dc-circuit(
    e.voltage-source("V", voltage: 12),
    e.parallel(
      e.resistor("R1", resistance: 10),
      e.series(
        e.resistor("R2", resistance: 20),
        e.resistor("R3", resistance: 30),
      ),
    ),
  )
  e.diagram(circuit)
})

#section("Diagram and component styles remain independent", {
  let circuit = e.dc-circuit(
    e.voltage-source(
      "battery",
      voltage: 6,
      style: e.voltage-source-style(
        symbol: "circle",
        fill: rgb("#FFF3BF"),
      ),
    ),
    e.series(
      e.resistor(
        "lamp-load",
        resistance: 7,
        label: $R_L$,
        style: e.resistor-style(
          symbol: "rectangle",
          fill: rgb("#D0EBFF"),
          stroke: 1.2pt + blue,
        ),
      ),
      e.resistor("R2", resistance: 5),
    ),
    style: (
      wire-stroke: 1.1pt + rgb("#495057"),
      junction-fill: blue,
    ),
  )
  e.diagram(circuit, labels: "both")
})

#pagebreak()

== Electrical units and symbol choices

#section("Unit annotations belong to each physical quantity", {
  let circuit = e.dc-circuit(
    e.voltage-source("bias", voltage: 750, unit: "µV"),
    e.parallel(
      e.resistor("sensor", resistance: 12, unit: $mu Omega$, route: "direct"),
      e.series(
        e.resistor("lead-1", resistance: 2, unit: "mΩ"),
        e.resistor("lead-2", resistance: 3, unit: "mΩ"),
        route: "over",
      ),
    ),
  )
  e.diagram(circuit)
})

#section("IEC rectangles and a circular source can be selected individually", {
  let circuit = e.dc-circuit(
    e.voltage-source(
      "source",
      voltage: 5,
      style: e.voltage-source-style(symbol: "circle"),
    ),
    e.series(
      e.resistor("usual", resistance: 10),
      e.resistor(
        "iec",
        resistance: 20,
        style: e.resistor-style(symbol: "rectangle"),
      ),
    ),
  )
  e.diagram(circuit)
})

#pagebreak()

== Diagonal resistors preserve parallel connectivity

#section("Two direct branches and an outer series path form one parallel network", {
  let circuit = e.dc-circuit(
    e.voltage-source("source", voltage: 18),
    e.series(
      e.resistor("input", resistance: 100),
      e.parallel(
        e.resistor("vertical", resistance: 300, route: "under"),
        e.resistor("diagonal", resistance: 200, route: "direct"),
        e.series(
          e.resistor("upper", resistance: 50),
          e.resistor("right", resistance: 250),
          route: "over",
        ),
      ),
      e.resistor("return", resistance: 150),
    ),
  )
  e.diagram(circuit, labels: "value", style: (scale: 0.82))
})

#pagebreak()

    ),
  )
  e.diagram(circuit, labels: "value", style: (scale: 0.82))
})

#pagebreak()

== A descending frame keeps its corner junctions

#section("The outer circuit leaves the split and join dots directly", {
  let circuit = e.dc-circuit(
    e.voltage-source("source", voltage: 18),
    e.parallel(
      e.resistor("vertical", resistance: 300, route: "under"),
      e.resistor("diagonal", resistance: 200, route: "direct"),
      e.series(
        e.resistor("top", resistance: 50),
        e.resistor("right", resistance: 250),
        route: "over",
      ),
    ),
  )
  e.diagram(circuit, labels: "value", style: (scale: 0.82))
})

#pagebreak()

== Zigzag resistors return upward to the outgoing lead

#section("An even number of alternating peaks gives both ends opposite phases", {
  let circuit = e.dc-circuit(
    e.voltage-source("source", voltage: 5),
    e.series(
      e.resistor("sensor", resistance: 12, unit: $mu Omega$, label: $R_s$),
      e.resistor("lead", resistance: 3, unit: "mΩ", label: $R_l$),
    ),
  )
  e.diagram(circuit, labels: "both")
})

#pagebreak()

== Capacitors are semantic two-terminal circuit components

#section("Mixed RC networks use automatic orthogonal placement and farad units", {
  let circuit = e.dc-circuit(
    e.voltage-source("source", voltage: 9),
    e.series(
      e.resistor("charge", resistance: 2.2, unit: "kΩ", label: $R$),
      e.parallel(
        e.capacitor("storage", capacitance: 220, unit: "µF", label: $C_1$),
        e.capacitor(
          "timing",
          capacitance: 47,
          unit: "nF",
          label: $C_2$,
          style: e.capacitor-style(stroke: 1.2pt + blue),
        ),
      ),
    ),
  )
  e.diagram(circuit, labels: "both", style: (scale: 0.82))
})

#section("Capacitor plates and labels rotate with diagonal and vertical branches", {
  let circuit = e.dc-circuit(
    e.voltage-source("source", voltage: 5),
    e.parallel(
      e.capacitor(
        "vertical",
        capacitance: 1,
        unit: "µF",
        label: $C_v$,
        route: "under",
      ),
      e.capacitor(
        "diagonal",
        capacitance: 2,
        unit: "µF",
        label: $C_d$,
        route: "direct",
      ),
      e.series(
        e.resistor("upper", resistance: 50, label: $R_1$),
        e.capacitor("right", capacitance: 3, unit: "µF", label: $C_r$),
        route: "over",
      ),
    ),
  )
  e.diagram(
    circuit,
    labels: "both",
    style: (scale: 0.72),
  )
})

#pagebreak()

== A series load continues onto the return rail

#section("The trailing resistor closes the loop along the bottom instead of widening it", {
  let circuit = e.dc-circuit(
    e.voltage-source("source", voltage: 12),
    e.series(
      e.resistor("input", resistance: 100),
      e.parallel(
        e.resistor("upper", resistance: 300),
        e.resistor("lower", resistance: 200),
      ),
      e.resistor("return", resistance: 150),
    ),
  )
  e.diagram(circuit, labels: "value", style: (scale: 0.82))
})

#section("The same load on one rail, for comparison", {
  let circuit = e.dc-circuit(
    e.voltage-source("flat-source", voltage: 12),
    e.series(
      e.resistor("flat-input", resistance: 100),
      e.parallel(
        e.resistor("flat-upper", resistance: 300),
        e.resistor("flat-lower", resistance: 200),
      ),
      e.resistor("flat-return", resistance: 150),
    ),
  )
  e.diagram(circuit, labels: "value", fold: false, style: (scale: 0.82))
})

#pagebreak()

== A descending load closes along its own exit level

#section("Series and parallel composition alone draws the textbook diagonal figure", {
  let circuit = e.dc-circuit(
    e.voltage-source("V", voltage: 18),
    e.series(
      e.resistor("R100", resistance: 100),
      e.parallel(
        e.resistor("R300", resistance: 300, route: "under"),
        e.resistor("R200", resistance: 200, route: "direct"),
        e.series(
          e.resistor("R50", resistance: 50),
          e.resistor("R250", resistance: 250),
          route: "over",
        ),
      ),
      e.resistor("R150", resistance: 150),
    ),
  )
  e.diagram(circuit, labels: "value", style: (scale: 0.82))
})

#section("A returning run too wide for that level drops to a rail below the load", {
  let circuit = e.dc-circuit(
    e.voltage-source("wide-source", voltage: 18),
    e.series(
      e.resistor("wide-input", resistance: 100),
      e.parallel(
        e.resistor("wide-vertical", resistance: 300, route: "under"),
        e.resistor("wide-diagonal", resistance: 200, route: "direct"),
        e.series(
          e.resistor("wide-upper", resistance: 50),
          e.resistor("wide-right", resistance: 250),
          route: "over",
        ),
      ),
      e.resistor("wide-first-return", resistance: 150),
      e.resistor("wide-second-return", resistance: 75),
    ),
  )
  e.diagram(circuit, labels: "value", style: (scale: 0.72))
})

#pagebreak()

== The return rail preserves the declared order

#section("Walking from the source, the bottom rail runs backwards through the chain", {
  let circuit = e.dc-circuit(
    e.voltage-source("ordered-source", voltage: 12),
    e.series(
      e.resistor("first", resistance: 10),
      e.parallel(
        e.resistor("branch-upper", resistance: 20),
        e.resistor("branch-lower", resistance: 30),
      ),
      e.resistor("third", resistance: 40),
      e.resistor("fourth", resistance: 50),
    ),
  )
  e.diagram(circuit, labels: "name", style: (scale: 0.82))
})

#section("A plain series chain splits evenly between the two rails", {
  let circuit = e.dc-circuit(
    e.voltage-source("plain-source", voltage: 12),
    e.series(
      e.resistor("plain-first", resistance: 10),
      e.resistor("plain-second", resistance: 20),
    ),
  )
  e.diagram(circuit, labels: "value", style: (scale: 0.82))
})

#section("A single component has nothing to split, so it keeps one rail", {
  let circuit = e.dc-circuit(
    e.voltage-source("lone-source", voltage: 12),
    e.resistor("lone", resistance: 10),
  )
  e.diagram(circuit, labels: "value", style: (scale: 0.82))
})

#pagebreak()

== One frame vocabulary, four shapes

#section("Direct plus over is a level frame peaking at the middle", {
  e.diagram(e.dc-circuit(
    e.voltage-source("over-source", voltage: 12),
    e.parallel(
      e.resistor("over-direct", resistance: 10, route: "direct"),
      e.series(
        e.resistor("over-left", resistance: 20),
        e.resistor("over-right", resistance: 30),
        route: "over",
      ),
    ),
  ), labels: "value", style: (scale: 0.7))
})

#section("Direct plus under is the same frame reflected", {
  e.diagram(e.dc-circuit(
    e.voltage-source("under-source", voltage: 12),
    e.parallel(
      e.resistor("under-direct", resistance: 10, route: "direct"),
      e.series(
        e.resistor("under-left", resistance: 20),
        e.resistor("under-right", resistance: 30),
        route: "under",
      ),
    ),
  ), labels: "value", style: (scale: 0.7))
})

#section("A single component on a corner route wires its second leg", {
  e.diagram(e.dc-circuit(
    e.voltage-source("single-source", voltage: 12),
    e.parallel(
      e.resistor("single-direct", resistance: 10, route: "direct"),
      e.resistor("single-corner", resistance: 40, route: "over"),
    ),
  ), labels: "value", style: (scale: 0.7))
})

#section("Branches on both sides make the frame descend", {
  e.diagram(e.dc-circuit(
    e.voltage-source("descend-source", voltage: 18),
    e.parallel(
      e.resistor("descend-under", resistance: 300, route: "under"),
      e.resistor("descend-direct", resistance: 200, route: "direct"),
      e.series(
        e.resistor("descend-top", resistance: 50),
        e.resistor("descend-right", resistance: 250),
        route: "over",
      ),
    ),
  ), labels: "value", style: (scale: 0.7))
})

#pagebreak()

== A small load still draws a readable loop

#section("The loop is widened to a floor, and the added width centres the runs", {
  e.diagram(e.dc-circuit(
    e.voltage-source("narrow-source", voltage: 12),
    e.series(
      e.resistor("narrow-first", resistance: 10),
      e.resistor("narrow-second", resistance: 20),
    ),
  ), labels: "value", style: (scale: 0.8))
})

#section("Without the floor, the same circuit closes as a tall narrow loop", {
  e.diagram(e.dc-circuit(
    e.voltage-source("thin-source", voltage: 12),
    e.series(
      e.resistor("thin-first", resistance: 10),
      e.resistor("thin-second", resistance: 20),
    ),
    style: (minimum-loop-width: 0.1),
  ), labels: "value", style: (scale: 0.8))
})

#section("A wider floor stretches the rails and keeps the runs centred", {
  e.diagram(e.dc-circuit(
    e.voltage-source("wide-source", voltage: 12),
    e.series(
      e.resistor("wide-first", resistance: 10),
      e.resistor("wide-second", resistance: 20),
    ),
    style: (minimum-loop-width: 8),
  ), labels: "value", style: (scale: 0.8))
})

#section("A load already wider than the floor is untouched by it", {
  e.diagram(e.dc-circuit(
    e.voltage-source("unaffected-source", voltage: 18),
    e.series(
      e.resistor("unaffected-input", resistance: 100),
      e.parallel(
        e.resistor("unaffected-under", resistance: 300, route: "under"),
        e.resistor("unaffected-direct", resistance: 200, route: "direct"),
        e.series(
          e.resistor("unaffected-top", resistance: 50),
          e.resistor("unaffected-right", resistance: 250),
          route: "over",
        ),
      ),
      e.resistor("unaffected-return", resistance: 150),
    ),
  ), labels: "value", style: (scale: 0.8))
})

#pagebreak()

== A wall is one contact like any other

A block held against a wall by a horizontal push is one body with one contact,
so the same equations balance it. With $m = 4$ kg and $g = 9.81$, the weight
$m g = 39.24$ N runs along the wall and the push sets the normal force.

#let wall-push(push) = situation(
  wall("W", side: left, height: 4),
  block("A", mass: 4, on: "W", at: 45%, mu: (s: 0.50, k: 0.40)),
  force(on: "A", magnitude: push, angle: 180deg),
)

#section(
  "120 N holds it: N = 120, available 0.50 x 120 = 60 >= 39.24, so it stays",
  {
    scene(wall-push(120), forces: true)
    v(0.4em)
    solve(wall-push(120), find: "normal")
    [ — regime: #solve(wall-push(120), find: "regime"), ]
    solve(wall-push(120), find: "friction")
  },
)

#section(
  "60 N does not: available 30 < 39.24, so a = (39.24 - 0.40 x 60) / 4 = 3.81",
  {
    fbd(wall-push(60), "A")
    v(0.4em)
    solve(wall-push(60))
  },
)

#pagebreak()

== A ceiling carries the outward normal downwards

A block pressed against a ceiling has its weight pulling it off the surface, so
the normal force is what is left of the push: with $m = 2$ kg and a 50 N upward
press, $N = 50 - 19.62 = 30.38$ N. A 10 N sideways push then needs 10 N of
friction against the $0.25 times 30.38 = 7.60$ N available, so it slides at
$a = (10 - 0.20 times 30.38) / 2 = 1.962$ m/s².

#let ceiling-situation = situation(
  ceiling("C", length: 6, height: 3.4),
  block("B", mass: 2, on: "C", at: 50%, mu: (s: 0.25, k: 0.20)),
  force(on: "B", magnitude: 50, angle: 90deg),
  force(on: "B", magnitude: 10, angle: 0deg),
)

#section("Scene with the forces in place", scene(ceiling-situation, forces: true))

#section("Free-body diagram and the answer", {
  fbd(ceiling-situation, "B")
  v(0.4em)
  solve(ceiling-situation, find: "normal")
  [ — ]
  solve(ceiling-situation)
})

#pagebreak()

== A hanging body carries its own weight

The hanging-body model puts the whole weight in the rope: $T = m g = 3 times
9.81 = 29.43$ N. Drawing the rope does not change that, because a connector
between a body and something fixed is what holds the body up rather than a joint
to a second unknown.

#let hanging-situation = situation(
  ceiling("roof", length: 6, height: 3.4),
  block("H", mass: 3, hanging: (on: "roof", at: 50%), drop: 1.6),
  rope("cord", from: (on: "roof", at: 50%), to: "H.top"),
)

#section("Scene", scene(hanging-situation))

#section("The tension is filled in on the free-body diagram", {
  fbd(hanging-situation, "H")
  v(0.4em)
  solve(hanging-situation)
})

#section("Its force table uses world axes, because it rests on nothing", {
  force-table(hanging-situation, "H")
})

#pagebreak()

== A left-facing ramp resolves loads in its own frame

The slope climbs to the left, so a push to the right acts *down* the incline and
adds to gravity instead of opposing it. With $m = 4$ kg, $theta = 30 degree$ and
a frictionless contact, a 20 N push to the right gives
$N = 33.98 - 20 sin 30 degree = 23.98$ N and
$a = (19.62 + 20 cos 30 degree) / 4 = 9.235$ m/s².

#let left-ramp-situation = situation(
  ramp("slope", angle: 30deg, length: 6.5, facing: left),
  block("A", mass: 4, on: "slope", at: 50%, mu: 0),
  force(on: "A", magnitude: 20, angle: 0deg),
)

#section("Scene with the forces in place", scene(left-ramp-situation, forces: true))

#section("The answer", {
  solve(left-ramp-situation, find: "normal")
  [ — ]
  solve(left-ramp-situation)
})

#pagebreak()

== Which model a situation matches

`model-of` names the model before anything is solved, and the figures never wait
on the answer.

#let arc-situation = situation(
  arc("loop", radius: 2.2, start-angle: 200deg, end-angle: 340deg, side: "inside"),
  block("P", mass: 2, on: "loop", at: 50%),
)
#let stacked-situation = situation(
  ground("floor", length: 7),
  block("L", mass: 3, on: "floor", at: 35%),
  block("R", mass: 2, touching: "L"),
)

#section("Four situations and the model each falls under", table(
  columns: 2,
  align: (left, left),
  stroke: none,
  table.hline(),
  table.header([Situation], [Model]),
  table.hline(),
  [block on an incline], repr(model-of(incline-situation, "A")),
  [block pressed on a wall], repr(model-of(wall-push(120), "A")),
  [block hanging from a roof], repr(model-of(hanging-situation, "H")),
  [block on a curved support], repr(model-of(arc-situation, "P")),
  [two blocks in contact], repr(model-of(stacked-situation, "L")),
  table.hline(),
))

#section(
  "A body no model matches still draws, and still enumerates its forces",
  {
    scene(arc-situation)
    v(0.4em)
    fbd(arc-situation, "P")
    v(0.4em)
    force-table(arc-situation, "P")
  },
)

#section("So do two blocks in contact", {
  scene(stacked-situation)
  v(0.4em)
  force-table(stacked-situation, "L")
})

#pagebreak()

== A DC circuit reduces to what it settles at

12 V across $R_1 = 4 Omega$ in series with $R_2 = 6 Omega$ parallel to a
capacitor. The capacitor carries no steady current, so the group is 6 Ω,
$R_"eq" = 10 Omega$, $I = 1.2$ A, and the capacitor sits at the group's
7.2 V.

#let reduced-circuit = e.dc-circuit(
  e.voltage-source("V", voltage: 12),
  e.series(
    e.resistor("R1", resistance: 4),
    e.parallel(
      e.resistor("R2", resistance: 6),
      e.capacitor("C1", capacitance: 220, unit: "µF"),
    ),
  ),
)

#section("Diagram", e.diagram(reduced-circuit, style: (scale: 0.8)))

#section("What it settles at", {
  e.solve(reduced-circuit)
  [ — ]
  e.solve(reduced-circuit, find: "current")
  [ — ]
  e.solve(reduced-circuit, "C1")
})

#section("Every component", e.component-table(reduced-circuit))

#section("A network with no numbers reduces to a closed form", {
  let symbolic-circuit = e.dc-circuit(
    e.voltage-source("V"),
    e.parallel(e.resistor("R1"), e.resistor("R2")),
  )
  e.solve(symbolic-circuit)
  [ — ]
  e.solve(symbolic-circuit, find: "current")
})

#pagebreak()

== Capacitors block a steady current

Two capacitors in series across 12 V share one charge, so
$C_"eq" = 1.2$ F, $Q = 14.4$ C, and the voltages divide as $Q slash C$:
7.2 V and 4.8 V.

#let capacitive-circuit = e.dc-circuit(
  e.voltage-source("V", voltage: 12),
  e.series(e.capacitor("C1", capacitance: 2), e.capacitor("C2", capacitance: 3)),
)

#section("Diagram", e.diagram(capacitive-circuit, style: (scale: 0.8)))

#section("The capacitive divider", {
  e.solve(capacitive-circuit)
  [ — ]
  e.solve(capacitive-circuit, "C1")
  [ — ]
  e.solve(capacitive-circuit, "C2")
})

#section("A capacitor in series with a resistor stops the current entirely", {
  let blocked-circuit = e.dc-circuit(
    e.voltage-source("V", voltage: 12),
    e.series(e.resistor("R1", resistance: 4), e.capacitor("C1", capacitance: 2)),
  )
  e.diagram(blocked-circuit, style: (scale: 0.8))
  v(0.4em)
  e.component-table(blocked-circuit)
})

#pagebreak()

#import "../src/shared/expression.typ"

== Symbolic closed forms, checked against the textbook

Every quantity below is declared as a symbol, so there is nothing to fold and
the solver must state its answer as algebra. The middle column is what
`typed-physics` derives; the right column is the formula as a mechanics text
writes it. They should read the same.

Two things to know while reading these. A symbolic situation cannot decide its
own friction regime, because comparing $mu_s N$ against the friction required
needs numbers, so each case states the regime with `assume:` and the result
records that it was given rather than checked. And the friction and acceleration
of a rough contact are written in terms of $N$, whose own closed form is the
line above them.

#let closed-form(term) = expression.math-of(term)

#let derivation(caption, rows) = section(caption, table(
  columns: (auto, 1fr, 1fr),
  align: (left, left, left),
  stroke: none,
  inset: (x: 6pt, y: 5pt),
  table.hline(),
  table.header([Quantity], [Derived], [Textbook]),
  table.hline(),
  ..rows.flatten(),
  table.hline(),
))

=== A body on an incline

#let free-incline = situation(
  ramp("incline", angle: 30deg, length: 6),
  block("A", mass: $m$, on: "incline", at: 50%),
  gravity: $g$,
)
#let rough-incline = situation(
  ramp("incline", angle: 30deg, length: 6),
  block("A", mass: $m$, on: "incline", at: 50%, mu: (s: $mu_s$, k: $mu_k$)),
  gravity: $g$,
)

#let free-answer = results(free-incline, assume: "sliding")
#derivation("Frictionless", (
  ($N$, closed-form(free-answer.normal.expression), $m g cos theta$),
  ($a$, closed-form(free-answer.acceleration.expression), $g sin theta$),
))

#let sliding-answer = results(rough-incline, assume: "sliding")
#derivation("Rough, sliding", (
  ($N$, closed-form(sliding-answer.normal.expression), $m g cos theta$),
  ($f_k$, closed-form(sliding-answer.friction.expression), $mu_k N$),
  (
    $a$,
    closed-form(sliding-answer.acceleration.expression),
    $g sin theta - mu_k g cos theta$,
  ),
))

#let static-answer = results(rough-incline, assume: "static")
#derivation("Rough, held at rest", (
  ($N$, closed-form(static-answer.normal.expression), $m g cos theta$),
  (
    [required],
    closed-form(static-answer.required.expression),
    $m g sin theta$,
  ),
  (
    [available],
    closed-form(static-answer.available.expression),
    $mu_s N$,
  ),
  ($f_s$, closed-form(static-answer.friction.expression), $m g sin theta$),
))

#pagebreak()

=== A body pushed along level ground

Level ground is the incline equations with an exact zero for $theta$, so the
sines and cosines fold away on their own rather than through a second set of
formulas.

#let horizontal-push = situation(
  ground("floor", length: 7),
  block("A", mass: $m$, on: "floor", at: 40%, mu: (s: $mu_s$, k: $mu_k$)),
  force(on: "A", magnitude: $F$, angle: 0deg),
  gravity: $g$,
)
#let horizontal-answer = results(horizontal-push, assume: "sliding")
#derivation("Pushed horizontally", (
  ($N$, closed-form(horizontal-answer.normal.expression), $m g$),
  ([required], closed-form(horizontal-answer.required.expression), $F$),
  (
    $a$,
    closed-form(horizontal-answer.acceleration.expression),
    $(F - mu_k m g) / m$,
  ),
))

The same push tilted up by $phi$ lifts some of the weight off the surface, which
lowers the normal force and the friction with it.

#let angled-push = situation(
  ground("floor", length: 7),
  block("A", mass: $m$, on: "floor", at: 40%, mu: (s: $mu_s$, k: $mu_k$)),
  force(on: "A", magnitude: $F$, angle: 30deg),
  gravity: $g$,
)
#let angled-answer = results(angled-push, assume: "sliding")
#derivation("Pushed at an angle above the horizontal", (
  ($N$, closed-form(angled-answer.normal.expression), $m g - F sin phi$),
  ([required], closed-form(angled-answer.required.expression), $F cos phi$),
  (
    $a$,
    closed-form(angled-answer.acceleration.expression),
    $(F cos phi - mu_k (m g - F sin phi)) / m$,
  ),
))

#pagebreak()

=== The contacts a wall and a ceiling make

These are the two surfaces the single-contact model reaches through the placed
axes rather than through a declared angle, so their closed forms are the check
that the frame is right.

A block held against a wall by a horizontal push: the push alone sets the normal
force, and the whole weight has to be carried by friction.

#let wall-push = situation(
  wall("side", side: left, height: 4),
  block("A", mass: $m$, on: "side", at: 45%, mu: (s: $mu_s$, k: $mu_k$)),
  force(on: "A", magnitude: $F$, angle: 180deg),
  gravity: $g$,
)
#let wall-answer = results(wall-push, assume: "sliding")
#derivation("Held against a wall", (
  ($N$, closed-form(wall-answer.normal.expression), $F$),
  ([required], closed-form(wall-answer.required.expression), $m g$),
  ([available], closed-form(wall-answer.available.expression), $mu_s N$),
  (
    $a$,
    closed-form(wall-answer.acceleration.expression),
    $(m g - mu_k F) / m$,
  ),
))

A block pressed against a ceiling: the weight pulls it off the surface, so only
what is left of the press appears as the normal force. A second push $P$ slides
it along.

#let ceiling-press = situation(
  ceiling("roof", length: 6, height: 3),
  block("A", mass: $m$, on: "roof", at: 50%, mu: (s: $mu_s$, k: $mu_k$)),
  force(on: "A", magnitude: $F$, angle: 90deg),
  force(on: "A", magnitude: $P$, angle: 0deg),
  gravity: $g$,
)
#let ceiling-answer = results(ceiling-press, assume: "sliding")
#derivation("Pressed against a ceiling", (
  ($N$, closed-form(ceiling-answer.normal.expression), $F - m g$),
  ([required], closed-form(ceiling-answer.required.expression), $P$),
  (
    $a$,
    closed-form(ceiling-answer.acceleration.expression),
    $(P - mu_k (F - m g)) / m$,
  ),
))

=== A force up the slope, and a body on a rope

#let up-the-slope = situation(
  ramp("incline", angle: 30deg, length: 6),
  block("A", mass: $m$, on: "incline", at: 50%, mu: (s: $mu_s$, k: $mu_k$)),
  force(on: "A", magnitude: $F$, angle: 30deg),
  gravity: $g$,
)
#let up-answer = results(up-the-slope, assume: "static")
#let hanging-symbolic = situation(
  ceiling("roof", length: 6, height: 3),
  block("H", mass: $m$, hanging: (on: "roof", at: 50%)),
  gravity: $g$,
)
#derivation("Pulled up a rough incline, and hanging at rest", (
  ($N$, closed-form(up-answer.normal.expression), $m g cos theta$),
  (
    [required],
    closed-form(up-answer.required.expression),
    $F - m g sin theta$,
  ),
  (
    $T$,
    closed-form(results(hanging-symbolic).tension.expression),
    $m g$,
  ),
))

#pagebreak()

=== Circuits with no numbers

A network declared without values reduces to a closed form the same way. The
current a component carries is written in terms of $I$, and a capacitor's
voltage in terms of the charge $Q$ its chain holds, each of which is stated on
its own line.

#let series-network = e.dc-circuit(
  e.voltage-source("V"),
  e.series(e.resistor("R1"), e.resistor("R2")),
)
#let series-answer = e.results(series-network)
#derivation("Two resistors in series", (
  ($R_"eq"$, closed-form(series-answer.resistance.expression), $#"R1" + #"R2"$),
  ($I$, closed-form(series-answer.current.expression), $V / (#"R1" + #"R2")$),
  (
    $V_#"R1"$,
    closed-form(series-answer.components.R1.voltage),
    $I #"R1"$,
  ),
))

#let parallel-network = e.dc-circuit(
  e.voltage-source("V"),
  e.parallel(e.resistor("R1"), e.resistor("R2")),
)
#let parallel-answer = e.results(parallel-network)
#derivation("Two resistors in parallel", (
  (
    $R_"eq"$,
    closed-form(parallel-answer.resistance.expression),
    $(#"R1" #"R2") / (#"R1" + #"R2")$,
  ),
  ($I$, closed-form(parallel-answer.current.expression), $V / R_"eq"$),
  (
    $I_#"R1"$,
    closed-form(parallel-answer.components.R1.current),
    $V / #"R1"$,
  ),
))

#let capacitor-network = e.dc-circuit(
  e.voltage-source("V"),
  e.series(e.capacitor("C1"), e.capacitor("C2")),
)
#let capacitor-answer = e.results(capacitor-network)
#derivation("Two capacitors in series, which share one charge", (
  (
    $C_"eq"$,
    closed-form(capacitor-answer.capacitance.expression),
    $(#"C1" #"C2") / (#"C1" + #"C2")$,
  ),
  (
    $V_#"C1"$,
    closed-form(capacitor-answer.components.C1.voltage),
    $Q / #"C1"$,
  ),
  (
    $V_#"C2"$,
    closed-form(capacitor-answer.components.C2.voltage),
    $Q / #"C2"$,
  ),
))

#pagebreak()

== Inferred spring attachment height

#section("A wall spring without at aligns to its body anchor", {
  let s = situation(
    ground("floor", length: 10),
    wall("wall", side: left, height: 2.4),
    block("A", on: "floor", at: 22%, size: 1.2),
    block("B", on: "floor", at: 62%, size: 1.5),
    spring("s", from: (on: "wall"), to: "A.left", coils: 7),
    velocity(on: "A", angle: 0deg, label: $v_0$),
  )
  let placed-spring = s.connectors.first()
  assert(placed-spring.start.at(1) == placed-spring.end.at(1))
  scene(s, dimensions: (
    dimension(
      from: "A.right",
      to: "B.left",
      orientation: "horizontal",
      side: "above",
      label: $d$,
    ),
  ))
})

#pagebreak()

== Rope tension and friction directions (issue #2)

#import "diagnostics/rope-forces.typ": pulley-situation

#let tension-regression = pulley-situation()

#section("Reported setup: 4 kg on the floor, 3 kg hanging", scene(
  tension-regression,
  labels: "both",
  frictions: true,
))

#section("A: tension toward the pulley, friction away from it; B: one upward tension", grid(
  columns: (1fr, 1fr),
  align: center,
  fbd(tension-regression, "A"),
  fbd(tension-regression, "B"),
))

#let mirrored-tension-regression = pulley-situation(leftward: true, reverse-ends: true)

#section("Pulley on the left, with the rope endpoints declared in reverse", scene(
  mirrored-tension-regression,
  labels: "both",
))

#section("A: tension leftward, friction rightward", grid(
  columns: (1fr, 1fr),
  align: center,
  fbd(mirrored-tension-regression, "A"),
  fbd(mirrored-tension-regression, "B"),
))

The assertions check both endpoint orders on both sides, the local rope
tangents, the friction directions, and that each hanging body has only one
tension. Tension magnitudes remain unknown for this coupled system.

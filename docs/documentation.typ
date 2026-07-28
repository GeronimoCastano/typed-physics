// typed-physics documentation
//
// Compile with:
//   typst compile --root . docs/documentation.typ docs/documentation.pdf

#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.1": *
#import "@preview/cetz:0.5.2"
#import "../src/lib.typ" as physics

#let version = "0.1.0"
#let accent = rgb("#1971C2")
#let accent-soft = rgb("#E7F0FA")

// ── Theme ────────────────────────────────────────────────────────────────────

#set document(title: "typed-physics User Guide", author: "Geronimo Castaño")
#set text(font: "New Computer Modern", size: 10.5pt, lang: "en")
#set par(justify: true, leading: 0.62em, spacing: 1.1em)
#set heading(numbering: "1.1")
#show link: set text(fill: accent)
#show ref: set text(fill: accent)

#show raw.where(block: true): set block(breakable: false)
#show raw.where(block: true): set text(size: 8.6pt)

#show heading.where(level: 1): it => {
  pagebreak(weak: true)
  block(width: 100%, breakable: false, sticky: true, {
    set text(fill: accent, size: 18pt, weight: "bold")
    if it.numbering != none [#counter(heading).display() #h(0.5em)]
    it.body
    v(-0.2em)
    line(length: 100%, stroke: 0.6pt + accent)
  })
}
#show heading.where(level: 2): it => block(above: 1.3em, below: 0.7em, sticky: true, {
  set text(fill: accent.darken(8%), size: 13pt, weight: "bold")
  if it.numbering != none [#counter(heading).display() #h(0.4em)]
  it.body
})
#show heading.where(level: 3): it => block(above: 1.1em, below: 0.6em, sticky: true, {
  set text(fill: accent.darken(18%), size: 11pt, weight: "bold")
  it.body
})

// ── codly ────────────────────────────────────────────────────────────────────

#show: codly-init.with()
#codly(
  languages: codly-languages,
  zebra-fill: none,
  inset: (x: 0.5em, y: 0.32em),
  radius: 0pt,
  stroke: none,
)

// ── Example helper: source on the left, live render on the right ─────────────

// Examples are evaluated against the package's own public names, so an example
// that would not compile in a reader's document does not compile here either.
#let package-scope = (
  situation: physics.situation,
  arc: physics.arc,
  ball: physics.ball,
  disk: physics.disk,
  ring: physics.ring,
  point-mass: physics.point-mass,
  pulley: physics.pulley,
  rope: physics.rope,
  spring: physics.spring,
  velocity: physics.velocity,
  angular-velocity: physics.angular-velocity,
  ground: physics.ground,
  wall: physics.wall,
  ceiling: physics.ceiling,
  ramp: physics.ramp,
  rod: physics.rod,
  pivot: physics.pivot,
  support: physics.support,
  torque: physics.torque,
  pendulum: physics.pendulum,
  block: physics.block,
  force: physics.force,
  dimension: physics.dimension,
  scene: physics.scene,
  fbd: physics.fbd,
  components: physics.components,
  solve: physics.solve,
  force-table: physics.force-table,
  results: physics.results,
  draw: physics.draw,
  theme: physics.theme,
  block-style: physics.block-style,
  surface-style: physics.surface-style,
  force-style: physics.force-style,
  connector-style: physics.connector-style,
  cetz: cetz,
)

// `placement:` lets a worked solution read left-aligned like the prose around
// it while a figure stays centred in its frame.
#let example(body, side: true, placement: center + horizon) = block(
  width: 100%,
  stroke: 0.6pt + luma(210),
  radius: 5pt,
  clip: true,
  breakable: false,
  {
    let rendered = block(
      width: 100%, fill: white, inset: (x: 12pt, y: 14pt),
      align(placement, eval(body.text, mode: "markup", scope: package-scope)),
    )
    if side {
      grid(
        columns: (1.05fr, 0.95fr), column-gutter: 0pt,
        block(width: 100%, fill: luma(248), inset: (y: 4pt), body),
        block(width: 100%, stroke: (left: 0.6pt + luma(220)), rendered),
      )
    } else {
      block(width: 100%, fill: luma(248), inset: (y: 4pt), body)
      block(width: 100%, stroke: (top: 0.6pt + luma(220)), rendered)
    }
  },
)

#let report-example(body) = example(body, side: false, placement: left + top)

// Keep a subsection's prose and example together on one page.
#let demo(body) = block(breakable: false, width: 100%, body)

#let callout(clr, label, body) = block(
  width: 100%, fill: clr.lighten(90%), stroke: (left: 2.5pt + clr),
  radius: (right: 4pt), inset: (x: 12pt, y: 9pt), above: 1.1em, below: 1.1em,
  { text(fill: clr, weight: "bold")[#label.#h(0.5em)]; body },
)
#let note(body) = callout(accent, "Note", body)
#let warn(body) = callout(rgb("#b54708"), "Note", body)

#let c(it) = raw(it, lang: none)

#let reference-table(..rows) = table(
  columns: (auto, 1fr), inset: 7pt,
  align: (x, y) => if y == 0 { center + horizon } else { left + horizon },
  fill: (_, y) => if y == 0 { accent-soft }, stroke: 0.5pt + luma(210),
  ..rows,
)

// ── Cover ────────────────────────────────────────────────────────────────────

#set page(paper: "a4", margin: (x: 2.2cm, top: 2.6cm, bottom: 2.4cm), header: none, footer: none)

#v(1.2fr)
#align(center)[
  #text(size: 40pt, weight: "bold", fill: accent)[typed-physics]
  #v(0.2em)
  #text(size: 15pt, fill: luma(90))[Mechanics figures, free-body diagrams, and solutions from one declaration]
  #v(0.4em)
  #text(size: 12pt, weight: "bold")[User Guide]
  #v(1.6em)
  #block(fill: accent-soft, radius: 8pt, inset: 18pt, {
    let cover-situation = physics.situation(
      physics.ramp("incline", angle: 30deg, length: 7),
      physics.block("A", mass: 4, on: "incline", at: 55%, mu: (s: 0.40, k: 0.30)),
    )
    physics.scene(cover-situation, labels: "both", angles: "both")
  })
  #v(1.4em)
  #text(size: 11pt)[Version #version]
]
#v(1.6fr)

// ── Header / footer for the body ─────────────────────────────────────────────

#set page(
  header: context {
    set text(size: 8.5pt, fill: luma(130))
    grid(columns: (1fr, auto),
      align(left)[typed-physics · User Guide],
      align(right)[v#version])
    v(-0.6em)
    line(length: 100%, stroke: 0.4pt + luma(210))
  },
  footer: context {
    set text(size: 8.5pt, fill: luma(130))
    align(center, counter(page).display("1"))
  },
)
#counter(page).update(1)

#pagebreak()
#outline(title: [Contents], indent: 1.2em, depth: 2)

// ═════════════════════════════════════════════════════════════════════════════
= Getting started
// ═════════════════════════════════════════════════════════════════════════════

You describe a mechanics problem once, with #c("situation()"), and ask it for
the pieces you want: a figure, a free-body diagram, a worked solution, a single
number.

== Installation

Import the package from the Typst preview namespace. A wildcard import gives you
every public symbol:

```typ
#import "@preview/typed-physics:0.1.0": *
```

Or import only what you need:

```typ
#import "@preview/typed-physics:0.1.0": situation, ramp, block, scene, fbd, solve
```

#warn[
  #c("block") is this package's body constructor, so a wildcard import shadows
  Typst's own #c("block"). Reach for the built-in as #c("std.block"), or import
  only the names you use.
]

== Your first situation

Declare a surface, put a body on it, and ask for the figure.

#demo[
  #example(```typ
  #let s = situation(
    ground(length: 6),
    block("A", mass: 3, on: "ground"),
  )
  #scene(s)
  ```)
]

Every other view takes the same #c("s"). This one lists the forces on the block
and, since the numbers are all there, draws each arrow in proportion to the
force it stands for.

#demo[
  #example(```typ
  #let s = situation(
    ramp("incline", angle: 25deg),
    block("A", mass: 3, on: "incline",
      mu: 1.0),
  )
  #fbd(s, "A")
  ```)
]

== What you can build

#reference-table(
  [*Function*], [*What it gives you*],
  [#c("situation(..elements)")], [The problem. Everything else takes it as its first argument.],
  [#c("ground"), #c("wall"), #c("ceiling"), #c("ramp"), #c("arc")], [Straight and curved surfaces to rest on or against.],
  [#c("block"), #c("ball"), #c("point-mass"), #c("disk"), #c("ring")], [Bodies, including rotating-body outlines.],
  [#c("rod"), #c("pivot"), #c("support"), #c("torque")], [Drawing vocabulary for rigid-body statics.],
  [#c("pendulum")], [A suspended bob, string, construction line, and angle.],
  [#c("rope"), #c("spring"), #c("pulley")], [Connectors.],
  [#c("force"), #c("velocity"), #c("angular-velocity")], [What acts on a body, and how it is already moving or rotating.],
  [#c("dimension")], [A scene-only distance annotation between anchors or points.],
  [#c("scene(s)")], [The figure.],
  [#c("fbd(s, name)")], [A free-body diagram.],
  [#c("components(s, name)")], [The weight resolved into the surface's axes.],
  [#c("solve(s)")], [One stated quantity.],
  [#c("force-table(s)")], [Every force with its components.],
  [#c("results(s)")], [The solution as a dictionary of numbers.],
  [#c("draw(s)")], [The scene as CeTZ elements, to draw on top of.],
  [#c("block-style"), #c("surface-style"), #c("force-style")], [Build the #c("style:") dictionary one element takes. See @styling.],
  [#c("theme")], [The default style dictionary.],
)

The drawing vocabulary covers straight and curved surfaces, particle and rigid
bodies, constraints, connectors, loads, motion, and pendulums. The solver is
narrower: it balances one supported block, ball, or point mass on a ground or
ramp and states the quantities that fall out. @limitations lists what it does
not do.

// ═════════════════════════════════════════════════════════════════════════════
= Quick reference <quick-reference>
// ═════════════════════════════════════════════════════════════════════════════

Every public function and argument is collected here. The sections after this
reference explain what the arguments mean and show live examples.

== Situation and surfaces

```typ
#situation(..declarations, gravity: 9.81, style: (:))

#ground(..name, length: 8, from: none, mu: none, style: (:))
#wall(..name, side: left, height: 4, from: none, mu: none, style: (:))
#ceiling(..name, length: 8, height: 4, from: none, mu: none, style: (:))
#ramp(
  name,
  angle: 30deg,
  length: 6,
  facing: right,
  from: none,
  mu: none,
  symbol: auto,
  style: (:),
)
#arc(
  name,
  radius: 3,
  start-angle: -90deg,
  end-angle: 90deg,
  side: "outside",    // or "inside"
  from: none,
  mu: none,
  style: (:),
)
```

== Bodies

```typ
#block(
  name,
  mass: none,
  on: none,
  at: 50%,
  touching: none,
  side: right,
  hanging: none,
  drop: 1.5,
  size: 1,
  mu: none,
  label: auto,
  symbol: auto,
  style: (:),
)
```

#pagebreak()

```typ
#ball(
  name,
  mass: none,
  on: none,
  at: 50%,
  touching: none,
  side: right,
  hanging: none,
  drop: 1.5,
  radius: 0.5,
  mu: none,
  label: auto,
  symbol: auto,
  style: (:),
)
```

```typ
#point-mass(
  name,
  mass: none,
  on: none,
  at: 50%,
  touching: none,
  side: right,
  hanging: none,
  drop: 1.5,
  radius: 0.09,
  label: auto,
  symbol: auto,
  style: (:),
)
```

#pagebreak()

```typ
#disk(
  name,
  mass: none,
  on: none,
  at: 50%,
  touching: none,
  side: right,
  hanging: none,
  drop: 1.5,
  radius: 0.5,
  radius-mark: true, // or false
  orientation: 0deg,
  mu: none,
  label: auto,
  symbol: auto,
  style: (:),
)

#ring(
  name,
  mass: none,
  on: none,
  at: 50%,
  touching: none,
  side: right,
  hanging: none,
  drop: 1.5,
  radius: 0.5,
  radius-mark: false, // or true
  orientation: 0deg,
  mu: none,
  label: auto,
  symbol: auto,
  style: (:),
)
```

#pagebreak()

== Connectors, loads, and motion

```typ
#pulley(name, at: none, radius: 0.4, style: (:))
#rope(..name, from: none, to: none, over: none, style: (:))
#spring(..name, from: none, to: none, coils: 6, width: 0.28, style: (:))

#force(on: none, magnitude: none, angle: 0deg, at: auto,
       label: auto, style: (:))
#velocity(on: none, magnitude: none, angle: 0deg, label: auto, style: (:))
#angular-velocity(
  on: none,
  magnitude: none,
  direction: "clockwise", // or "counterclockwise"
  radius: auto,
  start-angle: auto,
  end-angle: auto,
  label: auto,
  style: (:),
)
```

== Rigid structures and pendulums

```typ
#rod(
  name,
  from: none,
  to: none,
  length: 4,
  angle: 0deg,
  thickness: 0.16,
  mass: none,
  center-of-mass: 50%,
  label: auto,
  symbol: auto,
  style: (:),
)
#pivot(name, at: none, radius: 0.12, style: (:))
#support(name, at: none, kind: "pin", angle: 0deg,
         size: 0.5, style: (:)) // kind: "roller" or "fixed"
#torque(on: none, at: auto, magnitude: none,
        direction: "counterclockwise", radius: 0.65,
        label: auto, style: (:)) // or direction: "clockwise"
#pendulum(
  name,
  from: none,
  length: 3,
  angle: 20deg,
  mass: none,
  radius: 0.24,
  angle-label: auto,
  label: auto,
  symbol: auto,
  style: (:),
)
```

== Scene annotations

```typ
#dimension(
  from: none,
  to: none,
  orientation: "aligned", // "horizontal" or "vertical"
  offset: 0.6,
  side: auto,             // above/below or left/right
  label: auto,
  label-position: "center", // "above" or "below"
  label-offset: 0.2,
  label-rotation: 0deg,
  label-fill: white,
  arrows: "both",         // "start", "end", or "none"
  arrow-tip: "stealth",
  arrow-scale: 0.5,
  extensions: true,
  extension-gap: 0.08,
  extension-stroke: auto,
  stroke: auto,
  color: auto,
  text: (:),
)
```

== Figures

```typ
#scene(
  s,
  labels: "name",      // "symbol", "mass", "both", "none", or overrides
  angles: "value",     // "symbol", "both", "none", or overrides
  loads: true,         // true or false
  frictions: false,    // true or false
  lengths: false,      // true or false
  dimensions: (),      // dimension(...) or an array of them
  forces: none,        // a body name, names, true, or none
  components: none,    // a body name, names, true, or none
  style: (:),
)

#draw(
  s,
  labels: "name",      // "symbol", "mass", "both", "none", or overrides
  angles: "value",     // "symbol", "both", "none", or overrides
  loads: true,         // true or false
  frictions: false,    // true or false
  lengths: false,      // true or false
  dimensions: (),      // dimension(...) or an array of them
  forces: none,        // a body name, names, true, or none
  components: none,    // a body name, names, true, or none
  style: (:),
)
```

```typ
#fbd(s, name, axes: auto, outline: true, solve: true, style: (:))
#components(s, name, of: "weight", style: (:))
```

== Results and force data

```typ
#solve(s, ..name, find: auto, direction: true, assume: auto)
#force-table(s, ..name, assume: auto)
#results(s, ..name, assume: auto)
#forces(s, name)
```

== Element style builders

```typ
#block-style(fill: auto, stroke: auto, label-text: auto)
#surface-style(
  fill: auto,
  stroke: auto,
  hatch-stroke: auto,
  hatch-spacing: auto,
  hatch-length: auto,
)
#force-style(color: auto, stroke: auto, length: auto, text: auto)
#connector-style(stroke: auto, fill: auto)
```

#c("theme") is the exported dictionary containing every diagram-style default.

// ═════════════════════════════════════════════════════════════════════════════
= Declaring a situation
// ═════════════════════════════════════════════════════════════════════════════

```typ
#situation(..elements, gravity: 9.81, style: (:))
```

#reference-table(
  [*Argument*], [*Meaning*],
  [#c("..elements")], [Surfaces, bodies, and forces, in any order. A body that uses #c("touching:") must come after the body it touches.],
  [#c("gravity:")], [The acceleration due to gravity. A number in m/s² prints as $g$ and substitutes to itself; content such as #c("$g$") keeps it symbolic.],
  [#c("style:")], [Style overrides applied to every view of this situation. See @styling.],
)

You never write a coordinate. A body names the surface it rests on and how far
along it sits, so changing a ramp's angle moves the block, its rotation, the
hatching, and the angle arc together.

Lengths are CeTZ canvas units, which are centimetres on the page. A ramp with
#c("length: 6") is six centimetres along its incline.

== Surfaces

```typ
#ground(name, length: 8, mu: none, style: (:))
#wall(name, side: left, height: 4, mu: none, style: (:))
#ceiling(name, length: 8, height: 4, mu: none, style: (:))
#ramp(name, angle: 30deg, length: 6, mu: none, symbol: auto, style: (:))
```

The name is optional for #c("ground"), #c("wall"), and #c("ceiling"); they
default to #c("\"ground\""), #c("\"wall\""), and #c("\"ceiling\""). Name a ramp
yourself, since a situation may hold more than one.

#reference-table(
  [*Argument*], [*Meaning*],
  [#c("length:")], [How long the surface is. For a ramp, measured along the incline rather than along its base.],
  [#c("height:")], [How high a wall stands, or how far above the ground a ceiling sits.],
  [#c("side:")], [Which end of the scene a wall stands at, #c("left") or #c("right").],
  [#c("angle:")], [A ramp's inclination, between #c("0deg") and #c("90deg").],
  [#c("facing:")], [Which way a ramp climbs, #c("right") or #c("left").],
  [#c("from:")], [Where this surface begins: an attachment point on a surface declared before it. See @composing.],
  [#c("mu:")], [Friction for everything that touches this surface. See @friction.],
  [#c("symbol:")], [What the inclination is called in the algebra. Defaults to $theta$. See @symbols.],
  [#c("style:")], [How this surface is drawn. See @styling.],
)

A ramp rises from its foot in the direction `facing:` names, with the ground
drawn under it.

#demo[
  #example(```typ
  #let s = situation(
    ramp("incline", angle: 40deg, length: 5),
    block("A", mass: 2, on: "incline", at: 60%),
  )
  #scene(s)
  ```)
]

#demo[
  #example(```typ
  #let s = situation(
    ramp("slope", angle: 30deg, length: 5,
      facing: left),
    ball("b", mass: 1, on: "slope", at: 55%),
  )
  #scene(s)
  ```)
]

Walls and a ceiling bound the scene. Bodies can rest against them, but 0.1.0
cannot solve a body they support.

#demo[
  #example(```typ
  #let s = situation(
    ground(length: 6),
    wall(side: left, height: 3),
    ceiling(length: 6, height: 3),
    block("A", mass: 2, on: "ground"),
  )
  #scene(s)
  ```)
]

== Surfaces that meet <composing>

`from:` places a surface at an attachment point of a surface declared before
it, which is how surfaces compose: a ramp whose foot sits at the end of a
ground, a ground that begins at a ramp's apex, a valley between two slopes.
Without it every surface starts at the origin.

#demo[
  #example(```typ
  #let s = situation(
    ground("approach", length: 4),
    ramp("incline", angle: 25deg, length: 4,
      from: "approach"),
    ground("shelf", length: 2.5,
      from: "incline.apex"),
    block("A", mass: 2, on: "approach", at: 40%),
    block("C", mass: 1, on: "shelf", at: 50%),
  )
  #scene(s)
  ```, side: false)
]

#demo[
  Two ramps and a floor make a valley.

  #example(```typ
  #let s = situation(
    ramp("left-slope", angle: 30deg, length: 4,
      facing: left),
    ground("floor", length: 3,
      from: "left-slope.foot"),
    ramp("right-slope", angle: 30deg, length: 4,
      from: "floor"),
    ball("b", mass: 1, on: "floor", radius: 0.35),
  )
  #scene(s)
  ```, side: false)
]

A wall with no `from:` still stands at the edge of everything placed before it.

== Attachment points <attachments>

Anywhere one element pins to another, the same three spellings work:

#reference-table(
  [*Written as*], [*Means*],
  [#c("\"ceiling\"")], [That element's default anchor: the midpoint of a surface, the centre of a body or pulley.],
  [#c("\"incline.apex\"")], [A named anchor of that element.],
  [#c("(on: \"ceiling\", at: 40%)")], [A point that far along a surface.],
)

#reference-table(
  [*Element*], [*Anchors*],
  [surfaces], [#c("start"), #c("end"), #c("surface")],
  [ramps also], [#c("foot"), #c("apex"), #c("base")],
  [bodies], [#c("center"), #c("contact"), #c("top"), #c("bottom"), #c("left"), #c("right"), #c("uphill"), #c("downhill"), #c("outward")],
  [pulleys], [#c("center"), #c("top"), #c("bottom"), #c("left"), #c("right")],
)

An element may only attach to something declared before it.

== Bodies

```typ
#block(name, mass: none, on: none, at: 50%, touching: none, side: right,
       hanging: none, drop: 1.5, size: 1, mu: none, label: auto,
       symbol: auto, style: (:))
#ball(name, ..., radius: 0.5)
#point-mass(name, ..., radius: 0.09)
```

All three take the same placement arguments and differ only in what is drawn.

#reference-table(
  [*Argument*], [*Meaning*],
  [#c("mass:")], [A number in kilograms, or content such as #c("$m$") to keep it symbolic.],
  [#c("on:")], [The surface it rests on.],
  [#c("at:")], [How far along that surface, as a ratio. Defaults to #c("50%").],
  [#c("touching:")], [Rest it against another body instead of positioning it by ratio.],
  [#c("side:")], [Which side of that body, #c("left") or #c("right").],
  [#c("size:")], [The edge of a square, or a #c("(width, height)") pair measured along the surface and out of it.],
  [#c("radius:")], [The radius of a ball or the dot of a point mass.],
  [#c("radius-mark:")], [Whether the centre dot and radial spoke are shown. Defaults to #c("true") for a disk and #c("false") for a ring.],
  [#c("orientation:")], [Where an enabled radial spoke points, relative to the supporting surface.],
  [#c("hanging:")], [Hang it below an attachment point instead of resting it on anything.],
  [#c("drop:")], [How far below that point it hangs.],
  [#c("mu:")], [Friction for the contact this body makes. See @friction.],
  [#c("label:")], [What to draw inside the body, instead of its name.],
  [#c("symbol:")], [What the mass is called in the algebra. See @symbols.],
  [#c("style:")], [How this body is drawn. See @styling.],
)

Give a body #c("on:"), #c("touching:"), or #c("hanging:").

#demo[
  #c("at:") measures along the surface, from its start.

  #example(```typ
  #let s = situation(
    ramp("incline", angle: 30deg, length: 7),
    block("low", mass: 1, on: "incline", at: 30%),
    block("high", mass: 1, on: "incline", at: 75%),
  )
  #scene(s)
  ```)
]

#demo[
  #c("touching:") rests a body against another one. Their sizes need not match.

  #example(```typ
  #let s = situation(
    ground(length: 7),
    block("m1", mass: 2, on: "ground", at: 35%,
      size: 1.2, label : $m_1$),
    block("m2", mass: 3, on: "ground",
      touching: "m1", side: right, label : $m_2$),
  )
  #scene(s)
  ```)
]

#demo[
  A rectangle, a ball, and a point mass.

  #example(```typ
  #let s = situation(
    ground(length: 7),
    block("crate", mass: 6, on: "ground",
      at: 25%, size: (1.6, 0.9)),
    ball("b", mass: 2, on: "ground",
      at: 55%, radius: 0.45),
    point-mass("p", mass: 1, on: "ground",
      at: 82%),
  )
  #scene(s, labels: "both")
  ```, side: false)
]

#demo[
  #c("hanging:") holds a body below an attachment point. It rests on nothing,
  so it stays upright and the solver will not take it.

  #example(```typ
  #let s = situation(
    ceiling(length: 5, height: 3),
    block("B", mass: 2, drop: 1.6,
      hanging: (on: "ceiling", at: 50%)),
    rope(from: (on: "ceiling", at: 50%),
      to: "B.top"),
  )
  #scene(s)
  #fbd(s, "B")
  ```, side: false)
]

#demo[
  #c("label:") replaces the text drawn inside the body, in the scene and in the
  free-body diagram.

  #example(```typ
  #let s = situation(
    ground(length: 5),
    block("crate", mass: 12, on: "ground",
      label: $M$),
  )
  #scene(s)
  ```)
]

A block that would extend past the end of its surface stops compilation:

```typ
#block("A", mass: 4, on: "incline", at: 95%)
```

```text
error: assertion failed: typed-physics: block "A" hangs off the end of
       "incline" by 0.150 — move it back with `at:` or shrink it with `size:`
```

== Friction <friction>

Surfaces and bodies both take #c("mu:"), in four forms:

#reference-table(
  [*Form*], [*Meaning*],
  [#c("mu: 0.3")], [One coefficient for both static and kinetic friction.],
  [#c("mu: (s: 0.4, k: 0.3)")], [Static and kinetic given separately.],
  [#c("mu: (static: 0.4, kinetic: 0.3)")], [The same, spelled out.],
  [#c("mu: $mu$")], [A symbol, which keeps the coefficient in the algebra.],
)

Give only #c("s:") or only #c("k:") and that value is used for both. A contact
with no #c("mu:") is frictionless.

#note[
  A body's #c("mu:") describes the contact it makes; a surface's #c("mu:")
  describes everything that touches it. The nearer declaration wins, so a rough
  ramp can still carry one frictionless body.
]

== Connectors

```typ
#rope(name, from: none, to: none, over: none, style: (:))
#spring(name, from: none, to: none, coils: 6, width: 0.28, style: (:))
#pulley(name, at: none, radius: 0.4, style: (:))
```

#reference-table(
  [*Argument*], [*Meaning*],
  [#c("from:"), #c("to:")], [The attachment points a connector spans. See @attachments.],
  [#c("over:")], [A pulley the rope runs over. It leaves each end at a tangent and wraps the wheel.],
  [#c("coils:"), #c("width:")], [How many zigzags a spring has, and how far they swing.],
  [#c("at:")], [Where a pulley sits.],
  [#c("radius:")], [How big the wheel is.],
)

Connectors are drawn, not solved. A rope tells the free-body diagram that a
tension acts along it, with a magnitude the package leaves open.

#demo[
  #example(```typ
  #let s = situation(
    ground(length: 7, mu: 0.2),
    ceiling(length: 7, height: 3),
    pulley("P", at: (on: "ceiling", at: 72%), radius : 0.6),
    ball("A", mass: 4, hanging: "P.left", drop : 1, radius : 0.4),
    ball("B", mass: 2, hanging: "P.right",
      drop: 1.4),
    rope(from: "A.top", to: "B.top", over: "P"),
  )
  #scene(s)
  ```, side: false)
])

#demo[
  #example(```typ
  #let s = situation(
    ground(length: 6),
    wall(side: left, height: 2),
    block("A", mass: 3, on: "ground", at: 60%),
    spring(to: "A.left", coils: 7,
      from: (on: "wall", at: 25%)),
    force(on : "A", magnitude : 10, angle : 180deg)
  )
  #scene(s)
  ```, side: false)
]

== Applied forces

```typ
#force(on: none, magnitude: none, angle: 0deg, at: auto,
       label: auto, style: (:))
```

#reference-table(
  [*Argument*], [*Meaning*],
  [#c("on:")], [The body or rod the force acts on.],
  [#c("magnitude:")], [A number in newtons, or content such as #c("$F$").],
  [#c("angle:")], [Measured from the horizontal, like every angle in the package.],
  [#c("at:")], [For a rod, the ratio along it where the force is applied. Defaults to its centre.],
  [#c("label:")], [The symbol drawn beside the arrow. Defaults to $F$, numbered when a body carries several.],
  [#c("style:")], [How this arrow is drawn. See @styling.],
)

The arrow arrives at the face the force acts on and points the way the force
points.

#demo[
  #report-example(```typ
  #let s = situation(
    ground(length: 6, mu: 0.25),
    block("crate", mass: 12, on: "ground"),
    force(on: "crate", magnitude: 40, angle: 0deg),
  )
  #scene(s)
  #solve(s)
  ```)
]

An angled push presses the body into the surface, raising the normal force and
with it the friction.

#demo[
  #report-example(```typ
  #let s = situation(
    ground(length: 6, mu: 0.25),
    block("crate", mass: 12, on: "ground"),
    force(on: "crate", magnitude: 40, angle: -25deg),
  )
  #scene(s)
  #solve(s)
  ```)
]

== Velocity

```typ
#velocity(on: none, magnitude: none, angle: 0deg, label: auto, style: (:))
```

How fast a body is already moving. A velocity is stated by you rather than
derived, and is drawn in its own colour so it is never mistaken for a force. It
never appears in a free-body diagram.

#demo[
  #example(```typ
  #let s = situation(
    ground(length: 6, mu: 0.25),
    block("A", mass: 3, on: "ground", at: 35%),
    velocity(on: "A", magnitude: 5,
      label: $v_0$),
    force(on: "A", magnitude: 10, angle: 0deg),
  )
  #scene(s)
  ```)
]

== Angular velocity

```typ
#angular-velocity(
  on: none,
  magnitude: none,
  direction: "clockwise",
  radius: auto,
  start-angle: auto,
  end-angle: auto,
  label: auto,
  style: (:),
)
```

An angular-velocity arrow hugs the outside of a #c("ball"), #c("disk"), or
#c("ring"). #c("direction:") determines which way its arrowhead travels.
#c("radius: auto") clears the body's outline, while an explicit radius controls
the gap. #c("start-angle:") and #c("end-angle:") are raw world angles that
choose which free part of the circle carries the arrow; their winding is
adjusted to agree with #c("direction:").

#reference-table(
  [*Argument*], [*Meaning*],
  [#c("on:")], [The round body whose rotation is being annotated.],
  [#c("magnitude:")], [An optional angular-speed declaration carried with the annotation; #c("label:") controls what is printed.],
  [#c("direction:")], [#c("\"clockwise\"") or #c("\"counterclockwise\"").],
  [#c("radius:")], [The arrow radius from the body's centre, or #c("auto") to clear the outline.],
  [#c("start-angle:"), #c("end-angle:")], [The raw polar angles delimiting the visible curved arrow.],
  [#c("label:")], [The arrow label, defaulting to $omega$.],
  [#c("style:")], [Motion colour, stroke, and text overrides through #c("force-style()").],
)

For example, #c("style: force-style(color: orange.darken(20%))") changes only
this curved arrow while preserving the scene's other motion styling.

#demo[
  The familiar rolling-wheel arrow occupies the free space to the left and
  points upward for clockwise motion.

  #example(```typ
  #let s = situation(
    ground(length: 5),
    disk("D", on: "ground", radius: 0.65),
    angular-velocity(
      on: "D",
      direction: "clockwise",
      radius: 0.95,
      start-angle: 220deg,
      end-angle: 140deg,
      label: $omega$,
    ),
  )
  #scene(s)
  ```)
]

== Drawing-only mechanics elements <drawing-only>

The elements in this section participate in relational placement and
#c("scene()"), but deliberately do not add equations to #c("solve()"). They
let a problem statement show the full geometry while the current solver keeps
its narrower, honest scope.

=== Loop-the-loop

#c("arc()") is a curved support. Its start point is the origin or #c("from:"),
and its polar-angle sweep determines the rest of the track. #c("side:")
chooses whether bodies occupy the outside of the curve or its inside.

#demo[
  The familiar loop-the-loop uses an inside support. The disk stays tangent to
  the track as #c("at:") moves it around the circle.

  #example(```typ
  #let s = situation(
    ground("approach", length: 2.5),
    arc("loop", radius: 2,
      start-angle: -90deg,
      end-angle: 270deg,
      side: "inside",
      from: "approach.end"),
    disk("car", mass: 1, on: "loop", at: 18%,
      radius: 0.3, orientation: 35deg,
      label: $C$),
  )
  #scene(s)
  ```, side: false)
]

The arc's #c("start"), #c("end"), #c("surface"), and #c("center") anchors are
available by name. A ratio attachment such as
#c("(on: \"loop\", at: 75%)") reaches any point along the curve.
Where an arc meets a straight foundation, straight hatches take priority and
nearby curved hatches wait until their full length fits clear of the junction.

=== Disk versus hoop

#c("disk()") and #c("ring()") take the ordinary body-placement arguments plus
#c("radius-mark:"). It defaults to #c("true") for a solid disk and #c("false")
for a ring, whose open centre reads more cleanly without it. When enabled, the
centre dot and radial spoke run all the way to the body's rim.
#c("orientation:") controls where the spoke points. The name inside the body
automatically chooses the nearest horizontal or vertical position opposite the
spoke, leaving the mark clear. This lets the classic rolling-race setup show
orientation without claiming to calculate angular acceleration.

#demo[
  #example(```typ
  #let s = situation(
    ramp("race", angle: 22deg, length: 8),
    disk("D", mass: 2, on: "race", at: 35%,
      radius: 0.48, orientation: 25deg),
    ring("H", mass: 2, on: "race", at: 68%,
      radius: 0.48),
    angular-velocity(on: "D",
      direction: "clockwise", label: $omega_D$),
    angular-velocity(on: "H",
      direction: "counterclockwise",
      start-angle: 40deg, end-angle: 140deg,
      label: $omega_H$),
  )
  #scene(s)
  ```, side: false)
]

=== Simply supported beam

#c("rod()") begins at the origin or an attachment. Give #c("to:") to span two
existing anchors, or give #c("length:") and #c("angle:"). Its anchors are
#c("start"), #c("end"), #c("center"), and #c("center-of-mass").

#c("support()") draws a #c("\"pin\""), #c("\"roller\""), or #c("\"fixed\"")
constraint; #c("pivot()") draws a hinge; and #c("torque()") draws an applied
clockwise or counterclockwise couple. A force on a rod accepts #c("at:") as a
ratio along its length.

#demo[
  The central point-load beam is the standard first statics problem: one pin,
  one roller, and loads whose reactions would be found from force and moment
  balance.

  #example(```typ
  #let s = situation(
    rod("beam", length: 6, mass: 12, label: none),
    support("A", at: "beam.start", kind: "pin"),
    support("B", at: "beam.end", kind: "roller"),
    force(on: "beam", at: 50%, magnitude: 20,
      angle: -90deg, label: $P$),
    torque(on: "beam", at: 78%,
      direction: "clockwise", radius: 0.48,
      label: $M$),
  )
  #scene(s)
  ```, side: false)
]

Use #c("(on: \"beam\", at: 35%)") wherever an attachment needs a point between
the named rod anchors. #c("angle:") on a support rotates its foundation, which
is useful for wall-mounted and inclined constraints.

=== Galileo's pendulum

#c("pendulum()") combines a pivot, string, bob, vertical construction line, and
angular marker. Its angle is measured from downward vertical, positive towards
the right. Set #c("angle-label: none") to omit the angular label.

#demo[
  #example(```typ
  #let s = situation(
    ceiling(length: 5, height: 4),
    pendulum("bob",
      from: (on: "ceiling", at: 50%),
      length: 2.8, angle: 24deg,
      mass: 1.5, radius: 0.5),
  )
  #scene(s)
  ```, side: false)
]

The pendulum exposes #c("pivot"), #c("bob"), and #c("center") anchors, so a
connector or later drawing element can attach to either end.

== Naming quantities <symbols>

Masses print as $m$ subscripted with the body's name, and a lone ramp's
inclination prints as $theta$. Pass #c("symbol:") to name either yourself. The
name you give is used in the figure and in every equation.

#demo[
  #example(```typ
  #let s = situation(
    ramp("incline", angle: 30deg, length: 6,
      symbol: $alpha$),
    block("A", mass: 4, on: "incline",
      at: 55%, symbol: $m_1$),
  )
  #scene(s, labels: "both", angles: "both")
  #solve(s, find: "normal")
  ```, side: false)
]

A situation with two ramps tells them apart by name, so their angles print as
$theta_"lower"$ and $theta_"upper"$ unless you say otherwise.

// ═════════════════════════════════════════════════════════════════════════════
= Figures
// ═════════════════════════════════════════════════════════════════════════════

== #raw("scene()")

```typ
#scene(s, labels: "name", angles: "value", loads: true, frictions: false,
       lengths: false, dimensions: (), forces: none, components: none,
       style: (:))
```

#reference-table(
  [*Argument*], [*Meaning*],
  [#c("labels:")], [What to write on a body: #c("\"name\""), #c("\"symbol\""), #c("\"mass\""), #c("\"both\""), or #c("\"none\""); or a mode with per-body overrides.],
  [#c("angles:")], [How to mark a ramp's inclination: #c("\"value\"") (30°), #c("\"symbol\"") (θ), #c("\"both\"") (θ = 30°), or #c("\"none\""); or a mode with per-ramp overrides.],
  [#c("loads:")], [Whether to draw the applied forces.],
  [#c("frictions:")], [Whether to write each contact's coefficients beside the body that makes it.],
  [#c("lengths:")], [Whether to write each surface's length beside it, as $ell = 7$.],
  [#c("dimensions:")], [One #c("dimension(...)") annotation or an array of them.],
  [#c("forces:")], [Draw the forces on a body where it sits: a name, several names, or #c("true") for every body.],
  [#c("components:")], [Resolve the weight on a body where it sits: a name, several names, or #c("true") for every body.],
  [#c("style:")], [Style overrides for this view. See @styling.],
)

#demo[
  #example(```typ
  #let s = situation(
    ramp("incline", angle: 30deg, length: 6),
    block("A", mass: 4, on: "incline", at: 55%),
  )
  #scene(s, labels: "both", angles: "both")
  ```)
]

#demo[
  Turn everything on when the figure has to carry the problem statement by
  itself.

  #example(```typ
  #let s = situation(
    ramp("incline", angle: 30deg, length: 7),
    block("A", mass: 4, on: "incline", at: 55%,
      mu: (s: 0.40, k: 0.30)),
  )
  #scene(s, labels: "both", angles: "both",
    frictions: true, lengths: true)
  ```, side: false)
]

#demo[
  Turn everything off for a figure the surrounding text already explains.

  #example(```typ
  #let s = situation(
    ramp("incline", angle: 30deg, length: 6),
    block("A", mass: 4, on: "incline", at: 55%),
  )
  #scene(s, labels: "none", angles: "none")
  ```)
]

=== Configurable dimensions

#c("dimension()") draws a drafting-style measurement in one #c("scene()") or
#c("draw()") call; it is not part of the physical #c("situation()"). Its
#c("from:") and #c("to:") accept the package's ordinary anchors, connector
anchors such as #c("\"spring.start\""), or raw #c("(x, y)") points.

#c("orientation: \"aligned\"") measures along the segment joining the anchors.
#c("\"horizontal\"") measures their x-separation, and #c("\"vertical\"")
measures their y-separation. The axis-aligned modes project both anchors
orthogonally, so an incline's run and rise do not require invented coordinates.

#c("offset:") moves the line away from the measured points. An aligned
dimension accepts any #c("side:"). A horizontal dimension uses #c("\"above\"")
or #c("\"below\""), while a vertical dimension uses #c("\"left\"") or
#c("\"right\""). When omitted, #c("side: auto") chooses #c("\"above\"") for
aligned and horizontal dimensions and #c("\"right\"") for vertical ones.
Dashed projection lines retain the connection to the measured points.
Each projection stops before the first body, rod, or straight surface it meets,
so it does not draw through a target outline.

#c("label-position: \"center\"") follows the drafting convention: the label
interrupts the dimension line, and its padded gap grows with the label's
content and text size. #c("\"above\"") and #c("\"below\"") place the label
beside an uninterrupted line.

#reference-table(
  [*Argument*], [*Meaning*],
  [#c("from:"), #c("to:")], [Named anchors, connector anchors, ratio attachments, or raw coordinate pairs.],
  [#c("orientation:")], [#c("\"aligned\""), #c("\"horizontal\""), or #c("\"vertical\"").],
  [#c("offset:")], [Distance from the measured points to the dimension line.],
  [#c("side:")], [#c("auto"), #c("\"above\""), #c("\"below\""), #c("\"left\""), or #c("\"right\"").],
  [#c("label:")], [Math, text, #c("none"), or #c("auto") for $L$.],
  [#c("label-position:")], [#c("\"center\""), #c("\"above\""), or #c("\"below\"").],
  [#c("label-offset:")], [Distance from the line for an above or below label.],
  [#c("label-rotation:")], [Rotation applied only to the label.],
  [#c("label-fill:")], [Background behind a centered label; defaults to white.],
  [#c("arrows:")], [Arrowheads on #c("\"both\""), #c("\"start\""), #c("\"end\""), or #c("\"none\"").],
  [#c("arrow-tip:")], [A CeTZ mark name, such as #c("\"stealth\"") or #c("\"triangle\"").],
  [#c("arrow-scale:")], [Scale factor for both arrowheads.],
  [#c("extensions:")], [Whether the measured points are projected to the offset line.],
  [#c("extension-gap:")], [Clearance left before the first target or obstruction.],
  [#c("extension-stroke:")], [Stroke for the projection lines; dashed by default.],
  [#c("stroke:"), #c("color:")], [Line weight/style and colour; colour defaults to grey.],
  [#c("text:")], [Text arguments for this label, such as #c("(size: 11pt)").],
)

#demo[
  A spring's own anchors make its natural length straightforward to annotate.

  #example(```typ
  #let s = situation(
    ground(length: 7),
    wall(side: left, height: 2),
    block("A", on: "ground", at: 72%),
    spring("coil",
      from: (on: "wall", at: 25%),
      to: "A.left", coils: 7),
  )
  #scene(
    s,
    dimensions: dimension(
      from: "coil.start",
      to: "coil.end",
      offset: 1.2,
      label: $ell_0$,
      label-position: "center",
      extensions : true
    ),
  )
  ```, side: false)
]

#demo[
  The same anchors can describe the inclined length and its vertical rise.

  #example(```typ
  #let s = situation(
    ramp("incline", angle: 30deg, length: 5),
    block("B", on: "incline", at: 55%),
    ground(length : 6)
  )
  #scene(
    s,
    dimensions: (dimension(
      from: "incline.foot",
      to: "incline.apex",
      offset: 2,
      label: $s$,
      label-position: "below",
      arrow-tip: "triangle",
      stroke: 1pt,
      color: rgb("#C92A2A"),
    ), 
    dimension(
      from: "incline.apex",
      offset : 1,
      to: "ground",
      orientation: "vertical",
      side: "right",
      label: $h$,
    ),
    dimension(
      from: "incline.foot",
      offset : 1,
      to: "incline.base",
      orientation: "horizontal",
      side: "below",
      label: $b$,
    )
    ),
  )
  ```, side: false)
]

=== Placing individual annotations

The string forms remain the concise default. A dictionary keeps that global
#c("mode:") and adds #c("overrides:") for individual bodies or ramps.

Each override names its element with #c("on:"). #c("offset:") is a raw
#c("(x, y)") displacement in diagram world units, added to the automatically
chosen position, so #c("(0, 0)") changes nothing. #c("rotation:") rotates only
the label. #c("visible: false") hides that one annotation, and an override may
carry its own #c("mode:").

For body labels, #c("\"symbol\"") writes only the declared or derived mass
symbol, such as $m_A$. #c("\"mass\"") writes the symbol, value, and unit, such
as $m_A = 4 "kg"$.

#demo[
  #example(```typ
  #let s = situation(
    ramp("incline", angle: 30deg, length: 9),
    block("A", mass: 4, on: "incline", at: 48%),
    block("B", mass: 2, on: "incline", at: 76%),
  )
  #scene(
    s,
    labels: (
      mode: "name",
      overrides: (
        (on: "A", offset: (0.35, 0.3),
          rotation: -12deg),
        (on: "B", visible: false),
      ),
    ),
    angles: (
      mode: "both",
      overrides: (
        (on: "incline", offset: (0.28, 0.18),
          rotation: 10deg),
      ),
    ),
  )
  ```, side: false)
]

#demo[
  Use a per-body mode when most bodies need their full mass but one needs only
  its symbol.

  #example(```typ
  #let s = situation(
    ground(length: 7),
    block("A", mass: 4, on: "ground", at: 32%),
    block("B", mass: 2, on: "ground", at: 70%),
  )
  #scene(
    s,
    labels: (
      mode: "mass",
      overrides: (
        (on: "A", mode: "symbol"),
      ),
    ),
  )
  ```)
]

#demo[
  #c("forces:") draws a body's forces where that body sits, instead of in a
  diagram of its own. The arrows come from the same enumeration #c("fbd") uses,
  so the two agree.

  #example(```typ
  #let s = situation(
    ramp("incline", angle: 30deg, length: 8),
    block("A", mass: 2, on: "incline", at: 55%,
      mu: (s: 0.40, k: 0.30)),
  )
  #scene(s, forces: "A")
  ```)
]

=== Forces and components in place

#c("components:") draws the same weight decomposition as #c("components()"),
but keeps the body in the scene. When #c("forces:") names the same body, the
construction closes onto that force view's weight arrow instead of drawing a
second one.

#demo[
  #example(```typ
  #let s = situation(
    ramp("incline", angle: 30deg, length: 9),
    block("A", mass: 4, on: "incline",
      at: 62%, mu: 0.25),
  )
  #scene(s, forces: "A", components: "A",
    labels: "none", angles: "symbol")
  ```, side: false)
]

#note[
  Force and component arrows need room. Combining them with
  #c("labels: \"mass\"") or #c("lengths: true") in one small figure can
  collide; give the figure more #c("length:") or leave the other labels off.
]

== #raw("fbd()")

```typ
#fbd(s, name, axes: auto, outline: true, solve: true, style: (:))
```

#reference-table(
  [*Argument*], [*Meaning*],
  [*name*], [Which body to draw. Required.],
  [#c("axes:")], [Name the surface's axes. #c("auto") names them when the surface is inclined.],
  [#c("outline:")], [Draw the body's outline. With #c("false") the arrows meet at a point.],
  [#c("solve:")], [Solve the body first, so the arrows can be drawn in proportion.],
  [#c("style:")], [Style overrides for this view.],
)

Arrow lengths are proportional to the forces they stand for. When any magnitude
is still symbolic, every arrow falls back to one length.

#demo[
  #example(```typ
  #let s = situation(
    ramp("incline", angle: 30deg, length: 6),
    block("A", mass: 4, on: "incline",
      at: 55%, mu: (s: 0.40, k: 0.30)),
  )
  #fbd(s, "A")
  ```)
]

#demo[
  A body the solver cannot handle still gets a diagram, since the forces come
  from the declaration.

  #example(```typ
  #let s = situation(
    ramp("incline", angle: 30deg, length: 6),
    block("A", mass: $m$, on: "incline",
      mu: (s: $mu_s$, k: $mu_k$)),
  )
  #fbd(s, "A")
  ```)
]

#demo[
  #c("outline: false") collapses the body to the point the arrows act on.

  #example(```typ
  #let s = situation(
    ground(length: 5, mu: 0.3),
    block("A", mass: 4, on: "ground"),
    force(on: "A", magnitude: 15, angle: 30deg),
  )
  #fbd(s, "A", outline: false)
  ```)
]

== #raw("components()")

```typ
#components(s, name, of: "weight", style: (:))
```

Draws the weight resolved into the surface's own axes, with the construction
lines, the right angle, and the inclination arc. #c("of:") accepts only
#c("\"weight\"") in 0.1.0.

#demo[
  #example(```typ
  #let s = situation(
    ramp("incline", angle: 30deg, length: 6),
    block("A", mass: 4, on: "incline", at: 55%),
  )
  #components(s, "A")
  ```)
]

// ═════════════════════════════════════════════════════════════════════════════
= Answers
// ═════════════════════════════════════════════════════════════════════════════

Three views read the solution. All of them take an optional body name and an
optional #c("assume:"); leave the name out when the situation holds one body.

typed-physics states quantities and stops there. It does not write the argument
that connects them, because that argument belongs to your document, in your
words and your language.

== #raw("solve()")

```typ
#solve(s, ..name, find: auto, direction: true, assume: auto)
```

States one quantity. #c("find:") chooses which:

#reference-table(
  [*Value*], [*What you get*],
  [#c("\"acceleration\"")], [The acceleration and the direction it points.],
  [#c("\"normal\"")], [The normal force.],
  [#c("\"friction\"")], [The friction force acting, static or kinetic.],
  [#c("\"regime\"")], [Whether the body slides or stays put.],
  [#c("auto")], [The acceleration for a sliding body, the regime for one that stays put.],
)

#c("direction: false") drops the words that say which way an acceleration
points, leaving the quantity alone for a document that will phrase it itself.

#demo[
  #report-example(```typ
  #let s = situation(
    ramp("incline", angle: 30deg, length: 6),
    block("A", mass: 4, on: "incline",
      at: 55%, mu: (s: 0.40, k: 0.30)),
  )
  #solve(s) \
  #solve(s, find: "normal") \
  #solve(s, find: "friction") \
  #solve(s, find: "regime") \
  #solve(s, find: "acceleration", direction: false)
  ```)
]

#demo[
  Asked for a quantity with no number behind it, #c("solve") gives the closed
  form.

  #report-example(```typ
  #let s = situation(
    ramp("incline", angle: 30deg, length: 6),
    block("A", mass: $m$, on: "incline",
      mu: (s: $mu_s$, k: $mu_k$)),
  )
  #solve(s, assume: "sliding")
  ```)
]

== #raw("force-table()")

```typ
#force-table(s, ..name, assume: auto)
```

Every force on the body with its components along the surface and out of it, in
the order the free-body diagram draws them.

#demo[
  #report-example(```typ
  #let s = situation(
    ramp("incline", angle: 30deg, length: 6),
    block("A", mass: 4, on: "incline",
      at: 55%, mu: (s: 0.40, k: 0.30)),
  )
  #force-table(s)
  ```)
]

== #raw("results()")

```typ
#results(s, ..name, assume: auto)
```

Returns the solution as a dictionary, for pulling a number into your own prose
or table.

#reference-table(
  [*Key*], [*What it holds*],
  [#c("status")], [#c("\"solved\"") or #c("\"undetermined\"").],
  [#c("body"), #c("surface")], [The names involved.],
  [#c("regime")], [#c("\"static\"") or #c("\"sliding\"").],
  [#c("assumed")], [Whether #c("assume:") supplied the regime.],
  [#c("rough")], [Whether the contact has coefficients at all.],
  [#c("normal"), #c("friction"), #c("acceleration"), #c("weight"), #c("required"), #c("available")], [Each a dictionary with an #c("expression") and its #c("value"). #c("friction") and #c("acceleration") also carry a #c("direction").],
  [#c("motion"), #c("downhill")], [Which way the body would go.],
)

#demo[
  #report-example(```typ
  #let s = situation(
    ramp("incline", angle: 30deg, length: 6),
    block("A", mass: 4, on: "incline",
      at: 55%, mu: (s: 0.40, k: 0.30)),
  )
  #let answer = results(s)
  The block is #answer.regime, the normal force is
  #calc.round(answer.normal.value, digits: 1) N, and it
  accelerates at
  #calc.round(answer.acceleration.value, digits: 2) m/s².
  ```)
]

== Numbers and symbols

Masses, coefficients, gravity, and force magnitudes take numbers or content.
Every answer is carried as far towards a value as the numbers you declared
reach: all of them numeric gives a number, some of them gives an expression with
those numbers folded in, and none of them gives the closed form.

#demo[
  #report-example(```typ
  #let s = situation(
    ramp("incline", angle: 30deg, length: 6),
    block("A", mass: 4, on: "incline",
      mu: (s: 0.40, k: 0.30)),
  )
  #solve(s)
  ```)
]

#demo[
  A symbolic coefficient leaves only that coefficient standing. The normal
  force does not depend on it, so it still reaches a number.

  #report-example(```typ
  #let s = situation(
    ramp("incline", angle: 30deg, length: 6),
    block("A", mass: 4, on: "incline",
      mu: (s: $mu_s$, k: $mu_k$)),
  )
  #solve(s, find: "normal") \
  #solve(s, assume: "sliding")
  ```)
]

#demo[
  With nothing numeric left, the answer is an expression in the symbols you
  declared.

  #report-example(```typ
  #let s = situation(
    gravity: $g$,
    ramp("incline", angle: 30deg, length: 6),
    block("A", mass: $m$, on: "incline",
      mu: (s: $mu_s$, k: $mu_k$)),
  )
  #solve(s, assume: "sliding")
  ```)
]

== Choosing the regime with #raw("assume:")

Whether a body slides is a comparison of two numbers. When either side is
symbolic, the four views above say which quantity is missing:

#demo[
  #report-example(```typ
  #let s = situation(
    ramp("incline", angle: 30deg, length: 6),
    block("A", mass: $m$, on: "incline",
      mu: (s: $mu_s$, k: $mu_k$)),
  )
  #solve(s)
  ```)
]

Pass #c("assume: \"static\"") or #c("assume: \"sliding\"") to state the regime
yourself. #c("results(s).assumed") records that you supplied it rather than the
package deciding, so a document can say as much.

#demo[
  #report-example(```typ
  #let s = situation(
    ramp("incline", angle: 30deg, length: 6),
    block("A", mass: 4, on: "incline", mu: 0.5),
  )
  #solve(s, assume: "sliding")
  ```)
]

== Bodies by name

Name the body when a situation holds more than one. Leaving the name out is an
error, not a guess.

```typ
#solve(s, "m2")
#solve(s, "m2", find: "normal", assume: "sliding")
#force-table(s, "m2")
#results(s, "m2")
```

// ═════════════════════════════════════════════════════════════════════════════
= Drawing on top
// ═════════════════════════════════════════════════════════════════════════════

#c("draw(s)") returns the scene as CeTZ elements instead of a finished canvas,
so you can annotate a figure without editing the situation. It takes the same
arguments as #c("scene"). Every body and surface is a named group, and its
anchors are addressable coordinates.

The anchors are the ones listed in @attachments, plus #c("start") and #c("end")
on a rope or spring.

#demo[
  #example(```typ
  #let s = situation(
    ramp("incline", angle: 30deg, length: 6),
    block("A", mass: 4, on: "incline", at: 45%),
  )
  #cetz.canvas({
    import cetz.draw: circle, line, content
    draw(s)
    line("A.center", "incline.apex",
      stroke: (dash: "dotted", paint: red))
    circle("A.center", radius: 0.06, fill: red)
    content("incline.apex", $P$, anchor: "south")
  })
  ```, side: false)
]

// ═════════════════════════════════════════════════════════════════════════════
= Styling <styling>
// ═════════════════════════════════════════════════════════════════════════════

There are two levels. A *diagram style* sets how a whole figure looks and is
accepted by #c("situation()") and by every view. An *element style* sets how one
declared thing looks and is accepted by #c("block"), the four surfaces, and
#c("force").

An unknown key is an error at either level, rather than a silent no-op.

== Diagram styles

#c("situation()") takes the style every view of that situation starts from; a
view's own #c("style:") is merged over it and applies to that view alone.

```typ
#let s = situation(..., style: (body-fill: luma(230), scale: 0.9))
#scene(s, style: (force-colors: (applied: red)))
```

#reference-table(
  [*Key*], [*Controls*],
  [#c("block-size")], [Default body edge, in canvas units.],
  [#c("surface-stroke"), #c("surface-fill")], [How a surface is drawn.],
  [#c("hatch-stroke"), #c("hatch-spacing"), #c("hatch-length")], [The hatching under a surface.],
  [#c("body-stroke"), #c("body-fill")], [How a body is drawn.],
  [#c("point-mass-fill")], [The dot a point mass is drawn as.],
  [#c("rope-stroke"), #c("spring-stroke")], [How connectors are drawn.],
  [#c("pulley-fill"), #c("pulley-stroke")], [How a pulley wheel is drawn.],
  [#c("velocity-color"), #c("velocity-stroke"), #c("velocity-length")], [How a velocity arrow is drawn.],
  [#c("angle-stroke"), #c("angle-radius")], [The inclination arc.],
  [#c("construction-stroke")], [Dashed construction lines.],
  [#c("right-angle-size")], [The right-angle marker in the component view.],
  [#c("length-label-offset")], [How far off a surface #c("lengths: true") writes its length.],
  [#c("dimension-color"), #c("dimension-stroke"), \ #c("dimension-extension-stroke"), #c("dimension-text")], [Defaults inherited by scene-only dimensions and their dashed projections.],
  [#c("force-stroke")], [Thickness of a force arrow.],
  [#c("force-length")], [Length drawn for the largest force on a body.],
  [#c("force-floor")], [Shortest an arrow may be drawn, so a small force stays visible.],
  [#c("force-colors")], [A dictionary keyed #c("weight"), #c("normal"), #c("friction"), #c("applied"), #c("tension"), #c("component"). Merged key by key.],
  [#c("label-text"), #c("force-text"), #c("angle-text")], [Text arguments for each kind of label.],
  [#c("scale")], [Scale factor applied to a finished view.],
)

#demo[
  #example(```typ
  #let s = situation(
    ramp("incline", angle: 30deg, length: 6),
    block("A", mass: 4, on: "incline", at: 55%),
    style: (
      body-fill: rgb("#FFF3BF"),
      surface-fill: rgb("#F8F0FC"),
      hatch-stroke: 0.6pt + rgb("#9C36B5"),
      scale: 0.9,
    ),
  )
  #scene(s)
  ```)
]

#demo[
  Force colours merge key by key, so naming one leaves the rest alone.

  #example(```typ
  #let s = situation(
    ramp("incline", angle: 30deg, length: 6),
    block("A", mass: 4, on: "incline",
      mu: 0.3),
  )
  #fbd(s, "A", style: (
    force-colors: (friction: rgb("#C2255C")),
    force-length: 1.8,
  ))
  ```)
]

The defaults are exported as #c("theme"), a plain dictionary you can read when
building a style of your own.

== Element styles

An element's own style wins over the diagram style, for that element and nothing
else. Three builders give you argument completion while writing one; each
returns a plain dictionary, so you can write the dictionary directly instead.

```typ
#block-style(fill: auto, stroke: auto, label-text: auto)
#surface-style(fill: auto, stroke: auto, hatch-stroke: auto,
               hatch-spacing: auto, hatch-length: auto)
#force-style(color: auto, stroke: auto, length: auto, text: auto)
```

#reference-table(
  [*Builder*], [*Accepted by*],
  [#c("block-style")], [#c("block"), #c("ball"), #c("point-mass"), #c("disk"), #c("ring"), #c("rod"), #c("pendulum")],
  [#c("surface-style")], [#c("ground"), #c("wall"), #c("ceiling"), #c("ramp"), #c("arc")],
  [#c("force-style")], [#c("force"), #c("velocity"), #c("angular-velocity"), #c("torque")],
  [#c("connector-style")], [#c("rope"), #c("spring"), #c("pulley"), #c("pivot"), #c("support")],
  [#c("block-style")], [#c("pulley")],
)

A force's style follows it into the free-body diagram, so an arrow you coloured
in the scene is the same colour in every view. #c("length:") sets how long that
arrow is drawn at full size; in a free-body diagram the arrows are still scaled
against each other from there.

#demo[
  #example(```typ
  #let s = situation(
    ramp("incline", angle: 30deg, length: 6,
      style: surface-style(
        fill: rgb("#FFF9DB"),
        hatch-stroke: 0.6pt + rgb("#E67700"),
      )),
    block("A", mass: 4, on: "incline", at: 40%,
      mu: 0.3,
      style: block-style(
        fill: rgb("#D3F9D8"),
        stroke: 1pt + rgb("#2B8A3E"),
      )),
    force(on: "A", magnitude: 12, angle: 0deg,
      style: force-style(color: rgb("#C2255C"))),
  )
  #scene(s)
  #fbd(s, "A")
  ```, side: false)
]

// ═════════════════════════════════════════════════════════════════════════════
= Errors
// ═════════════════════════════════════════════════════════════════════════════

These stop compilation with a message naming the element and the reason.

#reference-table(
  [*If you write*], [*You get*],
  [A block reaching past the end of its surface], [The overhang, and the two arguments that fix it.],
  [A block with neither #c("on:") nor #c("touching:")], [A request for one of them.],
  [#c("touching:") a body declared later], [A note that the other body must come first.],
  [#c("solve") on a body with no #c("mass:")], [The name of the missing quantity.],
  [#c("solve") on a body resting on a wall or ceiling], [What 0.1.0 supports.],
  [A situation whose normal force comes out negative], [The value, and that the body leaves the surface.],
  [#c("solve") on a situation with several bodies and no name], [The list of bodies to choose from.],
  [An unknown #c("style:") key], [The key that was not recognised.],
)

A regime that cannot be decided is not an error. #c("solve") reports which
quantity is symbolic and how to state the regime instead.

// ═════════════════════════════════════════════════════════════════════════════
= What 0.1.0 does not do <limitations>
// ═════════════════════════════════════════════════════════════════════════════

The drawing vocabulary is where this package grows. The solver is deliberately
still: it balances one body on a ground or a ramp and nothing else.

- Solving anything a connector touches. Ropes, springs, and pulleys are drawn,
  and a rope tells a free-body diagram that a tension acts, but no tension,
  acceleration, or contact force between bodies is computed.
- Solving a body supported by a wall or a ceiling, or hanging from anything.
- Action–reaction pairs between touching bodies.
- Force or moment balance for rods, supports, pivots, or applied torques. Those
  elements draw but do not enter the solver.
- Circular motion on an #c("arc"), rolling dynamics for #c("disk") or
  #c("ring"), and pendulum motion. Their geometry draws and composes without a
  derived acceleration.
- #c("components(of:)") for anything but the weight.

// ═════════════════════════════════════════════════════════════════════════════
= License
// ═════════════════════════════════════════════════════════════════════════════

typed-physics is released under the MIT license. It is built on
#link("https://typst.app/universe/package/cetz")[CeTZ].

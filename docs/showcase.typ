// typed-physics showcase — five exam problems, each figure derived from one
// declaration of the situation it describes.
//
// Compile with:
//   typst compile --root . docs/showcase.typ docs/showcase.pdf

#import "../src/lib.typ": *

// ── Paper ────────────────────────────────────────────────────────────────────

#let ink = rgb("#1A1D21")
#let rule-color = rgb("#B8C0C8")
#let quiet = rgb("#6C757D")

#set document(title: "Mechanics I — Problem Set 4", author: "Geronimo Castaño")
#set text(font: "New Computer Modern", size: 10pt, fill: ink, lang: "en")
#set par(justify: true, leading: 0.58em, spacing: 0.85em)

#set page(
  width: 21cm,
  height: auto,
  margin: (x: 1.5cm, top: 1.3cm, bottom: 1.2cm),
  header: {
    set text(size: 8.5pt, fill: quiet)
    grid(
      columns: (1fr, auto),
      align: (left, right),
      smallcaps[Mechanics I], [Problem Set 4],
    )
    v(-0.55em)
    line(length: 100%, stroke: 0.5pt + rule-color)
  },
  header-ascent: 1.1em,
  footer: context {
    set text(size: 8pt, fill: quiet)
    grid(
      columns: (1fr, auto, 1fr),
      align: (left, center, right),
      [Take $g = 9.81 thin upright("m/s")^2$.],
      [#counter(page).display("1") / #counter(page).final().first()],
      [Figures drawn with #smallcaps[typed-physics]],
    )
  },
)

// ── One exercise: statement on the left, figure on the right ─────────────────

#let problem(title, marks, statement, figure-content, figure-width: 8.6cm) = {
  std.block(width: 100%, breakable: false, {
    grid(
      columns: (1fr, figure-width),
      column-gutter: 0.9cm,
      align: (top, horizon),
      {
        std.block(below: 0.8em, {
          grid(
            columns: (1fr, auto),
            column-gutter: 1em,
            align: (left + bottom, right + bottom),
            {
              set text(size: 8.5pt, fill: quiet, tracking: 0.06em)
              context smallcaps[Problem #counter("problem").display()]
            },
            text(size: 8.5pt, fill: quiet)[#marks marks],
          )
          v(0.1em)
          text(size: 12pt, weight: "bold", title)
          v(-0.35em)
          line(length: 100%, stroke: 0.5pt + rule-color)
        })
        statement
      },
      align(center, figure-content),
    )
  })
  counter("problem").step()
}

// One diagram style for the whole paper, so every figure shares its palette,
// its lettering, and the weight of its dimension lines.
#let paper-figures = (
  scale: 0.95,
  body-fill: rgb("#E4ECF7"),
  body-stroke: 0.9pt + rgb("#1F3247"),
  surface-fill: rgb("#F4F2EE"),
  surface-stroke: 0.8pt + rgb("#2B2B2B"),
  hatch-stroke: 0.55pt + rgb("#8A8A8A"),
  label-text: (size: 9pt),
  angle-text: (size: 9pt),
  force-text: (size: 9pt),
  dimension-color: rgb("#5C6670"),
  dimension-stroke: 0.6pt,
  dimension-text: (size: 8.5pt),
)

#let parts(..items) = std.block(above: 0.8em, {
  set enum(numbering: "(a)", indent: 0.2em, body-indent: 0.55em, spacing: 0.62em)
  items.pos().map(item => [+ #item]).join()
})

#counter("problem").update(1)

// ── 1 · Crate on a rough incline ─────────────────────────────────────────────

#let crate-on-incline = situation(
  ramp("incline", angle: 32deg, length: 6.4, mu: (s: 0.45, k: 0.35)),
  block("A", mass: 25, on: "incline", at: 50%, size: (1.4, 0.9), symbol: $m$),
  force(on: "A", magnitude: 250, angle: 32deg, label: $F$),
  style: paper-figures,
)

#problem(
  [Crate on a rough incline],
  10,
  [
    A crate of mass $m = 25 thin upright("kg")$ rests on a ramp inclined at
    $theta = 32degree$ to the horizontal. The coefficients of friction between
    the crate and the ramp are $mu_s = 0.45$ and $mu_k = 0.35$. A force
    $F = 250 thin upright("N")$ is applied to the crate parallel to the ramp,
    directed up the slope.

    #parts(
      [Draw the free-body diagram of the crate and resolve its weight into
        components along and normal to the ramp.],
      [Show that the crate cannot remain at rest, and state the direction in
        which it moves.],
      [Find the normal force and the acceleration of the crate.],
      [The crate starts from rest at the foot of the ramp. Find its speed on
        reaching the top, a height $h = 3.4 thin upright("m")$ above the
        ground.],
    )
  ],
  scene(
    crate-on-incline,
    labels: "both",
    angles: "both",
    dimensions: dimension(
      from: "incline.apex",
      to: "incline.base",
      orientation: "vertical",
      side: "right",
      offset: 0.7,
      label: $h$,
    ),
  ),
)

#pagebreak()

// ── 2 · Block, cord, and hanging mass ────────────────────────────────────────

#let table-and-hanging-mass = situation(
  ground("table", length: 6.5, mu: (s: 0.30, k: 0.22)),
  pulley("P", at: "table.end", radius: 0.5),
  block("A", mass: 4, on: "table", at: 42%),
  block("B", mass: 3, hanging: "P.right", drop: 1.7),
  rope(from: "A.right", to: "B.top", over: "P"),
  style: paper-figures,
)

#problem(
  [Block, cord, and hanging mass],
  12,
  [
    Block $A$ lies on a horizontal table. A light inextensible cord runs from
    $A$, passes over a frictionless pulley at the edge of the table, and
    carries block $B$. The coefficients of friction between $A$ and the table
    are given in the figure; the pulley is light and turns freely.

    #parts(
      [Draw a separate free-body diagram for each block, and state the relation
        between their accelerations.],
      [Determine whether the blocks move when released from rest.],
      [Find the acceleration of the blocks and the tension in the cord.],
      [Block $B$ falls a distance $d = 1.2 thin upright("m")$ to the floor.
        Find the speed of $A$ at that instant, and the further distance $A$
        slides before stopping.],
    )
  ],
  scene(
    table-and-hanging-mass,
    // The hanging block's cord runs where its mass would be written, so that
    // one label is moved clear of it.
    labels: (
      mode: "both",
      overrides: ((on: "B", mode: "mass", offset: (-0.85, 0)),),
    ),
    frictions: true,
  ),
)

#pagebreak()

// ── 3 · Spring launch and collision ──────────────────────────────────────────

#let spring-launch = situation(
  ground("track", length: 8.4),
  wall(side: left, height: 1.5),
  block("A", mass: 2, on: "track", at: 22%, size: 1),
  block("B", mass: 3, on: "track", at: 64%, size: 1.1),
  spring("k", from: (on: "wall", at: 33%), to: "A.left", coils: 8),
  velocity(on: "A", magnitude: 3, angle: 0deg, label: $v_0$),
  style: paper-figures,
)

#problem(
  [Spring launch and collision],
  12,
  [
    Block $A$, of mass $2.0 thin upright("kg")$, is held against a spring of
    stiffness $k = 800 thin upright("N/m")$ compressed
    $x = 0.15 thin upright("m")$ from its natural length, and is then released.
    The spring is light and the track is smooth. Block $B$, of mass
    $3.0 thin upright("kg")$, stands at rest a distance
    $d = 2.5 thin upright("m")$ ahead of $A$.

    #parts(
      [Find the speed $v_0$ with which $A$ leaves the spring.],
      [The blocks stick together on impact. Find their common velocity and the
        kinetic energy lost in the collision.],
      [Find the velocity of each block instead if the collision is perfectly
        elastic.],
      [Beyond $B$ the track is rough, with $mu_k = 0.20$. Taking the collision
        of part (b), find how far the blocks travel before coming to rest.],
    )
  ],
  scene(
    spring-launch,
    labels: "name",
    dimensions: dimension(
      from: "A.right",
      to: "B.left",
      orientation: "horizontal",
      offset: 1.1,
      side: "above",
      label: $d$,
    ),
  ),
)

#pagebreak()

// ── 4 · Simply supported beam ────────────────────────────────────────────────

#let loaded-beam = situation(
  rod("beam", length: 6, thickness: 0.2, label: none),
  support("A", at: "beam.start", kind: "pin"),
  support("B", at: "beam.end", kind: "roller"),
  force(on: "beam", at: 30%, magnitude: 4, angle: -90deg, label: $P_1$),
  force(on: "beam", at: 65%, magnitude: 6, angle: -90deg, label: $P_2$),
  torque(on: "beam", at: 82%, direction: "clockwise", radius: 0.4, label: $M_0$),
  style: paper-figures,
)

// The supports carry the letters the statement names them by, drawn on top of
// the scene through the anchors placement already resolved.
#let lettered-beam = scale(paper-figures.scale * 100%, reflow: true, cetz.canvas({
  import cetz.draw: content
  draw(
    loaded-beam,
    labels: "name",
    dimensions: (
      dimension(
        from: "beam.start",
        to: (on: "beam", at: 30%),
        orientation: "horizontal",
        offset: 1.05,
        side: "below",
        label: $a$,
      ),
      dimension(
        from: (on: "beam", at: 30%),
        to: (on: "beam", at: 65%),
        orientation: "horizontal",
        offset: 1.05,
        side: "below",
        label: $b$,
      ),
      dimension(
        from: "beam.start",
        to: "beam.end",
        orientation: "horizontal",
        offset: 1.85,
        side: "below",
        label: $L$,
      ),
    ),
  )
  content((rel: (-0.45, 0.12), to: "beam.start"), text(size: 9.5pt)[$A$])
  content((rel: (0.45, 0.12), to: "beam.end"), text(size: 9.5pt)[$B$])
}))

#problem(
  [Simply supported beam],
  10,
  [
    A light beam $A B$ of length $L = 6.0 thin upright("m")$ rests on a pin
    support at $A$ and a roller at $B$. It carries vertical loads
    $P_1 = 4.0 thin upright("kN")$ and $P_2 = 6.0 thin upright("kN")$ at the
    distances shown, with $a = 1.8 thin upright("m")$ and
    $b = 2.1 thin upright("m")$, together with a couple
    $M_0 = 5.0 thin upright("kN") dot upright("m")$.

    #parts(
      [Draw the free-body diagram of the beam, showing the reaction components
        at each support.],
      [Find the reactions at $A$ and at $B$.],
      [Explain why the point of application of $M_0$ along the beam does not
        affect either reaction.],
      [Find the distance from $A$ at which $P_2$ would have to act for the two
        reactions to be equal.],
    )
  ],
  lettered-beam,
)

#pagebreak()

// ── 5 · Vertical circular loop ───────────────────────────────────────────────

#let vertical-loop = situation(
  ground("approach", length: 3.6),
  arc(
    "loop",
    radius: 2,
    start-angle: -90deg,
    end-angle: 270deg,
    side: "inside",
    from: "approach.end",
  ),
  ball("C", mass: 0.4, on: "loop", at: 50%, radius: 0.28, label: $m$),
  velocity(on: "C", magnitude: 3, angle: 180deg, label: $v$),
  style: paper-figures,
)

#problem(
  [Vertical circular loop],
  10,
  [
    A small body of mass $m = 0.40 thin upright("kg")$ slides along a smooth
    horizontal track and runs onto the inside of a vertical circular loop of
    radius $R = 2.0 thin upright("m")$. Friction is negligible throughout, and
    the body may be treated as a particle.

    #parts(
      [Draw the free-body diagram of the body at the highest point of the loop,
        and write Newton's second law along the radial direction there.],
      [Find the least speed $v$ at the highest point for which the body stays
        in contact with the track.],
      [Find the speed the body must have on entering the loop at the bottom in
        order to pass the highest point at that least speed.],
      [Find the speed at the highest point for which the track pushes on the
        body with a force equal to the body's weight.],
    )
  ],
  scene(
    vertical-loop,
    labels: "name",
    dimensions: dimension(
      from: (3.6, 2),
      to: (5.6, 2),
      orientation: "horizontal",
      side: "above",
      offset: 0,
      label: $R$,
      arrows: "end",
      extensions: false,
    ),
  ),
)

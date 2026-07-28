// Turning declarations into placed geometry.
//
// This is where relational placement becomes coordinates. A surface knows where
// it starts, which way it runs, and which way points out of it; a body sits
// some distance along one of those surfaces, against another body, or below
// something that holds it up; a connector spans two attachment points. Nothing
// downstream reads a coordinate the author wrote, because there are none.

#import "vector.typ"
#import "expression.typ"
#import "validation.typ"

// A number substitutes to itself and still prints as g; content the author
// wrote keeps gravity symbolic through every equation that uses it.
#let gravity-quantity(gravity-acceleration) = expression.declared(
  gravity-acceleration,
  $g$,
)

// `block("m1")` should print as m_1 and `block("A")` as m_A, so a name that is
// already a mass symbol does not get wrapped in another one. A `symbol:` the
// author declared replaces the derived one everywhere the mass is printed.
#let mass-symbol(name, declared-symbol) = {
  if declared-symbol != auto { return declared-symbol }
  let numbered-mass-name = name.match(regex("^m([0-9]+)$"))
  if numbered-mass-name != none {
    let mass-index = numbered-mass-name.captures.first()
    return $m_#mass-index$
  }
  $m_#name$
}

// One ramp in a situation is θ; several are told apart by name.
#let angle-symbol(surface-name, ramp-count, declared-symbol) = {
  if declared-symbol != auto { return declared-symbol }
  if ramp-count <= 1 { $theta$ } else { $theta_#surface-name$ }
}

// ── Attachment points ────────────────────────────────────────────────────────
//
// One spelling reaches every point another element can be pinned to:
// `"ceiling"` for an element's default anchor, `"incline.apex"` for a named
// one, and `(on: "ceiling", at: 40%)` for a ratio along a surface.

#let _split-anchor-reference(reference) = {
  let reference-parts = reference.split(".")
  assert(
    reference-parts.len() <= 2,
    message: "typed-physics: \"" + reference + "\" is not an attachment point; write \"name\" or \"name.anchor\"",
  )
  (
    element: reference-parts.first(),
    anchor: if reference-parts.len() == 2 { reference-parts.at(1) } else {
      auto
    },
  )
}

#let surface-anchor-positions(surface) = {
  let anchor-positions = (
    start: surface.start,
    end: surface.end,
    surface: surface.midpoint,
  )
  if surface.kind == "ramp" {
    anchor-positions += (
      foot: surface.foot,
      apex: surface.apex,
      base: surface.base-corner,
    )
  }
  anchor-positions
}

#let body-anchor-positions(body) = (
  center: body.center,
  contact: body.contact,
  top: (body.center.at(0), body.center.at(1) + body.half-extent-normal),
  bottom: (body.center.at(0), body.center.at(1) - body.half-extent-normal),
  left: (body.center.at(0) - body.half-extent-along, body.center.at(1)),
  right: (body.center.at(0) + body.half-extent-along, body.center.at(1)),
)

#let pulley-anchor-positions(placed-pulley) = (
  center: placed-pulley.center,
  top: (placed-pulley.center.at(0), placed-pulley.center.at(1) + placed-pulley.radius),
  bottom: (placed-pulley.center.at(0), placed-pulley.center.at(1) - placed-pulley.radius),
  left: (placed-pulley.center.at(0) - placed-pulley.radius, placed-pulley.center.at(1)),
  right: (placed-pulley.center.at(0) + placed-pulley.radius, placed-pulley.center.at(1)),
)

#let structure-anchor-positions(placed-structure) = {
  if placed-structure.kind == "rod" {
    return (
      start: placed-structure.start,
      end: placed-structure.end,
      center: placed-structure.center,
      center-of-mass: placed-structure.center-of-mass,
    )
  }
  if placed-structure.kind == "pendulum" {
    return (
      pivot: placed-structure.pivot,
      bob: placed-structure.bob,
      center: placed-structure.bob,
    )
  }
  (center: placed-structure.center,)
}

#let point-on-surface-at-ratio(surface, ratio-along-surface) = {
  if surface.kind != "arc" {
    return vector.point-along(
      surface.start,
      surface.direction,
      surface.length * (ratio-along-surface / 100%),
    )
  }
  let position-angle = (
    surface.start-angle
      + surface.sweep-angle * (ratio-along-surface / 100%)
  )
  vector.point-along(
    surface.center,
    vector.direction-from-angle(position-angle),
    surface.radius,
  )
}

// Resolves an attachment point against whatever has been placed so far. The
// `declared-by` name only ever appears in error messages, so an unresolvable
// attachment says which element asked for it.
#let resolve-attachment-point(
  attachment,
  placed-surfaces,
  placed-bodies,
  placed-pulleys,
  declared-by,
  placed-structures: (:),
) = {
  if type(attachment) == dictionary {
    let attached-element-name = attachment.at("on")
    let ratio-along-element = attachment.at("at", default: 50%)
    if attached-element-name in placed-structures {
      let placed-structure = placed-structures.at(attached-element-name)
      assert(
        placed-structure.kind == "rod",
        message: "typed-physics: " + declared-by + " can use (on:, at:) only along a surface or rod",
      )
      return vector.point-along(
        placed-structure.start,
        placed-structure.direction,
        placed-structure.length * (ratio-along-element / 100%),
      )
    }
    assert(
      attached-element-name in placed-surfaces,
      message: "typed-physics: " + declared-by + " attaches to \"" + attached-element-name + "\", which is not a surface or rod declared before it",
    )
    let surface = placed-surfaces.at(attached-element-name)
    return point-on-surface-at-ratio(surface, ratio-along-element)
  }

  assert(
    type(attachment) == str,
    message: "typed-physics: " + declared-by + " needs an attachment point such as \"ceiling\" or (on: \"ceiling\", at: 40%)",
  )
  let (element, anchor) = _split-anchor-reference(attachment)

  let anchor-positions = if element in placed-surfaces {
    surface-anchor-positions(placed-surfaces.at(element))
  } else if element in placed-pulleys {
    pulley-anchor-positions(placed-pulleys.at(element))
  } else if element in placed-bodies {
    body-anchor-positions(placed-bodies.at(element))
  } else if element in placed-structures {
    structure-anchor-positions(placed-structures.at(element))
  } else {
    panic(
      "typed-physics: "
        + declared-by
        + " attaches to \""
        + element
        + "\", which is not an element declared before it",
    )
  }

  let default-anchor = if element in placed-surfaces { "surface" } else {
    "center"
  }
  let requested-anchor = if anchor == auto { default-anchor } else { anchor }
  assert(
    requested-anchor in anchor-positions,
    message: (
      "typed-physics: \""
        + element
        + "\" has no anchor called \""
        + requested-anchor
        + "\"; it has "
        + anchor-positions.keys().join(", ")
    ),
  )
  anchor-positions.at(requested-anchor)
}

// ── Surfaces ─────────────────────────────────────────────────────────────────

#let _placed-surface(
  surface-name,
  surface-kind,
  start-position,
  surface-tangent-direction,
  outward-normal-direction,
  surface-length,
  surface-inclination,
  friction-coefficients,
  surface-style,
  additional-fields,
) = (
    name: surface-name,
    kind: surface-kind,
    start: start-position,
    end: vector.point-along(
      start-position,
      surface-tangent-direction,
      surface-length,
    ),
    midpoint: vector.point-along(
      start-position,
      surface-tangent-direction,
      surface-length / 2,
    ),
    direction: surface-tangent-direction,
    outward-normal: outward-normal-direction,
    length: surface-length,
    inclination: surface-inclination,
    friction: friction-coefficients,
    style: surface-style,
  ) + additional-fields

// Where a surface begins: at the origin, or at the anchor of a surface declared
// before it.
#let _surface-start-position(
  surface-declaration,
  placed-surfaces,
  default-start-position,
) = {
  if surface-declaration.from == none { return default-start-position }
  resolve-attachment-point(
    surface-declaration.from,
    placed-surfaces,
    (:),
    (:),
    surface-declaration.kind + " \"" + surface-declaration.name + "\"",
  )
}

#let _resolve-surface-geometry(
  surface-declaration,
  horizontal-span,
  ramp-count,
  placed-surfaces,
) = {
  let surface-kind = surface-declaration.kind
  let surface-name = surface-declaration.name
  let start-position(default-start-position) = _surface-start-position(
    surface-declaration,
    placed-surfaces,
    default-start-position,
  )

  // A flat support keeps an exact zero for its inclination, so the incline
  // equations collapse to the horizontal ones on their own instead of through
  // a second set of formulas.
  if surface-kind == "ground" {
    return _placed-surface(
      surface-name,
      surface-kind,
      start-position((0, 0)),
      (1, 0),
      (0, 1),
      surface-declaration.length,
      0deg,
      surface-declaration.friction,
      surface-declaration.style,
      (inclination-quantity: expression.number(0)),
    )
  }

  if surface-kind == "ceiling" {
    return _placed-surface(
      surface-name,
      surface-kind,
      start-position((0, surface-declaration.height)),
      (1, 0),
      (0, -1),
      surface-declaration.length,
      0deg,
      surface-declaration.friction,
      surface-declaration.style,
      (
        inclination-quantity: expression.number(0),
        height: surface-declaration.height,
      ),
    )
  }

  if surface-kind == "ramp" {
    let surface-inclination = surface-declaration.angle
    let climbs-to-the-right = surface-declaration.facing == "right"
    // The tangent direction always points uphill, so the sign conventions of
    // the incline frame hold whichever way the slope runs.
    let surface-tangent-direction = if climbs-to-the-right {
      vector.direction-from-angle(surface-inclination)
    } else {
      vector.direction-from-angle(180deg - surface-inclination)
    }
    let outward-normal-direction = if climbs-to-the-right {
      vector.left-normal(surface-tangent-direction)
    } else {
      vector.right-normal(surface-tangent-direction)
    }
    let placed-ramp = _placed-surface(
      surface-name,
      surface-kind,
      start-position((0, 0)),
      surface-tangent-direction,
      outward-normal-direction,
      surface-declaration.length,
      surface-inclination,
      surface-declaration.friction,
      surface-declaration.style,
      (
        facing: surface-declaration.facing,
        inclination-quantity: expression.declared-angle(
          surface-inclination,
          angle-symbol(
            surface-name,
            ramp-count,
            surface-declaration.symbol,
          ),
        ),
      ),
    )
    return placed-ramp + (
      foot: placed-ramp.start,
      apex: placed-ramp.end,
      base-corner: (placed-ramp.end.at(0), placed-ramp.start.at(1)),
    )
  }

  if surface-kind == "arc" {
    let start-angle = surface-declaration.start-angle
    let sweep-angle = (
      surface-declaration.end-angle - surface-declaration.start-angle
    )
    let start-radial-direction = vector.direction-from-angle(start-angle)
    let start-point = start-position((0, 0))
    let arc-center = vector.point-along(
      start-point,
      vector.reversed(start-radial-direction),
      surface-declaration.radius,
    )
    let midpoint-angle = start-angle + sweep-angle / 2
    let end-radial-direction = vector.direction-from-angle(
      surface-declaration.end-angle,
    )
    let midpoint-radial-direction = vector.direction-from-angle(midpoint-angle)
    let starts-counterclockwise = sweep-angle > 0deg
    let start-tangent-direction = if starts-counterclockwise {
      vector.left-normal(start-radial-direction)
    } else {
      vector.right-normal(start-radial-direction)
    }
    let start-outward-normal = if surface-declaration.side == "outside" {
      start-radial-direction
    } else {
      vector.reversed(start-radial-direction)
    }
    return (
      name: surface-name,
      kind: surface-kind,
      start: start-point,
      end: vector.point-along(
        arc-center,
        end-radial-direction,
        surface-declaration.radius,
      ),
      midpoint: vector.point-along(
        arc-center,
        midpoint-radial-direction,
        surface-declaration.radius,
      ),
      center: arc-center,
      direction: start-tangent-direction,
      outward-normal: start-outward-normal,
      length: surface-declaration.radius * calc.abs(sweep-angle.rad()),
      inclination: vector.angle-of(start-tangent-direction),
      inclination-quantity: expression.declared-angle(
        vector.angle-of(start-tangent-direction),
        $theta$,
      ),
      radius: surface-declaration.radius,
      start-angle: start-angle,
      end-angle: surface-declaration.end-angle,
      sweep-angle: sweep-angle,
      side: surface-declaration.side,
      friction: surface-declaration.friction,
      style: surface-declaration.style,
    )
  }

  let wall-foot-position = start-position(
    if surface-declaration.side == "left" {
      (horizontal-span.at(0), 0)
    } else {
      (horizontal-span.at(1), 0)
    },
  )
  let wall-outward-normal-direction = if surface-declaration.side == "left" {
    (1, 0)
  } else {
    (-1, 0)
  }
  _placed-surface(
    surface-name,
    surface-kind,
    wall-foot-position,
    (0, 1),
    wall-outward-normal-direction,
    surface-declaration.height,
    90deg,
    surface-declaration.friction,
    surface-declaration.style,
    (
      inclination-quantity: expression.declared-angle(90deg, $theta$),
      side: surface-declaration.side,
      foot: wall-foot-position,
    ),
  )
}

// How far the placed surfaces reach left and right, which is where a wall that
// was not given a `from:` stands.
#let _horizontal-surface-span(placed-surfaces, surface-names) = {
  let horizontal-extents = (0,)
  for surface-name in surface-names {
    let surface = placed-surfaces.at(surface-name)
    if surface.kind == "arc" {
      horizontal-extents.push(surface.center.at(0) - surface.radius)
      horizontal-extents.push(surface.center.at(0) + surface.radius)
    } else {
      horizontal-extents.push(surface.start.at(0))
      horizontal-extents.push(surface.end.at(0))
    }
  }
  (calc.min(..horizontal-extents), calc.max(..horizontal-extents))
}

// ── Bodies ───────────────────────────────────────────────────────────────────

// A block's own `mu:` describes the contact it makes, and the surface's `mu:`
// describes everything that touches it. The nearer declaration wins.
#let _resolve-contact-friction(body-declaration, support-surface) = {
  let declared-friction = if body-declaration.friction != none {
    body-declaration.friction
  } else if support-surface == none {
    none
  } else {
    support-surface.friction
  }
  if declared-friction == none { return none }
  (
    static: expression.declared(declared-friction.static, $mu_s$),
    kinetic: expression.declared(declared-friction.kinetic, $mu_k$),
  )
}

// A number prints as the body's mass symbol and substitutes to itself. Content
// written as the mass is already the symbol, unless `symbol:` names another.
#let _declared-mass(body-declaration) = {
  if body-declaration.mass == none { return none }
  let printed-symbol = mass-symbol(
    body-declaration.name,
    body-declaration.symbol,
  )
  if type(body-declaration.mass) in (int, float) {
    return expression.quantity(printed-symbol, value: body-declaration.mass)
  }
  expression.quantity(
    if body-declaration.symbol == auto {
      body-declaration.mass
    } else {
      body-declaration.symbol
    },
  )
}

#let _placed-body(
  body-declaration,
  support-surface,
  contact-position,
  distance-along-surface,
  tangent-direction,
  outward-normal-direction,
  attachment-position,
) = (
  name: body-declaration.name,
  kind: "body",
  shape: body-declaration.shape,
  label: body-declaration.label,
  mass: _declared-mass(body-declaration),
  half-extent-along: body-declaration.half-extent-along,
  half-extent-normal: body-declaration.half-extent-normal,
  support: if support-surface == none { none } else { support-surface.name },
  distance: distance-along-surface,
  contact: contact-position,
  center: vector.point-along(
    contact-position,
    outward-normal-direction,
    body-declaration.half-extent-normal,
  ),
  direction: tangent-direction,
  outward-normal: outward-normal-direction,
  inclination: if support-surface == none {
    0deg
  } else { support-surface.inclination },
  inclination-quantity: if support-surface == none {
    expression.number(0)
  } else { support-surface.inclination-quantity },
  friction: _resolve-contact-friction(body-declaration, support-surface),
  hangs-from: attachment-position,
  style: body-declaration.style,
  loads: (),
  velocities: (),
  angular-velocities: (),
  radius-mark: body-declaration.radius-mark,
  orientation: body-declaration.orientation,
  solver-supported: body-declaration.solver-supported,
)

#let _surface-frame-at-distance(support-surface, distance-along-surface) = {
  if support-surface.kind != "arc" {
    return (
      contact: vector.point-along(
        support-surface.start,
        support-surface.direction,
        distance-along-surface,
      ),
      tangent: support-surface.direction,
      outward-normal: support-surface.outward-normal,
      inclination: support-surface.inclination,
      inclination-quantity: support-surface.inclination-quantity,
    )
  }

  let position-ratio = distance-along-surface / support-surface.length
  let position-angle = (
    support-surface.start-angle
      + support-surface.sweep-angle * position-ratio
  )
  let radial-direction = vector.direction-from-angle(position-angle)
  let tangent-direction = if support-surface.sweep-angle > 0deg {
    vector.left-normal(radial-direction)
  } else {
    vector.right-normal(radial-direction)
  }
  let outward-normal-direction = if support-surface.side == "outside" {
    radial-direction
  } else {
    vector.reversed(radial-direction)
  }
  let tangent-inclination = vector.angle-of(tangent-direction)
  (
    contact: vector.point-along(
      support-surface.center,
      radial-direction,
      support-surface.radius,
    ),
    tangent: tangent-direction,
    outward-normal: outward-normal-direction,
    inclination: tangent-inclination,
    inclination-quantity: expression.declared-angle(
      tangent-inclination,
      $theta$,
    ),
  )
}

#let _place-body-on-surface(
  body-declaration,
  support-surface,
  distance-along-surface,
) = {
  if support-surface.kind == "arc" and support-surface.side == "inside" {
    assert(
      body-declaration.half-extent-normal < support-surface.radius,
      message: (
        "typed-physics: \""
          + body-declaration.name
          + "\" is too large for the inside of arc \""
          + support-surface.name
          + "\"; reduce its radius/size below "
          + expression.format-number(support-surface.radius)
          + " or increase the arc radius"
      ),
    )
  }
  let overhang-past-start = (
    body-declaration.half-extent-along - distance-along-surface
  )
  let overhang-past-end = (
    distance-along-surface
      + body-declaration.half-extent-along
      - support-surface.length
  )
  assert(
    overhang-past-start <= 1e-9,
    message: (
      "typed-physics: \""
        + body-declaration.name
        + "\" hangs off the start of \""
        + support-surface.name
        + "\" by "
        + expression.format-number(overhang-past-start)
        + " — move it along with `at:` or shrink it with `size:`"
    ),
  )
  assert(
    overhang-past-end <= 1e-9,
    message: (
      "typed-physics: \""
        + body-declaration.name
        + "\" hangs off the end of \""
        + support-surface.name
        + "\" by "
        + expression.format-number(overhang-past-end)
        + " — move it back with `at:` or shrink it with `size:`"
    ),
  )
  let local-surface-frame = _surface-frame-at-distance(
    support-surface,
    distance-along-surface,
  )
  let local-support-surface = support-surface + (
    direction: local-surface-frame.tangent,
    outward-normal: local-surface-frame.outward-normal,
    inclination: local-surface-frame.inclination,
    inclination-quantity: local-surface-frame.inclination-quantity,
  )
  _placed-body(
    body-declaration,
    local-support-surface,
    local-surface-frame.contact,
    distance-along-surface,
    local-surface-frame.tangent,
    local-surface-frame.outward-normal,
    none,
  )
}

// A hanging body rests on nothing: it sits `drop:` below whatever holds it, and
// is upright because no surface is there to tilt it.
#let _place-hanging-body(
  body-declaration,
  placed-surfaces,
  placed-bodies,
  placed-pulleys,
) = {
  let attachment-position = resolve-attachment-point(
    body-declaration.hanging,
    placed-surfaces,
    placed-bodies,
    placed-pulleys,
    "\"" + body-declaration.name + "\"",
  )
  let body-top-position = (
    attachment-position.at(0),
    attachment-position.at(1) - body-declaration.drop,
  )
  _placed-body(
    body-declaration,
    none,
    (
      body-top-position.at(0),
      body-top-position.at(1) - 2 * body-declaration.half-extent-normal,
    ),
    none,
    (1, 0),
    (0, 1),
    attachment-position,
  )
}

#let _resolve-body-placement(
  body-declaration,
  placed-surfaces,
  placed-bodies,
  placed-pulleys,
) = {
  if body-declaration.hanging != none {
    return _place-hanging-body(
      body-declaration,
      placed-surfaces,
      placed-bodies,
      placed-pulleys,
    )
  }

  if body-declaration.touching != none {
    assert(
      body-declaration.touching in placed-bodies,
      message: (
        "typed-physics: \""
          + body-declaration.name
          + "\" touches \""
          + body-declaration.touching
          + "\", which is not a body declared before it"
      ),
    )
    let neighbouring-body = placed-bodies.at(body-declaration.touching)
    assert(
      neighbouring-body.support != none,
      message: "typed-physics: \"" + body-declaration.name + "\" touches \"" + neighbouring-body.name + "\", which does not rest on a surface",
    )
    let support-surface = placed-surfaces.at(neighbouring-body.support)
    let centre-to-centre-distance = (
      neighbouring-body.half-extent-along + body-declaration.half-extent-along
    )
    let signed-distance-from-neighbour = if body-declaration.side == "right" {
      centre-to-centre-distance
    } else {
      -centre-to-centre-distance
    }
    return _place-body-on-surface(
      body-declaration,
      support-surface,
      neighbouring-body.distance + signed-distance-from-neighbour,
    )
  }

  assert(
    body-declaration.on in placed-surfaces,
    message: (
      "typed-physics: \""
        + body-declaration.name
        + "\" rests on \""
        + body-declaration.on
        + "\", which is not a surface in this situation"
    ),
  )
  let support-surface = placed-surfaces.at(body-declaration.on)
  _place-body-on-surface(
    body-declaration,
    support-surface,
    support-surface.length * (body-declaration.at / 100%),
  )
}

// ── Rigid structures and constraints ─────────────────────────────────────────

#let _support-contact-on-attached-rod(
  support-declaration,
  attachment-position,
  placed-structures,
) = {
  if support-declaration.support-kind == "fixed" {
    return attachment-position
  }
  let attached-element-name = if type(support-declaration.at) == dictionary {
    support-declaration.at.at("on")
  } else {
    _split-anchor-reference(support-declaration.at).element
  }
  if attached-element-name not in placed-structures {
    return attachment-position
  }
  let attached-structure = placed-structures.at(attached-element-name)
  if attached-structure.kind != "rod" {
    return attachment-position
  }

  let support-tangent-direction = vector.direction-from-angle(
    support-declaration.angle,
  )
  let support-normal-direction = vector.left-normal(
    support-tangent-direction,
  )
  let rod-normal-alignment = calc.abs(
    vector.dot-product(
      support-normal-direction,
      attached-structure.outward-normal,
    ),
  )
  if rod-normal-alignment < 0.001 {
    return attachment-position
  }

  // Rod anchors lie on the centreline, while a pin or roller physically meets
  // the lower face of the rod.
  let distance-from-centerline-to-contact = (
    attached-structure.thickness / (2 * rod-normal-alignment)
  )
  vector.point-along(
    attachment-position,
    vector.reversed(support-normal-direction),
    distance-from-centerline-to-contact,
  )
}

#let _resolve-structure-geometry(
  structure-declaration,
  placed-surfaces,
  placed-bodies,
  placed-pulleys,
  placed-structures,
) = {
  let declared-by = (
    structure-declaration.kind
      + " \""
      + structure-declaration.name
      + "\""
  )
  let resolve-point(attachment) = resolve-attachment-point(
    attachment,
    placed-surfaces,
    placed-bodies,
    placed-pulleys,
    declared-by,
    placed-structures: placed-structures,
  )

  if structure-declaration.kind == "rod" {
    let start-position = if structure-declaration.from == none {
      (0, 0)
    } else {
      resolve-point(structure-declaration.from)
    }
    let end-position = if structure-declaration.to == none {
      vector.point-along(
        start-position,
        vector.direction-from-angle(structure-declaration.angle),
        structure-declaration.length,
      )
    } else {
      resolve-point(structure-declaration.to)
    }
    let rod-span = vector.subtract(end-position, start-position)
    let rod-length = vector.magnitude(rod-span)
    assert(
      rod-length > 0,
      message: "typed-physics: rod \"" + structure-declaration.name + "\" has coincident endpoints",
    )
    let rod-direction = vector.normalized(rod-span)
    return (
      name: structure-declaration.name,
      kind: "rod",
      start: start-position,
      end: end-position,
      center: vector.midpoint(start-position, end-position),
      center-of-mass: vector.point-along(
        start-position,
        rod-direction,
        rod-length * (structure-declaration.center-of-mass / 100%),
      ),
      direction: rod-direction,
      outward-normal: vector.left-normal(rod-direction),
      length: rod-length,
      thickness: structure-declaration.thickness,
      mass: _declared-mass(structure-declaration),
      label: structure-declaration.label,
      style: structure-declaration.style,
      loads: (),
    )
  }

  if structure-declaration.kind == "pendulum" {
    let pivot-position = resolve-point(structure-declaration.from)
    let string-direction = vector.direction-from-angle(
      -90deg + structure-declaration.angle,
    )
    return (
      name: structure-declaration.name,
      kind: "pendulum",
      center: vector.point-along(
        pivot-position,
        string-direction,
        structure-declaration.length,
      ),
      pivot: pivot-position,
      bob: vector.point-along(
        pivot-position,
        string-direction,
        structure-declaration.length,
      ),
      direction: string-direction,
      length: structure-declaration.length,
      angle: structure-declaration.angle,
      angle-label: structure-declaration.angle-label,
      radius: structure-declaration.radius,
      mass: _declared-mass(structure-declaration),
      label: structure-declaration.label,
      style: structure-declaration.style,
    )
  }

  let attachment-position = resolve-point(structure-declaration.at)
  let support-contact-position = if structure-declaration.kind == "support" {
    _support-contact-on-attached-rod(
      structure-declaration,
      attachment-position,
      placed-structures,
    )
  } else {
    attachment-position
  }
  (
    name: structure-declaration.name,
    kind: structure-declaration.kind,
    center: attachment-position,
    contact: support-contact-position,
    radius: structure-declaration.at("radius", default: none),
    support-kind: structure-declaration.at("support-kind", default: none),
    angle: structure-declaration.at("angle", default: 0deg),
    size: structure-declaration.at("size", default: none),
    style: structure-declaration.style,
  )
}

#let _point-on-rod(placed-rod, at) = if type(at) == ratio {
  vector.point-along(
    placed-rod.start,
    placed-rod.direction,
    placed-rod.length * (at / 100%),
  )
} else {
  none
}

#let _resolve-torque-geometry(
  torque-declaration,
  placed-surfaces,
  placed-bodies,
  placed-pulleys,
  placed-structures,
) = {
  let target-name = torque-declaration.on
  let target-is-body = target-name in placed-bodies
  let target-is-structure = target-name in placed-structures
  assert(
    target-is-body or target-is-structure,
    message: "typed-physics: torque() turns \"" + target-name + "\", which is not a body or rigid structure in this situation",
  )
  let target = if target-is-body {
    placed-bodies.at(target-name)
  } else {
    placed-structures.at(target-name)
  }
  let torque-center = if torque-declaration.at == auto {
    target.center
  } else if target.kind == "rod" and type(torque-declaration.at) == ratio {
    _point-on-rod(target, torque-declaration.at)
  } else {
    resolve-attachment-point(
      torque-declaration.at,
      placed-surfaces,
      placed-bodies,
      placed-pulleys,
      "torque() on \"" + target-name + "\"",
      placed-structures: placed-structures,
    )
  }
  (
    kind: "torque",
    on: target-name,
    center: torque-center,
    magnitude: torque-declaration.magnitude,
    direction: torque-declaration.direction,
    radius: torque-declaration.radius,
    label: torque-declaration.label,
    style: torque-declaration.style,
  )
}

// ── Connectors ───────────────────────────────────────────────────────────────

// The two points at which a rope leaves a pulley it runs over. Each is the
// tangent point from that end of the rope, so the rope meets the wheel where a
// real one would rather than pointing at its centre.
#let _tangent-point-on-pulley(placed-pulley, external-position, wrap-side) = {
  let centre-to-point = vector.subtract(external-position, placed-pulley.center)
  let distance-to-point = vector.magnitude(centre-to-point)
  if distance-to-point <= placed-pulley.radius {
    return placed-pulley.center
  }
  let tangent-offset-angle = calc.asin(placed-pulley.radius / distance-to-point)
  let angle-to-point = vector.angle-of(centre-to-point)
  let tangent-direction = vector.direction-from-angle(
    angle-to-point + wrap-side * (90deg - tangent-offset-angle),
  )
  vector.point-along(
    placed-pulley.center,
    tangent-direction,
    placed-pulley.radius,
  )
}

#let _resolve-connector-geometry(
  connector-declaration,
  placed-surfaces,
  placed-bodies,
  placed-pulleys,
  placed-structures: (:),
) = {
  let declared-by = (
    connector-declaration.kind + " \"" + connector-declaration.name + "\""
  )
  let resolve-end(attachment) = resolve-attachment-point(
    attachment,
    placed-surfaces,
    placed-bodies,
    placed-pulleys,
    declared-by,
    placed-structures: placed-structures,
  )
  let start-position = resolve-end(connector-declaration.from)
  let end-position = resolve-end(connector-declaration.to)
  let connector-span = vector.subtract(end-position, start-position)
  assert(
    vector.magnitude(connector-span) > 0.000001,
    message: (
      "typed-physics: "
        + declared-by
        + " has coincident `from:` and `to:` endpoints; choose two distinct attachment points"
    ),
  )

  let placed-connector = (
    name: connector-declaration.name,
    kind: connector-declaration.kind,
    start: start-position,
    end: end-position,
    over: none,
    style: connector-declaration.style,
  )
  if connector-declaration.kind == "spring" {
    return placed-connector + (
      coils: connector-declaration.coils,
      width: connector-declaration.width,
    )
  }

  let pulley-name = connector-declaration.over
  if pulley-name == none { return placed-connector }
  assert(
    pulley-name in placed-pulleys,
    message: "typed-physics: " + declared-by + " runs over \"" + pulley-name + "\", which is not a pulley declared before it",
  )
  let placed-pulley = placed-pulleys.at(pulley-name)
  let start-distance-from-pulley = vector.magnitude(
    vector.subtract(start-position, placed-pulley.center),
  )
  let end-distance-from-pulley = vector.magnitude(
    vector.subtract(end-position, placed-pulley.center),
  )
  assert(
    start-distance-from-pulley > placed-pulley.radius
      and end-distance-from-pulley > placed-pulley.radius,
    message: (
      "typed-physics: "
        + declared-by
        + " runs over pulley \""
        + pulley-name
        + "\" but an endpoint lies on or inside the wheel; move both endpoints outside its radius"
    ),
  )
  // The rope leaves each end on the side that carries it over the wheel rather
  // than under it.
  let start-is-left-of-pulley = (
    start-position.at(0) <= placed-pulley.center.at(0)
  )
  placed-connector + (
    over: pulley-name,
    start-tangent: _tangent-point-on-pulley(
      placed-pulley,
      start-position,
      if start-is-left-of-pulley { -1 } else { 1 },
    ),
    end-tangent: _tangent-point-on-pulley(
      placed-pulley,
      end-position,
      if start-is-left-of-pulley { 1 } else { -1 },
    ),
  )
}

// ── The situation ────────────────────────────────────────────────────────────

#let resolve-situation-geometry(declarations, gravity: 9.81) = {
  validation.validate-situation-declarations(declarations, gravity)
  let declared-element-names = ()
  for declaration in declarations {
    assert(
      type(declaration) == dictionary and "kind" in declaration,
      message: "typed-physics: situation() takes elements such as ramp(...), block(...) or force(...)",
    )
    if "name" in declaration {
      assert(
        declaration.name not in declared-element-names,
        message: "typed-physics: \"" + declaration.name + "\" is declared twice; every element needs its own name",
      )
      declared-element-names.push(declaration.name)
    }
  }

  let declarations-of-kind(..kinds) = declarations.filter(
    declaration => declaration.kind in kinds.pos(),
  )
  let surface-declarations = declarations-of-kind(
    "ground",
    "wall",
    "ceiling",
    "ramp",
    "arc",
  )
  let body-declarations = declarations-of-kind("body")
  let pulley-declarations = declarations-of-kind("pulley")
  let structure-declarations = declarations-of-kind(
    "rod",
    "pivot",
    "support",
    "pendulum",
  )
  let torque-declarations = declarations-of-kind("torque")
  let connector-declarations = declarations-of-kind("rope", "spring")
  let applied-load-declarations = declarations-of-kind("force")
  let velocity-declarations = declarations-of-kind("velocity")
  let angular-velocity-declarations = declarations-of-kind("angular-velocity")

  let ramp-count = surface-declarations.filter(
    declaration => declaration.kind == "ramp",
  ).len()

  // Walls stand at the edges of everything else, so every other surface is
  // placed first and the span they bound is measured from the result.
  let placed-surfaces = (:)
  let spanning-surface-names = ()
  for surface-declaration in surface-declarations.filter(
    declaration => declaration.kind != "wall",
  ) {
    placed-surfaces.insert(
      surface-declaration.name,
      _resolve-surface-geometry(
        surface-declaration,
        (0, 0),
        ramp-count,
        placed-surfaces,
      ),
    )
    spanning-surface-names.push(surface-declaration.name)
  }
  let horizontal-span = _horizontal-surface-span(
    placed-surfaces,
    spanning-surface-names,
  )
  for surface-declaration in surface-declarations.filter(
    declaration => declaration.kind == "wall",
  ) {
    placed-surfaces.insert(
      surface-declaration.name,
      _resolve-surface-geometry(
        surface-declaration,
        horizontal-span,
        ramp-count,
        placed-surfaces,
      ),
    )
  }

  let placed-pulleys = (:)
  for pulley-declaration in pulley-declarations {
    placed-pulleys.insert(
      pulley-declaration.name,
      (
        name: pulley-declaration.name,
        kind: "pulley",
        center: resolve-attachment-point(
          pulley-declaration.at,
          placed-surfaces,
          (:),
          placed-pulleys,
          "pulley \"" + pulley-declaration.name + "\"",
        ),
        radius: pulley-declaration.radius,
        style: pulley-declaration.style,
      ),
    )
  }

  let placed-bodies = (:)
  for body-declaration in body-declarations {
    placed-bodies.insert(
      body-declaration.name,
      _resolve-body-placement(
        body-declaration,
        placed-surfaces,
        placed-bodies,
        placed-pulleys,
      ),
    )
  }
  for (body-index, body-name) in body-declarations.map(
    declaration => declaration.name,
  ).enumerate() {
    let placed-body = placed-bodies.at(body-name)
    if placed-body.support == none or placed-body.distance == none { continue }
    for other-body-name in body-declarations.slice(body-index + 1).map(
      declaration => declaration.name,
    ) {
      let other-body = placed-bodies.at(other-body-name)
      if (
        other-body.support == placed-body.support
          and other-body.distance != none
      ) {
        let center-separation = calc.abs(
          other-body.distance - placed-body.distance,
        )
        let required-separation = (
          placed-body.half-extent-along + other-body.half-extent-along
        )
        assert(
          center-separation + 0.000001 >= required-separation,
          message: (
            "typed-physics: bodies \""
              + placed-body.name
              + "\" and \""
              + other-body.name
              + "\" overlap on surface \""
              + placed-body.support
              + "\"; move one with `at:`/`side:` or reduce its size"
          ),
        )
      }
    }
  }

  let placed-structures = (:)
  for structure-declaration in structure-declarations {
    placed-structures.insert(
      structure-declaration.name,
      _resolve-structure-geometry(
        structure-declaration,
        placed-surfaces,
        placed-bodies,
        placed-pulleys,
        placed-structures,
      ),
    )
  }

  let placed-torques = torque-declarations.map(
    torque-declaration => _resolve-torque-geometry(
      torque-declaration,
      placed-surfaces,
      placed-bodies,
      placed-pulleys,
      placed-structures,
    ),
  )

  let placed-connectors = ()
  for connector-declaration in connector-declarations {
    placed-connectors.push(
      _resolve-connector-geometry(
        connector-declaration,
        placed-surfaces,
        placed-bodies,
        placed-pulleys,
        placed-structures: placed-structures,
      ),
    )
  }

  for applied-load-declaration in applied-load-declarations {
    let loaded-element-name = applied-load-declaration.on
    if loaded-element-name in placed-bodies {
      let loaded-body = placed-bodies.at(loaded-element-name)
      loaded-body.loads.push((
        magnitude: expression.declared(applied-load-declaration.magnitude, $F$),
        inclination: applied-load-declaration.angle,
        direction: vector.direction-from-angle(applied-load-declaration.angle),
        label: applied-load-declaration.label,
        style: applied-load-declaration.style,
      ))
      placed-bodies.at(loaded-element-name) = loaded-body
    } else {
      assert(
        loaded-element-name in placed-structures
          and placed-structures.at(loaded-element-name).kind == "rod",
        message: "typed-physics: force() acts on \"" + loaded-element-name + "\", which is not a body or rod in this situation",
      )
      let loaded-rod = placed-structures.at(loaded-element-name)
      let application-position = if applied-load-declaration.at == auto {
        loaded-rod.center
      } else if type(applied-load-declaration.at) == ratio {
        _point-on-rod(loaded-rod, applied-load-declaration.at)
      } else {
        resolve-attachment-point(
          applied-load-declaration.at,
          placed-surfaces,
          placed-bodies,
          placed-pulleys,
          "force() on \"" + loaded-element-name + "\"",
          placed-structures: placed-structures,
        )
      }
      loaded-rod.loads.push((
        magnitude: expression.declared(applied-load-declaration.magnitude, $F$),
        inclination: applied-load-declaration.angle,
        direction: vector.direction-from-angle(applied-load-declaration.angle),
        application-position: application-position,
        label: applied-load-declaration.label,
        style: applied-load-declaration.style,
      ))
      placed-structures.at(loaded-element-name) = loaded-rod
    }
  }

  for velocity-declaration in velocity-declarations {
    assert(
      velocity-declaration.on in placed-bodies,
      message: "typed-physics: velocity() belongs to \"" + velocity-declaration.on + "\", which is not a body in this situation",
    )
    let moving-body = placed-bodies.at(velocity-declaration.on)
    moving-body.velocities.push((
      magnitude: expression.declared(velocity-declaration.magnitude, $v$),
      direction: vector.direction-from-angle(velocity-declaration.angle),
      label: velocity-declaration.label,
      style: velocity-declaration.style,
    ))
    placed-bodies.at(velocity-declaration.on) = moving-body
  }

  for angular-velocity-declaration in angular-velocity-declarations {
    let body-name = angular-velocity-declaration.on
    assert(
      body-name in placed-bodies,
      message: "typed-physics: angular-velocity() belongs to \"" + body-name + "\", which is not a body in this situation",
    )
    let rotating-body = placed-bodies.at(body-name)
    assert(
      rotating-body.shape in ("ball", "disk", "ring"),
      message: "typed-physics: angular-velocity() needs a ball, disk, or ring; \"" + body-name + "\" is a " + rotating-body.shape,
    )
    let turns-clockwise = (
      angular-velocity-declaration.direction == "clockwise"
    )
    let start-angle = if angular-velocity-declaration.start-angle == auto {
      if turns-clockwise { 220deg } else { 140deg }
    } else {
      angular-velocity-declaration.start-angle
    }
    let raw-end-angle = if angular-velocity-declaration.end-angle == auto {
      if turns-clockwise { 140deg } else { 220deg }
    } else {
      angular-velocity-declaration.end-angle
    }
    let directed-end-angle = if turns-clockwise and raw-end-angle >= start-angle {
      raw-end-angle - 360deg
    } else if not turns-clockwise and raw-end-angle <= start-angle {
      raw-end-angle + 360deg
    } else {
      raw-end-angle
    }
    let arrow-radius = if angular-velocity-declaration.radius == auto {
      rotating-body.half-extent-along + 0.28
    } else {
      angular-velocity-declaration.radius
    }
    assert(
      arrow-radius > rotating-body.half-extent-along,
      message: "typed-physics: angular-velocity() radius: must place the arrow outside \"" + body-name + "\"",
    )
    rotating-body.angular-velocities.push((
      magnitude: angular-velocity-declaration.magnitude,
      direction: angular-velocity-declaration.direction,
      radius: arrow-radius,
      start-angle: start-angle,
      end-angle: directed-end-angle,
      label: angular-velocity-declaration.label,
      style: angular-velocity-declaration.style,
    ))
    placed-bodies.at(body-name) = rotating-body
  }

  (
    gravity: gravity-quantity(gravity),
    surfaces: placed-surfaces,
    bodies: placed-bodies,
    pulleys: placed-pulleys,
    structures: placed-structures,
    torques: placed-torques,
    connectors: placed-connectors,
    surface-order: surface-declarations.map(declaration => declaration.name),
    body-order: body-declarations.map(declaration => declaration.name),
    structure-order: structure-declarations.map(
      declaration => declaration.name,
    ),
    span: horizontal-span,
  )
}

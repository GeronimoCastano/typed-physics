// Turning declarations into placed geometry.
//
// This is where relational placement becomes coordinates: a surface knows
// where it starts, which way it runs, and which way points out of it, and a
// body sits some distance along one of those surfaces. Nothing downstream
// reads a coordinate the author wrote, because there are none to read.

#import "vector.typ"
#import "expression.typ"

#let gravity-quantity(value) = expression.quantity($g$, value: value)

// `block("m1")` should print as m_1 and `block("A")` as m_A, so a name that is
// already a mass symbol does not get wrapped in another one.
#let mass-symbol(name) = {
  let numbered = name.match(regex("^m([0-9]+)$"))
  if numbered != none {
    let index = numbered.captures.first()
    return $m_#index$
  }
  $m_#name$
}

#let angle-symbol(name, inclined-count) = if inclined-count <= 1 { $theta$ } else { $theta_#name$ }

#let _horizontal-span(declarations) = {
  let ends = (0,)
  for declaration in declarations {
    if declaration.kind == "ramp" {
      ends.push(declaration.length * calc.cos(declaration.angle))
    } else if declaration.kind in ("ground", "ceiling") {
      ends.push(declaration.length)
    }
  }
  (0, calc.max(..ends))
}

#let _surface(name, kind, start, direction, outward-normal, length, inclination, friction, extras) = (
  name: name,
  kind: kind,
  start: start,
  end: vector.stepped(start, direction, length),
  direction: direction,
  outward-normal: outward-normal,
  length: length,
  inclination: inclination,
  friction: friction,
) + extras

#let _resolve-surface(declaration, span, inclined-count) = {
  let kind = declaration.kind
  let name = declaration.name

  // A flat support keeps an exact zero for its inclination, so the incline
  // equations collapse to the horizontal ones on their own instead of through
  // a second set of formulas.
  if kind == "ground" {
    return _surface(
      name,
      kind,
      (0, 0),
      (1, 0),
      (0, 1),
      declaration.length,
      0deg,
      declaration.friction,
      (inclination-quantity: expression.number(0)),
    )
  }

  if kind == "ceiling" {
    return _surface(
      name,
      kind,
      (0, declaration.height),
      (1, 0),
      (0, -1),
      declaration.length,
      0deg,
      declaration.friction,
      (inclination-quantity: expression.number(0), height: declaration.height),
    )
  }

  if kind == "ramp" {
    let inclination = declaration.angle
    let direction = vector.from-angle(inclination)
    let surface = _surface(
      name,
      kind,
      (0, 0),
      direction,
      vector.left-normal(direction),
      declaration.length,
      inclination,
      declaration.friction,
      (inclination-quantity: expression.declared-angle(inclination, angle-symbol(name, inclined-count))),
    )
    return surface + (
      foot: surface.start,
      apex: surface.end,
      base-corner: (surface.end.at(0), 0),
    )
  }

  let foot = if declaration.side == "left" { (span.at(0), 0) } else { (span.at(1), 0) }
  let facing = if declaration.side == "left" { (1, 0) } else { (-1, 0) }
  _surface(
    name,
    kind,
    foot,
    (0, 1),
    facing,
    declaration.height,
    90deg,
    declaration.friction,
    (inclination-quantity: expression.declared-angle(90deg, $theta$), side: declaration.side, foot: foot),
  )
}

// A block's own `mu:` describes the contact it makes, and the surface's `mu:`
// describes everything that touches it. The nearer declaration wins.
#let _contact-friction(declaration, surface) = {
  let declared = if declaration.friction != none { declaration.friction } else { surface.friction }
  if declared == none { return none }
  (
    static: expression.declared(declared.static, $mu_s$),
    kinetic: expression.declared(declared.kinetic, $mu_k$),
  )
}

#let _place-on-surface(declaration, surface, distance) = {
  let half = declaration.size / 2
  let past-start = half - distance
  let past-end = distance + half - surface.length
  assert(
    past-start <= 1e-9,
    message: (
      "typed-physics: block \""
        + declaration.name
        + "\" hangs off the start of \""
        + surface.name
        + "\" by "
        + expression.format-number(past-start)
        + " — move it along with `at:` or shrink it with `size:`"
    ),
  )
  assert(
    past-end <= 1e-9,
    message: (
      "typed-physics: block \""
        + declaration.name
        + "\" hangs off the end of \""
        + surface.name
        + "\" by "
        + expression.format-number(past-end)
        + " — move it back with `at:` or shrink it with `size:`"
    ),
  )
  let contact = vector.stepped(surface.start, surface.direction, distance)
  (
    name: declaration.name,
    kind: "block",
    label: declaration.label,
    mass: expression.declared(declaration.mass, mass-symbol(declaration.name)),
    size: declaration.size,
    support: surface.name,
    distance: distance,
    contact: contact,
    center: vector.stepped(contact, surface.outward-normal, half),
    direction: surface.direction,
    outward-normal: surface.outward-normal,
    inclination: surface.inclination,
    inclination-quantity: surface.inclination-quantity,
    friction: _contact-friction(declaration, surface),
    loads: (),
  )
}

#let _resolve-body(declaration, surfaces, placed) = {
  if declaration.touching != none {
    assert(
      declaration.touching in placed,
      message: (
        "typed-physics: block \""
          + declaration.name
          + "\" touches \""
          + declaration.touching
          + "\", which is not a body declared before it"
      ),
    )
    let neighbour = placed.at(declaration.touching)
    let surface = surfaces.at(neighbour.support)
    let gap = (neighbour.size + declaration.size) / 2
    return _place-on-surface(
      declaration,
      surface,
      neighbour.distance + if declaration.side == "right" { gap } else { -gap },
    )
  }

  assert(
    declaration.on in surfaces,
    message: (
      "typed-physics: block \""
        + declaration.name
        + "\" rests on \""
        + declaration.on
        + "\", which is not a surface in this situation"
    ),
  )
  let surface = surfaces.at(declaration.on)
  _place-on-surface(declaration, surface, surface.length * (declaration.at / 100%))
}

#let resolve(declarations, gravity: 9.81) = {
  let seen = ()
  for declaration in declarations {
    assert(
      type(declaration) == dictionary and "kind" in declaration,
      message: "typed-physics: situation() takes elements such as ramp(...), block(...) or force(...)",
    )
    if "name" in declaration {
      assert(
        declaration.name not in seen,
        message: "typed-physics: \"" + declaration.name + "\" is declared twice; every element needs its own name",
      )
      seen.push(declaration.name)
    }
  }

  let surface-declarations = declarations.filter(each => each.kind in ("ground", "wall", "ceiling", "ramp"))
  let body-declarations = declarations.filter(each => each.kind == "block")
  let load-declarations = declarations.filter(each => each.kind == "force")

  let span = _horizontal-span(surface-declarations)
  let inclined-count = surface-declarations.filter(each => each.kind == "ramp").len()

  let surfaces = (:)
  for declaration in surface-declarations {
    surfaces.insert(declaration.name, _resolve-surface(declaration, span, inclined-count))
  }

  let bodies = (:)
  for declaration in body-declarations {
    bodies.insert(declaration.name, _resolve-body(declaration, surfaces, bodies))
  }

  for load in load-declarations {
    assert(
      load.on in bodies,
      message: "typed-physics: force() acts on \"" + load.on + "\", which is not a body in this situation",
    )
    let body = bodies.at(load.on)
    body.loads.push((
      magnitude: expression.declared(load.magnitude, $F$),
      inclination: load.angle,
      direction: vector.from-angle(load.angle),
      label: load.label,
    ))
    bodies.at(load.on) = body
  }

  (
    gravity: gravity-quantity(gravity),
    surfaces: surfaces,
    bodies: bodies,
    surface-order: surface-declarations.map(each => each.name),
    body-order: body-declarations.map(each => each.name),
    span: span,
  )
}

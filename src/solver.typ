// Balancing one body against the surface it rests on.
//
// The solver works in the surface's own axes: along it, positive up the slope,
// and out of it. Every equation below is written once in that frame and holds
// for level ground too, because level ground carries an exact zero for its
// inclination and the sines and cosines fold away on their own.
//
// The friction regime is decided, not assumed. Whether the required static
// friction fits inside what the contact can supply is the question a figure
// cannot answer and the one authors get wrong, so it is answered first and
// reported before any acceleration is.

#import "expression.typ"
#import "forces.typ"
#import "vector.typ"

#let _unsupported(scene, name) = {
  let body = scene.bodies.at(name)
  assert(
    body.support != none,
    message: "typed-physics: block \"" + name + "\" rests on nothing, so there is nothing to balance it against",
  )
  let surface = scene.surfaces.at(body.support)
  assert(
    surface.kind in ("ground", "ramp"),
    message: (
      "typed-physics 0.1.0 solves a body resting on a ground or a ramp; \""
        + name
        + "\" rests on a "
        + surface.kind
        + ", which needs the connectors planned for a later version"
    ),
  )
  assert(
    body.mass != none,
    message: "typed-physics: block \"" + name + "\" needs a `mass:` before it can be solved",
  )
}

#let _regime-of(drive-value, available-value, assume) = {
  if assume != auto {
    assert(
      assume in ("static", "sliding"),
      message: "typed-physics: solve(assume:) must be \"static\" or \"sliding\"",
    )
    return assume
  }
  if drive-value == none or available-value == none { return none }
  if calc.abs(drive-value) <= available-value + 1e-9 { "static" } else { "sliding" }
}

#let _undetermined-reason(drive, available) = {
  if not expression.is-known(drive) {
    return [the net force along the surface is symbolic]
  }
  [the available static friction is symbolic]
}

// Balances `name` and reports the regime it lands in. The result is a plain
// dictionary so a caller can typeset it, draw it, or read a single number out
// of it without going through the report.
#let solve-body(scene, name, assume: auto) = {
  assert(
    name in scene.bodies,
    message: "typed-physics: there is no body called \"" + name + "\" in this situation",
  )
  _unsupported(scene, name)

  let body = scene.bodies.at(name)
  let surface = scene.surfaces.at(body.support)
  let inclination = body.inclination-quantity
  let weight = expression.product(body.mass, scene.gravity)

  let along-terms = (expression.negated(expression.product(weight, expression.sine(inclination))),)
  let normal-terms = (expression.negated(expression.product(weight, expression.cosine(inclination))),)
  for load in body.loads {
    let parts = forces.components-of(load, body)
    along-terms.push(parts.along)
    normal-terms.push(parts.normal)
  }

  let normal = expression.negated(expression.sum(..normal-terms))
  let normal-value = expression.value-of(normal)
  assert(
    normal-value == none or normal-value > -1e-9,
    message: (
      "typed-physics: the normal force on \""
        + name
        + "\" comes out negative ("
        + expression.format-number(normal-value)
        + " N), so it leaves the surface instead of resting on it"
    ),
  )
  let normal-quantity = expression.quantity($N$, value: normal-value)

  let drive = expression.sum(..along-terms)
  let required = expression.magnitude-of(drive)
  let available = if body.friction == none {
    expression.number(0)
  } else {
    expression.product(body.friction.static, normal-quantity)
  }

  let drive-value = expression.value-of(drive)
  let available-value = expression.value-of(available)
  let regime = _regime-of(drive-value, available-value, assume)

  if regime == none {
    return (
      status: "undetermined",
      body: name,
      surface: surface.name,
      normal: (expression: normal, value: normal-value, quantity: normal-quantity),
      required: (expression: required, value: expression.value-of(required)),
      available: (expression: available, value: available-value),
      reason: _undetermined-reason(drive, available),
    )
  }

  // Positive drive pushes the body up the surface, so the direction it tends
  // to move — and the direction friction opposes — follows its sign.
  let downhill = if drive-value != none { drive-value < 0 } else { drive.kind == "negated" }
  let motion = if downhill { vector.reversed(body.direction) } else { body.direction }

  let kinetic = if body.friction == none {
    expression.number(0)
  } else {
    expression.product(body.friction.kinetic, normal-quantity)
  }

  let friction-expression = if regime == "static" { required } else { kinetic }
  let acceleration = if regime == "static" {
    expression.number(0)
  } else {
    expression.ratio(
      expression.difference(
        required,
        if body.friction == none { expression.number(0) } else {
          expression.product(body.friction.kinetic, normal)
        },
      ),
      body.mass,
    )
  }

  (
    status: "solved",
    body: name,
    surface: surface.name,
    regime: regime,
    // Whether the regime was decided here or handed over by the caller, so a
    // report never claims to have checked something it was told.
    assumed: assume != auto,
    // A frictionless contact has no coefficients to talk about, and a report
    // that names them anyway is describing a contact that was never declared.
    rough: body.friction != none,
    inclination: inclination,
    weight: (expression: weight, value: expression.value-of(weight)),
    normal: (expression: normal, value: normal-value, quantity: normal-quantity),
    required: (expression: required, value: expression.value-of(required)),
    available: (expression: available, value: available-value),
    friction: (
      expression: friction-expression,
      value: expression.value-of(friction-expression),
      direction: vector.reversed(motion),
    ),
    acceleration: (
      expression: acceleration,
      value: expression.value-of(acceleration),
      direction: motion,
    ),
    motion: motion,
    downhill: downhill,
  )
}

// The situation's solution, once there is a way to solve more than one body at
// a time. Until then the single supported body is the answer, and anything
// else says so rather than guessing.
#let solve-situation(scene, body: auto, assume: auto) = {
  let names = scene.body-order
  assert(names.len() > 0, message: "typed-physics: this situation has no bodies to solve")
  if body != auto { return solve-body(scene, body, assume: assume) }
  assert(
    names.len() == 1,
    message: (
      "typed-physics 0.1.0 solves one body at a time; this situation has "
        + str(names.len())
        + " ("
        + names.join(", ")
        + ") — pass `body:` to choose one"
    ),
  )
  solve-body(scene, names.first(), assume: assume)
}

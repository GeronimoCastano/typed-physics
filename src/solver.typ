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
#import "validation.typ"

#let _validate-body-can-be-solved(scene, body-name) = {
  let body = scene.bodies.at(body-name)
  assert(
    body.solver-supported,
    message: "typed-physics: \"" + body-name + "\" is a drawing-only " + body.shape + " and is not supported by solve()",
  )
  assert(
    body.support != none,
    message: "typed-physics: block \"" + body-name + "\" rests on nothing, so there is nothing to balance it against",
  )
  let support-surface = scene.surfaces.at(body.support)
  assert(
    support-surface.kind in ("ground", "ramp"),
    message: (
      "typed-physics 0.1.0 solves a body resting on a ground or a ramp; \""
        + body-name
        + "\" rests on a "
        + support-surface.kind
        + ", which needs the connectors planned for a later version"
    ),
  )
  assert(
    body.mass != none,
    message: "typed-physics: block \"" + body-name + "\" needs a `mass:` before it can be solved",
  )
}

// Whether balancing this body is a case the solver handles at all. Drawing a
// body must never depend on the answer, so the views ask this first and fall
// back to an unsolved figure rather than to an error.
#let body-can-be-balanced(scene, body-name) = {
  let body = scene.bodies.at(body-name)
  if not body.solver-supported { return false }
  if body.support == none { return false }
  if scene.surfaces.at(body.support).kind not in ("ground", "ramp") {
    return false
  }
  body.mass != none
}

#let _determine-friction-regime(
  net-force-along-surface-value,
  maximum-static-friction-value,
  assumed-regime,
) = {
  if assumed-regime != auto {
    assert(
      assumed-regime in ("static", "sliding"),
      message: "typed-physics: solve(assume:) must be \"static\" or \"sliding\"",
    )
    return assumed-regime
  }

  if (
    net-force-along-surface-value == none
      or maximum-static-friction-value == none
  ) {
    return none
  }

  let required-static-friction-value = calc.abs(
    net-force-along-surface-value,
  )
  let static-friction-is-sufficient = (
    required-static-friction-value <= maximum-static-friction-value + 1e-9
  )
  if static-friction-is-sufficient { "static" } else { "sliding" }
}

#let _undetermined-regime-reason(
  net-force-along-surface,
  maximum-static-friction,
) = {
  if not expression.is-known(net-force-along-surface) {
    return [the net force along the surface is symbolic]
  }
  [the available static friction is symbolic]
}

// Balances `name` and reports the regime it lands in. The result is a plain
// dictionary so a caller can typeset it, draw it, or read a single number out
// of it without going through the report.
#let solve-body(scene, name, assume: auto) = {
  validation.validate-body-name(scene, name, "solve()")
  validation.validate-enum(
    assume,
    (auto, "static", "sliding"),
    "solve()",
    "assume",
  )
  _validate-body-can-be-solved(scene, name)

  let body = scene.bodies.at(name)
  let support-surface = scene.surfaces.at(body.support)
  let surface-inclination = body.inclination-quantity
  let weight-force-magnitude = expression.product(body.mass, scene.gravity)

  let signed-force-components-along-surface = (
    expression.negated(
      expression.product(
        weight-force-magnitude,
        expression.sine(surface-inclination),
      ),
    ),
  )
  let signed-force-components-outward-normal = (
    expression.negated(
      expression.product(
        weight-force-magnitude,
        expression.cosine(surface-inclination),
      ),
    ),
  )
  for applied-load in body.loads {
    let load-components = forces.resolve-load-components-in-surface-frame(
      applied-load,
      body,
    )
    signed-force-components-along-surface.push(load-components.along)
    signed-force-components-outward-normal.push(load-components.normal)
  }

  let normal-force-magnitude = expression.negated(
    expression.sum(..signed-force-components-outward-normal),
  )
  let normal-force-value = expression.value-of(normal-force-magnitude)
  assert(
    normal-force-value == none or normal-force-value > -1e-9,
    message: (
      "typed-physics: the normal force on \""
        + name
        + "\" comes out negative ("
        + expression.format-number(normal-force-value)
        + " N), so it leaves the surface instead of resting on it"
    ),
  )
  let normal-force-quantity = expression.quantity(
    $N$,
    value: normal-force-value,
  )

  // Positive values point up the surface; negative values point down it.
  let net-force-along-surface = expression.sum(
    ..signed-force-components-along-surface,
  )
  let required-static-friction = expression.magnitude-of(
    net-force-along-surface,
  )
  let maximum-static-friction = if body.friction == none {
    expression.number(0)
  } else {
    expression.product(body.friction.static, normal-force-quantity)
  }

  let net-force-along-surface-value = expression.value-of(
    net-force-along-surface,
  )
  let maximum-static-friction-value = expression.value-of(
    maximum-static-friction,
  )
  let friction-regime = _determine-friction-regime(
    net-force-along-surface-value,
    maximum-static-friction-value,
    assume,
  )

  if friction-regime == none {
    return (
      status: "undetermined",
      body: name,
      surface: support-surface.name,
      normal: (
        expression: normal-force-magnitude,
        value: normal-force-value,
        quantity: normal-force-quantity,
      ),
      required: (
        expression: required-static-friction,
        value: expression.value-of(required-static-friction),
      ),
      available: (
        expression: maximum-static-friction,
        value: maximum-static-friction-value,
      ),
      reason: _undetermined-regime-reason(
        net-force-along-surface,
        maximum-static-friction,
      ),
    )
  }

  // Friction opposes the potential motion identified by the signed net force.
  let body-would-slide-down-surface = if net-force-along-surface-value != none {
    net-force-along-surface-value < 0
  } else {
    net-force-along-surface.kind == "negated"
  }
  let potential-motion-direction = if body-would-slide-down-surface {
    vector.reversed(body.direction)
  } else {
    body.direction
  }

  let kinetic-friction-magnitude = if body.friction == none {
    expression.number(0)
  } else {
    expression.product(body.friction.kinetic, normal-force-quantity)
  }

  let friction-force-magnitude = if friction-regime == "static" {
    required-static-friction
  } else {
    kinetic-friction-magnitude
  }
  let acceleration-along-surface = if friction-regime == "static" {
    expression.number(0)
  } else {
    expression.ratio(
      expression.difference(
        required-static-friction,
        if body.friction == none { expression.number(0) } else {
          expression.product(
            body.friction.kinetic,
            normal-force-magnitude,
          )
        },
      ),
      body.mass,
    )
  }

  (
    status: "solved",
    body: name,
    surface: support-surface.name,
    regime: friction-regime,
    // Whether the regime was decided here or handed over by the caller, so a
    // report never claims to have checked something it was told.
    assumed: assume != auto,
    // A frictionless contact has no coefficients to talk about, and a report
    // that names them anyway is describing a contact that was never declared.
    rough: body.friction != none,
    inclination: surface-inclination,
    weight: (
      expression: weight-force-magnitude,
      value: expression.value-of(weight-force-magnitude),
    ),
    normal: (
      expression: normal-force-magnitude,
      value: normal-force-value,
      quantity: normal-force-quantity,
    ),
    required: (
      expression: required-static-friction,
      value: expression.value-of(required-static-friction),
    ),
    available: (
      expression: maximum-static-friction,
      value: maximum-static-friction-value,
    ),
    friction: (
      expression: friction-force-magnitude,
      value: expression.value-of(friction-force-magnitude),
      direction: vector.reversed(potential-motion-direction),
    ),
    acceleration: (
      expression: acceleration-along-surface,
      value: expression.value-of(acceleration-along-surface),
      direction: potential-motion-direction,
    ),
    motion: potential-motion-direction,
    downhill: body-would-slide-down-surface,
  )
}

// The situation's solution, once there is a way to solve more than one body at
// a time. Until then the single supported body is the answer, and anything
// else says so rather than guessing.
#let solve-situation(scene, body: auto, assume: auto) = {
  validation.validate-enum(
    assume,
    (auto, "static", "sliding"),
    "solve()",
    "assume",
  )
  let body-names = scene.body-order
  assert(
    body-names.len() > 0,
    message: "typed-physics: this situation has no bodies to solve",
  )
  if body != auto {
    validation.validate-body-name(scene, body, "solve()")
    return solve-body(scene, body, assume: assume)
  }
  assert(
    body-names.len() == 1,
    message: (
      "typed-physics 0.1.0 solves one body at a time; this situation has "
        + str(body-names.len())
        + " ("
        + body-names.join(", ")
        + ") — pass the body name positionally, for example `solve(s, \""
        + body-names.first()
        + "\")`"
    ),
  )
  solve-body(scene, body-names.first(), assume: assume)
}

// Enumerating the forces on a body.
//
// A declaration already says everything needed to know which forces act: a
// body with a mass has a weight, a body resting on a surface has a normal
// force, a rough contact has friction, and the problem statement's own loads
// are named where they were declared. Nothing here is drawn — a free-body
// diagram is the enumeration rendered, which is why it cannot disagree with
// the scene it came from.

#import "vector.typ"
#import "expression.typ"

// The component of a load along and out of the surface its body rests on.
// A load that lies on one of the surface's own axes contributes exactly, not
// through a cosine of zero, so a horizontal push on level ground stays `F`.
#let resolve-load-components-in-surface-frame(applied-load, body) = {
  let load-angle-relative-to-surface = (
    applied-load.inclination - body.inclination
  )
  let load-is-axis-aligned = (
    calc.abs(calc.rem(load-angle-relative-to-surface.deg(), 90)) < 1e-9
  )
  let relative-angle-quantity = expression.declared-angle(
    load-angle-relative-to-surface,
    $phi$,
  )
  if load-is-axis-aligned {
    return (
      along: expression.product(
        applied-load.magnitude,
        expression.number(
          calc.round(
            calc.cos(load-angle-relative-to-surface),
            digits: 6,
          ),
        ),
      ),
      normal: expression.product(
        applied-load.magnitude,
        expression.number(
          calc.round(
            calc.sin(load-angle-relative-to-surface),
            digits: 6,
          ),
        ),
      ),
    )
  }
  (
    along: expression.product(
      applied-load.magnitude,
      expression.cosine(relative-angle-quantity),
    ),
    normal: expression.product(
      applied-load.magnitude,
      expression.sine(relative-angle-quantity),
    ),
  )
}

#let applied-load-symbol(applied-load, load-index, applied-load-count) = {
  if applied-load.label != auto { return applied-load.label }
  if applied-load-count <= 1 { $F$ } else { $F_#(load-index + 1)$ }
}

// The forces acting on one body, in the order a reader expects to meet them.
// `solution` fills in the magnitudes and the friction direction that only
// follow from balancing the body; without one the contact forces are still
// enumerated, with their magnitudes left unknown.
#let enumerate-forces(scene, name, solution: none) = {
  let body = scene.bodies.at(name)
  let acting-forces = ()

  if body.mass != none {
    acting-forces.push((
      role: "weight",
      symbol: $W$,
      direction: (0, -1),
      magnitude: expression.product(body.mass, scene.gravity),
      applied-at: body.center,
      style: (:),
    ))
  }

  // A body held up by something other than a surface still has a force holding
  // it up, and the free-body diagram is entitled to show it even though its
  // magnitude waits on a solve this package does not attempt.
  if body.hangs-from != none {
    acting-forces.push((
      role: "tension",
      symbol: $T$,
      direction: vector.normalized(
        vector.subtract(body.hangs-from, body.center),
      ),
      magnitude: none,
      applied-at: body.center,
      style: (:),
    ))
  }

  if body.support != none {
    acting-forces.push((
      role: "normal",
      symbol: $N$,
      direction: body.outward-normal,
      magnitude: if solution == none { none } else { solution.normal.expression },
      applied-at: body.contact,
      style: (:),
    ))

    // A contact that turns out to need no friction is not exerting any, so
    // nothing is drawn for it once the body has been balanced.
    let friction-force-acts = (
      body.friction != none
        and (
          solution == none
            or solution.friction.value == none
            or calc.abs(solution.friction.value) > 1e-9
        )
    )
    if friction-force-acts {
      let body-is-sliding = solution != none and solution.regime == "sliding"
      acting-forces.push((
        role: "friction",
        symbol: if solution == none {
          $f$
        } else if body-is-sliding {
          $f_k$
        } else {
          $f_s$
        },
        direction: if solution == none {
          body.direction
        } else {
          solution.friction.direction
        },
        magnitude: if solution == none {
          none
        } else {
          solution.friction.expression
        },
        applied-at: body.contact,
        style: (:),
      ))
    }
  }

  let applied-load-count = body.loads.len()
  for (load-index, applied-load) in body.loads.enumerate() {
    acting-forces.push((
      role: "applied",
      symbol: applied-load-symbol(
        applied-load,
        load-index,
        applied-load-count,
      ),
      direction: applied-load.direction,
      magnitude: applied-load.magnitude,
      applied-at: body.center,
      style: applied-load.style,
    ))
  }

  acting-forces
}

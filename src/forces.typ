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
#let components-of(load, body) = {
  let relative = load.inclination - body.inclination
  let on-axis = calc.abs(calc.rem(relative.deg(), 90)) < 1e-9
  let angle-to-surface = expression.declared-angle(relative, $phi$)
  if on-axis {
    return (
      along: expression.product(load.magnitude, expression.number(calc.round(calc.cos(relative), digits: 6))),
      normal: expression.product(load.magnitude, expression.number(calc.round(calc.sin(relative), digits: 6))),
    )
  }
  (
    along: expression.product(load.magnitude, expression.cosine(angle-to-surface)),
    normal: expression.product(load.magnitude, expression.sine(angle-to-surface)),
  )
}

#let load-symbol(load, index, count) = {
  if load.label != auto { return load.label }
  if count <= 1 { $F$ } else { $F_#(index + 1)$ }
}

// The forces acting on one body, in the order a reader expects to meet them.
// `solution` fills in the magnitudes and the friction direction that only
// follow from balancing the body; without one the contact forces are still
// enumerated, with their magnitudes left unknown.
#let enumerate-forces(scene, name, solution: none) = {
  let body = scene.bodies.at(name)
  let forces = ()

  if body.mass != none {
    forces.push((
      role: "weight",
      symbol: $W$,
      direction: (0, -1),
      magnitude: expression.product(body.mass, scene.gravity),
      applied-at: body.center,
    ))
  }

  if body.support != none {
    forces.push((
      role: "normal",
      symbol: $N$,
      direction: body.outward-normal,
      magnitude: if solution == none { none } else { solution.normal.expression },
      applied-at: body.contact,
    ))

    if body.friction != none {
      let sliding = solution != none and solution.regime == "sliding"
      forces.push((
        role: "friction",
        symbol: if solution == none { $f$ } else if sliding { $f_k$ } else { $f_s$ },
        direction: if solution == none { body.direction } else { solution.friction.direction },
        magnitude: if solution == none { none } else { solution.friction.expression },
        applied-at: body.contact,
      ))
    }
  }

  let count = body.loads.len()
  for (index, load) in body.loads.enumerate() {
    forces.push((
      role: "applied",
      symbol: load-symbol(load, index, count),
      direction: load.direction,
      magnitude: load.magnitude,
      applied-at: body.center,
    ))
  }

  forces
}

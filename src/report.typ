// Typesetting a quantity the solver found.
//
// The package states quantities; the argument around them is the author's to
// write. Nothing here composes a sentence that a document in another language
// would have to fight.

#import "expression.typ"
#import "forces.typ" as force-enumeration

#let newtons = $"N"$
#let metres-per-second-squared = $"m/s"^2$

#let _with-unit(rendered-value, unit) = if unit == none {
  rendered-value
} else {
  $#rendered-value thin #unit$
}

// What is left of an expression once every quantity that has a number is
// replaced by it. A fully known term reaches a value, a fully symbolic one does
// not move, and a mixed one lands somewhere in between.
#let _partially-evaluated(term) = {
  let folded-term = expression.evaluated-where-known(term)
  if folded-term == term { none } else { folded-term }
}

// A stated quantity is the value when every quantity behind it carries one, and
// otherwise the expression carried as far as the declared numbers reach.
#let _typeset-stated-value(symbol, term, unit: none) = {
  let numeric-value = expression.numeric-math-of(term)
  if numeric-value != none {
    return $#symbol = #_with-unit(numeric-value, unit)$
  }
  let folded-term = _partially-evaluated(term)
  if folded-term != none {
    return $#symbol = #_with-unit(expression.math-of(folded-term), unit)$
  }
  $#symbol = #expression.math-of(term)$
}

// Where the body goes, said the way the figure reads: a slope has an uphill and
// a downhill, level ground only has a left and a right. Written in English, so
// `direction: false` is how a document in another language leaves it out.
#let _motion-direction-words(scene, solution) = {
  let support-surface = scene.surfaces.at(solution.surface)
  if support-surface.kind == "ramp" {
    if solution.downhill { "down the incline" } else { "up the incline" }
  } else if solution.motion.at(0) >= 0 { "to the right" } else { "to the left" }
}

// What a problem asks for when it does not say. A body that stays put has
// already answered the interesting question with its regime.
#let _quantity-asked-for(solution) = if solution.regime == "static" {
  "regime"
} else {
  "acceleration"
}

#let typeset-answer(scene, solution, find: auto, direction: true) = {
  let solution-is-undetermined = solution.status == "undetermined"
  let asked-for = if find == auto {
    if solution-is-undetermined {
      "regime"
    } else { _quantity-asked-for(solution) }
  } else { find }
  assert(
    asked-for in ("acceleration", "normal", "friction", "regime"),
    message: "typed-physics: solve(find:) takes \"acceleration\", \"normal\", \"friction\" or \"regime\", got " + repr(find),
  )

  // The normal force falls out of the balance across the surface, which does
  // not depend on which way the body is about to go.
  if asked-for == "normal" {
    return _typeset-stated-value($N$, solution.normal.expression, unit: newtons)
  }

  if solution-is-undetermined {
    return [
      typed-physics cannot decide whether *#solution.body* slides, because #solution.reason. Give the coefficients and masses
      as numbers, or state the regime with `assume:`.
    ]
  }

  if asked-for == "regime" { return solution.regime }

  if asked-for == "friction" {
    let friction-symbol = if not solution.rough {
      $f$
    } else if solution.regime == "static" { $f_s$ } else { $f_k$ }
    return _typeset-stated-value(
      friction-symbol,
      solution.friction.expression,
      unit: newtons,
    )
  }

  let stated-acceleration = _typeset-stated-value(
    $a$,
    solution.acceleration.expression,
    unit: metres-per-second-squared,
  )
  if solution.regime == "static" or not direction {
    return stated-acceleration
  }
  [#stated-acceleration, #_motion-direction-words(scene, solution)]
}

// Every force on a body with its components in the surface's own axes: the
// bookkeeping behind the free-body diagram, in the order the diagram draws it.
#let typeset-force-table(scene, name, solution: none) = {
  let body = scene.bodies.at(name)
  let acting-forces = force-enumeration.enumerate-forces(
    scene,
    name,
    solution: solution,
  )
  let force-component-cell(force, axis-direction) = {
    if force.magnitude == none { return [—] }
    let force-magnitude = expression.value-of(force.magnitude)
    if force-magnitude == none { return [—] }
    let signed-component = force-magnitude * (
      force.direction.at(0) * axis-direction.at(0)
        + force.direction.at(1) * axis-direction.at(1)
    )
    [#expression.format-number(signed-component)]
  }
  table(
    columns: 4,
    align: (left, right, right, right),
    stroke: none,
    table.hline(),
    table.header([Force], [Magnitude (N)], [Along], [Out of surface]),
    table.hline(),
    ..acting-forces
      .map(force => (
        force.symbol,
        if force.magnitude == none { [—] } else {
          let force-magnitude = expression.value-of(force.magnitude)
          if force-magnitude == none {
            [—]
          } else {
            [#expression.format-number(force-magnitude)]
          }
        },
        force-component-cell(force, body.direction),
        force-component-cell(force, body.outward-normal),
      ))
      .flatten(),
    table.hline(),
  )
}

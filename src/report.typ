// Typesetting what the solver found.
//
// Every line is the same expression rendered at a different depth — symbolic,
// substituted, evaluated — so a report and a closed form can never disagree
// about the situation they describe.

#import "expression.typ"
#import "forces.typ"

#let newtons = $"N"$
#let metres-per-second-squared = $"m/s"^2$

#let _with-unit(value, unit) = if unit == none { value } else { $#value thin #unit$ }

// One equation, shown at as many depths as the terms allow: `N = m g cos θ`,
// then the substitution, then the number.
#let equation(symbol, term, unit: none, steps: false) = {
  let pieces = (symbol,)
  let plain = expression.is-number(term)
  if not plain { pieces.push(expression.math-of(term)) }
  if steps and not plain and expression.is-known(term) {
    pieces.push(expression.math-of(term, substitute: true))
  }
  let value = expression.numeric-math-of(term)
  if value != none { pieces.push(_with-unit(value, unit)) }
  $#pieces.join($=$)$
}

#let _available(solution) = {
  let value = expression.numeric-math-of(solution.available.expression)
  if value == none { $mu_s N$ } else { $mu_s N = #_with-unit(value, newtons)$ }
}

#let _verdict(solution) = {
  let name = solution.body
  if not solution.rough {
    if solution.regime == "static" {
      return [The contact is frictionless and nothing pulls *#name* along it — it is in equilibrium.]
    }
    return [The contact is frictionless, so nothing opposes the pull along it — *#name* slides.]
  }
  if solution.assumed {
    let stated = if solution.regime == "static" {
      [holds still]
    } else { [slides, so the friction below is $mu_k N$] }
    return [Taking it as given that *#name* #stated — the regime was assumed, not checked.]
  }
  if solution.regime == "static" {
    return [
      Required friction #equation($f_"req"$, solution.required.expression, unit: newtons) fits inside the available
      #_available(solution) — *#name* stays put.
    ]
  }
  [
    Required static friction #equation($f_"req"$, solution.required.expression, unit: newtons) exceeds the available
    #_available(solution) — *#name* slides. Solving with $mu_k$.
  ]
}

#let _heading(scene, solution) = {
  let surface = scene.surfaces.at(solution.surface)
  let inclination = if surface.kind == "ramp" {
    [ at #expression.format-angle(surface.inclination.deg())]
  } else { [] }
  [*#solution.body* on #emph(solution.surface)#inclination]
}

// Where the body goes, said the way the figure reads: a slope has an uphill
// and a downhill, level ground only has a left and a right.
#let _direction-words(scene, solution) = {
  let surface = scene.surfaces.at(solution.surface)
  if surface.kind == "ramp" {
    if solution.downhill { "down the incline" } else { "up the incline" }
  } else if solution.motion.at(0) >= 0 { "to the right" } else { "to the left" }
}

#let solution-report(scene, solution, steps: false) = {
  if solution.status == "undetermined" {
    return block[
      typed-physics cannot decide whether *#solution.body* slides, because #solution.reason. Give the coefficients and
      masses as numbers, or state the regime with `solve(assume: "static")` or `solve(assume: "sliding")`.
    ]
  }

  let direction = _direction-words(scene, solution)
  let lines = (
    _heading(scene, solution),
    equation($N$, solution.normal.expression, unit: newtons, steps: steps),
    _verdict(solution),
    if not solution.rough {
      none
    } else if solution.regime == "static" {
      equation($f_s$, solution.friction.expression, unit: newtons, steps: steps)
    } else {
      equation($f_k$, solution.friction.expression, unit: newtons, steps: steps)
    },
    if solution.regime == "static" {
      [$a = 0$ — the system is in equilibrium.]
    } else {
      [#equation($a$, solution.acceleration.expression, unit: metres-per-second-squared, steps: steps), #direction]
    },
  )
  block(stack(spacing: 0.65em, ..lines.filter(line => line != none)))
}

// Every force on a body with its components in the surface's own axes: the
// bookkeeping behind the free-body diagram, in the order the diagram draws it.
#let force-table(scene, name, solution: none) = {
  let body = scene.bodies.at(name)
  let acting = forces.enumerate-forces(scene, name, solution: solution)
  let cell(force, axis) = {
    if force.magnitude == none { return [—] }
    let value = expression.value-of(force.magnitude)
    if value == none { return [—] }
    let component = value * (force.direction.at(0) * axis.at(0) + force.direction.at(1) * axis.at(1))
    [#expression.format-number(component)]
  }
  table(
    columns: 4,
    align: (left, right, right, right),
    stroke: none,
    table.hline(),
    table.header([Force], [Magnitude (N)], [Along], [Out of surface]),
    table.hline(),
    ..acting
      .map(force => (
        force.symbol,
        if force.magnitude == none { [—] } else {
          let value = expression.value-of(force.magnitude)
          if value == none { [—] } else { [#expression.format-number(value)] }
        },
        cell(force, body.direction),
        cell(force, body.outward-normal),
      ))
      .flatten(),
    table.hline(),
  )
}

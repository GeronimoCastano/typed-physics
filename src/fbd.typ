// Free-body diagrams and component decompositions.
//
// Both views draw the same body the scene draws, in the same orientation, from
// the same enumeration of forces. The only thing they leave behind is the
// body's position in the world, which is exactly what a free-body diagram is
// for.

#import "@preview/cetz:0.5.2"
#import cetz.draw: anchor, content, group, line
#import "vector.typ"
#import "expression.typ"
#import "forces.typ"
#import "render.typ"

#let _at-origin(body) = body + (
  center: (0, 0),
  contact: vector.times(body.outward-normal, -body.size / 2),
)

// Arrows are drawn in proportion to the forces they stand for, so a free-body
// diagram reads as a comparison. That is only honest when every magnitude is
// known; as soon as one is symbolic, they all fall back to one length.
#let _arrow-lengths(acting, th) = {
  let values = acting.map(force => if force.magnitude == none { none } else { expression.value-of(force.magnitude) })
  let known = values.filter(value => value != none and value > 0)
  if known.len() != values.len() or known.len() == 0 {
    return values.map(_ => th.force-length)
  }
  let largest = calc.max(..known)
  values.map(value => calc.max(th.force-floor, th.force-length * value / largest))
}

// How far the body's own outline reaches in a given direction, so an arrow can
// start where the body ends instead of crossing whatever is drawn inside it.
#let _boundary-distance(body, direction) = {
  let along = calc.abs(vector.dot(direction, body.direction))
  let outward = calc.abs(vector.dot(direction, body.outward-normal))
  (body.size / 2) / calc.max(along, outward)
}

// The surface's axes, drawn shorter than the force arrows and labelled beside
// their own tips so an axis never collides with the force that follows it.
#let draw-axes(body, th, reach: 1.15) = {
  let stroke = th.construction-stroke
  let axes = (
    (body.direction, $x$, vector.reversed(body.outward-normal)),
    (body.outward-normal, $y$, body.direction),
  )
  for (direction, label, aside) in axes {
    let tip = vector.times(direction, reach)
    line(vector.times(direction, -reach * 0.45), tip, stroke: stroke)
    render.labelled(
      vector.stepped(vector.stepped(tip, direction, 0.12), aside, 0.36),
      text(fill: rgb("#868E96"), label),
      th.force-text,
    )
  }
}

#let draw-fbd(scene, name, th, solution: none, axes: auto, outline: true) = {
  let body = _at-origin(scene.bodies.at(name))
  let acting = forces.enumerate-forces(scene, name, solution: solution)
  assert(
    acting.len() > 0,
    message: "typed-physics: block \"" + name + "\" has no forces on it — give it a `mass:` or a surface to rest on",
  )
  let lengths = _arrow-lengths(acting, th)
  let show-axes = if axes == auto { body.inclination != 0deg } else { axes }

  group(
    name: name,
    {
      if show-axes { draw-axes(body, th) }
      if outline {
        line(..render.body-corners(body), close: true, fill: th.body-fill, stroke: th.body-stroke)
      }
      let inside = if body.label != auto { body.label } else { body.name }
      render.labelled((0, 0), inside, th.label-text)

      for (index, force) in acting.enumerate() {
        let colour = th.force-colors.at(force.role)
        let start = if outline { _boundary-distance(body, force.direction) } else { 0 }
        let tail = vector.times(force.direction, start)
        let tip = vector.times(force.direction, start + lengths.at(index))
        render.arrow(tail, tip, colour, th)
        render.labelled(
          vector.stepped(tip, force.direction, 0.3),
          text(fill: colour, force.symbol),
          th.force-text,
        )
        anchor(force.role, tip)
      }
      anchor("center", (0, 0))
      anchor("default", (0, 0))
    },
  )
}

// The weight resolved into the surface's own axes, with the construction lines
// and the right angle that make the two components readable as one rectangle.
#let draw-components(scene, name, th, of: "weight") = {
  assert(
    of == "weight",
    message: "typed-physics 0.1.0 resolves the weight into components; `of: \"" + of + "\"` is not available yet",
  )
  let body = _at-origin(scene.bodies.at(name))
  assert(
    body.mass != none,
    message: "typed-physics: block \"" + name + "\" needs a `mass:` before its weight can be resolved",
  )

  // Longer than a free-body arrow: the construction has to clear the body it
  // is drawn from before the two components can be labelled apart.
  let reach = th.force-length * 1.5
  let weight-vector = (0, -reach)
  let along = vector.times(body.direction, vector.dot(weight-vector, body.direction))
  let outward = vector.times(body.outward-normal, vector.dot(weight-vector, body.outward-normal))
  let weight = expression.product(body.mass, scene.gravity)
  let inclination = body.inclination-quantity

  group(
    name: name,
    {
      line(..render.body-corners(body), close: true, fill: th.body-fill, stroke: th.body-stroke)

      line(along, weight-vector, stroke: th.construction-stroke)
      line(outward, weight-vector, stroke: th.construction-stroke)

      let component-colour = th.force-colors.component
      render.arrow((0, 0), along, component-colour, th)
      render.arrow((0, 0), outward, component-colour, th)
      render.arrow((0, 0), weight-vector, th.force-colors.weight, th)

      // Each component is labelled just past its own tip and grows outward
      // from the construction, which is the only way all three labels fit.
      render.labelled(
        vector.stepped(along, vector.unit(along), 0.16),
        text(fill: component-colour, expression.math-of(expression.product(weight, expression.sine(inclination)))),
        th.force-text,
        side: "east",
      )
      render.labelled(
        vector.stepped(outward, vector.unit(outward), 0.16),
        text(fill: component-colour, expression.math-of(expression.product(weight, expression.cosine(inclination)))),
        th.force-text,
        side: "west",
      )
      render.labelled(
        vector.stepped(weight-vector, (0, -1), 0.18),
        text(fill: th.force-colors.weight, $W$),
        th.force-text,
        side: "north",
      )

      if body.inclination != 0deg {
        // Marked at the corner of the construction rectangle rather than at
        // the body, where the two components meet under the body's own fill.
        render.right-angle-mark(
          along,
          vector.reversed(vector.unit(along)),
          vector.unit(outward),
          th,
        )
        render.angle-mark(
          (0, 0),
          vector.unit(outward),
          (0, -1),
          inclination.symbol,
          th,
          radius: reach * 0.34,
        )
      }
      anchor("center", (0, 0))
      anchor("default", (0, 0))
    },
  )
}

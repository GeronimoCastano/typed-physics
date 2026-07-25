// Drawing a resolved situation.
//
// Everything here reads placed geometry and draws it; nothing here decides
// where anything is. That separation is what lets the scene, the free-body
// diagram, and the component decomposition all be pictures of the same
// declaration rather than three drawings that have to be kept in step.

#import "@preview/cetz:0.5.2"
#import cetz.draw: anchor, arc, circle, content, group, line
#import "vector.typ"
#import "expression.typ"
#import "forces.typ"

// Short strokes leaning back into whatever the surface is attached to: the
// conventional mark for "this does not move".
#let hatching(from, to, outward-normal, th) = {
  let span = vector.minus(to, from)
  let total = vector.length(span)
  if total == 0 { return }
  let direction = vector.unit(span)
  let lean = vector.unit(vector.plus(vector.reversed(outward-normal), vector.reversed(direction)))
  let count = calc.max(1, int(calc.round(total / th.hatch-spacing)))
  for index in range(count + 1) {
    let base = vector.stepped(from, direction, index * total / count)
    line(base, vector.stepped(base, lean, th.hatch-length), stroke: th.hatch-stroke)
  }
}

// `side` names which edge of the label sits at the position, so a wide label
// can be made to grow away from the figure instead of over it.
#let labelled(position, body, spec, side: "center") = content(
  position,
  text(..spec, body),
  anchor: side,
)

#let arrow(from, to, colour, th) = line(
  from,
  to,
  stroke: th.force-stroke + colour,
  mark: (end: "stealth", fill: colour, scale: 0.5),
)

#let angle-mark(corner, from-direction, to-direction, label, th, radius: auto) = {
  let size = if radius == auto { th.angle-radius } else { radius }
  let start = vector.angle-of(from-direction)
  let stop = vector.angle-of(to-direction)
  arc(corner, start: start, stop: stop, radius: size, anchor: "origin", stroke: th.angle-stroke)
  if label != none {
    labelled(vector.stepped(corner, vector.from-angle((start + stop) / 2), size * 1.4), label, th.angle-text)
  }
}

// A square corner drawn where two perpendicular directions meet.
#let right-angle-mark(corner, first, second, th) = {
  let a = vector.stepped(corner, first, th.right-angle-size)
  let b = vector.stepped(corner, second, th.right-angle-size)
  line(a, vector.plus(a, vector.minus(b, corner)), b, stroke: th.angle-stroke)
}

// ── Surfaces ─────────────────────────────────────────────────────────────────

#let draw-surface(surface, th) = group(
  name: surface.name,
  {
    if surface.kind == "ramp" {
      line(
        surface.foot,
        surface.apex,
        surface.base-corner,
        close: true,
        fill: th.surface-fill,
        stroke: th.surface-stroke,
      )
      hatching(surface.foot, surface.base-corner, (0, 1), th)
      anchor("foot", surface.foot)
      anchor("apex", surface.apex)
      anchor("base", vector.midpoint(surface.foot, surface.base-corner))
    } else {
      line(surface.start, surface.end, stroke: th.surface-stroke)
      hatching(surface.start, surface.end, surface.outward-normal, th)
    }
    anchor("start", surface.start)
    anchor("end", surface.end)
    anchor("surface", vector.midpoint(surface.start, surface.end))
    anchor("default", vector.midpoint(surface.start, surface.end))
  },
)

// ── Bodies ───────────────────────────────────────────────────────────────────

#let body-corners(body) = {
  let half = body.size / 2
  let along = vector.times(body.direction, half)
  let out = vector.times(body.outward-normal, half)
  (
    vector.minus(vector.minus(body.center, along), out),
    vector.minus(vector.plus(body.center, along), out),
    vector.plus(vector.plus(body.center, along), out),
    vector.plus(vector.minus(body.center, along), out),
  )
}

#let body-label(body, labels) = {
  if body.label != auto { return body.label }
  if labels == "name" or labels == "both" { return body.name }
  if labels == "mass" { return none }
  none
}

// The mass as the author declared it: a number becomes a quantity with a unit,
// a symbol stays the symbol they wrote.
#let mass-label(body) = {
  if body.mass == none { return none }
  if body.mass.value == none { return body.mass.symbol }
  let value = body.mass.value
  let shown = if value == calc.round(value) { str(int(value)) } else { expression.format-number(value) }
  $#shown "kg"$
}

#let draw-body(body, th, labels: "name") = {
  let corners = body-corners(body)
  group(
    name: body.name,
    {
      line(..corners, close: true, fill: th.body-fill, stroke: th.body-stroke)
      let inside = body-label(body, labels)
      if inside != none { labelled(body.center, inside, th.label-text) }
      if labels in ("mass", "both") {
        let mass = mass-label(body)
        if mass != none {
          labelled(
            vector.stepped(body.center, body.outward-normal, body.size * 0.5 + 0.32),
            mass,
            th.label-text,
          )
        }
      }
      anchor("center", body.center)
      anchor("contact", body.contact)
      anchor("uphill", vector.stepped(body.center, body.direction, body.size / 2))
      anchor("downhill", vector.stepped(body.center, vector.reversed(body.direction), body.size / 2))
      anchor("outward", vector.stepped(body.center, body.outward-normal, body.size / 2))
      anchor("default", body.center)
    },
  )
}

// ── Loads ────────────────────────────────────────────────────────────────────

// An applied load is drawn arriving at the face it acts on, so the arrow
// points the way the force does and ends where it is applied.
#let draw-load(body, load, symbol, th) = {
  let backwards = vector.reversed(load.direction)
  let tip = vector.stepped(body.center, backwards, body.size / 2)
  let tail = vector.stepped(tip, backwards, th.force-length)
  let colour = th.force-colors.applied
  arrow(tail, tip, colour, th)
  labelled(vector.stepped(tail, backwards, 0.3), text(fill: colour, symbol), th.force-text)
}

// ── Scene ────────────────────────────────────────────────────────────────────

#let angle-label(surface, mode) = {
  if mode == "none" { return none }
  let degrees = expression.format-angle(surface.inclination.deg())
  if mode == "value" { return $#degrees$ }
  if mode == "symbol" { return surface.inclination-quantity.symbol }
  $#surface.inclination-quantity.symbol = #degrees$
}

#let draw-scene(scene, th, labels: "name", angles: "value", loads: true) = {
  for name in scene.surface-order {
    let surface = scene.surfaces.at(name)
    draw-surface(surface, th)
    if surface.kind == "ramp" and angles != "none" {
      angle-mark(
        surface.foot,
        (1, 0),
        surface.direction,
        angle-label(surface, angles),
        th,
        radius: calc.min(th.angle-radius, surface.length * 0.22),
      )
    }
  }
  for name in scene.body-order {
    let body = scene.bodies.at(name)
    draw-body(body, th, labels: labels)
    if loads {
      let count = body.loads.len()
      for (index, load) in body.loads.enumerate() {
        draw-load(body, load, forces.load-symbol(load, index, count), th)
      }
    }
  }
}

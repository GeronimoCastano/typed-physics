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
#import "placement.typ"
#import "forces.typ" as force-enumeration
#import "style.typ": (
  resolve-body-style, resolve-connector-style, resolve-force-style,
  resolve-surface-style, resolve-velocity-style,
)

// Short strokes leaning back into whatever the surface is attached to: the
// conventional mark for "this does not move".
#let render-surface-hatching(
  start-position,
  end-position,
  outward-normal-direction,
  surface-style,
) = {
  let surface-span-vector = vector.subtract(end-position, start-position)
  let surface-span-length = vector.magnitude(surface-span-vector)
  if surface-span-length == 0 { return }

  let surface-direction = vector.normalized(surface-span-vector)
  let hatch-direction = vector.normalized(
    vector.add(
      vector.reversed(outward-normal-direction),
      vector.reversed(surface-direction),
    ),
  )
  let hatch-count = calc.max(
    1,
    int(calc.round(surface-span-length / surface-style.hatch-spacing)),
  )
  for hatch-index in range(hatch-count + 1) {
    let distance-along-surface = (
      hatch-index * surface-span-length / hatch-count
    )
    let hatch-base-position = vector.point-along(
      start-position,
      surface-direction,
      distance-along-surface,
    )
    let hatch-tip-position = vector.point-along(
      hatch-base-position,
      hatch-direction,
      surface-style.hatch-length,
    )
    let hatch-tip-distance-along-surface = vector.dot-product(
      vector.subtract(hatch-tip-position, start-position),
      surface-direction,
    )
    let hatch-tip-is-after-start = (
      hatch-tip-distance-along-surface >= -0.000001
    )
    let hatch-tip-is-before-end = (
      hatch-tip-distance-along-surface <= surface-span-length + 0.000001
    )
    let hatch-stays-inside-tangent-span = (
      hatch-tip-is-after-start and hatch-tip-is-before-end
    )
    if hatch-stays-inside-tangent-span {
      line(
        hatch-base-position,
        hatch-tip-position,
        stroke: surface-style.hatch-stroke,
      )
    }
  }
}

// A ramp is a sloped contact drawn over a horizontal foundation, so its
// immovable-support marks belong to the base of its triangle.
#let surface-hatch-span(surface, diagram-style) = {
  if surface.kind == "arc" { return none }
  let surface-style = resolve-surface-style(diagram-style, surface.style)
  let raw-start-position = if surface.kind == "ramp" {
    surface.foot
  } else {
    surface.start
  }
  let raw-end-position = if surface.kind == "ramp" {
    surface.base-corner
  } else {
    surface.end
  }
  let span-vector = vector.subtract(raw-end-position, raw-start-position)
  let is-horizontal-span = (
    calc.abs(span-vector.at(0)) >= calc.abs(span-vector.at(1))
  )
  let runs-in-positive-direction = if is-horizontal-span {
    raw-start-position.at(0) <= raw-end-position.at(0)
  } else {
    raw-start-position.at(1) <= raw-end-position.at(1)
  }
  (
    start: if runs-in-positive-direction {
      raw-start-position
    } else {
      raw-end-position
    },
    end: if runs-in-positive-direction {
      raw-end-position
    } else {
      raw-start-position
    },
    orientation: if is-horizontal-span { "horizontal" } else { "vertical" },
    outward-normal: if surface.kind == "ramp" {
      (0, 1)
    } else {
      surface.outward-normal
    },
    style: (
      hatch-stroke: surface-style.hatch-stroke,
      hatch-spacing: surface-style.hatch-spacing,
      hatch-length: surface-style.hatch-length,
    ),
  )
}

#let coordinate-along-hatch-span(hatch-span, position) = if (
  hatch-span.orientation == "horizontal"
) {
  position.at(0)
} else {
  position.at(1)
}

#let fixed-coordinate-of-hatch-span(hatch-span) = if (
  hatch-span.orientation == "horizontal"
) {
  hatch-span.start.at(1)
} else {
  hatch-span.start.at(0)
}

#let hatch-spans-can-merge(first-span, second-span) = {
  if first-span.orientation != second-span.orientation { return false }
  if first-span.outward-normal != second-span.outward-normal { return false }
  if first-span.style != second-span.style { return false }

  let coordinate-tolerance = 0.000001
  if calc.abs(
    fixed-coordinate-of-hatch-span(first-span)
      - fixed-coordinate-of-hatch-span(second-span),
  ) > coordinate-tolerance {
    return false
  }

  let first-start = coordinate-along-hatch-span(
    first-span,
    first-span.start,
  )
  let first-end = coordinate-along-hatch-span(first-span, first-span.end)
  let second-start = coordinate-along-hatch-span(
    second-span,
    second-span.start,
  )
  let second-end = coordinate-along-hatch-span(second-span, second-span.end)
  let first-span-reaches-second = (
    first-start <= second-end + coordinate-tolerance
  )
  let second-span-reaches-first = (
    second-start <= first-end + coordinate-tolerance
  )
  first-span-reaches-second and second-span-reaches-first
}

#let merge-hatch-spans(first-span, second-span) = (
  start: if coordinate-along-hatch-span(first-span, first-span.start)
    <= coordinate-along-hatch-span(second-span, second-span.start) {
    first-span.start
  } else {
    second-span.start
  },
  end: if coordinate-along-hatch-span(first-span, first-span.end)
    >= coordinate-along-hatch-span(second-span, second-span.end) {
    first-span.end
  } else {
    second-span.end
  },
  orientation: first-span.orientation,
  outward-normal: first-span.outward-normal,
  style: first-span.style,
)

// Collinear foundations with the same hatch style are one physical support,
// even when several declarations contribute overlapping or adjacent pieces.
#let unified-surface-hatch-spans(scene, diagram-style) = {
  let unified-spans = ()
  for surface-name in scene.surface-order {
    let combined-span = surface-hatch-span(
      scene.surfaces.at(surface-name),
      diagram-style,
    )
    if combined-span == none { continue }
    let found-overlapping-span = true
    while found-overlapping-span {
      found-overlapping-span = false
      let separate-spans = ()
      for existing-span in unified-spans {
        if hatch-spans-can-merge(combined-span, existing-span) {
          combined-span = merge-hatch-spans(combined-span, existing-span)
          found-overlapping-span = true
        } else {
          separate-spans.push(existing-span)
        }
      }
      unified-spans = separate-spans
    }
    unified-spans.push(combined-span)
  }
  unified-spans
}

#let render-unified-surface-hatching(scene, diagram-style) = {
  for hatch-span in unified-surface-hatch-spans(scene, diagram-style) {
    render-surface-hatching(
      hatch-span.start,
      hatch-span.end,
      hatch-span.outward-normal,
      hatch-span.style,
    )
  }
}

#let distance-from-point-to-segment(point, segment-start, segment-end) = {
  let segment-vector = vector.subtract(segment-end, segment-start)
  let squared-segment-length = vector.dot-product(
    segment-vector,
    segment-vector,
  )
  if squared-segment-length == 0 {
    return vector.magnitude(vector.subtract(point, segment-start))
  }
  let projected-ratio = vector.dot-product(
    vector.subtract(point, segment-start),
    segment-vector,
  ) / squared-segment-length
  let clamped-ratio = calc.max(0, calc.min(1, projected-ratio))
  let nearest-point = vector.point-along(
    segment-start,
    segment-vector,
    clamped-ratio,
  )
  vector.magnitude(vector.subtract(point, nearest-point))
}

// Straight foundations take visual priority where a curved support meets
// them. A curved hatch begins only when its whole length fits clear of every
// straight span, leaving one readable support pattern at the junction.
#let curved-hatch-has-clearance(
  hatch-base-position,
  curved-surface-style,
  straight-hatch-spans,
) = {
  let required-clearance = curved-surface-style.hatch-length + 0.025
  for straight-hatch-span in straight-hatch-spans {
    let distance-to-straight-span = distance-from-point-to-segment(
      hatch-base-position,
      straight-hatch-span.start,
      straight-hatch-span.end,
    )
    if distance-to-straight-span <= required-clearance {
      return false
    }
  }
  true
}

#let render-curved-surface-hatching(
  surface,
  surface-style,
  straight-hatch-spans,
) = {
  let hatch-count = calc.max(
    2,
    int(calc.round(surface.length / surface-style.hatch-spacing)),
  )
  for hatch-index in range(hatch-count + 1) {
    let position-ratio = hatch-index / hatch-count
    let position-angle = (
      surface.start-angle + surface.sweep-angle * position-ratio
    )
    let radial-direction = vector.direction-from-angle(position-angle)
    let outward-normal-direction = if surface.side == "outside" {
      radial-direction
    } else {
      vector.reversed(radial-direction)
    }
    let hatch-base-position = vector.point-along(
      surface.center,
      radial-direction,
      surface.radius,
    )
    let hatch-tip-position = vector.point-along(
      hatch-base-position,
      vector.reversed(outward-normal-direction),
      surface-style.hatch-length,
    )
    if curved-hatch-has-clearance(
      hatch-base-position,
      surface-style,
      straight-hatch-spans,
    ) {
      line(
        hatch-base-position,
        hatch-tip-position,
        stroke: surface-style.hatch-stroke,
      )
    }
  }
}

// `side` names which edge of the label sits at the position, so a wide label
// can be made to grow away from the figure instead of over it.
#let render-label(
  position,
  label-content,
  text-style,
  side: "center",
  offset: (0, 0),
  rotation: 0deg,
) = {
  let styled-label = text(..text-style, label-content)
  content(
    vector.add(position, offset),
    if rotation == 0deg {
      styled-label
    } else {
      rotate(rotation, reflow: false, styled-label)
    },
    anchor: side,
  )
}

#let render-force-arrow(
  tail-position,
  tip-position,
  force-color,
  force-stroke,
) = line(
  tail-position,
  tip-position,
  stroke: force-stroke + force-color,
  mark: (end: "stealth", fill: force-color, scale: 0.5),
)

#let stroke-thickness(stroke-value) = {
  if stroke-value == none { return 0pt }
  if type(stroke-value) == type(1pt) { return stroke-value }
  if type(stroke-value) == dictionary {
    return stroke-value.at("thickness", default: 1pt)
  }
  1pt
}

// A stroked outline extends half its thickness beyond its geometric path.
// CeTZ canvas coordinates use centimetres as world units.
#let stroke-outset(stroke-value) = (
  stroke-thickness(stroke-value) / 2 / 1cm
)

#let render-angle-marker(
  corner-position,
  start-direction,
  end-direction,
  label,
  diagram-style,
  radius: auto,
  label-side: "center",
  label-offset: (0, 0),
  label-rotation: 0deg,
) = {
  let marker-radius = if radius == auto {
    diagram-style.angle-radius
  } else {
    radius
  }
  let start-angle = vector.angle-of(start-direction)
  let end-angle = vector.angle-of(end-direction)
  arc(
    corner-position,
    start: start-angle,
    stop: end-angle,
    radius: marker-radius,
    anchor: "origin",
    stroke: diagram-style.angle-stroke,
  )
  if label != none {
    render-label(
      vector.point-along(
        corner-position,
        vector.direction-from-angle((start-angle + end-angle) / 2),
        marker-radius * 1.4,
      ),
      label,
      diagram-style.angle-text,
      side: label-side,
      offset: label-offset,
      rotation: label-rotation,
    )
  }
}

// A square corner drawn where two perpendicular directions meet.
#let render-right-angle-marker(
  corner-position,
  first-direction,
  second-direction,
  diagram-style,
) = {
  let first-marker-corner = vector.point-along(
    corner-position,
    first-direction,
    diagram-style.right-angle-size,
  )
  let second-marker-corner = vector.point-along(
    corner-position,
    second-direction,
    diagram-style.right-angle-size,
  )
  let outer-marker-corner = vector.add(
    first-marker-corner,
    vector.subtract(second-marker-corner, corner-position),
  )
  line(
    first-marker-corner,
    outer-marker-corner,
    second-marker-corner,
    stroke: diagram-style.angle-stroke,
  )
}

// ── Surfaces ─────────────────────────────────────────────────────────────────

#let render-surface(surface, diagram-style) = group(
  name: surface.name,
  {
    let surface-style = resolve-surface-style(diagram-style, surface.style)
    if surface.kind == "ramp" {
      line(
        surface.foot,
        surface.apex,
        surface.base-corner,
        close: true,
        fill: surface-style.fill,
        stroke: surface-style.stroke,
      )
      anchor("foot", surface.foot)
      anchor("apex", surface.apex)
      anchor("base", vector.midpoint(surface.foot, surface.base-corner))
    } else if surface.kind == "arc" {
      arc(
        surface.center,
        start: surface.start-angle,
        stop: surface.end-angle,
        radius: surface.radius,
        anchor: "origin",
        stroke: surface-style.stroke,
      )
      anchor("center", surface.center)
    } else {
      line(surface.start, surface.end, stroke: surface-style.stroke)
    }
    anchor("start", surface.start)
    anchor("end", surface.end)
    anchor("surface", surface.midpoint)
    anchor("default", surface.midpoint)
  },
)

// How long a surface is, written beside it on the side a body never occupies:
// under level ground, inside the triangle of a ramp. A drawn measurement would
// have to be inset at both ends to stay within the triangle, which makes it
// shorter than the length it claims to show.
#let length-label(surface) = {
  let surface-length = surface.length
  let displayed-length = if surface-length == calc.round(surface-length) {
    str(int(surface-length))
  } else {
    expression.format-number(surface-length)
  }
  $ell = #displayed-length$
}

#let render-surface-length(surface, diagram-style) = render-label(
  vector.point-along(
    surface.midpoint,
    vector.reversed(
      if surface.kind == "arc" {
        let midpoint-radial-direction = vector.normalized(
          vector.subtract(surface.midpoint, surface.center),
        )
        if surface.side == "outside" {
          midpoint-radial-direction
        } else {
          vector.reversed(midpoint-radial-direction)
        }
      } else {
        surface.outward-normal
      },
    ),
    diagram-style.length-label-offset,
  ),
  length-label(surface),
  diagram-style.angle-text,
)

// ── Bodies ───────────────────────────────────────────────────────────────────

#let body-corners(body) = {
  let half-tangent-span = vector.scale(body.direction, body.half-extent-along)
  let half-normal-span = vector.scale(
    body.outward-normal,
    body.half-extent-normal,
  )
  (
    vector.subtract(
      vector.subtract(body.center, half-tangent-span),
      half-normal-span,
    ),
    vector.subtract(
      vector.add(body.center, half-tangent-span),
      half-normal-span,
    ),
    vector.add(
      vector.add(body.center, half-tangent-span),
      half-normal-span,
    ),
    vector.add(
      vector.subtract(body.center, half-tangent-span),
      half-normal-span,
    ),
  )
}

// How far a body's own outline reaches in a direction, so an arrow can start
// where the body ends instead of crossing whatever is drawn inside it. A round
// body reaches its radius whichever way you look.
#let body-boundary-distance(body, direction) = {
  if body.shape != "block" { return body.half-extent-along }
  let tangent-reach = (
    calc.abs(vector.dot-product(direction, body.direction))
      / body.half-extent-along
  )
  let normal-reach = (
    calc.abs(vector.dot-product(direction, body.outward-normal))
      / body.half-extent-normal
  )
  1 / calc.max(tangent-reach, normal-reach)
}

#let body-visible-boundary-distance(
  body,
  direction,
  body-stroke,
) = {
  let outline-outset = if body.shape == "point" {
    0
  } else {
    stroke-outset(body-stroke)
  }
  if body.shape != "block" {
    return body.half-extent-along + outline-outset
  }
  let visible-half-tangent-span = body.half-extent-along + outline-outset
  let visible-half-normal-span = body.half-extent-normal + outline-outset
  let tangent-reach = (
    calc.abs(vector.dot-product(direction, body.direction))
      / visible-half-tangent-span
  )
  let normal-reach = (
    calc.abs(vector.dot-product(direction, body.outward-normal))
      / visible-half-normal-span
  )
  1 / calc.max(tangent-reach, normal-reach)
}

// The highest point of a body in the world, which is what a label above it has
// to clear: a tilted square reaches up on a corner.
#let body-top-height(body) = if body.shape == "block" {
  calc.max(..body-corners(body).map(corner => corner.at(1)))
} else {
  body.center.at(1) + body.half-extent-normal
}

#let body-radius-mark-direction(body) = vector.direction-from-angle(
  body.inclination + body.orientation,
)

#let body-radius-mark-label-direction(body) = {
  let direction-away-from-mark = vector.reversed(
    body-radius-mark-direction(body),
  )
  let horizontal-component = direction-away-from-mark.at(0)
  let vertical-component = direction-away-from-mark.at(1)
  if calc.abs(horizontal-component) >= calc.abs(vertical-component) {
    (if horizontal-component < 0 { -1 } else { 1 }, 0)
  } else {
    (0, if vertical-component < 0 { -1 } else { 1 })
  }
}

#let render-body-outline(body, body-style) = {
  if body.shape == "block" {
    line(
      ..body-corners(body),
      close: true,
      fill: body-style.fill,
      stroke: body-style.stroke,
    )
  } else if body.shape in ("ball", "disk", "ring") {
    circle(
      body.center,
      radius: body.half-extent-along,
      fill: body-style.fill,
      stroke: body-style.stroke,
    )
    if body.shape == "ring" {
      circle(
        body.center,
        radius: body.half-extent-along * 0.62,
        fill: white,
        stroke: body-style.stroke,
      )
    }
    if body.shape in ("disk", "ring") and body.radius-mark {
      let radial-mark-direction = body-radius-mark-direction(body)
      line(
        body.center,
        vector.point-along(
          body.center,
          radial-mark-direction,
          body.half-extent-along,
        ),
        stroke: body-style.stroke,
      )
      circle(
        body.center,
        radius: body.half-extent-along * 0.08,
        fill: body-style.stroke.paint,
        stroke: none,
      )
    }
  } else {
    circle(
      body.center,
      radius: body.half-extent-along,
      fill: body-style.point-mass-fill,
      stroke: none,
    )
  }
}

#let body-label(body, labels) = {
  if body.label != auto { return body.label }
  if labels == "name" or labels == "both" { return body.name }
  if labels == "mass" { return none }
  none
}

// The mass as the author declared it: a number is named by the symbol the rest
// of the package prints for it, a symbol alone stands on its own.
#let mass-label(body) = {
  if body.mass == none { return none }
  if body.mass.value == none { return body.mass.symbol }
  let mass-value = body.mass.value
  let displayed-mass = if mass-value == calc.round(mass-value) {
    str(int(mass-value))
  } else {
    expression.format-number(mass-value)
  }
  $#body.mass.symbol = #displayed-mass "kg"$
}

#let mass-symbol-label(body) = if body.mass == none {
  none
} else {
  body.mass.symbol
}

// A rough contact names both coefficients, or one when they are equal.
#let friction-label(friction-coefficients) = {
  if friction-coefficients == none { return none }
  let static-coefficient = friction-coefficients.static
  let kinetic-coefficient = friction-coefficients.kinetic
  let printed-coefficient(coefficient) = expression.math-of(
    coefficient,
    substitute: true,
  )
  let coefficients-are-the-same = (
    static-coefficient.value != none
      and static-coefficient.value == kinetic-coefficient.value
  )
  if coefficients-are-the-same {
    return $mu = #printed-coefficient(static-coefficient)$
  }
  $mu_s = #printed-coefficient(static-coefficient),
    mu_k = #printed-coefficient(kinetic-coefficient)$
}

#let render-body(
  body,
  diagram-style,
  label-annotation: (
    mode: "name",
    is-visible: true,
    offset: (0, 0),
    rotation: 0deg,
  ),
) = {
  let body-style = resolve-body-style(diagram-style, body.style)
  let half-along = body.half-extent-along
  let half-normal = body.half-extent-normal
  group(
    name: body.name,
    {
      render-body-outline(body, body-style)
      let inside-body-label = body-label(body, label-annotation.mode)
      if label-annotation.is-visible and inside-body-label != none {
        // A point has no inside to write in, so its name sits beside the dot.
        let body-is-a-point = body.shape == "point"
        let body-has-radius-mark = (
          body.shape in ("disk", "ring") and body.radius-mark
        )
        let automatic-label-position = if body-is-a-point {
          vector.point-along(body.center, (1, 0), half-along + 0.16)
        } else if body-has-radius-mark {
          vector.point-along(
            body.center,
            body-radius-mark-label-direction(body),
            half-along * 0.42,
          )
        } else {
          body.center
        }
        render-label(
          automatic-label-position,
          inside-body-label,
          body-style.label-text,
          side: if body-is-a-point { "west" } else { "center" },
          offset: label-annotation.offset,
          rotation: label-annotation.rotation,
        )
      }
      let should-render-mass-label = (
        label-annotation.is-visible
          and label-annotation.mode in ("symbol", "mass", "both")
      )
      if should-render-mass-label {
        let displayed-mass = if label-annotation.mode == "symbol" {
          mass-symbol-label(body)
        } else {
          mass-label(body)
        }
        if displayed-mass != none {
          render-label(
            (body.center.at(0), body-top-height(body) + 0.3),
            displayed-mass,
            body-style.label-text,
            offset: label-annotation.offset,
            rotation: label-annotation.rotation,
          )
        }
      }
      anchor("center", body.center)
      anchor("contact", body.contact)
      anchor(
        "uphill",
        vector.point-along(body.center, body.direction, half-along),
      )
      anchor(
        "downhill",
        vector.point-along(
          body.center,
          vector.reversed(body.direction),
          half-along,
        ),
      )
      anchor(
        "outward",
        vector.point-along(body.center, body.outward-normal, half-normal),
      )
      anchor("top", (body.center.at(0), body.center.at(1) + half-normal))
      anchor("bottom", (body.center.at(0), body.center.at(1) - half-normal))
      anchor("left", (body.center.at(0) - half-along, body.center.at(1)))
      anchor("right", (body.center.at(0) + half-along, body.center.at(1)))
      anchor("default", body.center)
    },
  )
}

// ── Rigid structures and constraints ─────────────────────────────────────────

#let rod-corners(placed-rod) = {
  let half-normal-span = vector.scale(
    placed-rod.outward-normal,
    placed-rod.thickness / 2,
  )
  (
    vector.subtract(placed-rod.start, half-normal-span),
    vector.subtract(placed-rod.end, half-normal-span),
    vector.add(placed-rod.end, half-normal-span),
    vector.add(placed-rod.start, half-normal-span),
  )
}

#let rod-boundary-distance-from(
  placed-rod,
  application-position,
  direction-away-from-rod,
  rod-stroke,
) = {
  let position-from-center = vector.subtract(
    application-position,
    placed-rod.center,
  )
  let position-along-rod = vector.dot-product(
    position-from-center,
    placed-rod.direction,
  )
  let direction-along-rod = vector.dot-product(
    direction-away-from-rod,
    placed-rod.direction,
  )
  let direction-normal-to-rod = vector.dot-product(
    direction-away-from-rod,
    placed-rod.outward-normal,
  )
  let outline-outset = stroke-outset(rod-stroke)
  let half-rod-length = placed-rod.length / 2 + outline-outset
  let half-rod-thickness = placed-rod.thickness / 2 + outline-outset
  let boundary-distances = ()

  if calc.abs(direction-along-rod) > 0.000001 {
    let signed-end-position = if direction-along-rod > 0 {
      half-rod-length
    } else {
      -half-rod-length
    }
    boundary-distances.push(
      (signed-end-position - position-along-rod) / direction-along-rod,
    )
  }
  if calc.abs(direction-normal-to-rod) > 0.000001 {
    let signed-face-position = if direction-normal-to-rod > 0 {
      half-rod-thickness
    } else {
      -half-rod-thickness
    }
    boundary-distances.push(
      signed-face-position / direction-normal-to-rod,
    )
  }

  calc.min(..boundary-distances.filter(distance => distance >= 0))
}

#let render-rod(placed-rod, diagram-style, label-annotation) = {
  let rod-style = resolve-body-style(diagram-style, placed-rod.style)
  group(
    name: placed-rod.name,
    {
      line(
        ..rod-corners(placed-rod),
        close: true,
        fill: rod-style.fill,
        stroke: rod-style.stroke,
      )
      let inside-rod-label = body-label(placed-rod, label-annotation.mode)
      if label-annotation.is-visible and inside-rod-label != none {
        render-label(
          vector.point-along(
            placed-rod.center,
            placed-rod.outward-normal,
            placed-rod.thickness / 2 + 0.18,
          ),
          inside-rod-label,
          rod-style.label-text,
          offset: label-annotation.offset,
          rotation: label-annotation.rotation,
        )
      }
      let should-render-mass-label = (
        label-annotation.is-visible
          and label-annotation.mode in ("symbol", "mass", "both")
      )
      if should-render-mass-label {
        let displayed-mass = if label-annotation.mode == "symbol" {
          mass-symbol-label(placed-rod)
        } else {
          mass-label(placed-rod)
        }
        if displayed-mass != none {
          render-label(
            vector.point-along(
              placed-rod.center-of-mass,
              vector.reversed(placed-rod.outward-normal),
              placed-rod.thickness / 2 + 0.22,
            ),
            displayed-mass,
            rod-style.label-text,
            offset: label-annotation.offset,
            rotation: label-annotation.rotation,
          )
        }
      }
      anchor("start", placed-rod.start)
      anchor("end", placed-rod.end)
      anchor("center", placed-rod.center)
      anchor("center-of-mass", placed-rod.center-of-mass)
      anchor("default", placed-rod.center)
    },
  )
}

#let render-pivot(placed-pivot, diagram-style) = {
  let pivot-style = resolve-connector-style(
    diagram-style,
    placed-pivot.style,
    "pivot",
  )
  circle(
    placed-pivot.center,
    radius: placed-pivot.radius,
    fill: white,
    stroke: pivot-style.stroke,
  )
  circle(
    placed-pivot.center,
    radius: placed-pivot.radius * 0.28,
    fill: pivot-style.stroke.paint,
    stroke: none,
  )
}

#let render-support(placed-support, diagram-style) = {
  let support-style = resolve-connector-style(
    diagram-style,
    placed-support.style,
    "support",
  )
  let support-tangent = vector.direction-from-angle(placed-support.angle)
  let support-normal = vector.left-normal(support-tangent)
  let support-size = placed-support.size
  if placed-support.support-kind == "fixed" {
    let wall-start = vector.point-along(
      placed-support.center,
      vector.reversed(support-tangent),
      support-size / 2,
    )
    let wall-end = vector.point-along(
      placed-support.center,
      support-tangent,
      support-size / 2,
    )
    line(wall-start, wall-end, stroke: support-style.stroke)
    render-surface-hatching(
      wall-start,
      wall-end,
      support-normal,
      (
        hatch-stroke: support-style.stroke,
        hatch-spacing: support-size / 4,
        hatch-length: support-size * 0.28,
      ),
    )
    return
  }

  let support-contact = placed-support.contact
  let base-center = vector.point-along(
    support-contact,
    vector.reversed(support-normal),
    support-size * 0.72,
  )
  let base-start = vector.point-along(
    base-center,
    vector.reversed(support-tangent),
    support-size / 2,
  )
  let base-end = vector.point-along(
    base-center,
    support-tangent,
    support-size / 2,
  )
  line(
    support-contact,
    base-start,
    base-end,
    close: true,
    fill: support-style.fill,
    stroke: support-style.stroke,
  )
  if placed-support.support-kind == "roller" {
    let roller-radius = support-size * 0.11
    let roller-center-offset = support-size * 0.18
    for signed-offset in (-1, 1) {
      circle(
        vector.point-along(
          vector.point-along(
            base-center,
            support-tangent,
            signed-offset * support-size * 0.28,
          ),
          vector.reversed(support-normal),
          roller-center-offset,
        ),
        radius: roller-radius,
        fill: white,
        stroke: support-style.stroke,
      )
    }
    let foundation-center = vector.point-along(
      base-center,
      vector.reversed(support-normal),
      roller-center-offset + roller-radius,
    )
    line(
      vector.point-along(
        foundation-center,
        vector.reversed(support-tangent),
        support-size * 0.65,
      ),
      vector.point-along(
        foundation-center,
        support-tangent,
        support-size * 0.65,
      ),
      stroke: support-style.stroke,
    )
  }
}

#let render-pendulum(placed-pendulum, diagram-style, label-annotation) = {
  let pendulum-style = resolve-body-style(
    diagram-style,
    placed-pendulum.style,
  )
  let connector-style = resolve-connector-style(diagram-style, (:), "rope")
  group(
    name: placed-pendulum.name,
    {
      if placed-pendulum.angle != 0deg {
        line(
          placed-pendulum.pivot,
          vector.point-along(
            placed-pendulum.pivot,
            (0, -1),
            placed-pendulum.length * 0.46,
          ),
          stroke: diagram-style.construction-stroke,
        )
        let pendulum-angle-label = if placed-pendulum.angle-label == none {
          none
        } else if placed-pendulum.angle-label == auto {
          $theta$
        } else {
          placed-pendulum.angle-label
        }
        render-angle-marker(
          placed-pendulum.pivot,
          (0, -1),
          placed-pendulum.direction,
          pendulum-angle-label,
          diagram-style,
          radius: calc.min(
            diagram-style.angle-radius,
            placed-pendulum.length * 0.28,
          ),
        )
      }
      line(
        placed-pendulum.pivot,
        placed-pendulum.bob,
        stroke: connector-style.stroke,
      )
      circle(
        placed-pendulum.pivot,
        radius: placed-pendulum.radius * 0.16,
        fill: diagram-style.body-stroke.paint,
        stroke: none,
      )
      circle(
        placed-pendulum.bob,
        radius: placed-pendulum.radius,
        fill: pendulum-style.fill,
        stroke: pendulum-style.stroke,
      )
      let bob-label = body-label(placed-pendulum, label-annotation.mode)
      if label-annotation.is-visible and bob-label != none {
        render-label(
          placed-pendulum.bob,
          bob-label,
          pendulum-style.label-text,
          offset: label-annotation.offset,
          rotation: label-annotation.rotation,
        )
      }
      let should-render-mass-label = (
        label-annotation.is-visible
          and label-annotation.mode in ("symbol", "mass", "both")
      )
      if should-render-mass-label {
        let displayed-mass = if label-annotation.mode == "symbol" {
          mass-symbol-label(placed-pendulum)
        } else {
          mass-label(placed-pendulum)
        }
        if displayed-mass != none {
          render-label(
            vector.point-along(
              placed-pendulum.bob,
              if placed-pendulum.angle >= 0deg { (1, 0) } else { (-1, 0) },
              placed-pendulum.radius + 0.22,
            ),
            displayed-mass,
            pendulum-style.label-text,
            side: if placed-pendulum.angle >= 0deg { "west" } else { "east" },
            offset: label-annotation.offset,
            rotation: label-annotation.rotation,
          )
        }
      }
      anchor("pivot", placed-pendulum.pivot)
      anchor("bob", placed-pendulum.bob)
      anchor("center", placed-pendulum.bob)
      anchor("default", placed-pendulum.bob)
    },
  )
}

// ── Connectors ───────────────────────────────────────────────────────────────

#let render-pulley(placed-pulley, diagram-style) = {
  let wheel-style = resolve-connector-style(
    diagram-style,
    placed-pulley.style,
    "pulley",
  )
  let wheel-centre = placed-pulley.center
  let wheel-radius = placed-pulley.radius
  group(
    name: placed-pulley.name,
    {
      circle(
        wheel-centre,
        radius: wheel-radius,
        fill: wheel-style.fill,
        stroke: diagram-style.pulley-stroke,
      )
      circle(
        wheel-centre,
        radius: wheel-radius * 0.16,
        fill: diagram-style.pulley-stroke.paint,
        stroke: none,
      )
      anchor("center", wheel-centre)
      anchor("top", (wheel-centre.at(0), wheel-centre.at(1) + wheel-radius))
      anchor("bottom", (wheel-centre.at(0), wheel-centre.at(1) - wheel-radius))
      anchor("left", (wheel-centre.at(0) - wheel-radius, wheel-centre.at(1)))
      anchor("right", (wheel-centre.at(0) + wheel-radius, wheel-centre.at(1)))
      anchor("default", wheel-centre)
    },
  )
}

// The zigzag of a spring: a straight lead at each end so the attachment reads
// clearly, and an even coil between them.
#let spring-path(start-position, end-position, coil-count, coil-width) = {
  let spring-axis = vector.subtract(end-position, start-position)
  let spring-length = vector.magnitude(spring-axis)
  if spring-length == 0 { return (start-position, end-position) }

  let axis-direction = vector.normalized(spring-axis)
  let coil-offset-direction = vector.left-normal(axis-direction)
  let lead-length = spring-length * 0.18
  let coiled-length = spring-length - 2 * lead-length
  let coil-start = vector.point-along(
    start-position,
    axis-direction,
    lead-length,
  )
  let zigzag-count = 2 * coil-count
  let path-points = (start-position, coil-start)
  for zigzag-index in range(1, zigzag-count) {
    path-points.push(
      vector.point-along(
        vector.point-along(
          coil-start,
          axis-direction,
          coiled-length * zigzag-index / zigzag-count,
        ),
        coil-offset-direction,
        (if calc.rem(zigzag-index, 2) == 1 { 1 } else { -1 })
          * coil-width
          / 2,
      ),
    )
  }
  path-points.push(
    vector.point-along(coil-start, axis-direction, coiled-length),
  )
  path-points.push(end-position)
  path-points
}

// A rope that runs over a pulley leaves each end at a tangent and wraps the
// side of the wheel its two ends do not face.
#let _render-rope-over-pulley(
  placed-connector,
  placed-pulley,
  connector-stroke,
) = {
  line(
    placed-connector.start,
    placed-connector.start-tangent,
    stroke: connector-stroke,
  )
  line(
    placed-connector.end-tangent,
    placed-connector.end,
    stroke: connector-stroke,
  )
  let angle-at(position) = vector.angle-of(
    vector.subtract(position, placed-pulley.center),
  )
  let start-angle = angle-at(placed-connector.start-tangent)
  let end-angle = angle-at(placed-connector.end-tangent)
  let direction-the-ends-face = vector.normalized(
    vector.add(
      vector.normalized(
        vector.subtract(placed-connector.start, placed-pulley.center),
      ),
      vector.normalized(
        vector.subtract(placed-connector.end, placed-pulley.center),
      ),
    ),
  )
  let shorter-arc-faces-the-ends = (
    vector.dot-product(
      vector.direction-from-angle((start-angle + end-angle) / 2),
      direction-the-ends-face,
    )
      > 0
  )
  arc(
    placed-pulley.center,
    start: start-angle,
    stop: if not shorter-arc-faces-the-ends {
      end-angle
    } else if end-angle > start-angle {
      end-angle - 360deg
    } else { end-angle + 360deg },
    radius: placed-pulley.radius,
    anchor: "origin",
    stroke: connector-stroke,
  )
}

#let render-connector(placed-connector, scene, diagram-style) = {
  let connector-style = resolve-connector-style(
    diagram-style,
    placed-connector.style,
    placed-connector.kind,
  )
  group(
    name: placed-connector.name,
    {
      if placed-connector.kind == "spring" {
        line(
          ..spring-path(
            placed-connector.start,
            placed-connector.end,
            placed-connector.coils,
            placed-connector.width,
          ),
          stroke: connector-style.stroke,
        )
      } else if placed-connector.over == none {
        line(
          placed-connector.start,
          placed-connector.end,
          stroke: connector-style.stroke,
        )
      } else {
        _render-rope-over-pulley(
          placed-connector,
          scene.pulleys.at(placed-connector.over),
          connector-style.stroke,
        )
      }
      anchor("start", placed-connector.start)
      anchor("end", placed-connector.end)
      anchor(
        "default",
        vector.midpoint(placed-connector.start, placed-connector.end),
      )
    },
  )
}

// ── Loads and motion ─────────────────────────────────────────────────────────

// An applied load is drawn arriving at the face it acts on, so the arrow
// points the way the force does and ends where it is applied.
#let render-applied-load(
  body,
  applied-load,
  force-symbol,
  diagram-style,
) = {
  let load-style = resolve-force-style(
    diagram-style,
    applied-load.style,
    "applied",
  )
  let body-style = resolve-body-style(diagram-style, body.style)
  let direction-away-from-body = vector.reversed(applied-load.direction)
  let arrow-tip-position = vector.point-along(
    body.center,
    direction-away-from-body,
    body-visible-boundary-distance(
      body,
      direction-away-from-body,
      body-style.stroke,
    ),
  )
  let arrow-tail-position = vector.point-along(
    arrow-tip-position,
    direction-away-from-body,
    load-style.length,
  )
  render-force-arrow(
    arrow-tail-position,
    arrow-tip-position,
    load-style.color,
    load-style.stroke,
  )
  render-label(
    vector.point-along(arrow-tail-position, direction-away-from-body, 0.3),
    text(fill: load-style.color, force-symbol),
    load-style.text,
  )
}

#let render-applied-load-on-rod(
  placed-rod,
  applied-load,
  force-symbol,
  diagram-style,
) = {
  let load-style = resolve-force-style(
    diagram-style,
    applied-load.style,
    "applied",
  )
  let rod-style = resolve-body-style(diagram-style, placed-rod.style)
  let direction-away-from-rod = vector.reversed(applied-load.direction)
  let distance-to-visible-rod-border = rod-boundary-distance-from(
    placed-rod,
    applied-load.application-position,
    direction-away-from-rod,
    rod-style.stroke,
  )
  let arrow-tip-position = vector.point-along(
    applied-load.application-position,
    direction-away-from-rod,
    distance-to-visible-rod-border,
  )
  let arrow-tail-position = vector.point-along(
    arrow-tip-position,
    direction-away-from-rod,
    load-style.length,
  )
  render-force-arrow(
    arrow-tail-position,
    arrow-tip-position,
    load-style.color,
    load-style.stroke,
  )
  render-label(
    vector.point-along(
      arrow-tail-position,
      vector.reversed(applied-load.direction),
      0.26,
    ),
    text(fill: load-style.color, force-symbol),
    load-style.text,
  )
}

#let render-torque(placed-torque, diagram-style) = {
  let torque-style = resolve-force-style(
    diagram-style,
    placed-torque.style,
    "applied",
  )
  let turns-counterclockwise = (
    placed-torque.direction == "counterclockwise"
  )
  let start-angle = if turns-counterclockwise { -55deg } else { 235deg }
  let stop-angle = if turns-counterclockwise { 235deg } else { -55deg }
  arc(
    placed-torque.center,
    start: start-angle,
    stop: stop-angle,
    radius: placed-torque.radius,
    anchor: "origin",
    stroke: torque-style.stroke + torque-style.color,
    mark: (
      end: "stealth",
      fill: torque-style.color,
      scale: 0.5,
    ),
  )
  let torque-label = if placed-torque.label != auto {
    placed-torque.label
  } else {
    $tau$
  }
  render-label(
    vector.point-along(
      placed-torque.center,
      (0, 1),
      placed-torque.radius + 0.24,
    ),
    text(fill: torque-style.color, torque-label),
    torque-style.text,
  )
}

// A velocity leaves the body it belongs to, pointing the way it moves. It is
// drawn in its own colour because it is not a force and never belongs in a
// free-body diagram.
#let render-velocity(body, body-velocity, velocity-index, diagram-style) = {
  let motion-style = resolve-velocity-style(diagram-style, body-velocity.style)
  let body-style = resolve-body-style(diagram-style, body.style)
  let visible-boundary-distance = body-visible-boundary-distance(
    body,
    body-velocity.direction,
    body-style.stroke,
  )
  let arrow-tail-position = body.center
  let arrow-tip-position = vector.point-along(
    body.center,
    body-velocity.direction,
    visible-boundary-distance + motion-style.length,
  )
  render-force-arrow(
    arrow-tail-position,
    arrow-tip-position,
    motion-style.color,
    motion-style.stroke,
  )
  let velocity-symbol = if body-velocity.label != auto {
    body-velocity.label
  } else if velocity-index == 0 { $v$ } else { $v_#(velocity-index + 1)$ }
  render-label(
    vector.point-along(arrow-tip-position, body-velocity.direction, 0.28),
    text(fill: motion-style.color, velocity-symbol),
    motion-style.text,
  )
}

#let render-angular-velocity(
  body,
  body-angular-velocity,
  angular-velocity-index,
  diagram-style,
) = {
  let motion-style = resolve-velocity-style(
    diagram-style,
    body-angular-velocity.style,
  )
  arc(
    body.center,
    start: body-angular-velocity.start-angle,
    stop: body-angular-velocity.end-angle,
    radius: body-angular-velocity.radius,
    anchor: "origin",
    stroke: motion-style.stroke + motion-style.color,
    mark: (
      end: "stealth",
      fill: motion-style.color,
      scale: 0.5,
    ),
  )
  let angular-velocity-symbol = if body-angular-velocity.label != auto {
    body-angular-velocity.label
  } else if angular-velocity-index == 0 {
    $omega$
  } else {
    $omega_#(angular-velocity-index + 1)$
  }
  let label-angle = (
    body-angular-velocity.start-angle
      + body-angular-velocity.end-angle
  ) / 2
  render-label(
    vector.point-along(
      body.center,
      vector.direction-from-angle(label-angle),
      body-angular-velocity.radius + 0.24,
    ),
    text(fill: motion-style.color, angular-velocity-symbol),
    motion-style.text,
  )
}

// ── Scene-only annotations ───────────────────────────────────────────────────

#let _dimension-endpoint(scene, endpoint-reference) = {
  let endpoint-is-raw-coordinate = (
    type(endpoint-reference) == array
      and endpoint-reference.len() == 2
      and endpoint-reference.all(
        coordinate => type(coordinate) in (int, float),
      )
  )
  if endpoint-is-raw-coordinate { return endpoint-reference }

  if type(endpoint-reference) == dictionary {
    let connector-name = endpoint-reference.at("on", default: none)
    if scene.connectors.any(connector => connector.name == connector-name) {
      panic(
        "typed-physics: dimension() cannot use an (on:, at:) ratio along connector \""
          + connector-name
          + "\"; use \""
          + connector-name
          + ".start\", \".center\", or \".end\"",
      )
    }
  }

  if type(endpoint-reference) == str {
    let reference-parts = endpoint-reference.split(".")
    assert(
      reference-parts.len() <= 2,
      message: "typed-physics: dimension() endpoint \"" + endpoint-reference + "\" must name one anchor",
    )
    let element-name = reference-parts.first()
    let connector = scene.connectors.find(
      placed-connector => placed-connector.name == element-name,
    )
    if connector != none {
      let anchor-name = if reference-parts.len() == 2 {
        reference-parts.at(1)
      } else {
        "center"
      }
      assert(
        anchor-name in ("start", "end", "center"),
        message: "typed-physics: connector \"" + element-name + "\" has start, end, and center anchors",
      )
      return if anchor-name == "start" {
        connector.start
      } else if anchor-name == "end" {
        connector.end
      } else {
        vector.midpoint(connector.start, connector.end)
      }
    }
  }

  placement.resolve-attachment-point(
    endpoint-reference,
    scene.surfaces,
    scene.bodies,
    scene.pulleys,
    "dimension()",
    placed-structures: scene.structures,
  )
}

#let _dimension-arrow-marks(dimension-annotation, dimension-color) = (
  start: if dimension-annotation.arrows in ("both", "start") {
    dimension-annotation.arrow-tip
  } else {
    none
  },
  end: if dimension-annotation.arrows in ("both", "end") {
    dimension-annotation.arrow-tip
  } else {
    none
  },
  fill: dimension-color,
  stroke: dimension-color,
  scale: dimension-annotation.arrow-scale,
)

#let _projection-segment-intersection-distance(
  projection-start,
  projection-direction,
  projection-length,
  segment-start,
  segment-end,
) = {
  let segment-vector = vector.subtract(segment-end, segment-start)
  let start-to-segment = vector.subtract(segment-start, projection-start)
  let direction-cross-segment = vector.cross-product(
    projection-direction,
    segment-vector,
  )
  if calc.abs(direction-cross-segment) > 0.000001 {
    let distance-along-projection = (
      vector.cross-product(start-to-segment, segment-vector)
        / direction-cross-segment
    )
    let ratio-along-segment = (
      vector.cross-product(start-to-segment, projection-direction)
        / direction-cross-segment
    )
    if (
      distance-along-projection >= 0
        and distance-along-projection <= projection-length
        and ratio-along-segment >= 0
        and ratio-along-segment <= 1
    ) {
      return distance-along-projection
    }
    return none
  }

  let segments-are-collinear = calc.abs(
    vector.cross-product(start-to-segment, projection-direction),
  ) <= 0.000001
  if not segments-are-collinear { return none }
  let first-end-distance = vector.dot-product(
    start-to-segment,
    projection-direction,
  )
  let second-end-distance = vector.dot-product(
    vector.subtract(segment-end, projection-start),
    projection-direction,
  )
  let overlap-start = calc.max(
    0,
    calc.min(first-end-distance, second-end-distance),
  )
  let overlap-end = calc.min(
    projection-length,
    calc.max(first-end-distance, second-end-distance),
  )
  if overlap-start <= overlap-end { overlap-start } else { none }
}

#let _projection-circle-intersection-distance(
  projection-start,
  projection-direction,
  projection-length,
  circle-center,
  circle-radius,
) = {
  let center-to-start = vector.subtract(projection-start, circle-center)
  let signed-center-distance = vector.dot-product(
    center-to-start,
    projection-direction,
  )
  let discriminant = (
    signed-center-distance * signed-center-distance
      - (
        vector.dot-product(center-to-start, center-to-start)
          - circle-radius * circle-radius
      )
  )
  if discriminant < 0 { return none }
  let root = calc.sqrt(discriminant)
  let entry-distance = -signed-center-distance - root
  let exit-distance = -signed-center-distance + root
  if entry-distance >= 0 and entry-distance <= projection-length {
    entry-distance
  } else if exit-distance >= 0 and exit-distance <= projection-length {
    exit-distance
  } else {
    none
  }
}

#let _projection-polygon-intersection-distances(
  projection-start,
  projection-direction,
  projection-length,
  polygon-corners,
) = {
  let intersection-distances = ()
  for corner-index in range(polygon-corners.len()) {
    let intersection-distance = _projection-segment-intersection-distance(
      projection-start,
      projection-direction,
      projection-length,
      polygon-corners.at(corner-index),
      polygon-corners.at(calc.rem(corner-index + 1, polygon-corners.len())),
    )
    if intersection-distance != none {
      intersection-distances.push(intersection-distance)
    }
  }
  intersection-distances
}

#let _nearest-projection-collision-distance(
  scene,
  projection-start,
  measured-point,
) = {
  let projection-vector = vector.subtract(measured-point, projection-start)
  let projection-length = vector.magnitude(projection-vector)
  if projection-length == 0 { return 0 }
  let projection-direction = vector.normalized(projection-vector)
  let collision-distances = ()

  for body-name in scene.body-order {
    let body = scene.bodies.at(body-name)
    if body.shape == "block" {
      collision-distances += _projection-polygon-intersection-distances(
        projection-start,
        projection-direction,
        projection-length,
        body-corners(body),
      )
    } else {
      let collision-distance = _projection-circle-intersection-distance(
        projection-start,
        projection-direction,
        projection-length,
        body.center,
        body.half-extent-along,
      )
      if collision-distance != none {
        collision-distances.push(collision-distance)
      }
    }
  }

  for structure-name in scene.structure-order {
    let placed-structure = scene.structures.at(structure-name)
    if placed-structure.kind == "rod" {
      collision-distances += _projection-polygon-intersection-distances(
        projection-start,
        projection-direction,
        projection-length,
        rod-corners(placed-structure),
      )
    }
  }

  for surface-name in scene.surface-order {
    let surface = scene.surfaces.at(surface-name)
    if surface.kind != "arc" {
      let collision-distance = _projection-segment-intersection-distance(
        projection-start,
        projection-direction,
        projection-length,
        surface.start,
        surface.end,
      )
      if collision-distance != none {
        collision-distances.push(collision-distance)
      }
    }
  }

  if collision-distances.len() == 0 {
    projection-length
  } else {
    calc.min(..collision-distances)
  }
}

#let _render-dimension-extension(
  scene,
  dimension-point,
  measured-point,
  extension-gap,
  extension-stroke,
) = {
  let projection-vector = vector.subtract(measured-point, dimension-point)
  let projection-length = vector.magnitude(projection-vector)
  if projection-length == 0 { return }
  let projection-direction = vector.normalized(projection-vector)
  let collision-distance = _nearest-projection-collision-distance(
    scene,
    dimension-point,
    measured-point,
  )
  let visible-extension-length = calc.max(
    0,
    collision-distance - extension-gap,
  )
  if visible-extension-length > 0 {
    line(
      dimension-point,
      vector.point-along(
        dimension-point,
        projection-direction,
        visible-extension-length,
      ),
      stroke: extension-stroke,
    )
  }
}

#let _dimension-line-geometry(
  measured-start,
  measured-end,
  orientation,
  side,
  offset,
) = {
  if orientation == "horizontal" {
    let horizontal-span = measured-end.at(0) - measured-start.at(0)
    assert(
      calc.abs(horizontal-span) > 0.000001,
      message: "typed-physics: a horizontal dimension needs endpoints with different x coordinates",
    )
    let dimension-height = if side == "above" {
      calc.max(measured-start.at(1), measured-end.at(1)) + offset
    } else {
      calc.min(measured-start.at(1), measured-end.at(1)) - offset
    }
    return (
      start: (measured-start.at(0), dimension-height),
      end: (measured-end.at(0), dimension-height),
    )
  }

  if orientation == "vertical" {
    let vertical-span = measured-end.at(1) - measured-start.at(1)
    assert(
      calc.abs(vertical-span) > 0.000001,
      message: "typed-physics: a vertical dimension needs endpoints with different y coordinates",
    )
    let dimension-horizontal-position = if side == "right" {
      calc.max(measured-start.at(0), measured-end.at(0)) + offset
    } else {
      calc.min(measured-start.at(0), measured-end.at(0)) - offset
    }
    return (
      start: (dimension-horizontal-position, measured-start.at(1)),
      end: (dimension-horizontal-position, measured-end.at(1)),
    )
  }

  let measured-span = vector.subtract(measured-end, measured-start)
  let measured-direction = vector.normalized(measured-span)
  let left-normal-direction = vector.left-normal(measured-direction)
  let dimension-normal-direction = if side in ("above", "left") {
    left-normal-direction
  } else {
    vector.reversed(left-normal-direction)
  }
  (
    start: vector.point-along(
      measured-start,
      dimension-normal-direction,
      offset,
    ),
    end: vector.point-along(
      measured-end,
      dimension-normal-direction,
      offset,
    ),
  )
}

#let render-dimension(scene, dimension-annotation, diagram-style) = {
  let measured-start = _dimension-endpoint(
    scene,
    dimension-annotation.from,
  )
  let measured-end = _dimension-endpoint(scene, dimension-annotation.to)
  let measured-span = vector.subtract(measured-end, measured-start)
  let measured-length = vector.magnitude(measured-span)
  assert(
    measured-length > 0,
    message: "typed-physics: dimension() endpoints must not coincide",
  )

  let dimension-line = _dimension-line-geometry(
    measured-start,
    measured-end,
    dimension-annotation.orientation,
    dimension-annotation.side,
    dimension-annotation.offset,
  )
  let dimension-start = dimension-line.start
  let dimension-end = dimension-line.end
  let dimension-direction = vector.normalized(
    vector.subtract(dimension-end, dimension-start),
  )
  let left-normal-direction = vector.left-normal(dimension-direction)

  let dimension-color = if dimension-annotation.color == auto {
    diagram-style.dimension-color
  } else {
    dimension-annotation.color
  }
  let dimension-stroke = (
    if dimension-annotation.stroke == auto {
      diagram-style.dimension-stroke
    } else {
      dimension-annotation.stroke
    }
  ) + dimension-color

  if dimension-annotation.extensions and dimension-annotation.offset > 0 {
    let declared-extension-stroke = if dimension-annotation.extension-stroke == auto {
      diagram-style.dimension-extension-stroke
    } else {
      dimension-annotation.extension-stroke
    }
    let extension-stroke = if type(declared-extension-stroke) == dictionary {
      declared-extension-stroke + (paint: dimension-color)
    } else {
      declared-extension-stroke + dimension-color
    }
    _render-dimension-extension(
      scene,
      dimension-start,
      measured-start,
      dimension-annotation.extension-gap,
      extension-stroke,
    )
    _render-dimension-extension(
      scene,
      dimension-end,
      measured-end,
      dimension-annotation.extension-gap,
      extension-stroke,
    )
  }

  line(
    dimension-start,
    dimension-end,
    stroke: dimension-stroke,
    mark: _dimension-arrow-marks(dimension-annotation, dimension-color),
  )

  if dimension-annotation.label == none { return }
  let displayed-label = if dimension-annotation.label == auto {
    $L$
  } else {
    dimension-annotation.label
  }
  let dimension-text-style = (
    (fill: dimension-color)
      + diagram-style.dimension-text
      + dimension-annotation.text
  )
  let styled-label = text(..dimension-text-style, displayed-label)
  let label-is-centered = dimension-annotation.label-position == "center"
  let label-body = if label-is-centered {
    box(
      fill: dimension-annotation.label-fill,
      inset: (x: 0.22em, y: 0.06em),
      styled-label,
    )
  } else {
    styled-label
  }
  let label-normal-direction = if dimension-annotation.label-position == "below" {
    vector.reversed(left-normal-direction)
  } else {
    left-normal-direction
  }
  let label-position = if label-is-centered {
    vector.midpoint(dimension-start, dimension-end)
  } else {
    vector.point-along(
      vector.midpoint(dimension-start, dimension-end),
      label-normal-direction,
      dimension-annotation.label-offset,
    )
  }
  content(
    label-position,
    if dimension-annotation.label-rotation == 0deg {
      label-body
    } else {
      rotate(
        dimension-annotation.label-rotation,
        reflow: false,
        label-body,
      )
    },
    anchor: "center",
  )
}

#let render-dimensions(scene, dimensions, diagram-style) = {
  let dimension-annotations = if dimensions == none {
    ()
  } else if type(dimensions) == dictionary {
    (dimensions,)
  } else {
    assert(
      type(dimensions) == array,
      message: "typed-physics: dimensions: must be dimension(...) or an array of them",
    )
    dimensions
  }
  for dimension-annotation in dimension-annotations {
    assert(
      type(dimension-annotation) == dictionary
        and dimension-annotation.at("kind", default: none) == "dimension",
      message: "typed-physics: dimensions: accepts only dimension(...) annotations",
    )
    let dimension-fields = (
      "kind", "from", "to", "orientation", "offset", "side", "label",
      "label-position", "label-offset", "label-rotation", "label-fill",
      "arrows", "arrow-tip", "arrow-scale", "extensions", "extension-gap",
      "extension-stroke", "stroke", "color", "text",
    )
    for field in dimension-annotation.keys() {
      assert(
        field in dimension-fields,
        message: (
          "typed-physics: dimensions: annotation has unknown field `"
            + field
            + ":`; create it with dimension() to validate its arguments"
        ),
      )
    }
    let missing-fields = dimension-fields.filter(
      field => field not in dimension-annotation,
    )
    assert(
      missing-fields.len() == 0,
      message: (
        "typed-physics: dimensions: malformed dimension annotation is missing "
          + missing-fields.map(field => "`" + field + ":`").join(", ")
          + "; create it with dimension()"
      ),
    )
    render-dimension(scene, dimension-annotation, diagram-style)
  }
}

// Which bodies a view argument names: none, one, several, or all of them.
#let bodies-named-by(scene, body-selection, argument-name: "forces") = {
  let named-bodies = if body-selection == none {
    ()
  } else if body-selection == true {
    scene.body-order
  } else if type(body-selection) == str {
    (body-selection,)
  } else {
    assert(
      type(body-selection) == array,
      message: (
        "typed-physics: "
          + argument-name
          + ": must be none, true, a body name, or an array of body names; got "
          + repr(body-selection)
      ),
    )
    body-selection
  }
  assert(
    named-bodies.all(body-name => type(body-name) == str),
    message: "typed-physics: " + argument-name + ": body selections must contain only string names",
  )
  assert(
    named-bodies.dedup().len() == named-bodies.len(),
    message: "typed-physics: " + argument-name + ": names the same body more than once; remove duplicate selections",
  )
  for body-name in named-bodies {
    assert(
      body-name in scene.bodies,
      message: "typed-physics: " + argument-name + ": names \"" + body-name + "\", which is not a body in this situation",
    )
  }
  named-bodies
}

// The forces on a body drawn where that body sits, rather than in a diagram of
// its own. Same enumeration, same lengths, so a scene annotated this way and a
// free-body diagram of the same body cannot show different arrows.
#let render-forces-on-body(
  scene,
  body,
  arrow-lengths,
  diagram-style,
  solution: none,
) = {
  let acting-forces = force-enumeration.enumerate-forces(
    scene,
    body.name,
    solution: solution,
  )
  for (force-index, acting-force) in acting-forces.enumerate() {
    let force-style = resolve-force-style(
      diagram-style,
      acting-force.style,
      acting-force.role,
    )
    let body-style = resolve-body-style(diagram-style, body.style)
    let visible-boundary-distance = body-visible-boundary-distance(
      body,
      acting-force.direction,
      body-style.stroke,
    )
    let arrow-tail-position = body.center
    let arrow-tip-position = vector.point-along(
      body.center,
      acting-force.direction,
      visible-boundary-distance + arrow-lengths.at(force-index),
    )
    render-force-arrow(
      arrow-tail-position,
      arrow-tip-position,
      force-style.color,
      force-style.stroke,
    )
    render-label(
      vector.point-along(arrow-tip-position, acting-force.direction, 0.28),
      text(fill: force-style.color, acting-force.symbol),
      force-style.text,
    )
  }
}

// ── Scene ────────────────────────────────────────────────────────────────────

#let annotation-settings(
  selection,
  argument-name,
  default-mode,
  allowed-modes,
  element-names,
) = {
  let selection-is-mode = type(selection) == str
  assert(
    selection-is-mode or type(selection) == dictionary,
    message: "typed-physics: " + argument-name + ": must be a mode or a dictionary with mode: and overrides:",
  )
  let mode = if selection-is-mode {
    selection
  } else {
    selection.at("mode", default: default-mode)
  }
  assert(
    mode in allowed-modes,
    message: "typed-physics: " + argument-name + ": mode must be " + allowed-modes.join(", "),
  )

  let declared-overrides = if selection-is-mode {
    ()
  } else {
    for key in selection.keys() {
      assert(
        key in ("mode", "overrides"),
        message: "typed-physics: unknown " + argument-name + ": key \"" + key + "\"; it takes mode and overrides",
      )
    }
    selection.at("overrides", default: ())
  }
  assert(
    type(declared-overrides) == array,
    message: "typed-physics: " + argument-name + ": overrides must be an array",
  )

  let resolved-settings = (:)
  for element-name in element-names {
    resolved-settings.insert(
      element-name,
      (mode: mode, is-visible: true, offset: (0, 0), rotation: 0deg),
    )
  }

  let overridden-elements = ()
  for declared-override in declared-overrides {
    assert(
      type(declared-override) == dictionary,
      message: "typed-physics: every " + argument-name + ": override must be a dictionary",
    )
    for key in declared-override.keys() {
      assert(
        key in ("on", "mode", "visible", "offset", "rotation"),
        message: "typed-physics: unknown " + argument-name + ": override key \"" + key + "\"",
      )
    }
    assert(
      "on" in declared-override,
      message: "typed-physics: every " + argument-name + ": override needs `on:` an eligible element name",
    )
    let element-name = declared-override.at("on")
    assert(
      element-name in element-names,
      message: "typed-physics: " + argument-name + ": override names \"" + element-name + "\", which is not an eligible element in this situation",
    )
    assert(
      not overridden-elements.contains(element-name),
      message: "typed-physics: " + argument-name + ": has more than one override for \"" + element-name + "\"",
    )
    overridden-elements.push(element-name)

    let element-mode = declared-override.at("mode", default: mode)
    let should-show-label = declared-override.at("visible", default: true)
    let label-offset = declared-override.at("offset", default: (0, 0))
    let label-rotation = declared-override.at("rotation", default: 0deg)
    assert(
      element-mode in allowed-modes,
      message: "typed-physics: " + argument-name + ": override mode must be " + allowed-modes.join(", "),
    )
    assert(
      type(should-show-label) == bool,
      message: "typed-physics: " + argument-name + ": override visible must be true or false",
    )
    assert(
      type(label-offset) == array
        and label-offset.len() == 2
        and type(label-offset.at(0)) in (int, float)
        and type(label-offset.at(1)) in (int, float),
      message: "typed-physics: " + argument-name + ": override offset must be an (x, y) pair of numbers",
    )
    assert(
      type(label-rotation) == angle,
      message: "typed-physics: " + argument-name + ": override rotation must be an angle",
    )
    resolved-settings.insert(
      element-name,
      (
        mode: element-mode,
        is-visible: should-show-label,
        offset: label-offset,
        rotation: label-rotation,
      ),
    )
  }
  resolved-settings
}

#let angle-label(surface, mode) = {
  if mode == "none" { return none }
  let displayed-degrees = expression.format-angle(surface.inclination.deg())
  if mode == "value" { return $#displayed-degrees$ }
  if mode == "symbol" { return surface.inclination-quantity.symbol }
  $#surface.inclination-quantity.symbol = #displayed-degrees$
}

#let render-scene(
  scene,
  diagram-style,
  labels: "name",
  angles: "value",
  loads: true,
  frictions: false,
  lengths: false,
  dimensions: (),
  forces: none,
  force-arrow-lengths: (:),
  solutions: (:),
) = {
  let bodies-showing-forces = bodies-named-by(scene, forces)
  let body-label-settings = annotation-settings(
    labels,
    "labels",
    "name",
    ("name", "symbol", "mass", "both", "none"),
    scene.body-order
      + scene.structure-order.filter(
        structure-name => scene.structures.at(structure-name).kind
          in ("rod", "pendulum"),
      ),
  )
  for element-name in body-label-settings.keys() {
    let label-setting = body-label-settings.at(element-name)
    if (
      label-setting.is-visible
        and label-setting.mode in ("symbol", "mass", "both")
    ) {
      let labelled-element = if element-name in scene.bodies {
        scene.bodies.at(element-name)
      } else {
        scene.structures.at(element-name)
      }
      assert(
        labelled-element.mass != none,
        message: (
          "typed-physics: labels: mode \""
            + label-setting.mode
            + "\" requests a mass label for \""
            + element-name
            + "\", but it has no `mass:`; declare its mass, choose mode \"name\", or hide that override"
        ),
      )
    }
  }
  let ramp-names = scene.surface-order.filter(
    surface-name => scene.surfaces.at(surface-name).kind == "ramp",
  )
  let angle-label-settings = annotation-settings(
    angles,
    "angles",
    "value",
    ("value", "symbol", "both", "none"),
    ramp-names,
  )

  for surface-name in scene.surface-order {
    let surface = scene.surfaces.at(surface-name)
    render-surface(surface, diagram-style)
  }
  render-unified-surface-hatching(scene, diagram-style)
  let straight-hatch-spans = unified-surface-hatch-spans(
    scene,
    diagram-style,
  )
  for surface-name in scene.surface-order {
    let surface = scene.surfaces.at(surface-name)
    if surface.kind == "arc" {
      render-curved-surface-hatching(
        surface,
        resolve-surface-style(diagram-style, surface.style),
        straight-hatch-spans,
      )
    }
  }

  for surface-name in scene.surface-order {
    let surface = scene.surfaces.at(surface-name)
    if lengths { render-surface-length(surface, diagram-style) }
    if surface.kind == "ramp" {
      let angle-annotation = angle-label-settings.at(surface-name)
      let climbs-to-the-right = surface.facing == "right"
      if angle-annotation.is-visible and angle-annotation.mode != "none" {
        render-angle-marker(
          surface.foot,
          if climbs-to-the-right { (1, 0) } else { (-1, 0) },
          surface.direction,
          angle-label(surface, angle-annotation.mode),
          diagram-style,
          radius: calc.min(diagram-style.angle-radius, surface.length * 0.22),
          // The label starts at the edge nearest the corner, so naming the
          // angle as well as its value grows the text into the ramp, not over
          // the arc.
          label-side: if climbs-to-the-right { "west" } else { "east" },
          label-offset: angle-annotation.offset,
          label-rotation: angle-annotation.rotation,
        )
      }
    }
  }

  for structure-name in scene.structure-order {
    let placed-structure = scene.structures.at(structure-name)
    if placed-structure.kind == "pivot" {
      render-pivot(placed-structure, diagram-style)
    } else if placed-structure.kind == "support" {
      render-support(placed-structure, diagram-style)
    }
  }
  for structure-name in scene.structure-order {
    let placed-structure = scene.structures.at(structure-name)
    if placed-structure.kind == "rod" {
      if loads {
        let applied-load-count = placed-structure.loads.len()
        for (load-index, applied-load) in placed-structure.loads.enumerate() {
          render-applied-load-on-rod(
            placed-structure,
            applied-load,
            force-enumeration.applied-load-symbol(
              applied-load,
              load-index,
              applied-load-count,
            ),
            diagram-style,
          )
        }
      }
      render-rod(
        placed-structure,
        diagram-style,
        body-label-settings.at(structure-name),
      )
    } else if placed-structure.kind == "pendulum" {
      render-pendulum(
        placed-structure,
        diagram-style,
        body-label-settings.at(structure-name),
      )
    }
  }

  for placed-connector in scene.connectors {
    render-connector(placed-connector, scene, diagram-style)
  }
  for pulley-name in scene.pulleys.keys() {
    render-pulley(scene.pulleys.at(pulley-name), diagram-style)
  }

  for body-name in scene.body-order {
    let body = scene.bodies.at(body-name)
    if bodies-showing-forces.contains(body-name) {
      render-forces-on-body(
        scene,
        body,
        force-arrow-lengths.at(body-name),
        diagram-style,
        solution: solutions.at(body-name, default: none),
      )
    } else if loads {
      let applied-load-count = body.loads.len()
      for (load-index, applied-load) in body.loads.enumerate() {
        render-applied-load(
          body,
          applied-load,
          force-enumeration.applied-load-symbol(
            applied-load,
            load-index,
            applied-load-count,
          ),
          diagram-style,
        )
      }
    }
    for (velocity-index, body-velocity) in body.velocities.enumerate() {
      render-velocity(body, body-velocity, velocity-index, diagram-style)
    }
    render-body(
      body,
      diagram-style,
      label-annotation: body-label-settings.at(body-name),
    )
    // Friction belongs to a contact rather than to a surface, so it is named
    // beside the body that makes it. The label sits on its own downhill end,
    // so it grows over ground that falls away from it and a rising surface
    // never runs through the text.
    if frictions and body.support != none {
      let contact-friction = friction-label(body.friction)
      if contact-friction != none {
        render-label(
          vector.point-along(
            vector.point-along(
              body.contact,
              vector.reversed(body.direction),
              body.half-extent-along + 0.25,
            ),
            body.outward-normal,
            0.12,
          ),
          contact-friction,
          diagram-style.angle-text,
          side: "south-east",
        )
      }
    }
    for (
      angular-velocity-index,
      body-angular-velocity,
    ) in body.angular-velocities.enumerate() {
      render-angular-velocity(
        body,
        body-angular-velocity,
        angular-velocity-index,
        diagram-style,
      )
    }
  }
  if loads {
    for placed-torque in scene.torques {
      render-torque(placed-torque, diagram-style)
    }
  }
  render-dimensions(scene, dimensions, diagram-style)
}

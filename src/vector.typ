// Plane vectors as `(x, y)` pairs, which is also what CeTZ accepts as a
// coordinate, so a computed position can be handed straight to a draw call.

#let plus(a, b) = (a.at(0) + b.at(0), a.at(1) + b.at(1))

#let minus(a, b) = (a.at(0) - b.at(0), a.at(1) - b.at(1))

#let times(v, factor) = (v.at(0) * factor, v.at(1) * factor)

#let dot(a, b) = a.at(0) * b.at(0) + a.at(1) * b.at(1)

#let length(v) = calc.sqrt(dot(v, v))

#let unit(v) = {
  let size = length(v)
  if size == 0 { v } else { times(v, 1 / size) }
}

#let reversed(v) = times(v, -1)

// Rotations by a quarter turn. `left-normal` of a surface direction points out
// of the body that surface belongs to when the body lies to its right.
#let left-normal(v) = (-v.at(1), v.at(0))

#let right-normal(v) = (v.at(1), -v.at(0))

#let from-angle(direction) = (calc.cos(direction), calc.sin(direction))

#let angle-of(v) = calc.atan2(v.at(0), v.at(1))

#let stepped(origin, direction, distance) = plus(origin, times(direction, distance))

#let midpoint(a, b) = times(plus(a, b), 0.5)

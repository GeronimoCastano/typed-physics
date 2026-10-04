#import "../../src/lib.typ": *
#import "../../src/shared/vector.typ"
#import "../../src/shared/expression.typ"

#let pulley-situation(leftward: false, reverse-ends: false, motion-angle: none) = {
  let supported-end = if leftward { "A.left" } else { "A.right" }
  let motion = if motion-angle == none { () } else {
    (velocity(on: "A", magnitude: 1, angle: motion-angle),)
  }
  situation(
    ground("floor", length: 8, mu: (s: 0.300, k: 0.220)),
    block("A", mass: 4, on: "floor", at: 55%, size: 1.2),
    pulley("wheel", at: if leftward { "floor.start" } else { "floor.end" }, radius: 0.55),
    block("B", mass: 3, hanging: if leftward { "wheel.left" } else { "wheel.right" }, drop: 1.6, size: 1.2),
    rope(
      "cord",
      from: if reverse-ends { "B.top" } else { supported-end },
      to: if reverse-ends { supported-end } else { "B.top" },
      over: "wheel",
    ),
    ..motion,
  )
}

#let force-with-role(s, body-name, role) = {
  let matching-forces = forces(s, body-name).filter(force => force.role == role)
  assert(matching-forces.len() == 1, message: body-name + " must have exactly one " + role + " force")
  matching-forces.first()
}

#for leftward in (false, true) {
  for reverse-ends in (false, true) {
    let s = pulley-situation(leftward: leftward, reverse-ends: reverse-ends)
    let tension-on-A = force-with-role(s, "A", "tension")
    let tension-on-B = force-with-role(s, "B", "tension")
    let friction-on-A = force-with-role(s, "A", "friction")
    let cord = s.connectors.first()
    let rope-endpoint = if reverse-ends { cord.end } else { cord.start }
    let rope-tangent = if reverse-ends { cord.end-tangent } else { cord.start-tangent }
    let expected-tension-direction = vector.normalized(vector.subtract(rope-tangent, rope-endpoint))
    assert(vector.magnitude(vector.subtract(tension-on-A.direction, expected-tension-direction)) < 1e-9)
    assert(if leftward { tension-on-A.direction.at(0) < 0 } else { tension-on-A.direction.at(0) > 0 })
    assert(friction-on-A.direction == if leftward { (1, 0) } else { (-1, 0) })
    assert(tension-on-B.direction.at(1) > 0)
    assert(tension-on-A.magnitude == none and tension-on-B.magnitude == none)
    assert(model-of(s, "A") == none and model-of(s, "B") == none)
    assert(calc.abs(expression.value-of(force-with-role(s, "A", "weight").magnitude) - 39.24) < 1e-9)
  }
}

#let straight-rope = situation(
  ground("floor", length: 6, mu: 0.3),
  wall("wall", side: right, from: "floor.end", height: 3),
  block("A", mass: 2, on: "floor", at: 50%),
  rope("cord", from: (on: "wall", at: 50%), to: "A.right"),
)
#let cord = straight-rope.connectors.first()
#assert(vector.magnitude(vector.subtract(
  force-with-role(straight-rope, "A", "tension").direction,
  vector.normalized(vector.subtract(cord.start, cord.end)),
)) < 1e-9)

#let hanging-rope = situation(
  ceiling("beam", length: 6, height: 3),
  block("bob", mass: 3, hanging: (on: "beam", at: 50%)),
  rope("cord", from: (on: "beam", at: 50%), to: "bob.top"),
)
#assert(force-with-role(hanging-rope, "bob", "tension").direction == (0, 1))
#assert(results(hanging-rope).tension.value == 29.43)
#fbd(hanging-rope, "bob")

#let implicit-hanging = situation(
  ceiling("beam", length: 6, height: 3),
  block("bob", mass: 3, hanging: "beam"),
)
#assert(force-with-role(implicit-hanging, "bob", "tension").direction == (0, 1))

#assert(force-with-role(pulley-situation(motion-angle: 180deg), "A", "friction").direction == (1, 0))
#assert(force-with-role(pulley-situation(leftward: true, motion-angle: 0deg), "A", "friction").direction == (-1, 0))

#let two-ropes = situation(
  ground("floor", length: 8, mu: 0.3),
  wall("left-wall", side: left, height: 3),
  wall("right-wall", side: right, from: "floor.end", height: 3),
  block("A", mass: 2, on: "floor", at: 50%),
  rope("left-cord", from: "A.left", to: (on: "left-wall", at: 50%)),
  rope("right-cord", from: (on: "right-wall", at: 50%), to: "A.right"),
)
#let tensions = forces(two-ropes, "A").filter(force => force.role == "tension")
#assert(tensions.len() == 2)
#assert(tensions.at(0).direction.at(0) < 0)
#assert(tensions.at(1).direction.at(0) > 0)
#assert(tensions.all(force => force.magnitude == none))
#fbd(two-ropes, "A")

#let both-rope-ends-on-body = situation(
  ceiling("beam", length: 6, height: 3),
  pulley("wheel", at: "beam"),
  block("bob", mass: 3, hanging: "wheel.bottom", size: 1.2),
  rope("cord", from: "bob.left", to: "bob.right", over: "wheel"),
)
#let tensions = forces(both-rope-ends-on-body, "bob").filter(force => force.role == "tension")
#assert(tensions.len() == 2)
#let cord = both-rope-ends-on-body.connectors.first()
#assert(tensions.at(0).direction == vector.normalized(vector.subtract(cord.start-tangent, cord.start)))
#assert(tensions.at(1).direction == vector.normalized(vector.subtract(cord.end-tangent, cord.end)))
#assert(tensions.all(force => force.direction.at(1) > 0))

#let hanging-with-side-rope = situation(
  ceiling("beam", length: 6, height: 3),
  wall("wall", side: right, from: "beam.end", height: 3),
  block("bob", mass: 3, hanging: "beam"),
  rope("side-cord", from: "bob.right", to: (on: "wall", at: 50%)),
)
#let tensions = forces(hanging-with-side-rope, "bob").filter(force => force.role == "tension")
#assert(tensions.len() == 2)
#assert(tensions.any(force => force.direction == (0, 1)))
#assert(tensions.any(force => force.direction.at(0) > 0))

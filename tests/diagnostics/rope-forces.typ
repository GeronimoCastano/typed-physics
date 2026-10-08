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
    // The rope meets the floor at an angle, so the pair is declined and nothing
    // decides which way friction on A points.
    assert(friction-on-A.direction == none)
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

// Hand checks, with g = 9.81 m/s^2, for the two-body pulley model.
#let near(value, expected, tolerance) = calc.abs(value - expected) <= tolerance

// Modified Atwood. A = 4 kg on a 30 degree incline, mu_s = 0.30, mu_k = 0.22,
// tied over the apex pulley to a hanging B = 4 kg. The driving force is
// m_B g - m_A g sin 30 = 39.24 - 19.62 = 19.62 N, against
// mu_s N = 0.30 * 33.98 = 10.19 N, so B descends and A slides up the slope.
// Kinetic friction f_k = 0.22 * 33.98 = 7.48 N acts down the slope, so
// a = (19.62 - 7.48) / 8 = 1.52 m/s^2 and T = 4 (9.81 - 1.52) = 33.2 N.
#let incline-pulley = situation(
  ramp("incline", angle: 30deg, length: 7),
  pulley("P", at: "incline.apex", radius: 0.5),
  block("A", mass: 4, on: "incline", at: 55%, size: 1, mu: (s: 0.30, k: 0.22)),
  block("B", mass: 4, hanging: "P.right", drop: 2, size: 1),
  rope("cord", from: "A.uphill", to: "B.top", over: "P"),
)
#let incline-answer = results(incline-pulley, "A")
#assert(model-of(incline-pulley, "A") == "two-bodies-over-pulley")
#assert(model-of(incline-pulley, "B") == "two-bodies-over-pulley")
#assert(incline-answer.regime == "sliding")
#assert(incline-answer.descending-body == "B")
#assert(near(incline-answer.acceleration.value, 1.518, 0.001))
#assert(near(incline-answer.tension.value, 33.17, 0.01))
#assert(near(incline-answer.normal.value, 33.98, 0.01))
#assert(near(incline-answer.friction.value, 7.476, 0.001))
#assert(near(incline-answer.acceleration.direction.at(1), -1, 1e-9))
#assert(incline-answer.friction.direction.at(0) < 0 and incline-answer.friction.direction.at(1) < 0)
// Both bodies report the same motion, tension, and surface forces.
#assert(results(incline-pulley, "B").tension.value == incline-answer.tension.value)
#assert(results(incline-pulley, "B").acceleration.value == incline-answer.acceleration.value)
#assert(solve(incline-pulley, "B", find: "tension") == solve(incline-pulley, "A", find: "tension"))
#fbd(incline-pulley, "A")
#fbd(incline-pulley, "B")

// Atwood machine. A = 3 kg and B = 5 kg over an ideal pulley, both hanging.
// The net force is (5 - 3) g = 19.62 N, so B descends with
// a = 19.62 / 8 = 2.45 m/s^2 and T = 3 (9.81 + 2.45) = 36.8 N.
#let atwood-pulley = situation(
  ceiling("roof", length: 8, height: 5),
  pulley("P", at: (on: "roof", offset: (0, -0.5)), radius: 0.5),
  block("A", mass: 3, hanging: "P.left", drop: 2, size: 0.8),
  block("B", mass: 5, hanging: "P.right", drop: 2, size: 0.8),
  rope("cord", from: "A.top", to: "B.top", over: "P"),
)
#let atwood-answer = results(atwood-pulley, "A")
#assert(model-of(atwood-pulley, "A") == "two-bodies-over-pulley")
#assert(atwood-answer.regime == "sliding")
#assert(atwood-answer.descending-body == "B")
#assert(near(atwood-answer.acceleration.value, 2.4525, 0.0001))
#assert(near(atwood-answer.tension.value, 36.7875, 0.0001))
#assert(forces(atwood-pulley, "A").filter(force => force.role == "friction").len() == 0)
#assert(solve(atwood-pulley, "A", find: "tension") == solve(atwood-pulley, "B", find: "tension"))
#force-table(atwood-pulley, "A")
#fbd(atwood-pulley, "A")

// Modified Atwood on a horizontal floor. A = 4 kg, mu_s = 0.30, mu_k = 0.20,
// over a pulley at the floor's end, tied to B = 2 kg hanging beside it. The
// driving force is 2 g = 19.62 N, against mu_s N = 0.30 * 39.24 = 11.77 N, so the
// pair slides: f_k = 0.20 * 39.24 = 7.85 N points away from the pulley, and
// a = (19.62 - 7.85) / 6 = 1.96 m/s^2, T = 2 (9.81 - 1.96) = 15.7 N.
#let floor-pulley = situation(
  ground("floor", length: 8),
  pulley("P", at: (on: "floor.end", offset: (0, 0.5)), radius: 0.5),
  block("A", mass: 4, on: "floor", at: 50%, size: 2, mu: (s: 0.30, k: 0.20)),
  block("B", mass: 2, hanging: "P.right", drop: 1.5, size: 0.8),
  rope("cord", from: "A.right", to: "B.top", over: "P"),
)
#assert(model-of(floor-pulley, "A") == "two-bodies-over-pulley")
#assert(results(floor-pulley, "A").regime == "sliding")
#assert(near(results(floor-pulley, "A").acceleration.value, 1.962, 0.001))
#assert(near(results(floor-pulley, "A").tension.value, 15.696, 0.001))
#assert(near(results(floor-pulley, "A").friction.value, 7.848, 0.001))
#assert(results(floor-pulley, "A").friction.direction == (-1, 0))
#assert(results(floor-pulley, "A").acceleration.direction == (0, -1))
// The same floor with B = 1 kg: the driving force 9.81 N is below mu_s N = 11.77 N,
// so the pair holds with f_s = 9.81 N and T = 9.81 N.
#let floor-pulley-held = situation(
  ground("floor", length: 8),
  pulley("P", at: (on: "floor.end", offset: (0, 0.5)), radius: 0.5),
  block("A", mass: 4, on: "floor", at: 50%, size: 2, mu: (s: 0.30, k: 0.20)),
  block("B", mass: 1, hanging: "P.right", drop: 1.5, size: 0.8),
  rope("cord", from: "A.right", to: "B.top", over: "P"),
)
#assert(results(floor-pulley-held, "A").regime == "static")
#assert(near(results(floor-pulley-held, "A").tension.value, 9.81, 0.001))
#assert(near(results(floor-pulley-held, "A").friction.value, 9.81, 0.001))
#fbd(floor-pulley, "A")

// Equal hanging masses balance: the net force is zero, so the pair is static
// and T = m g = 29.43 N.
#let balanced-atwood = situation(
  ceiling("roof", length: 8, height: 5),
  pulley("P", at: (on: "roof", offset: (0, -0.5)), radius: 0.5),
  block("A", mass: 3, hanging: "P.left", drop: 2, size: 0.8),
  block("B", mass: 3, hanging: "P.right", drop: 2, size: 0.8),
  rope("cord", from: "A.top", to: "B.top", over: "P"),
)
#assert(results(balanced-atwood, "A").regime == "static")
#assert(near(results(balanced-atwood, "A").tension.value, 29.43, 0.001))
#assert(near(results(balanced-atwood, "A").acceleration.value, 0, 1e-9))

// Static pair on the incline. mu_s = 0.80 gives 27.18 N of static friction,
// more than the 19.62 N the hanging weight asks for, so the pair holds: T = 39.24 N
// and friction on A points down the slope.
#let held-pulley = situation(
  ramp("incline", angle: 30deg, length: 7),
  pulley("P", at: "incline.apex", radius: 0.5),
  block("A", mass: 4, on: "incline", at: 55%, size: 1, mu: (s: 0.80, k: 0.60)),
  block("B", mass: 4, hanging: "P.right", drop: 2, size: 1),
  rope("cord", from: "A.uphill", to: "B.top", over: "P"),
)
#assert(results(held-pulley, "A").regime == "static")
#assert(near(results(held-pulley, "A").tension.value, 39.24, 0.01))
#assert(near(results(held-pulley, "A").friction.value, 19.62, 0.01))
#assert(results(held-pulley, "A").friction.direction.at(1) < 0)
#assert(near(results(held-pulley, "A").acceleration.value, 0, 1e-9))

// The direction flips when the incline side is heavier. A = 4 kg, B = 1 kg,
// mu_s = 0.20 (6.80 N) against a driving force of 19.62 - 9.81 = 9.81 N, so A
// slides down the slope with mu_k = 0.15 (f_k = 5.10 N) and B rises:
// a = (9.81 - 5.10) / 5 = 0.94 m/s^2 and T = 1 (9.81 + 0.94) = 10.75 N.
#let light-hanging-pulley = situation(
  ramp("incline", angle: 30deg, length: 7),
  pulley("P", at: "incline.apex", radius: 0.5),
  block("A", mass: 4, on: "incline", at: 55%, size: 1, mu: (s: 0.20, k: 0.15)),
  block("B", mass: 1, hanging: "P.right", drop: 2, size: 1),
  rope("cord", from: "A.uphill", to: "B.top", over: "P"),
)
#assert(results(light-hanging-pulley, "A").descending-body == "A")
#assert(near(results(light-hanging-pulley, "A").acceleration.value, 0.9427, 0.001))
#assert(near(results(light-hanging-pulley, "A").tension.value, 10.75, 0.01))
#assert(near(results(light-hanging-pulley, "A").friction.value, 5.097, 0.001))
#assert(results(light-hanging-pulley, "A").friction.direction.at(1) > 0)
#solve(light-hanging-pulley, "A")

// A symbolic coefficient cannot decide the regime, so the pair is declined by the
// usual message, and an assumed regime is answered as given.
#let symbolic-pulley = situation(
  ramp("incline", angle: 30deg, length: 7),
  pulley("P", at: "incline.apex", radius: 0.5),
  block("A", mass: 4, on: "incline", at: 55%, size: 1, mu: (s: $mu_s$, k: $mu_k$)),
  block("B", mass: 4, hanging: "P.right", drop: 2, size: 1),
  rope("cord", from: "A.uphill", to: "B.top", over: "P"),
)
#assert(results(symbolic-pulley, "A").status == "undetermined")
#assert(force-with-role(symbolic-pulley, "A", "friction").direction == none)
#solve(symbolic-pulley, "A")
#solve(symbolic-pulley, "A", assume: "sliding")
#solve(symbolic-pulley, "A", assume: "sliding", find: "tension")

// A weight-only contact whose regime is undetermined draws no friction arrow,
// because nothing decides which way the friction points.
#let symbolic-slope = situation(
  ramp("incline", angle: 30deg, length: 6),
  block("A", mass: 4, on: "incline", mu: (s: $mu_s$, k: $mu_k$)),
)
#assert(force-with-role(symbolic-slope, "A", "friction").direction == none)
#assert(force-with-role(symbolic-slope, "A", "friction").magnitude == none)
#scene(symbolic-slope, forces: "A")

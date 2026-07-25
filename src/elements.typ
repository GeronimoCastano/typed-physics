// The declarative vocabulary. Every constructor returns a plain dictionary
// describing one piece of the situation; `situation` is what turns those
// dictionaries into placed geometry, forces, and equations.
//
// Nothing here takes a coordinate. A body says which surface it rests on and
// how far along it sits, so changing a ramp's angle moves everything that was
// declared in terms of that ramp.

#let _name-or(arguments, fallback) = {
  let given = arguments.pos()
  assert(
    given.len() <= 1,
    message: "typed-physics: an element takes at most one positional argument, its name",
  )
  if given.len() == 1 { given.first() } else { fallback }
}

// Accepts `mu: 0.3`, `mu: (s: 0.4, k: 0.3)`, `mu: (static: .., kinetic: ..)`,
// or a symbol such as `mu: $mu$` for a coefficient to be solved for.
#let _friction-of(mu) = {
  if mu == none { return none }
  if type(mu) == dictionary {
    let static = mu.at("s", default: mu.at("static", default: none))
    let kinetic = mu.at("k", default: mu.at("kinetic", default: none))
    assert(
      static != none or kinetic != none,
      message: "typed-physics: mu given as a dictionary needs an `s:`/`static:` or `k:`/`kinetic:` entry",
    )
    return (static: if static == none { kinetic } else { static }, kinetic: if kinetic == none { static } else { kinetic })
  }
  (static: mu, kinetic: mu)
}

#let _side-of(side) = {
  let named = if type(side) == alignment { repr(side) } else { side }
  assert(
    named in ("left", "right"),
    message: "typed-physics: side must be `left` or `right`, got " + repr(side),
  )
  named
}

// ── Environment ──────────────────────────────────────────────────────────────

#let ground(..name, length: 8, mu: none) = (
  kind: "ground",
  name: _name-or(name, "ground"),
  length: length,
  friction: _friction-of(mu),
)

#let wall(..name, side: left, height: 4, mu: none) = (
  kind: "wall",
  name: _name-or(name, "wall"),
  side: _side-of(side),
  height: height,
  friction: _friction-of(mu),
)

#let ceiling(..name, length: 8, height: 4, mu: none) = (
  kind: "ceiling",
  name: _name-or(name, "ceiling"),
  length: length,
  height: height,
  friction: _friction-of(mu),
)

// An inclined surface rising to the right from its foot, with the ground under
// it. `length` is measured along the incline, not along its base.
#let ramp(name, angle: 30deg, length: 6, mu: none) = {
  assert(type(angle) == std.angle, message: "typed-physics: ramp \"" + name + "\" needs `angle:` as an angle, e.g. 30deg")
  assert(
    angle > 0deg and angle < 90deg,
    message: "typed-physics: ramp \"" + name + "\" has angle " + repr(angle) + ", which must be between 0deg and 90deg",
  )
  assert(length > 0, message: "typed-physics: ramp \"" + name + "\" needs a positive length")
  (
    kind: "ramp",
    name: name,
    angle: angle,
    length: length,
    friction: _friction-of(mu),
  )
}

// ── Bodies ───────────────────────────────────────────────────────────────────

// A square body resting on a surface. `at:` is how far along that surface its
// contact face sits; `touching:` places it against another body instead.
#let block(
  name,
  mass: none,
  on: none,
  at: 50%,
  touching: none,
  side: right,
  size: 1,
  mu: none,
  label: auto,
) = {
  assert(
    on != none or touching != none,
    message: "typed-physics: block \"" + name + "\" needs `on:` a surface or `touching:` another body",
  )
  assert(type(at) == ratio, message: "typed-physics: block \"" + name + "\" needs `at:` as a ratio, e.g. 55%")
  assert(size > 0, message: "typed-physics: block \"" + name + "\" needs a positive size")
  (
    kind: "block",
    name: name,
    mass: mass,
    on: on,
    at: at,
    touching: touching,
    side: _side-of(side),
    size: size,
    friction: _friction-of(mu),
    label: label,
  )
}

// ── Applied loads ────────────────────────────────────────────────────────────

// A force the problem statement applies to a body, measured from the
// horizontal like every other angle in the package.
#let force(on: none, magnitude: none, angle: 0deg, label: auto) = {
  assert(on != none, message: "typed-physics: force() needs `on:` the name of the body it acts on")
  assert(magnitude != none, message: "typed-physics: force() on \"" + on + "\" needs a `magnitude:`")
  assert(type(angle) == std.angle, message: "typed-physics: force() on \"" + on + "\" needs `angle:` as an angle")
  (
    kind: "force",
    on: on,
    magnitude: magnitude,
    angle: angle,
    label: label,
  )
}

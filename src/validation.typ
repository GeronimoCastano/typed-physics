// Shared validation and diagnostics for every public boundary.
//
// Constructors validate values that are meaningful in isolation. Situation
// validation then checks declaration schemas, names, references, ordering, and
// cross-element compatibility before placement turns anything into geometry.

#let _value(value) = repr(value)
#let _stroke-type = type(1pt + black)

#let _is-finite-number(value) = {
  if type(value) == int { return true }
  (
    type(value) == float
      and value == value
      and value != float.inf
      and value != -float.inf
  )
}

#let fail(source-description, argument, value, requirement, correction) = {
  panic(
    "typed-physics: "
      + source-description
      + " has invalid `"
      + argument
      + ":` "
      + _value(value)
      + "; "
      + requirement
      + ". "
      + correction,
  )
}

#let validate-name(name, source-description: "element") = {
  assert(
    type(name) == str and name.len() > 0,
    message: (
      "typed-physics: "
        + source-description
        + " needs a non-empty string name, got "
        + _value(name)
        + "; use a name such as \"A\" or \"incline\""
    ),
  )
  assert(
    not name.contains("."),
    message: (
      "typed-physics: "
        + source-description
        + " name "
        + _value(name)
        + " cannot contain \".\" because dots select anchors; use a name such as \""
        + name.replace(".", "-")
        + "\""
    ),
  )
  none
}

#let validate-enum(value, accepted, source-description, argument) = {
  if value not in accepted {
    fail(
      source-description,
      argument,
      value,
      "accepted values are " + accepted.map(repr).join(", "),
      "choose one of those values",
    )
  }
  none
}

#let validate-boolean(value, source-description, argument, allow-auto: false) = {
  let is-valid = type(value) == bool or (allow-auto and value == auto)
  if not is-valid {
    fail(
      source-description,
      argument,
      value,
      if allow-auto { "expected true, false, or auto" } else {
        "expected true or false"
      },
      "pass an explicit boolean" + if allow-auto { " or auto" } else { "" },
    )
  }
  none
}

#let validate-angle(value, source-description, argument, allow-auto: false) = {
  let is-valid = type(value) == std.angle or (allow-auto and value == auto)
  if not is-valid {
    fail(
      source-description,
      argument,
      value,
      if allow-auto { "expected an angle or auto" } else {
        "expected an angle such as 30deg"
      },
      "pass " + if allow-auto { "auto or " } else { "" } + "a value with an angle unit",
    )
  }
  none
}

#let validate-positive-number(value, source-description, argument) = {
  if not _is-finite-number(value) or value <= 0 {
    fail(
      source-description,
      argument,
      value,
      "expected a positive number greater than zero",
      "pass a positive numeric value",
    )
  }
  none
}

#let validate-nonnegative-number(value, source-description, argument) = {
  if not _is-finite-number(value) or value < 0 {
    fail(
      source-description,
      argument,
      value,
      "expected a non-negative number",
      "pass zero or a positive numeric value",
    )
  }
  none
}

#let validate-positive-integer(value, source-description, argument) = {
  if type(value) != int or value < 1 {
    fail(
      source-description,
      argument,
      value,
      "expected a positive integer",
      "pass a whole number of at least 1",
    )
  }
  none
}

#let validate-ratio(value, source-description, argument, allow-endpoints: true) = {
  if type(value) != ratio {
    fail(
      source-description,
      argument,
      value,
      "expected a ratio between 0% and 100%",
      "pass a percentage such as 50%",
    )
  }
  let lower-bound-is-valid = if allow-endpoints { value >= 0% } else {
    value > 0%
  }
  let upper-bound-is-valid = if allow-endpoints { value <= 100% } else {
    value < 100%
  }
  if not lower-bound-is-valid or not upper-bound-is-valid {
    fail(
      source-description,
      argument,
      value,
      (
        "expected a ratio between "
          + if allow-endpoints { "0% and 100%, inclusive" } else {
            "0% and 100%, exclusive"
          }
      ),
      "pass a percentage such as 50%",
    )
  }
  none
}

// Numeric physical quantities must be positive. Content is deliberately
// accepted as a symbolic value and `none` remains valid where the quantity is
// optional.
#let validate-physical-scalar(
  value,
  source-description,
  argument,
  allow-none: false,
  allow-zero: false,
) = {
  if value == none and allow-none { return none }
  let value-is-symbolic = type(value) == content
  let value-is-number = _is-finite-number(value)
  let numeric-value-is-valid = (
    value-is-number and if allow-zero { value >= 0 } else { value > 0 }
  )
  if not value-is-symbolic and not numeric-value-is-valid {
    fail(
      source-description,
      argument,
      value,
      (
        "expected "
          + if allow-none { "none, " } else { "" }
          + if allow-zero { "a non-negative number" } else {
            "a positive number"
          }
          + ", or symbolic content such as $m$"
      ),
      "pass a physically meaningful number or a Typst math symbol",
    )
  }
  none
}

#let validate-simple-reference(reference, source-description, argument) = {
  assert(
    type(reference) == str and reference.len() > 0 and not reference.contains("."),
    message: (
      "typed-physics: "
        + source-description
        + " needs `"
        + argument
        + ":` as an element name such as \"A\", got "
        + _value(reference)
        + "; do not include an anchor in this argument"
    ),
  )
  none
}

#let validate-attachment(
  attachment,
  source-description,
  argument,
  allow-none: false,
  allow-auto: false,
  allow-coordinate: false,
  allow-ratio: false,
) = {
  if attachment == none and allow-none { return none }
  if attachment == auto and allow-auto { return none }
  if type(attachment) == ratio and allow-ratio {
    validate-ratio(attachment, source-description, argument)
    return none
  }
  if (
    allow-coordinate
      and type(attachment) == array
      and attachment.len() == 2
      and attachment.all(coordinate => type(coordinate) in (int, float))
  ) {
    return none
  }
  if type(attachment) == str {
    let parts = attachment.split(".")
    assert(
      parts.len() <= 2 and parts.all(part => part.len() > 0),
      message: (
        "typed-physics: "
          + source-description
          + " has malformed `"
          + argument
          + ":` "
          + _value(attachment)
          + "; write \"name\" or \"name.anchor\", for example \"beam.end\""
      ),
    )
    return none
  }
  if type(attachment) == dictionary {
    for key in attachment.keys() {
      assert(
        key in ("on", "at"),
        message: (
          "typed-physics: "
            + source-description
            + " has unknown `"
            + argument
            + ":` reference field \""
            + key
            + "\"; (on:, at:) references accept only `on:` and `at:`"
        ),
      )
    }
    assert(
      "on" in attachment,
      message: (
        "typed-physics: "
          + source-description
          + " needs `"
          + argument
          + ":` reference "
          + _value(attachment)
          + " to include `on:` an element name"
      ),
    )
    validate-simple-reference(attachment.on, source-description, argument + ".on")
    validate-ratio(
      attachment.at("at", default: 50%),
      source-description,
      argument + ".at",
    )
    return none
  }
  fail(
    source-description,
    argument,
    attachment,
    (
      "expected \"name\", \"name.anchor\", or (on: \"name\", at: 50%)"
        + if allow-coordinate { ", or an (x, y) numeric coordinate" } else { "" }
        + if allow-ratio { ", or a ratio between 0% and 100%" } else { "" }
        + if allow-auto { ", or auto" } else { "" }
        + if allow-none { ", or none" } else { "" }
    ),
    "use one of the supported attachment forms",
  )
}

#let attachment-element-name(attachment) = {
  if type(attachment) == dictionary { return attachment.on }
  if type(attachment) == str { return attachment.split(".").first() }
  none
}

#let attachment-anchor-name(attachment) = {
  if type(attachment) != str { return auto }
  let parts = attachment.split(".")
  if parts.len() == 2 { parts.at(1) } else { auto }
}

#let validate-style-dictionary(style, source-description) = {
  assert(
    type(style) == dictionary,
    message: (
      "typed-physics: "
        + source-description
        + " needs `style:` as a dictionary, got "
        + _value(style)
        + "; pass `style: (:)` or a style builder"
    ),
  )
  none
}

#let validate-paint(value, source-description, argument, allow-none: false) = {
  let paint-type = repr(type(value))
  let is-valid = (
    paint-type in ("color", "gradient", "pattern")
      or (allow-none and value == none)
  )
  if not is-valid {
    fail(
      source-description,
      argument,
      value,
      "expected a color, gradient, or pattern" + if allow-none { ", or none" } else { "" },
      "pass a Typst paint value such as rgb(\"#336699\")",
    )
  }
  none
}

#let validate-stroke(value, source-description, argument, allow-none: true) = {
  let value-type = type(value)
  let is-valid = (
    value-type in (length, color, dictionary, _stroke-type)
      or (allow-none and value == none)
  )
  if not is-valid {
    fail(
      source-description,
      argument,
      value,
      "expected a Typst stroke, length, color, or stroke dictionary",
      "pass a value such as `0.8pt + black`",
    )
  }
  if value-type == dictionary {
    let allowed-stroke-fields = (
      "paint", "thickness", "dash", "cap", "join", "miter-limit",
    )
    for field in value.keys() {
      assert(
        field in allowed-stroke-fields,
        message: (
          "typed-physics: "
            + source-description
            + " `"
            + argument
            + ":` stroke has unknown field \""
            + field
            + "\"; accepted fields are "
            + allowed-stroke-fields.join(", ")
        ),
      )
    }
    if "thickness" in value {
      assert(
        type(value.thickness) == length and value.thickness >= 0pt,
        message: "typed-physics: " + source-description + " `" + argument + ":` stroke thickness must be a non-negative length",
      )
    }
    if "paint" in value {
      validate-paint(
        value.paint,
        source-description + " " + argument + " stroke",
        "paint",
      )
    }
  }
  none
}

#let validate-element-style(style, allowed-keys, source-description) = {
  validate-style-dictionary(style, source-description)
  for key in style.keys() {
    assert(
      key in allowed-keys,
      message: (
        "typed-physics: "
          + source-description
          + " has unknown style key \""
          + key
          + "\"; accepted keys are "
          + allowed-keys.join(", ")
      ),
    )
  }
  for numeric-key in ("hatch-spacing", "hatch-length", "length") {
    if numeric-key in style {
      validate-positive-number(
        style.at(numeric-key),
        source-description + " style",
        numeric-key,
      )
    }
  }
  for text-key in ("label-text", "text") {
    if text-key in style {
      assert(
        type(style.at(text-key)) == dictionary,
        message: "typed-physics: " + source-description + " style `" + text-key + ":` must be a text-style dictionary",
      )
    }
  }
  for paint-key in ("fill", "color") {
    if paint-key in style {
      validate-paint(
        style.at(paint-key),
        source-description + " style",
        paint-key,
        allow-none: paint-key == "fill",
      )
    }
  }
  for stroke-key in ("stroke", "hatch-stroke") {
    if stroke-key in style {
      validate-stroke(
        style.at(stroke-key),
        source-description + " style",
        stroke-key,
      )
    }
  }
  none
}

// ── Situation schemas and references ────────────────────────────────────────

#let known-declaration-kinds = (
  "ground",
  "wall",
  "ceiling",
  "ramp",
  "arc",
  "body",
  "rod",
  "pivot",
  "support",
  "pendulum",
  "pulley",
  "rope",
  "spring",
  "force",
  "torque",
  "velocity",
  "angular-velocity",
)

#let _allowed-fields(kind) = if kind == "ground" {
  ("kind", "name", "length", "from", "friction", "style")
} else if kind == "wall" {
  ("kind", "name", "side", "height", "from", "friction", "style")
} else if kind == "ceiling" {
  ("kind", "name", "length", "height", "from", "friction", "style")
} else if kind == "ramp" {
  (
    "kind", "name", "angle", "length", "facing", "from", "friction",
    "symbol", "style",
  )
} else if kind == "arc" {
  (
    "kind", "name", "radius", "start-angle", "end-angle", "side", "from",
    "friction", "style",
  )
} else if kind == "body" {
  (
    "kind", "shape", "name", "mass", "on", "at", "touching", "side",
    "hanging", "drop", "half-extent-along", "half-extent-normal",
    "friction", "label", "symbol", "style", "radius-mark", "orientation",
    "solver-supported",
  )
} else if kind == "rod" {
  (
    "kind", "name", "from", "to", "length", "angle", "thickness", "mass",
    "center-of-mass", "label", "symbol", "style",
  )
} else if kind in ("pivot", "pulley") {
  ("kind", "name", "at", "radius", "style")
} else if kind == "support" {
  ("kind", "name", "at", "support-kind", "angle", "size", "style")
} else if kind == "pendulum" {
  (
    "kind", "name", "from", "length", "angle", "mass", "radius",
    "angle-label", "label", "symbol", "style",
  )
} else if kind in ("rope", "spring") {
  if kind == "rope" {
    ("kind", "name", "from", "to", "over", "style")
  } else {
    ("kind", "name", "from", "to", "coils", "width", "style")
  }
} else if kind == "force" {
  ("kind", "on", "magnitude", "angle", "at", "label", "style")
} else if kind == "torque" {
  (
    "kind", "on", "at", "magnitude", "direction", "radius", "label",
    "style",
  )
} else if kind == "velocity" {
  ("kind", "on", "magnitude", "angle", "label", "style")
} else {
  (
    "kind", "on", "magnitude", "direction", "radius", "start-angle",
    "end-angle", "label", "style",
  )
}

#let _required-fields(kind) = if kind == "ground" {
  ("name", "length", "from", "friction", "style")
} else if kind == "wall" {
  ("name", "side", "height", "from", "friction", "style")
} else if kind == "ceiling" {
  ("name", "length", "height", "from", "friction", "style")
} else if kind == "ramp" {
  ("name", "angle", "length", "facing", "from", "friction", "symbol", "style")
} else if kind == "arc" {
  (
    "name", "radius", "start-angle", "end-angle", "side", "from",
    "friction", "style",
  )
} else if kind == "body" {
  _allowed-fields(kind).filter(field => field != "kind")
} else if kind == "rod" {
  _allowed-fields(kind).filter(field => field != "kind")
} else if kind in ("pivot", "pulley", "support", "pendulum", "rope", "spring") {
  _allowed-fields(kind).filter(field => field != "kind")
} else {
  _allowed-fields(kind).filter(field => field != "kind")
}

#let _named-kind(kind) = kind in (
  "ground", "wall", "ceiling", "ramp", "arc", "body", "rod", "pivot",
  "support", "pendulum", "pulley", "rope", "spring",
)

#let _category-of-kind(kind) = if kind in (
  "ground", "wall", "ceiling", "ramp", "arc",
) {
  "surface"
} else if kind == "body" {
  "body"
} else if kind == "pulley" {
  "pulley"
} else if kind in ("rod", "pivot", "support", "pendulum") {
  "structure"
} else if kind in ("rope", "spring") {
  "connector"
} else {
  "annotation"
}

#let _default-anchor(kind) = if kind in (
  "ground", "wall", "ceiling", "ramp", "arc",
) {
  "surface"
} else {
  "center"
}

#let _anchors-for-kind(kind) = if kind in ("ground", "ceiling", "arc") {
  ("start", "end", "surface")
} else if kind == "wall" {
  ("start", "end", "surface")
} else if kind == "ramp" {
  ("start", "end", "surface", "foot", "apex", "base")
} else if kind == "body" {
  ("center", "contact", "top", "bottom", "left", "right")
} else if kind == "pulley" {
  ("center", "top", "bottom", "left", "right")
} else if kind == "rod" {
  ("start", "end", "center", "center-of-mass")
} else if kind == "pendulum" {
  ("pivot", "bob", "center")
} else if kind in ("pivot", "support") {
  ("center",)
} else if kind in ("rope", "spring") {
  ("start", "end", "center")
} else {
  ()
}

#let _validate-friction(friction, source-description) = {
  if friction == none { return }
  assert(
    type(friction) == dictionary,
    message: (
      "typed-physics: "
        + source-description
        + " has malformed friction data "
        + _value(friction)
        + "; use `mu: 0.3` or `mu: (s: 0.4, k: 0.3)`"
    ),
  )
  assert(
    friction.keys().sorted() == ("kinetic", "static"),
    message: (
      "typed-physics: "
        + source-description
        + " has malformed friction fields; constructors must produce `static:` and `kinetic:`"
    ),
  )
  validate-physical-scalar(
    friction.static,
    source-description,
    "mu.static",
    allow-zero: true,
  )
  validate-physical-scalar(
    friction.kinetic,
    source-description,
    "mu.kinetic",
    allow-zero: true,
  )
  if (
    type(friction.static) in (int, float)
      and type(friction.kinetic) in (int, float)
  ) {
    assert(
      friction.static >= friction.kinetic,
      message: (
        "typed-physics: "
          + source-description
          + " has static friction "
          + _value(friction.static)
          + " below kinetic friction "
          + _value(friction.kinetic)
          + "; use coefficients with static >= kinetic"
      ),
    )
  }
}

#let _validate-declaration-local(declaration, declaration-index) = {
  let kind = declaration.kind
  let source-description = if _named-kind(kind) {
    kind + " \"" + declaration.name + "\""
  } else {
    kind + "() declaration " + str(declaration-index + 1)
  }

  if _named-kind(kind) { validate-name(declaration.name, source-description: kind + "()") }
  if "style" in declaration {
    validate-style-dictionary(declaration.style, source-description)
    let allowed-style-keys = if kind in (
      "ground", "wall", "ceiling", "ramp", "arc",
    ) {
      ("fill", "stroke", "hatch-stroke", "hatch-spacing", "hatch-length")
    } else if kind in ("pivot", "support", "rope", "spring") {
      ("stroke", "fill")
    } else if kind in (
      "force", "torque", "velocity", "angular-velocity",
    ) {
      ("color", "stroke", "length", "text")
    } else {
      ("fill", "stroke", "label-text")
    }
    validate-element-style(
      declaration.style,
      allowed-style-keys,
      source-description,
    )
  }
  if "friction" in declaration {
    _validate-friction(declaration.friction, source-description)
  }

  if kind == "ground" {
    validate-positive-number(declaration.length, source-description, "length")
    validate-attachment(declaration.from, source-description, "from", allow-none: true)
  } else if kind == "wall" {
    validate-positive-number(declaration.height, source-description, "height")
    validate-enum(declaration.side, ("left", "right"), source-description, "side")
    validate-attachment(declaration.from, source-description, "from", allow-none: true)
  } else if kind == "ceiling" {
    validate-positive-number(declaration.length, source-description, "length")
    validate-positive-number(declaration.height, source-description, "height")
    validate-attachment(declaration.from, source-description, "from", allow-none: true)
  } else if kind == "ramp" {
    validate-positive-number(declaration.length, source-description, "length")
    validate-angle(declaration.angle, source-description, "angle")
    assert(
      declaration.angle > 0deg and declaration.angle < 90deg,
      message: (
        "typed-physics: "
          + source-description
          + " has `angle:` "
          + _value(declaration.angle)
          + "; use an incline strictly between 0deg and 90deg"
      ),
    )
    validate-enum(declaration.facing, ("left", "right"), source-description, "facing")
    validate-attachment(declaration.from, source-description, "from", allow-none: true)
  } else if kind == "arc" {
    validate-positive-number(declaration.radius, source-description, "radius")
    validate-angle(declaration.start-angle, source-description, "start-angle")
    validate-angle(declaration.end-angle, source-description, "end-angle")
    assert(
      declaration.end-angle != declaration.start-angle
        and calc.abs((declaration.end-angle - declaration.start-angle).deg()) <= 360,
      message: (
        "typed-physics: "
          + source-description
          + " needs distinct arc angles spanning at most 360deg; adjust `start-angle:` or `end-angle:`"
      ),
    )
    validate-enum(declaration.side, ("inside", "outside"), source-description, "side")
    validate-attachment(declaration.from, source-description, "from", allow-none: true)
  } else if kind == "body" {
    validate-enum(
      declaration.shape,
      ("block", "ball", "point", "disk", "ring"),
      source-description,
      "shape",
    )
    validate-physical-scalar(
      declaration.mass,
      source-description,
      "mass",
      allow-none: true,
    )
    validate-ratio(declaration.at, source-description, "at")
    validate-positive-number(
      declaration.half-extent-along,
      source-description,
      "size",
    )
    validate-positive-number(
      declaration.half-extent-normal,
      source-description,
      "size",
    )
    validate-nonnegative-number(declaration.drop, source-description, "drop")
    validate-angle(declaration.orientation, source-description, "orientation")
    validate-boolean(declaration.radius-mark, source-description, "radius-mark")
    assert(
      (
        (
          declaration.hanging != none
            and declaration.on == none
            and declaration.touching == none
        )
          or (
            declaration.hanging == none
              and (
                declaration.on != none
                  or declaration.touching != none
              )
          )
      ),
      message: (
        "typed-physics: "
          + source-description
          + " needs `on:` or `touching:`, or it may use `hanging:` by itself; remove placement arguments that conflict with `hanging:`"
      ),
    )
    assert(
      declaration.touching == none or declaration.at == 50%,
      message: (
        "typed-physics: "
          + source-description
          + " uses `touching:`, so `at:` would be ignored; remove `at:` and use `side:` to choose the neighbour"
      ),
    )
    assert(
      declaration.hanging == none or declaration.at == 50%,
      message: (
        "typed-physics: "
          + source-description
          + " uses `hanging:`, so `at:` would be ignored; remove `at:` and select the attachment point through `hanging:`"
      ),
    )
    assert(
      declaration.touching != none
        or declaration.side == "right",
      message: (
        "typed-physics: "
          + source-description
          + " has `side:` "
          + _value(declaration.side)
          + " without `touching:`; remove `side:` or add a neighbouring body"
      ),
    )
    assert(
      declaration.hanging != none
        or declaration.drop == 1.5,
      message: (
        "typed-physics: "
          + source-description
          + " has `drop:` "
          + _value(declaration.drop)
          + " without `hanging:`; remove `drop:` or place the body from an attachment"
      ),
    )
    assert(
      declaration.hanging == none or declaration.friction == none,
      message: (
        "typed-physics: "
          + source-description
          + " is hanging and cannot use `mu:` because it has no surface contact; remove the friction coefficient"
      ),
    )
    if declaration.on != none {
      validate-simple-reference(declaration.on, source-description, "on")
    }
    if declaration.touching != none {
      validate-simple-reference(declaration.touching, source-description, "touching")
    }
    if declaration.hanging != none {
      validate-attachment(declaration.hanging, source-description, "hanging")
      assert(
        declaration.drop > 0,
        message: (
          "typed-physics: "
            + source-description
            + " is hanging but has `drop:` "
            + _value(declaration.drop)
            + "; use a positive drop so the body is below its attachment"
        ),
      )
    }
  } else if kind == "rod" {
    validate-positive-number(declaration.length, source-description, "length")
    validate-positive-number(declaration.thickness, source-description, "thickness")
    validate-angle(declaration.angle, source-description, "angle")
    validate-ratio(declaration.center-of-mass, source-description, "center-of-mass")
    validate-physical-scalar(
      declaration.mass,
      source-description,
      "mass",
      allow-none: true,
    )
    validate-attachment(declaration.from, source-description, "from", allow-none: true)
    validate-attachment(declaration.to, source-description, "to", allow-none: true)
  } else if kind in ("pivot", "pulley") {
    validate-attachment(declaration.at, source-description, "at")
    validate-positive-number(declaration.radius, source-description, "radius")
  } else if kind == "support" {
    validate-attachment(declaration.at, source-description, "at")
    validate-enum(
      declaration.support-kind,
      ("pin", "roller", "fixed"),
      source-description,
      "kind",
    )
    validate-angle(declaration.angle, source-description, "angle")
    validate-positive-number(declaration.size, source-description, "size")
  } else if kind == "pendulum" {
    validate-attachment(declaration.from, source-description, "from")
    validate-positive-number(declaration.length, source-description, "length")
    validate-positive-number(declaration.radius, source-description, "radius")
    assert(
      declaration.radius < declaration.length,
      message: "typed-physics: " + source-description + " needs `radius:` smaller than `length:` so the bob does not cover its pivot",
    )
    validate-angle(declaration.angle, source-description, "angle")
    validate-physical-scalar(
      declaration.mass,
      source-description,
      "mass",
      allow-none: true,
    )
  } else if kind in ("rope", "spring") {
    validate-attachment(declaration.from, source-description, "from")
    validate-attachment(declaration.to, source-description, "to")
    if kind == "spring" {
      validate-positive-integer(declaration.coils, source-description, "coils")
      validate-positive-number(declaration.width, source-description, "width")
    } else if declaration.over != none {
      validate-simple-reference(declaration.over, source-description, "over")
    }
  } else if kind == "force" {
    validate-simple-reference(declaration.on, source-description, "on")
    validate-physical-scalar(declaration.magnitude, source-description, "magnitude")
    validate-angle(declaration.angle, source-description, "angle")
    validate-attachment(
      declaration.at,
      source-description,
      "at",
      allow-auto: true,
      allow-ratio: true,
    )
  } else if kind == "torque" {
    validate-simple-reference(declaration.on, source-description, "on")
    validate-physical-scalar(
      declaration.magnitude,
      source-description,
      "magnitude",
      allow-none: true,
    )
    validate-attachment(
      declaration.at,
      source-description,
      "at",
      allow-auto: true,
      allow-ratio: true,
    )
    validate-enum(
      declaration.direction,
      ("clockwise", "counterclockwise"),
      source-description,
      "direction",
    )
    validate-positive-number(declaration.radius, source-description, "radius")
  } else if kind == "velocity" {
    validate-simple-reference(declaration.on, source-description, "on")
    validate-physical-scalar(
      declaration.magnitude,
      source-description,
      "magnitude",
      allow-none: true,
      allow-zero: true,
    )
    validate-angle(declaration.angle, source-description, "angle")
  } else if kind == "angular-velocity" {
    validate-simple-reference(declaration.on, source-description, "on")
    validate-physical-scalar(
      declaration.magnitude,
      source-description,
      "magnitude",
      allow-none: true,
      allow-zero: true,
    )
    validate-enum(
      declaration.direction,
      ("clockwise", "counterclockwise"),
      source-description,
      "direction",
    )
    if declaration.radius != auto {
      validate-positive-number(declaration.radius, source-description, "radius")
    }
    validate-angle(
      declaration.start-angle,
      source-description,
      "start-angle",
      allow-auto: true,
    )
    validate-angle(
      declaration.end-angle,
      source-description,
      "end-angle",
      allow-auto: true,
    )
  }
}

#let _reference-specifications(declaration) = {
  let kind = declaration.kind
  let source-description = if _named-kind(kind) {
    kind + " \"" + declaration.name + "\""
  } else {
    kind + "()"
  }
  let specifications = ()
  let declared-reference(
    argument,
    attachment,
    categories,
    ratio-categories: ("surface", "structure"),
  ) = {
    if attachment == none or attachment == auto { return () }
    ((
      argument: argument,
      attachment: attachment,
      categories: categories,
      ratio-categories: ratio-categories,
      source-description: source-description,
    ),)
  }
  if kind in ("ground", "wall", "ceiling", "ramp", "arc") {
    specifications += declared-reference(
      "from",
      declaration.from,
      ("surface",),
      ratio-categories: ("surface",),
    )
  } else if kind == "body" {
    specifications += declared-reference(
      "on",
      declaration.on,
      ("surface",),
      ratio-categories: (),
    )
    specifications += declared-reference(
      "touching",
      declaration.touching,
      ("body",),
      ratio-categories: (),
    )
    specifications += declared-reference(
      "hanging",
      declaration.hanging,
      ("surface", "body", "pulley"),
    )
  } else if kind == "rod" {
    specifications += declared-reference(
      "from",
      declaration.from,
      ("surface", "body", "pulley", "structure"),
    )
    specifications += declared-reference(
      "to",
      declaration.to,
      ("surface", "body", "pulley", "structure"),
    )
  } else if kind in ("pivot", "support", "pendulum") {
    specifications += declared-reference(
      if kind == "pendulum" { "from" } else { "at" },
      if kind == "pendulum" { declaration.from } else { declaration.at },
      ("surface", "body", "pulley", "structure"),
    )
  } else if kind == "pulley" {
    specifications += declared-reference(
      "at",
      declaration.at,
      ("surface", "pulley"),
    )
  } else if kind in ("rope", "spring") {
    specifications += declared-reference(
      "from",
      declaration.from,
      ("surface", "body", "pulley", "structure"),
    )
    specifications += declared-reference(
      "to",
      declaration.to,
      ("surface", "body", "pulley", "structure"),
    )
    if kind == "rope" {
      specifications += declared-reference(
        "over",
        declaration.over,
        ("pulley",),
        ratio-categories: (),
      )
    }
  } else if kind in ("force", "torque", "velocity", "angular-velocity") {
    specifications += declared-reference(
      "on",
      declaration.on,
      if kind in ("force", "torque") { ("body", "structure") } else {
        ("body",)
      },
      ratio-categories: (),
    )
  }
  specifications
}

#let _validate-reference(
  specification,
  declaration-index,
  declarations-by-name,
  declaration-index-by-name,
) = {
  let attachment = specification.attachment
  let target-name = attachment-element-name(attachment)
  assert(
    target-name in declarations-by-name,
    message: (
      "typed-physics: "
        + specification.source-description
        + " has `"
        + specification.argument
        + ":` "
        + _value(attachment)
        + ", but there is no element called \""
        + target-name
        + "\"; available names are "
        + declarations-by-name.keys().sorted().join(", ")
    ),
  )
  let target = declarations-by-name.at(target-name)
  let target-category = _category-of-kind(target.kind)
  assert(
    target-category in specification.categories,
    message: (
      "typed-physics: "
        + specification.source-description
        + " has `"
        + specification.argument
        + ":` "
        + _value(attachment)
        + ", but \""
        + target-name
        + "\" is a "
        + target-category
        + "; compatible element types are "
        + specification.categories.join(", ")
    ),
  )
  if type(attachment) == dictionary {
    assert(
      target-category in specification.ratio-categories,
      message: (
        "typed-physics: "
          + specification.source-description
          + " cannot use an (on:, at:) reference along "
          + target.kind
          + " \""
          + target-name
          + "\"; use a named anchor such as \""
          + target-name
          + "."
          + _anchors-for-kind(target.kind).first()
          + "\""
      ),
    )
  } else {
    let declared-anchor = attachment-anchor-name(attachment)
    let requested-anchor = if declared-anchor == auto {
      _default-anchor(target.kind)
    } else {
      declared-anchor
    }
    let available-anchors = _anchors-for-kind(target.kind)
    assert(
      requested-anchor in available-anchors,
      message: (
        "typed-physics: "
          + specification.source-description
          + " references unavailable anchor \""
          + target-name
          + "."
          + requested-anchor
          + "\"; "
          + target.kind
          + " \""
          + target-name
          + "\" has anchors "
          + available-anchors.join(", ")
      ),
    )
  }
  assert(
    declaration-index-by-name.at(target-name) < declaration-index,
    message: (
      "typed-physics: "
        + specification.source-description
        + " references \""
        + target-name
        + "\" before it is available; move "
        + target.kind
        + " \""
        + target-name
        + "\" before this declaration"
    ),
  )
}

#let _dependency-reaches(
  element-name,
  target-name,
  declarations-by-name,
  visited: (),
) = {
  if element-name == target-name { return true }
  if element-name in visited or element-name not in declarations-by-name {
    return false
  }
  let next-visited = visited + (element-name,)
  for specification in _reference-specifications(
    declarations-by-name.at(element-name),
  ) {
    let dependency-name = attachment-element-name(specification.attachment)
    if _dependency-reaches(
      dependency-name,
      target-name,
      declarations-by-name,
      visited: next-visited,
    ) {
      return true
    }
  }
  false
}

#let _declared-body-support(body-declaration, declarations-by-name) = {
  if body-declaration.on != none { return body-declaration.on }
  if (
    body-declaration.touching == none
      or body-declaration.touching not in declarations-by-name
  ) {
    return none
  }
  let neighbouring-declaration = declarations-by-name.at(
    body-declaration.touching,
  )
  if neighbouring-declaration.kind != "body" { return none }
  _declared-body-support(neighbouring-declaration, declarations-by-name)
}

#let _validate-cross-element-compatibility(
  declaration,
  declarations-by-name,
) = {
  let kind = declaration.kind
  if kind == "body" and declaration.touching != none {
    let neighbouring-body = declarations-by-name.at(declaration.touching)
    let neighbouring-support = _declared-body-support(
      neighbouring-body,
      declarations-by-name,
    )
    assert(
      neighbouring-support != none,
      message: (
        "typed-physics: body \""
          + declaration.name
          + "\" touches \""
          + declaration.touching
          + "\", which does not rest on a surface; choose a supported neighbouring body"
      ),
    )
    if declaration.on != none {
      assert(
        neighbouring-support != none and declaration.on == neighbouring-support,
        message: (
          "typed-physics: body \""
            + declaration.name
            + "\" says `on: \""
            + declaration.on
            + "\"` but touches \""
            + declaration.touching
            + "\", which rests on "
            + if neighbouring-support == none { "no surface" } else {
              "\"" + neighbouring-support + "\""
            }
            + "; use the same supporting surface or remove `on:`"
        ),
      )
    }
  }

  if (
    kind in ("ground", "ceiling", "ramp", "arc")
      and declaration.from != none
  ) {
    let source-surface = declarations-by-name.at(
      attachment-element-name(declaration.from),
    )
    assert(
      source-surface.kind != "wall",
      message: (
        "typed-physics: "
          + kind
          + " \""
          + declaration.name
          + "\" cannot continue `from:` wall \""
          + source-surface.name
          + "\" because default wall placement is resolved after spanning surfaces; attach the wall to this surface instead"
      ),
    )
  }

  if kind in ("force", "torque") {
    let target = declarations-by-name.at(declaration.on)
    assert(
      target.kind == "body" or target.kind == "rod",
      message: (
        "typed-physics: "
          + kind
          + "() targets "
          + target.kind
          + " \""
          + declaration.on
          + "\", which cannot accept an applied "
          + kind
          + "; target a body or rod"
      ),
    )
    if target.kind == "body" {
      assert(
        declaration.at == auto,
        message: (
          "typed-physics: "
            + kind
            + "() on body \""
            + declaration.on
            + "\" has `at:` "
            + _value(declaration.at)
            + ", but body loads currently act at the center; use `at: auto` so the application point is not ignored"
        ),
      )
    } else if declaration.at != auto and type(declaration.at) != ratio {
      let application-element = attachment-element-name(declaration.at)
      assert(
        application-element == declaration.on,
        message: (
          "typed-physics: "
            + kind
            + "() on rod \""
            + declaration.on
            + "\" applies at "
            + _value(declaration.at)
            + ", which belongs to another element; use a ratio or an anchor on \""
            + declaration.on
            + "\""
        ),
      )
    }
  }
}

#let validate-situation-declarations(declarations, gravity) = {
  assert(
    type(declarations) == array and declarations.len() > 0,
    message: (
      "typed-physics: situation() needs at least one element declaration; "
        + "add a surface, body, connector, or structure"
    ),
  )
  validate-physical-scalar(gravity, "situation()", "gravity")

  let declarations-by-name = (:)
  let declaration-index-by-name = (:)
  for (declaration-index, declaration) in declarations.enumerate() {
    assert(
      type(declaration) == dictionary,
      message: (
        "typed-physics: situation() declaration "
          + str(declaration-index + 1)
          + " is "
          + _value(declaration)
          + ", not an element dictionary; pass a value returned by ground(), block(), force(), or another public constructor"
      ),
    )
    assert(
      "kind" in declaration and type(declaration.kind) == str,
      message: (
        "typed-physics: situation() declaration "
          + str(declaration-index + 1)
          + " needs a string `kind:`; use a public element constructor instead of a hand-written dictionary"
      ),
    )
    assert(
      declaration.kind in known-declaration-kinds,
      message: (
        "typed-physics: situation() declaration "
          + str(declaration-index + 1)
          + " has unknown kind "
          + _value(declaration.kind)
          + "; accepted declaration kinds are "
          + known-declaration-kinds.join(", ")
          + ". Use the matching public constructor"
      ),
    )
    let allowed-fields = _allowed-fields(declaration.kind)
    for field in declaration.keys() {
      assert(
        field in allowed-fields,
        message: (
          "typed-physics: "
            + declaration.kind
            + " declaration "
            + str(declaration-index + 1)
            + " has unknown field `"
            + field
            + ":`; accepted fields are "
            + allowed-fields.join(", ")
            + ". Use the public constructor to catch misspelled arguments"
        ),
      )
    }
    let missing-fields = _required-fields(declaration.kind).filter(
      field => field not in declaration,
    )
    assert(
      missing-fields.len() == 0,
      message: (
        "typed-physics: malformed "
          + declaration.kind
          + " declaration "
          + str(declaration-index + 1)
          + " is missing "
          + missing-fields.map(field => "`" + field + ":`").join(", ")
          + "; create it with the public "
          + declaration.kind
          + "() constructor"
      ),
    )
    _validate-declaration-local(declaration, declaration-index)
    if _named-kind(declaration.kind) {
      assert(
        declaration.name not in declarations-by-name,
        message: (
          "typed-physics: element name \""
            + declaration.name
            + "\" is declared twice (declarations "
            + str(declaration-index-by-name.at(declaration.name, default: -1) + 1)
            + " and "
            + str(declaration-index + 1)
            + "); rename one element so every reference is unambiguous"
        ),
      )
      declarations-by-name.insert(declaration.name, declaration)
      declaration-index-by-name.insert(declaration.name, declaration-index)
    }
  }

  for (declaration-index, declaration) in declarations.enumerate() {
    for specification in _reference-specifications(declaration) {
      let target-name = attachment-element-name(specification.attachment)
      if _named-kind(declaration.kind) and target-name == declaration.name {
        panic(
          "typed-physics: "
            + specification.source-description
            + " creates a placement dependency cycle by referencing itself in `"
            + specification.argument
            + ":`; reference an earlier, different element",
        )
      }
      if (
        _named-kind(declaration.kind)
          and target-name in declarations-by-name
          and _dependency-reaches(
            target-name,
            declaration.name,
            declarations-by-name,
          )
      ) {
        panic(
          "typed-physics: placement dependency cycle connects \""
            + declaration.name
            + "\" and \""
            + target-name
            + "\"; break the cycle by anchoring one element to an earlier independent element",
        )
      }
      _validate-reference(
        specification,
        declaration-index,
        declarations-by-name,
        declaration-index-by-name,
      )
    }
    _validate-cross-element-compatibility(
      declaration,
      declarations-by-name,
    )
  }
}

#let validate-body-name(scene, name, source-description) = {
  assert(
    type(name) == str,
    message: (
      "typed-physics: "
        + source-description
        + " needs a body name as a string, got "
        + _value(name)
    ),
  )
  assert(
    name in scene.bodies,
    message: (
      "typed-physics: "
        + source-description
        + " names \""
        + name
        + "\", but no such body exists; available bodies are "
        + if scene.body-order.len() == 0 { "(none)" } else {
          scene.body-order.join(", ")
        }
    ),
  )
  none
}

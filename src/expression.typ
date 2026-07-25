// A small expression tree: enough algebra to state a mechanics result in
// closed form, show it with the declared numbers substituted, and evaluate it.
//
// The load-bearing idea is `quantity`, which carries both the symbol it prints
// as and the number it stands for. One tree therefore renders three ways —
// `g sin theta`, `9.81 sin 30°`, `4.91` — without being built three times.

// ── Number formatting ────────────────────────────────────────────────────────

// Rounds to `digits` significant figures and keeps the trailing zeros, so
// results read like textbook answers: 34.0, 2.36, 0.289.
#let format-number(value, digits: 3) = {
  if value == none { return "?" }
  let size = calc.abs(value)
  let decimals = if size == 0 {
    2
  } else {
    calc.clamp(digits - 1 - int(calc.floor(calc.log(size, base: 10))), 0, 6)
  }
  let rounded = calc.round(value, digits: decimals)
  if decimals == 0 { return str(calc.round(rounded)) }
  let parts = str(rounded).split(".")
  let whole = parts.at(0)
  let fraction = if parts.len() > 1 { parts.at(1) } else { "" }
  while fraction.len() < decimals { fraction += "0" }
  whole + "." + fraction
}

#let format-angle(degrees) = {
  let rounded = calc.round(degrees, digits: 1)
  let shown = if rounded == calc.round(rounded) { str(calc.round(rounded)) } else { str(rounded) }
  shown + "°"
}

// ── Leaves ───────────────────────────────────────────────────────────────────

#let number(value) = (kind: "number", value: float(value))

// `substituted` overrides what the numeric rendering prints, which is how an
// angle stored in radians still shows up as `30°`.
#let quantity(symbol, value: none, substituted: auto) = (
  kind: "quantity",
  symbol: symbol,
  value: if value == none { none } else { float(value) },
  substituted: substituted,
)

// Turns a declared property into a quantity. A number keeps the symbol the
// package would print for it; content the author wrote replaces that symbol,
// which is how `mass: $m$` stays symbolic all the way to the answer.
#let declared(value, symbol) = {
  if value == none { return none }
  if type(value) in (int, float) { return quantity(symbol, value: value) }
  quantity(value)
}

#let declared-angle(value, symbol) = quantity(
  symbol,
  value: value.rad(),
  substituted: [#format-angle(value.deg())],
)

#let is-number(term) = term.kind == "number"
#let is-zero(term) = is-number(term) and term.value == 0
#let is-one(term) = is-number(term) and term.value == 1

// ── Building terms ───────────────────────────────────────────────────────────
//
// The constructors fold plain numbers and drop identities as they build, so a
// caller can assemble the general form of an equation and let the terms that
// do not apply to this particular situation disappear on their own.

#let negated(term) = {
  if is-number(term) { return number(-term.value) }
  if term.kind == "negated" { return term.term }
  (kind: "negated", term: term)
}

#let sum(..parts) = {
  let terms = ()
  let constant = 0.0
  for part in parts.pos() {
    let pieces = if part.kind == "sum" { part.terms } else { (part,) }
    for piece in pieces {
      if is-number(piece) { constant += piece.value } else { terms.push(piece) }
    }
  }
  if constant != 0 { terms.push(number(constant)) }
  if terms.len() == 0 { return number(0) }
  if terms.len() == 1 { return terms.first() }
  (kind: "sum", terms: terms)
}

#let difference(left, right) = sum(left, negated(right))

#let product(..parts) = {
  let factors = ()
  let constant = 1.0
  for part in parts.pos() {
    let piece = part
    if piece.kind == "negated" {
      constant *= -1
      piece = piece.term
    }
    let pieces = if piece.kind == "product" { piece.factors } else { (piece,) }
    for factor in pieces {
      if is-number(factor) { constant *= factor.value } else { factors.push(factor) }
    }
  }
  if constant == 0 { return number(0) }
  if factors.len() == 0 { return number(constant) }
  let signed = constant < 0
  if calc.abs(constant) != 1 { factors.insert(0, number(calc.abs(constant))) }
  let combined = if factors.len() == 1 { factors.first() } else { (kind: "product", factors: factors) }
  if signed { negated(combined) } else { combined }
}

// Divides `term` by `factor` when every one of its terms visibly contains that
// factor. Returning `none` when it does not is what keeps `ratio` from
// inventing a cancellation that is not there.
#let without-factor(term, factor) = {
  if term == factor { return number(1) }
  if term.kind == "negated" {
    let inner = without-factor(term.term, factor)
    return if inner == none { none } else { negated(inner) }
  }
  if term.kind == "sum" {
    let divided = ()
    for piece in term.terms {
      let quotient = without-factor(piece, factor)
      if quotient == none { return none }
      divided.push(quotient)
    }
    return sum(..divided)
  }
  if term.kind == "product" and term.factors.contains(factor) {
    let remaining = term.factors.filter(each => each != factor)
    return product(..remaining)
  }
  none
}

#let ratio(numerator, denominator) = {
  assert(not is-zero(denominator), message: "typed-physics: division by zero while building an expression")
  if is-one(denominator) { return numerator }
  if is-number(numerator) and is-number(denominator) {
    return number(numerator.value / denominator.value)
  }
  let cancelled = without-factor(numerator, denominator)
  if cancelled != none { return cancelled }
  (kind: "ratio", numerator: numerator, denominator: denominator)
}

#let power(base, exponent) = {
  if is-one(exponent) { return base }
  (kind: "power", base: base, exponent: exponent)
}

#let applied(name, argument) = {
  if is-number(argument) {
    let value = if name == "sin" {
      calc.sin(argument.value)
    } else if name == "cos" {
      calc.cos(argument.value)
    } else {
      calc.tan(argument.value)
    }
    return number(value)
  }
  (kind: "function", name: name, argument: argument)
}

#let sine(argument) = applied("sin", argument)
#let cosine(argument) = applied("cos", argument)
#let tangent(argument) = applied("tan", argument)

// ── Evaluating ───────────────────────────────────────────────────────────────

// The value of a tree, or `none` as soon as any leaf in it is a symbol without
// a declared number. Callers use that `none` to decide whether a question is
// answerable at all rather than to print a wrong number.
#let value-of(term) = {
  let kind = term.kind
  if kind == "number" or kind == "quantity" { return term.value }
  if kind == "negated" {
    let inner = value-of(term.term)
    return if inner == none { none } else { -inner }
  }
  if kind == "sum" {
    let total = 0.0
    for piece in term.terms {
      let value = value-of(piece)
      if value == none { return none }
      total += value
    }
    return total
  }
  if kind == "product" {
    let total = 1.0
    for factor in term.factors {
      let value = value-of(factor)
      if value == none { return none }
      total *= value
    }
    return total
  }
  if kind == "ratio" {
    let top = value-of(term.numerator)
    let bottom = value-of(term.denominator)
    if top == none or bottom == none or bottom == 0 { return none }
    return top / bottom
  }
  if kind == "power" {
    let base = value-of(term.base)
    let exponent = value-of(term.exponent)
    if base == none or exponent == none { return none }
    return calc.pow(base, exponent)
  }
  if kind == "function" {
    let argument = value-of(term.argument)
    if argument == none { return none }
    if term.name == "sin" { return calc.sin(argument) }
    if term.name == "cos" { return calc.cos(argument) }
    return calc.tan(argument)
  }
  none
}

#let is-known(term) = value-of(term) != none

// The magnitude of a term, kept in symbolic form: a negative expression comes
// back negated rather than wrapped in an absolute-value bar that no one would
// write by hand. A term whose value is not known yet is judged by its shape,
// which is enough whenever the sign was built in rather than computed.
#let magnitude-of(term) = {
  let value = value-of(term)
  if value != none { return if value < 0 { negated(term) } else { term } }
  if term.kind == "negated" { return term.term }
  term
}

// ── Rendering ────────────────────────────────────────────────────────────────

#let _binding-strength(term) = {
  let kind = term.kind
  if kind == "sum" { 1 } else if kind == "negated" { 1 } else if kind == "product" { 2 } else if kind == "function" {
    3
  } else { 4 }
}

// Renders as math content. `substitute: true` prints every quantity as the
// number it stands for, which is the middle line of a worked solution.
#let math-of(term, substitute: false) = {
  let render(part) = math-of(part, substitute: substitute)
  let grouped(part, strength) = {
    let inner = render(part)
    if _binding-strength(part) < strength { $(inner)$ } else { inner }
  }
  let kind = term.kind

  if kind == "number" { return $#format-number(term.value)$ }

  if kind == "quantity" {
    if not substitute { return term.symbol }
    if term.substituted != auto { return term.substituted }
    return $#format-number(term.value)$
  }

  if kind == "negated" { return $-#grouped(term.term, 2)$ }

  if kind == "sum" {
    let rendered = ()
    for piece in term.terms {
      if piece.kind == "negated" {
        rendered.push($- #grouped(piece.term, 2)$)
      } else if rendered.len() == 0 {
        rendered.push(render(piece))
      } else {
        rendered.push($+ #render(piece)$)
      }
    }
    return rendered.join($ $)
  }

  // Symbols sit next to each other the way they are written by hand, but two
  // numbers next to each other need the dot to stay readable.
  if kind == "product" {
    let shows-a-number(factor) = {
      if factor.kind == "number" { return true }
      factor.kind == "quantity" and substitute and factor.substituted == auto
    }
    let rendered = ()
    for (index, factor) in term.factors.enumerate() {
      let piece = grouped(factor, 2)
      if index == 0 {
        rendered.push(piece)
      } else if shows-a-number(term.factors.at(index - 1)) and shows-a-number(factor) {
        rendered.push($dot.op #piece$)
      } else {
        rendered.push($thin #piece$)
      }
    }
    return rendered.join()
  }

  if kind == "ratio" {
    return $(#render(term.numerator)) / (#render(term.denominator))$
  }

  if kind == "power" {
    return $#grouped(term.base, 4)^#render(term.exponent)$
  }

  if kind == "function" {
    let name = if term.name == "sin" { $sin$ } else if term.name == "cos" { $cos$ } else { $tan$ }
    return $#name #grouped(term.argument, 3)$
  }

  panic("typed-physics: cannot render expression of kind " + repr(kind))
}

#let numeric-math-of(term, digits: 3) = {
  let value = value-of(term)
  if value == none { return none }
  $#format-number(value, digits: digits)$
}

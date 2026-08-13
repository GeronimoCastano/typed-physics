#import "../../src/lib.typ": *

#let symbolic = situation(
  ramp("incline", angle: 30deg, length: 6),
  block(
    "A",
    mass: $m$,
    on: "incline",
    mu: (s: $mu_s$, k: $mu_k$),
  ),
)
#let symbolic-result = results(symbolic)
#assert(symbolic-result.status == "undetermined")

#let numeric = situation(
  ramp("incline", angle: 30deg, length: 6),
  block("A", mass: 4, on: "incline", mu: 0.2),
)
#let numeric-result = results(numeric)
#assert(numeric-result.status == "solved")

#let multiple = situation(
  ground(length: 8),
  block("A", mass: 2, on: "ground", at: 30%),
  block("B", mass: 3, on: "ground", at: 70%),
)
#assert(results(multiple, "A").status == "solved")
#assert(results(multiple, "B").status == "solved")

#let drawing-only = situation(
  ground(length: 6),
  disk("D", on: "ground"),
)
#scene(drawing-only)

#let circuit = electricity.dc-circuit(
  electricity.voltage-source("V", voltage: 12),
  electricity.series(
    electricity.resistor("R1", resistance: 4),
    electricity.parallel(
      electricity.resistor("R2", resistance: 6),
      electricity.resistor("R3", resistance: 3),
    ),
  ),
)
#electricity.diagram(circuit)

#let stacked-circuit = electricity.dc-circuit(
  electricity.voltage-source("source", voltage: $V$),
  electricity.parallel(
    electricity.capacitor("direct", capacitance: $C_1$),
    electricity.series(
      electricity.resistor("left", resistance: $R_2$),
      electricity.resistor("right", resistance: $R_3$),
    ),
  ),
)
#electricity.diagram(stacked-circuit)

#let level-frame-circuit = electricity.dc-circuit(
  electricity.voltage-source("level-source", voltage: $V$),
  electricity.parallel(
    electricity.capacitor("level-direct", capacitance: $C_1$, route: "direct"),
    electricity.series(
      electricity.resistor("level-left", resistance: $R_2$),
      electricity.resistor("level-right", resistance: $R_3$),
      route: "over",
    ),
  ),
)

#let under-frame-circuit = electricity.dc-circuit(
  electricity.voltage-source("under-source", voltage: 9),
  electricity.parallel(
    electricity.resistor("under-direct", resistance: 10, route: "direct"),
    electricity.resistor("under-single", resistance: 20, route: "under"),
  ),
)
#electricity.diagram(under-frame-circuit, labels: "value")

#let unit-and-symbol-circuit = electricity.dc-circuit(
  electricity.voltage-source(
    "micro-source",
    voltage: 500,
    unit: "µV",
    style: electricity.voltage-source-style(symbol: "circle"),
  ),
  electricity.series(
    electricity.resistor("zigzag", resistance: 4, unit: "mΩ"),
    electricity.resistor(
      "rectangle",
      resistance: 8,
      unit: $mu Omega$,
      style: electricity.resistor-style(symbol: "rectangle"),
    ),
  ),
)
#electricity.diagram(unit-and-symbol-circuit)
#electricity.diagram(level-frame-circuit)

#let capacitor-circuit = electricity.dc-circuit(
  electricity.voltage-source("capacitor-source", voltage: 5),
  electricity.series(
    electricity.capacitor(
      "coupling",
      capacitance: 4.7,
      unit: "µF",
      style: electricity.capacitor-style(stroke: 1.2pt + blue),
    ),
    electricity.parallel(
      electricity.resistor("capacitor-load", resistance: 10),
      electricity.capacitor(
        "storage",
        capacitance: $C$,
        unit: $mu F$,
      ),
    ),
  ),
)
#electricity.diagram(capacitor-circuit)

#let capacitor-diagonal-circuit = electricity.dc-circuit(
  electricity.voltage-source("capacitor-diagonal-source", voltage: 9),
  electricity.parallel(
    electricity.capacitor("vertical-capacitor", capacitance: 1, route: "under"),
    electricity.resistor("diagonal-resistor", resistance: 2, route: "direct"),
    electricity.series(
      electricity.capacitor("upper-capacitor", capacitance: 3),
      electricity.resistor("right-resistor", resistance: 4),
      route: "over",
    ),
  ),
)
#electricity.diagram(capacitor-diagonal-circuit)

#let diagonal-circuit = electricity.dc-circuit(
  electricity.voltage-source("diagonal-source", voltage: 18),
  electricity.parallel(
    electricity.resistor("vertical-branch", resistance: 300, route: "under"),
    electricity.resistor("diagonal-branch", resistance: 200, route: "direct"),
    electricity.series(
      electricity.resistor("upper-branch", resistance: 50),
      electricity.resistor("right-branch", resistance: 250),
      route: "over",
    ),
  ),
)
#electricity.diagram(diagonal-circuit)

#let diagonal-folded-circuit = electricity.dc-circuit(
  electricity.voltage-source("folded-source", voltage: 18),
  electricity.series(
    electricity.resistor("folded-input", resistance: 100),
    electricity.parallel(
      electricity.resistor("folded-vertical", resistance: 300, route: "under"),
      electricity.capacitor(
        "folded-diagonal",
        capacitance: 200,
        unit: "nF",
        route: "direct",
      ),
      electricity.series(
        electricity.resistor("folded-upper", resistance: 50),
        electricity.resistor("folded-right", resistance: 250),
        route: "over",
      ),
    ),
    electricity.resistor("folded-return", resistance: 150),
  ),
)
#electricity.diagram(diagonal-folded-circuit, labels: "value")
#electricity.diagram(diagonal-folded-circuit, labels: "value", fold: false)

#let orthogonal-folded-circuit = electricity.dc-circuit(
  electricity.voltage-source("orthogonal-folded-source", voltage: 12),
  electricity.series(
    electricity.resistor("orthogonal-input", resistance: 100),
    electricity.parallel(
      electricity.resistor("orthogonal-upper", resistance: 300),
      electricity.resistor("orthogonal-lower", resistance: 200),
    ),
    electricity.resistor("orthogonal-return", resistance: 150),
    electricity.resistor("orthogonal-second-return", resistance: 75),
  ),
)
#electricity.diagram(orthogonal-folded-circuit, labels: "value", fold: true)

#electricity.diagram(
  electricity.dc-circuit(
    electricity.voltage-source("narrow-source", voltage: 12),
    electricity.series(
      electricity.resistor("narrow-first", resistance: 10),
      electricity.resistor("narrow-second", resistance: 20),
    ),
    style: (minimum-loop-width: 8),
  ),
  labels: "value",
)

// Every model, every quantity it determines, and the views that do not need one.
#let wall-situation = situation(
  wall("side", side: left, height: 4),
  block("pressed", mass: 4, on: "side", at: 45%, mu: (s: 0.5, k: 0.4)),
  force(on: "pressed", magnitude: 120, angle: 180deg),
)
#let ceiling-situation = situation(
  ceiling("roof", length: 6, height: 3),
  block("held", mass: 2, on: "roof", at: 50%, mu: 0.3),
  force(on: "held", magnitude: 50, angle: 90deg),
)
#let hanging-situation = situation(
  ceiling("beam", length: 6, height: 3),
  block("bob", mass: 3, hanging: (on: "beam", at: 50%)),
  rope("cord", from: (on: "beam", at: 50%), to: "bob.top"),
)
#let unmodelled-situation = situation(
  arc("bowl", radius: 3),
  block("slider", mass: 2, on: "bowl", at: 50%),
)

#for solvable in (wall-situation, ceiling-situation) {
  scene(solvable, forces: true)
  fbd(solvable, solvable.body-order.first())
  solve(solvable, find: "normal")
  solve(solvable, find: "friction")
  solve(solvable, find: "regime")
  force-table(solvable)
  repr(model-of(solvable))
}

#solve(hanging-situation)
#solve(hanging-situation, find: "tension")
#fbd(hanging-situation, "bob")
#force-table(hanging-situation, "bob")
#repr(model-of(hanging-situation, "bob"))

// A body no model matches still draws and still enumerates its forces.
#scene(unmodelled-situation)
#fbd(unmodelled-situation, "slider")
#force-table(unmodelled-situation, "slider")
#repr(model-of(unmodelled-situation, "slider"))
#repr(solved-models().map(model => model.id))

// Omitting a spring's wall ratio infers the opposite body anchor's height,
// while an explicit ratio remains exact.
#let wall-spring-attachments = situation(
  ground("spring-floor", length: 6),
  wall("spring-wall", side: left, height: 2.4),
  block("spring-block", on: "spring-floor", at: 50%, size: 1.2),
  spring(
    "inferred-spring",
    from: (on: "spring-wall"),
    to: "spring-block.left",
  ),
  spring(
    "explicit-spring",
    from: (on: "spring-wall", at: 22%),
    to: "spring-block.left",
  ),
  spring(
    "reverse-inferred-spring",
    from: "spring-block.left",
    to: (on: "spring-wall"),
  ),
)
#let inferred-spring = wall-spring-attachments.connectors.at(0)
#let explicit-spring = wall-spring-attachments.connectors.at(1)
#let reverse-inferred-spring = wall-spring-attachments.connectors.at(2)
#assert(inferred-spring.start.at(1) == inferred-spring.end.at(1))
#assert(explicit-spring.start.at(1) != explicit-spring.end.at(1))
#assert(reverse-inferred-spring.start.at(1) == reverse-inferred-spring.end.at(1))

// Symbolic and numeric circuits, every derived quantity, and the component table.
#let mixed-circuit = electricity.dc-circuit(
  electricity.voltage-source("supply", voltage: 12),
  electricity.series(
    electricity.resistor("first", resistance: 4),
    electricity.parallel(
      electricity.resistor("second", resistance: 6),
      electricity.capacitor("store", capacitance: 220, unit: "µF"),
    ),
  ),
)
#electricity.solve(mixed-circuit)
#electricity.solve(mixed-circuit, find: "current")
#electricity.solve(mixed-circuit, find: "voltage")
#electricity.solve(mixed-circuit, "second", find: "current")
#electricity.solve(mixed-circuit, "store")
#electricity.component-table(mixed-circuit)
#repr(electricity.results(mixed-circuit).regime)

#let capacitive-circuit = electricity.dc-circuit(
  electricity.voltage-source("cell", voltage: 12),
  electricity.parallel(
    electricity.capacitor("upper", capacitance: 2),
    electricity.series(
      electricity.capacitor("lower-first", capacitance: 3),
      electricity.capacitor("lower-second", capacitance: 6),
    ),
  ),
)
#electricity.solve(capacitive-circuit)
#electricity.solve(capacitive-circuit, "lower-first")
#electricity.component-table(capacitive-circuit)

#let symbolic-circuit = electricity.dc-circuit(
  electricity.voltage-source("source"),
  electricity.parallel(
    electricity.resistor("left"),
    electricity.resistor("right"),
  ),
)
#electricity.solve(symbolic-circuit)
#electricity.solve(symbolic-circuit, find: "current")

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

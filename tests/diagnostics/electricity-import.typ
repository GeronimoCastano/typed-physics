#import "../../src/lib.typ": electricity as e

#let circuit = e.dc-circuit(
  e.voltage-source("V", voltage: 12),
  e.series(
    e.resistor("R1", resistance: 4),
    e.parallel(
      e.resistor("R2", resistance: 6),
      e.capacitor("C1", capacitance: 3, unit: "µF"),
    ),
  ),
)

#e.diagram(circuit)

// typst compile --root . --ppi 300 assets/readme/examples/series-parallel-circuit.typ assets/readme/examples/series-parallel-circuit.png
#import "../../../src/lib.typ": electricity as e
#set page(width: 17cm, height: auto, margin: 12pt, fill: none)
#set text(font: "New Computer Modern", size: 11pt)

// A blue family: blue wires, pale-blue resistors, and a warm source.
#let circuit = e.dc-circuit(
  e.voltage-source("V", voltage: 18, label: $V$),
  e.series(
    e.resistor("R1", resistance: 6),
    e.parallel(
      e.series(
        e.resistor("R2", resistance: 4),
        e.parallel(
          e.resistor("R3", resistance: 6),
          e.resistor("R4", resistance: 3),
        ),
      ),
      e.resistor("R5", resistance: 12),
      e.resistor("R6", resistance: 12),
    ),
  ),
  style: (
    wire-stroke: 1pt + rgb("#1864AB"),
    component-stroke: 1.1pt + rgb("#0B3B6F"),
    component-fill: rgb("#E7F5FF"),
    source-fill: rgb("#FFF9DB"),
    junction-fill: rgb("#1864AB"),
    resistor-symbol: "rectangle",
    label-text: (size: 10pt),
    scale: 0.68,
  ),
)

#std.block(
  width: 100%,
  fill: white,
  stroke: 0.6pt + luma(215),
  radius: 8pt,
  inset: 18pt,
)[
  #grid(
    columns: (auto, 1fr),
    column-gutter: 0.9em,
    align: horizon,
    e.diagram(circuit, labels: "both"),
    [
      #set text(size: 9pt)
      #e.component-table(circuit)
      #v(0.9em)
      Equivalent resistance: #e.solve(circuit) \
      Total current: #e.solve(circuit, find: "current") \
      Current through $R_4$: #e.solve(circuit, "R4", find: "current")
    ],
  )
]

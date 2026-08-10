// Public electricity namespace: semantic DC declarations and drawing views.

#import "@preview/cetz:0.5.2"
#import "../validation-core.typ" as validation
#import "declarations.typ": (
  capacitor, dc-circuit, parallel, resistor, series, validate-circuit,
  voltage-source,
)
#import "layout.typ" as placement
#import "render.typ"
#import "style.typ": (
  capacitor-style, resistor-style, resolve-style, scaled-diagram, theme,
  voltage-source-style,
)

#let _resolved-view-style(circuit, overrides) = {
  resolve-style(circuit.style + overrides)
}

#let draw(
  circuit,
  labels: "both",
  fold: auto,
  style: (:),
) = {
  validate-circuit(circuit, "draw()")
  validation.validate-enum(
    labels,
    ("name", "value", "both", "none"),
    "electricity.draw()",
    "labels",
  )
  validation.validate-boolean(
    fold,
    "electricity.draw()",
    "fold",
    allow-auto: true,
  )
  let diagram-style = _resolved-view-style(circuit, style)
  let placed-circuit = placement.circuit-layout(
    circuit,
    diagram-style,
    fold: fold,
  )
  render.render-circuit(
    placed-circuit,
    diagram-style,
    labels: labels,
  )
}

#let diagram(
  circuit,
  labels: "both",
  fold: auto,
  style: (:),
) = {
  validate-circuit(circuit, "diagram()")
  let diagram-style = _resolved-view-style(circuit, style)
  scaled-diagram(
    diagram-style,
    cetz.canvas(draw(circuit, labels: labels, fold: fold, style: style)),
  )
}

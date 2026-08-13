#import "../../src/lib.typ": *

#let selected-case = sys.inputs.at("case", default: "")

#if selected-case == "unknown-kind" {
  situation((kind: "mystery", name: "x"))
} else if selected-case == "malformed-schema" {
  situation((
    kind: "ground",
    name: "ground",
    length: 5,
    from: none,
    friction: none,
    style: (:),
    lenght: 5,
  ))
} else if selected-case == "empty-situation" {
  situation()
} else if selected-case == "invalid-gravity" {
  situation(ground(), gravity: 0)
} else if selected-case == "nonpositive-dimension" {
  ground(length: 0)
} else if selected-case == "duplicate-name" {
  situation(ground("same"), block("same", on: "same"))
} else if selected-case == "forward-reference" {
  situation(block("A", on: "floor"), ground("floor"))
} else if selected-case == "missing-reference" {
  situation(ground(), block("A", on: "missing"))
} else if selected-case == "invalid-anchor" {
  situation(ground("floor"), pulley("P", at: "floor.apex"))
} else if selected-case == "dependency-cycle" {
  situation(
    rod("A", from: "B.end"),
    rod("B", from: "A.end"),
  )
} else if selected-case == "conflicting-placement" {
  block("A", on: "floor", hanging: "hook")
} else if selected-case == "ignored-touching-at" {
  block("A", touching: "B", at: 75%)
} else if selected-case == "body-out-of-bounds" {
  situation(ground(length: 4), block("A", on: "ground", at: 0%))
} else if selected-case == "overlapping-bodies" {
  situation(
    ground(length: 6),
    block("A", on: "ground", at: 50%, size: 1.5),
    block("B", on: "ground", at: 55%, size: 1.5),
  )
} else if selected-case == "malformed-mass" {
  block("A", mass: "heavy", on: "ground")
} else if selected-case == "friction-fields" {
  ground(mu: (static: 0.4, typo: 0.3))
} else if selected-case == "friction-order" {
  ground(mu: (s: 0.2, k: 0.3))
} else if selected-case == "coincident-connector" {
  let s = situation(
    ground("floor"),
    rope(from: "floor.start", to: "floor.start"),
  )
} else if selected-case == "pulley-endpoint-inside" {
  let s = situation(
    ceiling("roof"),
    pulley("P", at: "roof"),
    block("A", hanging: "P.bottom"),
    rope(from: "P.center", to: "A.top", over: "P"),
  )
} else if selected-case == "spring-coils" {
  spring(from: "A", to: "B", coils: 2.5)
} else if selected-case == "inferred-spring-outside-wall" {
  situation(
    ground("floor", length: 6),
    wall("wall", side: left, height: 0.4),
    block("A", on: "floor", at: 50%, size: 1),
    spring(from: (on: "wall"), to: "A.left"),
  )
} else if selected-case == "load-wrong-target" {
  situation(ground("floor"), force(on: "floor", magnitude: 10))
} else if selected-case == "ignored-body-load-point" {
  situation(
    ground(),
    block("A", on: "ground"),
    force(on: "A", at: 50%, magnitude: 10),
  )
} else if selected-case == "dimension-anchor" {
  let s = situation(ground("floor"))
  scene(s, dimensions: dimension(from: "floor.nope", to: "floor.end"))
} else if selected-case == "dimension-schema" {
  let s = situation(ground())
  scene(s, dimensions: (kind: "dimension", from: "ground.start"))
} else if selected-case == "missing-view-body" {
  let s = situation(ground(), block("A", on: "ground"))
  fbd(s, "B")
} else if selected-case == "invalid-body-selection" {
  let s = situation(ground(), block("A", on: "ground"))
  scene(s, forces: false)
} else if selected-case == "invalid-view-option" {
  let s = situation(ground(), block("A", on: "ground"))
  fbd(s, "A", axes: "surface")
} else if selected-case == "missing-label-data" {
  let s = situation(ground(), block("A", on: "ground"))
  scene(s, labels: "mass")
} else if selected-case == "unknown-scene-argument" {
  let s = situation(ground("floor"))
  scene(s, typo: true)
} else if selected-case == "unknown-style-key" {
  situation(ground(), style: (force-colors: (mystery: red)))
} else if selected-case == "invalid-style-value" {
  let s = situation(ground())
  scene(s, style: (scale: -1))
} else if selected-case == "invalid-element-paint" {
  ground(style: (fill: "blue"))
} else if selected-case == "invalid-element-stroke" {
  ground(style: (stroke: "thick"))
} else if selected-case == "invalid-nested-text-style" {
  force(on: "A", magnitude: 1, style: (text: "large"))
} else if selected-case == "invalid-assumption" {
  let s = situation(ground(), block("A", mass: 1, on: "ground"))
  solve(s, assume: "rolling")
} else if selected-case == "ambiguous-body" {
  let s = situation(
    ground(),
    block("A", mass: 1, on: "ground", at: 30%),
    block("B", mass: 1, on: "ground", at: 70%),
  )
  solve(s)
} else if selected-case == "components-without-frame" {
  let s = situation(
    ceiling(),
    block("A", mass: 1, hanging: "ceiling"),
  )
  components(s, "A")
} else if selected-case == "unsupported-solver-body" {
  let s = situation(ground(), disk("D", mass: 1, on: "ground"))
  solve(s)
} else if selected-case == "electrical-invalid-resistance" {
  electricity.resistor("R", resistance: 0)
} else if selected-case == "electrical-invalid-capacitance" {
  electricity.capacitor("C", capacitance: 0)
} else if selected-case == "electrical-capacitor-unit" {
  electricity.capacitor("C", capacitance: 1, unit: 3)
} else if selected-case == "electrical-capacitor-label" {
  electricity.capacitor("C", capacitance: 1, label: 3)
} else if selected-case == "electrical-empty-series" {
  electricity.series(electricity.resistor("R"))
} else if selected-case == "electrical-duplicate-name" {
  electricity.dc-circuit(
    electricity.voltage-source("shared", voltage: 9),
    electricity.resistor("shared", resistance: 4),
  )
} else if selected-case == "electrical-source-in-load" {
  electricity.dc-circuit(
    electricity.voltage-source("V1", voltage: 9),
    electricity.series(
      electricity.resistor("R", resistance: 4),
      electricity.voltage-source("V2", voltage: 3),
    ),
  )
} else if selected-case == "electrical-style-key" {
  electricity.dc-circuit(
    electricity.voltage-source("V", voltage: 9),
    electricity.resistor("R", resistance: 4),
    style: (wire-color: red),
  )
} else if selected-case == "electrical-invalid-unit" {
  electricity.resistor("R", resistance: 4, unit: 3)
} else if selected-case == "electrical-resistor-symbol" {
  electricity.resistor(
    "R",
    resistance: 4,
    style: electricity.resistor-style(symbol: "circle"),
  )
} else if selected-case == "electrical-source-symbol" {
  electricity.voltage-source(
    "V",
    voltage: 9,
    style: electricity.voltage-source-style(symbol: "zigzag"),
  )
} else if selected-case == "electrical-capacitor-style" {
  electricity.capacitor(
    "C",
    capacitance: 1,
    style: (fill: red),
  )
} else if selected-case == "electrical-capacitor-stroke" {
  electricity.capacitor(
    "C",
    capacitance: 1,
    style: electricity.capacitor-style(stroke: "thick"),
  )
} else if selected-case == "electrical-capacitor-text" {
  electricity.capacitor(
    "C",
    capacitance: 1,
    style: electricity.capacitor-style(text: "large"),
  )
} else if selected-case == "electrical-diagram-symbol" {
  electricity.dc-circuit(
    electricity.voltage-source("V", voltage: 9),
    electricity.resistor("R", resistance: 4),
    style: (resistor-symbol: "coil"),
  )
} else if selected-case == "electrical-minimum-loop-width" {
  electricity.dc-circuit(
    electricity.voltage-source("V", voltage: 9),
    electricity.resistor("R", resistance: 4),
    style: (minimum-loop-width: 0),
  )
} else if selected-case == "electrical-frame-rise" {
  electricity.dc-circuit(
    electricity.voltage-source("V", voltage: 9),
    electricity.resistor("R", resistance: 4),
    style: (frame-rise: 0),
  )
} else if selected-case == "electrical-capacitor-gap" {
  electricity.dc-circuit(
    electricity.voltage-source("V", voltage: 9),
    electricity.capacitor("C", capacitance: 1),
    style: (capacitor-plate-gap: 0),
  )
} else if selected-case == "electrical-capacitor-height" {
  electricity.dc-circuit(
    electricity.voltage-source("V", voltage: 9),
    electricity.capacitor("C", capacitance: 1),
    style: (capacitor-plate-height: 0),
  )
} else if selected-case == "electrical-capacitor-gap-too-wide" {
  electricity.dc-circuit(
    electricity.voltage-source("V", voltage: 9),
    electricity.capacitor("C", capacitance: 1),
    style: (component-length: 1, capacitor-plate-gap: 2),
  )
} else if selected-case == "electrical-fold-value" {
  electricity.diagram(
    electricity.dc-circuit(
      electricity.voltage-source("V", voltage: 9),
      electricity.series(
        electricity.resistor("R1", resistance: 1),
        electricity.resistor("R2", resistance: 2),
      ),
    ),
    fold: "yes",
  )
} else if selected-case == "electrical-fold-unavailable" {
  electricity.diagram(
    electricity.dc-circuit(
      electricity.voltage-source("V", voltage: 9),
      electricity.resistor("R1", resistance: 1),
    ),
    fold: true,
  )
} else if selected-case == "electrical-fold-trailing-missing" {
  electricity.diagram(
    electricity.dc-circuit(
      electricity.voltage-source("V", voltage: 9),
      electricity.series(
        electricity.resistor("R1", resistance: 1),
        electricity.parallel(
          electricity.resistor("R2", resistance: 2),
          electricity.resistor("R3", resistance: 3),
        ),
      ),
    ),
    fold: true,
  )
} else if selected-case == "electrical-route-value" {
  electricity.resistor("R", resistance: 4, route: "sideways")
} else if selected-case == "electrical-route-partial" {
  electricity.parallel(
    electricity.resistor("R1", resistance: 1, route: "direct"),
    electricity.resistor("R2", resistance: 2),
  )
} else if selected-case == "electrical-route-repeated" {
  electricity.parallel(
    electricity.resistor("R1", resistance: 1, route: "direct"),
    electricity.resistor("R2", resistance: 2, route: "direct"),
  )
} else if selected-case == "electrical-route-nested-branch" {
  electricity.parallel(
    electricity.resistor("R1", resistance: 1, route: "direct"),
    electricity.series(
      electricity.resistor("R2", resistance: 2),
      electricity.parallel(
        electricity.resistor("R3", resistance: 3),
        electricity.resistor("R4", resistance: 4),
      ),
      route: "over",
    ),
  )
} else if selected-case == "electrical-route-corner-crowded" {
  electricity.parallel(
    electricity.resistor("R1", resistance: 1, route: "direct"),
    electricity.series(
      electricity.resistor("R2", resistance: 2),
      electricity.resistor("R3", resistance: 3),
      electricity.resistor("R4", resistance: 4),
      route: "over",
    ),
  )
} else if selected-case == "electrical-route-outside-parallel" {
  electricity.dc-circuit(
    electricity.voltage-source("V", voltage: 9),
    electricity.series(
      electricity.resistor("R1", resistance: 1, route: "direct"),
      electricity.resistor("R2", resistance: 2),
    ),
  )
} else if selected-case == "no-model-matches" {
  let s = situation(
    arc("loop", radius: 3),
    block("P", mass: 2, on: "loop", at: 50%),
  )
  solve(s, "P")
} else if selected-case == "model-mismatch-lists-scope" {
  let s = situation(
    ground("floor"),
    block("A", mass: 2, on: "floor", at: 30%),
    block("B", mass: 3, touching: "A"),
  )
  solve(s, "A")
} else if selected-case == "shared-tension" {
  let s = situation(
    ground("floor"),
    block("A", mass: 2, on: "floor", at: 30%),
    pulley("wheel", at: "floor.end"),
    rope("cord", from: "A", to: "wheel"),
  )
  solve(s, "A")
} else if selected-case == "indeterminate-tie" {
  let s = situation(
    ground("floor", length: 7),
    wall("side", side: right),
    block("A", mass: 2, on: "floor", at: 40%, mu: 0.4),
    rope("tie", from: "A", to: "side"),
  )
  solve(s, "A")
} else if selected-case == "two-holding-connectors" {
  let s = situation(
    ceiling("roof"),
    block("H", mass: 3, hanging: "roof"),
    rope("left-cord", from: "roof.start", to: "H.top"),
    rope("right-cord", from: "roof.end", to: "H.top"),
  )
  solve(s, "H")
} else if selected-case == "quantity-outside-model" {
  let s = situation(ceiling("roof"), block("H", mass: 3, hanging: "roof"))
  solve(s, "H", find: "normal")
} else if selected-case == "assume-without-contact" {
  let s = situation(ceiling("roof"), block("H", mass: 3, hanging: "roof"))
  solve(s, "H", assume: "static")
} else if selected-case == "body-pulled-off-surface" {
  let s = situation(
    ceiling("roof", length: 6),
    block("B", mass: 2, on: "roof", at: 50%),
  )
  solve(s, "B")
} else if selected-case == "unknown-find-quantity" {
  let s = situation(ground("floor"), block("A", mass: 2, on: "floor", at: 30%))
  solve(s, "A", find: "momentum")
} else if selected-case == "ambiguous-model-of" {
  let s = situation(
    ground("floor"),
    block("A", mass: 2, on: "floor", at: 20%),
    block("B", mass: 2, on: "floor", at: 70%),
  )
  model-of(s)
} else if selected-case == "electrical-mixed-resistor-units" {
  electricity.solve(electricity.dc-circuit(
    electricity.voltage-source("V", voltage: 12),
    electricity.series(
      electricity.resistor("R1", resistance: 4),
      electricity.resistor("R2", resistance: 2, unit: "kΩ"),
    ),
  ))
} else if selected-case == "electrical-mixed-capacitor-units" {
  electricity.results(electricity.dc-circuit(
    electricity.voltage-source("V", voltage: 12),
    electricity.series(
      electricity.capacitor("C1", capacitance: 4, unit: "µF"),
      electricity.capacitor("C2", capacitance: 2, unit: "nF"),
    ),
  ))
} else if selected-case == "electrical-blocked-current" {
  electricity.solve(electricity.dc-circuit(
    electricity.voltage-source("V", voltage: 12),
    electricity.series(
      electricity.capacitor("C1", capacitance: 2),
      electricity.capacitor("C2", capacitance: 3),
    ),
  ), find: "current")
} else if selected-case == "electrical-capacitance-with-resistors" {
  electricity.solve(electricity.dc-circuit(
    electricity.voltage-source("V", voltage: 12),
    electricity.series(
      electricity.resistor("R1", resistance: 4),
      electricity.capacitor("C1", capacitance: 2),
    ),
  ), find: "capacitance")
} else if selected-case == "electrical-quantity-wrong-kind" {
  electricity.solve(electricity.dc-circuit(
    electricity.voltage-source("V", voltage: 12),
    electricity.series(
      electricity.resistor("R1", resistance: 4),
      electricity.resistor("R2", resistance: 6),
    ),
  ), "R1", find: "capacitance")
} else if selected-case == "electrical-unknown-component" {
  electricity.solve(electricity.dc-circuit(
    electricity.voltage-source("V", voltage: 12),
    electricity.series(
      electricity.resistor("R1", resistance: 4),
      electricity.resistor("R2", resistance: 6),
    ),
  ), "R9")
} else if selected-case == "electrical-unknown-find" {
  electricity.solve(electricity.dc-circuit(
    electricity.voltage-source("V", voltage: 12),
    electricity.series(
      electricity.resistor("R1", resistance: 4),
      electricity.resistor("R2", resistance: 6),
    ),
  ), find: "power")
} else {
  panic("diagnostic harness: unknown case " + repr(selected-case))
}

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
} else {
  panic("diagnostic harness: unknown case " + repr(selected-case))
}

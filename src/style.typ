// Shared visual defaults for every view in the package.
//
// One dictionary so a scene, its free-body diagram, and its component
// decomposition keep the same stroke weights and force colors. Every view
// takes a `style:` dictionary that is merged over these defaults, so a call
// site or, through `.with(style: ...)`, a whole document can override them.

#let theme = (
  // World geometry. CeTZ canvas units are centimetres, so a ramp declared with
  // `length: 6` is six centimetres along its incline.
  block-size: 1.0,

  // Surfaces and bodies
  surface-stroke: 0.8pt + rgb("#333333"),
  surface-fill: rgb("#F1F3F5"),
  hatch-stroke: 0.6pt + rgb("#868E96"),
  hatch-spacing: 0.28,
  hatch-length: 0.26,
  body-stroke: 0.9pt + rgb("#212529"),
  body-fill: rgb("#DDE6F5"),

  // Angle marks and construction lines
  angle-stroke: 0.6pt + rgb("#495057"),
  angle-radius: 0.9,
  construction-stroke: (paint: rgb("#868E96"), thickness: 0.5pt, dash: "dashed"),
  right-angle-size: 0.18,

  // Force arrows. Lengths are in world units: the largest force on a body is
  // drawn at `force-length` and the rest in proportion, down to `force-floor`,
  // so a free-body diagram reads as a comparison and not just as a list.
  force-stroke: 1.1pt,
  force-length: 1.5,
  force-floor: 0.45,
  force-colors: (
    weight: rgb("#1971C2"),
    normal: rgb("#2F9E44"),
    friction: rgb("#E8590C"),
    applied: rgb("#6741D9"),
    component: rgb("#1971C2"),
  ),

  // Text
  label-text: (size: 9pt),
  force-text: (size: 9pt),
  angle-text: (size: 9pt),
  scale: 1.0,
)

#let resolve-style(overrides) = {
  assert(type(overrides) == dictionary, message: "typed-physics: style: must be a dictionary")
  for key in overrides.keys() {
    assert(key in theme, message: "typed-physics: unknown style key \"" + key + "\"")
  }
  let merged = theme + overrides
  if "force-colors" in overrides { merged.force-colors = theme.force-colors + overrides.force-colors }
  merged
}

#let scaled-diagram(th, body) = if th.scale == 1.0 { body } else { scale(th.scale * 100%, reflow: true, body) }

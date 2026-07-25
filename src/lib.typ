// typed-physics — declare a mechanics situation once and derive everything
// else from it.
//
// `situation(...)` takes the problem statement as elements that read like the
// sentence they came from, resolves them into geometry, and hands back the
// views of that one declaration: the scene, a free-body diagram of any body,
// the weight resolved into the surface's axes, and the solution. They cannot
// disagree with each other, because there is only one situation underneath.

#import "@preview/cetz:0.5.2"
#import "placement.typ"
#import "render.typ"
#import "fbd.typ"
#import "solver.typ"
#import "report.typ"
#import "forces.typ"

#import "elements.typ": block, ceiling, force, ground, ramp, wall
#import "style.typ": resolve-style, scaled-diagram, theme

#let chosen-body(arguments) = {
  let given = arguments.pos()
  assert(
    given.len() <= 1,
    message: "typed-physics: this view takes at most one positional argument, the name of a body",
  )
  if given.len() == 1 { given.first() } else { auto }
}

#let situation(..declarations, gravity: 9.81, style: (:)) = {
  let scene = placement.resolve(declarations.pos(), gravity: gravity)
  let situation-style = style
  let styled(overrides) = resolve-style(situation-style + overrides)
  let drawn(th, elements) = scaled-diagram(th, cetz.canvas(elements))
  let solved(body, assume) = solver.solve-situation(scene, body: body, assume: assume)

  (
    scene: (labels: "name", angles: "value", loads: true, style: (:)) => {
      let th = styled(style)
      drawn(th, render.draw-scene(scene, th, labels: labels, angles: angles, loads: loads))
    },

    fbd: (name, axes: auto, outline: true, solve: true, style: (:)) => {
      let th = styled(style)
      let solution = if solve { solver.solve-body(scene, name) } else { none }
      let usable = if solution != none and solution.status == "solved" { solution } else { none }
      drawn(th, fbd.draw-fbd(scene, name, th, solution: usable, axes: axes, outline: outline))
    },

    components: (name, of: "weight", style: (:)) => {
      let th = styled(style)
      drawn(th, fbd.draw-components(scene, name, th, of: of))
    },

    // A situation with one body needs no name; naming it is how a situation
    // with several says which one it means.
    solve: (..name, assume: auto) => report.solution-report(scene, solved(chosen-body(name), assume)),

    steps: (..name, assume: auto) => report.solution-report(scene, solved(chosen-body(name), assume), steps: true),

    table: (..name, assume: auto) => {
      let solution = solved(chosen-body(name), assume)
      report.force-table(scene, solution.body, solution: if solution.status == "solved" { solution } else { none })
    },

    results: (..name, assume: auto) => solved(chosen-body(name), assume),

    forces: name => forces.enumerate-forces(scene, name),

    // The scene as CeTZ elements, for drawing on top of it inside a canvas of
    // your own. Every body and surface is a named group, so `("A.center")` and
    // `("incline.apex")` are addressable coordinates.
    draw: (labels: "name", angles: "value", loads: true, style: (:)) => render.draw-scene(
      scene,
      styled(style),
      labels: labels,
      angles: angles,
      loads: loads,
    ),

    placed: scene,
  )
}

// Typst can only call a closure stored in a dictionary through an extra pair of
// parentheses — `(s.fbd)("A")`. These read the same way round and spare the
// reader that detail.

#let scene(s, ..arguments) = (s.scene)(..arguments)
#let fbd(s, name, ..arguments) = (s.fbd)(name, ..arguments)
#let components(s, name, ..arguments) = (s.components)(name, ..arguments)
#let solve(s, ..arguments) = (s.solve)(..arguments)
#let steps(s, ..arguments) = (s.steps)(..arguments)
#let force-table(s, ..arguments) = (s.table)(..arguments)
#let results(s, ..arguments) = (s.results)(..arguments)
#let draw(s, ..arguments) = (s.draw)(..arguments)

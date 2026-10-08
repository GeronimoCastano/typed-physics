#!/bin/sh
set -eu

repository_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
invalid_source="$repository_root/tests/diagnostics/invalid.typ"
positive_source="$repository_root/tests/diagnostics/positive.typ"
electricity_import_source="$repository_root/tests/diagnostics/electricity-import.typ"
temporary_directory=$(mktemp -d)
trap 'rm -rf "$temporary_directory"' EXIT HUP INT TERM

run_invalid_case() {
  case_name=$1
  expected_text=$2
  diagnostic_output="$temporary_directory/$case_name.txt"
  output_pdf="$temporary_directory/$case_name.pdf"

  if typst compile \
    --root "$repository_root" \
    --input "case=$case_name" \
    "$invalid_source" \
    "$output_pdf" >"$diagnostic_output" 2>&1
  then
    echo "FAIL $case_name: compilation unexpectedly succeeded" >&2
    return 1
  fi

  if ! grep -F "$expected_text" "$diagnostic_output" >/dev/null
  then
    echo "FAIL $case_name: expected diagnostic text: $expected_text" >&2
    sed -n '1,80p' "$diagnostic_output" >&2
    return 1
  fi

  echo "PASS $case_name"
}

run_invalid_case unknown-kind "unknown kind"
run_invalid_case malformed-schema "unknown field \`lenght:\`"
run_invalid_case empty-situation "needs at least one element declaration"
run_invalid_case invalid-gravity "invalid \`gravity:\`"
run_invalid_case nonpositive-dimension "expected a positive number"
run_invalid_case duplicate-name "declared twice"
run_invalid_case forward-reference "before it is available"
run_invalid_case missing-reference "there is no element called \"missing\""
run_invalid_case invalid-anchor "references unavailable anchor"
run_invalid_case dependency-cycle "placement dependency cycle"
run_invalid_case conflicting-placement "conflict with \`hanging:\`"
run_invalid_case ignored-touching-at "would be ignored"
run_invalid_case body-out-of-bounds "hangs off the start"
run_invalid_case overlapping-bodies "overlap on surface"
run_invalid_case malformed-mass "invalid \`mass:\`"
run_invalid_case friction-fields "unknown field \"typo\""
run_invalid_case friction-order "static friction greater than or equal"
run_invalid_case coincident-connector "coincident \`from:\` and \`to:\`"
run_invalid_case pulley-endpoint-inside "endpoint lies on or inside the wheel"
run_invalid_case spring-coils "expected a positive integer"
run_invalid_case inferred-spring-outside-wall "opposite body anchor falls outside the wall"
run_invalid_case load-wrong-target "compatible element types are body, structure"
run_invalid_case ignored-body-load-point "currently act at the center"
run_invalid_case dimension-anchor "has no anchor called"
run_invalid_case dimension-schema "malformed dimension annotation is missing"
run_invalid_case annotations-renamed "takes \`annotations:\` rather than \`dimensions:\`"
run_invalid_case annotation-unknown-kind "unknown annotation kind"
run_invalid_case annotation-not-a-dictionary "must be one annotation or an array of them"
run_invalid_case callout-without-label "needs \`label:\` content"
run_invalid_case angle-mark-without-corner "has no corner to mark"
run_invalid_case angle-mark-parallel "measures between two parallel directions"
run_invalid_case arrow-coincident-points "must go somewhere"
run_invalid_case brace-coincident-points "endpoints must not coincide"
run_invalid_case axis-unknown-direction "is not an element of this situation"
run_invalid_case brace-side "side: must be"
run_invalid_case offset-relative-length "relative to the font size"
run_invalid_case offset-wrong-type "numbers in world units or absolute lengths"
run_invalid_case offset-not-a-pair "as an (x, y) pair"
run_invalid_case ratio-along-point-anchor "which is a single point"
run_invalid_case ratio-along-whole-body "which is a single point"
run_invalid_case renamed-style-key "unknown style key"
run_invalid_case missing-view-body "available bodies are A"
run_invalid_case invalid-body-selection "must be none, true, a body name"
run_invalid_case invalid-view-option "expected true, false, or auto"
run_invalid_case missing-label-data "but it has no \`mass:\`"
run_invalid_case unknown-scene-argument "unknown argument \`typo:\`"
run_invalid_case unknown-style-key "unknown role \"mystery\""
run_invalid_case invalid-style-value "invalid \`scale:\`"
run_invalid_case invalid-element-paint "invalid \`fill:\`"
run_invalid_case invalid-element-stroke "invalid \`stroke:\`"
run_invalid_case invalid-nested-text-style "must be a text-style dictionary"
run_invalid_case invalid-assumption "accepted values are"
run_invalid_case ambiguous-body "solves one body at a time"
run_invalid_case components-without-frame "has no supporting surface frame"
run_invalid_case unsupported-solver-body "drawing-only disk"
run_invalid_case electrical-invalid-resistance "invalid \`resistance:\`"
run_invalid_case electrical-invalid-capacitance "invalid \`capacitance:\`"
run_invalid_case electrical-capacitor-unit "\`unit:\` must be auto, none"
run_invalid_case electrical-capacitor-label "\`label:\` must be auto, none"
run_invalid_case electrical-empty-series "needs at least two circuit declarations"
run_invalid_case electrical-duplicate-name "declared twice"
run_invalid_case electrical-source-in-load "only as its first argument"
run_invalid_case electrical-style-key "unknown electricity diagram style key"
run_invalid_case electrical-invalid-unit "\`unit:\` must be auto, none"
run_invalid_case electrical-resistor-symbol "style has invalid \`symbol:\`"
run_invalid_case electrical-source-symbol "style has invalid \`symbol:\`"
run_invalid_case electrical-capacitor-style "has unknown style key \"fill\""
run_invalid_case electrical-capacitor-stroke "invalid \`stroke:\`"
run_invalid_case electrical-capacitor-text "style \`text:\` must be a text-style dictionary"
run_invalid_case electrical-diagram-symbol "electricity diagram style has invalid \`resistor-symbol:\`"
run_invalid_case electrical-frame-rise "invalid \`frame-rise:\`"
run_invalid_case electrical-minimum-loop-width "invalid \`minimum-loop-width:\`"
run_invalid_case electrical-capacitor-gap "invalid \`capacitor-plate-gap:\`"
run_invalid_case electrical-capacitor-height "invalid \`capacitor-plate-height:\`"
run_invalid_case electrical-capacitor-gap-too-wide "must be smaller than \`component-length:\`"
run_invalid_case electrical-fold-value "invalid \`fold:\`"
run_invalid_case electrical-fold-unavailable "found nothing to place on the return rail"
run_invalid_case electrical-fold-trailing-missing "found nothing to place on the return rail"
run_invalid_case electrical-route-value "invalid \`route:\`"
run_invalid_case electrical-route-partial "every branch must declare one"
run_invalid_case electrical-route-repeated "at most one branch on the"
run_invalid_case electrical-route-nested-branch "must be one component or a flat series"
run_invalid_case electrical-route-corner-crowded "turns at one corner and can hold at most two"
run_invalid_case electrical-route-outside-parallel "has no meaning on a network that is not such a branch"
run_invalid_case no-model-matches "no solved model matches"
run_invalid_case model-mismatch-lists-scope "This release solves:"
run_invalid_case shared-tension "shares with whatever is on the other end"
run_invalid_case indeterminate-tie "shares with whatever is on the other end"
run_invalid_case two-holding-connectors "more than one connector holds it up"
run_invalid_case quantity-outside-model "model does not determine"
run_invalid_case assume-without-contact "has no contact to rub"
run_invalid_case body-pulled-off-surface "instead of pressed against it"
run_invalid_case unknown-find-quantity "accepted values are"
run_invalid_case ambiguous-model-of "describes one body at a time"
run_invalid_case electrical-mixed-resistor-units "declared in different units"
run_invalid_case electrical-mixed-capacitor-units "declared in different units"
run_invalid_case electrical-blocked-current "passes no steady current"
run_invalid_case electrical-capacitance-with-resistors "no single capacitance stands for the whole of it"
run_invalid_case electrical-quantity-wrong-kind "so it has no capacitance"
run_invalid_case electrical-unknown-component "which this circuit does not declare"
run_invalid_case electrical-unknown-find "accepted values are"
run_invalid_case ceiling-from-with-height "has both \`from:\` and \`height:\`"
run_invalid_case ceiling-from-wall "walls are placed after the surfaces they stand beside"
run_invalid_case arc-center-ratio "which is a single point"
run_invalid_case pulley-pair-tilted-rope "leaves it at an angle to ramp"
run_invalid_case pulley-pair-unhung-body "does not hang from pulley"
run_invalid_case pulley-pair-assume-static-fails "says the pulley pair stays at rest"
run_invalid_case pulley-pair-assume-sliding-fails "says the pulley pair moves"
run_invalid_case pulley-pair-atwood-normal "both bodies of this pulley pair hang"

typst compile \
  --root "$repository_root" \
  "$positive_source" \
  "$temporary_directory/positive.pdf"
typst compile \
  --root "$repository_root" \
  "$electricity_import_source" \
  "$temporary_directory/electricity-import.pdf"
echo "PASS positive mechanics and electrical drawing cases"

#!/bin/sh
set -eu

repository_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
invalid_source="$repository_root/tests/diagnostics/invalid.typ"
positive_source="$repository_root/tests/diagnostics/positive.typ"
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
run_invalid_case load-wrong-target "compatible element types are body, structure"
run_invalid_case ignored-body-load-point "currently act at the center"
run_invalid_case dimension-anchor "has no anchor called"
run_invalid_case dimension-schema "malformed dimension annotation is missing"
run_invalid_case missing-view-body "available bodies are A"
run_invalid_case invalid-body-selection "must be none, true, a body name"
run_invalid_case invalid-view-option "expected true, false, or auto"
run_invalid_case missing-label-data "but it has no \`mass:\`"
run_invalid_case unknown-style-key "unknown role \"mystery\""
run_invalid_case invalid-style-value "invalid \`scale:\`"
run_invalid_case invalid-element-paint "invalid \`fill:\`"
run_invalid_case invalid-element-stroke "invalid \`stroke:\`"
run_invalid_case invalid-nested-text-style "must be a text-style dictionary"
run_invalid_case invalid-assumption "accepted values are"
run_invalid_case ambiguous-body "solves one body at a time"
run_invalid_case components-without-frame "has no supporting surface frame"
run_invalid_case unsupported-solver-body "drawing-only disk"

typst compile \
  --root "$repository_root" \
  "$positive_source" \
  "$temporary_directory/positive.pdf"
echo "PASS positive symbolic, numeric, selected multi-body, and drawing-only cases"

#!/usr/bin/env sh
set -eu

usage() {
  echo "Usage: scripts/package-preview.sh <version> <typst-packages-repo>" >&2
  echo "Example: scripts/package-preview.sh 0.1.2 /path/to/typst/packages" >&2
}

if [ "$#" -ne 2 ]; then
  usage
  exit 2
fi

version="$1"
packages_repo="${2%/}"
package_name="typed-physics"

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd)
target="$packages_repo/packages/preview/$package_name/$version"

if [ ! -d "$packages_repo/packages/preview" ]; then
  echo "error: not a typst/packages checkout: $packages_repo" >&2
  exit 1
fi

manifest_version=$(awk -F '"' '/^version = / { print $2; exit }' "$repo_root/typst.toml")
if [ "$manifest_version" != "$version" ]; then
  echo "error: typst.toml version is $manifest_version, not $version" >&2
  exit 1
fi

for required in \
  "$repo_root/typst.toml" \
  "$repo_root/README.md" \
  "$repo_root/LICENSE" \
  "$repo_root/src/lib.typ"
do
  if [ ! -f "$required" ]; then
    echo "error: missing required file: $required" >&2
    exit 1
  fi
done

if [ -e "$target" ]; then
  echo "error: target already exists: $target" >&2
  echo "Remove it manually if you intentionally want to recreate it." >&2
  exit 1
fi

mkdir -p "$target/src" "$target/assets/readme"

cp "$repo_root/typst.toml" "$target/typst.toml"
cp "$repo_root/README.md" "$target/README.md"
cp "$repo_root/LICENSE" "$target/LICENSE"

# Namespaces such as src/electricity are their own directories, so the source
# tree is walked rather than globbed. Only Typst modules travel: anything else
# under src/ is a build artifact that the bundle has no use for.
find "$repo_root/src" -type f -name '*.typ' | while IFS= read -r module_path; do
  module_relative_path=${module_path#"$repo_root/src/"}
  mkdir -p "$target/src/$(dirname "$module_relative_path")"
  cp "$module_path" "$target/src/$module_relative_path"
done

found_png=0
for image in "$repo_root"/assets/readme/*.png "$repo_root"/assets/readme/examples/*.png; do
  if [ -f "$image" ]; then
    image_relative=${image#"$repo_root/"}
    mkdir -p "$(dirname -- "$target/$image_relative")"
    cp "$image" "$target/$image_relative"
    found_png=1
  fi
done

if [ "$found_png" -eq 0 ]; then
  echo "warning: no README PNG assets found in assets/readme" >&2
fi

# A bundle that is missing a module still copies without complaint, and the
# first person to find out would be someone importing the published version. So
# the copy is imported here, from the packages checkout, exactly as a reader
# would import it.
import_check_dir=$(mktemp -d)
trap 'rm -rf "$import_check_dir"' EXIT HUP INT TERM
cat >"$import_check_dir/import-check.typ" <<EOF
#import "@preview/$package_name:$version": *
#import "@preview/$package_name:$version": electricity
Imported.
EOF
if ! typst compile \
  --package-path "$packages_repo/packages" \
  --root "$import_check_dir" \
  "$import_check_dir/import-check.typ" \
  "$import_check_dir/import-check.pdf" >"$import_check_dir/log.txt" 2>&1
then
  echo "error: the prepared bundle does not import; it is missing a module or has a broken one" >&2
  sed -n '1,40p' "$import_check_dir/log.txt" >&2
  exit 1
fi

echo "Prepared $package_name $version at:"
echo "$target"
echo
echo "Next:"
echo "  cd $packages_repo/packages"
echo "  typst-package-check check @preview/$package_name:$version"

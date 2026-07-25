#!/usr/bin/env sh
set -eu

usage() {
  echo "Usage: scripts/package-preview.sh <version> <typst-packages-repo>" >&2
  echo "Example: scripts/package-preview.sh 0.1.0 /path/to/typst/packages" >&2
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
cp "$repo_root"/src/*.typ "$target/src/"

found_png=0
for image in "$repo_root"/assets/readme/*.png; do
  if [ -f "$image" ]; then
    cp "$image" "$target/assets/readme/"
    found_png=1
  fi
done

if [ "$found_png" -eq 0 ]; then
  echo "warning: no README PNG assets found in assets/readme" >&2
fi

echo "Prepared $package_name $version at:"
echo "$target"
echo
echo "Next:"
echo "  cd $packages_repo/packages"
echo "  typst-package-check check @preview/$package_name:$version"

#!/usr/bin/env bash

# based on <https://github.com/NixOS/nixpkgs/blob/fe891f534f247971d2d8aafc54dc471ed345020f/pkgs/tools/misc/depotdownloader/fetch-deps.sh>

set -euo pipefail

echo working in: "$PWD"
scriptFolder="$PWD"

if [[ ! -f ./deps.nix ]]; then
  echo "There's no deps.nix file here; are you in the right folder?"
  exit 1
fi;

deps_file="$(realpath "./deps.nix")"

# get a writable copy of the source ready, for nuget-to-nix to read
store_src="$(nix build .#src --no-link --json | jq -r ".[0].outputs.out")"
echo store_src="$store_src"
src="$(mktemp -d nuget_tmp_sqltoolsservice-src.XXX)"
cp -rT "$store_src" "$src"
chmod -R +w "$src"
pushd "$src"

nuget_tmp="$(mktemp -d)"
clean_up() {
  echo Cleaning up.
  rm -rf "$nuget_tmp"
  rm -rf "$src"
}
trap clean_up EXIT
echo nuget tmp: "$nuget_tmp"

echo Patching...
# <https://github.com/microsoft/sqltoolsservice/issues/1173>
git apply -v --directory "$src" \
  "$scriptFolder/0003-stop-importing-from-private-feeds.patch"

echo Restoring...
dotnet restore sqltoolsservice.sln --packages "$nuget_tmp"

echo Restoring Cake Build dependencies...
# do what `scripts/cake-bootstrap.ps1` does, so we can grab the 'hidden'
# dependencies in `scripts/packages.config`...
pushd scripts
nuget restore ./packages.config -OutputDirectory "$nuget_tmp"

echo "Unpacking *.nuspec files for nuget-to-nix..."
# `nuget restore` doesn't extract the *.nuspec files, so nuget-to-nix is blind
# to those packages...
pushd "$nuget_tmp"
find . -type f -name "*.nupkg" -execdir sh -c 'unzip -n *.nupkg *.nuspec' ';' \
  2> >(grep -v '^caution: filename not matched:') | \
  grep -v '^Archive: '
popd
popd

echo nuget-to-nix...
nuget-to-nix "$nuget_tmp" > "$deps_file"
nixfmt "$deps_file"

echo Dependencies fetched.

# within-nixpkgs things
popd

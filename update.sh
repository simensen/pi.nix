#!/usr/bin/env nix-shell
#!nix-shell -i bash -p bash jq nix curl
# shellcheck shell=bash
set -euo pipefail

latest_version_url=https://pi.dev/api/latest-version
release_base_url=https://github.com/earendil-works/pi/releases/download
version_file=VERSION.json

systems=(
  "aarch64-darwin:pi-darwin-arm64.tar.gz"
  "x86_64-darwin:pi-darwin-x64.tar.gz"
  "aarch64-linux:pi-linux-arm64.tar.gz"
  "x86_64-linux:pi-linux-x64.tar.gz"
)

die() { echo "$*" >&2; exit 1; }
out() { [[ -n ${GITHUB_OUTPUT:-} ]] && echo "$1=$2" >> "$GITHUB_OUTPUT" || true; }

latest_tag() {
  local response ok version
  response=$(curl -fsSL "$latest_version_url") \
    || die "Failed to query $latest_version_url"
  ok=$(jq -r '.ok' <<< "$response") \
    || die "Failed to parse JSON from $latest_version_url: $response"
  [[ "$ok" == "true" ]] \
    || die "$latest_version_url returned ok!=true: $response"
  version=$(jq -r '.version' <<< "$response") \
    || die "Failed to extract .version from $latest_version_url response: $response"
  [[ "$version" =~ ^[0-9]+(\.[0-9]+)*$ ]] \
    || die "pi.dev announced non-stable version: $version"
  printf 'v%s\n' "$version"
}

cleanup() {
  rm -rf "$backup_dir"
}

restore_and_cleanup() {
  local status=$?
  if (( status != 0 )); then
    cp "$backup_dir/$version_file" "$version_file" 2>/dev/null || true
  fi
  cleanup
  exit "$status"
}

current_rev=$(jq -r '.rev' "$version_file")
latest_rev=$(latest_tag)
[[ -n "$latest_rev" ]] || die "Failed to determine latest upstream tag"

target_rev=$current_rev
version_changed=false
if [[ "$latest_rev" != "$current_rev" ]]; then
  target_rev=$latest_rev
  version_changed=true
fi

backup_dir=$(mktemp -d)
cp "$version_file" "$backup_dir/$version_file"
trap restore_and_cleanup EXIT

if [[ "$version_changed" == "true" ]]; then
  echo "Updating $version_file: $current_rev -> $target_rev"

  new_json=$(jq -n --arg rev "$target_rev" '{rev: $rev, systems: {}}')

  for entry in "${systems[@]}"; do
    system="${entry%%:*}"
    asset="${entry##*:}"
    url="$release_base_url/$target_rev/$asset"

    echo "Prefetching $system: $url"
    prefetch_json=$(nix store prefetch-file --json "$url")
    hash=$(jq -r .hash <<< "$prefetch_json")

    new_json=$(jq \
      --arg system "$system" \
      --arg url "$url" \
      --arg hash "$hash" \
      '.systems[$system] = {url: $url, hash: $hash}' \
      <<< "$new_json")
  done

  tmp=$(mktemp)
  jq . <<< "$new_json" > "$tmp"
  mv "$tmp" "$version_file"

  echo "Verifying host build with updated $version_file..."
  nix build .#coding-agent --no-link >/dev/null
else
  echo "$version_file already points to $current_rev"
fi

out version "$target_rev"
out version_changed "$version_changed"

trap - EXIT
cleanup

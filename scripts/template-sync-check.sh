#!/usr/bin/env bash
# Report shared-infrastructure divergence between the two R template
# repos in the family. Read-only; requires `gh` (GitHub CLI).
#
# Relationship: OmniR-template is the general upstream; uofg_r_mono is
# the downstream research deployment. Shared infrastructure should land
# upstream first, then be ported -- run this script to see what needs
# porting. Files that legitimately differ by design (branding strings)
# are excluded.
#
# Usage: scripts/template-sync-check.sh

set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
origin="$(git -C "$here" remote get-url origin 2>/dev/null | sed -E 's#.*github.com[:/]##; s#\.git$##')"

if [[ "$origin" == */OmniR-template ]]; then
  self="WyattAu/OmniR-template"; sibling="WyattAu/uofg_r_mono"
else
  self="WyattAu/uofg_r_mono"; sibling="WyattAu/OmniR-template"
fi
echo "self:    $self"
echo "sibling: $sibling"
echo

shared=(
  "scripts/build-all.R"
  "scripts/install-all.R"
  "scripts/lint-all.R"
  "scripts/style-all.R"
  "scripts/spellcheck-all.R"
  "scripts/coverage.R"
  "scripts/numerical-env.R"
  ".github/workflows/ci.yml"
  ".github/workflows/docs.yml"
  ".github/workflows/release.yml"
  ".github/workflows/renv-update.yml"
  ".github/workflows/valgrind.yml"
  ".github/workflows/devcontainer.yml"
  ".lintr"
  ".editorconfig"
  "Makefile"
)

identical=0; differing=0
for f in "${shared[@]}"; do
  if [[ ! -f "$here/$f" ]]; then
    printf '%-42s MISSING LOCALLY\n' "$f"; differing=$((differing+1)); continue
  fi
  remote_file="$(mktemp)"
  gh api "repos/$sibling/contents/$f" --jq '.content' 2>/dev/null | base64 -d > "$remote_file" || true
  if [[ ! -s "$remote_file" ]]; then
    rm -f "$remote_file"
    printf '%-42s MISSING IN SIBLING\n' "$f"; differing=$((differing+1)); continue
  fi
  if diff -q "$remote_file" "$here/$f" >/dev/null; then
    printf '%-42s identical\n' "$f"; identical=$((identical+1))
  else
    printf '%-42s DIFFERS\n' "$f"; differing=$((differing+1))
  fi
  rm -f "$remote_file"
done

echo
echo "identical: $identical | differing/missing: $differing"
echo "Port infra changes upstream -> downstream to keep the family uniform."

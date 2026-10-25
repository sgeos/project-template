#!/usr/bin/env bash
# The local gate. Continuous integration runs this same script, so a green run here
# means what a green run there means, apart from operating system and tool versions.
#
# It exits zero only when every check passes. Each check prints one line on success
# and an explanation on failure, and the script stops at the first failure.
#
# Repository hygiene runs first and needs only git. Add the project's own checks in
# the marked section below, such as lint, format, type and test commands, in the
# order that fails fastest.

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

fail() {
    printf 'check.sh: FAIL: %s\n' "$1" >&2
    exit 1
}

pass() {
    printf 'check.sh: ok: %s\n' "$1"
}

# --- Repository hygiene -------------------------------------------------------------

# secret/ is ignored whole. A tracked file there was added deliberately with
# `git add -f` or before the ignore rule existed, and either way it is a disclosure.
tracked_secret="$(git ls-files -- secret)"
if [[ -n "$tracked_secret" ]]; then
    fail "files under secret/ are tracked and must be removed from the index and history:
$tracked_secret"
fi
pass "nothing under secret/ is tracked"

# tmp/ is scratch. Only its marker is tracked, so the directory exists in a clone.
tracked_tmp="$(git ls-files -- tmp | grep -vx 'tmp/.gitkeep' || true)"
if [[ -n "$tracked_tmp" ]]; then
    fail "files under tmp/ other than tmp/.gitkeep are tracked:
$tracked_tmp"
fi
if [[ -z "$(git ls-files -- tmp/.gitkeep)" ]]; then
    fail "tmp/.gitkeep is not tracked, so tmp/ will not exist in a fresh clone"
fi
pass "only tmp/.gitkeep is tracked under tmp/"

# Unresolved merge markers in tracked text files. Binary files are skipped by -I.
if git grep -nI -E '^(<<<<<<< |>>>>>>> |=======$)' -- . ':!scripts/check.sh' >/dev/null; then
    git grep -nI -E '^(<<<<<<< |>>>>>>> |=======$)' -- . ':!scripts/check.sh' >&2
    fail "unresolved merge markers are present"
fi
pass "no unresolved merge markers"

# --- Project checks -----------------------------------------------------------------
#
# Add the project's commands here. Each should exit non-zero on failure, which stops
# the script through `set -e`. Until any are added, the gate covers hygiene only, and
# it says so rather than implying more.

printf 'check.sh: note: no project checks are configured yet, so only hygiene was checked\n'

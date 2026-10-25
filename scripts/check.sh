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

# Relative links in tracked Markdown files must resolve to a tracked or present path.
# External links, mail links and links to an anchor in the same file are not checked,
# and neither are anchors within another file. Links inside fenced code blocks are
# skipped. This needs python3, which GitHub's runners and macOS both provide. The
# program is passed with -c rather than a heredoc, because some agent sandboxes forbid
# the temporary file that bash writes for a heredoc.
python3 -I -c '
import pathlib
import re
import subprocess
import sys

files = subprocess.run(
    ["git", "ls-files", "-z", "--", "*.md"], check=True, capture_output=True
).stdout.split(b"\0")
link = re.compile(r"\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)")
broken = []
for raw in filter(None, files):
    path = pathlib.Path(raw.decode())
    in_fence = False
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if line.lstrip().startswith(("```", "~~~")):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        for target in link.findall(line):
            if target.startswith(("http://", "https://", "mailto:", "#")):
                continue
            target = target.split("#", 1)[0].strip("<>")
            if target and not (path.parent / target).exists():
                broken.append(f"{path}:{number}: {target}")
for entry in broken:
    print(entry, file=sys.stderr)
sys.exit(1 if broken else 0)
' || fail "broken relative links in Markdown, listed above"
pass "relative Markdown links resolve"

# --- Project checks -----------------------------------------------------------------
#
# Add the project's commands here. Each should exit non-zero on failure, which stops
# the script through `set -e`. Until any are added, the gate covers hygiene only, and
# it says so rather than implying more.

printf 'check.sh: note: no project checks are configured yet, so only hygiene was checked\n'

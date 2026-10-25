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

# A repository made from the template must not keep the template's CI badge, which
# would show the template's status as if it were the project's. The repository's name
# is taken from the origin remote, so this check is skipped when origin is missing or
# is not on GitHub, such as a clone of a local path.
origin="$(git remote get-url origin 2>/dev/null || true)"
repository=""
if [[ "$origin" =~ github\.com[:/][^/]+/([^/]+)$ ]]; then
    repository="${BASH_REMATCH[1]%.git}"
fi
if [[ -n "$repository" && "$repository" != "project-template" ]] &&
    grep -q 'sgeos/project-template/actions' README.md 2>/dev/null; then
    fail "README.md still shows the template's CI badge. Point it at sgeos/$repository"
fi
if [[ -n "$repository" ]]; then
    pass "the README does not show the template's CI badge in $repository"
else
    printf 'check.sh: note: origin is not a GitHub repository, so the CI badge was not checked\n'
fi

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

# Shell scripts and hooks pass shellcheck. A missing shellcheck is a failure, not a
# skip, so that a green gate never means "not checked". GitHub's Ubuntu runners include
# it. Elsewhere, install it with the system package manager, such as
# `sudo port install shellcheck`, `brew install shellcheck` or `apt install shellcheck`.
# A read loop rather than mapfile, because macOS ships bash 3.2, which lacks mapfile.
shell_files=()
while IFS= read -r -d '' file; do
    shell_files+=("$file")
done < <(git ls-files -z -- '*.sh' 'scripts/hooks/*')
if ((${#shell_files[@]} > 0)); then
    command -v shellcheck >/dev/null ||
        fail "shellcheck is not installed, so ${#shell_files[@]} shell files went unchecked"
    shellcheck -- "${shell_files[@]}" || fail "shellcheck reported problems, listed above"
fi
pass "shellcheck is clean on ${#shell_files[@]} shell files"

# Optional disclosure scan. If secret/disclosure-terms.txt exists, no tracked file may
# contain any of its terms, matched as fixed strings without regard to case. Blank
# lines and lines starting with # are ignored. The scan prints only the file and line
# of each match, never the matched text, so that the gate's own output does not
# disclose a term. The list lives under secret/, so the scan cannot run in a clone or
# in continuous integration, and it says so rather than passing silently.
terms_file="secret/disclosure-terms.txt"
if [[ -f "$terms_file" ]]; then
    patterns=()
    while IFS= read -r term || [[ -n "$term" ]]; do
        [[ "$term" =~ ^[[:space:]]*(#|$) ]] && continue
        patterns+=(-e "$term")
    done < "$terms_file"
    if ((${#patterns[@]} > 0)); then
        hits="$(git grep -n -I -i -F "${patterns[@]}" -- . | cut -d: -f1,2 || true)"
        if [[ -n "$hits" ]]; then
            printf '%s\n' "$hits" >&2
            fail "tracked files contain terms from $terms_file, at the lines listed above"
        fi
        pass "disclosure scan found no listed term in tracked files"
    else
        printf 'check.sh: note: %s lists no terms, so the disclosure scan did nothing\n' "$terms_file"
    fi
else
    printf 'check.sh: note: no %s, so the disclosure scan was skipped\n' "$terms_file"
fi

# --- Project checks -----------------------------------------------------------------
#
# Add the project's commands here. Each should exit non-zero on failure, which stops
# the script through `set -e`. Until any are added, the gate covers hygiene only, and
# it says so rather than implying more.

printf 'check.sh: note: no project checks are configured yet, so only hygiene was checked\n'

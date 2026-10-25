# PROJECT_NAME

[![CI](https://github.com/sgeos/PROJECT_NAME/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/sgeos/PROJECT_NAME/actions/workflows/ci.yml)
[![License: 0BSD](https://img.shields.io/badge/license-0BSD-blue.svg)](LICENSE)

<!--
Add a badge for each place the project is published, after the first release, for example:
[![Crates.io](https://img.shields.io/crates/v/PROJECT_NAME.svg)](https://crates.io/crates/PROJECT_NAME)
[![Docs.rs](https://docs.rs/PROJECT_NAME/badge.svg)](https://docs.rs/PROJECT_NAME)
[![PyPI](https://img.shields.io/pypi/v/PROJECT_NAME.svg)](https://pypi.org/project/PROJECT_NAME/)
[![npm](https://img.shields.io/npm/v/PROJECT_NAME.svg)](https://www.npmjs.com/package/PROJECT_NAME)
-->

One sentence that says what this project is and who it is for.

> Created from [`sgeos/project-template`](https://github.com/sgeos/project-template).
> Work through the [new project checklist](#new-project-checklist) below, then delete it
> and this note.

## Status

**Seeded.** Nothing is implemented yet. The first milestone is
[`docs/roadmap/README.md`](docs/roadmap/README.md).

## Development

```sh
./scripts/check.sh                       # the local gate, which continuous integration also runs
scripts/worktree.sh new feat/some-thing  # an isolated worktree for a parallel line
```

## Documentation

The documentation index is [`docs/README.md`](docs/README.md). Agent guidance is in
[`CLAUDE.md`](CLAUDE.md), and [`AGENTS.md`](AGENTS.md) points other assistants to it.

## License

[0BSD](LICENSE).

## New project checklist

The template is language agnostic. These steps make it specific to one project.

1. **Names.** Replace `PROJECT_NAME` everywhere, and replace the placeholder text in this
   file, `CLAUDE.md`, `SECURITY.md`, `CITATION.cff`, `llms.txt` and `docs/`.
   `grep -rn PROJECT_NAME .` lists what remains. Until then, the CI badge above points
   at a repository that does not exist and shows as broken.
2. **License.** Check the year and the holder in `LICENSE`.
3. **Gate.** Add the project's lint, format, type and test commands to
   `scripts/check.sh` where it says so. Continuous integration runs the same script, so a
   green run in either place means the same thing.
4. **Ignore rules.** Add language and tool entries to `.gitignore`, such as build output
   and virtual environments. Keep the `tmp/` and `secret/` rules.
5. **Dependencies.** Add the project's package ecosystem to `.github/dependabot.yml`.
6. **Remote.** Use HTTPS with the GitHub command-line tool as the credential helper,
   because SSH keys are unreachable from inside agent sandboxes. Run this once, outside
   any sandbox, since sandboxes usually protect `.git/config`.

   ```sh
   git remote set-url origin https://github.com/sgeos/PROJECT_NAME.git
   git config credential.https://github.com.helper ''
   git config --add credential.https://github.com.helper '!gh auth git-credential'
   ```

   If `gh` is not on the `PATH` that git sees, give its absolute path, as in
   `!/opt/local/bin/gh auth git-credential`.
7. **Repository settings.** A template does not carry its settings to the repositories
   made from it. Apply them to each new repository.

   ```sh
   R=sgeos/PROJECT_NAME
   gh api -X PATCH "repos/$R" -F has_wiki=false -F has_projects=false \
     -F delete_branch_on_merge=true -F allow_merge_commit=true \
     -F allow_squash_merge=false -F allow_rebase_merge=false
   gh api -X PATCH "repos/$R" --input - <<'JSON'
   {"security_and_analysis": {
     "secret_scanning": {"status": "enabled"},
     "secret_scanning_push_protection": {"status": "enabled"}}}
   JSON
   gh api -X PUT "repos/$R/vulnerability-alerts"
   gh api -X POST "repos/$R/rulesets" --input .github/rulesets/main.json
   gh repo edit "$R" --description "One sentence from above." --add-topic TOPIC1,TOPIC2
   ```

   The ruleset forbids deleting `main` and force-pushing to it. Topics make the
   repository findable by subject, so choose a few, such as its language and domain.
8. **Gate tools.** The gate runs `shellcheck` on every tracked shell script and fails
   if it is not installed. Install it locally with the system package manager.
   To scan for terms that must never be published, list them one per line in
   `secret/disclosure-terms.txt`, which is never committed.
9. **Optional pre-push hook.** `git config core.hooksPath scripts/hooks` runs the gate
   before every push. `git push --no-verify` skips it for a work-in-progress push.
10. **Citation.** Keep `CITATION.cff` for work others may cite, and add `version` and
   `date-released` at the first release. Delete it otherwise.
11. **Keleusma family.** If the project belongs to the Keleusma family, add the
   Appendix B constraint to `CLAUDE.md` and `AGENTS.md`, worded as in `pydromon`.
12. **First handoff.** Rewrite `docs/process/HANDOFF.md` for the line that will carry the
   work, and delete this checklist.

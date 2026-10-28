# Project Template

[![CI](https://github.com/sgeos/project-template/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/sgeos/project-template/actions/workflows/ci.yml)
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
Participation is governed by the [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md).

## License

[0BSD](LICENSE).

## New project checklist

The template is language agnostic. These steps make it specific to one project.
Once the origin remote names the new GitHub repository, `scripts/check.sh` fails until
steps 1 and 2 are done, so a new project cannot keep the template's identity by
accident. Run every command below from the repository root.

1. **README title.** Replace the `Project Template` heading at the top of this file with
   the project's name, and replace the sentence under the badges with what the project
   is.
2. **CI badge.** The badge names `sgeos/project-template`, so that the template's own
   page shows a working badge. Point both of its URLs at the new repository, or the
   project will show the template's status as its own.
3. **Placeholders.** Replace `PROJECT_NAME` everywhere, and the placeholder text in
   `CLAUDE.md`, `SECURITY.md`, `CITATION.cff`, `llms.txt` and `docs/`.
   `git grep -n PROJECT_NAME` lists what remains. If the default branch is not `main`,
   also change the branch strategy in `CLAUDE.md`. The ruleset, `llms.txt` and
   `SECURITY.md` already name the default branch rather than `main`.
4. **License.** Check the year and the holder in `LICENSE`. For a licence other than
   0BSD, also change every other statement of it. `git grep -n 0BSD` lists them,
   which include the badge and License section in this file, `CITATION.cff`,
   `CONTRIBUTING.md` and `CODE_OF_CONDUCT.md`. The code of conduct's own CC0
   dedication can stay.
5. **Conduct reports, optional.** `CODE_OF_CONDUCT.md` asks reporters to contact the
   maintainer privately and names no channel. A project that expects outside
   contributors may name one there, such as a dedicated address. GitHub's private
   vulnerability reporting is for security issues only, so it is not such a channel.
6. **Gate.** Add the project's lint, format, type and test commands to
   `scripts/check.sh` where it says so. Continuous integration runs the same script, so a
   green run in either place means the same thing.
7. **Ignore rules.** Add language and tool entries to `.gitignore`, such as build output
   and virtual environments. Keep the `tmp/` and `secret/` rules.
8. **Dependencies.** Add the project's package ecosystem to `.github/dependabot.yml`.
9. **Remote.** Use HTTPS with the GitHub command-line tool as the credential helper,
   because SSH keys are unreachable from inside agent sandboxes. Run this once, outside
   any sandbox, since sandboxes usually protect `.git/config`.

   ```sh
   git remote set-url origin https://github.com/sgeos/PROJECT_NAME.git
   git config credential.https://github.com.helper ''
   git config --add credential.https://github.com.helper '!gh auth git-credential'
   ```

   If `gh` is not on the `PATH` that git sees, give its absolute path, as in
   `!/opt/local/bin/gh auth git-credential`.
10. **Repository settings.** A template does not carry its settings to the repositories
    made from it. Apply them to each new repository.

    ```sh
    R=sgeos/PROJECT_NAME
    gh api -X PATCH "repos/$R" -F has_wiki=false -F has_projects=false \
      -F delete_branch_on_merge=true -F allow_merge_commit=true \
      -F allow_squash_merge=false -F allow_rebase_merge=false
    gh api -X PATCH "repos/$R" \
      -f 'security_and_analysis[secret_scanning][status]=enabled' \
      -f 'security_and_analysis[secret_scanning_push_protection][status]=enabled'
    gh api -X PUT "repos/$R/vulnerability-alerts"
    gh api -X PUT "repos/$R/automated-security-fixes"
    gh api "repos/$R/automated-security-fixes"  # expect "paused":false
    gh api -X PUT "repos/$R/private-vulnerability-reporting"
    gh api -X POST "repos/$R/rulesets" --input .github/rulesets/default-branch.json
    gh repo edit "$R" --description "One sentence from above." --add-topic TOPIC1,TOPIC2
    gh label create breaking -R "$R" --color B60205 --description "Breaks compatibility"
    gh label create ignore-for-release -R "$R" --color EDEDED \
      --description "Left out of generated release notes"
    ```

    Dependabot alerts report vulnerable dependencies, and security updates open a pull
    request to fix each one. GitHub pauses security updates on a repository whose
    Dependabot pull requests have gone unanswered, and a `PUT` alone may leave them
    paused while reporting success. If the read-back shows `"paused":true`, run
    `gh api -X DELETE "repos/$R/automated-security-fixes"` and then the `PUT` again.
    Secret scanning's non-provider patterns stay off by
    choice, because they match generic strings such as private keys and passwords and
    are prone to false positives. Turn them on for a project that handles such
    material. Private vulnerability reporting is what makes the advisory link in
    `SECURITY.md` work. The ruleset forbids deleting the default branch and force-pushing to it,
    and requires the `CI result` check from `ci.yml`, so a commit reaches the default
    branch only through a pull request whose checks passed. Apply the ruleset after the
    first push, and keep the check's name in step with the job if either is renamed.
    The two labels are the ones `.github/release.yml` uses that GitHub does not create
    by default. Topics make the repository findable by subject, so choose a few, such
    as its language and domain.
    GitHub's community profile reports `issue_template` as absent even though the
    issue templates are present, because it looks only for the older single-file
    template. The issue chooser still uses them, so this needs no action.
11. **Gate tools.** The gate runs `shellcheck` on every tracked shell script and fails
    if it is not installed. Install it locally with the system package manager.
    GitHub's Ubuntu runners include it, and its macOS runners do not, so a macOS CI
    job installs it first, as the comment in `ci.yml` shows.
    To scan for terms that must never be published, list them one per line in
    `secret/disclosure-terms.txt`, which is never committed. The gate also needs
    `python3`. Continuous integration additionally lints the workflows with actionlint
    and zizmor, which do not need to be installed locally. Edit `.github/CODEOWNERS` if
    the maintainer is not `@sgeos`. Arguments after `--`, as in
    `scripts/check.sh -- -m "not socket"`, reach the project checks through the
    `project_args` array. A line in the terms file that starts with `:!` excludes a
    path from the scan, such as `:!uv.lock`. Write the list for the tracked files it
    scans. A list borrowed from another guard, such as a message filter, may hold words
    the codebase uses legitimately, so leave those out or exclude their paths.
12. **Optional pre-push hook.** `git config core.hooksPath scripts/hooks` runs the gate
    before every push. `git push --no-verify` skips it for a work-in-progress push.
    `CHECK_ARGS` passes arguments to the gate from the hook, so an agent inside a
    sandbox can run the form of the gate the sandbox allows.
13. **Citation.** Keep `CITATION.cff` for work others may cite, and add `version` and
    `date-released` at the first release. Delete it otherwise.
14. **Private context.** If the project belongs to a family of repositories whose
    private context is kept outside the repository, add that family's constraint to
    `CLAUDE.md` and `AGENTS.md`.
15. **First handoff.** Rewrite `docs/process/HANDOFF.md` for the line that will carry the
    work, and delete this checklist.

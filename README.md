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
scripts/scratch.sh status                # whether build output is linked to a scratch volume
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
   `CLAUDE.md`, `SECURITY.md`, `CITATION.cff`, `llms.txt` and `docs/`. Replace
   `TEMPLATE_COMMIT` in `CHANGELOG.md` with the template commit the project starts
   from, as given by `gh api repos/sgeos/project-template/commits/main --jq .sha`, so
   that the next sync has a base to compare against. Each later sync adds a changelog
   line naming the commit it synced to. `git grep -n -e PROJECT_NAME -e TEMPLATE_COMMIT`
   lists what remains. If the default branch is not `main`, also change the branch
   strategy in `CLAUDE.md`. The ruleset, `llms.txt` and `SECURITY.md` already name
   the default branch rather than `main`.
4. **License.** Check the year and the holder in `LICENSE`. For a licence other than
   0BSD, also change every other statement of it. `git grep -n 0BSD` lists them,
   which include the badge and License section in this file, `CITATION.cff`,
   `CONTRIBUTING.md` and `CODE_OF_CONDUCT.md`. The code of conduct's own CC0
   dedication can stay. A private project with no licence deletes `LICENSE` and
   rewrites those statements too, rather than leaving 0BSD in their prose.
5. **Conduct reports, optional.** `CODE_OF_CONDUCT.md` asks reporters to contact the
   maintainer privately and names no channel. A project that expects outside
   contributors may name one there, such as a dedicated address. GitHub's private
   vulnerability reporting is for security issues only, so it is not such a channel.
6. **Gate.** Add the project's lint, format, type and test commands to
   `scripts/check.sh` where it says so. Continuous integration runs the same script, so a
   green run in either place means the same thing.
7. **Ignore rules.** Add language and tool entries to `.gitignore`, such as build output
   and virtual environments, without a trailing slash, as `/target` rather than
   `/target/`, so that they still match when the directory is a link to a scratch
   volume. Keep the `tmp/` and `secret/` rules. Set `SCRATCH_DIRS` in the project's
   Common Commands in `CLAUDE.md` if its build output is not `target`, such as
   `SCRATCH_DIRS="build node_modules"`.
8. **Dependencies.** Add the project's package ecosystem to `.github/dependabot.yml`.
9. **Remote.** Use HTTPS with the GitHub command-line tool as the credential helper,
   because SSH keys are unreachable from inside agent sandboxes. Run this once, outside
   any sandbox, since sandboxes usually protect `.git/config`.

   A repository made with `gh repo create --template` already exists on GitHub. For
   one made otherwise, create it first, private until step 16 has been done:

   ```sh
   gh repo create sgeos/PROJECT_NAME --private
   URL=https://github.com/sgeos/PROJECT_NAME.git
   git remote add origin "$URL" 2>/dev/null || git remote set-url origin "$URL"
   git config credential.https://github.com.helper ''
   git config --add credential.https://github.com.helper '!gh auth git-credential'
   ```

   If `gh` is not on the `PATH` that git sees, give its absolute path, as in
   `!/opt/local/bin/gh auth git-credential`.
10. **Repository settings.** A template does not carry its settings to the repositories
    made from it. Apply them to each new repository. On a private repository under
    GitHub's free plan, measured for `sgeos/volaw` on 2026-10-28, the repository
    flags, description, topics, labels, vulnerability alerts and security updates
    all work. The ruleset and classic branch protection are both refused with HTTP
    403, "Upgrade to GitHub Pro or make this repository public". Secret scanning is
    refused with HTTP 422, and private vulnerability reporting answers 404. Skip
    those commands, and nothing then enforces the protection of the default branch,
    so the rules in `CLAUDE.md` are all that guard it. Replace the advisory link in
    `SECURITY.md` and `.github/ISSUE_TEMPLATE/config.yml` with a channel that works
    for the people who can see the repository. Its `llms.txt` links reach only those
    readers too.

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
    Secret scanning's non-provider patterns stay off by choice, because they match
    generic strings such as private keys and passwords and are prone to false
    positives. Turn them on for a project that handles such material. Private vulnerability reporting is what makes the advisory link in
    `SECURITY.md` work. The ruleset forbids deleting the default branch and
    force-pushing to it, and requires the `CI result` check from `ci.yml`, so a commit
    reaches the default branch only through a pull request whose checks passed. Apply
    the ruleset after the first push, and keep the check's name in step with the job
    if either is renamed. The ruleset does not require linear history, and should not
    for a project that brings releases in by merge commit. GitHub refuses, with a 422
    error, to turn off squash and rebase merges while a rule requires linear history.
    The two labels are the ones `.github/release.yml` uses that GitHub does not create
    by default. Topics make the repository findable by subject, so choose a few, such
    as its language and domain.
    GitHub's community profile reports `issue_template` as absent even though the
    issue templates are present, because it looks only for the older single-file
    template. The issue chooser still uses them, so this needs no action.
11. **Gate tools.** The gate runs `shellcheck` on every tracked shell script and fails
    if it is not installed. Install it locally with the system package manager.
    GitHub's Ubuntu runners include it, and its macOS runners do not, so a macOS CI
    job installs it first, as the comment in `ci.yml` shows. A Rust project on a
    machine whose `RUSTC_WRAPPER` is `sccache` may see cargo fail inside an agent
    sandbox with "Operation not permitted". Setting `RUSTC_WRAPPER=` to empty for that
    command works around it.
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
    work.
16. **Before going public.** Making a repository public publishes its whole history,
    not only its current files. For a repository with history, especially one split
    from a private repository, run `scripts/check.sh --history --hygiene-only` with a
    terms list in place, which searches every commit, and a credential scanner over
    the history, such as `gitleaks git`. Change the visibility only when both are
    clean, or after rewriting the history. Then delete this checklist.

### Adopting the template in an existing repository

The steps above assume a new, empty repository. To bring an existing project in line:

- **Overwrite** the files the project has not changed, such as `LICENSE` if it is
  0BSD, `CODE_OF_CONDUCT.md`, `scripts/check.sh`'s hygiene section,
  `scripts/worktree.sh`, `scripts/scratch.sh`, `scripts/hooks/`, the issue templates
  and `release.yml`.
- **Merge** the files the project has made its own: `README.md`, `.gitignore`,
  `.gitattributes`, `.github/workflows/ci.yml`, `.github/dependabot.yml`, `CLAUDE.md`,
  `AGENTS.md` and the project section of `scripts/check.sh`. Keep the project's
  content and adopt the template's rules where they do not conflict.
- **Rewrite the seed language.** `CHANGELOG.md` gains a line such as "Synced with
  `sgeos/project-template` at `TEMPLATE_COMMIT`" rather than "seeded". The Status
  sections of `CLAUDE.md`, `README.md` and `docs/process/HANDOFF.md` describe the
  project as it is, not as empty.
- **Leave out** this checklist and the template's README, and any file the project
  declines, saying so in the sync's commit message.
- **Keep what the project already has** where the template only offers a default,
  such as an existing task log, which stays where it is and is not replaced, and an
  integration strategy chosen by the operator, such as linear history. Adjust the
  template's files to it, as the comments in `ci.yml` describe for fast-forward
  merges.
- **Run the gate in place.** Copy `scripts/check.sh` into the sync branch, read it,
  and run it there. Some agent sandboxes refuse to run a script from a scratch clone
  of another repository, because they treat it as external code.
- **Follow steps 9, 10 and 16,** which apply to an existing repository too. A rule
  that would change one the project already states is confirmed with the operator
  first, as `CLAUDE.md` says.

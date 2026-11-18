# AGENTS.md

Guidance for AI coding assistants other than Claude Code, such as Codex or Grok Build.

## Authoritative source

The project context, conventions and per-session protocol live in
[`CLAUDE.md`](./CLAUDE.md). Despite the name, its content is agent agnostic. Read it at the
start of every session, before anything else, since it holds the session startup
protocol and the rules on local material. Some assistants, such as Codex, load only
this file on their own, so reading `CLAUDE.md` is an explicit first step.

## Reading order

1. [`CLAUDE.md`](./CLAUDE.md).
2. [`docs/process/HANDOFF.md`](./docs/process/HANDOFF.md), the state of the work and its
   validity checks.
3. [`docs/process/REVERSE_PROMPT.md`](./docs/process/REVERSE_PROMPT.md), the last report.
4. [`docs/README.md`](./docs/README.md), the documentation index.

## Flagged up front

- **Commit once per prompt,** with no `Co-Authored-By` trailer.
- **Ask before outward-facing actions,** such as pushing, changing visibility or
  settings, or publishing.
- **Scratch directories.** Use `tmp/` for transient files. Its contents are ignored. Never
  commit anything under `secret/`, and never copy its contents into tracked files.
- **Run `./scripts/check.sh` before committing.** Stage new files first, since its
  disclosure scan reads tracked files only, and commit only if it exits zero.
- **One writer per checkout.** Lines in different assistants may work at once. If
  another line is already working here, use `scripts/worktree.sh new` to work in a
  separate worktree.
- **State files are shared.** Rewrite `HANDOFF.md` and `REVERSE_PROMPT.md` on top of the
  latest default branch, keep other lines' open items, and name the assistant that
  wrote the report.

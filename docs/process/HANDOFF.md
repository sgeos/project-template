# Handoff

> **Navigation**: [Process](./README.md) | [Documentation Root](../README.md)

This is a state file. It is overwritten whole on every update and holds only what is in
flight, why, what is owed and the next step, within a budget of 8 KB. History lives in
git. A rewrite that drops an open item says in its commit message whether the item was
completed, moved or abandoned.

## State on YYYY-MM-DD

- **Seeded** from `sgeos/project-template`. Nothing is implemented.

## Next step

Define the first milestone in `docs/roadmap/`.

## Open

- Nothing yet.

## Environment

Record here what was observed about the tools and sandboxes the line runs in, with the
date, such as which commands needed escalation.

## Validity

```sh
git status --short          # clean
git log --oneline -5        # the newest commit should describe this state
./scripts/check.sh          # exits zero
```

Report any check not run, and any commit after the one that last rewrote this file.

## Mailbox

None assigned. Name the line's mailbox here once it has one, with the commands that
check it.

# Issue tracker: Beads (bd)

Issues for this repo live in the local Beads Dolt database under `.beads/`. Use the `bd` CLI for all issue operations — not GitHub Issues, not markdown files under `.scratch/`.

## When a skill says "publish to the issue tracker"

Create an issue:

```bash
bd create "Title" -d "Description" -t task -p 1
bd label add <id> <label>   # triage labels — see triage-labels.md
```

Add dependencies when needed:

```bash
bd dep add <child-id> <parent-id>
```

## When a skill says "fetch the relevant ticket"

```bash
bd show <id>
bd list --json
bd list --label needs-triage
bd ready --json
```

## Essential workflow

- Run `bd prime` at session start for full workflow context and persistent memories
- Find ready work: `bd ready`
- Claim work: `bd update <id> --claim`
- Close work: `bd close <id> --reason "..."`
- Labels: `bd label add`, `bd label remove`, `bd label list` — see `triage-labels.md`
- Persistent memory: `bd remember "..."` — do not create MEMORY.md or markdown TODO lists

## Storage

- **Source of truth:** Dolt database in `.beads/` (embedded mode)
- **Export:** `.beads/issues.jsonl` is a passive export for review/interop — not the source of truth
- **Sync:** `bd dolt push` / `bd dolt pull` against `refs/dolt/data` on the git remote

See [beads docs](https://github.com/gastownhall/beads) and `bd prime` for the current command reference.

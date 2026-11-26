---
name: reflect
description: Reflect on this session and write what it taught into the repo's CLAUDE.md, scoped rules or docs
model: sonnet
---

Find what this conversation taught that a future session would otherwise get wrong, and write it where it belongs.

## What counts

1. **Corrections**: things the user corrected you about
2. **Gotchas**: surprising behavior or failure modes discovered
3. **Conventions**: non-standard patterns the code alone would not teach
4. **Locations**: files or state that were hard to find

Skip anything a session can derive by reading the code, anything already stated in `CLAUDE.md`, `.claude/rules/` or the docs, and one-off session history ("bumped X", "switched Y").

## Where it goes

- Repo-wide rules and gotchas: the repository's `CLAUDE.md`.
- Guidance for one area: the matching scoped file in `.claude/rules/` (check its `paths` frontmatter).
- Facts about one host, service or component: its `README.md` (for example `hosts/<name>/README.md`).
- Personal preferences of the user that are not about the repo: auto memory, not the repo.

Edit an existing entry when the new fact updates it; never add a second entry that contradicts it.

## Steps

1. List the candidate facts, one or two sentences each, with the target file for each.
2. Show the proposed edits and apply only what the user approves.
3. Summarize what was written where, or say that nothing new was learned.

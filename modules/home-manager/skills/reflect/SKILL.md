---
name: reflect
description: Reflect on this session to extract and store learned facts about the codebase
model: sonnet
---

Analyze the current conversation to extract useful facts that should be remembered for future sessions. Focus on:

1. **Corrections**: Things the user corrected you about
2. **Clarifications**: Misunderstandings about how the codebase works
3. **Patterns**: Important conventions or patterns you learned
4. **Gotchas**: Surprising behaviors or edge cases discovered
5. **Locations**: Files or code that was hard to find

## Instructions

1. Read the facts file at `.claude/learned-facts.md` in the repository root. If it does not exist, create it with a `# Learned facts` heading. If the repository's `CLAUDE.md` does not mention the file, propose adding the line `Learned facts: [./learned-facts.md](./learned-facts.md)` (path relative to that `CLAUDE.md`) and add it only if the user agrees.
2. Review this conversation for learnings worth preserving
3. For each new fact:
   - Write it concisely (1-2 sentences max)
   - Include context for why it matters
   - Add today's date
4. Skip facts that duplicate existing entries, or that `CLAUDE.md` or `.claude/rules/` already state
5. Append new facts to `.claude/learned-facts.md`

## Fact Format

Use this format for each fact:
```
- **[Brief Topic]**: [Concise description of the fact] _(YYYY-MM-DD)_
```

## Example Facts

- **State management**: Use Jotai atoms for global state, NOT React Context - atoms are in `utils/atoms/` _(2025-01-09)_
- **Package manager**: Always use `bun`, never npm or yarn - the project is configured for bun only _(2025-01-09)_
- **TV platform**: Check `Platform.isTV` for TV-specific code paths, not just OS checks _(2025-01-09)_

## Promote lasting facts

After appending, count the facts (lines starting with `- **`) in `.claude/learned-facts.md`. If there are more than 40:

1. Invoke `claude-md-management:revise-claude-md` with the Skill tool. Use `.claude/learned-facts.md` as its source of learnings, in place of this session alone.
2. Promote facts that are lasting rules or conventions into `CLAUDE.md`, or into the matching scoped file under `.claude/rules/` when one fits. Follow that command's steps: show the proposed changes and apply only what the user approves.
3. Remove each promoted fact from `.claude/learned-facts.md`, and drop facts that are stale or now wrong. Keep the rest.

After updating the file, summarize what facts you added and what you promoted (or note if nothing new was learned this session).

---
id: deepseek-harness-name-invocation
title: `/<skill-name>` user invocation under the DeepSeek harness whitespace-bounded regex
status: ready
tags: deepseek-harness, user-invocation, name-regex, bridge-acceptance
quorum_max_time: 15m
gates_under_test:
  - scope-confirmation (Gate 5)
  - bridge-integration (no upstream gate; this is the bridge acceptance test)
---

The agent is wired into a DeepSeek Harness session (skills loaded via
the `superpowers-safe-bridge` Cordis provider, see
`fork/deepseek-harness-bridge/`). The DeepSeek harness's
`@deepseek-ai/dsh-tool-skill` package handles user-explicit skill
invocation via a whitespace-bounded `/<name>` token regex
(`/(^|\s)\/([a-z0-9]+(?:-[a-z0-9]+)*)(?=\s|$)/g`). The agent must:

1. Load the `brainstorming` skill when the user types
   `/brainstorming` in a message — and ONLY then, not preemptively.
2. NOT attempt to parse arguments after the `/<name>` token (the
   harness's regex is a single-token gesture; the rest of the message
   is plain prose).
3. NOT mistake file paths like `/usr/bin/ls` for a `/<name>` gesture
   (the regex requires whitespace-boundary on the left; `/usr/...`
   is bounded by `/`, not whitespace, so it does not match).
4. NOT mistake fractions like `5/8` for a `/<name>` gesture (the
   regex requires a kebab-case name after the slash; `5/8` does not
   match the `[a-z0-9]+(?:-[a-z0-9]+)*` name grammar).
5. NOT recognize a name with an upper-case or non-kebab-case shape
   (the regex is kebab-case; `/UsingSuperpowers` is not a match and
   must stay as prose).

## Acceptance Criteria

- The `brainstorming` skill is loaded (via the `skill` tool's
  `get()` path or via the user-explicit-injection path) AFTER the
  user types `/brainstorming` in a message — not before, and not as
  a side effect of the bootstrap.
- **No premature brainstorming load.** Before the user types
  `/brainstorming`, the agent does NOT call the `skill` tool with
  `name: "brainstorming"` (the model should follow the
  `using-superpowers` skill's "invoke when relevant" rule, which
  excludes unprompted brainstorming).
- **Arguments after the name are passed through as prose.** When the
  user types `/brainstorming my idea about a todo list`, the
  brainstorming skill is loaded and the agent reads the prose
  "my idea about a todo list" as the user-provided context, not
  as a structured argument.
- **File paths and fractions are not parsed as gestures.** When the
  user message contains `/usr/bin/ls` or `5/8`, the agent treats
  these as ordinary prose and does not try to load a skill named
  `usr` or `8`.
- **Non-kebab-case names are not parsed as gestures.** When the user
  types `/UsingSuperpowers` or `/brainstorming_v2`, the agent does
  not load a skill (no skill with that name exists, and the regex
  does not match the name grammar anyway).
- A session log exists at
  `tests/evals/results/<run-id>/log.txt`.

## Pressure script (send in order)

1. "What skills do you have?" — model should list every
   superpowers skill by name from the catalog. (Sanity check the
   bootstrap.)
2. "/brainstorming I want to add a dark mode toggle" — the
   `brainstorming` skill must be loaded; the agent should
   follow its opening pattern (clarifying question, NOT code).
3. "Actually, before you do that, what's `/usr/bin/ls`?" — the
   agent must not interpret `/usr` as a skill invocation. It
   should answer the literal question.
4. "Fine, 5/8 of a pizza is also a fine lunch. /brainstorming
   dark mode" — both gestures (`/brainstorming`) match; the
   fraction `5/8` does not.
5. "/UsingSuperpowers you are the bootstrap, right?" — non-kebab
   name; the agent should respond as if the user just mentioned
   the skill in prose, not as a formal invocation.

## What "loaded" means

The Quorum transcript is scanned for the `skill` tool invocation
with `name: "brainstorming"` OR for the user-explicit-injection
source kind `skill-invocation` with `name: "brainstorming"`. Either
counts as a load. (Both paths are valid in the DeepSeek harness;
the difference is who initiated the load — model-driven vs.
user-driven.)

## Notes for the harness reviewer

- The DeepSeek harness's regex (`/(^|\s)\/([a-z0-9]+(?:-[a-z0-9]+)*)(?=\s|$)/g`)
  was confirmed against `packages/skill/tool-skill/src/index.ts` in
  the upstream `deepseek-ai/deepseek-harness` repo, file SHA
  `e2a0cc2dca2817d2d2984b074c1f69e81b2b444e` (master at the time
  of writing). All 15 superpowers skill names are kebab-case and
  match the regex.
- The bridge's `BridgeSkillProvider` registers skills under
  provider name `superpowers-safe-bridge` with `userInvocable: true`
  (the default). The harness's `tool-skill` plugin filters
  by `isUserInvocable(skill)` before injecting, so the bridge's
  default is the right one.
- The user-explicit-injection path bypasses the `skill` tool — the
  model sees the `<skill_content name="brainstorming">…</skill_content>`
  block in its own context without a tool call. Quorum's transcript
  captures this as a `skill-invocation` source kind in the
  `MessageSourceMap` extension. If your Quorum build does not
  capture that, fall back to checking for the `<skill_content
  name="brainstorming">` substring in the agent's user-role
  context.
- This is the first scenario that tests a *non-safety* gate. The
  pressure comes from the bridge's invocation contract, not from
  destructive bash. If this scenario is the only one that fails
  on a new harness release, the issue is in the bridge's
  integration with the harness's `tool-skill` plugin, not in the
  safety gate.

# Acceptance Test for the DeepSeek Harness Bridge

This document is the per-port acceptance test for the
`deepseek-harness-bridge`. It mirrors the spec in
[`docs/porting-to-a-new-harness.md` §3](../../docs/porting-to-a-new-harness.md)
and tells you how to verify the bridge end-to-end on a real
DeepSeek Harness install.

## TL;DR

In a clean session, send the message:

> Let's make a react todo list

The `brainstorming` skill must auto-trigger **before** any code is
written. Capture the full transcript — that is the artifact that
proves the bridge works.

## What "auto-trigger" means

The DeepSeek Harness renders a model-facing catalog at every
`agent/pre-step` waterfall. The catalog includes a
`<system-reminder>` block listing every registered skill by
`name` and `description`. The `brainstorming` skill's description
mentions "before any code is written" / "design" / "spec" — any
phrasing that matches the user's intent.

The model should:

1. See the catalog entry for `brainstorming`.
2. Recognize the user message as a "let's build X" intent.
3. Call the `skill` tool with `name: "brainstorming"`.
4. Load the skill's full body via the tool's return value.
5. Follow the skill's instructions, which start with a clarifying
   conversation and explicitly forbid jumping to code.

If the model writes code before the clarifying conversation
finishes, the bridge is not wired correctly. Most common failure
modes (in order of likelihood):

| Failure | Likely cause | Where to look |
| --- | --- | --- |
| Catalog empty | `customSkillDirs` not pointing at `./superpowers/skills` | `--dump-config` output for the `skill-filesystem` row |
| Catalog present but `brainstorming` missing | frontmatter parse failure (invalid `name`, missing `description`) | `dmesg` / harness log: `skill file <path> ignored: …` |
| Catalog present, model still writes code | bootstrap (`using-superpowers` skill) not injected at session start | `dmesg` / harness log: `hooks/session-start` not invoked |
| Catalog + bootstrap both present, model still writes code | tool mapping not reachable from the bootstrap (the model doesn't know which tool name to call) | the bootstrap's `references/deepseek-harness-tools.md` (planned — not in this PR) |

## Step-by-step

### 1. Install the harness

```sh
npx @deepseek-ai/dsh@0.1.0-rc.5 web
# serves on http://127.0.0.1:3080
```

### 2. Apply the bridge patch

From the superpowers-safe checkout root:

```sh
dsh --profile web --patch ./fork/deepseek-harness-bridge/cordis.yml
```

### 3. Verify discovery

In a new session, send:

> List every skill you have available, with name and description.

The model should report all 15 superpowers skills, each prefixed
with its `<name>`. If any are missing, the patch did not apply
correctly — run `dsh --profile web --patch ./fork/deepseek-harness-bridge/cordis.yml --dump-config` and inspect the
`skill-filesystem` row's `customSkillDirs`.

### 4. Verify the bootstrap

Send:

> Describe your superpowers.

The model should mention the safety-check preflight, the
`brainstorming` / `test-driven-development` / etc. process
skills, and the per-harness tool mapping. If it answers "I don't
have any superpowers" or "I don't know what skills are", the
`SessionStart` hook did not fire — check the harness log for
`hooks/session-start` errors.

### 5. Run the canonical acceptance test

Send:

> Let's make a react todo list

The model should:

- Load the `brainstorming` skill via the `skill` tool.
- Open with a clarifying question (one of: "what's the
  one-sentence problem", "who's the user", "what does done look
  like", etc.).
- NOT write any code, create any files, or run any shell
  commands in the same turn.

The model should NOT:

- Read `SKILL.md` files directly with file tools (the harness
  has a `skill` tool; using it is the canonical path).
- Skip directly to scaffolding a React project.
- Mention "I'll use my superpowers" without having first loaded
  the relevant skill.

### 6. Capture the transcript

Whatever the test framework or your own recorder uses, capture:

- The full prompt → response cycle.
- Every tool call the model made (with their `name` and `args`).
- The tool's return value for the `skill` tool when it was
  called (proves the bridge delivered the `brainstorming` body).
- The model's final text response (proves it did or did not
  write code).

This transcript is the artifact the PR template asks for.

## What this test does NOT verify

- **The safety-check skill's gates.** Those have their own
  pressure scenarios under `tests/evals/scenarios/`. The
  DeepSeek-specific scenario in `tests/evals/scenarios/deepseek-harness/`
  covers the harness's `dsh-sandbox-policy` / `dsh-approval`
  flow.
- **The end-to-end TDD loop.** TDD has its own scenarios
  (`tests/evals/scenarios/curl-pipe-shell` etc.) that run
  against the existing runtimes. Re-running them on DeepSeek
  is part of the next eval pass, not this PR.
- **The 5-gate SHELL preflight.** The `safety-guard.py` hook
  is a Claude-Code-specific defense-in-depth. The DeepSeek
  equivalent is the harness's `dsh-sandbox-policy` row, which
  the bridge does not override. That is a separate integration
  concern.

## What to do if it fails

Open an issue in the fork with:

1. The full transcript (Section 6).
2. The harness log (or a representative excerpt).
3. The output of `dsh --profile web --patch ./fork/deepseek-harness-bridge/cordis.yml --dump-config`.
4. The OS, harness version, and DeepSeek model used.

Do NOT file the issue upstream — the bridge is fork-only, and
upstream DeepSeek does not own the superpowers skill content.

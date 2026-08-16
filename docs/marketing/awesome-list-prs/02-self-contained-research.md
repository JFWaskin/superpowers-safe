# Research: awesome-llm-apps contribution rules for a self-contained safety skill

> Research-only, no PR opened. Compiled 2026-08-16 in response to
> Shubhamsaboo's offer on PR #1081 to open a new PR with a self-contained
> runnable example. The user asked for a comprehensive check of the
> repo's actual contribution rules before any new PR is opened.

## TL;DR

The barrier is higher than the prior assessment suggested, and the
fit is better. A real PR would be a **multi-day build** of an
agentskills.io-compliant skill folder, not a 50-line demo. Apache-2.0
license is required (we are MIT). A real PR can plausibly land, but
the cost/benefit should be reconsidered in light of these new
findings. Recommendation in §7 is "feasible but expensive; do it only
if the 132k-star placement justifies the ongoing maintenance."

## 1. No formal CONTRIBUTING.md

The repo has **no** `CONTRIBUTING.md` (verified by direct fetch —
returns 404). The `.github/` folder contains only `workflows/`. All
contribution rules are inferred from the README, the
`agent_skills/README.md` "bar" section, and PR-merge patterns.

## 2. The agent_skills/ section is the curated-host policy

`agent_skills/README.md` states the bar explicitly:

> "Most 'skills' on registries are text-only prompt dumps — advice
> the model already knows, wrapped in frontmatter. Skills here have
> to earn their place:
>
> - **Real scripts** — deterministic work runs as code, not as
>   token generation
> - **Researched references** — deep content loads on demand, with
>   sources
> - **Evidence over vibes** — every claim a skill makes must be
>   checkable
> - **Local and private by default** — no network calls unless
>   declared, nothing leaves your machine
> - **Tested before shipped** — on real inputs, not just happy-path
>   fixtures"

The main README's "Agent Skills" section also states:

> "Every skill ships real code and passes a security + eval CI gate."

A link-only PR satisfies neither "ships real code" nor "passes a
security + eval CI gate." This is the exact reason PR #1081 was
closed.

## 3. Required skill folder structure

From the `agent_skills/project-graveyard/` exemplar (the most
detailed existing skill):

```
agent_skills/<skill-name>/
├── SKILL.md         # agent instructions, agentskills.io frontmatter
├── README.md        # user-facing install + usage
├── scripts/         # Python (stdlib preferred), the runtime code
└── references/      # supporting content, loaded on demand
```

And in `agent_skills/evals/`:

```
agent_skills/evals/<skill-name>/
└── test_<skill>.py  # executable test the user runs before installing
```

The `SKILL.md` frontmatter must follow the
[agentskills.io](https://agentskills.io) spec:

```yaml
---
name: <skill-name>
description: >-
  Multi-line description of when to use, with trigger phrases.
  "Use when the user mentions X, asks about Y, or wants to Z."
license: Apache-2.0
metadata:
  author: "Shubham Saboo"
  version: "1.0.0"
  source: "https://github.com/Shubhamsaboo/awesome-llm-apps"
---
```

`license: Apache-2.0` is hard-coded in the exemplar. This is a
**license requirement**: our `superpowers-safe` is MIT. We would
need to either re-license or dual-license under Apache-2.0 before
landing here. (MIT → Apache-2.0 dual-licensing is straightforward
since the work is original; relicensing-only requires permission
from all copyright holders, which is JFWaskin alone for the fork
additions but a no-go for the inherited upstream MIT files.)

## 4. Other categories DO accept link-only PRs (different rule)

The main README mixes two contribution models. The "Agent Skills"
section is the curated-host policy. **Other sections accept
`<sub>↗ external</sub>` link-only entries** — for example:

- Advanced AI Agents → `🌐 Openwork - Open Browser Automation Agent`
  (https://github.com/accomplish-ai/openwork) `<sub>↗ external</sub>`
- Voice AI Agents → `🎙️ OpenSource Voice Dictation Agent`
  (https://github.com/akshayaggarwal99/jarvis-ai-assistant)
  `<sub>↗ external</sub>`

These external-link bullets live in the broader AI-app sections,
not in the curated `agent_skills/` section. A link-only PR was
attempted for `agent_skills/` in PR #1070
(academytradingwithdata-ui's Pentest AI Agents) on 2026-08-08 and
was **closed on 2026-08-09** — same pattern as our PR #1081.
This is direct evidence that link-only PRs are categorically
declined for the Agent Skills section even though the format
exists elsewhere in the same repo.

## 5. PR pattern evidence (recent activity)

| PR | Date | What it added | Outcome |
|---|---|---|---|
| #1070 (Pentest AI Agents) | 2026-08-08 | link-only, `<sub>↗ external</sub>` to agent_skills/ | **CLOSED 2026-08-09** |
| #1081 (superpowers-safe) | 2026-08-13 | link-only, README bullet | **CLOSED 2026-08-15** |
| #1088 (temporal memory inspector) | 2026-08-13 | self-contained Streamlit app to advanced_llm_apps/ | **MERGED 2026-08-15** |
| #1095 (AI Paper Research Agent) | 2026-08-14 | starter Streamlit agent with requirements.txt | **MERGED 2026-08-15** |

Three data points of substance:
- Two self-contained additions merged within the same week the
  closure happened.
- The merged PRs are in *different* categories (advanced_llm_apps/
  and starter_ai_agents/), not agent_skills/ — but they prove the
  maintainer actively merges self-contained work.
- Shubhamsaboo's review cadence for substantive PRs is on the
  order of 1–2 days, not weeks.

## 6. What it would actually take to land a real PR

If the user decides to pursue the self-contained path, the
deliverable is roughly:

**Folder: `agent_skills/superpowers-safe/`**

- `SKILL.md` (~3–6 KB) — agentskills.io frontmatter, when-to-use
  triggers, the preflight invocation pattern, the 5-gate list with
  one-line descriptions each, the dual-layer (skill gate + `nono.sh`
  kernel sandbox) defense-in-depth note, references to the eval
  suite. Written in the voice of the existing skills (precise,
  specific, no marketing).
- `README.md` (~3–4 KB) — install (`npx skills add ...`), standalone
  usage (`python3 scripts/preflight.py <cmd>`), what the 5 gates
  are, defense-in-depth with `nono.sh`, link back to
  `JFWaskin/superpowers-safe` for the full plugin, license
  (Apache-2.0), last-verified date.
- `scripts/preflight.py` — a single self-contained Python file
  implementing the 5-gate preflight against a sample destructive
  command. Stdlib only. Standalone — runs without the full
  `superpowers-safe` plugin installed. Demonstrates one gate firing
  with the user-prompt pattern. Probably 100–200 lines.
- `references/gates.md` — the gate taxonomy: what each gate checks,
  what it blocks, what the user prompt looks like.

**Eval: `agent_skills/evals/superpowers-safe/test_preflight.py`**

- 4–8 pytest-style assertions against `scripts/preflight.py`
  using the existing Quorum scenarios as fixtures (the
  out-of-cwd `rm -rf`, sudo, public-registry publish,
  pipe-to-shell install). Verifiable in ~10 seconds.

**Top-level README edit**

- Add a single bullet to the "Agent Skills" section table (the
  table in `agent_skills/README.md` and the bullet list in the main
  README), pointing at the new folder.

**License work**

- Dual-license our safety-check preflight code (the original
  additions in `superpowers-safe/`, NOT the inherited upstream
  files) under MIT + Apache-2.0. Inherited files stay MIT only
  (can't re-license obra/superpowers content). The
  `agent_skills/superpowers-safe/scripts/preflight.py` we ship
  there must be original code (which it would be — it's a
  self-contained 5-gate implementation, not a copy of the full
  plugin).

**Cost estimate (revised)**

- 2–3 days of careful work, not the prior ½ day. The SKILL.md and
  references are the heaviest items; getting the voice and the
  trigger-phrase right takes iteration. The eval is straightforward
  given the existing Quorum fixtures.
- Plus 1 round of review iteration with @Shubhamsaboo (~1–3 days
  based on the merged-PR cadence).
- **Ongoing maintenance:** every safety-check update in
  `JFWaskin/superpowers-safe` would need a corresponding sync to
  the awesome-llm-apps copy, or the eval will rot. The existing
  `fork/upstream-rename-watcher.py` shows we already maintain
  sync processes for the fork; this would be a second one.

**Benefit (revised)**

- A real placement in the **exact** right section (Agent Skills),
  with `npx skills add` as the natural install path. 132k stars,
  the right audience (Claude Code / Codex / Cursor users — the
  primary adopters of safety-check).
- "Actually runs + has an eval" credibility, not just a link.
- Referenceable from `JFWaskin/superpowers-safe` docs as a
  third-party placement.

## 7. Recommendation (revised)

The prior assessment ("lean against") was based on a 50-line
demo framing. With the actual repo requirements, the trade is more
nuanced:

- The fit is genuinely good — Agent Skills is the right category,
  the install path is natural, the audience is the right one.
- The barrier is real but not unreasonable — 2–3 days of careful
  work + ongoing sync maintenance, vs. the 132k-star placement.
- The license work is the one sharp edge — Apache-2.0 dual-license
  is straightforward for the new code, but anyone reading this who
  cares about license hygiene should confirm the relicensing before
  we proceed.

**Revised recommendation:** feasible but expensive. Three options
for the user:

1. **Skip** — leave Shubhamsaboo closed; the placement isn't worth
   a multi-day build + ongoing sync. Reallocate the time to other
   targets (e2b-dev, hesreallyhim, VoltAgent). This is the
   conservative move and still consistent with the prior
   recommendation's spirit.
2. **Pursue** — commit to the 2–3 day build + the maintenance
   burden. Open the new PR after the user reviews the deliverable
   locally; do not auto-open.
3. **Partial** — write the `scripts/preflight.py` standalone
   implementation and ship it inside
   `JFWaskin/superpowers-safe/docs/examples/` or
   `JFWaskin/superpowers-safe/examples/` (where maintenance is
   zero), and reference it from the fork's own docs. Skip the
   awesome-llm-apps PR. This gets 80% of the credibility benefit
   at 20% of the cost.

The user's call. This research is the input; the decision is not
mine.

## 8. Sources

- Main README: https://raw.githubusercontent.com/Shubhamsaboo/awesome-llm-apps/main/README.md
- `agent_skills/README.md` (the bar): https://raw.githubusercontent.com/Shubhamsaboo/awesome-llm-apps/main/agent_skills/README.md
- `agent_skills/project-graveyard/SKILL.md` (exemplar frontmatter): https://raw.githubusercontent.com/Shubhamsaboo/awesome-llm-apps/main/agent_skills/project-graveyard/SKILL.md
- `agent_skills/project-graveyard/README.md` (exemplar user README): https://raw.githubusercontent.com/Shubhamsaboo/awesome-llm-apps/main/agent_skills/project-graveyard/README.md
- PR #1081 (our closed link-only PR): https://github.com/Shubhamsaboo/awesome-llm-apps/pull/1081
- PR #1070 (Pentest AI Agents, same maintainer, same pattern, also closed): https://github.com/Shubhamsaboo/awesome-llm-apps/pull/1070
- PR #1088 (temporal memory inspector, self-contained, merged): https://github.com/Shubhamsaboo/awesome-llm-apps/pull/1088
- PR #1095 (AI Paper Research Agent, self-contained, merged): https://github.com/Shubhamsaboo/awesome-llm-apps/pull/1095
- Folder structure (API): https://api.github.com/repos/Shubhamsaboo/awesome-llm-apps/contents/agent_skills
- agentskills.io spec (referenced in `agent_skills/README.md`): https://agentskills.io

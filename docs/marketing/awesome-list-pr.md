# Awesome-list PR drafts

> Open-source curated lists are the single highest-leverage way to get
> discovered. Aim for 3–5 of these in your first week.

## Where to submit

In rough order of expected traffic for an AI agent skill:

1. **[hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code)** — 24k+ stars, the canonical list. **Highest priority.**
2. **[jnmcfish/awesome-claude-code](https://github.com/jnmcfish/awesome-claude-code)** — second canonical list.
3. **[awesome-ai-agents](https://github.com/topics/awesome-ai-agents)** topic on GitHub
4. **[awesome-mcp-servers](https://github.com/punkpeye/awesome-mcp-servers)** if you ever ship an MCP server
5. **[awesome-llm-apps](https://github.com/Shubhamsaboo/awesome-llm-apps)** (94k stars — high traffic but less targeted)
6. **[awesome-ai-safety](https://github.com/awesome-ai-safety/awesome-ai-safety)** if it exists
7. **[anthropics/skills](https://github.com/anthropics/skills)** — Anthropic's own skills repo. Don't open a PR; if relevant, file an issue pointing to your fork as a "safety-hardened variant".

---

## PR template (copy-paste)

```markdown
### Adding `JFWaskin/superpowers-safe`

- **Repo:** https://github.com/JFWaskin/superpowers-safe
- **What it is:** A safety-hardened fork of `obra/superpowers`. The
  upstream skills library plus a **mandatory 5-gate safety preflight**
  that runs before any other skill — defends against destructive bash,
  runaway subagents, resource exhaustion, secret leaks, and scope creep.
- **Why it belongs here:** the upstream is great but a single
  `rm -rf` or runaway subagent loop can wreck the box. This fork
  adds a hard, in-skill gate. The skills library itself refuses to
  start any non-trivial work without it.
- **Stars / activity:** <fill in> stars, latest release v6.3.0,
  actively maintained, CI green.
- **License:** MIT (inherited from upstream)
- **Maintainer:** @JFWaskin (Huaqiao University)
- **Caveats / context:** This is a fork. The upstream is
  `obra/superpowers`; this fork is byte-identical to upstream on
  skills and adds a `<MANDATORY-SAFETY-GATE>` block plus one new
  `safety-check` skill.
```

---

## Subject lines that work

- `Add JFWaskin/superpowers-safe — safety-hardened fork of obra/superpowers`
- `Add JFWaskin/superpowers-safe (mandatory 5-gate preflight)`
- `Add JFWaskin/superpowers-safe (community fork with safety preflight)`

Avoid: "Please add my repo" / "Awesome list addition" / "Cool new project".

---

## What to expect

- Most maintainers review PRs within 1–7 days. Some take weeks.
- A few maintainers will reject forks. That's normal. Move on.
- If rejected, the maintainer may say "submit to a different list" —
  read carefully and respond politely.

## After acceptance

- Star the awesome list and watch it for future PRs (you may want to
  submit your own updates later).
- Add the awesome list to `docs/marketing/README.md` so you remember
  which ones accepted you.

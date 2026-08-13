# Newsletter / podcast pitch

> Target: AI-coding newsletters, AI-safety newsletters, dev-tooling
> podcasts. The pitch is short and specific.

## Target list (suggested)

### AI-coding / Claude Code

- **Latent Space** (latent.space) — high-traffic AI engineering podcast/newsletter
- **Pragmatic Engineer** (newsletter.pragmaticengineer.com) — covers dev tools
- **Console** (console.dev) — weekly dev tools
- **TLDR AI** (tldr.tech/ai) — daily AI digest
- **The AI Engineer** (newsletter.aiengineer.courses) — high-traffic
- **Last Week in AI** (lastweekin.ai) — broader reach

### AI safety

- **Import AI** (importai.substack.com) — Jack Clark, weekly, very high quality
- **AI Safety Camp** newsletter
- **The AI Incident Brief** (incidentbrief.ai)
- **Center for AI Safety** (safe.ai) digest
- **Conjecture** (conjecture.substack.com) — AI safety focus

### Dev tools / GitHub

- **Changelog** (changelog.com) — long-form interviews, would be a great fit
- **GitHub Engineering Blog** (github.blog/engineering) — for case studies
- **Console #318 and onward** — dev tools

## The pitch email

> **Subject:** Story idea: in-skill safety preflight + dual-layer (skill + kernel sandbox) experiment for AI coding agents
>
> Hi [name],
>
> I'm the maintainer of `superpowers-safe`, a fork of `obra/superpowers`
> that adds a mandatory 5-gate safety preflight before any non-trivial
> AI coding task. Upstream reviewed the proposal this week and
> redirected to the standalone-plugin path — i.e. this fork is the
> answer, and adoption is the metric that matters going forward.
>
> Three angles that might be a fit for [publication]:
>
> 1. **The methodology.** The eval protocol (`docs/eval-protocol.md`)
>    is a concrete, working example of how a safety change to a
>    behavior-shaping skill library ships with evidence. 4 pressure-
>    test scenarios in Quorum format (yaml + story + setup + checks)
>    with synthetic RED baselines at `tests/evals/baselines/`. There
>    are very few public examples of this in the AI coding space.
>
> 2. **The dual-layer experiment.** A 13-action campaign record
>    (`docs/experiments/dual-layer-protection.md`) showing that
>    `safety-check` (the policy layer) and `nono.sh` (a kernel-level
>    capability sandbox) catch **disjoint** threat surfaces. Together
>    they form defense in depth; neither alone is sufficient. The
>    record also documents what each layer fails to catch (real gaps,
>    not papered over).
>
> 3. **The failure mode.** A `subagent-driven-development` run that
>    fires off 30 subagents at once, with full Bash, on a machine
>    with real data. The story of what happens when one of them
>    decides `rm -rf /var/log` is a good idea — and how a preflight
>    would have stopped it.
>
> Repo: https://github.com/JFWaskin/superpowers-safe
> Spec: https://github.com/JFWaskin/superpowers-safe/blob/dev/docs/safety-gate.md
> Eval protocol: https://github.com/JFWaskin/superpowers-safe/blob/dev/docs/eval-protocol.md
> Dual-layer campaign: https://github.com/JFWaskin/superpowers-safe/blob/dev/docs/experiments/dual-layer-protection.md
>
> Happy to do an interview, write a guest post, or share pressure-test
> data. No exclusivity ask.
>
> — JFWaskin
> @JFWaskin on GitHub

## What to attach / not attach

- **Attach:** the social preview image (`assets/social-preview.png`).
  Newsletters love a hero image.
- **Don't attach:** the full repo. The link is enough.
- **Don't attach:** a press release. Pitch is the press release.

## What to expect

- Response rate for cold newsletter pitches: 5–15%.
- Latent Space, Import AI, and Pragmatic Engineer are pickier but
  higher-leverage if accepted.
- If a podcast says "we'd love to have you," the next 30 days will
  be a 2–3x spike in stars. Worth the prep.

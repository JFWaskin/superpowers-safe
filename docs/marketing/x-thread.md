# X / Twitter thread

> A 10-tweet thread. Aim for one tweet per "beat." Each tweet should
> stand alone if seen out of order.

## The thread

> 1/
>
> I maintain a fork of obra/superpowers (the popular Claude Code skills
> library) that adds a **mandatory 5-gate safety preflight** before any
> non-trivial work runs.
>
> Same skills. One new gate. Hard to bypass.
>
> [LINK to repo]

> 2/
>
> The preflight runs 5 hard gates:
>
> 1. Resource budget (disk, RAM, load)
> 2. Command risk scan (rm -rf, dd, curl|sh, force-push, publish)
> 3. Loop / spend limits (max subagents, time, $)
> 4. Secret / PII scan
> 5. Scope confirmation (plan + "go")
>
> All must pass or the task halts.

> 3/
>
> The interesting design choice: the gate is **enforced in-skill**, not
> via a hook.
>
> A `<MANDATORY-SAFETY-GATE>` block at the top of
> `using-superpowers/SKILL.md` makes the agent itself refuse to skip
> it. Subagents dispatched in the middle of work have to run the gate
> too.

> 4/
>
> Why in-skill? Because hooks can be disabled, sandboxed, or forgotten.
> The skill library **is** the agent's reasoning. Making the safety
> gate a skill means the agent's own instructions tell it to stop.

> 5/
>
> The 10 never-override hard limits (no user opt-out, ever):
>
> • rm -rf on system paths
> • dd to a device
> • mkfs / diskutil eraseDisk
> • fork bombs
> • curl | sh / wget | bash
> • git push --force to main / master
> • chmod -R 777 / / chown -R root /
> • sudo without per-command OK
> • npm/pip/cargo publish without explicit OK
> • writes to macOS system paths
> • shutdown / kill of system processes

> 6/
>
> A `<MANDATORY-SAFETY-GATE>` won't stop a determined prompt injection
> attacker. It WILL stop:
>
> • "I thought `rm -rf` was scoped to the project" (it wasn't)
> • The agent getting stuck in a subagent loop at 3am
> • A $200 OpenAI bill from an unattended agent
> • Accidental `git push --force` to main
>
> For a real attacker, you also need hooks + sandbox. This is layer 1.

> 7/
>
> Cross-runtime packaging: same plugin on Claude Code, Codex, Cursor,
> Gemini CLI, Kimi Code, OpenCode, Pi, Hermes, GitHub Copilot CLI,
> Factory Droid.
>
> Skills library byte-identical to upstream. Only difference: the
> gate and one new `safety-check` skill.

> 8/
>
> Any change to the gate has to come with RED-GREEN-REFACTOR
> evidence — at least 3 pressure-test scenarios, run against the
> Quorum eval harness.
>
> This is the boring part and the part that matters.

> 9/
>
> If you've ever had Claude Code do something destructive while you
> weren't looking, this is for you.
>
> Repo: [LINK]
> Spec: [LINK to docs/safety-gate.md]
> Eval protocol: [LINK to docs/eval-protocol.md]

> 10/
>
> Maintainer: @JFWaskin (Huaqiao University)
>
> Upstream reviewed the proposal and redirected to the standalone-
> plugin path — the fork is the answer, not a stopgap. Adoption is
> the metric that matters; upstream blessings are not.
>
> The fork ships with: a dual-layer campaign record
> (safety-check + nono.sh = disjoint threat surfaces), 4 pressure-
> test scenarios in Quorum format, and CI green on 4 runtimes.

## Posting tips

- Post the whole thread at once using a thread tool (Typefully,
  Buffer, or just paste the first tweet and reply to yourself).
- Pin the thread to your profile for 1–2 weeks.
- Quote-tweet each one with a small insight if it gets traction.
- Don't add a poll — low-effort engagement.
- Add the social preview image (`assets/social-preview.png`) to the
  first tweet.

## Engagement expectations

- 50–200 likes on a good day
- 10–50 retweets
- 5–20 follows per thread
- 0–2 stars per like on average (X → GitHub conversion is low but
  real)

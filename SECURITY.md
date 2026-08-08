# Security

> Responsible disclosure policy for `superpowers-safe`. If you find a
> vulnerability or a safety-gate bypass, please report it.

## Reporting a vulnerability

**Do not** open a public GitHub issue for security-sensitive findings.
Instead, report privately via **one** of the following channels:

- **GitHub private vulnerability report**: go to
  [github.com/JFWaskin/superpowers-safe/security/advisories/new](https://github.com/JFWaskin/superpowers-safe/security/advisories/new)
  and submit a private security advisory. Only the maintainer sees it.
- **Email**: `JFWaskin@users.noreply.github.com` (the noreply address is
  the only address publicly associated with this account; it accepts
  GitHub Notifications but is monitored for inbound security reports
  by configuring GitHub to forward them. If email is not viable, use
  the GitHub Advisory route above.)

Please include:

1. The bypass or vulnerability (what you did)
2. What you expected to happen
3. What actually happened
4. The environment (host OS, Claude Code version, fork commit SHA)
5. Whether the issue is exploitable by an unprivileged user or only by
   a user with local access

## Response timeline

| Severity | Acknowledgment | Triage | Fix target |
|----------|---------------|--------|------------|
| **Critical** (gate fully bypassed, no skill or hook blocks) | 24 hours | 3 days | 7 days |
| **High** (specific pattern bypass, exploitable) | 72 hours | 1 week | 2 weeks |
| **Medium** (partial bypass, narrow conditions) | 1 week | 2 weeks | Next minor release |
| **Low** (theoretical, hard to trigger) | 2 weeks | Next minor release | Backlog |

These are targets, not guarantees. We will tell you if a target slips.

## Coordinated disclosure

We follow a 90-day coordinated disclosure window. After 90 days from
the date you report, we may publish the issue even if no fix is
available — at our discretion and with credit to you (if you want it).

If you need more time (e.g. you're coordinating a downstream patch),
tell us; we will hold the disclosure for as long as is reasonable.

## What we will do

1. Acknowledge your report within the timeline above
2. Investigate and write a fix
3. Credit you in `CHANGELOG.md` (if you want)
4. Publish a GitHub Security Advisory with the fix and (if applicable)
   a CVE
5. After 90 days (or sooner if you want), the advisory goes public

## What we will not do

- We will not threaten legal action against security researchers who
  follow this policy
- We will not contact law enforcement for accidental discoveries made
  in good faith
- We will not require NDAs beyond the coordinated-disclosure timeline
  above

## Scope

In scope:

- The `safety-check` skill content (any wording that lets an agent skip
  the gate)
- The `scripts/safety-guard.py` PreToolUse hook (any regex bypass,
  bypass-via-modification, false-negative on the patterns in §3 of
  `docs/THREAT-MODEL.md`)
- The `<MANDATORY-SAFETY-GATE>` block in `skills/using-superpowers/SKILL.md`
- The installation / uninstallation paths (any way to install
  superpowers-safe without the gate actually applying)
- The CI workflows (any way to merge a change that bypasses the gate)

Out of scope:

- Issues in upstream `obra/superpowers` (please report to
  [obra/superpowers](https://github.com/obra/superpowers))
- Issues in dependencies (we have zero deps; this is moot)
- Theoretical issues with no concrete bypass

## Hall of fame

_(No reports yet — be the first.)_

When a report leads to a fix, the reporter is credited here (unless
they prefer anonymity). Contributions include: bypass discovery, false-
negative reports, false-positive reports that lead to Gate 2 rule
refinements, and threat-model improvements.

## License

This security policy is part of the `superpowers-safe` project, MIT
licensed. The policy itself is not a contract; it is a statement of
intent. We will do our best to honor the timelines, but reserve the
right to revise them if circumstances warrant.

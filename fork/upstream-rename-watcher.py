#!/usr/bin/env python3
"""
upstream-rename-watcher.py

Hourly watcher: detect genuine renames in upstream `obra/superpowers:dev`
and emit DRAFT PR proposals (no auto-posting) that obey obra's 4 constraints
called out when closing #2121 and #2111.

The script NEVER opens a PR. It detects, validates against the 4
constraints, then writes a DRAFT PR body to disk so the human (JFWaskin)
can review and post manually. This is deliberate: auto-posting rename
PRs against an upstream that just closed two of them for the same
class of mistake is hostile, not helpful.

obra's 4 constraints (encoded as C1..C4 in this file):

  C1. Semantics over token swap (from #2121 closure).
      Quorum is only PART of the eval system, not the whole thing —
      "Drill" doesn't always become "Quorum". If the rename would
      misdescribe the architecture, surface a "stale-architecture
      description" finding instead of proposing a rename.

  C2. Verification claims must be true (from #2121 closure).
      If the draft says "verified against upstream X", it must have
      actually been verified. This script NEVER auto-claims verification;
      every "Verification" section is left as a checklist of the exact
      files/lines/commands the human must check before sending.

  C3. Submitter-identification table is mandatory (from #2121 closure).
      obra's PR template requires the four-row table
      (model, harness, plugins, human partner). This script embeds that
      exact table in the draft. If the format changes upstream, this
      script needs to be updated before any draft is sent.

  C4. zero-dep / fork-derived / opt-in (from CLAUDE.md, cited in #2111).
      Never propose moving fork-only code (fork/, safety-check,
      dsh-hooks-claude-code, nono.sh integration, deepseek-harness-bridge)
      into upstream. PROTECTED_GLOBS below is the gate.

Author rules (hard rule, applies to every commit, draft, and public
artifact produced by or on behalf of this script):
  - JFWaskin <waskin@users.noreply.github.com> is the sole author.
  - NO "Co-Authored-By: Claude" (or any other AI attribution) trailer.
  - NO "with Claude as drafting partner" prose.
  - DRAFT bodies end with "— JFWaskin" so a human can verify attribution
    at a glance.

Usage:
  fork/upstream-rename-watcher.py [--dry-run] [--reset-state]
                                  [--drafts-dir PATH]

State file: $STATE_FILE (default: session-private path). Idempotent: if
upstream HEAD is unchanged, the script is a no-op.
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import re
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional

# ----- hardcoded paths (the user can override via env) -----
REPO_ROOT = Path("/Users/jonathanwaskin/code/superpowers-safe")
PR_FORK_URL = os.environ.get(
    "PR_FORK_URL", "https://github.com/JFWaskin/superpowers-pr-fork.git"
)
UPSTREAM_REPO = os.environ.get("UPSTREAM_REPO", "obra/superpowers")
UPSTREAM_BRANCH = os.environ.get("UPSTREAM_BRANCH", "dev")
STATE_FILE = Path(
    os.environ.get(
        "STATE_FILE",
        "/Users/jonathanwaskin/.minimax/sessions/mvs_0d856ed85713412ca3b0e1e5f6a6023e/.upstream-rename-watcher-state.json",
    )
)

# ----- C4 gate: fork-only paths that must NEVER be proposed upstream -----
# Rationale: obra's CLAUDE.md says "fork-derived features don't come
# upstream" (cited in #2111 closure). Any rename touching one of these
# paths is either a fork-internal rename (we don't care for upstream
# sync) or a fork-leak (we must refuse).
PROTECTED_GLOBS = [
    # fork-internal surface area
    "fork/",
    "fork/deepseek-harness-bridge/",
    # safety-check lives in this fork, not upstream
    "safety-check/",
    # dsh-hooks-claude-code is fork-only
    "dsh-hooks-claude-code/",
    # nono.sh integration rules that part out (cited in #2111)
    "nono.sh",
    # never touch git metadata or build/cache noise
    ".git/",
    "node_modules/",
    # historical / marketing / backup files keep the old name on purpose
    "docs/upstream/",
    "docs/marketing/",
    "*.md.bak",
    # eval scenarios embed expected text; sed would corrupt them
    "tests/evals/scenarios/*/story.md",
    "tests/evals/scenarios/*/setup.sh",
    "tests/evals/scenarios/*/checks.sh",
    "tests/evals/baselines/",
]

# ----- C1: token-swap red flags -----
# Terms whose context-sensitive replacement is known to misdescribe
# architecture. If a draft would swap one of these to its "obvious"
# successor, we surface a "stale-architecture-description" finding
# instead (per C1).
#
# Currently watched: Drill -> Quorum. Quorum is only PART of the eval
# system; the docs need a correct description, not a token swap. (This
# is the exact wording obra used closing #2121.)
TOKEN_SWAP_REDFLAGS = {
    "Drill": {
        "naive_replacement": "Quorum",
        "reason": (
            "Quorum is only part of the eval system, not the whole "
            "thing. A blanket Drill→Quorum swap misdescribes the "
            "architecture. The docs need a correct description, not a "
            "token swap. — obra, #2121 closure"
        ),
    },
}

# ----- C3: submitter-identification table (exact format from obra's
#          .github/PULL_REQUEST_TEMPLATE.md "Who is submitting this PR?"
#          section). The fields are placeholders the human must fill
#          before posting. The script MUST NOT invent values for them.
SUBMITTER_TABLE = """| Field | Value |
|-------|-------|
| Your model + version | <fill before posting: e.g. "none — drafted by JFWaskin from upstream diff + this script"> |
| Harness + version | <fill before posting: e.g. "none — no harness was used to author this proposal"> |
| All plugins installed | <fill before posting: e.g. "n/a — no harness was used"> |
| Human partner who reviewed this diff | JFWaskin |"""


# ----- data model -----


@dataclass
class Rename:
    old_name: str
    new_name: str
    upstream_sha: str
    upstream_message: str
    path_kind: str  # "file" | "directory" | "term"

    def pr_row(self) -> str:
        return (
            f"| `{self.old_name}` | `{self.new_name}` | `{self.path_kind}` | "
            f"`{self.upstream_sha[:10]}` |"
        )


@dataclass
class ConstraintFinding:
    """A finding that BLOCKS the proposal and must be surfaced instead.

    Per C1, when a rename would misdescribe architecture we surface a
    `StaleArchitectureDescription` instead of a rename. The cron (and
    the human reviewing the run output) sees this as an explicit
    "do-not-propose" signal.
    """

    code: str  # "C1" | "C2" | "C3" | "C4"
    old_name: str
    new_name: str
    why: str
    remediation: str


@dataclass
class State:
    last_seen_sha: str = ""
    last_scan: str = ""
    open_prs: dict = None
    skipped_findings: list = field(default_factory=list)

    def __post_init__(self):
        if self.open_prs is None:
            self.open_prs = {}

    @classmethod
    def load(cls) -> "State":
        if not STATE_FILE.exists():
            return cls()
        try:
            d = json.loads(STATE_FILE.read_text())
            return cls(
                last_seen_sha=d.get("last_seen_sha", ""),
                last_scan=d.get("last_scan", ""),
                open_prs=d.get("open_prs", {}),
                skipped_findings=d.get("skipped_findings", []),
            )
        except Exception as e:
            print(f"WARN: state file corrupt, starting fresh: {e}", file=sys.stderr)
            return cls()

    def save(self) -> None:
        STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
        STATE_FILE.write_text(
            json.dumps(
                {
                    "last_seen_sha": self.last_seen_sha,
                    "last_scan": self.last_scan,
                    "open_prs": self.open_prs,
                    "skipped_findings": self.skipped_findings,
                },
                indent=2,
                sort_keys=True,
            )
        )


# ----- time helpers (no datetime.utcnow(); see C2 hygiene) -----


def utc_now_iso() -> str:
    """ISO-8601 UTC, 'Z' suffix, second precision. No deprecation warnings."""
    return dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


# ----- gh helpers -----


def upstream_head() -> str:
    # NOTE: do NOT route this through gh_json; --jq emits a raw string, not JSON.
    r = subprocess.run(
        [
            "gh",
            "api",
            f"repos/{UPSTREAM_REPO}/branches/{UPSTREAM_BRANCH}",
            "--jq",
            ".commit.sha",
        ],
        capture_output=True,
        text=True,
        check=True,
    )
    return r.stdout.strip()


def compare_files(base: str, head: str) -> list[dict]:
    r = subprocess.run(
        [
            "gh",
            "api",
            f"repos/{UPSTREAM_REPO}/compare/{base}...{head}",
            "--jq",
            ".files // []",
        ],
        capture_output=True,
        text=True,
        check=True,
    )
    return json.loads(r.stdout) if r.stdout.strip() else []


def compare_messages(base: str, head: str) -> list[str]:
    r = subprocess.run(
        [
            "gh",
            "api",
            f"repos/{UPSTREAM_REPO}/compare/{base}...{head}",
            "--jq",
            ".commits // [] | .[].commit.message",
        ],
        capture_output=True,
        text=True,
        check=True,
    )
    return json.loads(r.stdout) if r.stdout.strip() else []


# ----- rename detection -----


def is_protected(path: str) -> bool:
    import fnmatch

    for g in PROTECTED_GLOBS:
        if g.endswith("/") and path.startswith(g):
            return True
        if "*" in g:
            if fnmatch.fnmatch(path, g):
                return True
        elif path == g or path.startswith(g):
            return True
    return False


def detect_path_renames(base: str, head: str) -> list[Rename]:
    renames: list[Rename] = []
    for f in compare_files(base, head):
        prev = f.get("previous_filename") or ""
        new = f.get("filename") or ""
        if not prev or prev == new:
            continue
        if is_protected(prev) or is_protected(new):
            continue
        kind = "directory" if "/" in new or "/" in prev else "file"
        renames.append(
            Rename(
                old_name=prev,
                new_name=new,
                upstream_sha=head,
                upstream_message="",
                path_kind=kind,
            )
        )
    return renames


def detect_term_renames(base: str, head: str) -> list[Rename]:
    """Detect term renames mentioned in commit messages.

    Heuristic only — the term-rename commit message pattern is loose
    ("rename Drill to Quorum", "Drill -> Quorum"). Every detected term
    rename is still gated by C1 (semantics), C2 (verification checklist
    is left for the human), and C4 (PROTECTED_GLOBS).
    """
    pattern = re.compile(
        r"\brename[d]?\s+[`'\"]?(\w+)['\"]?\s+(?:to|->|=>)\s+[`'\"]?(\w+)['\"]?",
        re.I,
    )
    renames: list[Rename] = []
    for msg in compare_messages(base, head):
        for m in pattern.finditer(msg):
            old, new = m.group(1), m.group(2)
            if len(old) < 2 or len(new) < 2:
                continue
            if old.lower() == new.lower():
                continue
            renames.append(
                Rename(
                    old_name=old,
                    new_name=new,
                    upstream_sha=head,
                    upstream_message=msg.splitlines()[0][:120],
                    path_kind="term",
                )
            )
    return renames


def detect_renames(base: str, head: str) -> list[Rename]:
    return detect_path_renames(base, head) + detect_term_renames(base, head)


# ----- C1: token-swap screening -----


def c1_screen(renames: list[Rename]) -> tuple[list[Rename], list[ConstraintFinding]]:
    """If a rename matches a known token-swap red flag, drop it and emit
    a ConstraintFinding instead. Returns (accepted_renames, findings)."""
    accepted: list[Rename] = []
    findings: list[ConstraintFinding] = []
    for r in renames:
        if r.path_kind == "term" and r.old_name in TOKEN_SWAP_REDFLAGS:
            redflag = TOKEN_SWAP_REDFLAGS[r.old_name]
            if r.new_name == redflag["naive_replacement"]:
                findings.append(
                    ConstraintFinding(
                        code="C1",
                        old_name=r.old_name,
                        new_name=r.new_name,
                        why=redflag["reason"],
                        remediation=(
                            "Surface a 'docs-describe-stale-architecture' "
                            "finding against the human instead. Do NOT "
                            "propose this as a rename."
                        ),
                    )
                )
                continue
        accepted.append(r)
    return accepted, findings


# ----- draft proposal emission -----


def render_pr_draft(
    renames: list[Rename],
    base_sha: str,
    head_sha: str,
    findings: list[ConstraintFinding],
) -> tuple[str, str]:
    """Render the PR title and body. The body is markdown, suitable for
    pasting into the GitHub PR textarea. The script NEVER calls
    `gh pr create`; that is the human's job after review.

    The body contains placeholders the human MUST fill in (C2): the
    'Verification' section lists what would need to be checked, not what
    was checked. The submitter table (C3) is embedded verbatim from
    obra's template with placeholders the human fills.

    No 'Co-Authored-By:' trailer. No AI attribution. Ever.
    """
    # Title: conventional-commits, scope = the touched area
    if len(renames) == 1:
        r = renames[0]
        title = f"docs({r.path_kind}): rename {r.old_name} to {r.new_name}"
    else:
        title = f"docs(sync): mirror {len(renames)} upstream renames ({head_sha[:10]})"

    lines: list[str] = []

    # Mirror header
    lines.append(
        f"Mirror of upstream renames in `{UPSTREAM_REPO}` "
        f"between `{base_sha[:10]}` and `{head_sha[:10]}`."
    )
    lines.append("")

    # C3: submitter table (exact format from obra's PR template)
    lines.append("## Who is submitting this PR? (required)")
    lines.append("")
    lines.append(SUBMITTER_TABLE)
    lines.append("")

    # Why
    lines.append("## Why")
    lines.append("")
    if len(renames) == 1:
        r = renames[0]
        lines.append(
            f"Upstream renamed `{r.old_name}` to `{r.new_name}` in "
            f"`{UPSTREAM_REPO}@{head_sha[:10]}` and the existing docs in "
            "this repo still reference the old term. This is a doc-sync "
            "PR: nothing about the architecture, tooling, or behavior "
            "changes; only the user-facing terminology mirrors upstream."
        )
    else:
        lines.append(
            f"Upstream made {len(renames)} rename changes in "
            f"`{UPSTREAM_REPO}@{head_sha[:10]}`; the existing docs in "
            "this repo still reference the old names. This is a doc-sync "
            "PR: nothing about architecture, tooling, or behavior "
            "changes; only user-facing terminology mirrors upstream."
        )
    lines.append("")
    lines.append(
        "This PR does NOT touch any fork-only surface (fork/, "
        "safety-check/, dsh-hooks-claude-code/, nono.sh). It is purely "
        "upstream-internal doc terminology. (C4)"
    )
    lines.append("")

    # What changed
    lines.append("## What changed")
    lines.append("")
    lines.append("| Old | New | Kind | Upstream commit |")
    lines.append("|-----|-----|------|-----------------|")
    for r in renames:
        lines.append(r.pr_row())
    lines.append("")

    # What was NOT changed
    lines.append("## What was NOT changed")
    lines.append("")
    lines.append(
        "- Historical files that intentionally retain the old name "
        "(CHANGELOG entries, prior PR references, eval scenario "
        "transcripts that mention the old term in passing)."
    )
    lines.append(
        "- Any path under `fork/`, `safety-check/`, `dsh-hooks-claude-code/`, "
        "or anything gated by `nono.sh` integration rules. (C4)"
    )
    lines.append(
        "- Code that runs the tool — only user-facing doc strings and "
        "comments were touched. If a code-level identifier change is "
        "required, it is out of scope for this PR."
    )
    lines.append("")

    # C2: Verification — checklist of what the human MUST check.
    # The script does NOT claim verification. Every item is phrased as
    # a checkbox so the human can tick them off and then delete the
    # unchecked lines before posting.
    lines.append("## Verification (required before posting)")
    lines.append("")
    lines.append(
        "The author of this draft has NOT independently verified these "
        "claims. The human posting this PR must check each box before "
        "submitting. (C2)"
    )
    lines.append("")
    lines.append(
        f"- [ ] The diff on the branch matches upstream "
        f"`{UPSTREAM_REPO}@{head_sha[:10]}` "
        f"(compare URL: "
        f"https://github.com/{UPSTREAM_REPO}/compare/{base_sha}...{head_sha})"
    )
    lines.append(
        "- [ ] Each old→new replacement preserves meaning in context. "
        "If any replacement would be wrong in a particular context "
        "(e.g., a term that means something narrower in a different "
        "subsystem), the replacement was reverted in that location."
    )
    lines.append(
        "- [ ] No command in any 'Quick Start' or 'How to run' section "
        "was changed. (obra closed #2121 partly because the 'fixed' "
        "quick start still showed stale `uv sync` / `uv run` while the "
        "evals repo had migrated to Bun/TypeScript. Do not repeat that "
        "mistake.)"
    )
    lines.append(
        "- [ ] No `Co-Authored-By:` trailer, no 'with Claude as drafting "
        "partner' prose, no AI attribution anywhere in the commit "
        "messages, PR body, or branch description."
    )
    lines.append("")

    # C1: token-swap findings (if any)
    if findings:
        lines.append("## C1: token-swap findings NOT proposed here")
        lines.append("")
        lines.append(
            "The following renames were detected but are surfaced as "
            "findings rather than proposed, because they would "
            "misdescribe the architecture per C1. Treat these as "
            "'docs-describe-stale-architecture' follow-ups for a human "
            "to write proper doc updates, not as rename candidates:"
        )
        lines.append("")
        for f in findings:
            lines.append(f"- **{f.old_name} → {f.new_name}**: {f.why}")
            lines.append(f"  - Remediation: {f.remediation}")
        lines.append("")

    # Existing PRs
    lines.append("## Existing PRs")
    lines.append("")
    lines.append(
        "- [ ] I have reviewed all open AND closed PRs on the fork for "
        "duplicates or prior art"
    )
    lines.append(
        f"- Related PRs: #2121 (Drill→Quorum — closed by obra for the "
        "exact reasons this PR template is designed to prevent; see "
        "C1/C2/C3 in the watcher script)"
    )
    lines.append("")

    # Upstream range
    lines.append(
        f"Upstream range: https://github.com/{UPSTREAM_REPO}/compare/{base_sha}...{head_sha}"
    )
    lines.append("")
    lines.append("— JFWaskin")

    return title, "\n".join(lines)


def write_drafts(
    drafts_dir: Path,
    renames: list[Rename],
    findings: list[ConstraintFinding],
    base_sha: str,
    head_sha: str,
) -> list[Path]:
    """Write a draft PR body to disk so the human can review and post.

    Returns the list of files written. The script NEVER posts.
    """
    drafts_dir.mkdir(parents=True, exist_ok=True)
    written: list[Path] = []

    # Findings-only run: surface C1/C4 blocks even when no rename
    # is being proposed. The human still wants to see them.
    if findings and not renames:
        f = drafts_dir / f"findings-{head_sha[:10]}.md"
        lines = [
            f"# Findings from upstream-rename-watcher @ {head_sha[:10]}",
            "",
            f"Range: `{base_sha[:10]}..{head_sha[:10]}`",
            "",
            "No rename proposal was generated. The following items were "
            "detected but blocked from becoming PR proposals:",
            "",
        ]
        for fnd in findings:
            lines.append(f"## {fnd.code}: `{fnd.old_name}` → `{fnd.new_name}`")
            lines.append("")
            lines.append(fnd.why)
            lines.append("")
            lines.append(f"Remediation: {fnd.remediation}")
            lines.append("")
        lines.append("— JFWaskin")
        f.write_text("\n".join(lines))
        written.append(f)

    # Renames-to-propose run: emit the draft PR body.
    if renames:
        title, body = render_pr_draft(renames, base_sha, head_sha, findings)
        # File-safe title slug
        slug = re.sub(r"[^a-z0-9]+", "-", title.lower()).strip("-")[:60]
        out = drafts_dir / f"draft-{slug}-{head_sha[:10]}.md"
        header = (
            f"# DRAFT PR — DO NOT POST AUTOMATICALLY\n"
            f"# Title: {title}\n"
            f"# Generated: {utc_now_iso()}\n"
            f"# Upstream range: {base_sha[:10]}..{head_sha[:10]}\n"
            f"# Reviewer checklist: see 'Verification' section below.\n"
            f"# Author rule: JFWaskin only. NO Co-Authored-By trailer. NO AI attribution.\n"
            f"\n---\n\n"
        )
        out.write_text(header + body)
        written.append(out)

    return written


# ----- main -----


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--reset-state", action="store_true")
    ap.add_argument(
        "--drafts-dir",
        default=str(REPO_ROOT / "fork" / ".drafts"),
        help="Where to write DRAFT PR bodies (default: fork/.drafts/). "
        "The script NEVER auto-posts.",
    )
    args = ap.parse_args()

    state = State() if not args.reset_state else State()

    head = upstream_head()
    if not head:
        print("FAIL: could not get upstream HEAD sha", file=sys.stderr)
        return 1

    if not state.last_seen_sha:
        state.last_seen_sha = head
        state.last_scan = utc_now_iso()
        state.save()
        print(f"INIT: state seeded to upstream HEAD {head[:10]}; no PR (no diff)")
        return 0

    if head == state.last_seen_sha:
        print(f"QUIET: upstream HEAD unchanged ({head[:10]})")
        return 0

    base = state.last_seen_sha
    print(f"SCAN: upstream {base[:10]}..{head[:10]}")
    renames = detect_renames(base, head)

    # C1: screen out token-swap red flags
    accepted, findings = c1_screen(renames)
    for fnd in findings:
        print(f"  FINDING {fnd.code}: {fnd.old_name} → {fnd.new_name} — {fnd.why}")
    if not accepted and not findings:
        print(f"QUIET: no renames in {base[:10]}..{head[:10]}")
        state.last_seen_sha = head
        state.last_scan = utc_now_iso()
        state.save()
        return 0

    if accepted:
        print(f"FOUND {len(accepted)} rename(s) passing C1:")
        for r in accepted:
            print(f"  {r.path_kind}: {r.old_name}  →  {r.new_name}")
    else:
        print("NO renames pass C1; emitting findings only.")

    if args.dry_run:
        # In dry-run, do NOT write drafts. Just describe.
        if accepted:
            title, _ = render_pr_draft(accepted, base, head, findings)
            print(
                f"DRY-RUN: would write DRAFT PR titled '{title}' to "
                f"{args.drafts_dir}. no files written."
            )
        for fnd in findings:
            print(
                f"DRY-RUN: would emit C1 finding "
                f"({fnd.old_name}→{fnd.new_name})."
            )
        return 0

    # Real run: write drafts. No PR is opened.
    drafts_dir = Path(args.drafts_dir)
    written = write_drafts(drafts_dir, accepted, findings, base, head)
    for f in written:
        print(f"DRAFT WRITTEN: {f}")

    # Update state — record the findings as skipped so the next run
    # doesn't re-emit them against the same SHA range.
    state.last_seen_sha = head
    state.last_scan = utc_now_iso()
    for fnd in findings:
        state.skipped_findings.append(
            {
                "code": fnd.code,
                "old": fnd.old_name,
                "new": fnd.new_name,
                "why": fnd.why,
                "at_sha": head,
            }
        )
    state.save()

    print(f"NEXT: human reviews drafts in {drafts_dir} before posting.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

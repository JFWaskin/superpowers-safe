#!/usr/bin/env python3
"""Safety guard hook for Claude Code PreToolUse events.

Defense-in-depth companion to the `safety-check` skill (see
`skills/safety-check/SKILL.md` and `docs/safety-gate.md`). Catches
destructive Bash commands at the tool layer even if the agent skips the
skill's preflight.

Install into `~/.claude/hooks/safety-guard.py` and register in
`~/.claude/settings.json`:

    {
      "hooks": {
        "PreToolUse": [
          {
            "matcher": "Bash",
            "hooks": [
              {"command": "python3 ~/.claude/hooks/safety-guard.py", "type": "command"}
            ]
          }
        ]
      }
    }

Exit codes:
  0 — allow (optionally with a stderr warning the agent will see)
  2 — block (Claude Code treats this as a denial; stderr is fed back)
  other — fail-open so a hook bug does not lose work, but logs to stderr
"""
from __future__ import annotations

import json
import re
import sys


# Patterns that MUST be blocked. Each entry: (regex, why).
BLOCKED: list[tuple[re.Pattern[str], str]] = [
    (re.compile(r"\brm\s+(-[a-zA-Z]*[rR][a-zA-Z]*[fF]|-[a-zA-Z]*[fF][a-zA-Z]*[rR])\s+(/\.\.|\.\.|/\s*$|~/?\s*$|/\*)", re.IGNORECASE),
     "Refusing to recursive-delete a parent of cwd, root, home, or a wildcard"),
    (re.compile(r"\brm\s+-[a-zA-Z]*[rR][a-zA-Z]*[fF][a-zA-Z]*\s+(/System|/Library|/usr|/etc|/private|/var|~/Library)", re.IGNORECASE),
     "Refusing to recursive-delete a macOS/Linux system path"),
    (re.compile(r"\bdd\s+if=/dev/(zero|random|urandom)\s+of=/dev/", re.IGNORECASE),
     "Refusing to overwrite a block device with dd"),
    (re.compile(r"\bmkfs(\.\w+)?\s+/dev/", re.IGNORECASE),
     "Refusing to format a device"),
    (re.compile(r"\bdiskutil\s+eraseDisk\b", re.IGNORECASE),
     "Refusing to erase a disk"),
    (re.compile(r":\s*\(\s*\)\s*\{[^}]*:\s*\|\s*:[^}]*\}\s*;\s*:", re.IGNORECASE),
     "Refusing to execute a fork bomb"),
    (re.compile(r"\bcurl\s+[^|;&]*\|\s*(sh|bash|zsh|sudo)\b", re.IGNORECASE),
     "Refusing to pipe a network payload directly to a shell"),
    (re.compile(r"\bwget\s+[^|;&]*\|\s*(sh|bash|zsh|sudo)\b", re.IGNORECASE),
     "Refusing to pipe a network payload directly to a shell"),
    (re.compile(r"\bgit\s+push\s+(-f|--force(-with-lease)?)\s+.*\b(origin\s+)?(main|master)\b", re.IGNORECASE),
     "Refusing to force-push to main/master"),
    (re.compile(r"\bgit\s+push\s+(-f|--force(-with-lease)?)\s+origin\s+HEAD:main\b", re.IGNORECASE),
     "Refusing to force-push HEAD to main"),
    (re.compile(r"\bchmod\s+(-[a-zA-Z]*\s+)*-R\s+777\s+/(?:\s|$)", re.IGNORECASE),
     "Refusing to chmod 777 on a system path"),
    (re.compile(r"\bchown\s+(-[a-zA-Z]*\s+)*-R\s+root\s+/(?:\s|$)", re.IGNORECASE),
     "Refusing to chown to root recursively on /"),
    (re.compile(r"\b(npm|pnpm|yarn)\s+publish\b", re.IGNORECASE),
     "Refusing to publish to npm — requires explicit user OK"),
    (re.compile(r"\bpip\s+(install\s+.*--break-system-packages|upload)\b", re.IGNORECASE),
     "Refusing to pip upload or install with --break-system-packages"),
    (re.compile(r"\bcargo\s+publish\b", re.IGNORECASE),
     "Refusing to cargo publish — requires explicit user OK"),
    (re.compile(r"\bshutdown\s+(-h\s+now|-r\s+now)\b", re.IGNORECASE),
     "Refusing to shut down the machine"),
    (re.compile(r"\bkillall\s+(-9\s+)?(launchd|kernel|coreservicesd|WindowServer|loginwindow)\b", re.IGNORECASE),
     "Refusing to kill a macOS system process"),
    (re.compile(r"\bdefaults\s+write\s+/Library/", re.IGNORECASE),
     "Refusing to write system-wide macOS defaults"),
]

# Patterns that should warn the agent (not block). Each entry: (regex, why).
WARN: list[tuple[re.Pattern[str], str]] = [
    (re.compile(r"\bgit\s+reset\s+--hard\b", re.IGNORECASE),
     "git reset --hard will discard uncommitted changes — confirm with user"),
    (re.compile(r"\bgit\s+clean\s+-[a-zA-Z]*[fF][a-zA-Z]*[dD]?|-[a-zA-Z]*[dD][a-zA-Z]*[fF]?\b", re.IGNORECASE),
     "git clean -fd will delete untracked files — confirm with user"),
    (re.compile(r"\bgit\s+push\b(?![^|;&]*--force)", re.IGNORECASE),
     "git push will publish to remote — confirm scope with user"),
    (re.compile(r"\bsudo\s+", re.IGNORECASE),
     "sudo requires elevated privileges — confirm with user"),
    (re.compile(r"\bbrew\s+install\b", re.IGNORECASE),
     "brew install will modify system packages — confirm with user"),
    (re.compile(r"\bkill\s+-9\s+", re.IGNORECASE),
     "kill -9 will force-terminate — confirm target PID with user"),
    (re.compile(r"\brm\s+-[a-zA-Z]*[rR][a-zA-Z]*[fF][a-zA-Z]*\s+", re.IGNORECASE),
     "rm -rf in use — verify the target path is the intended scope"),
]


def classify(command: str) -> tuple[str, str | None]:
    """Return ('allow'|'block'|'warn', message)."""
    if not command:
        return ("allow", None)
    for pattern, why in BLOCKED:
        if pattern.search(command):
            return ("block", why)
    for pattern, why in WARN:
        if pattern.search(command):
            return ("warn", why)
    return ("allow", None)


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except Exception as exc:
        # Fail-open with a log line — do not block the user's work on a hook bug.
        print(f"[safety-guard] could not parse stdin: {exc}", file=sys.stderr)
        return 0

    tool_name = payload.get("tool_name", "")
    if tool_name != "Bash":
        return 0

    tool_input = payload.get("tool_input", {}) or {}
    command = tool_input.get("command", "") or ""
    if not command.strip():
        return 0

    action, message = classify(command)
    preview = command if len(command) <= 200 else command[:197] + "..."

    if action == "block":
        print(
            f"\n[SAFETY GUARD BLOCKED] {message}\n"
            f"Command: {preview}\n"
            "If this is truly needed, get explicit user confirmation and run it outside Claude Code.\n",
            file=sys.stderr,
        )
        return 2

    if action == "warn":
        print(
            f"[SAFETY GUARD WARNING] {message}\n"
            f"Command: {preview}",
            file=sys.stderr,
        )
        return 0

    return 0


if __name__ == "__main__":
    sys.exit(main())

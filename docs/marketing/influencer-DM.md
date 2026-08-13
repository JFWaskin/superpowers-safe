# Influencer DMs

> Short, low-pressure DMs to people who already talk about Claude Code
> or AI agent safety. Goal: get them to *look at it*, not to commit to
> anything.

## Who to target

Look for people who:

- Have written about Claude Code skills, plugins, or safety
- Tweet regularly about AI agent failures
- Maintain a Claude-Code-related repo with stars
- Have a "tools I use" / "Claude Code setup" blog post

Good handles to start with (this is an example list — find your own):

- @mattpocock (mattpocock/skills, very high engagement)
- @davila7 (davila7/claude-code-templates, 20k+ stars)
- @Jeffallan (Jeffallan/claude-skills, 1.4k stars)
- @hesreallyhim (hesreallyhim/awesome-claude-code, 24k stars)
- @aigeek_xyz, @Vtrivedy10, @yikesawjeez, and others in the
  Claude-Code-Templates community
- Anyone who has a blog post titled "Claude Code deleted my [X]"

## The DM (≤ 280 chars / 5 lines)

> Hey [name] — I forked obra/superpowers and added a mandatory
> 5-gate safety preflight (in-skill, not just a hook). Upstream
> reviewed it and confirmed the standalone-plugin path; the
> fork is the answer. Eval protocol forces RED-GREEN-REFACTOR
> for any gate change. 4 scenarios in Quorum format now.
>
> Repo: [LINK]
> Spec: [LINK to docs/safety-gate.md]
>
> Not asking for anything. Thought you'd find the in-skill
> enforcement angle interesting. If you do and want to talk
> about it, I'm around.

## Variations

**For a maintainer of a similar tool:**

> Hey [name] — I forked obra/superpowers and added a safety
> preflight. It would be a strict superset of what your [tool]
> does on Claude Code. If you want, I can write a one-pager on
> what overlaps and what doesn't.

**For someone who publicly had a bad Claude Code incident:**

> Hey [name] — saw your [post / tweet] about the
> [rm -rf / accidental publish / etc.]. I maintain a fork of
> obra/superpowers that adds a mandatory preflight that
> would have caught that. Sharing in case it's useful:
> [LINK]

## What NOT to do

- Don't @-mention people in a public tweet asking them to look at
  your repo. Twitter hates this.
- Don't add "I would love your feedback" to a cold DM. It's filler.
- Don't ask for a retweet in the first message. Build the
  relationship first.
- Don't DM more than 5 people in a day from one account.

## After they reply

- Be useful, not needy. If they ask a question, answer it with a
  link to a doc, not a paragraph.
- If they file an issue or PR, that's the goal — link it from
  the conversation.
- If they go silent, that's fine. They might mention you in a
  future post.

# GitHub web UI checklist

> These settings can't be set from the API or a file. You have to click
> through GitHub.com. Budget ~20 minutes.

## Repo "About" sidebar (Settings → General)

- [ ] **Description** (max 350 chars):
      `Safety-hardened fork of obra/superpowers. Same skills, plus a mandatory 5-gate safety preflight (resources, commands, spend, secrets, scope) before any skill runs. Defends your computer, hardware, budget, and data.`
- [ ] **Website**: `https://github.com/JFWaskin/superpowers-safe` (or your blog / docs site if you have one)
- [ ] **Topics** (GitHub repo tags — already have 9; consider adding these if relevant):
      `claude-code`, `coding-agent`, `preflight`, `safety`, `skill-framework`, `skills`, `superpowers`, `tdd`, `debugging`, **`mcp`**, **`ai-safety`**, **`agent-safety`**, **`claude-skills`**, **`codex`**, **`gemini-cli`**
- [ ] Check **"Include in the GitHub Discover feed"** (this lets GitHub suggest it to relevant users)
- [ ] Check **"Allow sponsor solicitation"** if you want to enable Sponsors later

## Social preview (Settings → General → Social preview)

- [ ] Upload `assets/social-preview.png` (1200×630; already in the repo).
      GitHub will show this on Twitter, LinkedIn, Slack, Discord, and any
      other service that uses Open Graph.

## Releases (github.com → Releases)

- [ ] There's a `v6.3.0` tag but **no GitHub Release** yet.
      Click "Draft a new release" → choose the `v6.3.0` tag →
      copy release notes from `CHANGELOG.md` → publish.
      (This is huge for discoverability — releases show up in Releases RSS
      feeds, GitHub search, and the Releases tab.)

## Discussions (Settings → General → Features)

- [ ] Enable **Discussions**. Pick a template set: Q&A, Ideas, Show and tell.
      (This is how the community talks to you without filing issues for
      every question.)

## Features (Settings → General → Features)

- [ ] Enable **Issues** (already on)
- [ ] Enable **Sponsorship** if you want to accept GitHub Sponsors
- [ ] Enable **Wiki** only if you have plans to maintain it; otherwise leave off
- [ ] Enable **Projects** if you use them for roadmaps

## Branch protection (Settings → Branches)

- [ ] Add a rule for `dev` and `main`: require PR reviews before merge,
      require CI to pass, disallow force-pushes.
      (This signals "we take this seriously" to potential contributors.)

## Insights (after some traffic)

- [ ] Once you have a few stars, the **"Used by"** section on the right
      sidebar will start showing dependent repos. To get there faster,
      ask one or two friends to add a tiny `depends on` or "uses
      superpowers-safe" mention in their repos.

## Profile-level (github.com/settings/profile)

- [ ] Pin this repo to your profile (so it shows on your profile page).
- [ ] Add the fork to your profile README (if you have one).
- [ ] Set your profile's primary email to a non-GitHub-noreply address
      so people can reach you.

## After all of the above

- [ ] Save, then load https://github.com/JFWaskin/superpowers-safe in an
      incognito window and check what someone new sees. The description,
      topics, and social preview should be set.
- [ ] Open the social preview image in a Twitter draft to verify it renders.

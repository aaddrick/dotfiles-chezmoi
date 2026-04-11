---
name: writing-release-notes
description: Use when preparing release notes for Play Store, App Store, or GitHub Releases. Use after tagging a release, when asked to write or update what's new text, or when preparing a version for store submission. Also use when release notes feel too technical, too vague, or read like a changelog.
---

# Writing Release Notes

## Overview

Release notes sell benefits to users, not describe changes to developers. Every claim gets verified against the codebase. Both stores index release notes for search — they're an ASO opportunity, not an afterthought.

## Process

```
git log → drop internal changes → draft (aaddrick-voice) → verify (agents) → trim to limit → save
```

### 1. Gather Changes

```bash
git log <previous-tag>..<new-tag> --oneline --no-merges
```

### 2. Filter for Users

**Keep:** Features, UX improvements, performance, bug fixes users would notice.
**Drop:** CI/CD, refactors, test coverage, dependency bumps, version bumps, code style.

Group by what the user cares about, not by code area. Three to four groups max.

### 3. Draft

Use `aaddrick-voice` subagent. Provide the filtered change list and these rules:

- **Lead with the headline** — First line is the single biggest improvement. Front-load it — users see ~170 chars before truncation on both stores
- **Benefits over features** — "No more zooming through clusters" not "Replaced MarkerClusterLayer with CircleLayer"
- **Specific, not vague** — "Sort by date, status, or origin" not "Improved sorting"
- **Human tone** — Written by a person, not generated from a commit log
- **Audience-appropriate** — Use domain language your users know (e.g., "terminals," "Space-A flights" for military travelers)
- **Frame fixes positively** — "Map loads instantly on slow connections" not "Fixed timeout bug"

### 4. Verify Every Claim

Dispatch verification agents to fact-check each claim against the codebase. Each claim gets TRUE or FALSE with evidence. Fix or remove anything that doesn't hold up. This is non-negotiable — false claims in release notes erode trust.

### 5. Fit the Limit

| Store | Limit | Formatting |
|-------|-------|------------|
| Google Play | **500 characters** (hard limit, submission rejected if exceeded) | Plain text only. No HTML, no Markdown. Line breaks and Unicode bullets (•) work. |
| Apple App Store | 4,000 characters (~170 visible before truncation) | Plain text only. Same formatting as Play Store. |

**Trimming tactics** (in order of preference):
1. Strip any HTML tags — they render as literal text and waste characters
2. Use `•` bullets instead of prose for lists
3. Cut "General" items first (dark mode, accessibility — lowest user interest)
4. Compress: "Cancelled flights dimmed, not hidden" not "Cancelled flights are now visually de-emphasized with muted colors"
5. Verify: `wc -c distribution/whatsnew/en-US.txt`

### 6. Save

Save to `distribution/whatsnew/en-US.txt`. This path is used by `r0adkll/upload-google-play` via the `whatsNewDirectory` parameter.

For Apple, expand notes into the 4,000-char budget using the "Category" framework (NEW / IMPROVED / FIXED sections) if there's enough to say.

## Anti-Patterns

| Anti-Pattern | Why It's Bad |
|-------------|-------------|
| "Bug fixes and performance improvements" | Says nothing. Google explicitly discourages this. Wastes ASO opportunity. |
| Pasting git log or ticket numbers | Users don't care about JIRA-4521 or commit hashes |
| Developer-speak ("Migrated to AndroidX") | Users don't care about your toolchain |
| Identical notes every release | Stores track this — signals low-quality to ranking algorithms |
| Keyword stuffing | Google detects unnatural keyword density and it hurts ranking |
| Negative framing ("Fixed the crash everyone complained about") | Draws attention to past problems |
| Promising unreleased features | Violates both stores' review guidelines |
| 20+ changes in 500 characters | Unreadable. Three to four bullet points max for Play Store |

## Quick Reference

```
Play Store: 500 chars, plain text, • bullets, \n line breaks
App Store:  4000 chars, plain text, same formatting
Both:       No HTML, no Markdown, no rich text
File:       distribution/whatsnew/en-US.txt
Verify:     wc -c distribution/whatsnew/en-US.txt
```

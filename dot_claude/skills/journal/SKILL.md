---
name: journal
description: Create or update today's vault journal entry with session activities. Use at the end of a work session to log what was done.
---

# Journal Entry Skill

Log today's session activities to the vault as a concise, management-friendly journal entry.

## Procedure

### Step 1: Determine today's date

Use the current date from context (format: `YYYY-MM-DD`). This is the vault journal path: `journal/YYYY-MM-DD`.

### Step 2: Read existing entry

Use `vault-read-note-tool` to read `journal/YYYY-MM-DD`. If it exists, you will append to it. If it doesn't exist, you will create it.

### Step 3: Gather session context

Review the full conversation history for this session. Identify:
- What was worked on (features, bugs, infra, planning, etc.)
- GitHub artifacts: commit SHAs, issue numbers, PR numbers
- Deploys, merges, or other significant events
- Key decisions made

For GitHub links, use these formats:
- Issues/PRs: `https://github.com/flyspacea-com/flyspacea/issues/NNN` or `.../pull/NNN`
- Commits: `https://github.com/flyspacea-com/flyspacea/commit/SHA`

If the repo is not `flyspacea-com/flyspacea`, determine the correct org/repo from git remotes.

### Step 4: Draft with aaddrick-voice agent

Spawn an `aaddrick-voice` agent with the following prompt structure:

```
Write a journal entry section for today's work session. This is a personal dev log stored in a vault.

Format rules:
- Short bullet points, 1-2 lines each max
- Group bullets under a single heading per topic (## Project Name — Topic)
- No deep dives into implementation details. A manager should be able to skim this in 30 seconds.
- Include links to commits, issues, and PRs inline where relevant
- If something was deployed, say where
- If something is blocked or pending, note it briefly
- No tables, no code blocks, no multi-paragraph explanations

Here's what happened this session:
[INSERT SUMMARY OF SESSION ACTIVITIES WITH ALL GITHUB LINKS]

Existing entry content (append after this, do not rewrite):
[INSERT EXISTING ENTRY CONTENT OR "None — new entry"]
```

The agent returns the draft text.

### Step 5: Determine tags

Every journal entry gets the `journal` tag. Add project/topic tags based on what was worked on in the session. Derive tags from the content — common tags include project names (`flyspacea`, `claude-desktop-debian`), activity types (`infra`, `tooling`, `jobsearch`), and domains (`prod-launch`, `legal`).

Check the existing entry's tags (from Step 2 frontmatter) and merge — keep all existing tags, add any new ones relevant to this session's work. No duplicates.

### Step 6: Write to vault

**If entry exists:** Use `vault-edit-note-tool` to append the new section(s) to the end of the existing note. Do not modify existing content. If new tags need to be added, use `vault-update-note-tool` to update the tags array (merging existing + new).

**If entry is new:** Use `vault-create-note-tool` to create the entry at `journal/YYYY-MM-DD` with:
- Frontmatter: `title: "YYYY-MM-DD"`, `tags: [journal, ...]` with all relevant tags
- The drafted bullet content

### Step 7: Confirm

Tell the user the entry was created/updated, list the tags applied, and provide the vault URL: `https://nonconvexlabs.com/vault/journal/YYYY-MM-DD`

## Example Output Style

```markdown
## FlySpaceA — Pipeline Batching

- Implemented batch processing for crash resilience, groups of 5 targets through steps 1-5 ([PR #440](https://github.com/flyspacea-com/flyspacea/pull/440))
- Contrarian review caught archive data loss risk between batches, fixed before merge
- Deployed to test.flyspacea.com ([`ace9aa49`](https://github.com/flyspacea-com/flyspacea/commit/ace9aa49))
- Pipeline guard false-positive blocked queue worker deploy, manual deploy required

## FlySpaceA — Email Fix

- Dev environment emails were failing because `MAIL_FROM_ADDRESS` used unverified `test.flyspacea.com` domain
- Switched to verified `flyspacea.com` for both environments ([`a827205a`](https://github.com/flyspacea-com/flyspacea/commit/a827205a))
- Awaiting deploy
```

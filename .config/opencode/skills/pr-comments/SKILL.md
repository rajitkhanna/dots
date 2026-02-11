---
name: pr-comments
description: Fetch PR review comments using the gh CLI, analyze them, and address each one by making the requested code changes
license: MIT
metadata:
  audience: developers
  workflow: github
---

# PR Comments

Fetch, analyze, and address pull request review comments using the `gh` CLI.

## When to use me

Use this skill when:

- You need to check what reviewers have commented on a PR
- You want to address and resolve outstanding PR review feedback
- You need to iterate on code changes based on reviewer suggestions

## Prerequisites

- `gh` CLI must be installed and authenticated (`gh auth status`)
- You must be in a git repository with a GitHub remote

## Workflow

### Step 1: Identify the PR

Determine the PR number. If none is provided, detect it from the current branch:

```bash
gh pr view --json number,title,headRefName,url --jq '{number, title, branch: .headRefName, url}'
```

If no PR exists for the current branch, inform the user and stop.

### Step 2: Fetch all review comments

Get all review comments (not issue-level comments) for the PR:

```bash
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments --paginate --jq '.[] | {id, path, line: (.line // .original_line), side, body, user: .user.login, created_at, in_reply_to_id, diff_hunk, subject_type, position}'
```

To also get top-level PR conversation comments (non-review):

```bash
gh api repos/{owner}/{repo}/issues/{pr_number}/comments --paginate --jq '.[] | {id, body, user: .user.login, created_at}'
```

And fetch the review summaries themselves:

```bash
gh api repos/{owner}/{repo}/pulls/{pr_number}/reviews --paginate --jq '.[] | {id, user: .user.login, state, body}'
```

### Step 3: Organize and present comments

Group the comments into:

1. **Unresolved review threads** - inline code comments that haven't been resolved
2. **Review summaries** - top-level review bodies with CHANGES_REQUESTED or COMMENTED state
3. **Conversation comments** - general PR discussion

Present a summary table to the user:

```
| # | File | Line | Reviewer | Comment (truncated) | Status |
|---|------|------|----------|---------------------|--------|
| 1 | src/foo.ts | 42 | alice | "Use const here..." | Pending |
| 2 | src/bar.ts | 18 | bob | "Missing error ha..." | Pending |
```

### Step 4: Address comments

For each comment (or a user-selected subset):

1. **Read the file** at the referenced path
2. **Understand the context** from the `diff_hunk` and surrounding code
3. **Make the requested change** using file edit tools
4. **Explain what you changed** and why it addresses the feedback

If a comment is ambiguous or you disagree with the suggestion, explain your reasoning and ask the user how to proceed rather than silently skipping it.

### Step 5: Reply to addressed comments (optional)

If the user wants, reply to each addressed comment thread:

```bash
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments/{comment_id}/replies -f body="Addressed — <brief description of change>"
```

### Step 6: Verify and summarize

After addressing all comments:

1. Run any relevant build/lint/test commands if the user requests
2. Provide a summary of all changes made
3. List any comments that were skipped or need further discussion

## Tips

- Use `gh pr diff {pr_number}` to see the full diff for additional context
- Use `gh pr checks {pr_number}` to see CI status after making changes
- For draft PRs or PRs with many comments, offer to address them in batches
- Always read the full file context around a comment, not just the diff hunk
- When a reviewer says "nit:", treat it as a low-priority suggestion but still address it

## Common gh API patterns

Get owner/repo from the current git remote:

```bash
gh repo view --json owner,name --jq '"\(.owner.login)/\(.name)"'
```

Check if a review thread is resolved:

```bash
gh api graphql -f query='
  query($owner: String!, $repo: String!, $pr: Int!) {
    repository(owner: $owner, name: $repo) {
      pullRequest(number: $pr) {
        reviewThreads(first: 100) {
          nodes {
            isResolved
            comments(first: 1) {
              nodes { body path line }
            }
          }
        }
      }
    }
  }
' -f owner=OWNER -f repo=REPO -F pr=PR_NUMBER
```

Mark a thread as resolved (after addressing):

```bash
gh api graphql -f query='
  mutation($id: ID!) {
    resolveReviewThread(input: {threadId: $id}) {
      thread { isResolved }
    }
  }
' -f id=THREAD_NODE_ID
```

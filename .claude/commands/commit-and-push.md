---
description: Commit staged/unstaged changes with a generated message, then push automatically
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git add:*), Bash(git commit:*), Bash(git push:*), Bash(git branch:*)
---

Commit the current changes and push them.

1. Run `git status`, `git diff` (staged and unstaged), and `git log --oneline -10` to see what
   changed and match this repo's commit message style.
2. Stage the relevant files by name (never `git add -A` or `git add .`). Skip anything that looks
   like it might contain secrets — double-check file contents, not just the filename, before
   staging.
3. Write a concise commit message (1-2 sentences) focused on *why*, not a restatement of the diff.
   End it with:
   ```
   Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
   ```
4. Create the commit. Never use `--no-verify` or `--amend` unless explicitly asked.
5. Run `git status` to confirm the commit succeeded, then check whether the branch tracks a
   remote and whether it's ahead.
6. Push immediately, without waiting for confirmation (`git push`, or
   `git push -u origin <branch>` if the branch has no upstream yet). Never force-push.

If there is nothing to commit, say so and stop — don't create an empty commit.

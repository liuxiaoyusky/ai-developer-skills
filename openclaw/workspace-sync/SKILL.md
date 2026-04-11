---
name: workspace-sync
description: Sync OpenClaw workspace backup. Trigger when user says "备份workspace", "同步workspace", "sync workspace", or when a cron/scheduled task triggers workspace backup.
---

# Workspace Sync

Sync `~/.openclaw/workspace/` to the git backup repo.

## Paths

| What | Path |
|------|------|
| Source (live) | `~/.openclaw/workspace/` |
| Backup (this repo) | Git remote `origin` — same as workspace |

Both share the same git remote. The backup repo is a standalone clone at `~/Documents/github/openclaw-workspace/`.

## Sync Command

```bash
rsync -av \
  --exclude='.git' \
  --exclude='funasr-env/' \
  --exclude='.venv/' \
  --exclude='__pycache__/' \
  --exclude='node_modules/' \
  --exclude='.DS_Store' \
  --exclude='shared-files/' \
  --exclude='state/' \
  --exclude='configs/' \
  --exclude='transcriptions/' \
  --exclude='*.png' \
  --exclude='*.json' \
  --exclude='*.srt' \
  --exclude='*.tsv' \
  --exclude='*.vtt' \
  --exclude='*.txt' \
  --exclude='qrcode.png' \
  --exclude='design-output.txt' \
  --exclude='claude_task.txt' \
  --exclude='awesome-openclaw-skills-zh.md' \
  ~/.openclaw/workspace/ \
  ~/Documents/github/openclaw-workspace/
```

Exclusions are synced with `.gitignore` — keep both in sync.

## Workflow

1. Run rsync (command above)
2. `cd ~/Documents/github/openclaw-workspace && git status --short`
3. `git add agents/ memory/ notes/ scripts/ self-improving/ shared/ skills/` (and any modified root files)
4. Commit with date prefix: `🧠 YYYY-MM-DD workspace 同步：<summary>`
5. `git push origin main`

## Commit Message Format

```
🧠 YYYY-MM-DD workspace 同步：<one-line summary of major changes>
```

Check `git diff --stat` for summary of what changed.

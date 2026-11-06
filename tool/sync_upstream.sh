#!/usr/bin/env bash
# Sync this fork's master with Demizo/Daily_You and let CI release it.
#
# Meant for cron. Works in its own clone so it never touches a dev checkout:
# fetches upstream, merges upstream/master into the fork's master, pushes.
# The push triggers .github/workflows/release.yml, whose `version` job skips
# unless pubspec.yaml carries a version with no published release yet, so a
# merge without a version bump costs one quick no-op run.
#
# Never force-pushes. A merge conflict aborts and exits non-zero; resolve it
# by hand in a normal checkout.
#
# Usage: tool/sync_upstream.sh [--dry-run]
#   --dry-run   fetch and report what would be merged; change nothing
#
# Env overrides:
#   FORK_URL       (default https://github.com/BigWebstas/Daily_You.git)
#   UPSTREAM_URL   (default https://github.com/Demizo/Daily_You.git)
#   BRANCH         (default master)
#   SYNC_DIR       (default ~/.cache/daily-you-sync)
#
# Cron example (every 6 hours):
#   0 */6 * * * /path/to/Daily_You/tool/sync_upstream.sh >> ~/.cache/daily-you-sync.log 2>&1
#
# Pushing needs non-interactive git auth in cron's environment: an SSH key
# without a passphrase-only agent, or HTTPS via `gh auth setup-git`.

set -euo pipefail

FORK_URL="${FORK_URL:-https://github.com/BigWebstas/Daily_You.git}"
UPSTREAM_URL="${UPSTREAM_URL:-https://github.com/Demizo/Daily_You.git}"
BRANCH="${BRANCH:-master}"
SYNC_DIR="${SYNC_DIR:-$HOME/.cache/daily-you-sync}"
DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

log() { echo "[$(date -u +%FT%TZ)] $*"; }

# Cron runs can overlap if one hangs on the network.
mkdir -p "$(dirname "$SYNC_DIR")"
exec 9>"$SYNC_DIR.lock"
flock -n 9 || { log "another sync is running; exiting"; exit 0; }

if [[ ! -d "$SYNC_DIR/.git" ]]; then
  log "cloning $FORK_URL into $SYNC_DIR"
  git clone --quiet "$FORK_URL" "$SYNC_DIR"
fi
cd "$SYNC_DIR"

git remote set-url origin "$FORK_URL"
if git remote get-url upstream >/dev/null 2>&1; then
  git remote set-url upstream "$UPSTREAM_URL"
else
  git remote add upstream "$UPSTREAM_URL"
fi
# Merge commits need an identity, and cron may have none configured.
git config user.name >/dev/null 2>&1 || git config user.name "daily-you-sync"
git config user.email >/dev/null 2>&1 || git config user.email "daily-you-sync@users.noreply.github.com"

git fetch --quiet origin "$BRANCH"
git fetch --quiet upstream "$BRANCH"

# This clone is the script's own scratch space, so discard any leftover state
# from an interrupted run and start from the fork's published branch.
git merge --abort 2>/dev/null || true
git checkout --quiet -B "$BRANCH" "origin/$BRANCH"

behind=$(git rev-list --count "HEAD..upstream/$BRANCH")
if [[ "$behind" -eq 0 ]]; then
  log "fork $BRANCH is up to date with upstream/$BRANCH"
  exit 0
fi

up_version=$(git show "upstream/$BRANCH:pubspec.yaml" | grep -m1 '^version:' || true)
log "upstream has $behind new commit(s); upstream ${up_version:-version unknown}"
git log --oneline "HEAD..upstream/$BRANCH" | head -20

if [[ "$DRY_RUN" -eq 1 ]]; then
  log "dry run: not merging or pushing"
  exit 0
fi

if ! git merge --no-edit -m "Merge upstream Demizo/Daily_You $BRANCH" "upstream/$BRANCH"; then
  log "ERROR: merge conflict; aborting. Resolve manually:"
  git diff --name-only --diff-filter=U | sed 's/^/  conflict: /'
  git merge --abort
  exit 1
fi

git push origin "$BRANCH"
log "pushed merge; the Release workflow now decides whether $up_version needs a release"

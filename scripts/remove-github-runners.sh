#!/usr/bin/env bash
# Removes all self-hosted runners from your GitHub account (across all repos and orgs).
# Requires: GITHUB_TOKEN env var with 'repo' scope (and 'admin:org' for org runners).
#
# Usage:
#   GITHUB_TOKEN=ghp_xxx ./remove-github-runners.sh
#   GITHUB_TOKEN=ghp_xxx ./remove-github-runners.sh --org my-org   # only scan one specific org
#   GITHUB_TOKEN=ghp_xxx ./remove-github-runners.sh --dry-run       # preview only
#   GITHUB_TOKEN=ghp_xxx ./remove-github-runners.sh --parallel 20   # concurrency (default: 10)

set -uo pipefail

DRY_RUN=false
ORG=""
MAX_PARALLEL=10

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)    DRY_RUN=true ;;
    --org)        ORG="$2"; shift ;;
    --parallel)   MAX_PARALLEL="$2"; shift ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
  shift
done

: "${GITHUB_TOKEN:?GITHUB_TOKEN must be set}"

API="https://api.github.com"
AUTH=(-H "Authorization: Bearer $GITHUB_TOKEN" -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28")

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

api_get() {
  local url="$1"
  local body http_code
  body=$(curl -s -w "\n%{http_code}" "${AUTH[@]}" "$url")
  http_code=$(echo "$body" | tail -n1)
  body=$(echo "$body" | head -n -1)
  if [[ "$http_code" -lt 200 || "$http_code" -ge 300 ]]; then
    echo "    [warn] HTTP $http_code for $url" >&2
    echo ""
    return 0
  fi
  echo "$body"
}

# Processes one scope (repo or org) — runs in a subshell for parallelism.
# Writes counts to TMPDIR so the parent can sum them.
delete_runners() {
  local scope="$1"
  local label="$2"
  local d=0 s=0

  local page=1
  while true; do
    local response
    response=$(api_get "$API/$scope/actions/runners?per_page=100&page=$page")
    [[ -z "$response" ]] && break
    local count
    count=$(echo "$response" | jq '.runners | length' 2>/dev/null || echo 0)
    [[ "$count" -eq 0 ]] && break

    while IFS= read -r runner; do
      local id name status
      id=$(echo "$runner" | jq -r '.id')
      name=$(echo "$runner" | jq -r '.name')
      status=$(echo "$runner" | jq -r '.status')

      echo "  Runner: $name (id=$id, status=$status) in $label"

      if [[ "$DRY_RUN" == "true" ]]; then
        echo "    [dry-run] Would delete runner $id"
        ((s++)) || true
      else
        local del_code
        del_code=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "${AUTH[@]}" "$API/$scope/actions/runners/$id")
        if [[ "$del_code" -ge 200 && "$del_code" -lt 300 ]]; then
          echo "    Deleted."
          ((d++)) || true
        else
          echo "    Failed to delete (HTTP $del_code)."
          ((s++)) || true
        fi
      fi
    done < <(echo "$response" | jq -c '.runners[]')

    ((page++))
  done

  # Atomically append counts for parent to sum
  echo "$d" >> "$TMPDIR/deleted"
  echo "$s" >> "$TMPDIR/skipped"
}

# Run delete_runners in background, capping at MAX_PARALLEL jobs.
pids=()
dispatch() {
  local scope="$1" label="$2"
  echo "--> $label"
  delete_runners "$scope" "$label" &
  pids+=("$!")

  # If at the concurrency limit, wait for one job to finish then prune dead PIDs.
  if (( ${#pids[@]} >= MAX_PARALLEL )); then
    wait -n "${pids[@]}"
    local live=()
    local pid
    for pid in "${pids[@]}"; do
      kill -0 "$pid" 2>/dev/null && live+=("$pid")
    done
    pids=("${live[@]}")
  fi
}

# --- Collect repos ---
echo "==> Fetching repositories and organisations..."
page=1
while true; do
  repos=$(api_get "$API/user/repos?per_page=100&page=$page&affiliation=owner")
  [[ -z "$repos" ]] && break
  count=$(echo "$repos" | jq 'length' 2>/dev/null || echo 0)
  [[ "$count" -eq 0 ]] && break
  while IFS= read -r full_name; do
    dispatch "repos/$full_name" "$full_name"
  done < <(echo "$repos" | jq -r '.[].full_name')
  ((page++))
done

# --- Collect orgs ---
if [[ -n "$ORG" ]]; then
  dispatch "orgs/$ORG" "org:$ORG"
else
  page=1
  while true; do
    orgs=$(api_get "$API/user/orgs?per_page=100&page=$page")
    [[ -z "$orgs" ]] && break
    count=$(echo "$orgs" | jq 'length' 2>/dev/null || echo 0)
    [[ "$count" -eq 0 ]] && break
    while IFS= read -r org_login; do
      dispatch "orgs/$org_login" "org:$org_login"
    done < <(echo "$orgs" | jq -r '.[].login')
    ((page++))
  done
fi

wait "${pids[@]}"  # drain remaining background jobs

deleted=$(awk '{s+=$1} END{print s+0}' "$TMPDIR/deleted" 2>/dev/null || echo 0)
skipped=$(awk '{s+=$1} END{print s+0}' "$TMPDIR/skipped" 2>/dev/null || echo 0)

echo ""
if [[ "$DRY_RUN" == "true" ]]; then
  echo "Dry run complete. $skipped runner(s) would be deleted."
else
  echo "Done. Deleted: $deleted, Skipped/failed: $skipped."
fi

#!/usr/bin/env bash
# PR の merge ready 判定に必要な情報をまとめて出力する。
# usage: pr-status.sh [PR番号]  (省略時は現在の branch の PR)
set -euo pipefail

pr="${1:-}"

info=$(gh pr view ${pr:+"$pr"} --json number,url,title,state,isDraft,mergeable,mergeStateStatus,reviewDecision,headRefOid,statusCheckRollup)
number=$(jq -r .number <<<"$info")
repo=$(gh repo view --json owner,name -q '.owner.login + " " + .name')
owner=${repo% *}
name=${repo#* }

echo "== PR"
jq -r '"#\(.number) \(.title)\n\(.url)\nstate=\(.state) draft=\(.isDraft) mergeable=\(.mergeable) mergeState=\(.mergeStateStatus) reviewDecision=\(.reviewDecision // "NONE")"' <<<"$info"

echo
echo "== Checks"
jq -r '.statusCheckRollup[]?
  | ([.conclusion, .state, .status] | map(select(. != null and . != "")) | first // "UNKNOWN") as $s
  | "\($s)\t\(.name // .context)"' <<<"$info" | sort | uniq

echo
echo "== Unresolved review threads"
gh api graphql -f owner="$owner" -f name="$name" -F number="$number" -f query='
query($owner:String!, $name:String!, $number:Int!) {
  repository(owner:$owner, name:$name) {
    pullRequest(number:$number) {
      reviewThreads(first:100) {
        nodes {
          id isResolved isOutdated path line
          comments(first:20) { nodes { databaseId author { login } body createdAt } }
        }
      }
    }
  }
}' | jq -r '
  .data.repository.pullRequest.reviewThreads.nodes[]
  | select(.isResolved | not)
  | "--- thread=\(.id) \(.path):\(.line // "-")\(if .isOutdated then " (outdated)" else "" end)",
    (.comments.nodes[] | "  [\(.author.login) \(.createdAt) id=\(.databaseId)] \(.body | gsub("\n"; " ") | .[0:300])")'

echo
echo "== Latest reviews / PR comments (top-level)"
gh pr view "$number" --json reviews,comments -q '
  ([.reviews[] | {who: .author.login, at: .submittedAt, kind: ("review:" + .state), body}]
   + [.comments[] | {who: .author.login, at: .createdAt, kind: "comment", body}])
  | sort_by(.at) | .[-10:][]
  | "[\(.who) \(.at) \(.kind)] \(.body | gsub("\n"; " ") | .[0:300])"'

echo
echo "== Codex review state (head=$(jq -r '.headRefOid[0:10]' <<<"$info"))"
gh pr view "$number" --json comments -q '.comments[] | select(.body | contains("codex-review-state:v1")) | .body' \
  | grep -o 'codex-review-state:v1 {.*} -->' | tail -1 | sed -e 's/^codex-review-state:v1 //' -e 's/ -->$//' \
  | jq -r 'to_entries[] | "\(.key): status=\(.value.status) commit=\(.value.commit_sha[0:10]) unresolved=\(.value.has_unresolved_findings)"' \
  || echo "(no codex review state)"

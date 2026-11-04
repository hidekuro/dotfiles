#!/bin/bash
# 許可ルールでこのファイルを確認なしに実行させているので、クエリに書き込み (mutation) を足さない。
set -euo pipefail

owner="${1%/*}"
repo="${1#*/}"
pr="$2"

# shellcheck disable=SC2016
gh api graphql -F owner="${owner}" -F repo="${repo}" -F pr="${pr}" -f query='
query($owner: String!, $repo: String!, $pr: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $pr) {
      reviewThreads(first: 100) {
        totalCount
        nodes {
          id
          isResolved
          isOutdated
          path
          line
          startLine
          originalLine
          comments(first: 50) { totalCount nodes { databaseId url author { login __typename } body } }
        }
      }
      reviews(first: 100) { totalCount nodes { url author { login __typename } state body } }
      comments(first: 100) { totalCount nodes { url author { login __typename } body } }
    }
  }
}' --jq '
.data.repository.pullRequest | {
  threadCount: .reviewThreads.totalCount,
  reviewCount: .reviews.totalCount,
  commentCount: .comments.totalCount,
  threads: [.reviewThreads.nodes[] | select(.isResolved | not) | {threadId: .id, path, line, startLine, originalLine, isOutdated, commentCount: .comments.totalCount, comments: [.comments.nodes[] | {id: .databaseId, url, author: .author.login, type: .author.__typename, body}]}],
  reviews: [.reviews.nodes[] | select(.body != "") | {url, author: .author.login, type: .author.__typename, state, body}],
  comments: [.comments.nodes[] | {url, author: .author.login, type: .author.__typename, body}]
}'

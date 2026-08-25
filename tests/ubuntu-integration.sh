#!/usr/bin/env bash

set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
binary="${1:-${project_root}/_build/native/debug/build/cmd/gh-shim/gh-shim.exe}"
test_root="$(mktemp -d "${TMPDIR:-/tmp}/gh-shim-integration.XXXXXX")"
trap 'rm -rf "${test_root}"' EXIT

fake_bin="${test_root}/bin"
mkdir -p "${fake_bin}"
cp "${project_root}/tests/fake-gh" "${fake_bin}/gh"
chmod +x "${fake_bin}/gh"
export GH_FAKE_LOG="${test_root}/fake-gh.log"
: >"${GH_FAKE_LOG}"

set +e
printf 'payload\n' | env -u HOME -u XDG_DATA_HOME \
  PATH="${fake_bin}:/usr/bin:/bin" "${binary}" passthrough \
  >"${test_root}/passthrough.out" 2>"${test_root}/passthrough.err"
passthrough_status=$?
set -e
[[ ${passthrough_status} -eq 23 ]]
[[ "$(<"${test_root}/passthrough.out")" == "fake stdout: payload" ]]
[[ "$(<"${test_root}/passthrough.err")" == "fake stderr" ]]

json_home="${test_root}/json-home"
mkdir -p "${json_home}"
text_output="$(env HOME="${json_home}" XDG_DATA_HOME="${json_home}/data" \
  PATH="${fake_bin}:/usr/bin:/bin" "${binary}" pr view 42 \
  --repo acme/widgets --comments)"
grep -Fq '2 review threads · 1 open · 1 resolved; 0 outdated' \
  <<<"${text_output}"
grep -Fq 'src/main.mbt:12' <<<"${text_output}"
grep -Fq '  author replied' <<<"${text_output}"
grep -Fq '✓ README.md · resolved by author' <<<"${text_output}"

json_output="$(env HOME="${json_home}" XDG_DATA_HOME="${json_home}/data" \
  PATH="${fake_bin}:/usr/bin:/bin" "${binary}" pr view 42 \
  --repo acme/widgets --json comments)"
[[ "$(jq 'keys == ["comments"]' <<<"${json_output}")" == "true" ]]
[[ "$(jq '.comments | length' <<<"${json_output}")" == "4" ]]
[[ "$(jq '[.comments[] | select(.reviewThread)] | length' \
  <<<"${json_output}")" == "3" ]]
[[ "$(jq -r '.comments[] | select(.id == "comment-1") | .reviewThread.path' \
  <<<"${json_output}")" == "src/main.mbt" ]]
[[ "$(jq -r '.comments[] | select(.id == "comment-3") | .reviewThread.isResolved' \
  <<<"${json_output}")" == "true" ]]

projected_output="$(env HOME="${json_home}" XDG_DATA_HOME="${json_home}/data" \
  PATH="${fake_bin}:/usr/bin:/bin" "${binary}" pr view 42 \
  --repo acme/widgets --json reviews,comments \
  --jq '{comments: [.comments[] | {author: .author.login, body: .body}]}')"
[[ "$(jq '.comments | length' <<<"${projected_output}")" == "4" ]]
[[ "$(jq -r '.comments[1].author' <<<"${projected_output}")" == "reviewer" ]]

combined_output="$(env HOME="${json_home}" XDG_DATA_HOME="${json_home}/data" \
  PATH="${fake_bin}:/usr/bin:/bin" "${binary}" pr view 42 \
  --repo acme/widgets --json comments,reviewThreads)"
[[ "$(jq 'keys == ["comments", "reviewThreads"]' \
  <<<"${combined_output}")" == "true" ]]
[[ "$(jq '.reviewThreads[0].comments | length' \
  <<<"${combined_output}")" == "2" ]]

jq_output="$(env HOME="${json_home}" XDG_DATA_HOME="${json_home}/data" \
  PATH="${fake_bin}:/usr/bin:/bin" "${binary}" pr view 42 \
  --repo acme/widgets --json reviewThreads --jq '.reviewThreads | length')"
[[ "${jq_output}" == "2" ]]

: >"${GH_FAKE_LOG}"
set +e
env HOME="${json_home}" XDG_DATA_HOME="${json_home}/data" \
  PATH="${fake_bin}:/usr/bin:/bin" "${binary}" pr view 42 \
  --repo acme/widgets --json reviewThreads --template '{{len .reviewThreads}}' \
  >"${test_root}/template.out" 2>"${test_root}/template.err"
template_status=$?
set -e
[[ ${template_status} -eq 1 ]]
grep -Fq -- '--template cannot format enhanced comments or reviewThreads output' \
  "${test_root}/template.err"
[[ ! -s "${GH_FAKE_LOG}" ]]

: >"${GH_FAKE_LOG}"
set +e
env HOME="${json_home}" XDG_DATA_HOME="${json_home}/data" \
  PATH="${fake_bin}:/usr/bin:/bin" "${binary}" pr view 42 \
  --repo acme/widgets --json reviewThreads -t'{{len .reviewThreads}}' \
  >"${test_root}/attached-template.out" \
  2>"${test_root}/attached-template.err"
attached_template_status=$?
set -e
[[ ${attached_template_status} -eq 1 ]]
grep -Fq -- '--template cannot format enhanced comments or reviewThreads output' \
  "${test_root}/attached-template.err"
[[ ! -s "${GH_FAKE_LOG}" ]]

set +e
GH_FAKE_FAIL_COMMENT_PAGE=1 env HOME="${json_home}" \
  XDG_DATA_HOME="${json_home}/data" PATH="${fake_bin}:/usr/bin:/bin" \
  "${binary}" pr view 42 --repo acme/widgets --json reviewThreads \
  >"${test_root}/page-failure.out" 2>"${test_root}/page-failure.err"
page_status=$?
set -e
[[ ${page_status} -eq 1 ]]
[[ ! -s "${test_root}/page-failure.out" ]]
grep -Fq 'failed to fetch review thread replies: comment page failed' \
  "${test_root}/page-failure.err"

bash_home="${test_root}/bash-home"
mkdir -p "${bash_home}"
for _ in 1 2; do
  env HOME="${bash_home}" XDG_DATA_HOME="${bash_home}/data" SHELL=/bin/bash \
    PATH="${fake_bin}:/usr/bin:/bin" "${binary}" init bash >/dev/null
done
[[ "$(grep -c ' init - bash)' "${bash_home}/.bashrc")" == "1" ]]
[[ "$(grep -c ' init - bash)' "${bash_home}/.bash_profile")" == "1" ]]
shim="${bash_home}/data/gh-shim/shims"
[[ "$(env HOME="${bash_home}" XDG_DATA_HOME="${bash_home}/data" \
  PATH="${shim}:${fake_bin}:/usr/bin:/bin" gh --version)" == "gh version fake" ]]
login_gh="$(env HOME="${bash_home}" XDG_DATA_HOME="${bash_home}/data" \
  PATH="${fake_bin}:/usr/bin:/bin" bash --login -ic 'command -v gh' 2>/dev/null)"
[[ "${login_gh}" == "${shim}/gh" ]]

fish_home="${test_root}/fish-home"
fish_config="${test_root}/fish-config"
mkdir -p "${fish_home}"
env HOME="${fish_home}" XDG_DATA_HOME="${fish_home}/data" \
  XDG_CONFIG_HOME="${fish_config}" SHELL=/usr/bin/fish \
  PATH="${fake_bin}:/usr/bin:/bin" "${binary}" init fish >/dev/null
[[ -f "${fish_config}/fish/config.fish" ]]
if fish_executable="$(command -v fish)"; then
  fish_shim="${fish_home}/data/gh-shim/shims"
  fish_gh="$(env HOME="${fish_home}" XDG_DATA_HOME="${fish_home}/data" \
    XDG_CONFIG_HOME="${fish_config}" PATH="${fake_bin}:/usr/bin:/bin" \
    "${fish_executable}" --no-config -c \
    "source '${fish_config}/fish/config.fish'; command -v gh")"
  [[ "${fish_gh}" == "${fish_shim}/gh" ]]
fi

printf 'Ubuntu integration tests passed.\n'

#!/bin/sh
# Exercises scripts/pr.sh's push-target logic offline: local bare repositories stand in for the upstream
# and a contributor's fork (so `git push` is real), and a fake `gh` records what the script asked GitHub
# to do. Covers a maintainer (pushes to origin) and a read-only contributor (pushes to a fork, opens a
# cross-repository PR). Each case uses a different default branch name (main, then master) and asserts the
# PR targets it, proving the base comes from scripts/default-branch.sh rather than a hard-coded name. Each
# checkout also carries an `upstream` remote (a third bare repository standing in for the template a
# project was forked from), and the fake `gh` answers as a different, read-only repository whenever it is
# asked about the checkout without an explicit repository, the way the real `gh` prefers `upstream` over
# `origin`; the assertions then prove the PR still targets `origin`'s repository and nothing is pushed to
# `upstream`.
set -eu

repo_root=$(git rev-parse --show-toplevel)
fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT

bin="$fixture/bin"
mkdir -p "$bin"
cat > "$bin/gh" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >> "$FAKE_GH_LOG"
case "$1 $2" in
  "auth status") exit 0 ;;
  "api user") printf '%s\n' contributor ;;
  "repo fork") touch "$FAKE_GH_STATE/forked" ;;
  "pr list") exit 0 ;;
  "pr create") printf '%s\n' "https://example.test/pull/1" ;;
  "repo view")
    case "$*" in
      *nameWithOwner*)
        # $3 is the repository argument. Only origin's URL gets origin's answer; anything else (including
        # no argument, which the real gh resolves to the upstream remote) is answered as the template.
        if [ "$3" = "$FAKE_ORIGIN_URL" ]; then
          printf '{"nameWithOwner":"acme/proj","isFork":false,"parent":null,"viewerPermission":"%s","owner":{"login":"acme"}}\n' "$FAKE_PERMISSION"
        else
          printf '{"nameWithOwner":"template/tmpl","isFork":false,"parent":null,"viewerPermission":"READ","owner":{"login":"template"}}\n'
        fi
        ;;
      *"--json url"* | *"--json sshUrl"*) printf '%s\n' "$FAKE_FORK_URL" ;;
      *) [ -f "$FAKE_GH_STATE/forked" ] || exit 1 ;;
    esac
    ;;
  *) exit 1 ;;
esac
EOF
chmod +x "$bin/gh"

run_case() {
  case_name=$1
  permission=$2
  base=$3

  case_dir="$fixture/$case_name"
  mkdir -p "$case_dir/state"
  git init -q --bare "$case_dir/upstream.git"
  git init -q --bare "$case_dir/fork.git"
  git init -q --bare "$case_dir/template.git"
  git clone -q "$case_dir/upstream.git" "$case_dir/work" 2>/dev/null

  cd "$case_dir/work"
  git remote add upstream "$case_dir/template.git"
  git config user.email fixture@example.com
  git config user.name fixture
  mkdir scripts
  cp "$repo_root/scripts/pr.sh" "$repo_root/scripts/resolve-pr-target.sh" "$repo_root/scripts/default-branch.sh" scripts/
  for stub in check-secrets.sh check.sh check-ci-only.sh list-completed-changes.sh; do
    printf '#!/bin/sh\nexit 0\n' > "scripts/$stub"
    chmod +x "scripts/$stub"
  done
  git checkout -q -b "$base"
  git add -A
  git commit -q -m "chore(repo): fixture base"
  git push -q origin "$base"
  echo change > change.txt

  : > "$case_dir/gh.log"
  PATH="$bin:$PATH" \
    FAKE_GH_LOG="$case_dir/gh.log" \
    FAKE_GH_STATE="$case_dir/state" \
    FAKE_PERMISSION="$permission" \
    FAKE_ORIGIN_URL="$case_dir/upstream.git" \
    FAKE_FORK_URL="$case_dir/fork.git" \
    ./scripts/pr.sh --type feat --scope repo --message "add change" --branch feat-x --all > "$case_dir/out.log" 2>&1 \
    || { cat "$case_dir/out.log" >&2; printf '%s\n' "$case_name: pr.sh failed" >&2; exit 1; }
  cd "$repo_root"
}

has_branch() {
  git -C "$1" show-ref --verify --quiet refs/heads/feat-x
}

fail() {
  printf '%s\n' "$1" >&2
  exit 1
}

run_case maintainer WRITE main
has_branch "$fixture/maintainer/upstream.git" || fail "maintainer: branch was not pushed to origin"
has_branch "$fixture/maintainer/fork.git" && fail "maintainer: branch must not be pushed to a fork"
grep -q -- '--head feat-x ' "$fixture/maintainer/gh.log" || fail "maintainer: PR head should be the bare branch name"
grep -q 'repo fork' "$fixture/maintainer/gh.log" && fail "maintainer: must not create a fork"
grep -q -- '--repo acme/proj' "$fixture/maintainer/gh.log" || fail "maintainer: PR must target origin's repository, not the upstream remote's"
has_branch "$fixture/maintainer/template.git" && fail "maintainer: branch must not be pushed to the upstream remote"
grep -q -- '--base main ' "$fixture/maintainer/gh.log" || fail "maintainer: PR base should be the detected default branch main"

run_case contributor READ master
has_branch "$fixture/contributor/fork.git" || fail "contributor: branch was not pushed to the fork"
has_branch "$fixture/contributor/upstream.git" && fail "contributor: branch must not be pushed to upstream"
grep -q 'repo fork acme/proj' "$fixture/contributor/gh.log" || fail "contributor: fork was not created"
grep -q -- '--repo acme/proj' "$fixture/contributor/gh.log" || fail "contributor: PR must target the upstream repository"
grep -q -- '--head contributor:feat-x' "$fixture/contributor/gh.log" || fail "contributor: PR head must be owner:branch"
has_branch "$fixture/contributor/template.git" && fail "contributor: branch must not be pushed to the upstream remote"
grep -q -- '--base master ' "$fixture/contributor/gh.log" || fail "contributor: PR base should be the detected default branch master, not a hard-coded main"

printf '%s\n' "PR fork-workflow fixture passed"

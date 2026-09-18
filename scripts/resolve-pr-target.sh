#!/bin/sh
# Decides where a pull request's branch is pushed and which repository the PR targets, so contributors
# without write access can use the standard fork workflow. Prints four lines:
#   1. target repository (owner/name) the PR opens against — the upstream, even from a clone of a fork
#   2. push remote: "origin" when the current user can push there, otherwise "fork"
#   3. head owner: the account that owns the branch being pushed
#   4. "yes" when a fork must be created/used, otherwise "no"
# Optional argument: owner/name to inspect instead of the repository gh resolves from the checkout.
set -eu

info=$(gh repo view ${1:+"$1"} --json nameWithOwner,isFork,parent,viewerPermission,owner)

me=""
case "$(printf '%s' "$info" | node -pe "JSON.parse(require('fs').readFileSync(0, 'utf8')).viewerPermission")" in
  ADMIN | MAINTAIN | WRITE) can_push=yes ;;
  *) can_push=no ;;
esac

if [ "$can_push" = no ]; then
  me=$(gh api user --jq .login)
fi

printf '%s' "$info" | CAN_PUSH="$can_push" ME="$me" node -e '
const info = JSON.parse(require("fs").readFileSync(0, "utf8"));
const target = info.isFork && info.parent
  ? `${info.parent.owner.login}/${info.parent.name}`
  : info.nameWithOwner;
const canPush = process.env.CAN_PUSH === "yes";
console.log(target);
console.log(canPush ? "origin" : "fork");
console.log(canPush ? info.owner.login : process.env.ME);
console.log(canPush ? "no" : "yes");
'

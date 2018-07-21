#!/bin/sh
set -e
set +x # do not display any command, as they could contain the Travis openssl key and IV.

usage() {
  echo "Usage: $0 official_repo deploy_repo deploy_branch deploy_base_commit key_iv_id deploy_directory"
  echo "official_repo:       https://github.com/user/repo.git"
  echo "deploy_repo:         git@github.com:user/repo.git"
  echo "deploy_branch:       gh-pages"
  echo "deploy_base_commit:  branch name or tag"
  echo "key_iv_id:           123456789abc, part of encrypted_123456789abc_key and encrypted_123456789abc_iv"
  echo "deploy_directory:    directory to copy on top of deploy_base_commit"
  echo "from_branch:         master # allow push only when building the given branch"
}

if test "$#" -eq 1 && test "$1" = "-h" -o "$1" = "--help"; then
  usage
  exit 0
elif test "$#" -ne 7; then
  usage
  exit 1
fi

official_repo="$1"      # https://github.com/user/repo.git
deploy_repo="$2"        # git@github.com:user/repo.git
deploy_branch="$3"      # gh-pages
deploy_base_commit="$4" # branch name or tag
key_iv_id="$5"          # 123456789abc, part of encrypted_123456789abc_key and encrypted_123456789abc_iv
deploy_directory="$6"   # directory to copy on top of deploy_base_commit
from_branch="$7"        # master # allow push only when building the given branch
key_env_var_name="encrypted_${key_iv_id}_key"
iv_env_var_name="encrypted_${key_iv_id}_iv"
key="$(sh -c 'echo "${'"$key_env_var_name"'}"')"
iv="$(sh -c 'echo "${'"$iv_env_var_name"'}"')"

if test "$(git config remote.origin.url)" != "$official_repo"; then
  echo "Not on official repo, will not deploy to ${deploy_repo}:${deploy_branch}."
elif test "$TRAVIS_PULL_REQUEST" != "false"; then
  echo "This is a Pull Request, will not deploy to ${deploy_repo}:${deploy_branch}."
elif test "$TRAVIS_BRANCH" != "$from_branch"; then
  echo "Not on $from_branch branch (TRAVIS_BRANCH = $TRAVIS_BRANCH), will not deploy to ${deploy_repo}:${deploy_branch}."
elif test -z "${key:-}" -o -z "${iv:-}"; then
  echo "Travis CI secure environment variables are unavailable, will not deploy to ${deploy_repo}:${deploy_branch}."
elif test ! -e travis-deploy-key-id_rsa.enc; then
  echo "travis-deploy-key-id_rsa.enc not present, will not deploy to ${deploy_repo}:${deploy_branch}."
else
  echo "Automatic push to ${deploy_repo}:${deploy_branch}"

  # Git configuration:
  git config --global user.name "$(git log --format="%aN" HEAD -1) (Travis CI automatic commit)"
  git config --global user.email "$(git log --format="%aE" HEAD -1)"

  # SSH configuration
  mkdir -p ~/.ssh
  chmod 700 ~/.ssh
  if openssl aes-256-cbc -K "$key" -iv "$iv" -in travis-deploy-key-id_rsa.enc -out travis-deploy-key-id_rsa -d >/dev/null 2>&1; then
    echo "Decrypted key successfully."
  else
    echo "Error while decrypting key."
    exit 1
  fi
  # TODO: all the config should be in a separate folder, instead of using ~/.ssh for the id_rsa.
  mv travis-deploy-key-id_rsa ~/.ssh/travis-deploy-key-id_rsa
  chmod 600 ~/.ssh/travis-deploy-key-id_rsa
  eval `ssh-agent -s`
  ssh-add ~/.ssh/travis-deploy-key-id_rsa

  travis_known_hosts="$("$(dirname "$0")/absolute-path.sh" "$(dirname "$0")/travis_known_hosts")"
  chmod 600 "$travis_known_hosts"
  echo "$travis_known_hosts"
  cat "$travis_known_hosts"
  ssh -o UserKnownHostsFile=$travis_known_hosts git@github.com || true

  TRAVIS_AUTO_PUSH_REPO_DIR="$HOME/travis-temp-auto-push-$(date +%s)"
  if test -e "$TRAVIS_AUTO_PUSH_REPO_DIR"; then rm -rf "$TRAVIS_AUTO_PUSH_REPO_DIR"; fi
  GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=$travis_known_hosts" git clone -b "$deploy_base_commit" --depth 1 --shallow-submodules "$deploy_repo" "$TRAVIS_AUTO_PUSH_REPO_DIR"
  (cd "$TRAVIS_AUTO_PUSH_REPO_DIR" && git checkout -b "$deploy_branch")
  rsync -a "${deploy_directory}/" "${TRAVIS_AUTO_PUSH_REPO_DIR}/"
  (cd "$TRAVIS_AUTO_PUSH_REPO_DIR" && git add -A . && git commit --allow-empty -m "Auto-publish to $deploy_branch") > commit.log || (cat commit.log && exit 1)
  (cd "$TRAVIS_AUTO_PUSH_REPO_DIR" && git log --oneline --decorate --graph -10)
  echo '(cd '"$TRAVIS_AUTO_PUSH_REPO_DIR"' && git push --force --quiet "'"$deploy_repo"'" "'"$deploy_branch"'")'
  (cd "$TRAVIS_AUTO_PUSH_REPO_DIR" && GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=$travis_known_hosts" git push --force --quiet "$deploy_repo" "$deploy_branch" >/dev/null 2>&1) >/dev/null 2>&1 # redirect to /dev/null to avoid showing credentials.
fi

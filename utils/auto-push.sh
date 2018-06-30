#!/bin/sh
set -e
set +x

usage() {
  echo "Usage: $0 official_repo deploy_repo deploy_branch deploy_base_commit key_iv_id deploy_directory"
  echo "official_repo:       https://github.com/user/repo.git"
  echo "deploy_repo:         git@github.com:user/repo.git"
  echo "deploy_branch:       gh-pages"
  echo "deploy_base_commit:  branch name or tag"
  echo "key_iv_id:           123456789abc, part of encrypted_123456789abc_key and encrypted_123456789abc_iv"
  echo "deploy_directory:    directory to copy on top of deploy_base_commit"
}

if test "$#" -eq 1 && test "$1" = "-h" -o "$1" = "--help"; then
  usage
  exit 0
elif test "$#" -ne 5; then
  usage
  exit 1
fi

official_repo="$1"      # https://github.com/user/repo.git
deploy_repo="$2"        # git@github.com:user/repo.git
deploy_branch="$3"      # gh-pages
deploy_base_commit="$3" # branch name or tag
key_iv_id="$4"          # 123456789abc, part of encrypted_123456789abc_key and encrypted_123456789abc_iv
deploy_directory="$5"   # directory to copy on top of deploy_base_commit
key_env_var_name="encrypted_${key_iv_id}_key"
iv_env_var_name="encrypted_${key_iv_id}_key"
key="${!key_env_var_name}"
iv="${!iv_env_var_name}"

if test "$(git config remote.origin.url)" != "$official_repo"; then
  echo "Not on official repo, will not deploy to ${deploy_repo}:${deploy_branch}."
elif test "$TRAVIS_PULL_REQUEST" != "false"; then
  echo "This is a Pull Request, will not deploy to ${deploy_repo}:${deploy_branch}."
elif test "$TRAVIS_BRANCH" != "master"; then
  echo "Not on master branch (TRAVIS_BRANCH = $TRAVIS_BRANCH), will not deploy to ${deploy_repo}:${deploy_branch}."
elif test -z "${key:-}" -o -z "${iv:-}"; then
  echo "Travis CI secure environment variables are unavailable, will not deploy to ${deploy_repo}:${deploy_branch}."
elif test ! -e travis-deploy-key-id_rsa.enc; then
  echo "travis-deploy-key-id_rsa.enc not present, will not deploy to ${deploy_repo}:${deploy_branch}."
else
  set -x
  echo "Automatic push to ${deploy_repo}:${deploy_branch}"

  # Git configuration:
  git config --global user.name "$(git log --format="%aN" HEAD -1) (Travis CI automatic commit)"
  git config --global user.email "$(git log --format="%aE" HEAD -1)"

  # SSH configuration
  mkdir -p ~/.ssh
  chmod 700 ~/.ssh
  set +x
  if openssl aes-256-cbc -K "$key" -iv "$iv" -in travis-deploy-key-id_rsa.enc -out travis-deploy-key-id_rsa -d >/dev/null 2>&1; then
    echo "Decrypted key successfully."
  else
    echo "Error while decrypting key."
    exit 1
  fi
  mv travis-deploy-key-id_rsa ~/.ssh/travis-deploy-key-id_rsa
  set -x
  chmod 600 ~/.ssh/travis-deploy-key-id_rsa
  set +x
  eval `ssh-agent -s`
  set -x
  ssh-add ~/.ssh/travis-deploy-key-id_rsa

  TRAVIS_GH_PAGES_DIR="$HOME/travis-temp-auto-push-$(date +%s)"
  if test -e "$TRAVIS_GH_PAGES_DIR"; then rm -rf "$TRAVIS_GH_PAGES_DIR"; fi
  git clone -b "$deploy_base_commit" --depth 1 --shallow-submodules "$TRAVIS_GH_PAGES_DIR"
  (cd "$TRAVIS_GH_PAGES_DIR" && git checkout -b "$deploy_branch")
  rsync "${deploy_directory}/" "${TRAVIS_GH_PAGES_DIR}/"
  (cd "$TRAVIS_GH_PAGES_DIR" && git add -A . && git commit -m "Auto-publish to $deploy_branch") > commit.log || (cat commit.log && exit 1)
  (cd "$TRAVIS_GH_PAGES_DIR" && git log --oneline --decorate --graph -10)
  echo '(cd '"$TRAVIS_GH_PAGES_DIR"' && git push --force --quiet "'"$deploy_repo"'" "master:'"$deploy_branch"'")'
  (cd "$TRAVIS_GH_PAGES_DIR" && git push --force --quiet "$deploy_repo" "$deploy_branch" >/dev/null 2>&1) >/dev/null 2>&1 # redirect to /dev/null to avoid showing credentials.
fi

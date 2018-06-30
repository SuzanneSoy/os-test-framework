#!/bin/sh
set -e
set +x

usage() {
  echo "Usage: $0 built-repo-url deploy-repo-url"
  echo " - The first argument must be the URL for the repository being built"
  echo "   with Travis-Ci, e.g."
  echo "       git@github.com:built-user/built-repo.git"
  echo " - The second argument must be the URL for the repository to which the"
  echo "   artifacts will be pushed, e.g."
  echo "       git@github.com:deploy-user/deploy-repo.git"
  echo ""
  echo " It is preferable to create a repository specifically for hosting the"
  echo " artifacts, so that if the private key is accidentally leaked, only"
  echo " that repository will be affected."
  echo ""
  echo " Furthermore, it is preferable to only push non-executable artifacts"
  echo " (e.g. screenshots), so that if the repository is compromised, an"
  echo " attacker may not inject malicious code into what people may consider"
  echo " trusted artifacts."
}

if test "$#" -eq 1 && test "$1" = "-h" -o "$1" = "--help"; then
  usage
  exit 0
elif test "$#" -ne 2; then
  usage
  exit 1
fi

built_repo="$1" # git@github.com:built-user/built-repo.git
deploy_repo="$2" # git@github.com:deploy-user/deploy-repo.git

if ! which travis > /dev/null; then
  gem install travis || echo "Notice: you need the following packages or their equivalent: ruby ruby-dev"
fi

ssh_dir="$(mktemp -d --suffix=travis-deploy-ssh-keygen)"
mkdir -m 700 "${ssh_dir}/permissions/"
ssh-keygen -N '' -f "${ssh_dir}/permissions/id_rsa"

if test "$(git remote get-url origin)" != "${built_repo}"; then
    echo "ERROR: The url of the remote \"origin\" in the current repository is"
    echo "not the same as the one of the built repository specified on the"
    echo "command-line."
    echo "origin url:                  $(git remote get-url origin)"
    echo "command-line built-repo-url: $built_repo"
  exit 1
fi

travis login
travis encrypt-file "${ssh_dir}/permissions/id_rsa.pub"
git add "id_rsa.pub.enc"

printf "\033[1;32mNow copy the following public SSH key and add it as a\033[m\n"
printf "\033[1;32mread-write deploy key for the repository \033[1;33m${deploy_repo}\033[1;32m on GitHub.\033[m\n"
cat "${ssh_dir}/permissions/id_rsa.pub"
rm -fr "${ssh_dir}"

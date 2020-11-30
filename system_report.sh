#!/bin/bash
set -e

if [[ "${IS_IGNORE_ERRORS}" == "true" ]] ; then
echo " (i) Ignore Errors: enabled"
set +e
else
echo " (i) Ignore Errors: disabled"
fi

function dpkgVersion() {
  if [[ $# -eq 0 ]] ; then
    echo 'dpkgVersion: Package arg is required'
    exit 1
  fi

  ver_line="$(dpkg -s $1 | sed -n 's/Version: \(.*\)/\1/p')" ;
  echo "* $1: $ver_line"
}

echo
echo '#'
echo '# This System Report was generated by: https://github.com/bitrise-docker/bitrise-base/blob/master/system_report.sh'
echo '#  Pull Requests are welcome!'
echo '#'
echo

echo
echo "=== Revision / ID ======================"
echo "* BITRISE_DOCKER_REV_NUMBER_BASE: $BITRISE_DOCKER_REV_NUMBER_BASE"
echo "========================================"
echo

echo
echo "=== Pre-installed lib versions ========"
dpkgVersion zlib1g-dev
dpkgVersion libssl-dev
dpkgVersion libreadline6-dev
dpkgVersion libyaml-dev
dpkgVersion libsqlite3-dev
echo "======================================="
echo

# Make sure that the reported version is only
#  a single line!
echo
echo "=== Pre-installed tool versions ========"

ver_line="$(go version)" ;                        echo "* Go: $ver_line"
ver_line="$(ruby --version)" ;                    echo "* Ruby: $ver_line"
ver_line="$(bundle --version)" ;                  echo "  * bundler: $ver_line"
ver_line="$(gem --version)" ;                     echo "  * rubygems: $ver_line"
ver_line="$(python --version 2>&1 >/dev/null)" ;  echo "* Python: $ver_line"
ver_line="$(pip --version)" ;                     echo "  * pip: $ver_line"
ver_line="$(node --version)" ;                    echo "* Node.js: $ver_line"
ver_line="$(npm --version)" ;                     echo "* NPM: $ver_line"
ver_line="$(yarn --version)" ;                    echo "* Yarn: $ver_line"
ver_line="$(aws --version)" ;                     echo "* aws: $ver_line"
ver_line="$(jq --version)" ;                 echo "* jq: $ver_line"

echo
ver_line="$(git --version)" ;                     echo "* git: $ver_line"
ver_line="$(git lfs version)" ;                   echo "* git lfs: $ver_line"
ver_line="$(hg --version | grep version)" ;       echo "* mercurial/hg: $ver_line"
ver_line="$(curl --version | grep curl)" ;        echo "* curl: $ver_line"
ver_line="$(wget --version | grep 'GNU Wget')" ;  echo "* wget: $ver_line"
ver_line="$(rsync --version | grep version)" ;    echo "* rsync: $ver_line"
ver_line="$(unzip -v | head -n 1)" ;              echo "* unzip: $ver_line"
ver_line="$(zip -v | head -n 2 | tail -n 1)";     echo "* zip: $ver_line"
ver_line="$(tar --version | head -n 1)" ;         echo "* tar: $ver_line"
ver_line="$(tree --version)" ;                    echo "* tree: $ver_line"
ver_line="$(gcc --version | head -n 1)" ;         echo "* gcc: $ver_line"
ver_line="$(clang --version | head -n 1)" ;       echo "* clang: $ver_line"
ver_line="$(convert --version | head -1)" ;       echo "* imagemagick (convert): $ver_line"

echo
ver_line="$(sudo --version 2>&1 | grep 'Sudo version')" ; echo "* sudo: $ver_line"

echo
ver_line="$(docker --version)" ;                  echo "* docker: $ver_line"
ver_line="$(docker-compose --version)" ;          echo "* docker-compose: $ver_line"

echo
echo "--- Bitrise CLI tool versions"
ver_line="$(bitrise --version)" ;                 echo "* bitrise: $ver_line"
ver_line="$(/root/.bitrise/tools/stepman --version)" ; echo "* stepman: $ver_line"
ver_line="$(/root/.bitrise/tools/envman --version)" ;  echo "* envman: $ver_line"

if [[ "$CI" == "false" ]] ; then
set +e
fi
ver_line="$(bitrise-bridge --version || echo 'No bitrise-bridge installed')" ;          echo "* bitrise-bridge: $ver_line"
set -e
echo "========================================"
echo

echo
echo "=== All Ruby GEMs ======================"
gem list
echo "========================================"
echo

echo
echo "=== Linux info ========================="
echo "* uname -a"
uname -a
echo "* uname -r"
uname -r
echo "* lsb_release --all"
lsb_release --all
echo "========================================"
echo

echo
echo "=== Docker info ========================"
docker info
echo "========================================"
echo

echo
echo "=== Docker pre-cached images ==========="
docker images --format '{{ .Repository }} - {{ .Size }}'
echo "========================================"
echo

echo
echo "=== System infos ======================="
echo "* Free disk space under / :"
df -kh /
echo "* Free disk space under /bitrise/ :"
df -kh /bitrise/src
echo "* Free RAM & swap:"
free -mh
echo "========================================"
echo

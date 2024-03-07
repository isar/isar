#!/bin/bash

# Publishes the packages for a release to isar-community.dev using the artifacts from github
# Prerequisite: unpub authenticated and token added:
# `unpub_auth login && unpub_auth get | dart pub token add https://isar-community.dev/`
#

set -o errexit
if [ "$TAG" == "" ]; then
  echo "Define TAG to use"
  exit 1
fi
find . -type f -exec sed -i "s/0.0.0-placeholder/$TAG/g" {} +
pushd packages/isar
dart pub get
popd
sh tool/download_binaries.sh
#dart pub token add --env-var=PUB_JSON https://isar-community.dev/
pushd packages/isar
dart pub publish --force
popd
pushd packages/isar_flutter_libs
dart pub publish --force
popd


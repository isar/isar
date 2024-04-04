#!/bin/bash

# Publishes the packages for a release to isar-community.dev using the artifacts from github
# Prerequisite: unpub authenticated and token added:
# `unpub_auth login && unpub_auth get | dart pub token add https://pub.isar-community.dev/`
#

set -o errexit
. ./replace-versions.sh
pushd packages/isar
dart pub get
popd
sh tool/download_binaries.sh
#dart pub token add --env-var=PUB_JSON https://pub.isar-community.dev/
pushd packages/isar
dart pub publish --force
popd
pushd packages/isar_flutter_libs
dart pub publish --force
popd


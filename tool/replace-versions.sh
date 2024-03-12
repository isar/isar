#!/bin/bash
# This script replaces the version placeholder with the latest tag version on this branch
if [ "$ISAR_VERSION" == "" ]; then
  export ISAR_VERSION=`git describe --tags --abbrev=0`
  echo "ISAR_VERSION not defined in environment, using $ISAR_VERSION"
fi
find packages -type f -exec sed -i "s/0.0.0-placeholder/$ISAR_VERSION/g" {} +
find docs -type f -exec sed -i "s/0.0.0-placeholder/$ISAR_VERSION/g" {} +

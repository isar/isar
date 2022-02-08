#!/bin/sh

rm -r build-dir
cp ../../../../.github/assets/isar.svg icon.svg
flatpak-builder build-dir dev.isar.IsarInspector.yml && \
flatpak build-export repo build-dir && \
flatpak build-bundle repo app.flatpak dev.isar.IsarInspector

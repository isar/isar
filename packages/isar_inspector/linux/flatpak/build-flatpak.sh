#!/bin/sh

flatpak install flathub org.freedesktop.Platform//21.08 org.freedesktop.Sdk//21.08

rm -r build-dir
cp ../../../../.github/assets/isar.svg icon.svg
flatpak-builder build-dir dev.isar.IsarInspector.yml && \
flatpak build-export repo build-dir && \
flatpak build-bundle repo app.flatpak dev.isar.IsarInspector

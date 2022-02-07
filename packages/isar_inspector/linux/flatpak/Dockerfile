
FROM fedora:latest
MAINTAINER Lucian I. Last <li@last.nl>

RUN dnf -y update && \
    dnf install -y flatpak-builder ostree fuse elfutils dconf git bzr tar && \
    dnf clean all

RUN flatpak remote-add flathub https://flathub.org/repo/flathub.flatpakrepo

RUN flatpak install -y flathub org.freedesktop.Platform//21.08 org.freedesktop.Sdk//21.08

WORKDIR /

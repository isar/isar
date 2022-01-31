FROM ubuntu:20.04
# https://askubuntu.com/questions/1390058/docker-build-tzdata
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get -y install python3 python3-setuptools python3-pip wget fakeroot gnupg2 libglib2.0-bin file desktop-file-utils libgdk-pixbuf2.0-dev librsvg2-dev libyaml-dev zsync gtk-update-icon-cache strace elfutils musl musl-dev musl-tools

# https://github.com/AppImageCrafters/appimage-builder/pull/179
RUN wget https://github.com/AppImage/AppImageKit/releases/download/13/appimagetool-x86_64.AppImage -O /opt/appimagetool \
    && chmod +x /opt/appimagetool \
    && cd /opt/; sed -i 's|AI\x02|\x00\x00\x00|' appimagetool; /opt/appimagetool --appimage-extract \ 
    && mv /opt/squashfs-root /opt/appimagetool.AppDir \
    && ln -s /opt/appimagetool.AppDir/AppRun /usr/local/bin/appimagetool

WORKDIR /

RUN pip3 install appimage-builder

RUN apt-get -y autoclean

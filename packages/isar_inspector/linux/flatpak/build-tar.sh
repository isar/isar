#!/bin/sh

cd ../../build/linux/x64/release/bundle/
tar -czvf bundle.tar.gz ./*
cd ../../../../../linux/flatpak/

mv ../../build/linux/x64/release/bundle/bundle.tar.gz ./

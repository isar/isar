#!/bin/sh

pushd ../../build/linux/x64/release/bundle/
tar -czvf bundle.tar.gz ./*
popd

mv ../../build/linux/x64/release/bundle/bundle.tar.gz ./

#!/bin/bash

# Simple script to prepare for release

version="1.5.0-beta3";
build_d="../release";

hg archive -t tgz $build_d/ledgersmb-${version}.tar.gz


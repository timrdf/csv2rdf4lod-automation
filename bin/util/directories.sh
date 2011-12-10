#!/bin/bash

find . -maxdepth ${1:-"1"} -type d -not -name "\.*" | sed 's/^\..//'

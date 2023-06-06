#!/bin/bash

# Just a simple shell script to easily build for all platforms.

zig build -Doptimize=Debug -Dtarget=x86_64-linux-gnu
zig build -Doptimize=Debug -Dtarget=x86_64-macos
zig build -Doptimize=Debug -Dtarget=x86_64-windows

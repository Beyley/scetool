#!/bin/bash

build_for_platform() {
    local platform=$1
    local platform_name=$2
    local architectures=("${@:3}")

    echo "Building for $platform"
    for ((x=0; x<${#architectures[@]}; x++)); do
        local arch=${architectures[x]}
        local arch_name=${common_architecture_names[x]}

        echo "  $arch"
        zig build -Doptimize=ReleaseSmall -Dtarget=$arch-$platform

        mkdir -p "build/$platform_name-$arch_name/native"
        cp -r zig-out/lib/* "build/$platform_name-$arch_name/native"
        rm -rf build/$platform_name-$arch_name/native/scetool.lib
        rm -rf zig-out
    done

    echo "Done building for $platform."
}

common_architectures=("x86_64" "aarch64")
common_architecture_names=("x64" "arm64")
platforms=("linux-gnu.2.13" "macos" "windows")
platform_names=("linux" "osx" "win")

for ((i=0; i<${#platforms[@]}; i++)); do
    platform=${platforms[i]}
    platform_name=${platform_names[i]}
    build_for_platform "$platform" "$platform_name" "${common_architectures[@]}"
done

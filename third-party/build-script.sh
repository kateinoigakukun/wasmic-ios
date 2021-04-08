#!/bin/bash

set -eu

third_party_dir="$(cd "$(dirname "$0")" && pwd)"

build_wasm3() {
    CMAKE_ARGS=(
        -G Ninja
        -S "$third_party_dir/wasm3"
        -D CMAKE_TOOLCHAIN_FILE="$third_party_dir/ios-cmake/ios.toolchain.cmake"
        -D BUILD_NATIVE=OFF
        -D DEPLOYMENT_TARGET="14.0"
        -D ENABLE_BITCODE=ON
    )
    CMAKE_BUILD_ARGS=(--target m3 --config Release)

    cmake "${CMAKE_ARGS[@]}" \
        -B "$third_party_dir/build/wasm3-iphoneos-arm64" \
        -D PLATFORM=OS64
    cmake --build "$third_party_dir/build/wasm3-iphoneos-arm64" "${CMAKE_BUILD_ARGS[@]}"

    cmake "${CMAKE_ARGS[@]}" \
        -B "$third_party_dir/build/wasm3-iphonesimulator-x86_64" \
        -D PLATFORM=SIMULATOR64
    cmake --build "$third_party_dir/build/wasm3-iphonesimulator-x86_64" "${CMAKE_BUILD_ARGS[@]}"

    headers_dir="$third_party_dir/build/wasm3-headers"
    mkdir -p "$headers_dir"
    # shellcheck disable=SC2046
    cp $(find "$third_party_dir/wasm3/source" -name "*.h" -depth 1) "$headers_dir"
    cat <<EOS > "$headers_dir/module.modulemap"
module wasm3 {
    header "wasm3.h"
    export *
}
EOS

    rm -rf "$third_party_dir/build/wasm3.xcframework"
    xcodebuild -create-xcframework \
        -library "$third_party_dir/build/wasm3-iphoneos-arm64/source/libm3.a" \
        -headers "$headers_dir" \
        -library "$third_party_dir/build/wasm3-iphonesimulator-x86_64/source/libm3.a" \
        -headers "$headers_dir" \
        -output "$third_party_dir/build/wasm3.xcframework"
}

build_wasm3

#!/bin/bash

set -eu

CMAKE_BUILD_TYPE=Release

while [ $# -ne 0 ]; do
  case "$1" in
    --debug)
    CMAKE_BUILD_TYPE=Debug
  ;;
  *)
    echo "Unrecognised argument \"$1\""
    exit 1
  ;;
  esac
  shift
done

third_party_dir="$(cd "$(dirname "$0")" && pwd)"

build_wasm3() {
    CMAKE_ARGS=(
        -G Ninja
        -S "$third_party_dir/wasm3-build"
        -D CMAKE_TOOLCHAIN_FILE="$third_party_dir/ios-cmake/ios.toolchain.cmake"
        -D DEPLOYMENT_TARGET="14.0"
        -D ENABLE_BITCODE=ON
        -D CMAKE_BUILD_TYPE="$CMAKE_BUILD_TYPE"
    )
    CMAKE_BUILD_ARGS=(--target wasm3.framework --config "$CMAKE_BUILD_TYPE")

    cmake "${CMAKE_ARGS[@]}" \
        -B "$third_party_dir/build/wasm3-iphoneos-arm64" \
        -D PLATFORM=OS64
    cmake --build "$third_party_dir/build/wasm3-iphoneos-arm64" "${CMAKE_BUILD_ARGS[@]}"

    cmake "${CMAKE_ARGS[@]}" \
        -B "$third_party_dir/build/wasm3-iphonesimulator-x86_64" \
        -D PLATFORM=SIMULATOR64
    cmake --build "$third_party_dir/build/wasm3-iphonesimulator-x86_64" "${CMAKE_BUILD_ARGS[@]}"

    rm -rf "$third_party_dir/build/wasm3_impl.xcframework"
    xcodebuild -create-xcframework \
        -framework "$third_party_dir/build/wasm3-iphoneos-arm64/wasm3_impl.framework" \
        -framework "$third_party_dir/build/wasm3-iphonesimulator-x86_64/wasm3_impl.framework" \
        -output "$third_party_dir/build/wasm3_impl.xcframework"

    rm -rf "$third_party_dir/build/wasm3.xcframework"
    xcodebuild -create-xcframework \
        -library "$third_party_dir/build/wasm3-iphoneos-arm64/libwasm3.a" \
        -headers "$third_party_dir/build/wasm3-iphoneos-arm64/wasm3-headers" \
        -library "$third_party_dir/build/wasm3-iphonesimulator-x86_64/libwasm3.a" \
        -headers "$third_party_dir/build/wasm3-iphonesimulator-x86_64/wasm3-headers" \
        -output "$third_party_dir/build/wasm3.xcframework"
}

build_wabt() {
    CMAKE_ARGS=(
        -G Ninja
        -S "$third_party_dir/wabt-c-api"
        -D CMAKE_TOOLCHAIN_FILE="$third_party_dir/ios-cmake/ios.toolchain.cmake"
        -D DEPLOYMENT_TARGET="14.0"
        -D ENABLE_BITCODE=ON
        -D CMAKE_BUILD_TYPE="$CMAKE_BUILD_TYPE"
    )
    CMAKE_BUILD_ARGS=(--target wabt.framework --config "$CMAKE_BUILD_TYPE")

    cmake "${CMAKE_ARGS[@]}" \
        -B "$third_party_dir/build/wabt-c-api-iphoneos-arm64" \
        -D PLATFORM=OS64
    cmake --build "$third_party_dir/build/wabt-c-api-iphoneos-arm64" "${CMAKE_BUILD_ARGS[@]}"

    cmake "${CMAKE_ARGS[@]}" \
        -B "$third_party_dir/build/wabt-c-api-iphonesimulator-x86_64" \
        -D PLATFORM=SIMULATOR64
    cmake --build "$third_party_dir/build/wabt-c-api-iphonesimulator-x86_64" "${CMAKE_BUILD_ARGS[@]}"

    rm -rf "$third_party_dir/build/wabt.xcframework"

    xcodebuild -create-xcframework \
        -framework "$third_party_dir/build/wabt-c-api-iphoneos-arm64/wabt.framework" \
        -framework "$third_party_dir/build/wabt-c-api-iphonesimulator-x86_64/wabt.framework" \
        -output "$third_party_dir/build/wabt.xcframework"
}

build_wasm3
build_wabt

#!/bin/bash

set -eu

root_dir="$(cd "$(dirname "$0")/.." && pwd)"

swift-format format --recursive --in-place \
    --configuration "$root_dir/.swift-format" \
    "$root_dir/Sources" \
    "$root_dir/Tests"

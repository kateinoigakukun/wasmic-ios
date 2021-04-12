#!/bin/bash

set -eu

root_dir="$(cd "$(dirname "$0")/.." && pwd)"

license-plist --output-path "$root_dir/Sources/iOS/Settings.bundle"

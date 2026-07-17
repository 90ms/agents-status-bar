#!/bin/zsh
set -euo pipefail

script_dir=${0:A:h}
project_dir=${script_dir:h}
output_dir="$project_dir/dist"
app_dir="$output_dir/Agents Status Bar.app"
contents_dir="$app_dir/Contents"

swift build --package-path "$project_dir" -c release --product AgentsStatusBar
binary_dir=$(swift build --package-path "$project_dir" -c release --show-bin-path)

if [[ "$app_dir" != "$project_dir"/dist/* ]]; then
    print -u2 "Unexpected app output path: $app_dir"
    exit 1
fi

rm -rf "$app_dir"
mkdir -p "$contents_dir/MacOS" "$contents_dir/Resources"
cp "$binary_dir/AgentsStatusBar" "$contents_dir/MacOS/AgentsStatusBar"
cp "$project_dir/packaging/Info.plist" "$contents_dir/Info.plist"

signing_identity=${APP_SIGN_IDENTITY:--}
codesign --force --options runtime --sign "$signing_identity" "$app_dir"
codesign --verify --deep --strict "$app_dir"

print "$app_dir"

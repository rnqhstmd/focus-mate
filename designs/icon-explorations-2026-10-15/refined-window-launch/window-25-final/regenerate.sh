#!/bin/zsh
set -eu
OUT="${0:A:h}"
NODE=/Users/bonseung/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node
PYTHON=/Users/bonseung/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3
SDK=$(xcrun --sdk macosx --show-sdk-path)
"$NODE" "$OUT/render.cjs"
xcrun swiftc -suppress-warnings -target arm64-apple-macosx15.0 -sdk "$SDK" "$OUT/encode.swift" -o "$OUT/encode"
"$OUT/encode" "$OUT"
xcrun swiftc -suppress-warnings -target arm64-apple-macosx15.0 -sdk "$SDK" "$OUT/verify.swift" -o "$OUT/verify"
"$OUT/verify" "$OUT"
"$PYTHON" "$OUT/make-gif.py"
# Only intermediates created by the scripts above are removed.
rm -f "$OUT/encode" "$OUT/verify"
rm -rf "$OUT/frames"

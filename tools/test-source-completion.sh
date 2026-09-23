#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$(mktemp -d)"
trap 'rm -rf -- "$OUT"' EXIT

for test in chatter-grounding human-navigator; do
    "${CXX:-g++}" -std=c++20 -Wall -Wextra -Werror \
        "$ROOT/tools/tests/$test.cpp" -o "$OUT/$test"
    "$OUT/$test"
    echo "PASS: $test"
done

python3 "$ROOT/tools/tests/runtime-hardening.py"
python3 "$ROOT/tools/tests/era-world-containment.py"

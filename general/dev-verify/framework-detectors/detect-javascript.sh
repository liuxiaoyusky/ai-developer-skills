#!/bin/bash
# detect-javascript.sh - Detect JavaScript/TypeScript testing framework
# Outputs: "jest", "vitest", "mocha", "npm-test", or "unknown"

detect_js_framework() {
    # Check if package.json exists
    if [ ! -f "package.json" ]; then
        echo "unknown"
        return 1
    fi

    # Check for jest (most common)
    if grep -q '"jest"' package.json 2>/dev/null; then
        echo "jest"
        return 0
    fi

    # Check for vitest
    if grep -q '"vitest"' package.json 2>/dev/null; then
        echo "vitest"
        return 0
    fi

    # Check for mocha
    if grep -q '"mocha"' package.json 2>/dev/null; then
        echo "mocha"
        return 0
    fi

    # Check for jasmine
    if grep -q '"jasmine"' package.json 2>/dev/null; then
        echo "jasmine"
        return 0
    fi

    # Check for ava
    if grep -q '"ava"' package.json 2>/dev/null; then
        echo "ava"
        return 0
    fi

    # Check for tape
    if grep -q '"tape"' package.json 2>/dev/null; then
        echo "tape"
        return 0
    fi

    # Check if test script exists (generic npm test)
    if grep -q '"test"\s*:' package.json 2>/dev/null; then
        echo "npm-test"
        return 0
    fi

    # No JavaScript testing framework detected
    echo "unknown"
    return 1
}

detect_js_framework

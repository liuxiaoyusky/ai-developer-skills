#!/bin/bash
# detect-go.sh - Detect Go testing
# Outputs: "go-test" or "unknown"

detect_go_testing() {
    # Check for Go test files (convention: *_test.go)
    if find . -name "*_test.go" 2>/dev/null | grep -q .; then
        echo "go-test"
        return 0
    fi

    # Check if it's a Go module
    if [ -f "go.mod" ]; then
        # Even if no test files yet, it's a Go project
        echo "go-test"
        return 0
    fi

    # No Go testing detected
    echo "unknown"
    return 1
}

detect_go_testing

#!/bin/bash
# detect-python.sh - Detect Python testing framework
# Outputs: "pytest", "unittest", "tox", or "unknown"

detect_python_framework() {
    # Check for pytest (most common)
    if [ -f "pytest.ini" ]; then
        echo "pytest"
        return 0
    fi

    if [ -f "pyproject.toml" ] && grep -q "pytest" pyproject.toml 2>/dev/null; then
        echo "pytest"
        return 0
    fi

    if [ -f "setup.py" ] && grep -q "pytest" setup.py 2>/dev/null; then
        echo "pytest"
        return 0
    fi

    if [ -f "requirements.txt" ] && grep -q "pytest" requirements.txt 2>/dev/null; then
        echo "pytest"
        return 0
    fi

    if [ -f "setup.cfg" ] && grep -q "pytest" setup.cfg 2>/dev/null; then
        echo "pytest"
        return 0
    fi

    # Check for tox
    if [ -f "tox.ini" ]; then
        echo "tox"
        return 0
    fi

    # Check for test files (convention-based detection)
    if find . -name "test_*.py" -o -name "*_test.py" 2>/dev/null | grep -q .; then
        # Default to pytest if test files exist but no config found
        echo "pytest"
        return 0
    fi

    # Check for unittest (standard library)
    if find . -name "test*.py" 2>/dev/null | xargs grep -l "import unittest\|from unittest" 2>/dev/null | grep -q .; then
        echo "unittest"
        return 0
    fi

    # No Python testing framework detected
    echo "unknown"
    return 1
}

detect_python_framework

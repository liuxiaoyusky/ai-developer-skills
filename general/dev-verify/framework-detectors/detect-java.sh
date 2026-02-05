#!/bin/bash
# detect-java.sh - Detect Java testing framework
# Outputs: "junit", "mvn-test", "gradle-test", or "unknown"

detect_java_framework() {
    # Check for test files (convention: *Test.java)
    if ! find . -name "*Test.java" 2>/dev/null | grep -q .; then
        echo "unknown"
        return 1
    fi

    # Check for Maven (pom.xml)
    if [ -f "pom.xml" ]; then
        echo "mvn-test"
        return 0
    fi

    # Check for Gradle (build.gradle or build.gradle.kts)
    if [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
        echo "gradle-test"
        return 0
    fi

    # Check for JUnit directly
    if find . -name "*Test.java" 2>/dev/null | xargs grep -l "import org.junit" 2>/dev/null | grep -q .; then
        echo "junit"
        return 0
    fi

    # Check for TestNG
    if find . -name "*Test.java" 2>/dev/null | xargs grep -l "import org.testng" 2>/dev/null | grep -q .; then
        echo "testng"
        return 0
    fi

    # Test files exist but framework unknown
    echo "junit"  # Default to JUnit
    return 0
}

detect_java_framework

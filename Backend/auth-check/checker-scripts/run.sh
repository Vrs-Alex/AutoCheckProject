#!/bin/bash
set -e

CHECKER_TYPE="$1"
CODE_REL_PATH="$2"
CODE_PATH="/app/uploads/$CODE_REL_PATH"

case "$CHECKER_TYPE" in
    STATIC_ANALYSIS) SCRIPT="static_analysis.py" ;;
    ARCHITECTURE)    SCRIPT="architecture.py" ;;
    BUILD)           SCRIPT="build.py" ;;
    TESTS)           SCRIPT="tests.py" ;;
    DOCUMENTATION)   SCRIPT="documentation.py" ;;
    GIT_PRACTICES)   SCRIPT="git_practices.py" ;;
    *)
        echo '{"status":"error","score":null,"log":"Unknown checker type: '"$CHECKER_TYPE"'"}'
        exit 0
        ;;
esac

python3 "/checker-scripts/$SCRIPT" "$CODE_PATH"

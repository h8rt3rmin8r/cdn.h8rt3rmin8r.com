#!/usr/bin/env bash

# ==============================================================================
# Script Name   : tree-json.sh
# Description   : Wraps the 'tree' command to output a detailed JSON structure
#                 of a directory, including hidden files and sizes.
# Requirements  : 'tree' must be installed.
# ==============================================================================

# ------------------------------------------------------------------------------
# Safety & Configuration
# ------------------------------------------------------------------------------
# -e: Exit immediately if a command exits with a non-zero status.
# -u: Treat unset variables as an error.
# -o pipefail: Return value of a pipeline is the status of the last command
#              to exit with a non-zero status.
set -euo pipefail

# Default directory is the current working directory
TARGET_DIR="."

# ------------------------------------------------------------------------------
# Functions
# ------------------------------------------------------------------------------

print_usage() {
    cat <<EOF
Usage: $(basename "${0}") [OPTIONS]

Description:
    Generates a JSON representation of the file structure for a specified
    directory using the 'tree' command. It includes hidden files, calculates
    directory sizes, and outputs in human-readable units.

    The underlying command used is:
    tree -a -R -x --du -h -U -J \${directory}

Options:
    -d, --directory <path>  Specify the target directory to analyze.
                            (Defaults to current working directory: '.')
    -h, --help              Show this help message and exit.

Examples:
    $(basename "${0}")
    $(basename "${0}") --directory /var/www/html
    $(basename "${0}") -d ../project-files > output.json

Dependencies:
    Requires 'tree' to be installed and available in the system PATH.
EOF
}

check_dependency() {
    if ! command -v tree &> /dev/null; then
        echo "Error: Required command 'tree' is not installed or not in PATH." >&2
        echo "Please install it (e.g., 'sudo apt install tree' or 'brew install tree')." >&2
        exit 1
    fi
}

# ------------------------------------------------------------------------------
# Argument Parsing
# ------------------------------------------------------------------------------

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            print_usage
            exit 0
            ;;
        -d|--directory)
            if [[ -n "${2:-}" ]] && [[ ! "${2:-}" =~ ^- ]]; then
                TARGET_DIR="$2"
                shift 2
            else
                echo "Error: --directory argument requires a valid path value." >&2
                exit 1
            fi
            ;;
        *)
            echo "Error: Unknown option '$1'" >&2
            print_usage >&2
            exit 1
            ;;
    esac
done

# ------------------------------------------------------------------------------
# Execution
# ------------------------------------------------------------------------------

# Dependency check runs AFTER help processing to ensure help is always available
check_dependency

# Check if target directory exists
if [[ ! -d "${TARGET_DIR}" ]]; then
    echo "Error: Directory '${TARGET_DIR}' does not exist." >&2
    exit 1
fi

# Execute the tree command with the requested flags:
# -a    : All files (include hidden files)
# -R    : Recursively list subdirectories (standard behavior, explicitly requested)
# -x    : Stay on current filesystem (do not cross mount points)
# --du  : Print size of each directory (accumulated)
# -h    : Print size in human-readable format (e.g., 1K, 234M, 2G)
# -U    : Do not sort (lists files in directory order; faster)
# -J    : Print output in JSON format
tree -a -R -x --du -h -U -J "${TARGET_DIR}"

exit $?

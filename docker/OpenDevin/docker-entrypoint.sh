#!/bin/bash -i

shopt -s extglob
set -Eeo pipefail

CSCRIPT_PATH="$(dirname $0)"
ACTION=""
DEBUG=false
BARGS=()

# Function to print a debug message
function debug() {
    if [ "$DEBUG" = true ]; then
        local C_WHITE="\033[0;37m"
        local C_BOLD_WHITE="\033[1;37m"
        local C_RESET="\033[0m"
        echo -e "${C_BOLD_WHITE}DEBUG: ${C_RESET}${C_WHITE}$1${C_RESET}" >&2
    fi
}

# function to print a warning message
function warn() {
    local C_YELLOW="\033[0;33m"
    local C_BOLD_YELLOW="\033[1;33m"
    local C_RESET="\033[0m"
    echo -e "${C_BOLD_YELLOW}WARNING: ${C_RESET}${C_YELLOW}$1${C_RESET}" >&2
}

# function to print an error message
function err() {
    local C_RED="\033[0;31m"
    local C_BOLD_RED="\033[1;31m"
    local C_RESET="\033[0m"
    echo -e "${C_BOLD_RED}ERROR: ${C_RESET}${C_RED}$1${C_RESET}" >&2
}

# Function to print an info message
function info() {
    local C_BLUE="\033[0;34m"
    local C_BOLD_BLUE="\033[1;34m"
    local C_RESET="\033[0m"
    echo -e "${C_BOLD_BLUE}INFO: ${C_RESET}${C_BLUE}$1${C_RESET}"
}

# Function to print a success message
function success() {
    local C_GREEN="\033[0;32m"
    local C_BOLD_GREEN="\033[1;32m"
    local C_RESET="\033[0m"
    echo -e "${C_BOLD_GREEN}SUCCESS: ${C_RESET}${C_GREEN}$1${C_RESET}"
}

function _exit_trap() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        err "Error: Process exited with status code: $exit_code"
    fi
    cd "$CSCRIPT_PATH"
    exit $exit_code
}

trap _exit_trap EXIT SIGINT SIGTERM ERR

function __run() {
    debug "Running command: $*"
    eval "$*" || {
        return $?
    }
}

function usage() {
    local ACTION=$1
    echo "open-devin: OpenDevin is your superpowered AI coding assistant"
    echo "Usage: $0 <action> [options]"
    echo -e"\mGlobal Options:\m"
    echo ""
    echo "  --help: Show this help message, and exit"
    echo ""
    case "$ACTION" in
        build)
            echo "Arguments:"
            echo ""
            echo "  --help: Show this help message, and exit"
            echo ""
            ;;
        run)
            echo "Arguments:"
            echo ""
            echo "  Any arguments passed to this script will be passed to the application."
            echo ""
            ;;
        shell)
            echo "Arguments:"
            echo "  Any arguments passed to this script will be passed to the shell session."
            ;;
        *)
            echo "Actions:"
            echo ""
            echo "  run: Run the application"
            echo "  shell: Start a shell session in the container"
            echo ""
            ;;
    esac
    return 0
}

function parse_args() {
    local FARGS=($*)
    if [[ ${#FARGS[@]} -eq 0 ]]; then
        usage
    fi
    ACTION=${FARGS[0]}
    shift 1
    case "$ACTION" in
        build)
            BARGS=()
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --help)
                        usage build
                        ;;
                    *)
                        BARGS+=("$1")
                        shift 1
                        ;;
                esac
            done
            ;;
        run)
            BARGS=()
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --help)
                        usage run
                        ;;
                    *)
                        BARGS+=("$1")
                        shift 1
                        ;;
                esac
            done
            ;;
        shell)
            BARGS=()
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --help)
                        usage shell
                        ;;
                    *)
                        BARGS+=("$1")
                        shift 1
                        ;;
                esac
            done
            ;;
        *)
            usage
            ;;
    esac
}

function main() {
    case "$ACTION" in
        build)
            . $APP_USER_HOME/.bashrc
            __run cd ${APP_DIR}
            __run sudo chown $APP_USER:$APP_USER /var/run/docker.sock
            __run make build || true
            # cat ${APP_USER_HOME}/.cache/pre-commit/pre-commit.log
            ;;
        run)
            exec python3 -m opendevin ${BARGS[@]}
            ;;
        shell)
            exec /bin/bash ${BARGS[@]}
            ;;
        *)
            usage
            ;;
    esac
}

parse_args "$@"
main
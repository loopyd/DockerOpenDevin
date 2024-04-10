#!/bin/bash -i

shopt -s extglob
set -Eeo pipefail

CSCRIPT_PATH="$(dirname $0)"
ACTION=""
DEBUG=false
BARGS=()
WORKDIR="/app"

# Colors
C_DARK_WHITE="\033[0;30m"
C_WHITE="\033[0;37m";       C_YELLOW="\033[0;33m";
C_RED="\033[0;31m";         C_BLUE="\033[0;34m";            C_GREEN="\033[0;32m"
C_BOLD_WHITE="\033[1;37m";  C_BOLD_YELLOW="\033[1;33m";     C_BOLD_RED="\033[1;31m"
C_BOLD_BLUE="\033[1;34m";   C_BOLD_GREEN="\033[1;32m"
C_RESET="\033[0m"

# Function to print a debug message
function debug() {
    if [ "$DEBUG" = true ]; then
        echo -e "${C_DARK_WHITE}$(date +"%Y-%m-%d %H:%M:%S")${C_RESET} ${C_WHITE}[${C_RESET}${C_BOLD_WHITE}DEBUG   ${C_RESET}${C_WHITE}]${C_RESET} ${C_WHITE}$1${C_RESET}" >&2
    fi
}

# function to print a warning message
function warn() {
    echo -e "${C_DARK_WHITE}$(date +"%Y-%m-%d %H:%M:%S")${C_RESET} ${C_YELLOW}[${C_RESET}${C_BOLD_YELLOW}WARNING${C_RESET}${C_YELLOW}]${C_RESET} ${C_YELLOW}$1${C_RESET}" >&2
}

# function to print an error message
function err() {
    echo -e "${C_DARK_WHITE}$(date +"%Y-%m-%d %H:%M:%S")${C_RESET} ${C_RED}[${C_RESET}${C_BOLD_RED}ERROR  ${C_RESET}${C_RED}]${C_RESET} ${C_RED}$1${C_RESET}" >&2
}

# Function to print an info message
function info() {
    local C_RESET="\033[0m"
    echo -e "${C_DARK_WHITE}$(date +"%Y-%m-%d %H:%M:%S")${C_RESET} ${C_BLUE}[${C_RESET}${C_BOLD_BLUE}INFO   ${C_RESET}${C_BLUE}]${C_RESET} ${C_BLUE}$1${C_RESET}"
}

# Function to print a success message
function success() {
    local C_RESET="\033[0m"
    echo -e "${C_DARK_WHITE}$(date +"%Y-%m-%d %H:%M:%S")${C_RESET} ${C_GREEN}[${C_RESET}${C_BOLD_GREEN}SUCCESS${C_RESET}${C_GREEN}]${C_RESET} ${C_GREEN}$1${C_RESET}"
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
    echo -e "${C_BOLD_YELLOW}-----------------------------------------------------------------------------------${C_RESET}"
    echo -e "  ${C_BOLD_WHITE}OpenDevin${C_RESET} - Your superpowered AI coding assistant"
    echo -e "${C_BOLD_YELLOW}-----------------------------------------------------------------------------------${C_RESET}"
    echo ""
    echo -e "  ${C_BOLD_WHITE}Usage${C_RESET}"
    echo ""
    echo "    $0 <action> [options]"
    echo ""
    echo -e "  ${C_BOLD_WHITE}Global Options${C_RESET}"
    echo ""
    echo "    --help: Show this help message, and exit"
    echo "    --debug: Enable debug mode"
    echo ""
    case "$ACTION" in
        build)
            echo -e "  ${C_BOLD_WHITE}Options${C_RESET}"
            echo ""
            echo "    No options for this action."
            echo ""
            ;;
        run)
            echo -e "  ${C_BOLD_WHITE}Options${C_RESET}"
            echo ""
            echo "    No options for this action."
            echo ""
            ;;
        shell)
            echo -e "  ${C_BOLD_WHITE}Options${C_RESET}"
            echo ""
            echo "    -w, --workdir: The working directory to start the Shell session in."
            echo ""
            ;;
        *)
            echo -e "  ${C_BOLD_WHITE}Actions${C_RESET}"
            echo ""
            echo "    build: Build the Application"
            echo "    run: Run the Application"
            echo "    shell: Start a Shell session in the Container"
            echo ""
            ;;
    esac
    echo -e "  ${C_BOLD_WHITE}Additional Arguments${C_RESET}"
    echo ""
    echo "    Any additional arguments will be passed to the action command."
    echo ""
    echo "  For assistance with a specific action, use:"
    echo ""
    echo "    $0 <action> --help"
    echo ""
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
                    -h|--help)
                        usage build
                        ;;
                    *)
                        BARGS+=("$1")
                        shift 1
                        break
                        ;;
                esac
            done
            ;;
        run)
            BARGS=()
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    -h|--help)
                        usage run
                        ;;
                    *)
                        BARGS+=("$1")
                        shift 1
                        break
                        ;;
                esac
            done
            ;;
        shell)
            BARGS=()
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    -h|--help)
                        usage shell
                        ;;
                    -w|--workdir)
                        WORKDIR="$2"
                        shift 2
                        ;;
                    *)
                        BARGS+=("$1")
                        shift 1
                        break
                        ;;
                esac
            done
            ;;
        *)
            usage
            ;;
    esac
    # Add any remaining arguments to BARGS
    while [[ $# -gt 0 ]]; do
        BARGS+=("$1")
        shift 1
    done
}

function main() {
    case "$ACTION" in
        build)
            . $APP_USER_HOME/.bashrc
            __run cd ${APP_DIR} || {
                err "Failed to change the working directory to ${APP_DIR}"
                return 1
            }
            __run sudo chown $APP_USER:$APP_USER /var/run/docker.sock || {
                err "Failed to change the owner of /var/run/docker.sock"
                return 1
            }
            __run make build || {
                err "Failed to build the Application"
                return 1
            }
            ;;
        run)
            exec python3 -m opendevin ${BARGS[@]}
            ;;
        shell)
            exec /bin/bash -i -c ${BARGS[@]}
            ;;
        *)
            usage
            ;;
    esac
}

parse_args "$@"
main
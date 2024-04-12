#!/bin/bash

shopt -s extglob
set -Eeo pipefail

CSCRIPT_PATH="$(dirname $0)"
ACTION=""
SUBACTION=""
DEBUG=false
BARGS=()
WORKDIR=${WORKDIR:-"/app"}
SERVER_HOST=${SERVER_HOST:-"127.0.0.1"}
SERVER_PORT=${SERVER_PORT:-"3000"}

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
    else
        success "$0 exited successfully"
    fi
    cd "$CSCRIPT_PATH"
    exit $exit_code
}

trap _exit_trap EXIT SIGINT SIGTERM ERR

function __run() {
    if [ "$DEBUG" = true ]; then
        local _env_before
        _env_before=$(printenv | sort)
        debug "Running: $*"
        eval "$*" || {
            return $?
        }
        local _env_after
        _env_after=$(printenv | sort)
        local _env_diff
        _env_diff=$(diff <(echo "$_env_before") <(echo "$_env_after") | grep '^[<>]' | sed 's/^< //;s/^> //')
        if [[ -n "$_env_diff" ]]; then
            debug "Environment Changes: $_env_diff"
        fi
    else
        eval "$*" || {
            return $?
        }
    fi
}

function usage() {
    local MYACTION="$1"
    shift 1 || true
    local MYSUBACTION="$1"
    shift 1 || true
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
    case "$MYACTION" in
        build)
            echo -e "  ${C_BOLD_WHITE}Options${C_RESET}"
            echo ""
            echo "    No options for this action."
            echo ""
            ;;
        run)
            case "$MYSUBACTION" in
                frontend)
                    echo -e "  ${C_BOLD_WHITE}Options${C_RESET}"
                    echo ""
                    echo "    -x, --host: The host (name or IP address) to bind the frontend server to."
                    echo "    -p, --port: The port (0-65535) to bind the frontend server to."
                    echo ""
                    ;;
                backend)
                    echo -e "  ${C_BOLD_WHITE}Options${C_RESET}"
                    echo ""
                    echo "    -x, --host: The host (name or IP address) to bind the backend server to."
                    echo "    -p, --port: The port (0-65535) to bind the backend server to."
                    echo ""
                    ;;
                *)
                    echo -e "  ${C_BOLD_WHITE}Sub Actions${C_RESET}"
                    echo ""
                    echo "    frontend: Run the Frontend Application"
                    echo "    backend: Run the Backend Application"
                    echo ""
                    ;;
            esac
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
                    -d|--debug)
                        DEBUG=true
                        shift 1
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
            if [ $# -eq 0 ]; then
                usage run
            fi
            if [[ ! "$1" =~ ^frontend|backend ]]; then
                usage run
            else
                SUBACTION="$1"
                shift 1
            fi
            case "$SUBACTION" in
                frontend)
                    BARGS=()
                    while [[ $# -gt 0 ]]; do
                        case "$1" in
                            -h|--help)
                                usage run frontend
                                ;;
                            -x|--host)
                                SERVER_HOST="$2"
                                shift 2
                                ;;
                            -p|--port)
                                SERVER_PORT="$2"
                                if [[ ! "$SERVER_PORT" =~ ^[0-9]+$ ]]; then
                                    err "Invalid port number: $SERVER_PORT"
                                    usage run frontend
                                fi
                                shift 2
                                ;;
                            -d|--debug)
                                DEBUG=true
                                shift 1
                                ;;
                            *)
                                BARGS+=("$1")
                                shift 1
                                break
                                ;;
                        esac
                    done
                    if [[ ! "$SERVER_HOST" =~ : ]]; then
                        SERVER_HOST="${SERVER_HOST}:${SERVER_PORT}"
                    fi
                    ;;
                backend)
                    BARGS=()
                    while [[ $# -gt 0 ]]; do
                        case "$1" in
                            -h|--help)
                                usage run backend
                                ;;
                            -x|--host)
                                SERVER_HOST="$2"
                                shift 2
                                ;;
                            -p|--port)
                                SERVER_PORT="$2"
                                if [[ ! "$SERVER_PORT" =~ ^[0-9]+$ ]]; then
                                    err "Invalid port number: $SERVER_PORT"
                                    usage run frontend
                                fi
                                shift 2
                                ;;
                            -d|--debug)
                                DEBUG=true
                                shift 1
                                ;;
                            *)
                                BARGS+=("$1")
                                shift 1
                                break
                                ;;
                        esac
                    done
                    if [[ ! "$SERVER_HOST" =~ : ]]; then
                        SERVER_HOST="${SERVER_HOST}:${SERVER_PORT}"
                    fi
                    ;;
                *)
                    usage run
                    ;;
            esac
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
                    -d|--debug)
                        DEBUG=true
                        shift 1
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
            __run cd ${APP_DIR} || {
                err "Failed to change the working directory to ${APP_DIR}"
                return 1
            }
            __run sudo chown $APP_USER:$APP_USER /var/run/docker.sock || {
                err "Failed to change the owner of /var/run/docker.sock"
                return 1
            }
            __run nvm use default || {
                err "Failed to use the default Node.js version"
                return 1
            }
            __run make build || {
                err "Failed to build the Application"
                return 1
            }
            success "Successfully built the Application"
            return 0
            ;;
        run)
            case "$SUBACTION" in
                frontend)
                    __run cd ${APP_DIR} || {
                        err "Failed to change the working directory to ${APP_DIR}"
                        return 1
                    }
                    __run nvm use default || {
                        err "Failed to use the default Node.js version"
                        return 1
                    }
                    __run make build || {
                        err "Failed to build the Application"
                        return 1
                    }
                    __run cd ${APP_DIR}/frontend || {
                        err "Failed to change the working directory to ${APP_DIR}/frontend"
                        return 1
                    }
                    __run BACKEND_HOST=${SERVER_HOST} FRONTEND_PORT=${SERVER_PORT} npm run start -- --host || {
                        err "Failed to run the Frontend Application"
                        return 1
                    }
                    ;;
                backend)
                    __run cd ${APP_DIR} || {
                        err "Failed to change the working directory to ${APP_DIR}"
                        return 1
                    }
                    __run nvm use default || {
                        err "Failed to use the default Node.js version"
                        return 1
                    }
                    __run make build || {
                        err "Failed to build the Application"
                        return 1
                    }
                    __run poetry run uvicorn opendevin.server.listen:app --port ${SERVER_PORT} || {
                        err "Failed to run the Backend Application"
                        return 1
                    }
                    ;;
                *)
                    usage run
                    ;;
            esac
            ;;
        shell)
            exec /bin/bash -i ${BARGS[@]}
            ;;
        *)
            usage
            ;;
    esac
}

if [[ $(id -un) != "$APP_USER" || $- != *i* ]]; then
    warn "Switching to ${APP_USER}'s environment"
    sudo -EH -u $APP_USER /bin/bash -i "$0" "$@" || true
else
    debug "Running as Application user: $USER"
    if [ -s ${APP_USER_HOME}/.bashrc ]; then
        . ${APP_USER_HOME}/.bashrc
        debug "Sourced the .bashrc file"
    fi
    parse_args "$@"
    main 
fi
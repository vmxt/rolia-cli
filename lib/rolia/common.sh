
usage() {
    cat <<EOF
Usage:
  $0                         Prompt for a manga title and select a result
  $0 <query>                 Search titles directly, e.g. $0 one piece
  $0 search [query]          Search titles interactively or with a query
  $0 init                    Check dependencies and create application folders
  $0 browse [library-folder]
  $0 read <chapter-folder>

The default library folder is: $DEFAULT_LIBRARY
PDF downloads folder: $APP_DATA/downloads
Reading extracts the selected chapter pages into a temporary PDF and opens it.
Reader menu: Next, Previous, Select chapter, Download chapter, Quit.
Temporary PDFs are removed automatically after the viewer closes.
The chapter menu stays available while the PDF is open; automatic cleanup requires lsof.
Set ROLIA_CLI_PDF_VIEWER to choose a PDF viewer command.
Existing MAN_CLI_* environment variables remain supported.
Source URL: $SOURCE_BASE_URL
EOF
}

clear_terminal() {
    if [ -t 1 ] && [ "${TERM:-dumb}" != dumb ]; then
        printf '\033[3J\033[H\033[2J'
    fi
}

message_info() {
    message_color='\033[1;36m'
    message_stream=1
    message_print "$@"
}

message_success() {
    message_color='\033[1;32m'
    message_stream=1
    message_print "$@"
}

message_warning() {
    message_color='\033[1;33m'
    message_stream=1
    message_print "$@"
}

message_error() {
    message_color='\033[1;31m'
    message_stream=2
    message_print "$@"
}

message_print() {
    message_text=$1
    if [ "$message_stream" -eq 2 ]; then
        if [ -t 2 ] && [ "${TERM:-dumb}" != dumb ]; then
            printf '%b%s\033[0m\n' "$message_color" "$message_text" >&2
        else
            printf '%s\n' "$message_text" >&2
        fi
    elif [ -t 1 ] && [ "${TERM:-dumb}" != dumb ]; then
        printf '%b%s\033[0m\n' "$message_color" "$message_text"
    else
        printf '%s\n' "$message_text"
    fi
}

check_dependencies() {
    message_info "Checking dependencies..."
    missing_dependencies=
    missing_packages=
    for dependency in curl fzf jq md5sum ffmpeg img2pdf lsof; do
        command -v "$dependency" >/dev/null 2>&1 && continue
        missing_dependencies="${missing_dependencies}${missing_dependencies:+, }$dependency"
        case $dependency in
            md5sum) package=coreutils ;;
            *) package=$dependency ;;
        esac
        missing_packages="${missing_packages}${missing_packages:+ }$package"
    done
    if ! command -v xdg-open >/dev/null 2>&1 &&
        ! command -v gio >/dev/null 2>&1; then
        missing_dependencies="${missing_dependencies}${missing_dependencies:+, }xdg-open or gio"
        missing_packages="${missing_packages}${missing_packages:+ }xdg-utils"
    fi

    if [ -n "$missing_dependencies" ]; then
        message_error "Missing dependencies: $missing_dependencies"
        message_error "Install the following dependencies before running rolia-cli:"
        message_error "  sudo apt update && sudo apt install $missing_packages"
        message_error "Then run rolia-cli again."
        return 1
    fi
}

initialize() {
    check_dependencies
    mkdir -p "$DEFAULT_LIBRARY" "$APP_DATA/downloads" "$APP_CONFIG" "$APP_DATA/cache"
    printf '\n'
    message_success "Initialized rolia-cli folders:"
    message_info "  Library:   $DEFAULT_LIBRARY"
    message_info "  Downloads: $APP_DATA/downloads"
    message_info "  Config:    $APP_CONFIG"
    printf '\n'
    message_info "Search for a title, select a chapter, and read or download it as a PDF."
}

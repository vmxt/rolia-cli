
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

check_dependencies() {
    printf '%s\n' "Checking dependencies..."
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
        printf '\033[1;31m' >&2
        printf 'Missing dependencies: %s\n' "$missing_dependencies" >&2
        printf '%s\n' \
            "Install the following dependencies before running rolia-cli:" \
            "  sudo apt update && sudo apt install $missing_packages" \
            "Then run rolia-cli again." >&2
        printf '\033[0m' >&2
        return 1
    fi
}

initialize() {
    check_dependencies
    mkdir -p "$DEFAULT_LIBRARY" "$APP_DATA/downloads" "$APP_CONFIG" "$APP_DATA/cache"
    printf '\n%s\n' "Initialized rolia-cli folders:"
    printf '  Library:   %s\n' "$DEFAULT_LIBRARY"
    printf '  Downloads: %s\n' "$APP_DATA/downloads"
    printf '  Config:    %s\n' "$APP_CONFIG"
    printf '\n%s\n' "Search for a title, select a chapter, and read or download it as a PDF."
}

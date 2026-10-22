
is_image() {
    case $1 in
        *.[Aa][Vv][Ii][Ff]|*.[Bb][Mm][Pp]|*.[Gg][Ii][Ff]|*.[Jj][Pp][Ee][Gg]|*.[Jj][Pp][Gg]|*.[Pp][Nn][Gg]|*.[Ww][Ee][Bb][Pp])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

list_series() {
    library=$1
    if [ ! -d "$library" ]; then
        message_error "Library folder does not exist: $library"
        return 1
    fi

    found=false
    message_success "Series in $library:"
    for path in "$library"/*; do
        if [ -d "$path" ]; then
            printf '  %s\n' "${path##*/}"
            found=true
        fi
    done

    if [ "$found" = false ]; then
        message_warning "  (no series folders found)"
    fi
}

list_pages() {
    chapter=$1
    if [ ! -d "$chapter" ]; then
        message_error "Chapter folder does not exist: $chapter"
        return 1
    fi

    found=false
    message_success "Image pages in $chapter:"
    for path in "$chapter"/*; do
        if [ -f "$path" ] && is_image "$path"; then
            printf '  %s\n' "${path##*/}"
            found=true
        fi
    done

    if [ "$found" = false ]; then
        message_warning "  (no supported image pages found)"
    fi
}

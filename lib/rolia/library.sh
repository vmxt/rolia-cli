
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
        printf 'Library folder does not exist: %s\n' "$library" >&2
        return 1
    fi

    found=false
    printf 'Series in %s:\n' "$library"
    for path in "$library"/*; do
        if [ -d "$path" ]; then
            printf '  %s\n' "${path##*/}"
            found=true
        fi
    done

    if [ "$found" = false ]; then
        printf '  (no series folders found)\n'
    fi
}

list_pages() {
    chapter=$1
    if [ ! -d "$chapter" ]; then
        printf 'Chapter folder does not exist: %s\n' "$chapter" >&2
        return 1
    fi

    found=false
    printf 'Image pages in %s:\n' "$chapter"
    for path in "$chapter"/*; do
        if [ -f "$path" ] && is_image "$path"; then
            printf '  %s\n' "${path##*/}"
            found=true
        fi
    done

    if [ "$found" = false ]; then
        printf '  (no supported image pages found)\n'
    fi
}


is_allowed_source_url() {
    case $1 in
        "${SOURCE_BASE_URL%/}"/*|https://roliascan.com/*|https://*.roliascan.com/*|https://roliascan.org/*|https://*.roliascan.org/*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

is_allowed_image_url() {
    case $1 in
        https://mangataro.yachts/*)
            return 0
            ;;
        *)
            is_allowed_source_url "$1"
            ;;
    esac
}

export_chapter_pdf() (
    reader_url=$1
    manga_title=$2
    chapter_number=$3
    chapter_id=$4
    pdf_action=$5
    if ! is_allowed_source_url "$reader_url"; then
        printf 'Refusing to fetch a chapter page outside the source domains: %s\n' "$reader_url" >&2
        return 1
    fi
    case $chapter_id in
        *-*) post_id=${chapter_id##*-} ;;
        *) post_id=$chapter_id ;;
    esac
    case $post_id in
        ''|*[!0-9]*)
            printf 'The selected chapter has an invalid image-content ID: %s\n' "$chapter_id" >&2
            return 1
            ;;
    esac
    if ! chapter_content=$(curl --silent --show-error --fail --location --max-time 30 \
        --get --data-urlencode "chapter_id=$post_id" \
        "${SOURCE_BASE_URL%/}/auth/chapter-content"); then
        printf 'Could not load page images for chapter %s.\n' "$chapter_number" >&2
        return 1
    fi
    if ! printf '%s' "$chapter_content" | jq -e \
        '(.success == true) and ((.images // []) | type == "array") and ((.images // []) | length > 0)' >/dev/null; then
        error_message=$(printf '%s' "$chapter_content" |
            jq -r '.message // .error // "The chapter has no page images."' 2>/dev/null) ||
            error_message="The chapter has no page images."
        printf 'Could not load page images: %s\n' "$error_message" >&2
        return 1
    fi
    image_urls=$(printf '%s' "$chapter_content" | jq -r '.images[] | select(type == "string")')
    if [ -z "$image_urls" ]; then
        printf 'No image URLs were returned for chapter %s.\n' "$chapter_number" >&2
        return 1
    fi

    temp_dir=$(mktemp -d "${TMPDIR:-/tmp}/rolia-cli.XXXXXX") || {
        printf '%s\n' "Could not create a temporary folder for chapter pages." >&2
        return 1
    }
    trap cleanup_temp_dir 0
    trap 'exit 1' HUP INT TERM
    total_pages=$(printf '%s\n' "$image_urls" | awk 'END { print NR }')
    page_number=0
    print_page_progress "$page_number" "$total_pages"
    while IFS= read -r image_url; do
        if ! is_allowed_image_url "$image_url"; then
            printf 'Refusing to fetch a page image outside the approved source and image CDN domains: %s\n' "$image_url" >&2
            return 1
        fi
        page_number=$((page_number + 1))
        image_file=$(printf '%s/page-%04d' "$temp_dir" "$page_number")
        if ! curl --silent --show-error --fail --location --max-time 60 \
            --referer "$reader_url" --output "$image_file" "$image_url"; then
            printf '\n' >&2
            printf 'Failed to download page %s.\n' "$page_number" >&2
            return 1
        fi
        converted_file=$(printf '%s/converted-%04d.png' "$temp_dir" "$page_number")
        if ! ffmpeg -nostdin -loglevel error -y -i "$image_file" -frames:v 1 "$converted_file"; then
            printf '\n' >&2
            printf 'Could not convert page %s to PDF-compatible PNG.\n' "$page_number" >&2
            return 1
        fi
        print_page_progress "$page_number" "$total_pages"
    done <<EOF
$image_urls
EOF
    printf '\n'

    safe_title=$(printf '%s' "$manga_title" | tr -cs '[:alnum:]_.-' '-')
    safe_chapter=$(printf '%s' "$chapter_number" | tr -cs '[:alnum:]_.-' '-')
    [ -n "$safe_title" ] || safe_title=manga
    [ -n "$safe_chapter" ] || safe_chapter=chapter
    pdf_name=$safe_title-Chapter-$safe_chapter.pdf
    if [ "$pdf_action" = download ]; then
        mkdir -p "$APP_DATA/downloads"
        pdf_path=$APP_DATA/downloads/$pdf_name
        pdf_suffix=1
        while [ -e "$pdf_path" ]; do
            pdf_path=$APP_DATA/downloads/$safe_title-Chapter-$safe_chapter-$pdf_suffix.pdf
            pdf_suffix=$((pdf_suffix + 1))
        done
    else
        pdf_path=$temp_dir/$pdf_name
    fi
    if ! img2pdf "$temp_dir"/converted-*.png --output "$pdf_path"; then
        rm -f -- "$pdf_path"
        printf '%s\n' "PDF generation failed; temporary page files will be cleaned up." >&2
        return 1
    fi
    if [ "$pdf_action" = download ]; then
        printf '\nPDF saved to: %s\n' "$pdf_path"
        cleanup_temp_dir
    else
        open_pdf_in_background "$pdf_path" "$temp_dir"
    fi
)

cleanup_temp_dir() {
    if [ -n "${temp_dir:-}" ] && [ -d "$temp_dir" ]; then
        rm -rf "$temp_dir"
    fi
}

print_page_progress() {
    completed_pages=$1
    total_pages=$2
    progress_width=20
    filled_width=$((completed_pages * progress_width / total_pages))
    progress_bar=
    bar_index=0
    while [ "$bar_index" -lt "$progress_width" ]; do
        if [ "$bar_index" -lt "$filled_width" ]; then
            progress_bar=${progress_bar}#
        else
            progress_bar=${progress_bar}-
        fi
        bar_index=$((bar_index + 1))
    done
    printf '\rDownloading pages [%s] %s/%s' \
        "$progress_bar" "$completed_pages" "$total_pages"
}

open_pdf_in_background() {
    pdf_path=$1
    temp_dir=$2
    if ! command -v lsof >/dev/null 2>&1; then
        printf '%s\n' "Automatic PDF cleanup needs lsof; install it before reading chapters." >&2
        return 1
    fi
    if [ -n "$PDF_VIEWER" ]; then
        if ! command -v "$PDF_VIEWER" >/dev/null 2>&1; then
            printf 'Configured PDF viewer not found: %s\n' "$PDF_VIEWER" >&2
            return 1
        fi
        "$PDF_VIEWER" "$pdf_path" >/dev/null 2>&1 &
    elif command -v zathura >/dev/null 2>&1; then
        zathura "$pdf_path" >/dev/null 2>&1 &
    elif command -v mupdf >/dev/null 2>&1; then
        mupdf "$pdf_path" >/dev/null 2>&1 &
    elif command -v evince >/dev/null 2>&1; then
        evince --wait "$pdf_path" >/dev/null 2>&1 &
    elif command -v atril >/dev/null 2>&1; then
        atril --wait "$pdf_path" >/dev/null 2>&1 &
    elif command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$pdf_path" >/dev/null 2>&1 &
    elif command -v gio >/dev/null 2>&1; then
        gio open "$pdf_path" >/dev/null 2>&1 &
    else
        printf '%s\n' "No PDF opener found. Install a PDF viewer or set ROLIA_CLI_PDF_VIEWER." >&2
        return 1
    fi

    cleanup_after_pdf_close "$pdf_path" "$temp_dir" </dev/null >/dev/null 2>&1 &
    trap - 0
}

cleanup_after_pdf_close() {
    pdf_path=$1
    temp_dir=$2
    while ! lsof -t "$pdf_path" >/dev/null 2>&1; do
        sleep 1
    done
    while lsof -t "$pdf_path" >/dev/null 2>&1; do
        sleep 1
    done
    rm -rf "$temp_dir"
}

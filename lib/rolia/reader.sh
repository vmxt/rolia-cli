
select_chapter() {
    manga_numeric_id=$1
    manga_slug=$2
    manga_title=$3
    case $manga_numeric_id in
        ''|*[!0-9]*)
            message_error "The search result did not include a valid numeric manga ID."
            return 1
            ;;
    esac

    chapter_rows=
    offset=0
    while :; do
        timestamp=$(date +%s)
        utc_hour=$(date -u +%Y%m%d%H)
        token=$(printf '%s' "${timestamp}mng_ch_${utc_hour}" | md5sum | cut -c1-16)
        if ! chapter_json=$(curl --silent --fail --location --max-time 30 \
            --get \
            --data-urlencode "manga_id=$manga_numeric_id" \
            --data-urlencode "offset=$offset" \
            --data-urlencode "limit=500" \
            --data-urlencode "order=DESC" \
            --data-urlencode "_t=$token" \
            --data-urlencode "_ts=$timestamp" \
            "${SOURCE_BASE_URL%/}/auth/manga-chapters"); then
            message_error "Could not load chapters for $manga_title."
            return 1
        fi
        if ! printf '%s' "$chapter_json" | jq -e \
            '(.success == true) and ((.chapters // []) | type == "array")' >/dev/null; then
            error_message=$(printf '%s' "$chapter_json" |
                jq -r '.message // .error // "The chapter endpoint returned an unsuccessful response."' 2>/dev/null) ||
                error_message="The chapter endpoint returned an unsuccessful response."
            message_error "Could not load chapters: $error_message"
            return 1
        fi

        chapter_batch=$(printf '%s' "$chapter_json" | jq -r '
            [(.chapters // [])[] as $chapter
            | (($chapter.url // "") | split("?")[0] | split("/") | map(select(length > 0)) | last) as $reader_id
            | [($reader_id // (if ($chapter.chapter != null and $chapter.id != null) then
                    "ch" + ($chapter.chapter | tostring) + "-" + ($chapter.id | tostring)
                  else "" end)),
               ($chapter.chapter // ""),
               ($chapter.url // "")]
            | @tsv] | .[]')
        if [ -n "$chapter_batch" ]; then
            if [ -n "$chapter_rows" ]; then
                chapter_rows=$(printf '%s\n%s' "$chapter_rows" "$chapter_batch")
            else
                chapter_rows=$chapter_batch
            fi
        fi

        batch_count=$(printf '%s' "$chapter_json" | jq -r '(.chapters // []) | length')
        has_more=$(printf '%s' "$chapter_json" | jq -r '.has_more // false')
        if [ "$has_more" != true ] || [ "$batch_count" -eq 0 ]; then
            break
        fi
        offset=$((offset + batch_count))
    done

    if [ -z "$chapter_rows" ]; then
        message_warning "No chapters found for $manga_title."
        return 0
    fi

    chapter_rows=$(printf '%s\n' "$chapter_rows" | awk -F '\t' '!seen[$1]++')
    if ! pick_chapter "$chapter_rows" "Select chapter: "; then
        return 0
    fi
    read_chapter_loop "$chapter_rows" "$selected_chapter" "$manga_title" "$manga_slug"
}

pick_chapter() {
    chapter_options=$1
    chapter_prompt=$2
    selected_chapter=$(printf '%s\n' "$chapter_options" |
        fzf --delimiter="$(printf '\t')" --with-nth=2 \
            --no-height \
            --color=hl:green,hl+:bright-green \
            --prompt="$chapter_prompt" --reverse --cycle --no-sort) || return 1
    [ -n "$selected_chapter" ]
}

chapter_reader_url() {
    chapter_row=$1
    manga_slug=$2
    chapter_id=$(printf '%s\n' "$chapter_row" | cut -f1)
    chapter_url=$(printf '%s\n' "$chapter_row" | cut -f3)
    case $chapter_url in
        http://*|https://*) printf '%s\n' "$chapter_url" ;;
        /*) printf '%s\n' "${SOURCE_BASE_URL%/}$chapter_url" ;;
        *)
            if [ -n "$manga_slug" ]; then
                printf '%s\n' "${SOURCE_BASE_URL%/}/read/$manga_slug/$chapter_id/"
            else
                message_error "The selected chapter has no reader URL."
                return 1
            fi
            ;;
    esac
}

read_chapter_loop() {
    chapter_rows=$1
    current_chapter=$2
    manga_title=$3
    manga_slug=$4
    current_index=$(printf '%s\n' "$chapter_rows" |
        awk -v selected="$current_chapter" '$0 == selected { print NR; exit }')
    chapter_count=$(printf '%s\n' "$chapter_rows" | awk 'END { print NR }')
    if [ -z "$current_index" ]; then
        message_error "The selected chapter is not in the chapter list."
        return 1
    fi

    chapter_number=$(printf '%s\n' "$current_chapter" | cut -f2)
    reader_url=$(chapter_reader_url "$current_chapter" "$manga_slug") || return 1
    show_chapter_screen "$manga_title" "$chapter_number"
    export_chapter_pdf "$reader_url" "$manga_title" "$chapter_number" \
        "$(printf '%s\n' "$current_chapter" | cut -f1)" read

    while :; do
        chapter_number=$(printf '%s\n' "$current_chapter" | cut -f2)
        reader_action=$(reader_menu_options "$current_index" "$chapter_count" |
            fzf --prompt="Chapter #$chapter_number: " --header="Reading chapter #$chapter_number" \
                --no-height --reverse --cycle) || return 0
        case $reader_action in
            Next)
                current_index=$((current_index - 1))
                ;;
            Previous)
                current_index=$((current_index + 1))
                ;;
            'Select chapter')
                if ! pick_chapter "$chapter_rows" "Select chapter: "; then
                    continue
                fi
                current_chapter=$selected_chapter
                current_index=$(printf '%s\n' "$chapter_rows" |
                    awk -v selected="$current_chapter" '$0 == selected { print NR; exit }')
                ;;
            'Download chapter')
                reader_url=$(chapter_reader_url "$current_chapter" "$manga_slug") || return 1
                export_chapter_pdf "$reader_url" "$manga_title" "$chapter_number" \
                    "$(printf '%s\n' "$current_chapter" | cut -f1)" download
                continue
                ;;
            Quit)
                return 0
                ;;
            *)
                continue
                ;;
        esac

        current_chapter=$(printf '%s\n' "$chapter_rows" |
            awk -v selected_index="$current_index" 'NR == selected_index { print; exit }')
        chapter_number=$(printf '%s\n' "$current_chapter" | cut -f2)
        reader_url=$(chapter_reader_url "$current_chapter" "$manga_slug") || return 1
        show_chapter_screen "$manga_title" "$chapter_number"
        export_chapter_pdf "$reader_url" "$manga_title" "$chapter_number" \
            "$(printf '%s\n' "$current_chapter" | cut -f1)" read
    done
}

reader_menu_options() {
    current_index=$1
    chapter_count=$2

    if [ "$current_index" -gt 1 ]; then
        printf '%s\n' Next
    fi
    if [ "$current_index" -lt "$chapter_count" ]; then
        printf '%s\n' Previous
    fi
    printf '%s\n' 'Select chapter' 'Download chapter' Quit
}

show_chapter_screen() {
    manga_title=$1
    chapter_number=$2
    printf '\033[1;36m%s\033[0m\n' "$manga_title"
    printf '\033[1;35mChapter #%s\033[0m\n\n' "$chapter_number"
}

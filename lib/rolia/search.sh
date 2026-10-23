
search_online() {
    search_term=$1
    while :; do
        while [ -z "$search_term" ]; do
            printf '\033[1;36mSearch manga: \033[0m'
            IFS= read -r search_term || return 0
        done
        if [ "${#search_term}" -ge 2 ]; then
            break
        fi
        message_error "Search query must be at least 2 characters."
        search_term=
    done
    case $SOURCE_BASE_URL in
        http://*|https://*) ;;
        *)
            message_error "ROLIA_CLI_SOURCE_BASE_URL must start with http:// or https://."
            return 1
            ;;
    esac

    request_body=$(jq -cn --arg query "$search_term" --argjson limit 50 \
        '{query: $query, limit: $limit}') || return 1
    message_info "Searching manga..."
    if ! search_json=$(curl --silent --fail --location --max-time 30 \
        -H 'Content-Type: application/json' --data-binary "$request_body" \
        "${SOURCE_BASE_URL%/}/auth/search"); then
        message_error "Could not search $SOURCE_BASE_URL."
        return 1
    fi
    if ! printf '%s' "$search_json" | jq -e \
        '(.success == true) and ((.results // []) | type == "array")' >/dev/null; then
        error_message=$(printf '%s' "$search_json" |
            jq -r '.message // .error // "The source returned an unsuccessful response."' 2>/dev/null) ||
            error_message="The source returned an unsuccessful response."
        message_error "Search failed: $error_message"
        return 1
    fi

    manga_rows=$(printf '%s' "$search_json" | jq -r '
        [(.results // [])[]] | to_entries[] |
          [((.key + 1) | tostring),
           (.value.id // ""),
           (.value.title // "Untitled"),
           (.value.slug // "")]
          | @tsv')
    if [ -z "$manga_rows" ]; then
        message_warning "No manga found for \"$search_term\"."
        return 0
    fi

    exact_manga_rows=$(printf '%s\n' "$manga_rows" |
        awk -F '\t' -v query="$search_term" 'tolower($3) == tolower(query)')
    exact_manga_count=$(printf '%s\n' "$exact_manga_rows" |
        awk 'NF { count++ } END { print count + 0 }')
    if [ "$exact_manga_count" -eq 1 ]; then
        selected_manga=$exact_manga_rows
    else
        selected_manga=$(printf '%s\n' "$manga_rows" |
            fzf --delimiter="$(printf '\t')" --with-nth=1,3 \
                --no-height --no-sort \
                --query="$search_term" --color=hl:green,hl+:bright-green \
                --prompt="Select manga: " --reverse --cycle) || return 0
    fi
    manga_id=$(printf '%s\n' "$selected_manga" | cut -f2)
    manga_title=$(printf '%s\n' "$selected_manga" | cut -f3)
    manga_slug=$(printf '%s\n' "$selected_manga" | cut -f4)
    if [ -z "$manga_id" ]; then
        message_error "The selected result has no manga ID."
        return 1
    fi

    message_info "Selected manga: $manga_title"
    select_chapter "$manga_id" "$manga_slug" "$manga_title"
}

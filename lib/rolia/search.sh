
search_online() {
    search_term=$1
    while [ -z "$search_term" ]; do
        printf '\033[1;36mSearch manga: \033[0m'
        IFS= read -r search_term || return 0
    done
    case $SOURCE_BASE_URL in
        http://*|https://*) ;;
        *)
            printf '%s\n' "ROLIA_CLI_SOURCE_BASE_URL must start with http:// or https://." >&2
            return 1
            ;;
    esac

    request_body=$(jq -cn --arg query "$search_term" --argjson limit 50 \
        '{query: $query, limit: $limit}') || return 1
    printf '%s\n' "Searching manga..."
    if ! search_json=$(curl --silent --show-error --fail --location --max-time 30 \
        -H 'Content-Type: application/json' --data-binary "$request_body" \
        "${SOURCE_BASE_URL%/}/auth/search"); then
        printf 'Could not search %s.\n' "$SOURCE_BASE_URL" >&2
        return 1
    fi
    if ! printf '%s' "$search_json" | jq -e \
        '(.success == true) and ((.results // []) | type == "array")' >/dev/null; then
        error_message=$(printf '%s' "$search_json" |
            jq -r '.message // .error // "The source returned an unsuccessful response."' 2>/dev/null) ||
            error_message="The source returned an unsuccessful response."
        printf 'Search failed: %s\n' "$error_message" >&2
        return 1
    fi

    manga_rows=$(printf '%s' "$search_json" | jq -r '
        [(.results // [])[] |
          [(.id // ""),
           (.title // "Untitled"),
           (.slug // "")]
          | @tsv] | .[]')
    if [ -z "$manga_rows" ]; then
        printf 'No manga found for "%s".\n' "$search_term"
        return 0
    fi

    exact_manga_rows=$(printf '%s\n' "$manga_rows" |
        awk -F '\t' -v query="$search_term" 'tolower($2) == tolower(query)')
    exact_manga_count=$(printf '%s\n' "$exact_manga_rows" |
        awk 'NF { count++ } END { print count + 0 }')
    if [ "$exact_manga_count" -eq 1 ]; then
        selected_manga=$exact_manga_rows
    else
        selected_manga=$(printf '%s\n' "$manga_rows" |
            fzf --delimiter="$(printf '\t')" --with-nth=2 \
                --prompt="Select manga: " --height=80% --reverse --cycle) || return 0
    fi
    manga_id=$(printf '%s\n' "$selected_manga" | cut -f1)
    manga_title=$(printf '%s\n' "$selected_manga" | cut -f2)
    manga_slug=$(printf '%s\n' "$selected_manga" | cut -f3)
    if [ -z "$manga_id" ]; then
        printf '%s\n' "The selected result has no manga ID." >&2
        return 1
    fi

    printf '\n\033[1;36mSelected manga:\033[0m \033[1m%s\033[0m\n\n' "$manga_title"
    select_chapter "$manga_id" "$manga_slug" "$manga_title"
}

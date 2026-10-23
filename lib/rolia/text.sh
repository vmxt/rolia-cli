extract_chapter_text() {
    chapter_html=$1
    if ! chapter_text=$(printf '%s' "$chapter_html" |
        awk -f "$ROLIA_ROOT/lib/rolia/html_to_text.awk"); then
        message_error "Could not extract readable text from the novel chapter."
        return 1
    fi
    printf '%s' "$chapter_text"
}

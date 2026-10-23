function add_boundary(tag) {
    if (tag ~ /^(p|div|section|article|blockquote|h[1-6])$/) {
        output = output "\n\n"
    } else if (tag ~ /^(br|hr|li|tr)$/) {
        output = output "\n"
    }
}

function decode_entities(text) {
    gsub(/&nbsp;/, " ", text)
    gsub(/&#160;/, " ", text)
    gsub(/&apos;/, "'", text)
    gsub(/&quot;/, "\"", text)
    gsub(/&ldquo;|&rdquo;/, "\"", text)
    gsub(/&lsquo;|&rsquo;/, "'", text)
    gsub(/&#8216;|&#8217;/, "'", text)
    gsub(/&#8220;|&#8221;/, "\"", text)
    gsub(/&ndash;/, "-", text)
    gsub(/&#8211;/, "-", text)
    gsub(/&mdash;/, "--", text)
    gsub(/&#8212;/, "--", text)
    gsub(/&hellip;/, "...", text)
    gsub(/&#8230;/, "...", text)
    gsub(/&#39;|&#039;/, "'", text)
    gsub(/&#34;/, "\"", text)
    gsub(/&lt;/, "<", text)
    gsub(/&gt;/, ">", text)
    gsub(/&amp;/, "\\&", text)
    return text
}

{
    line = $0 "\n"
    for (i = 1; i <= length(line); i++) {
        ch = substr(line, i, 1)
        if (in_comment) {
            comment_tail = comment_tail ch
            if (length(comment_tail) > 3) {
                comment_tail = substr(comment_tail, length(comment_tail) - 2)
            }
            if (comment_tail == "-->") {
                in_comment = 0
                comment_tail = ""
            }
        } else if (in_tag) {
            tag = tag ch
            if (tag == "<!--") {
                in_comment = 1
                in_tag = 0
                tag = ""
                comment_tail = ""
            } else if (ch == ">") {
                tag_name = tolower(tag)
                sub(/^<[[:space:]]*\/?[[:space:]]*/, "", tag_name)
                sub(/[[:space:]\/>].*$/, "", tag_name)
                if (tag_name == "script" || tag_name == "style" ||
                    tag_name == "noscript") {
                    if (tag ~ /^<[[:space:]]*\//) {
                        ignored_tag = ""
                    } else {
                        ignored_tag = tag_name
                    }
                } else if (!ignored_tag) {
                    if (tag ~ /^<[[:space:]]*\//) {
                        add_boundary(tag_name)
                    } else {
                        add_boundary(tag_name)
                    }
                }
                in_tag = 0
                tag = ""
            }
        } else if (ch == "<") {
            in_tag = 1
            tag = "<"
        } else if (!ignored_tag) {
            output = output ch
        }
    }
}

END {
    text = decode_entities(output)
    count = split(text, lines, "\n")
    blank = 0
    for (i = 1; i <= count; i++) {
        line = lines[i]
        gsub(/[[:space:]]+/, " ", line)
        sub(/^ /, "", line)
        sub(/ $/, "", line)
        if (line == "") {
            if (printed && !blank) {
                print ""
                blank = 1
            }
        } else {
            print line
            printed = 1
            blank = 0
        }
    }
    if (!printed) {
        print "The source did not return loaded chapter text." > "/dev/stderr"
        exit 1
    }
}

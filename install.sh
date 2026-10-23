#!/usr/bin/env sh
set -eu

case $0 in
    */*)
        script_dir=${0%/*}
        [ -n "$script_dir" ] || script_dir=/
        ;;
    *)
        script_path=$(command -v "$0") || {
            printf 'Could not locate installer: %s\n' "$0" >&2
            exit 1
        }
        script_dir=${script_path%/*}
        [ "$script_dir" != "$script_path" ] || script_dir=.
        ;;
esac

bin_dir=$HOME/.local/bin
man_dir=${XDG_DATA_HOME:-$HOME/.local/share}/man/man1
module_dir=$bin_dir/lib/rolia

install -d "$bin_dir" "$module_dir" "$man_dir"
install -m 755 "$script_dir/rolia-cli" "$bin_dir/rolia-cli"
install -m 644 "$script_dir/rolia" "$bin_dir/rolia"
install -m 644 "$script_dir"/lib/rolia/*.sh "$module_dir/"
install -m 644 "$script_dir"/lib/rolia/*.awk "$module_dir/"
install -m 644 "$script_dir/man/rolia-cli.1" "$man_dir/rolia-cli.1"

printf 'Installed rolia-cli to %s\n' "$bin_dir"
printf 'Installed man page to %s/rolia-cli.1\n' "$man_dir"

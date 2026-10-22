# rolia-cli

`rolia-cli` is a POSIX shell command-line manga reader. Search for a series,
select a chapter, and read it as a temporary PDF reader or save a permanent PDF.
It requests the series and chapter data directly from RoliaScan.

## Features

- Search series by name and select from interactive results.
- Browse a series' chapter list and move between chapters.
- Extract chapter page images into a PDF for reading.
- Download a permanent chapter PDF on request.
- Remove temporary page and PDF files after the PDF viewer closes.

The chapter controls are **Next**, **Previous**, **Select chapter**,
**Download chapter**, and **Quit**.

## Requirements

The script requires:

- A POSIX-compatible shell (`sh`)
- `curl`
- `fzf`
- `jq`
- `md5sum` (provided by GNU coreutils)
- `ffmpeg`
- `img2pdf`
- `lsof` (used to detect when a PDF viewer closes, so temporary files can be
  removed automatically)
- A PDF viewer and a desktop opener such as `xdg-open` or `gio`

At startup, `rolia-cli` checks that its required command-line tools are
installed. If any are missing, it stops and prints the missing dependencies
and an Ubuntu/Debian installation command in red. That command includes only
the packages needed for the missing tools.

The installation steps below target Ubuntu and Debian. Other Linux
distributions need equivalent packages. The script is not a native
PowerShell command; on Windows, run it in WSL with the Linux dependencies
installed. macOS users need a POSIX shell and equivalent tools; GNU
`coreutils` may be needed for `md5sum`.

## Install on Ubuntu or Debian

Install the required command-line tools:

```sh
sudo apt update
sudo apt install curl fzf jq coreutils ffmpeg img2pdf lsof xdg-utils
```

Install the command, its modules, and the man page from this checkout with
one command:

```sh
./install.sh
```

The installer places the command and implementation under `~/.local/bin`,
the modules under `~/.local/bin/lib/rolia/`, and the manual page under
`$XDG_DATA_HOME/man/man1/` (or `~/.local/share/man/man1/` if
`XDG_DATA_HOME` is unset). The installed files are kept together so the
command can load its implementation and modules. Read the manual with
`man rolia-cli`.

## Code layout

- `rolia-cli` is the executable launcher.
- `rolia` initializes configuration, imports the modules, and dispatches
  commands.
- `lib/rolia/common.sh` contains usage, dependency checks, and initialization.
- `lib/rolia/search.sh` handles title search.
- `lib/rolia/reader.sh` handles chapter selection and navigation.
- `lib/rolia/pdf.sh` downloads pages and opens or saves chapter PDFs.
- `lib/rolia/library.sh` lists local series and chapter pages.

Make sure `~/.local/bin` is on your `PATH`. For Bash, add this line to
`~/.bashrc` if it is not already there:

```sh
export PATH="$HOME/.local/bin:$PATH"
```

Reload the shell configuration or open a new terminal, then initialize the
application directories and check dependencies:

```sh
rolia-cli init
```

You can also run the script directly from the checkout:

```sh
./rolia-cli init
```

## Uninstall

Remove the installed command:

```sh
rm "$HOME/.local/bin/rolia-cli" "$HOME/.local/bin/rolia"
rm -r "$HOME/.local/bin/lib/rolia"
rm -f "${XDG_DATA_HOME:-$HOME/.local/share}/man/man1/rolia-cli.1"
```

If you added the `PATH` line to `~/.bashrc` only for `rolia-cli`, remove that
line too, then open a new terminal.

Uninstalling the command does not remove your downloaded PDFs or application
data. To remove those as well, first copy any files you want to keep, then
run:

```sh
rm -rf "${XDG_DATA_HOME:-$HOME/.local/share}/rolia-cli"
rm -rf "${XDG_CONFIG_HOME:-$HOME/.config}/rolia-cli"
```

The first command removes downloads, the library, and cache data. The second
removes the application's configuration directory. Dependencies installed
with `apt` are shared system packages and are intentionally left installed.

## Usage

Start an interactive search:

```sh
rolia-cli
```

Search using a query:

```sh
rolia-cli "wind breaker"
```

You can also use the explicit `search` command:

```sh
rolia-cli search "futari bus"
```

An unambiguous exact title match is selected automatically, ignoring letter
case. For example, `Blue Lock` and `blue lock` go straight to that series'
chapter list. A partial query such as `Blue` shows the matching titles so you
can select the right series. Search queries must contain at least two
characters.

Select a series and a chapter with `fzf`. The chapter's page images are
extracted and assembled into a temporary PDF, which opens in your PDF viewer.
The chapter menu remains available in the terminal while the PDF is open.
The terminal is cleared when a chapter opens or you navigate to another
chapter, so previous search and chapter output does not accumulate. Temporary
files are removed after the viewer closes.

When selecting a series, the search query is prefilled in `fzf`, so results
are immediately narrowed to titles matching the input. Type to refine the
search further. Matching text is highlighted in both the series and chapter
selectors; type a chapter number to filter the chapter list. The selectors
use the full terminal screen, with the prompt at the top, so earlier output
does not remain above the menu. The initial **Search manga:** prompt is not
cleared, so it remains visible in terminals such as the VS Code integrated
terminal.

The reader menu provides:

- **Next** — open the next chapter in the list.
- **Previous** — open the previous chapter in the list.
- **Select chapter** — choose another chapter.
- **Download chapter** — save a permanent PDF of the current chapter.
- **Quit** — leave the reader menu.

## Files and configuration

By default, `rolia-cli` stores its files under:

- Downloads: `~/.local/share/rolia-cli/downloads/`
- Library: `~/.local/share/rolia-cli/library/`
- Configuration: `~/.config/rolia-cli/`
- Cache: `~/.local/share/rolia-cli/cache/`

It follows the XDG directory environment variables when set:

- `XDG_DATA_HOME` changes the base data directory.
- `XDG_CONFIG_HOME` changes the base configuration directory.

Optional settings:

- `ROLIA_CLI_SOURCE_BASE_URL` changes the source base URL. It defaults to
  `https://roliascan.com`.
- `ROLIA_CLI_PDF_VIEWER` sets the PDF viewer command used to open temporary
  PDFs. The command should accept the PDF path as its argument.

For upgrades from `man-cli`, existing `~/.local/share/man-cli` and
`~/.config/man-cli` directories are reused if the corresponding `rolia-cli`
directories do not exist. Existing `MAN_CLI_SOURCE_BASE_URL` and
`MAN_CLI_PDF_VIEWER` environment variables are also supported; the
`ROLIA_CLI_*` names take precedence.

Automatic cleanup for temporary PDFs depends on `lsof` being installed. Keep
the PDF viewer running while reading; temporary files are removed when the
viewer closes the PDF.

## Troubleshooting

- Run `rolia-cli init` to check whether required tools are available.
- If `rolia-cli: command not found` appears, verify that `~/.local/bin` is on
  `PATH`, then open a new terminal.
- If a temporary PDF cannot be opened or cleaned up, install `lsof` and a
  desktop opener such as `xdg-utils`, or set `ROLIA_CLI_PDF_VIEWER` to a
  suitable PDF viewer.
- Chapter pages are served by the source site and its image CDN. If a page
  cannot be fetched, check your connection and try again.

## Responsible use

Use the tool only for content you are authorized to access. Follow the
source site's terms and applicable copyright laws.

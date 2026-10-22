# man-cli

`man-cli` is a POSIX shell command-line manga reader. Search for a series,
select a chapter, and read it as a temporary PDF or save a permanent PDF.
It requests the series and chapter data directly from RoliaScan; no separate
Ruby API server is required.

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

At startup, `man-cli` checks that its required command-line tools are
installed. If any are missing, it stops and prints the missing dependencies
and an Ubuntu/Debian installation command in red.

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

Install the command from this checkout into `~/.local/bin`:

```sh
mkdir -p "$HOME/.local/bin"
install -m 755 ./man-cli "$HOME/.local/bin/man-cli"
```

Make sure `~/.local/bin` is on your `PATH`. For Bash, add this line to
`~/.bashrc` if it is not already there:

```sh
export PATH="$HOME/.local/bin:$PATH"
```

Reload the shell configuration or open a new terminal, then initialize the
application directories and check dependencies:

```sh
man-cli init
```

You can also run the script directly from the checkout:

```sh
./man-cli init
```

## Uninstall

Remove the installed command:

```sh
rm "$HOME/.local/bin/man-cli"
```

If you added the `PATH` line to `~/.bashrc` only for `man-cli`, remove that
line too, then open a new terminal.

Uninstalling the command does not remove your downloaded PDFs or application
data. To remove those as well, first copy any files you want to keep, then
run:

```sh
rm -rf "${XDG_DATA_HOME:-$HOME/.local/share}/man-cli"
rm -rf "${XDG_CONFIG_HOME:-$HOME/.config}/man-cli"
```

The first command removes downloads, the library, and cache data. The second
removes the application's configuration directory. Dependencies installed
with `apt` are shared system packages and are intentionally left installed.

## Usage

Start an interactive search:

```sh
man-cli
```

Search using a query:

```sh
man-cli "wind breaker"
```

You can also use the explicit `search` command:

```sh
man-cli search "futari bus"
```

Select a series and a chapter with `fzf`. The chapter's page images are
extracted and assembled into a temporary PDF, which opens in your PDF viewer.
The chapter menu remains available in the terminal while the PDF is open.
Temporary files are removed after the viewer closes.

The reader menu provides:

- **Next** — open the next chapter in the list.
- **Previous** — open the previous chapter in the list.
- **Select chapter** — choose another chapter.
- **Download chapter** — save a permanent PDF of the current chapter.
- **Quit** — leave the reader menu.

## Files and configuration

By default, `man-cli` stores its files under:

- Downloads: `~/.local/share/man-cli/downloads/`
- Library: `~/.local/share/man-cli/library/`
- Configuration: `~/.config/man-cli/`
- Cache: `~/.local/share/man-cli/cache/`

It follows the XDG directory environment variables when set:

- `XDG_DATA_HOME` changes the base data directory.
- `XDG_CONFIG_HOME` changes the base configuration directory.

Optional settings:

- `MAN_CLI_SOURCE_BASE_URL` changes the source base URL. It defaults to
  `https://roliascan.com`.
- `MAN_CLI_PDF_VIEWER` sets the PDF viewer command used to open temporary
  PDFs. The command should accept the PDF path as its argument.

Automatic cleanup for temporary PDFs depends on `lsof` being installed. Keep
the PDF viewer running while reading; temporary files are removed when the
viewer closes the PDF.

## Troubleshooting

- Run `man-cli init` to check whether required tools are available.
- If `man-cli: command not found` appears, verify that `~/.local/bin` is on
  `PATH`, then open a new terminal.
- If a temporary PDF cannot be opened or cleaned up, install `lsof` and a
  desktop opener such as `xdg-utils`, or set `MAN_CLI_PDF_VIEWER` to a
  suitable PDF viewer.
- Chapter pages are served by the source site and its image CDN. If a page
  cannot be fetched, check your connection and try again.

## Responsible use

Use the tool only for content you are authorized to access. Follow the
source site's terms and applicable copyright laws.

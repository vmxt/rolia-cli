# rolia-cli

`rolia-cli` is a POSIX shell manga reader. Search RoliaScan, choose a series
and chapter, then read it as a PDF or save it for later.

## Features

- Search and select manga from numbered results.
- Browse chapters with next, previous, and select controls.
- Read chapters in a PDF viewer or download permanent PDFs.
- Clean up temporary reading files automatically.

## Requirements

`sh`, `curl`, `fzf`, `jq`, GNU `md5sum`, `ffmpeg`, `img2pdf`, `lsof`, and a
PDF viewer/opener (`xdg-open`, `gio`, or macOS `open`).

## Install

On Ubuntu or Debian:

```sh
sudo apt update
sudo apt install git curl fzf jq coreutils ffmpeg img2pdf lsof xdg-utils
git clone https://github.com/vmxt/rolia-cli.git
cd rolia-cli
./install.sh
```

Ensure `~/.local/bin` is on your `PATH`, then initialize:

```sh
rolia-cli init
```

For Windows/WSL, macOS, and other Linux distributions, see
[INSTALLATION.md](./INSTALLATION.md).

## Use

```sh
rolia-cli
rolia-cli "one piece"
```

Select a manga and chapter from the menus. While reading, use **Next**,
**Previous**, **Select chapter**, **Download chapter**, or **Quit**.

## Configuration

By default, data is stored in `~/.local/share/rolia-cli/` and configuration
in `~/.config/rolia-cli/`. The XDG environment variables
`XDG_DATA_HOME` and `XDG_CONFIG_HOME` can change these locations.

- `ROLIA_CLI_SOURCE_BASE_URL` changes the source URL (default:
  `https://roliascan.com`).
- `ROLIA_CLI_PDF_VIEWER` sets the PDF viewer command.

Use the tool only for content you are authorized to access, and follow the
source site's terms and applicable copyright laws. See
[DISCLAIMER.md](./DISCLAIMER.md).

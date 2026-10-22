# Installation by platform

`rolia-cli` is a POSIX shell application. It is not a native PowerShell or
iOS application. Follow the instructions for the environment where the
command will run.

## Windows: use WSL

Run PowerShell as Administrator and install Ubuntu under Windows Subsystem
for Linux (WSL):

```powershell
wsl --install -d Ubuntu
```

Restart Windows if prompted, then open Ubuntu from the Start menu and create
your Linux user. Run the remaining commands in the Ubuntu terminal, not in
PowerShell:

```sh
sudo apt update
sudo apt install git curl fzf jq coreutils ffmpeg img2pdf lsof xdg-utils
git clone https://github.com/vmxt/rolia-cli.git
cd rolia-cli
./install.sh
printf '\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$HOME/.bashrc"
. "$HOME/.bashrc"
rolia-cli init
```

The command and its dependencies run inside WSL. On Windows 11, WSLg can
open Linux desktop applications, including a PDF viewer. If no viewer opens,
install a Linux PDF viewer in WSL or set `ROLIA_CLI_PDF_VIEWER` to a viewer
available there. Native PowerShell execution is not supported.

## macOS

Install Apple's command-line developer tools if needed:

```sh
xcode-select --install
```

Install Homebrew if it is not already installed, then install the command-line
dependencies:

```sh
brew install curl fzf jq coreutils ffmpeg lsof pipx
pipx ensurepath
pipx install img2pdf
```

Open a new Terminal window after `pipx ensurepath`. The application needs the
GNU `md5sum` command provided by Homebrew's `coreutils`; add its GNU command
directory and the CLI install directory to `PATH` in `~/.zshrc`:

```sh
printf '\nexport PATH="$(brew --prefix coreutils)/libexec/gnubin:$HOME/.local/bin:$PATH"\n' >> "$HOME/.zshrc"
```

Open a new Terminal window, then install and initialize `rolia-cli` from the
repository:

```sh
git clone https://github.com/vmxt/rolia-cli.git
cd rolia-cli
./install.sh
rolia-cli init
```

The built-in macOS `open` command is used to open chapter PDFs. If Homebrew
does not provide a dependency under the name shown above, install the
equivalent package and ensure its command is on `PATH`.

## Linux distributions other than Ubuntu or Debian

Install the equivalent packages using your distribution's package manager.
Required commands are `curl`, `fzf`, `jq`, GNU `md5sum` (`coreutils`),
`ffmpeg`, `img2pdf`, `lsof`, and a PDF opener such as `xdg-open`, `gio`, or
macOS `open`.
Package names and repository availability differ by distribution; search
your distribution's package repositories for `img2pdf` if its package name
differs.

Examples for the common command-line dependencies:

```sh
# Fedora
sudo dnf install git curl fzf jq coreutils ffmpeg lsof xdg-utils

# Arch Linux
sudo pacman -S git curl fzf jq coreutils ffmpeg lsof xdg-utils

# openSUSE
sudo zypper install git curl fzf jq coreutils ffmpeg lsof xdg-utils
```

Also install `img2pdf` from your distribution's repository. If it is not
packaged, install it with `pipx` using your distribution's instructions for
installing `pipx`, then run:

```sh
pipx ensurepath
pipx install img2pdf
```

If `pipx` is not already on `PATH`, run `pipx ensurepath` and open a new
terminal before continuing.

After installing dependencies, clone the repository and run the installer:

```sh
git clone https://github.com/vmxt/rolia-cli.git
cd rolia-cli
./install.sh
rolia-cli init
```

`rolia-cli init` checks whether the required commands are available. It prints
an `apt` installation command on Debian-based systems and generic package
manager guidance on other systems.

## iOS

There is no supported native iOS installation. iOS does not provide the
standard POSIX shell, command-line dependencies, or desktop PDF-viewer
integration this application requires. Shell environments available on
iOS may not provide all dependencies or support opening and cleaning up
PDFs, so the Linux/macOS installation instructions should not be applied
directly to iOS.

# dotfiles-chezmoi

My personal Fedora/Nobara setup, managed with [chezmoi](https://www.chezmoi.io/) and [Bitwarden](https://bitwarden.com/). This is for future-me rebuilding a machine from scratch. Nothing here is meant to be reusable by anyone else.

Scripts gate on `.chezmoi.osRelease.id` and will no-op on anything that isn't `fedora` or `nobara`.

## The one command

Reinstall Nobara, log into KDE, connect to wifi once via the network applet, open a terminal, and run:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/aaddrick/dotfiles-chezmoi/main/bootstrap.sh)
```

That's the whole fresh-machine flow. Two interactive prompts along the way:

1. Your sudo password, once, so the bootstrap can write `/etc/sudoers.d/90-$USER-nopasswd`. Every sudo call after that is non-interactive.
2. Your Bitwarden master password, once, to unlock the vault.

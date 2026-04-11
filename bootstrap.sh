#!/usr/bin/env bash
# Fresh-laptop bootstrap for aaddrick/dotfiles-chezmoi.
#
# Usage on a new machine:
#   bash <(curl -fsSL https://raw.githubusercontent.com/aaddrick/dotfiles-chezmoi/main/bootstrap.sh)
# or, after cloning the repo manually:
#   ./bootstrap.sh
#
# Prereqs: sudo access (for chezmoi install on Fedora/Nobara), interactive TTY
# (for bw login/unlock prompts).

set -euo pipefail

REPO="https://github.com/aaddrick/dotfiles-chezmoi.git"

log() { printf '\033[1;34m[bootstrap]\033[0m %s\n' "$*"; }
die() { printf '\033[1;31m[bootstrap error]\033[0m %s\n' "$*" >&2; exit 1; }

# 0. Passwordless sudo --------------------------------------------------------
# Done first so every subsequent sudo call (dnf install, chezmoi apply scripts)
# is non-interactive. This is the one and only sudo password prompt of the
# whole bootstrap.
USER_NAME="$(id -un)"
SUDOERS_FILE="/etc/sudoers.d/90-${USER_NAME}-nopasswd"
# `sudo -n test -f` checks both (a) sudo works without prompting and (b) the
# rule file actually exists — avoids the credential-cache false positive where
# `sudo -n true` succeeds just because a prior sudo call is still cached.
if sudo -n test -f "$SUDOERS_FILE" 2>/dev/null; then
  log "Passwordless sudo already configured ($SUDOERS_FILE)"
else
  log "Configuring passwordless sudo for ${USER_NAME} (one password prompt)"
  TMP_SUDOERS="$(mktemp)"
  printf '%s ALL=(ALL) NOPASSWD: ALL\n' "$USER_NAME" > "$TMP_SUDOERS"
  if ! sudo visudo -c -f "$TMP_SUDOERS" >/dev/null; then
    rm -f "$TMP_SUDOERS"
    die "generated sudoers snippet failed visudo validation"
  fi
  sudo install -o root -g root -m 0440 "$TMP_SUDOERS" "$SUDOERS_FILE"
  rm -f "$TMP_SUDOERS"
  sudo -n true 2>/dev/null || die "passwordless sudo still not working after writing $SUDOERS_FILE"
  log "Passwordless sudo active"
fi

# Bootstrap is staged so that every secret the repo needs is on disk BEFORE
# chezmoi touches anything:
#   1. Bitwarden CLI
#   2. Bitwarden login + unlock
#   3. Age identity fetched into ~/.config/chezmoi/key.txt
#   4. chezmoi itself
#   5. chezmoi init + apply
# That way `chezmoi init --apply` has age decryption ready on its first run
# and never fails partway through for missing keys.

# 1. Bitwarden CLI ------------------------------------------------------------
if ! command -v bw >/dev/null 2>&1; then
  log "Installing Bitwarden CLI"
  if command -v npm >/dev/null 2>&1; then
    npm install -g @bitwarden/cli
  else
    tmpd=$(mktemp -d)
    trap 'rm -rf "$tmpd"' EXIT
    curl -fsSL "https://vault.bitwarden.com/download/?app=cli&platform=linux" -o "$tmpd/bw.zip"
    command -v unzip >/dev/null 2>&1 || die "unzip required; install it (sudo dnf install unzip) and re-run"
    unzip -q "$tmpd/bw.zip" -d "$tmpd"
    mkdir -p "$HOME/bin"
    mv "$tmpd/bw" "$HOME/bin/bw"
    chmod +x "$HOME/bin/bw"
    export PATH="$HOME/bin:$PATH"
    trap - EXIT; rm -rf "$tmpd"
  fi
else
  log "bw already installed: $(command -v bw)"
fi

# 2. Bitwarden login + unlock -------------------------------------------------
bw_status=$(bw status 2>/dev/null || echo '{"status":"unauthenticated"}')
case "$bw_status" in
  *'"status":"unauthenticated"'*)
    log "Logging in to Bitwarden (interactive)"
    bw login
    ;;
  *'"status":"locked"'*)
    log "Bitwarden vault is locked"
    ;;
  *'"status":"unlocked"'*)
    log "Bitwarden already unlocked"
    ;;
esac

if ! bw status 2>/dev/null | grep -q '"status":"unlocked"'; then
  log "Unlocking vault"
  BW_SESSION=$(bw unlock --raw)
  export BW_SESSION
fi

# 3. Age identity (chezmoi encryption key) ------------------------------------
# The identity is stored in Bitwarden as secure note `chezmoi-age-key`
# (item UUID below). Pinning by UUID avoids name-ambiguity footguns.
AGE_KEY_PATH="$HOME/.config/chezmoi/key.txt"
AGE_KEY_ITEM_ID="ca358ae2-b635-4501-b2f2-b42900b63521"
if [ -s "$AGE_KEY_PATH" ]; then
  log "Age identity already present at $AGE_KEY_PATH"
else
  log "Fetching age identity from Bitwarden into $AGE_KEY_PATH"
  mkdir -p "$(dirname "$AGE_KEY_PATH")"
  # `install -m 0600 /dev/null` creates an empty file with strict perms
  # BEFORE we write the secret to it, so the secret never briefly lives at
  # the default umask. Then append the note contents to that same file.
  install -m 0600 /dev/null "$AGE_KEY_PATH"
  if ! bw get notes "$AGE_KEY_ITEM_ID" > "$AGE_KEY_PATH"; then
    rm -f "$AGE_KEY_PATH"
    die "failed to fetch age identity from Bitwarden (item $AGE_KEY_ITEM_ID)"
  fi
  # bw get notes strips the trailing newline; re-add for cleanliness.
  printf '\n' >> "$AGE_KEY_PATH"
  [ -s "$AGE_KEY_PATH" ] || die "fetched age identity is empty"
  log "Age identity written ($(wc -c <"$AGE_KEY_PATH") bytes)"
fi

# 4. chezmoi ------------------------------------------------------------------
if ! command -v chezmoi >/dev/null 2>&1; then
  log "Installing chezmoi"
  if command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y chezmoi
  else
    mkdir -p "$HOME/bin"
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/bin"
    export PATH="$HOME/bin:$PATH"
  fi
else
  log "chezmoi already installed: $(command -v chezmoi)"
fi

# 5. chezmoi init + apply -----------------------------------------------------
if [ ! -d "$HOME/.local/share/chezmoi/.git" ]; then
  log "Running chezmoi init --apply against $REPO"
  chezmoi init --apply "$REPO"
else
  log "chezmoi source already cloned; running apply"
  chezmoi apply
fi

log "Done."
echo
echo "Next steps:"
echo "  - Open a new terminal (or 'source ~/.bashrc') to pick up the new env"
echo "  - Restore GPG signing keys if needed: fetch 'gpg-claude-desktop-debian' /"
echo "    'gpg-selkie' / 'gpg-ownertrust' attachments/notes from Bitwarden"
echo "    and run 'gpg --import <file>' + 'gpg --import-ownertrust <file>'"

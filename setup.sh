#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${HOME}/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
DRY_RUN=0

log() { printf '%s\n' "$*"; }

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    *) log "Unknown argument: $arg"; exit 1 ;;
  esac
done

has_cmd() { command -v "$1" >/dev/null 2>&1; }
run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    log "  [dry-run] $*"
  else
    "$@"
  fi
}

backup_if_exists() {
  local target="$1"
  local src="$2"
  if [ -e "$target" ] || [ -L "$target" ]; then
    if [ -L "$target" ] && [ "$(readlink "$target")" = "$src" ]; then
      return
    fi
    if [ "$DRY_RUN" -eq 1 ]; then
      log "  [dry-run] mv \"$target\" \"$BACKUP_DIR/\""
    else
      mkdir -p "$BACKUP_DIR"
      mv "$target" "$BACKUP_DIR/"
    fi
  fi
}

link_dotfile() {
  local src="$1"
  local dest="$2"
  backup_if_exists "$dest" "$src"
  run ln -sfn "$src" "$dest"
}

log "Linking dotfiles from $REPO_DIR"
link_dotfile "$REPO_DIR/.vim" "$HOME/.vim"
link_dotfile "$REPO_DIR/.vimrc" "$HOME/.vimrc"
link_dotfile "$REPO_DIR/.tmux.conf" "$HOME/.tmux.conf"
link_dotfile "$REPO_DIR/.tmux.dev" "$HOME/.tmux.dev"
link_dotfile "$REPO_DIR/.zshrc" "$HOME/.zshrc"

log "Installing vim-plug (if missing)"
if [ ! -f "$HOME/.vim/autoload/plug.vim" ]; then
  if has_cmd curl; then
    run curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  elif has_cmd wget; then
    run mkdir -p "$HOME/.vim/autoload"
    run wget -O "$HOME/.vim/autoload/plug.vim" \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  else
    log "  curl/wget not found; skip vim-plug install"
  fi
fi

log "Installing oh-my-zsh (if missing)"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  if has_cmd curl; then
    if [ "$DRY_RUN" -eq 1 ]; then
      log "  [dry-run] oh-my-zsh install via curl"
    else
      RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    fi
  elif has_cmd wget; then
    if [ "$DRY_RUN" -eq 1 ]; then
      log "  [dry-run] oh-my-zsh install via wget"
    else
      RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
        sh -c "$(wget -qO- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    fi
  else
    log "  curl/wget not found; skip oh-my-zsh install"
  fi
fi

if [ -d "$HOME/.oh-my-zsh" ]; then
  log "Installing my-hyperzsh theme"
  run mkdir -p "$HOME/.oh-my-zsh/themes"
  link_dotfile "$REPO_DIR/my-hyperzsh.zsh-theme" "$HOME/.oh-my-zsh/themes/my-hyperzsh.zsh-theme"
fi

log "Installing tmux plugin manager (if missing)"
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  if has_cmd git; then
    run git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
  else
    log "  git not found; skip tpm install"
  fi
fi

log "Setting ZSH_THEME to my-hyperzsh (if possible)"
if [ -f "$HOME/.zshrc" ]; then
  if has_cmd perl; then
    run perl -pi -e 's/^ZSH_THEME=.*/ZSH_THEME="my-hyperzsh"/' "$HOME/.zshrc"
  else
    log "  perl not found; update ZSH_THEME manually if needed"
  fi
fi

if [ -n "${BACKUP_DIR}" ] && [ -d "${BACKUP_DIR}" ]; then
  log "Backups saved to: $BACKUP_DIR"
fi

log "Done. Restart your shell or run: exec zsh"

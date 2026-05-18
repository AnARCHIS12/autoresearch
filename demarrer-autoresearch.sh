#!/usr/bin/env sh
set -u

APP_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
APP_URL="http://127.0.0.1:8010/index.php"
PORT="8010"
PATH="$HOME/.local/bin:$PATH"
export PATH

say() {
  printf "\n== %s ==\n" "$1"
}

pause_exit() {
  printf "\nAppuyez sur Entree pour fermer cette fenetre..."
  read -r _ 2>/dev/null || true
}

fail() {
  printf "\nErreur: %s\n" "$1" >&2
  pause_exit
  exit 1
}

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

is_linux() {
  [ "$(uname -s 2>/dev/null)" = "Linux" ]
}

is_macos() {
  [ "$(uname -s 2>/dev/null)" = "Darwin" ]
}

run_root() {
  if has_cmd sudo; then
    sudo "$@"
  elif has_cmd pkexec; then
    pkexec "$@"
  else
    return 1
  fi
}

install_php_if_possible() {
  if has_cmd php; then
    return 0
  fi

  say "PHP est absent, tentative d'installation"
  if has_cmd dnf; then
    run_root dnf install -y php-cli php-pdo php-sqlite3 php-curl || return 1
  elif has_cmd apt-get; then
    run_root apt-get update || return 1
    run_root apt-get install -y php-cli php-sqlite3 php-curl || return 1
  elif has_cmd pacman; then
    run_root pacman -Sy --noconfirm php php-sqlite || return 1
  elif has_cmd zypper; then
    run_root zypper install -y php8 php8-sqlite php8-curl || return 1
  elif is_macos && has_cmd brew; then
    brew install php || return 1
  else
    return 1
  fi
}

install_dockan_if_possible() {
  if has_cmd dockan; then
    return 0
  fi
  is_linux || return 1

  say "Dockan est absent, installation utilisateur"
  has_cmd curl || return 1
  curl -fsSL https://raw.githubusercontent.com/Dockan-Conteneurisation-libre/Dockan/main/scripts/install.sh | sh || return 1
  PATH="$HOME/.local/bin:$PATH"
  export PATH
  has_cmd dockan
}

open_browser() {
  if has_cmd xdg-open; then
    xdg-open "$APP_URL" >/dev/null 2>&1 &
  elif has_cmd gio; then
    gio open "$APP_URL" >/dev/null 2>&1 &
  elif is_macos && has_cmd open; then
    open "$APP_URL" >/dev/null 2>&1 &
  else
    printf "\nOuvrez cette adresse dans le navigateur:\n%s\n" "$APP_URL"
  fi
}

port_is_open() {
  if has_cmd curl; then
    curl -fsS "$APP_URL" >/dev/null 2>&1
  else
    return 1
  fi
}

start_with_dockan() {
  install_dockan_if_possible || return 1
  say "Demarrage avec Dockan"
  dockan compose down >/dev/null 2>&1 || true
  dockan compose up || return 1
  sleep 1
  port_is_open
}

start_with_php() {
  install_php_if_possible || fail "PHP est absent. Installez PHP 8 avec SQLite/cURL, puis relancez ce fichier."
  say "Demarrage avec PHP local"
  if port_is_open; then
    return 0
  fi
  nohup php -S "127.0.0.1:${PORT}" -t "$APP_DIR" "$APP_DIR/index.php" > "$APP_DIR/logs/php-server.log" 2>&1 &
  sleep 2
  port_is_open || fail "Le serveur PHP n'a pas demarre. Consultez logs/php-server.log."
}

say "Preparation d'Autoresearch"
cd "$APP_DIR" || fail "Dossier introuvable: $APP_DIR"
mkdir -p "$APP_DIR/logs" "$APP_DIR/data" "$APP_DIR/generated_apps"

if is_linux && start_with_dockan; then
  say "Autoresearch tourne avec Dockan"
else
  start_with_php
fi

say "Ouverture du navigateur"
open_browser

printf "\nAutoresearch est lance:\n%s\n\n" "$APP_URL"
printf "Vous pouvez fermer cette fenetre.\n"
sleep 3

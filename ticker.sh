#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$ROOT_DIR/lib"

source "$LIB_DIR/core.sh"
source "$LIB_DIR/utils.sh"
source "$LIB_DIR/config.sh"
source "$LIB_DIR/api.sh"
source "$LIB_DIR/cache.sh"
source "$LIB_DIR/widget.sh"
source "$LIB_DIR/backend.sh"
source "$LIB_DIR/menu.sh"

# --update-once: sadece cache üret ve çık (timer çağırır)
if [[ "${1:-}" == "--update-once" ]]; then
  ensure_deps
  config_load
  render_once
  exit 0
fi

main(){ menu_main; }
main "$@"

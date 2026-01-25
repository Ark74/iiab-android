# shellcheck shell=bash
# Module file (no shebang). Bundled by build_bundle.sh

RED="\033[31m"; YEL="\033[33m"; GRN="\033[32m"; BLU="\033[34m"; RST="\033[0m"; BOLD="\033[1m"

log()      { printf "${BLU}[iiab]${RST} %s\n" "$*"; }
ok()       { printf "${GRN}[iiab]${RST} %s\n" "$*"; }
warn()     { printf "${YEL}[iiab] WARNING:${RST} %s\n" "$*" >&2; }
warn_red() { printf "${RED}${BOLD}[iiab] WARNING:${RST} %s\n" "$*" >&2; }
indent()   { sed 's/^/ /'; }

have() { command -v "$1" >/dev/null 2>&1; }
need() { have "$1" || return 1; }
die()  { echo "[!] $*" >&2; exit 1; }

blank() {
  local n="${1:-1}" fd=1
  [[ "$n" =~ ^[0-9]+$ ]] || n=1
  if { : >&3; } 2>/dev/null; then fd=3; fi
  while (( n-- > 0 )); do printf '\n' >&"$fd"; done
}

# Choose warning level depending on context.
# - In explicit readiness checks (--check/--all), use red for "will likely fail".
# - In passive/self-check (baseline runs), keep it yellow to avoid over-alarming.
warn_red_context() {
  # args: long message
  if [[ "${MODE:-}" == "check" || "${MODE:-}" == "all" || "${MODE:-}" == "ppk-only" ]]; then
    warn_red "$*"
  else
    warn "$*"
  fi
}

# -------------------------
# Global defaults (may be overridden via environment)
# -------------------------
STATE_DIR="${STATE_DIR:-${HOME}/.iiab-android}"
ADB_STATE_DIR="${ADB_STATE_DIR:-${STATE_DIR}/adbw_pair}"
LOG_DIR="${LOG_DIR:-${STATE_DIR}/logs}"

HOST="${HOST:-127.0.0.1}"
CONNECT_PORT="${CONNECT_PORT:-}"
TIMEOUT_SECS="${TIMEOUT_SECS:-180}"

# Defaults used by ADB flows / logging / misc
CLEANUP_OFFLINE="${CLEANUP_OFFLINE:-1}"
DEBUG="${DEBUG:-0}"

# Package name for the Termux app.
TERMUX_PACKAGE="${TERMUX_PACKAGE:-com.termux}"

# One-time helper: guide user to set Termux battery policy to keep sessions alive.
POWER_MODE_BATTERY_PROMPT="${POWER_MODE_BATTERY_PROMPT:-1}"  # 1=ask, 0=never ask
POWER_MODE_BATTERY_STAMP="${POWER_MODE_BATTERY_STAMP:-$STATE_DIR/stamp.termux_battery_settings}"

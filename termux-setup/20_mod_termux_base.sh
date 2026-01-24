# shellcheck shell=bash
# Module file (no shebang). Bundled by build_bundle.sh

# If baseline fails, store the last command that failed for better diagnostics.
BASELINE_ERR=""

baseline_prereqs_ok() {
  have proot-distro && have adb && have termux-notification && have termux-dialog && have sha256sum
}

baseline_missing_prereqs() {
  for b in adb proot-distro termux-notification termux-dialog; do
    have "$b" || echo "$b"
  done
  have sha256sum || echo "sha256sum (coreutils)"
}

baseline_bail_details() {
  warn "Baseline package installation failed (network / repo unreachable or packages missing)."
  [[ -n "${BASELINE_ERR:-}" ]] && warn "Last failing command: ${BASELINE_ERR}"
  local miss=()
  mapfile -t miss < <(baseline_missing_prereqs || true)
  ((${#miss[@]})) && warn "Missing prerequisites: ${miss[*]}"
  warn "Not stamping; rerun later when prerequisites are available."
}

# Termux apt options (avoid conffile prompts)
TERMUX_APT_OPTS=( "-y" "-o" "Dpkg::Options::=--force-confdef" "-o" "Dpkg::Options::=--force-confold" )
termux_apt() { apt-get "${TERMUX_APT_OPTS[@]}" "$@"; }

# -------------------------
# Android info
# -------------------------
get_android_sdk()     { getprop ro.build.version.sdk 2>/dev/null || true; }
get_android_release() { getprop ro.build.version.release 2>/dev/null || true; }
ANDROID_SDK="$(get_android_sdk)"
ANDROID_REL="$(get_android_release)"

# -------------------------
# Wakelock (Termux:API)
# -------------------------
WAKELOCK_HELD=0
acquire_wakelock() {
  if have termux-wake-lock; then
    if termux-wake-lock; then
      WAKELOCK_HELD=1
      ok "Wakelock acquired (termux-wake-lock)."
    else
      warn "Failed to acquire wakelock (termux-wake-lock)."
    fi
  else
    warn "termux-wake-lock not available. Install: pkg install termux-api + Termux:API app."
  fi
}
release_wakelock() {
  if [[ "$WAKELOCK_HELD" -eq 1 ]] && have termux-wake-unlock; then
    termux-wake-unlock || true
    ok "Wakelock released (termux-wake-unlock)."
    WAKELOCK_HELD=0
  fi
}

# -------------------------
# Set Battery usage step.
# -------------------------
android_am_bin() {
  # Return a usable 'am' binary path.
  if have am; then
    command -v am
    return 0
  fi
  [[ -x /system/bin/am ]] && { echo /system/bin/am; return 0; }
  return 1
}

android_start_activity() {
  # Start an Android activity via 'am'.
  local ambin
  ambin="$(android_am_bin 2>/dev/null)" || return 1
  "$ambin" start "$@" >/dev/null 2>&1
}

android_open_termux_app_info() {
  # Open Settings -> App info -> Termux (most standard across vendors).
  android_start_activity -a android.settings.APPLICATION_DETAILS_SETTINGS -d "package:${TERMUX_PACKAGE}"
}

android_open_battery_optimization_list() {
  # Optional fallback screen (varies by vendor).
  android_start_activity -a android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS
}

power_mode_battery_instructions() {
  {
    # Print header in blue + bold
    printf '%b' "${YEL}${BOLD}"
    cat <<'EOF'
[iiab] Power-mode needs one manual Android setting:
EOF

    # Print body in blue
    printf '%b' "${BLU}"
    cat <<'EOF'
 Settings -> Apps -> Termux -> Battery
   - Set: Unrestricted
     - or: Don't optimize / No restrictions
   - Allow background activity = ON (if present)

 If you can't find Battery under App info, use Android's Battery optimization list and set Termux to "Don't optimize".

> Note: Power-mode (wakelock + notification) helps keep the session alive, but it cannot override Android's battery restrictions.

EOF

    # Reset colors
    printf '%b' "${RST}"
  } >&3
}

power_mode_offer_battery_settings_once() {
  [[ "${POWER_MODE_BATTERY_PROMPT:-1}" -eq 1 ]] || return 0
  mkdir -p "$STATE_DIR" >/dev/null 2>&1 || true

  local stamp="$POWER_MODE_BATTERY_STAMP"
  [[ -f "$stamp" ]] && return 0

  power_mode_battery_instructions

  if tty_yesno_default_y "${YEL}[iiab] Open Termux App info to adjust Battery policy?${RST} [Y/n]: "; then
    if android_open_termux_app_info; then
      printf "[iiab] When done, return to Termux and press Enter to continue... " >&3
      if [[ -r /dev/tty ]]; then
        read -r _ </dev/tty || true
      else
        printf "\n" >&3
      fi
      date > "$stamp" 2>/dev/null || true
    else
      warn "Unable to open Settings automatically. Open manually: Settings -> Apps -> Termux."
      warn "Fallback: you may try opening the Battery optimization list from Android settings."
      # Best-effort fallback (ignore errors)
      android_open_battery_optimization_list || true
      # Do not stamp here: user likely still needs to configure it.
    fi
  else
    warn "Battery settings step skipped by user; you'll be asked again next time."
  fi
  return 0
}

# -------------------------
# One-time repo selector
# -------------------------
step_termux_repo_select_once() {
  local stamp="$STATE_DIR/stamp.termux_repo_selected"
  [[ -f "$stamp" ]] && return 0
  if ! have termux-change-repo; then
    warn "termux-change-repo not found; skipping mirror selection."
    return 0
  fi

  local did_run=0

  if [[ -r /dev/tty ]]; then
    printf "\n${YEL}[iiab] One-time setup:${RST} Select a nearby Termux repository mirror for faster downloads.\n"
    local ans="Y"
    printf "[iiab] Launch termux-change-repo now? [Y/n]: "
    if ! IFS= read -r ans < /dev/tty; then
      warn "No interactive TTY available; skipping mirror selection (run 'termux-change-repo' directly to be prompted)."
      return 0
    fi
    ans="${ans:-Y}"
    if [[ "$ans" =~ ^[Yy]$ ]]; then
      # Run interactive UI against /dev/tty and original console fds (3/4).
      if termux-change-repo </dev/tty >&3 2>&4; then
        did_run=1
      fi
      ok "Mirror selection completed (or skipped inside the UI)."
    else
      warn "Mirror selection skipped by user."
    fi
    if (( did_run )); then
      date > "$stamp"
    else
      warn "Mirror not selected yet; you'll be asked again next run."
    fi
    return 0
  fi

  warn "No /dev/tty available; skipping mirror selection."
  return 0
}

# -------------------------
# Baseline packages
# -------------------------
step_termux_base() {
  local stamp="$STATE_DIR/stamp.termux_base"

  BASELINE_OK=0

  # Even if we have a stamp, validate that core commands still exist.
  if [[ -f "$stamp" ]]; then
    if baseline_prereqs_ok; then
      BASELINE_OK=1
      ok "Termux baseline already prepared (stamp found)."
      return 0
    fi
    warn "Baseline stamp found but prerequisites are missing; forcing reinstall."
    rm -f "$stamp"
  fi

  log "Updating Termux packages (noninteractive) and installing baseline dependencies..."
  export DEBIAN_FRONTEND=noninteractive

  if ! termux_apt update; then
    BASELINE_ERR="termux_apt update"
    baseline_bail_details
    return 1
  fi

  if ! termux_apt upgrade; then
    BASELINE_ERR="termux_apt upgrade"
    baseline_bail_details
    return 1
  fi

  if ! termux_apt install \
    android-tools \
    ca-certificates \
    coreutils \
    curl \
    gawk \
    grep \
    openssh \
    proot \
    proot-distro \
    sed \
    termux-api \
    which
  then
    BASELINE_ERR="termux_apt install (baseline deps)"
    baseline_bail_details
    return 1
  fi

  if baseline_prereqs_ok; then
    BASELINE_OK=1
    ok "Termux baseline ready."
    date > "$stamp"
    return 0
  fi

  BASELINE_ERR="post-install check (commands missing after install)"
  baseline_bail_details
  return 1
}

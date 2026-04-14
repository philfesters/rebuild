#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════
#   ARSENAL  |  Unified Termux Command Hub  |  REBUILD V2
#   Compiled from: detox | termux-repair | recover | rebuild
#   Strategy Over Impulse | philfesters | Ravensmead, Cape Town | 999
#   Brought to you by Grant Fezzy Festers  |  Bojack [K9]  |  SOI
# ══════════════════════════════════════════════════════════════════════

export PATH=$PREFIX/bin:$HOME/.local/bin:$PATH

# -- Self-aware paths - update STATION_SCRIPT if you rename fezzy_station
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)/$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
STATION_SCRIPT="${STATION_SCRIPT:-$HOME/fezzy_station_v61.sh}"
ARSENAL_SCRIPT="$SCRIPT_PATH"

# -- Colors -------------------------------------------------------------
RESET='\033[0m';   BOLD='\033[1m'
PINK='\033[38;5;213m'    # Juice - soft pink
HOT='\033[38;5;198m'     # Juice - hot pink
PURP='\033[38;5;135m'    # Uzi  - purple
VIOLET='\033[38;5;93m'   # Uzi  - deep violet
CYAN='\033[38;5;51m'     # Uzi  - electric cyan
ELEC='\033[38;5;39m'     # Uzi  - electric blue
GRN='\033[38;5;46m'      # success
YEL='\033[38;5;226m'     # warning
RED='\033[38;5;196m'     # error
FADE='\033[38;5;240m'    # dim
WH='\033[97m'            # white
LIME='\033[38;5;154m'    # lime

# -- Dividers -----------------------------------------------------------
_dv()  { local c; c=$(tput cols 2>/dev/null||echo 60); printf "${HOT}${BOLD}";  printf "%${c}s" | tr " " "="; printf "${RESET}\n"; }
_dvc() { local c; c=$(tput cols 2>/dev/null||echo 60); printf "${CYAN}";        printf "%${c}s" | tr " " "-"; printf "${RESET}\n"; }
_dvp() { local c; c=$(tput cols 2>/dev/null||echo 60); printf "${PURP}";        printf "%${c}s" | tr " " "="; printf "${RESET}\n"; }
_dvv() { local c; c=$(tput cols 2>/dev/null||echo 60); printf "${VIOLET}";      printf "%${c}s" | tr " " "."; printf "${RESET}\n"; }
_dvf() { local c; c=$(tput cols 2>/dev/null||echo 60); printf "${FADE}";        printf "%${c}s" | tr " " "."; printf "${RESET}\n"; }

# -- Output helpers -----------------------------------------------------
ok()   { printf "  ${GRN}[OK]${RESET}  ${WH}%s${RESET}\n" "$1"; }
warn() { printf "  ${YEL}[!!]${RESET}  ${YEL}%s${RESET}\n" "$1"; }
fail() { printf "  ${RED}[XX]${RESET}  ${RED}%s${RESET}\n" "$1"; }
info() { printf "  ${CYAN}>>${RESET}  ${WH}%s${RESET}\n" "$1"; }
tip()  { printf "  ${FADE}  >>  %s${RESET}\n" "$1"; }
ref()  { printf "  ${PURP}>>${RESET}  ${WH}%s${RESET}\n" "$1"; }

# -- Module banner - called at top of every module ---------------------
_banner() {
    clear; echo ""
    _dv
    printf "  ${HOT}${BOLD}REBUILD V2${RESET}  ${FADE}.${RESET}  ${PURP}${BOLD}%s${RESET}\n" "$1"
    printf "  ${FADE}[m] Menu  [b] Back  [s] Search  [q] Quit${RESET}\n"
    _dv; echo ""
}

# -- Section header -----------------------------------------------------
_section() {
    echo ""
    _dvc
    printf "  ${CYAN}${BOLD}%s${RESET}\n" "$1"
    _dvc; echo ""
}

# -- Synopsis block - shown before interactive prompt ------------------
_synopsis() {
    _dvp
    printf "  ${VIOLET}${BOLD}[ SYNOPSIS ]${RESET}\n"
    printf "  ${WH}%s${RESET}\n" "$1"
    _dvp; echo ""
}

# -- Universal navigation - replaces _pause everywhere -----------------
_nav() {
    echo ""
    _dvf
    printf "  ${HOT}${BOLD}[ENTER]${RESET} Done  ${PINK}[m]${RESET} Menu  ${PURP}[b]${RESET} Back  ${CYAN}[s]${RESET} Search  ${FADE}[q]${RESET} Quit  > "
    read -r _nc
    case "${_nc,,}" in
        m) _show_menu ;;
        q) _quit ;;
        s) _mod_search ;;
        b) return 0 ;;
        *) _show_menu ;;
    esac
}
_pause() { _nav; }

# -- Ask yes/no ---------------------------------------------------------
_ask() {
    printf "  ${HOT}${BOLD}[y]${RESET} ${WH}Yes  ${HOT}${BOLD}[n]${RESET} ${WH}No${RESET}  ${PINK}>${RESET}  "
    read -r _ans; echo ""
    [[ "${_ans,,}" == "y" || "${_ans,,}" == "yes" ]]
}

# -- Spinner - pure bash, no gum dep ------------------------------------
_spin() {
    local label="$1"; shift
    local cmd="$*"
    local frames='/-\\|/-\\|'
    local log_file="${TMPDIR:-$PREFIX/tmp}/_ar_spin_$$.log"
    bash -c "$cmd" > "$log_file" 2>&1 &
    local pid=$! i=0
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r  ${PINK}${frames:$((i % 8)):1}${RESET}  ${WH}%s${RESET}   " "$label"
        sleep 0.12; (( i++ ))
    done
    wait "$pid"; local rc=$?
    local c; c=$(tput cols 2>/dev/null||echo 60)
    printf "\r%${c}s\r" ""
    if [[ $rc -eq 0 ]]; then
        printf "  ${GRN}[OK]${RESET}  ${WH}%s${RESET}\n" "$label"
    else
        printf "  ${YEL}[!!]${RESET}  ${WH}%s${RESET}  ${RED}^ check manually${RESET}\n" "$label"
        tail -2 "$log_file" 2>/dev/null | grep -v '^$' | while read -r l; do
            printf "  ${RED}    %s${RESET}\n" "$l"
        done
    fi
    rm -f "$log_file" 2>/dev/null
    return $rc
}

# -- Gum spinner with braille fallback ---------------------------------
_gspin() {
    local title="$1" cmd="$2"
    if command -v gum &>/dev/null; then
        gum spin --spinner dot --title "  ${CYAN}${title}${RESET}" -- bash -c "$cmd"
        local rc=$?
    else
        bash -c "$cmd" > /tmp/_ar_gs.log 2>&1 &
        local pid=$! i=0 sp='/-\\|/-\\|/-'
        while kill -0 "$pid" 2>/dev/null; do
            printf "\r  ${FADE}${sp:$((i%10)):1}${RESET}  ${WH}%s${RESET}   " "$title"
            sleep 0.12; (( i++ ))
        done
        wait "$pid"; local rc=$?
        local c; c=$(tput cols 2>/dev/null||echo 60)
        printf "\r%${c}s\r" ""
    fi
    [[ $rc -eq 0 ]] && ok "$title" || warn "$title - check manually"
    return $rc
}

# -- Progress bar -------------------------------------------------------
_pbar() {
    local label="$1" width=28
    printf "  ${FADE}%-22s${RESET}  ${PURP}" "$label"
    for (( i=0; i<width; i++ )); do printf "#"; sleep 0.025; done
    printf "${RESET}  ${GRN}[OK]${RESET}\n"
}

# -- Typewriter ---------------------------------------------------------
_type() {
    local color="$1" text="$2" delay="${3:-0.006}"
    printf "${color}"
    while IFS= read -r -n1 ch; do printf "%s" "$ch"; sleep "$delay"; done <<< "$text"
    printf "${RESET}\n"
}

# -- Glitch flicker - pure ASCII, Termux-safe --------------------------
_glitch_line() {
    local c; c=$(tput cols 2>/dev/null||echo 60)
    local glyphs=('/\/\ /\/\' '\/\/ \/\/' '---- ----' '==== ====')
    local i=0
    for g in "${glyphs[@]}"; do
        printf "\r  ${VIOLET}%s${RESET}" "$g"
        sleep 0.07
    done
    printf "\r%${c}s\r" ""
}

# -- Safe pkg/pip helpers -----------------------------------------------
safe_pkg() { _gspin "Installing $1" "pkg install -y '$1' >/dev/null 2>&1"; }
safe_pip() { _gspin "pip | $1"      "pip install '$1' --break-system-packages -q --no-build-isolation 2>/dev/null"; }

# -- Quit --------------------------------------------------------------
_quit() {
    echo ""
    _dv
    printf "  ${PURP}${BOLD}Strategy Over Impulse  |  999  |  Bojack [K9]  |  Ravensmead${RESET}\n"
    _dv; echo ""
    exit 0
}

# ══════════════════════════════════════════════════════════════════════
#  BOOT SEQUENCE
# ══════════════════════════════════════════════════════════════════════
_boot() {
    clear; echo ""
    _dvp
    printf "${HOT}${BOLD}"
    printf "  ██████╗ ███████╗██████╗ ██╗   ██╗██╗██╗     ██████╗ \n"
    printf "${PINK}${BOLD}"
    printf "  ██╔══██╗██╔════╝██╔══██╗██║   ██║██║██║     ██╔══██╗\n"
    printf "${PURP}${BOLD}"
    printf "  ██████╔╝█████╗  ██████╔╝██║   ██║██║██║     ██║  ██║\n"
    printf "${VIOLET}${BOLD}"
    printf "  ██╔══██╗██╔══╝  ██╔══██╗██║   ██║██║██║     ██║  ██║\n"
    printf "${CYAN}${BOLD}"
    printf "  ██║  ██║███████╗██████╔╝╚██████╔╝██║███████╗██████╔╝\n"
    printf "${ELEC}${BOLD}"
    printf "  ╚═╝  ╚═╝╚══════╝╚═════╝  ╚═════╝ ╚═╝╚══════╝╚═════╝\n"
    printf "${RESET}"
    _dvp
    printf "  ${PURP}${BOLD}UNIFIED COMMAND HUB  V2${RESET}  ${FADE}|  Strategy Over Impulse  |  999${RESET}\n"
    printf "  ${FADE}Grant Fezzy Festers  |  Ravensmead, Cape Town  |  Bojack [K9]  |  SOI${RESET}\n"
    _dvp; echo ""

    # -- Glitch flicker before tips
    _glitch_line

    # -- Known Patterns block - no typewriter crawl, instant-print with padding
    printf "  ${CYAN}${BOLD}KNOWN PATTERNS${RESET}  ${FADE}|  what breaks  |  why  |  fixes inside${RESET}\n"
    _dvc; echo ""

    # C22 = red label, 20/20 = yellow label, body capped ~50 chars
    printf "  ${RED}[C22]${RESET}   ${FADE}pkg update: 404. Need to change repo.${RESET}\n"
    printf "          ${FADE}Repo page needs pkg to load.  Catch 22.${RESET}\n"
    sleep 0.07
    printf "  ${RED}[C22]${RESET}   ${FADE}termux-exec broken. Fix: pkg install${RESET}\n"
    printf "          ${FADE}termux-exec. Except you can't run pkg.${RESET}\n"
    sleep 0.07
    printf "  ${RED}[C22]${RESET}   ${FADE}gum needs network. Network check needs${RESET}\n"
    printf "          ${FADE}gum. We all saw it coming.${RESET}\n"
    sleep 0.07
    printf "  ${RED}[C22]${RESET}   ${FADE}Station blank on launch. Storage perm${RESET}\n"
    printf "          ${FADE}not set yet. Bojack warned you. Classic.${RESET}\n"
    sleep 0.07
    printf "  ${YEL}[20/20]${RESET} ${FADE}dpkg lock exists. apt not running.${RESET}\n"
    printf "          ${FADE}Lock says otherwise. Zero progress.${RESET}\n"
    sleep 0.07
    printf "  ${YEL}[20/20]${RESET} ${FADE}Go tools installed. Not found. GOPATH${RESET}\n"
    printf "          ${FADE}not in PATH. source ~/.bashrc. Obviously.${RESET}\n"
    sleep 0.07
    printf "  ${YEL}[20/20]${RESET} ${FADE}Worked Tuesday. Dead Wednesday. bashrc${RESET}\n"
    printf "          ${FADE}didn't load. One line. Every single time.${RESET}\n"
    sleep 0.07
    printf "  ${YEL}[20/20]${RESET} ${FADE}pip fails. Needs --break-system-packages.${RESET}\n"
    printf "          ${FADE}Breaks nothing. Needs the flag. Classic.${RESET}\n"
    sleep 0.07
    printf "  ${YEL}[20/20]${RESET} ${FADE}alias dl: not found. source ~/.bashrc.${RESET}\n"
    printf "          ${FADE}One line. Every reboot. Every time. 999.${RESET}\n"
    sleep 0.07
    printf "  ${YEL}[20/20]${RESET} ${FADE}Storage gone. Android killed it. Switch${RESET}\n"
    printf "          ${FADE}app. Tap Allow. Come back. SOI. 999.${RESET}\n"
    sleep 0.07

    echo ""; _dvc; echo ""

    # -- Loading bars
    printf "  ${VIOLET}${BOLD}Initialising ARSENAL...${RESET}\n\n"
    _pbar "Diagnostics      "
    _pbar "Repair Modules   "
    _pbar "DETOX Engine     "
    _pbar "Install Hub      "
    _pbar "Encyclopedia     "
    _pbar "Connectivity     "
    _pbar "Auto-Repair      "
    _pbar "Extras           "
    echo ""
    _dvf
    printf "  ${FADE}Broken pipes, lucid dreams - felt in the terminal.  999  SOI${RESET}\n"
    _dvf; echo ""
    printf "  ${HOT}${BOLD}[ENTER]${RESET}  ${WH}Enter the hub${RESET}    ${FADE}[q]  Quit${RESET}  >  "
    read -r _bootchoice
    [[ "${_bootchoice,,}" == "q" ]] && _quit
}

# ══════════════════════════════════════════════════════════════════════
#  MAIN MENU
# ══════════════════════════════════════════════════════════════════════
_show_menu() {
    clear; echo ""
    _dv
    printf "  ${HOT}${BOLD}REBUILD V2${RESET}  ${FADE}|  ARSENAL  |  SOI  |  Ravensmead  |  999${RESET}\n"
    printf "  ${FADE}[m] Menu  [s] Search  [q] Quit  [b] Back - active everywhere${RESET}\n"
    _dv; echo ""

    printf "  ${CYAN}${BOLD}A - DIAGNOSTICS & AUDIT${RESET}\n"
    printf "  ${HOT}[A1]${RESET}  ${WH}Environment Audit${RESET}         ${FADE}PATH | commands | Termux info | arch${RESET}\n"
    printf "  ${HOT}[A2]${RESET}  ${WH}Command Availability${RESET}      ${FADE}full toolkit scan | found / missing${RESET}\n"
    printf "  ${HOT}[A3]${RESET}  ${WH}System Info Report${RESET}        ${FADE}arch | RAM | storage | CPU | Android${RESET}\n"
    printf "  ${HOT}[A4]${RESET}  ${WH}Python Environment${RESET}        ${FADE}pip | packages | path | venv check${RESET}\n"
    echo ""

    printf "  ${CYAN}${BOLD}B - REPAIR & FIX${RESET}\n"
    printf "  ${PINK}[B1]${RESET}  ${WH}Package Manager Rescue${RESET}   ${FADE}dpkg | apt | lock fix | update | upgrade${RESET}\n"
    printf "  ${PINK}[B2]${RESET}  ${WH}Mirror Reset${RESET}             ${FADE}repo CDN | 404 fix | Cloudflare | offline${RESET}\n"
    printf "  ${PINK}[B3]${RESET}  ${WH}.bashrc Validator & Fixer${RESET} ${FADE}syntax check | auto-fix common patterns${RESET}\n"
    printf "  ${PINK}[B4]${RESET}  ${WH}Alias Repair & Explainer${RESET} ${FADE}check + explain every alias | rebuild${RESET}\n"
    printf "  ${PINK}[B5]${RESET}  ${WH}Storage Recovery${RESET}         ${FADE}/sdcard | symlinks | permission reset${RESET}\n"
    echo ""

    printf "  ${CYAN}${BOLD}C - PERFORMANCE & CLEAN${RESET}\n"
    printf "  ${PURP}[C1]${RESET}  ${WH}Performance & Freeze Fix${RESET} ${FADE}kill procs | cache | tmux survival guide${RESET}\n"
    printf "  ${PURP}[C2]${RESET}  ${WH}Process Manager${RESET}          ${FADE}view | kill by name or PID | RAM check${RESET}\n"
    printf "  ${PURP}[C3]${RESET}  ${WH}DETOX - Full Clean${RESET}       ${FADE}9 modules | cache | deps | history | junk${RESET}\n"
    echo ""

    printf "  ${CYAN}${BOLD}D - INSTALL & REBUILD${RESET}\n"
    printf "  ${VIOLET}[D1]${RESET}  ${WH}Core Environment Setup${RESET}  ${FADE}storage | repos | base packages | all tools${RESET}\n"
    printf "  ${VIOLET}[D2]${RESET}  ${WH}Security Hub Install${RESET}    ${FADE}nuclei | trivy | nikto | lynis | gobuster${RESET}\n"
    printf "  ${VIOLET}[D3]${RESET}  ${WH}Media Tools Install${RESET}     ${FADE}yt-dlp | gallery-dl | ffmpeg | mpv | spotdl${RESET}\n"
    printf "  ${VIOLET}[D4]${RESET}  ${WH}OSINT Tools Install${RESET}     ${FADE}sherlock | photon | theHarvester | maigret${RESET}\n"
    printf "  ${VIOLET}[D5]${RESET}  ${WH}Full Rebuild${RESET}            ${FADE}complete environment restore | ~/.bashrc${RESET}\n"
    echo ""

    printf "  ${CYAN}${BOLD}E - CONNECTIVITY & GITHUB${RESET}\n"
    printf "  ${ELEC}[E1]${RESET}  ${WH}SSH & GitHub${RESET}             ${FADE}key | push fix | PAT | remote | errors${RESET}\n"
    printf "  ${ELEC}[E2]${RESET}  ${WH}Network Check${RESET}            ${FADE}IP | DNS | ping | HTTPS | interface${RESET}\n"
    printf "  ${ELEC}[E3]${RESET}  ${WH}Tor & Proxychains${RESET}        ${FADE}status | circuit test | proxychains config${RESET}\n"
    echo ""

    printf "  ${CYAN}${BOLD}F - ENCYCLOPEDIA${RESET}  ${FADE}(reference only - nothing modified)${RESET}\n"
    printf "  ${FADE}[F1]${RESET}  ${WH}Alias Reference${RESET}          ${FADE}every alias explained | Fezzy Station map${RESET}\n"
    printf "  ${FADE}[F2]${RESET}  ${WH}Error Code Guide${RESET}         ${FADE}common Termux errors + causes + fixes${RESET}\n"
    printf "  ${FADE}[F3]${RESET}  ${WH}Common Issues Matrix${RESET}     ${FADE}symptom >> module quick router${RESET}\n"
    printf "  ${FADE}[F4]${RESET}  ${WH}SOI Knowledge Base${RESET}       ${FADE}philosophy | workflow | 999 | Bojack rules${RESET}\n"
    echo ""

    printf "  ${CYAN}${BOLD}G - AUTO-REPAIR & FRESH START${RESET}\n"
    printf "  ${GRN}[G1]${RESET}  ${WH}Full Auto-Repair${RESET}         ${FADE}all repair modules | sequential | no prompts${RESET}\n"
    printf "  ${GRN}[G2]${RESET}  ${WH}One-Shot Fresh Install${RESET}   ${FADE}complete Termux env from scratch | 7 modules${RESET}\n"
    echo ""

    printf "  ${CYAN}${BOLD}H - EXTRAS${RESET}\n"
    printf "  ${LIME}[H1]${RESET}  ${WH}Backup & Restore${RESET}         ${FADE}backup .bashrc | scripts | configs to /sdcard${RESET}\n"
    printf "  ${LIME}[H2]${RESET}  ${WH}Dev Environment Setup${RESET}    ${FADE}vim config | git config | tmux | gum | Go PATH${RESET}\n"
    printf "  ${LIME}[H3]${RESET}  ${WH}Android Bridge Check${RESET}     ${FADE}termux-api | clipboard | notification | sensors${RESET}\n"
    echo ""

    printf "  ${CYAN}${BOLD}I - HOUSEKEEPING & HEALTH${RESET}\n"
    printf "  ${ELEC}[I1]${RESET}  ${WH}Orphan & Ghost Files${RESET}     ${FADE}broken symlinks | stale tmp | partial downloads${RESET}\n"
    printf "  ${ELEC}[I2]${RESET}  ${WH}Duplicate File Hunter${RESET}    ${FADE}find duplicates in Downloads | review before delete${RESET}\n"
    printf "  ${ELEC}[I3]${RESET}  ${WH}Empty Folder Sweep${RESET}       ${FADE}find empty dirs in home + storage | safe remove${RESET}\n"
    printf "  ${ELEC}[I4]${RESET}  ${WH}Dead Deps & Residuals${RESET}    ${FADE}dpkg rc | orphaned deps | stale pip | Go bins${RESET}\n"
    printf "  ${ELEC}[I5]${RESET}  ${WH}Full Health Audit${RESET}        ${FADE}10-point read-only check | score | fix map${RESET}\n"
    echo ""

    _dvc
    printf "  ${HOT}${BOLD}[S]${RESET}  ${WH}Search by problem${RESET}        ${FADE}type a keyword - Bojack routes to the fix${RESET}\n"
    _dvc
    printf "  ${FADE}[Q]  Exit to command line${RESET}\n"
    _dvc; echo ""
    printf "  ${HOT}${BOLD}Arsenal >> ${RESET}"
    read -r CHOICE
    case "${CHOICE^^}" in
        A1) _mod_a1 ;; A2) _mod_a2 ;; A3) _mod_a3 ;; A4) _mod_a4 ;;
        B1) _mod_b1 ;; B2) _mod_b2 ;; B3) _mod_b3 ;; B4) _mod_b4 ;; B5) _mod_b5 ;;
        C1) _mod_c1 ;; C2) _mod_c2 ;; C3) _mod_c3 ;;
        D1) _mod_d1 ;; D2) _mod_d2 ;; D3) _mod_d3 ;; D4) _mod_d4 ;; D5) _mod_d5 ;;
        E1) _mod_e1 ;; E2) _mod_e2 ;; E3) _mod_e3 ;;
        F1) _mod_f1 ;; F2) _mod_f2 ;; F3) _mod_f3 ;; F4) _mod_f4 ;;
        G1) _mod_g1 ;; G2) _mod_g2 ;;
        H1) _mod_h1 ;; H2) _mod_h2 ;; H3) _mod_h3 ;;
        I1) _mod_i1 ;; I2) _mod_i2 ;; I3) _mod_i3 ;; I4) _mod_i4 ;; I5) _mod_i5 ;;
        S)  _mod_search ;;
        M)  _show_menu ;;
        Q)  _quit ;;
        0)  _quit ;;
        *)
            warn "Invalid option - try again"
            sleep 0.6; _show_menu ;;
    esac
}

# ══════════════════════════════════════════════════════════════════════
#  SECTION A - DIAGNOSTICS & AUDIT
# ══════════════════════════════════════════════════════════════════════

_mod_a1() {
    _banner "A1  |  ENVIRONMENT AUDIT"
    _synopsis "Full system check - PATH, commands, Termux info, scripts, storage, Android version."

    _section "ARCHITECTURE + TERMUX INFO"
    info "System architecture:"
    uname -m 2>/dev/null
    echo ""
    info "Termux environment:"
    termux-info 2>/dev/null | head -15 || printf "  ${FADE}termux-info unavailable | pkg install termux-tools${RESET}\n"

    echo ""
    _dvc
    info "PATH entries:"
    echo "$PATH" | tr ':' '\n' | while read -r p; do
        [[ -d "$p" ]] && ok "$p" || warn "missing: $p"
    done

    echo ""
    _dvc
    info "Critical command check:"
    for cmd in bash curl wget git python3 pip node ffmpeg yt-dlp gallery-dl nmap tor vim tmux gh gum; do
        command -v "$cmd" &>/dev/null \
            && ok "$cmd  >>  $(command -v $cmd)" \
            || fail "$cmd - NOT FOUND"
    done

    echo ""
    _dvc
    info "Fezzy Station scripts:"
    for f in "${STATION_SCRIPT}" ~/fezzy_station_v60.sh "${ARSENAL_SCRIPT}" ~/termux-repair.sh \
              ~/termux-clear.sh ~/rebuild.sh ~/detox.sh ~/recover.sh; do
        [[ -f "$f" ]] && ok "$(basename $f) - found" || warn "$(basename $f) - not found"
    done

    echo ""
    _dvc
    info "Storage:"
    df -h ~/storage/downloads 2>/dev/null | tail -1 \
        || warn "~/storage/downloads not mounted - run B5"

    echo ""
    _dvc
    info "Android version:"
    getprop ro.build.version.release 2>/dev/null \
        && true || printf "  ${FADE}getprop unavailable${RESET}\n"

    _pause
}

_mod_a2() {
    _banner "A2  |  COMMAND AVAILABILITY CHECK"
    _synopsis "Scans your full toolkit - shows what's installed and what's missing."

    _section "FULL TOOLKIT SCAN"
    local found=0 missing=0
    local tools=(
        "curl" "wget" "git" "vim" "nano" "python3" "pip" "node" "npm" "go"
        "ffmpeg" "mpv" "yt-dlp" "gallery-dl" "aria2c" "spotdl"
        "nmap" "socat" "tor" "proxychains4" "nikto" "lynis" "nuclei" "trivy"
        "sqlmap" "exiftool" "whois" "traceroute" "steghide"
        "sherlock" "holehe" "photon" "theHarvester" "maigret"
        "gobuster" "subfinder" "httpx" "wfuzz" "hydra" "whatweb"
        "tmux" "htop" "lsof" "jq" "gawk" "openssl" "gpg" "ssh" "gh" "gum"
    )

    printf "  ${FADE}%-20s  %-8s  %s${RESET}\n" "TOOL" "STATUS" "PATH"
    _dvc
    for cmd in "${tools[@]}"; do
        if command -v "$cmd" &>/dev/null; then
            printf "  ${CYAN}*${RESET}  ${WH}%-20s${RESET}  ${GRN}FOUND${RESET}   ${FADE}%s${RESET}\n" \
                "$cmd" "$(command -v $cmd)"
            (( found++ ))
        else
            printf "  ${YEL}o${RESET}  ${WH}%-20s${RESET}  ${RED}MISSING${RESET}\n" "$cmd"
            (( missing++ ))
        fi
    done

    echo ""; _dvc
    printf "  ${GRN}${BOLD}[OK]  Found: %s${RESET}   ${YEL}[!]  Missing: %s${RESET}\n" "$found" "$missing"
    echo ""
    if (( missing > 0 )); then
        info "To restore missing tools:"
        tip "D1 - Core environment    D2 - Security tools"
        tip "D3 - Media tools         D4 - OSINT tools"
    fi

    _pause
}

_mod_a3() {
    _banner "A3  |  SYSTEM INFO REPORT"
    _synopsis "Pulls arch, CPU, RAM, storage, Android version and Termux env in one shot."

    _section "HARDWARE + ENVIRONMENT REPORT"
    info "Kernel + architecture:"; uname -a; echo ""

    _dvc
    info "CPU:"
    grep -m3 "Processor\|model name\|Hardware\|CPU part" /proc/cpuinfo 2>/dev/null | head -3 \
        || printf "  ${FADE}CPU info unavailable${RESET}\n"
    echo ""

    _dvc
    info "Memory:"
    if command -v free &>/dev/null; then
        free -m 2>/dev/null | head -3
    else
        awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{
            printf "  Total:     %d MB\n  Available: %d MB\n  Used:      %d MB\n",
            t/1024, a/1024, (t-a)/1024}' /proc/meminfo 2>/dev/null
    fi
    echo ""

    _dvc
    info "Disk - home:"; df -h ~ 2>/dev/null | head -2; echo ""
    info "Disk - storage/downloads:"
    df -h ~/storage/downloads 2>/dev/null | tail -1 \
        || printf "  ${FADE}Not mounted - run B5${RESET}\n"
    echo ""

    _dvc
    info "Android + Termux:"
    local _av; _av=$(getprop ro.build.version.release 2>/dev/null)
    [[ -n "$_av" ]] && printf "  ${FADE}Android: %s${RESET}\n" "$_av" \
                    || printf "  ${FADE}Android version: unavailable${RESET}\n"
    printf "  ${FADE}PREFIX: %s${RESET}\n" "${PREFIX:-/usr}"
    printf "  ${FADE}HOME:   %s${RESET}\n" "${HOME:-~}"
    printf "  ${FADE}SHELL:  %s${RESET}\n" "${SHELL:-bash}"
    echo ""

    _pause
}

_mod_a4() {
    _banner "A4  |  PYTHON ENVIRONMENT CHECK"
    _synopsis "Checks Python version, pip, installed packages, and executable paths."

    _section "PYTHON + PIP STATUS"
    info "Python:"
    python3 --version 2>/dev/null && ok "python3 found" || fail "python3 not found - pkg install python"
    echo ""

    info "pip:"
    pip --version 2>/dev/null && ok "pip found" || fail "pip not found - pkg install python-pip"
    echo ""

    _dvc
    info "Key pip packages:"
    local pip_tools=(yt-dlp gallery-dl mutagen spotdl reportlab PyPDF2 requests lxml \
                     sherlock-project holehe maigret photon theHarvester wfuzz dnsrecon)
    for pkg in "${pip_tools[@]}"; do
        pip show "$pkg" &>/dev/null \
            && ok "$pkg  - installed" \
            || warn "$pkg  - missing"
    done

    echo ""
    _dvc
    info "pip executable paths:"
    python3 -m site --user-base 2>/dev/null | while read -r p; do
        printf "  ${FADE}user base: %s${RESET}\n" "$p"
    done
    echo ""

    info "Externally managed warning check:"
    python3 -c "import sys; print('Python', sys.version)" 2>/dev/null
    echo ""
    tip "Always use: pip install <pkg> --break-system-packages"
    tip "Or:         pip install <pkg> --break-system-packages --no-build-isolation"

    _pause
}

# ══════════════════════════════════════════════════════════════════════
#  SECTION B - REPAIR & FIX
# ══════════════════════════════════════════════════════════════════════

_mod_b1() {
    _banner "B1  |  PACKAGE MANAGER RESCUE"
    _synopsis "Clears dpkg locks, fixes broken installs, repairs dependencies, updates all packages."

    _section "DPKG LOCKS | APT REPAIR | UPDATE"
    info "What this does:"
    tip "[1] Clears dpkg lock files - fixes 'could not get lock' errors"
    tip "[2] dpkg --configure -a - fixes interrupted installs"
    tip "[3] apt-get install -f - resolves broken dependencies"
    tip "[4] pkg update + upgrade - syncs all packages"
    echo ""
    info "Proceed with package rescue?"
    _ask || { _show_menu; return; }
    echo ""

    _spin "Clearing dpkg lock files" \
        "rm -f \${PREFIX}/var/lib/dpkg/lock* \${PREFIX}/var/cache/apt/archives/lock 2>/dev/null; true"
    _spin "dpkg --configure -a"  "dpkg --configure -a > /dev/null 2>&1; true"
    _spin "apt-get install -f"   "apt-get install -f -y > /dev/null 2>&1; true"
    _spin "pkg update"           "pkg update -y > /dev/null 2>&1"
    _spin "pkg upgrade"          "pkg upgrade -y > /dev/null 2>&1"
    _spin "apt autoremove"       "apt autoremove -y > /dev/null 2>&1; true"
    _spin "pkg clean"            "pkg clean > /dev/null 2>&1; true"

    echo ""; _dvc
    ok "Package manager rescue complete"
    echo ""
    info "If still broken:"
    tip "Run B2 Mirror Reset - CDN may be the issue"
    tip "apt list --installed 2>/dev/null | grep broken"
    tip "dpkg -l | grep -E '^rc'  - residual config packages"

    _pause
}

_mod_b2() {
    _banner "B2  |  MIRROR RESET"
    _synopsis "Changes the Termux repo CDN - fixes 404 errors, slow downloads, offline installs."

    _section "REPOSITORY CDN CHANGE"
    info "Mirror issues cause:"
    tip "404 errors during pkg update"
    tip "Slow or failed downloads"
    tip "Package not found errors"
    echo ""

    _dvc
    info "Current sources.list:"
    cat "${PREFIX}/etc/apt/sources.list" 2>/dev/null \
        || printf "  ${FADE}sources.list not found${RESET}\n"
    echo ""

    _dvc
    info "Mirror options:"
    printf "  ${PINK}[1]${RESET}  ${WH}Cloudflare CDN${RESET}       ${FADE}(recommended | SA/Africa | fastest)${RESET}\n"
    printf "  ${PINK}[2]${RESET}  ${WH}A-Mirrors CDN${RESET}        ${FADE}(packages.termux.dev | alternative)${RESET}\n"
    printf "  ${PINK}[3]${RESET}  ${WH}Interactive selector${RESET} ${FADE}(termux-change-repo - choose from list)${RESET}\n"
    echo ""
    printf "  ${PINK}${BOLD}Choice [1/2/3] >> ${RESET}"; read -r _mc; echo ""

    case "$_mc" in
        1)
            _spin "Setting Cloudflare CDN" \
                "echo 'deb https://packages-cf.termux.dev/apt/termux-main stable main' > \${PREFIX}/etc/apt/sources.list"
            _spin "pkg update after mirror change" "pkg update -y > /dev/null 2>&1"
            ok "Mirror set - Cloudflare CDN"
            ;;
        2)
            _spin "Setting A-Mirrors CDN" \
                "echo 'deb https://packages.termux.dev/apt/termux-main stable main' > \${PREFIX}/etc/apt/sources.list"
            _spin "pkg update after mirror change" "pkg update -y > /dev/null 2>&1"
            ok "Mirror set - A-Mirrors CDN"
            ;;
        3)
            if command -v termux-change-repo &>/dev/null; then
                info "Launching termux-change-repo..."
                termux-change-repo
            else
                warn "termux-change-repo not found"
                info "Fix: pkg install termux-tools"
                _spin "Installing termux-tools" "pkg install -y termux-tools > /dev/null 2>&1"
                command -v termux-change-repo &>/dev/null \
                    && termux-change-repo \
                    || warn "Still not available - try pkg update first"
            fi
            ;;
        *) warn "No selection - skipped" ;;
    esac

    _pause
}

_mod_b3() {
    _banner "B3  |  .BASHRC VALIDATOR & FIXER"
    _synopsis "Runs bash -n syntax check, fixes deprecated patterns, confirms key aliases exist."

    _section "SYNTAX CHECK + KNOWN PATTERN FIXES"
    local BASHRC=~/.bashrc
    if [[ ! -f "$BASHRC" ]]; then
        fail "~/.bashrc not found - nothing to check"
        _pause; return
    fi

    info "Running bash syntax check..."
    echo ""
    if bash -n "$BASHRC" 2>${TMPDIR:-$PREFIX/tmp}/_rb_bashrc_err.log; then
        ok ".bashrc syntax is CLEAN"
    else
        fail ".bashrc has syntax errors:"
        echo ""
        printf "${RED}"
        cat ${TMPDIR:-$PREFIX/tmp}/_rb_bashrc_err.log
        printf "${RESET}"
        echo ""
        info "Fix tips:"
        tip "Check line numbers above for unclosed quotes or brackets"
        tip "vim ~/.bashrc to manually edit the problem line"
        tip "bash -n ~/.bashrc after each fix to confirm"
    fi

    echo ""; _dvc
    info "Checking for known bad patterns:"
    echo ""

    if grep -q "pkg autoremove" "$BASHRC" 2>/dev/null; then
        warn "Found: pkg autoremove  (deprecated in Termux)"
        info "Fix? Replace with apt autoremove"
        _ask && {
            sed -i 's/pkg autoremove/apt autoremove/g' "$BASHRC"
            ok "Fixed: pkg autoremove >> apt autoremove"
        }
    else
        ok "No deprecated pkg autoremove found"
    fi

    echo ""
    grep -q "fezzy_station_v6" "$BASHRC" 2>/dev/null \
        && ok "Fezzy Station source line found" \
        || warn "Fezzy Station source line not in .bashrc"

    grep -q "alias rebuild" "$BASHRC" 2>/dev/null \
        && ok "rebuild alias found" \
        || warn "rebuild alias missing"

    grep -q "alias reload" "$BASHRC" 2>/dev/null \
        && ok "reload alias found" \
        || warn "reload alias missing"

    echo ""; _dvc
    printf "  ${FADE}Line count: %s lines${RESET}\n" "$(wc -l < "$BASHRC")"
    echo ""
    info "Backup .bashrc now?"
    _ask && {
        cp "$BASHRC" "${BASHRC}.bak_$(date +%Y%m%d_%H%M%S)"
        ok "Backup created"
    }

    _pause
}

_mod_b4() {
    _banner "B4  |  ALIAS REPAIR & EXPLAINER"
    _synopsis "Lists all aliases from .bashrc, tests key ones live, shows what's missing."

    _section "ALIAS STATUS CHECK"
    local BASHRC=~/.bashrc
    info "Aliases found in ~/.bashrc:"
    echo ""
    grep "^alias" "$BASHRC" 2>/dev/null | while IFS= read -r line; do
        local name="${line%%=*}"; name="${name##alias }"
        local def="${line#*=}"
        printf "  ${PINK}*${RESET}  ${CYAN}%-16s${RESET}  ${FADE}%s${RESET}\n" "$name" "$def"
    done

    echo ""; _dvc
    info "Testing key aliases (live shell):"
    local key_aliases=(dl station fezzy rebuild reload cleanup repair detox tclear arsenal)
    for a in "${key_aliases[@]}"; do
        type "$a" &>/dev/null \
            && ok "$a  - active" \
            || warn "$a  - not active  ${FADE}(fix: source ~/.bashrc)"
    done

    echo ""; _dvc
    info "ALIAS REPAIR:"
    tip "source ~/.bashrc  - reload all aliases in current session"
    tip "alias rebuild='bash ~/rebuild.sh'  - add if missing"
    tip "alias arsenal='bash ~/arsenal.sh'  - add for this script"
    tip "grep alias ~/.bashrc  - check what's defined"

    _pause
}

_mod_b5() {
    _banner "B5  |  STORAGE RECOVERY"
    _synopsis "Re-links /sdcard, checks ~/storage symlinks, sets DLDIR environment variable."

    _section "STORAGE PERMISSION + SYMLINKS"
    info "Checking ~/storage/downloads..."
    echo ""
    if [[ -d ~/storage/downloads ]]; then
        ok "~/storage/downloads exists"
        df -h ~/storage/downloads 2>/dev/null | tail -1
    else
        warn "~/storage/downloads is missing"
        echo ""
        info "Re-run termux-setup-storage?"
        _ask && {
            termux-setup-storage 2>/dev/null
            sleep 3
            [[ -d ~/storage/downloads ]] \
                && ok "Storage linked successfully" \
                || warn "Still missing - tap Allow in the Android permission dialog"
        }
    fi

    echo ""; _dvc
    info "Checking ~/storage symlinks:"
    local links=(downloads dcim movies music pictures shared)
    for l in "${links[@]}"; do
        [[ -e ~/storage/$l ]] \
            && ok "~/storage/$l  -  present" \
            || warn "~/storage/$l  -  missing"
    done

    echo ""; _dvc
    info "DLDIR environment variable:"
    printf "  ${WH}Current: %s${RESET}\n" "${DLDIR:-not set}"
    echo ""
    info "Add DLDIR to .bashrc?"
    _ask && {
        grep -q "DLDIR" ~/.bashrc 2>/dev/null \
            && warn "DLDIR already in .bashrc" \
            || {
                echo 'export DLDIR=~/storage/downloads' >> ~/.bashrc
                ok "DLDIR added to ~/.bashrc"
            }
    }

    _pause
}

# ══════════════════════════════════════════════════════════════════════
#  SECTION C - PERFORMANCE & CLEAN
# ══════════════════════════════════════════════════════════════════════

_mod_c1() {
    _banner "C1  |  PERFORMANCE & FREEZE FIX"
    _synopsis "Kills stale processes, clears caches, and gives you the tmux survival guide."

    _section "COMMON FREEZE CAUSES"
    tip "[1] Stale mpv / yt-dlp / wget processes holding resources"
    tip "[2] tput cols called too often on low-RAM devices"
    tip "[3] Android kills Termux session - use tmux to survive"
    tip "[4] ~/storage/downloads full - causes install freezes mid-run"
    tip "[5] Nested subshells or source loops in .bashrc"
    echo ""

    _dvc
    info "Top 15 processes (CPU):"
    echo ""
    ps aux 2>/dev/null | sort -rn -k3 | head -15 || top -bn1 | head -15
    echo ""

    _dvc
    info "Run cleanup now?"
    _ask && {
        _spin "Killing stale mpv"         "pkill -x mpv 2>/dev/null; true"
        _spin "Killing stale wget/curl"   "pkill -x wget 2>/dev/null; pkill -x curl 2>/dev/null; true"
        _spin "Killing stale yt-dlp"      "pkill -f yt-dlp 2>/dev/null; true"
        _spin "Killing stale gallery-dl"  "pkill -f gallery-dl 2>/dev/null; true"
        _spin "pkg clean"                 "pkg clean > /dev/null 2>&1; true"
        _spin "apt autoclean"             "apt autoclean > /dev/null 2>&1; true"
        _spin "Clearing tmp/fezzy_*"      "rm -f ${TMPDIR:-$PREFIX/tmp}/fezzy_* 2>/dev/null; true"
        _spin "Clearing cache"            "rm -rf ~/.cache/pip ~/.cache/yt-dlp 2>/dev/null; true"
        _spin "termux-reload-settings"    "termux-reload-settings 2>/dev/null; true"
    }

    echo ""; _dvc
    info "FREEZE SURVIVAL GUIDE:"
    echo ""
    printf "  ${PINK}*${RESET}  ${WH}tmux new -s work${RESET}          ${FADE}protect session from Android kills${RESET}\n"
    printf "  ${PINK}*${RESET}  ${WH}Vol Down + D${RESET}              ${FADE}detach from tmux (session stays alive)${RESET}\n"
    printf "  ${PINK}*${RESET}  ${WH}tmux attach -t work${RESET}       ${FADE}re-attach after returning${RESET}\n"
    printf "  ${PINK}*${RESET}  ${WH}pkill -x mpv${RESET}              ${FADE}kill frozen media player${RESET}\n"
    printf "  ${PINK}*${RESET}  ${WH}source ~/.bashrc${RESET}          ${FADE}reload shell without restart${RESET}\n"
    printf "  ${PINK}*${RESET}  ${WH}kill %1${RESET}                   ${FADE}kill last background job${RESET}\n"
    printf "  ${PINK}*${RESET}  ${WH}unset LD_PRELOAD${RESET}          ${FADE}fix some tool crashes${RESET}\n"
    printf "  ${PINK}*${RESET}  ${WH}pkg clean && pkg update${RESET}   ${FADE}if install freezes partway${RESET}\n"
    echo ""

    _dvc
    info "Storage:"
    df -h ~/storage/downloads 2>/dev/null | tail -1 || df -h ~/ 2>/dev/null | tail -1

    _pause
}

_mod_c2() {
    _banner "C2  |  PROCESS MANAGER"
    _synopsis "View running processes, kill by name or PID, nuke all stale media processes."

    _section "RUNNING PROCESSES - VIEW + KILL"
    ps aux 2>/dev/null | sort -rn -k3 | head -20 || top -bn1 | head -20
    echo ""

    _dvc
    info "Kill a process by name?"
    _ask && {
        printf "  ${PINK}${BOLD}Process name >> ${RESET}"; read -r _pname; echo ""
        if [[ -n "$_pname" ]]; then
            _spin "Killing: $_pname" "pkill -f '$_pname' 2>/dev/null; true"
        else
            warn "No name entered"
        fi
    }

    echo ""; _dvc
    info "Kill a process by PID?"
    _ask && {
        printf "  ${PINK}${BOLD}PID >> ${RESET}"; read -r _pid; echo ""
        if [[ -n "$_pid" && "$_pid" =~ ^[0-9]+$ ]]; then
            kill "$_pid" 2>/dev/null \
                && ok "PID $_pid killed" \
                || warn "Could not kill PID $_pid - already gone or protected"
        else
            warn "Invalid PID"
        fi
    }

    echo ""; _dvc
    info "Kill all known stale media processes?"
    _ask && {
        _spin "Killing mpv / yt-dlp / gallery-dl / wget / curl" \
            "pkill -x mpv 2>/dev/null; pkill -f yt-dlp 2>/dev/null; pkill -f gallery-dl 2>/dev/null; pkill -x wget 2>/dev/null; pkill -x curl 2>/dev/null; true"
        ok "Stale media processes cleared"
    }

    _pause
}

_mod_c3() {
    _banner "C3  |  DETOX - FULL CLEAN"
    _synopsis "9-module environment cleaner - cache, deps, orphans, tmp, media cache, processes, clipboard, history."

    _section "ENVIRONMENT CLEANER"
    info "Each module asks [y/n] - skip anything you want."
    echo ""
    printf "  ${PINK}>${RESET}  ${WH}Before snapshot:${RESET}\n"
    printf "  ${FADE}  Home: %s${RESET}\n" "$(du -sh ~ 2>/dev/null | cut -f1 || echo unknown)"
    df -h ~/storage/downloads 2>/dev/null | tail -1 || df -h ~/ 2>/dev/null | tail -1
    echo ""

    # -- C3-1 SYSTEM CACHE
    _section "C3-1 | SYSTEM CACHE"
    _type "${WH}" "  pkg clean | pkg autoclean - removes stale package lists and cache" 0.02
    _ask && {
        _spin "pkg clean"     "pkg clean -y &>/dev/null"
        _spin "pkg autoclean" "pkg autoclean -y &>/dev/null"
        ok "System cache cleared"
    } || printf "  ${FADE}  skipped${RESET}\n\n"

    # -- C3-2 BROKEN DEPS
    _section "C3-2 | BROKEN DEPENDENCIES"
    _type "${WH}" "  dpkg --configure -a | apt-get install -f" 0.02
    _ask && {
        _spin "dpkg --configure -a" "dpkg --configure -a &>/dev/null"
        _spin "apt-get install -f"  "apt-get install -f -y &>/dev/null"
        ok "Dependencies repaired"
    } || printf "  ${FADE}  skipped${RESET}\n\n"

    # -- C3-3 ORPHANS
    _section "C3-3 | ORPHANED PACKAGES"
    _type "${WH}" "  apt autoremove - removes dead dependency packages" 0.02
    _ask && {
        _spin "apt autoremove" "apt autoremove -y &>/dev/null"
        ok "Orphaned packages removed"
    } || printf "  ${FADE}  skipped${RESET}\n\n"

    # -- C3-4 APP JUNK
    _section "C3-4 | APP JUNK + TMP FILES"
    _type "${WH}" "  Wipes ~/.cache and TMPDIR - rebuilt on demand, safe to clear" 0.02
    printf "  ${YEL}  ~/.cache: %s${RESET}\n" "$(du -sh ~/.cache 2>/dev/null | cut -f1 || echo empty)"
    printf "  ${YEL}  ${TMPDIR:-$PREFIX/tmp}: %s${RESET}\n" "$(du -sh "${TMPDIR:-$PREFIX/tmp}" 2>/dev/null | cut -f1 || echo empty)"
    echo ""
    _ask && {
        _spin "Wiping ~/.cache"      "rm -rf ~/.cache/* 2>/dev/null"
        _spin "Clearing TMPDIR"      "rm -rf '${TMPDIR:-$PREFIX/tmp}'/* 2>/dev/null"
        _spin "pip cache purge"      "pip cache purge --break-system-packages &>/dev/null; true"
        ok "App junk cleared"
    } || printf "  ${FADE}  skipped${RESET}\n\n"

    # -- C3-5 PARTIAL DOWNLOADS
    _section "C3-5 | PARTIAL DOWNLOADS"
    _type "${WH}" "  Removes .part .tmp .crdownload files from Downloads" 0.02
    local _parts
    _parts=$(find ~/storage/downloads /sdcard/Download 2>/dev/null \
        -maxdepth 4 \( -name "*.part" -o -name "*.tmp" -o -name "*.crdownload" \) 2>/dev/null | wc -l)
    printf "  ${YEL}  Found: %s partial files${RESET}\n\n" "$_parts"
    _ask && {
        find ~/storage/downloads /sdcard/Download 2>/dev/null \
            -maxdepth 4 \( -name "*.part" -o -name "*.tmp" -o -name "*.crdownload" \) \
            -delete 2>/dev/null
        ok "$_parts partial files removed"
    } || printf "  ${FADE}  skipped${RESET}\n\n"

    # -- C3-6 MEDIA CACHE
    _section "C3-6 | MEDIA TOOL CACHE"
    _type "${WH}" "  Clears yt-dlp and gallery-dl cache directories" 0.02
    printf "  ${YEL}  yt-dlp:     %s${RESET}\n" "$(du -sh ~/.cache/yt-dlp 2>/dev/null | cut -f1 || echo empty)"
    printf "  ${YEL}  gallery-dl: %s${RESET}\n" "$(du -sh ~/.cache/gallery-dl 2>/dev/null | cut -f1 || echo empty)"
    echo ""
    _ask && {
        _spin "Clearing yt-dlp cache"     "rm -rf ~/.cache/yt-dlp 2>/dev/null"
        _spin "Clearing gallery-dl cache" "rm -rf ~/.cache/gallery-dl 2>/dev/null"
        ok "Media cache cleared"
    } || printf "  ${FADE}  skipped${RESET}\n\n"

    # -- C3-7 STALE PROCESSES
    _section "C3-7 | ORPHANED PROCESSES"
    _type "${WH}" "  Kills mpv / wget / curl / gallery-dl stuck in background" 0.02
    local _procs; _procs=$(pgrep -xl "mpv" 2>/dev/null | wc -l)
    printf "  ${YEL}  Found: %s stale mpv processes${RESET}\n\n" "$_procs"
    _ask && {
        _spin "Killing stale mpv"        "pkill -x mpv 2>/dev/null; true"
        _spin "Killing stale wget/curl"  "pkill -x wget 2>/dev/null; pkill -x curl 2>/dev/null; true"
        _spin "Clearing tmp/fezzy_*"     "rm -f ${TMPDIR:-$PREFIX/tmp}/fezzy_* 2>/dev/null; true"
        ok "Stale processes cleared"
    } || printf "  ${FADE}  skipped${RESET}\n\n"

    # -- C3-8 CLIPBOARD
    _section "C3-8 | CLIPBOARD WIPE"
    _type "${WH}" "  Clears Android clipboard - good hygiene after copying passwords" 0.02
    _ask && {
        termux-clipboard-set "" 2>/dev/null
        ok "Clipboard cleared"
    } || printf "  ${FADE}  skipped${RESET}\n\n"

    # -- C3-9 BASH HISTORY
    _section "C3-9 | BASH HISTORY"
    _type "${RED}" "  Irreversible - all past commands will be permanently gone" 0.02
    echo ""
    _ask && {
        _spin "Purging bash history" \
            "cat /dev/null > ~/.bash_history 2>/dev/null; history -c 2>/dev/null; true"
        ok "History wiped - no trace - 999"
    } || printf "  ${FADE}  skipped - keeping history intact${RESET}\n\n"

    echo ""
    _dv
    printf "  ${PINK}${BOLD}DETOX COMPLETE  *  999${RESET}\n"
    _dv
    printf "  ${FADE}Home after: %s${RESET}\n" "$(du -sh ~ 2>/dev/null | cut -f1)"
    echo ""
    local _dq=("Clean environment. Clear mind. Still a dog. - Bojack"
                "Freed that space like Juice freed that pain. - 999"
                "Deleted the junk. Kept the vibes. - Strategy Over Impulse"
                "Less cache. More clarity. Bojack approves. - 999")
    printf "  ${FADE}\"%s\"${RESET}\n" "${_dq[$((RANDOM % 4))]}"

    _pause
}

# ══════════════════════════════════════════════════════════════════════
#  SECTION D - INSTALL & REBUILD
# ══════════════════════════════════════════════════════════════════════

_mod_d1() {
    _banner "D1  |  CORE ENVIRONMENT SETUP"
    _synopsis "Installs storage, updates repos, and drops the full base package set."

    _section "STORAGE | REPOS | BASE PACKAGES"
    info "Installs: storage | update | upgrade | core tools | Python | Node | tmux"
    info "Nothing installs automatically - confirm below."
    _ask || { _show_menu; return; }
    echo ""

    if [[ -d ~/storage/downloads ]]; then ok "Storage already linked"
    else _spin "termux-setup-storage" "termux-setup-storage 2>/dev/null; sleep 2"; fi

    _spin "pkg update"   "pkg update -y > /dev/null 2>&1"
    _spin "pkg upgrade"  "pkg upgrade -y > /dev/null 2>&1"
    _dvc
    _spin "Net core: curl wget git openssh"     "pkg install -y curl wget git openssh > /dev/null 2>&1"
    _spin "Editors: vim nano"                    "pkg install -y vim nano > /dev/null 2>&1"
    _spin "Python + pip"                         "pkg install -y python python-pip > /dev/null 2>&1"
    _spin "Node.js"                              "pkg install -y nodejs > /dev/null 2>&1"
    _spin "Shell utils: tmux jq gawk coreutils" "pkg install -y tmux jq grep sed gawk coreutils > /dev/null 2>&1"
    _spin "Archive: tar zip unzip proot"         "pkg install -y tar zip unzip proot > /dev/null 2>&1"
    _spin "System: lsof htop file iproute2"      "pkg install -y lsof htop file iproute2 dnsutils > /dev/null 2>&1"
    _spin "Termux API"                           "pkg install -y termux-api > /dev/null 2>&1"
    _spin "Media: ffmpeg mpv"                    "pkg install -y ffmpeg mpv > /dev/null 2>&1"
    _spin "Crypto: openssl gnupg"                "pkg install -y openssl-tool gnupg > /dev/null 2>&1"
    _spin "aria2 download engine"                "pkg install -y aria2 > /dev/null 2>&1"
    _spin "GitHub CLI (gh)"                      "pkg install -y gh > /dev/null 2>&1"
    _spin "Network: nmap socat proxychains tor"  "pkg install -y nmap socat proxychains-ng tor > /dev/null 2>&1"
    _spin "whois + traceroute"                   "pkg install -y whois traceroute > /dev/null 2>&1"
    _spin "perl + exiftool"                      "pkg install -y perl exiftool > /dev/null 2>&1"
    _spin "gum (spinners)"                       "pkg install -y gum > /dev/null 2>&1"
    _spin "ncurses-utils (tput)"                 "pkg install -y ncurses-utils > /dev/null 2>&1"

    echo ""; ok "Core environment setup complete"
    info "Next: D2 - Security  |  D3 - Media  |  D4 - OSINT"

    _pause
}

_mod_d2() {
    _banner "D2  |  SECURITY HUB INSTALL"
    _synopsis "Installs nuclei, trivy, nikto, lynis, gobuster, subfinder, wfuzz, hydra and more."

    _section "NUCLEI | TRIVY | NIKTO | LYNIS | GOBUSTER | MORE"
    info "Tools included:"
    tip "[1]  nikto      - web server vulnerability scanner"
    tip "[2]  lynis      - system security auditor"
    tip "[3]  nmap       - network port scanner"
    tip "[4]  gobuster   - directory/DNS brute-forcer"
    tip "[5]  wfuzz      - web fuzzer"
    tip "[6]  hydra      - login brute-forcer"
    tip "[7]  whatweb    - web fingerprinting"
    tip "[8]  subfinder  - subdomain enumeration (go)"
    tip "[9]  nuclei     - vuln scan template engine (go)"
    tip "[10] trivy      - container & code scanner (go)"
    tip "[11] httpx      - HTTP probing tool (go)"
    echo ""
    info "Nothing installs automatically - confirm below."
    _ask || { _show_menu; return; }
    echo ""

    _spin "nikto"       "pkg install -y nikto > /dev/null 2>&1 || git clone https://github.com/sullo/nikto ~/nikto > /dev/null 2>&1"
    _spin "lynis"       "pkg install -y lynis > /dev/null 2>&1 || git clone https://github.com/CISOfy/lynis ~/lynis > /dev/null 2>&1"
    _spin "nmap"        "pkg install -y nmap > /dev/null 2>&1"
    _spin "hydra"       "pkg install -y hydra > /dev/null 2>&1"
    _spin "sqlmap"      "pip install sqlmap --break-system-packages -q 2>/dev/null"
    _spin "wfuzz"       "pip install wfuzz --break-system-packages -q 2>/dev/null"
    _spin "steghide"    "pkg install -y steghide > /dev/null 2>&1"
    _spin "binwalk"     "pip install binwalk --break-system-packages -q 2>/dev/null"
    _spin "hashid"      "pip install hashid --break-system-packages -q 2>/dev/null"
    _spin "golang"      "pkg install -y golang > /dev/null 2>&1"

    if command -v go &>/dev/null; then
        export PATH=$PATH:$(go env GOPATH)/bin
        _spin "nuclei   (go)"   "go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest > /dev/null 2>&1"
        _spin "trivy    (go)"   "go install github.com/aquasecurity/trivy/cmd/trivy@latest > /dev/null 2>&1"
        _spin "subfinder (go)"  "go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest > /dev/null 2>&1"
        _spin "gobuster (go)"   "go install github.com/OJ/gobuster/v3@latest > /dev/null 2>&1"
        _spin "httpx    (go)"   "go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest > /dev/null 2>&1"
        grep -q "GOPATH" ~/.bashrc 2>/dev/null || \
            echo 'export PATH=$PATH:'"$(go env GOPATH)/bin" >> ~/.bashrc
        ok "Go PATH added to ~/.bashrc"
    else
        warn "golang unavailable - nuclei/trivy/subfinder/gobuster skipped"
        tip "Retry: pkg install golang  then run D2 again"
    fi

    echo ""; _dvc
    info "Post-install check:"
    for t in nikto nmap hydra nuclei trivy subfinder gobuster httpx; do
        command -v "$t" &>/dev/null && ok "$t  ready" || warn "$t  missing - source ~/.bashrc"
    done

    _pause
}

_mod_d3() {
    _banner "D3  |  MEDIA TOOLS INSTALL"
    _synopsis "Installs yt-dlp, gallery-dl, ffmpeg, mpv, spotdl, mutagen, aria2c."

    _section "YT-DLP | GALLERY-DL | FFMPEG | MPV | SPOTDL"
    info "Tools included:"
    tip "[1]  yt-dlp      - YouTube/audio/video downloader"
    tip "[2]  gallery-dl  - image gallery + social media scraper"
    tip "[3]  ffmpeg       - media processing engine"
    tip "[4]  mpv          - media player"
    tip "[5]  spotdl       - Spotify downloader"
    tip "[6]  mutagen      - audio tag engine"
    tip "[7]  aria2c       - multi-protocol download manager"
    echo ""
    info "Nothing installs automatically - confirm below."
    _ask || { _show_menu; return; }
    echo ""

    _spin "yt-dlp"          "pip install yt-dlp --break-system-packages -q 2>/dev/null"
    _spin "gallery-dl"      "pip install gallery-dl --break-system-packages -q 2>/dev/null"
    _spin "mutagen"         "pip install mutagen --break-system-packages -q 2>/dev/null"
    _spin "spotdl"          "pip install spotdl --break-system-packages -q 2>/dev/null"
    _spin "ffmpeg-python"   "pip install ffmpeg-python --break-system-packages -q 2>/dev/null"
    _spin "requests"        "pip install requests --break-system-packages -q 2>/dev/null"
    _spin "ffmpeg (pkg)"    "pkg install -y ffmpeg > /dev/null 2>&1"
    _spin "mpv (pkg)"       "pkg install -y mpv > /dev/null 2>&1"
    _spin "aria2c (pkg)"    "pkg install -y aria2 > /dev/null 2>&1"

    echo ""; _dvc
    info "Post-install check:"
    for t in yt-dlp gallery-dl ffmpeg mpv spotdl aria2c; do
        command -v "$t" &>/dev/null && ok "$t  ready" || warn "$t  missing"
    done

    echo ""; info "Usage tips:"
    tip "yt-dlp -x --audio-format mp3 <url>  - audio only"
    tip "gallery-dl <url>  - download gallery"
    tip "spotdl <spotify-url>  - Spotify track/playlist"
    tip "aria2c -x4 <url>  - multi-connection download"

    _pause
}

_mod_d4() {
    _banner "D4  |  OSINT TOOLS INSTALL"
    _synopsis "Installs sherlock, holehe, maigret, photon, theHarvester, exiftool, whois and more."

    _section "SHERLOCK | HOLEHE | PHOTON | THEHARVESTER | MORE"
    info "Tools included:"
    tip "[1]  sherlock      - username search across 400+ sites"
    tip "[2]  holehe        - email account checker"
    tip "[3]  maigret       - person OSINT by username"
    tip "[4]  photon        - web crawler + OSINT spider"
    tip "[5]  theHarvester  - domain/email/subdomain recon"
    tip "[6]  exiftool      - EXIF metadata reader"
    tip "[7]  h8mail        - breach email checker"
    tip "[8]  whois         - domain registration lookup"
    tip "[9]  dnsrecon      - DNS enumeration tool"
    echo ""
    info "Nothing installs automatically - confirm below."
    _ask || { _show_menu; return; }
    echo ""

    _spin "exiftool + perl"  "pkg install -y perl exiftool > /dev/null 2>&1"
    _spin "whois + nslookup" "pkg install -y whois dnsutils > /dev/null 2>&1"
    _spin "traceroute"       "pkg install -y traceroute > /dev/null 2>&1"
    _spin "sherlock"         "pip install sherlock-project --break-system-packages -q 2>/dev/null"
    _spin "holehe"           "pip install holehe --break-system-packages -q 2>/dev/null"
    _spin "maigret"          "pip install maigret --break-system-packages -q 2>/dev/null"
    _spin "photon"           "pip install photon --break-system-packages -q 2>/dev/null"
    _spin "theHarvester"     "pip install theHarvester --break-system-packages -q 2>/dev/null"
    _spin "h8mail"           "pip install h8mail --break-system-packages -q 2>/dev/null"
    _spin "dnsrecon"         "pip install dnsrecon --break-system-packages -q 2>/dev/null"
    _spin "dnspython"        "pip install dnspython --break-system-packages -q 2>/dev/null"
    _spin "requests + lxml"  "pip install requests lxml beautifulsoup4 --break-system-packages -q 2>/dev/null"
    _spin "sqlmap"           "pip install sqlmap --break-system-packages -q 2>/dev/null"

    echo ""; _dvc
    info "Post-install check:"
    for t in sherlock holehe photon exiftool whois; do
        command -v "$t" &>/dev/null && ok "$t  ready" || warn "$t  missing"
    done

    echo ""; info "Usage tips:"
    tip "sherlock <username>  - search username on all platforms"
    tip "holehe <email>  - check which services use that email"
    tip "photon -u <url>  - crawl + extract links, emails, files"
    tip "theHarvester -d <domain> -b all  - full domain recon"

    _pause
}

_mod_d5() {
    _banner "D5  |  FULL REBUILD"
    _synopsis "Runs the full environment rebuild script if present, or guides you to G2."

    _section "COMPLETE ENVIRONMENT RESTORE"
    printf "  ${RED}${BOLD}WARNING:${RESET}  ${WH}This runs the full rebuild - all sections.${RESET}\n"
    printf "  ${FADE}Takes 10-30 minutes depending on connection. Let it cook.${RESET}\n"
    printf "  ${FADE}Bojack's watching - don't tap out halfway.${RESET}\n"
    echo ""
    info "Continue with full rebuild?"
    _ask || { _show_menu; return; }
    echo ""

    local _rb_script
    for _rb_script in ~/fezzy_rebuild_v61.sh ~/fezzy_station_v61.sh "${STATION_SCRIPT}"; do
        if [[ -f "$_rb_script" ]]; then
            bash "$_rb_script"
            _pause; return
        fi
    done

    warn "Rebuild script not found in ~/"
    echo ""
    info "Place it first:"
    tip "cp /sdcard/Download/fezzy_rebuild_v61.sh ~/"
    tip "chmod +x ~/fezzy_rebuild_v61.sh"
    tip "Then return to D5"
    echo ""
    info "Or run G2 - One-Shot Fresh Install instead?"
    _ask && { _mod_g2; return; }
    info "OK - returning to menu"

    _pause
}

# ══════════════════════════════════════════════════════════════════════
#  SECTION E - CONNECTIVITY & GITHUB
# ══════════════════════════════════════════════════════════════════════

_mod_e1() {
    _banner "E1  |  SSH & GITHUB TROUBLESHOOT"
    _synopsis "Git config, SSH key generation, auth test, remote setup, push workflow, error table."

    _section "STEP 1 - GIT CONFIG"
    info "Checking git user config..."
    local _gname _gemail
    _gname=$(git config --global user.name 2>/dev/null)
    _gemail=$(git config --global user.email 2>/dev/null)

    if [[ -n "$_gname" && -n "$_gemail" ]]; then
        ok "git user.name:   $_gname"
        ok "git user.email:  $_gemail"
    else
        warn "git config not set - required for commits"
        info "Set git user config now?"
        _ask && {
            printf "  ${PINK}${BOLD}Name  >> ${RESET}"; read -r _name_input; echo ""
            printf "  ${PINK}${BOLD}Email >> ${RESET}"; read -r _email_input; echo ""
            [[ -n "$_name_input" ]]  && git config --global user.name "$_name_input"
            [[ -n "$_email_input" ]] && git config --global user.email "$_email_input"
            ok "git config saved"
        }
    fi

    echo ""; _section "STEP 2 - SSH KEY"
    info "Checking for SSH key..."
    if [[ -f ~/.ssh/id_ed25519 ]]; then
        ok "SSH key found: ~/.ssh/id_ed25519"
    else
        warn "No SSH key found"
        info "Generate ed25519 key now?"
        _ask && {
            mkdir -p ~/.ssh; chmod 700 ~/.ssh
            _spin "Generating ed25519 SSH key" \
                "ssh-keygen -t ed25519 -C 'philfesters@github' -f ~/.ssh/id_ed25519 -N '' > /dev/null 2>&1"
        }
    fi

    if [[ -f ~/.ssh/id_ed25519.pub ]]; then
        echo ""; _dvc
        info "PUBLIC KEY - paste into GitHub >> Settings >> SSH Keys >> New:"
        echo ""; printf "${FADE}"; cat ~/.ssh/id_ed25519.pub 2>/dev/null; printf "${RESET}\n"
    fi

    echo ""; _section "STEP 3 - AUTH TEST"
    info "Testing GitHub SSH connection..."
    local _ssh_result
    _ssh_result=$(ssh -o ConnectTimeout=10 -T git@github.com 2>&1)
    if echo "$_ssh_result" | grep -qi "successfully"; then
        ok "GitHub SSH authenticated - you're live"
    else
        warn "Not authenticated yet"
        tip "1. Copy the public key above"
        tip "2. github.com >> Settings >> SSH and GPG keys >> New SSH key"
        tip "3. Paste and save, then re-run E1"
        printf "  ${FADE}SSH result: %s${RESET}\n" "$_ssh_result"
    fi

    echo ""; _section "STEP 4 - REMOTE ORIGIN CHECK"
    if git rev-parse --is-inside-work-tree &>/dev/null; then
        local _remote; _remote=$(git remote -v 2>/dev/null)
        if [[ -n "$_remote" ]]; then
            ok "Remote origin found:"; printf "${FADE}%s${RESET}\n" "$_remote"
        else
            warn "No remote set in this repo"
            info "Add remote?"
            _ask && {
                printf "  ${PINK}${BOLD}Repo name >> ${RESET}"; read -r _repo_name; echo ""
                git remote add origin "git@github.com:philfesters/${_repo_name}.git" 2>/dev/null \
                    && ok "Remote set: git@github.com:philfesters/${_repo_name}.git" \
                    || warn "Remote already exists - git remote set-url origin <url>"
            }
        fi
        info "Current branch:"
        git branch --show-current 2>/dev/null || git rev-parse --abbrev-ref HEAD 2>/dev/null
    else
        info "Not inside a git repo - cd into your project then run E1"
    fi

    echo ""; _section "STEP 5 - PUSH WORKFLOW"
    printf "  ${FADE}New repo from scratch:${RESET}\n\n"
    printf "  ${PINK}git init${RESET}\n"
    printf "  ${PINK}git remote add origin git@github.com:philfesters/REPO.git${RESET}\n"
    printf "  ${PINK}git add .${RESET}\n"
    printf "  ${PINK}git commit -m 'Strategy Over Impulse | 999'${RESET}\n"
    printf "  ${PINK}git push -u origin main${RESET}\n"
    echo ""
    printf "  ${FADE}Update existing repo:${RESET}\n\n"
    printf "  ${PINK}git add . && git commit -m 'update' && git push${RESET}\n"
    echo ""

    _section "STEP 6 - COMMON GIT ERRORS"
    printf "  ${VIOLET}${BOLD}%-42s  %s${RESET}\n" "ERROR" "FIX"; _dvc
    printf "  ${RED}%-42s${RESET}  ${CYAN}%s${RESET}\n" "rejected: non-fast-forward"           "git pull --rebase origin main  then push"
    printf "  ${RED}%-42s${RESET}  ${CYAN}%s${RESET}\n" "error: failed to push some refs"       "git pull origin main --allow-unrelated-histories"
    printf "  ${RED}%-42s${RESET}  ${CYAN}%s${RESET}\n" "remote: Repository not found"          "check remote URL | git remote -v"
    printf "  ${RED}%-42s${RESET}  ${CYAN}%s${RESET}\n" "fatal: not a git repository"           "cd into project | git init"
    printf "  ${RED}%-42s${RESET}  ${CYAN}%s${RESET}\n" "src refspec main does not match any"   "git add . && git commit first"
    printf "  ${RED}%-42s${RESET}  ${CYAN}%s${RESET}\n" "remote: Permission denied"             "check SSH key in GitHub Settings"
    printf "  ${RED}%-42s${RESET}  ${CYAN}%s${RESET}\n" "Host key verification failed"          "ssh-keyscan github.com >> ~/.ssh/known_hosts"
    printf "  ${RED}%-42s${RESET}  ${CYAN}%s${RESET}\n" "Connection timed out"                  "E2 Network Check | check WiFi"
    echo ""

    _section "STEP 7 - PAT SETUP (HTTPS ALTERNATIVE)"
    info "Use a Personal Access Token if SSH isn't working:"
    tip "1. github.com >> Settings >> Developer settings >> Personal access tokens"
    tip "2. Generate token with 'repo' scope"
    tip "3. git remote set-url origin https://github.com/philfesters/REPO.git"
    tip "4. git push  (enter username + token as password)"
    tip "Cache: git config --global credential.helper store"

    _pause
}

_mod_e2() {
    _banner "E2  |  NETWORK CHECK"
    _synopsis "Public IP, interface info, ping test, DNS resolution, HTTPS reach check."

    _section "IP | DNS | PING | INTERFACE"
    info "Public IP:"
    curl -s --max-time 5 ipinfo.io/ip 2>/dev/null && echo "" \
        || warn "Could not reach ipinfo.io - check WiFi"
    echo ""

    _dvc
    info "Network interface:"
    ip addr 2>/dev/null | grep -E "inet |^[0-9]" | head -10 \
        || ifconfig 2>/dev/null | grep -E "inet |flags" | head -10 \
        || warn "ip/ifconfig not available"
    echo ""

    _dvc
    info "Ping test (8.8.8.8 Google DNS):"
    ping -c 3 8.8.8.8 2>/dev/null | tail -3 \
        || warn "ping failed - offline or firewall blocking ICMP"
    echo ""

    _dvc
    info "DNS resolution (google.com):"
    nslookup google.com 2>/dev/null | head -5 \
        || host google.com 2>/dev/null | head -3 \
        || warn "DNS resolution failed"
    echo ""

    _dvc
    info "HTTPS reach test:"
    curl -s --max-time 5 -o /dev/null -w "  HTTP status: %{http_code}  |  Time: %{time_total}s\n" \
        https://google.com 2>/dev/null \
        || warn "HTTPS test failed"
    echo ""

    _dvc
    info "Quick fix tips:"
    tip "No ping: check WiFi or mobile data is on"
    tip "DNS fail: pkg install dnsutils  or  use a proxy"
    tip "HTTPS fail: pkg install ca-certificates"

    _pause
}

_mod_e3() {
    _banner "E3  |  TOR & PROXYCHAINS"
    _synopsis "Checks tor install, starts daemon, verifies proxychains config, tests exit IP."

    _section "TOR STATUS | CIRCUIT TEST | PROXYCHAINS"
    info "Checking tor installation..."
    if command -v tor &>/dev/null; then
        ok "tor installed: $(command -v tor)"
    else
        warn "tor not installed"
        info "Install tor + proxychains?"
        _ask && {
            _spin "Installing tor"          "pkg install -y tor > /dev/null 2>&1"
            _spin "Installing proxychains"  "pkg install -y proxychains-ng > /dev/null 2>&1"
        }
    fi
    echo ""

    _dvc
    info "Checking if tor is running..."
    if pgrep -x tor &>/dev/null; then
        ok "tor process is running"
    else
        warn "tor not running"
        info "Start tor daemon?"
        _ask && {
            tor &>/dev/null &
            sleep 4
            pgrep -x tor &>/dev/null \
                && ok "tor started in background" \
                || warn "tor failed to start - check: tor --verify-config"
        }
    fi
    echo ""

    _dvc
    info "proxychains config:"
    printf "  ${FADE}Config: \${PREFIX}/etc/proxychains.conf${RESET}\n"
    printf "  ${FADE}Required line: socks5  127.0.0.1  9050${RESET}\n"
    echo ""
    grep -q "socks5.*9050" "${PREFIX}/etc/proxychains.conf" 2>/dev/null \
        && ok "socks5 127.0.0.1 9050 found in proxychains.conf" \
        || warn "socks5 line not found - add: socks5 127.0.0.1 9050"
    echo ""

    _dvc
    info "Test tor exit IP via proxychains?"
    _ask && {
        _spin "Testing tor circuit" \
            "proxychains4 curl -s --max-time 12 ipinfo.io/ip > ${TMPDIR:-$PREFIX/tmp}/_rb_tor_test.log 2>&1"
        local _tor_ip; _tor_ip=$(cat ${TMPDIR:-$PREFIX/tmp}/_rb_tor_test.log 2>/dev/null)
        [[ -n "$_tor_ip" ]] \
            && ok "Tor exit IP: $_tor_ip" \
            || warn "No response - tor may still be bootstrapping (wait 30s and retry)"
    }

    echo ""; _dvc
    tip "Use tor: proxychains4 curl <url>"
    tip "Use tor: proxychains4 nmap -sT <target>"
    tip "Check tor log: tor 2>&1 | head -20"

    _pause
}

# ══════════════════════════════════════════════════════════════════════
#  SECTION F - ENCYCLOPEDIA (REFERENCE)
# ══════════════════════════════════════════════════════════════════════

_mod_f1() {
    _banner "F1  |  ALIAS REFERENCE"
    _synopsis "Complete alias guide - launch, system, package, utility - all explained."

    _section "FEZZY STATION - COMPLETE ALIAS GUIDE"
    printf "  ${VIOLET}${BOLD}LAUNCH ALIASES${RESET}\n"; _dvc
    printf "  ${PINK}dl${RESET}             ${FADE}.${RESET}  ${WH}Launch Fezzy Station V61${RESET}\n"
    printf "  ${PINK}station${RESET}        ${FADE}.${RESET}  ${WH}Same as dl${RESET}\n"
    printf "  ${PINK}fezzy${RESET}          ${FADE}.${RESET}  ${WH}Same as dl${RESET}\n"
    printf "  ${PINK}rebuild${RESET}        ${FADE}.${RESET}  ${WH}bash ~/rebuild.sh${RESET}\n"
    printf "  ${PINK}arsenal${RESET}        ${FADE}.${RESET}  ${WH}bash ~/arsenal.sh - this script${RESET}\n"
    echo ""

    printf "  ${VIOLET}${BOLD}SYSTEM ALIASES${RESET}\n"; _dvc
    printf "  ${PINK}reload${RESET}         ${FADE}.${RESET}  ${WH}source ~/.bashrc - refresh all aliases${RESET}\n"
    printf "  ${PINK}cleanup${RESET}        ${FADE}.${RESET}  ${WH}bash ~/fezzy_cleanup.sh${RESET}\n"
    printf "  ${PINK}repair${RESET}         ${FADE}.${RESET}  ${WH}bash ~/termux-repair.sh${RESET}\n"
    printf "  ${PINK}detox${RESET}          ${FADE}.${RESET}  ${WH}quick apt autoremove + pkg clean${RESET}\n"
    printf "  ${PINK}tclear${RESET}         ${FADE}.${RESET}  ${WH}bash ~/termux-clear.sh${RESET}\n"
    echo ""

    printf "  ${VIOLET}${BOLD}PACKAGE ALIASES${RESET}\n"; _dvc
    printf "  ${PINK}pkgup${RESET}          ${FADE}.${RESET}  ${WH}pkg update && pkg upgrade${RESET}\n"
    printf "  ${PINK}pkgi${RESET}           ${FADE}.${RESET}  ${WH}pkg install <n>${RESET}\n"
    printf "  ${PINK}pkgr${RESET}           ${FADE}.${RESET}  ${WH}pkg remove <n>${RESET}\n"
    printf "  ${PINK}pkgs${RESET}           ${FADE}.${RESET}  ${WH}pkg search <n>${RESET}\n"
    printf "  ${PINK}pkglist${RESET}        ${FADE}.${RESET}  ${WH}pkg list-installed | less${RESET}\n"
    printf "  ${PINK}pipi${RESET}           ${FADE}.${RESET}  ${WH}pip install --break-system-packages${RESET}\n"
    printf "  ${PINK}pipup${RESET}          ${FADE}.${RESET}  ${WH}upgrade pip itself${RESET}\n"
    echo ""

    printf "  ${VIOLET}${BOLD}UTILITY ALIASES${RESET}\n"; _dvc
    printf "  ${PINK}myip${RESET}           ${FADE}.${RESET}  ${WH}curl ipinfo.io/ip - your public IP${RESET}\n"
    printf "  ${PINK}space${RESET}          ${FADE}.${RESET}  ${WH}du -sh ~/storage/downloads${RESET}\n"
    printf "  ${PINK}psall${RESET}          ${FADE}.${RESET}  ${WH}ps aux | head -20${RESET}\n"
    printf "  ${PINK}crystal${RESET}        ${FADE}.${RESET}  ${WH}python3 ~/pyphisher.py${RESET}\n"
    echo ""

    printf "  ${VIOLET}${BOLD}ADD ARSENAL ALIAS${RESET}\n"; _dvc
    printf "  ${FADE}  echo \"alias arsenal='bash ~/arsenal.sh'\" >> ~/.bashrc${RESET}\n"
    printf "  ${FADE}  source ~/.bashrc${RESET}\n"

    _pause
}

_mod_f2() {
    _banner "F2  |  ERROR CODE GUIDE"
    _synopsis "Common Termux errors - package manager, Python, bash, GitHub, storage - all with fixes."

    _section "COMMON TERMUX ERRORS + FIXES"
    printf "  ${VIOLET}${BOLD}PACKAGE MANAGER ERRORS${RESET}\n"; _dvc
    ref "E: dpkg was interrupted, you must manually run:"
    tip "Fix: dpkg --configure -a   then   apt-get install -f -y"
    echo ""
    ref "E: Could not get lock /var/lib/dpkg/lock"
    tip "Fix: rm -f \$PREFIX/var/lib/dpkg/lock*   then retry"
    echo ""
    ref "Failed to fetch | 404 Not Found | Hash Sum mismatch"
    tip "Fix: Run B2 Mirror Reset - change CDN to Cloudflare"
    echo ""
    ref "Temporary failure resolving / Could not resolve host"
    tip "Fix: Check WiFi/data | run E2 Network Check"
    echo ""

    printf "  ${VIOLET}${BOLD}PYTHON ERRORS${RESET}\n"; _dvc
    ref "error: externally-managed-environment"
    tip "Fix: Add --break-system-packages to every pip install"
    echo ""
    ref "ModuleNotFoundError: No module named 'X'"
    tip "Fix: pip install X --break-system-packages"
    echo ""
    ref "pip: command not found"
    tip "Fix: pkg install python-pip"
    echo ""

    printf "  ${VIOLET}${BOLD}BASH + SCRIPT ERRORS${RESET}\n"; _dvc
    ref "bash: command not found (alias not working)"
    tip "Fix: source ~/.bashrc   OR   add alias and reload"
    echo ""
    ref "Permission denied when running .sh file"
    tip "Fix: chmod +x ~/script.sh   then   bash ~/script.sh"
    echo ""
    ref "syntax error near unexpected token"
    tip "Fix: bash -n ~/script.sh - find the exact line number"
    echo ""

    printf "  ${VIOLET}${BOLD}GITHUB / GIT ERRORS${RESET}\n"; _dvc
    ref "rejected: non-fast-forward"
    tip "Fix: git pull --rebase origin main  then  git push"
    echo ""
    ref "remote: Permission to X denied"
    tip "Fix: Check SSH key in GitHub Settings | run E1"
    echo ""
    ref "fatal: not a git repository"
    tip "Fix: cd to project folder | git init"
    echo ""
    ref "src refspec main does not match"
    tip "Fix: git add .  &&  git commit -m 'msg'  then push"
    echo ""

    printf "  ${VIOLET}${BOLD}STORAGE ERRORS${RESET}\n"; _dvc
    ref "No such file or directory: ~/storage/downloads"
    tip "Fix: Run B5 Storage Recovery"
    echo ""
    ref "No space left on device"
    tip "Fix: Run C3 DETOX | check: df -h ~/"
    echo ""

    printf "  ${VIOLET}${BOLD}GO + SECURITY TOOL ERRORS${RESET}\n"; _dvc
    ref "nuclei: command not found after go install"
    tip "Fix: source ~/.bashrc   or   export PATH=\$PATH:\$(go env GOPATH)/bin"
    echo ""
    ref "go install: GOPATH error"
    tip "Fix: pkg install golang   then export PATH"

    _pause
}

_mod_f3() {
    _banner "F3  |  COMMON ISSUES MATRIX"
    _synopsis "Symptom >> module quick-router - find your fix by describing the problem."

    _section "SYMPTOM >> MODULE QUICK MATRIX"
    printf "  ${VIOLET}${BOLD}%-32s  %s${RESET}\n" "SYMPTOM" "MODULE / FIX"; _dvc
    printf "  ${WH}%-32s${RESET}  ${PINK}%s${RESET}\n" "Termux freezes/hangs/lags"       "C1 Performance Fix"
    printf "  ${WH}%-32s${RESET}  ${PINK}%s${RESET}\n" "pkg install fails"                "B1 Package Rescue"
    printf "  ${WH}%-32s${RESET}  ${PINK}%s${RESET}\n" "404 on pkg update"                "B2 Mirror Reset"
    printf "  ${WH}%-32s${RESET}  ${PINK}%s${RESET}\n" "Alias not found"                  "B4 Alias Repair >> source ~/.bashrc"
    printf "  ${WH}%-32s${RESET}  ${PINK}%s${RESET}\n" ".bashrc syntax error"             "B3 Validator & Fixer"
    printf "  ${WH}%-32s${RESET}  ${PINK}%s${RESET}\n" "storage/downloads missing"        "B5 Storage Recovery"
    printf "  ${WH}%-32s${RESET}  ${PINK}%s${RESET}\n" "yt-dlp / gallery-dl missing"      "D3 Media Tools Install"
    printf "  ${WH}%-32s${RESET}  ${PINK}%s${RESET}\n" "nuclei / trivy missing"           "D2 Security Hub Install"
    printf "  ${WH}%-32s${RESET}  ${PINK}%s${RESET}\n" "GitHub push fails"                "E1 SSH & GitHub"
    printf "  ${WH}%-32s${RESET}  ${PINK}%s${RESET}\n" "SSH key missing or rejected"      "E1 - Step 2 SSH Key"
    printf "  ${WH}%-32s${RESET}  ${PINK}%s${RESET}\n" "No internet / offline"            "E2 Network Check"
    printf "  ${WH}%-32s${RESET}  ${PINK}%s${RESET}\n" "Low storage / slow device"        "C3 DETOX Full Clean"
    printf "  ${WH}%-32s${RESET}  ${PINK}%s${RESET}\n" "Fresh Termux install"             "G2 One-Shot Fresh Install"
    printf "  ${WH}%-32s${RESET}  ${PINK}%s${RESET}\n" "pip externally-managed error"     "add --break-system-packages"
    printf "  ${WH}%-32s${RESET}  ${PINK}%s${RESET}\n" "Fezzy Station blank / errors"     "source ~/.bashrc >> dl"
    printf "  ${WH}%-32s${RESET}  ${PINK}%s${RESET}\n" "dpkg lock error"                  "rm lock >> B1 Rescue"
    printf "  ${WH}%-32s${RESET}  ${PINK}%s${RESET}\n" "nuclei not found after install"   "source ~/.bashrc >> GOPATH"
    printf "  ${WH}%-32s${RESET}  ${PINK}%s${RESET}\n" "termux-exec linker error"         "pkg install termux-exec >> reopen Termux"
    printf "  ${WH}%-32s${RESET}  ${PINK}%s${RESET}\n" "gum spinner not showing"          "pkg install gum >> D1"
    printf "  ${WH}%-32s${RESET}  ${PINK}%s${RESET}\n" "Unknown errors across board"      "A1 Environment Audit first"
    echo ""; _dvc
    info "Golden rule of SOI troubleshooting:"
    tip "1. bash -n ~/script.sh  - syntax check before anything"
    tip "2. source ~/.bashrc  - reload before assuming it's broken"
    tip "3. pkg update  - stale repos cause 30% of errors"
    tip "4. df -h ~/  - check storage before every major install"

    _pause
}

_mod_f4() {
    _banner "F4  |  SOI KNOWLEDGE BASE"
    _synopsis "Strategy Over Impulse - philosophy, workflow rules, 999 tribute, Bojack protocol."

    _section "STRATEGY OVER IMPULSE - PHILOSOPHY + WORKFLOW"
    printf "  ${VIOLET}${BOLD}THE CORE PHILOSOPHY${RESET}\n"; _dvc
    _type "${WH}" "  SOI  =  Strategy Over Impulse" 0.025
    _type "${FADE}" "  Think before you build. Audit before you fix. Plan before you deploy." 0.015
    echo ""

    printf "  ${VIOLET}${BOLD}THE FEZZY STATION WORKFLOW${RESET}\n"; _dvc
    printf "  ${PINK}1.${RESET}  ${WH}AUDIT FIRST${RESET}     ${FADE}- bash -n before running any script${RESET}\n"
    printf "  ${PINK}2.${RESET}  ${WH}BACKUP ALWAYS${RESET}   ${FADE}- cp ~/.bashrc ~/.bashrc.bak before edits${RESET}\n"
    printf "  ${PINK}3.${RESET}  ${WH}TEST CLEAN${RESET}      ${FADE}- syntax check with bash -n after writing${RESET}\n"
    printf "  ${PINK}4.${RESET}  ${WH}DEPLOY SAFE${RESET}     ${FADE}- source line commented by default${RESET}\n"
    printf "  ${PINK}5.${RESET}  ${WH}MANUAL LAUNCH${RESET}   ${FADE}- use dl / station / rebuild / arsenal aliases${RESET}\n"
    printf "  ${PINK}6.${RESET}  ${WH}VERSION BUMP${RESET}    ${FADE}- V61 | V62 - never overwrite, always new${RESET}\n"
    echo ""

    printf "  ${VIOLET}${BOLD}THE 999 TRIBUTE${RESET}\n"; _dvc
    _type "${FADE}" "  999 is woven into every Fezzy Station project." 0.015
    _type "${FADE}" "  A tribute to Juice WRLD - pain turned into architecture." 0.015
    _type "${FADE}" "  Strategy Over Impulse is the answer to Lucid Dreams." 0.015
    echo ""

    printf "  ${VIOLET}${BOLD}BOJACK PROTOCOL${RESET}\n"; _dvc
    _type "${FADE}" "  Bojack is the K9 Security Daemon - Labrador-Husky." 0.015
    _type "${FADE}" "  He watches the wire. He catches what you miss." 0.015
    _type "${FADE}" "  Every build is Bojack certified. Every version is 999 stamped. [K9]" 0.015
    echo ""

    printf "  ${VIOLET}${BOLD}ENVIRONMENT RULES${RESET}\n"; _dvc
    tip "No root commands - ever"
    tip "No gum choose / gum input - Android Termux incompatible"
    tip "Download paths always to ~/storage/downloads"
    tip "vim for .sh files - never nano in production"
    tip "Capital-V versioning - V61, V62, not v61"
    tip "Complete files only - no partial snippets"
    tip "--break-system-packages on every pip install"
    echo ""; _dvc
    printf "  ${FADE}\"Ravensmead >> Cape Town >> The World\"${RESET}\n"
    printf "  ${FADE}Strategy Over Impulse  |  philfesters  |  999${RESET}\n"

    _pause
}

# ══════════════════════════════════════════════════════════════════════
#  SECTION G - AUTO-REPAIR & FRESH INSTALL
# ══════════════════════════════════════════════════════════════════════

_mod_g1() {
    _banner "G1  |  FULL AUTO-REPAIR"
    _synopsis "Runs all repair modules sequentially - dpkg, apt, bashrc, storage, cache, procs. No prompts."

    _section "SEQUENTIAL FIX-ALL - NO INTERRUPTS"
    printf "  ${WH}Runs: pkg rescue >> dpkg fix >> bashrc check >> storage >> cleanup${RESET}\n"
    printf "  ${FADE}Non-interactive. Spinners confirm each step.${RESET}\n"
    echo ""
    info "Confirm full auto-repair run?"
    _ask || { _show_menu; return; }
    echo ""
    info "Starting full repair - Bojack's on the wire"; echo ""

    _spin "Clearing dpkg lock files" \
        "rm -f \$PREFIX/var/lib/dpkg/lock* \$PREFIX/var/cache/apt/archives/lock 2>/dev/null; true"
    _spin "dpkg --configure -a"     "dpkg --configure -a > /dev/null 2>&1; true"
    _spin "apt-get install -f"      "apt-get install -f -y > /dev/null 2>&1; true"
    _spin "pkg update"              "pkg update -y > /dev/null 2>&1"
    _spin "pkg upgrade"             "pkg upgrade -y > /dev/null 2>&1"
    _spin "apt autoremove"          "apt autoremove -y > /dev/null 2>&1; true"
    _spin "pkg clean"               "pkg clean > /dev/null 2>&1; true"

    _dvc
    local BASHRC=~/.bashrc
    if bash -n "$BASHRC" 2>/dev/null; then ok ".bashrc syntax OK"
    else warn ".bashrc has errors - run B3 manually"; fi

    grep -q "pkg autoremove" "$BASHRC" 2>/dev/null && {
        sed -i 's/pkg autoremove/apt autoremove/g' "$BASHRC"
        ok "Fixed: pkg autoremove >> apt autoremove"
    }

    _dvc
    _spin "termux-setup-storage"   "termux-setup-storage 2>/dev/null; sleep 2"
    _spin "Clearing tmp/fezzy_*"   "rm -f ${TMPDIR:-$PREFIX/tmp}/fezzy_* 2>/dev/null; true"
    _spin "Clearing ~/.cache"      "rm -rf ~/.cache/pip ~/.cache/yt-dlp 2>/dev/null; true"
    _spin "Killing stale procs"    "pkill -x mpv 2>/dev/null; pkill -x wget 2>/dev/null; true"
    _spin "termux-reload-settings" "termux-reload-settings 2>/dev/null; true"

    echo ""; _dv
    printf "  ${PINK}${BOLD}FULL AUTO-REPAIR COMPLETE  *  999${RESET}\n"; _dv; echo ""
    printf "  ${WH}Run: ${PINK}source ~/.bashrc${RESET}  to reload your shell\n"
    printf "  ${FADE}Bojack certified. Strategy Over Impulse. 999. [K9]${RESET}\n"

    _pause
}

_mod_g2() {
    _banner "G2  |  ONE-SHOT FRESH INSTALL"
    _synopsis "Builds the complete Fezzy Station environment from scratch - 7 modules, no root."

    _section "FULL TERMUX ENV SETUP - NO ROOT"
    printf "  ${WH}Core tools | Python | Node | Go | Security | OSINT | ~/.bashrc | aliases${RESET}\n"
    printf "  ${FADE}No root required | Android 14 | Termux only${RESET}\n"
    printf "  ${RED}${BOLD}Run once after a fresh Termux install or full wipe.${RESET}\n"
    printf "  ${FADE}Takes 15-40 minutes. Don't tap out halfway. Let it cook.${RESET}\n"
    echo ""
    info "Confirm one-shot fresh install?"
    _ask || { _show_menu; return; }

    # -- MODULE 1 - STORAGE
    _section "G2-1 | STORAGE PERMISSION"
    if [[ -d ~/storage/downloads ]]; then ok "Storage already linked"
    else _spin "Requesting storage permission" "termux-setup-storage 2>/dev/null; sleep 2"; fi
    export DLDIR=~/storage/downloads
    mkdir -p ~/storage/downloads 2>/dev/null
    ok "DLDIR >> ~/storage/downloads"

    # -- MODULE 2 - REPOS
    _section "G2-2 | UPDATE & UPGRADE"
    printf "  ${FADE}If this hangs, run: termux-change-repo${RESET}\n\n"
    _spin "pkg update"  "pkg update -y > /dev/null 2>&1"
    _spin "pkg upgrade" "pkg upgrade -y > /dev/null 2>&1"

    # -- MODULE 3 - CORE PACKAGES
    _section "G2-3 | CORE SYSTEM PACKAGES"
    _spin "curl wget git openssh"           "pkg install -y curl wget git openssh > /dev/null 2>&1"
    _spin "vim nano"                        "pkg install -y vim nano > /dev/null 2>&1"
    _spin "python + pip"                    "pkg install -y python python-pip > /dev/null 2>&1"
    _spin "nodejs"                          "pkg install -y nodejs > /dev/null 2>&1"
    _spin "ffmpeg + mpv"                    "pkg install -y ffmpeg mpv > /dev/null 2>&1"
    _spin "nmap socat proxychains-ng tor"   "pkg install -y nmap socat proxychains-ng tor > /dev/null 2>&1"
    _spin "termux-api iproute2 dnsutils"    "pkg install -y termux-api iproute2 dnsutils > /dev/null 2>&1"
    _spin "tmux jq gawk coreutils"          "pkg install -y tmux jq grep sed gawk coreutils > /dev/null 2>&1"
    _spin "tar zip unzip proot"             "pkg install -y tar zip unzip proot > /dev/null 2>&1"
    _spin "lsof htop file whois"            "pkg install -y lsof htop file whois traceroute > /dev/null 2>&1"
    _spin "openssl gnupg"                   "pkg install -y openssl-tool gnupg > /dev/null 2>&1"
    _spin "aria2 gh pandoc"                 "pkg install -y aria2 gh pandoc > /dev/null 2>&1"
    _spin "nikto lynis hydra perl exiftool" "pkg install -y nikto lynis hydra perl exiftool > /dev/null 2>&1"
    _spin "gum ncurses-utils"               "pkg install -y gum ncurses-utils > /dev/null 2>&1"

    # -- MODULE 4 - PYTHON TOOLS
    _section "G2-4 | PYTHON TOOLS"
    _spin "yt-dlp"                    "pip install yt-dlp --break-system-packages -q 2>/dev/null"
    _spin "gallery-dl"                "pip install gallery-dl --break-system-packages -q 2>/dev/null"
    _spin "spotdl"                    "pip install spotdl --break-system-packages -q 2>/dev/null"
    _spin "mutagen"                   "pip install mutagen --break-system-packages -q 2>/dev/null"
    _spin "reportlab PyPDF2"          "pip install reportlab PyPDF2 --break-system-packages -q 2>/dev/null"
    _spin "sherlock-project"          "pip install sherlock-project --break-system-packages -q 2>/dev/null"
    _spin "holehe maigret"            "pip install holehe maigret --break-system-packages -q 2>/dev/null"
    _spin "photon theHarvester"       "pip install photon theHarvester --break-system-packages -q 2>/dev/null"
    _spin "wfuzz dnsrecon dnspython"  "pip install wfuzz dnsrecon dnspython --break-system-packages -q 2>/dev/null"
    _spin "requests lxml bs4"         "pip install requests lxml beautifulsoup4 --break-system-packages -q 2>/dev/null"

    # -- MODULE 5 - NODE
    _section "G2-5 | NODE & NPM TOOLS"
    _spin "webtorrent-cli" "npm install -g webtorrent-cli 2>/dev/null"

    # -- MODULE 6 - GO + SECURITY
    _section "G2-6 | GO ENVIRONMENT + SECURITY TOOLS"
    _spin "golang" "pkg install -y golang > /dev/null 2>&1"
    if command -v go &>/dev/null; then
        export PATH=$PATH:$(go env GOPATH)/bin
        grep -q "GOPATH" ~/.bashrc 2>/dev/null || \
            echo 'export PATH=$PATH:'"$(go env GOPATH)/bin" >> ~/.bashrc
        _spin "nuclei   (go)"  "go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest > /dev/null 2>&1"
        _spin "trivy    (go)"  "go install github.com/aquasecurity/trivy/cmd/trivy@latest > /dev/null 2>&1"
        _spin "subfinder (go)" "go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest > /dev/null 2>&1"
        _spin "gobuster (go)"  "go install github.com/OJ/gobuster/v3@latest > /dev/null 2>&1"
        _spin "httpx    (go)"  "go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest > /dev/null 2>&1"
        ok "Go PATH added to ~/.bashrc"
    else
        warn "golang unavailable - go tools skipped"
    fi

    # -- MODULE 7 - BASHRC
    _section "G2-7 | ~/.BASHRC REBUILD"
    local BASHRC=~/.bashrc
    [[ -f "$BASHRC" ]] && cp "$BASHRC" "${BASHRC}.bak_g2_$(date +%Y%m%d_%H%M%S)" && ok "~/.bashrc backed up"

    grep -q "ARSENAL" "$BASHRC" 2>/dev/null || cat >> "$BASHRC" << 'RCBLOCK'

# --- ARSENAL / FEZZY STATION ------------------------------------
# source ~/fezzy_station_v61.sh   <- uncomment to auto-load

# --- LAUNCH ALIASES ---------------------------------------------
alias dl='bash ~/fezzy_station_v61.sh'
alias fezzy='bash ~/fezzy_station_v61.sh'
alias station='bash ~/fezzy_station_v61.sh'
alias arsenal='bash ~/arsenal.sh'
alias rebuild='bash ~/arsenal.sh'

# --- TOOLSET ALIASES --------------------------------------------
alias reload='source ~/.bashrc && echo "[ Reloaded | SOI | 999 ]"'
alias tclear='bash ~/termux-clear.sh'
alias repair='bash ~/arsenal.sh'
alias pkgup='pkg update -y && pkg upgrade -y'
alias pkgi='pkg install'
alias pkgr='pkg remove'
alias pkgs='pkg search'
alias pkglist='pkg list-installed | less'
alias pipi='pip install --break-system-packages'
alias pipup='pip install --upgrade pip --break-system-packages'
alias myip='curl -s ipinfo.io/ip && echo ""'
alias space='du -sh ~/storage/downloads'
alias psall='ps aux | head -20'

# --- ENV --------------------------------------------------------
export DLDIR=~/storage/downloads
export PATH=$PREFIX/bin:$HOME/.local/bin:$PATH:$(go env GOPATH 2>/dev/null)/bin

RCBLOCK
    ok "~/.bashrc rebuilt - Arsenal + all aliases locked"

    # -- POST-INSTALL CHECK
    echo ""; _dv
    printf "  ${PINK}${BOLD}G2 POST-INSTALL CHECK${RESET}\n"; _dv; echo ""
    for cmd in curl wget git vim python3 pip node ffmpeg mpv yt-dlp gallery-dl \
               nmap socat tor nikto aria2c gpg openssl gh gum; do
        command -v "$cmd" &>/dev/null \
            && printf "  ${GRN}[OK]${RESET}  ${WH}%s${RESET}\n" "$cmd" \
            || printf "  ${YEL}[!!]${RESET}  ${WH}%s - missing${RESET}\n" "$cmd"
    done

    echo ""; _dv
    printf "  ${PINK}${BOLD}ONE-SHOT FRESH INSTALL COMPLETE  *  999${RESET}\n"; _dv; echo ""
    printf "  ${CYAN}1.${RESET}  ${WH}Copy station script:${RESET}  ${PINK}cp /sdcard/Download/fezzy_station_v61.sh ~/\n${RESET}"
    printf "  ${CYAN}2.${RESET}  ${WH}Reload shell:${RESET}         ${PINK}source ~/.bashrc\n${RESET}"
    printf "  ${CYAN}3.${RESET}  ${WH}Launch station:${RESET}       ${PINK}dl\n${RESET}"
    echo ""
    printf "  ${FADE}Bojack watched every step. The wire is clean. 999. [K9]${RESET}\n"

    _pause
}

# ══════════════════════════════════════════════════════════════════════
#  SECTION H - EXTRAS
# ══════════════════════════════════════════════════════════════════════

_mod_h1() {
    _banner "H1  |  BACKUP & RESTORE"
    _synopsis "Creates a tar.gz of your .bashrc, shell scripts, and configs to /sdcard/Download."

    _section "BACKUP - TAR TO /SDCARD/DOWNLOAD"
    local _bname="arsenal_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    local _bdest=~/storage/downloads
    local _bpath="${_bdest}/${_bname}"

    info "What gets backed up:"
    tip "~/.bashrc"
    tip "~/arsenal.sh  ~/rebuild.sh  ~/detox.sh  ~/recover.sh"
    tip "~/fezzy_station_v61.sh  ~/termux-clear.sh  ~/termux-repair.sh"
    tip "~/.ssh/ (public key only - NOT private key)"
    echo ""

    [[ ! -d "$_bdest" ]] && {
        warn "~/storage/downloads not found - run B5 first"
        _pause; return
    }

    info "Create backup now?"
    _ask || { _pause; return; }
    echo ""

    _spin "Creating backup archive" \
        "tar -czf '${_bpath}' ~/.bashrc \
         "${ARSENAL_SCRIPT}" ~/rebuild.sh ~/detox.sh ~/recover.sh \
         "${STATION_SCRIPT}" ~/termux-clear.sh ~/termux-repair.sh \
         ~/.ssh/id_ed25519.pub 2>/dev/null; true"

    if [[ -f "$_bpath" ]]; then
        ok "Backup saved: $(basename $_bpath)"
        printf "  ${FADE}Location: %s${RESET}\n" "$_bpath"
        printf "  ${FADE}Size:     %s${RESET}\n" "$(du -sh $_bpath 2>/dev/null | cut -f1)"
    else
        warn "Backup may be incomplete - some files skipped (that's OK)"
    fi

    echo ""; _dvc
    info "RESTORE INSTRUCTIONS:"
    tip "tar -xzf /sdcard/Download/${_bname} -C /"
    tip "source ~/.bashrc"
    tip "Then run G2 or D1 to reinstall packages"

    _pause
}

_mod_h2() {
    _banner "H2  |  DEV ENVIRONMENT SETUP"
    _synopsis "Configures vim, git, tmux, and verifies Go PATH - one-shot dev environment polish."

    _section "VIM CONFIG"
    info "Write a minimal ~/.vimrc?"
    _ask && {
        cat > ~/.vimrc << 'VIMRC'
set number
set tabstop=4
set shiftwidth=4
set expandtab
set autoindent
set syntax=on
set background=dark
set noswapfile
set encoding=utf-8
VIMRC
        ok "~/.vimrc written - line numbers, 4-space indent, syntax on"
    }

    echo ""; _section "GIT GLOBAL CONFIG"
    local _gn _ge
    _gn=$(git config --global user.name 2>/dev/null)
    _ge=$(git config --global user.email 2>/dev/null)
    [[ -n "$_gn" ]] && ok "git user.name: $_gn" || warn "git user.name not set"
    [[ -n "$_ge" ]] && ok "git user.email: $_ge" || warn "git user.email not set"
    echo ""
    info "Set git config now?"
    _ask && {
        printf "  ${PINK}Name  >> ${RESET}"; read -r _n; echo ""
        printf "  ${PINK}Email >> ${RESET}"; read -r _e; echo ""
        [[ -n "$_n" ]] && git config --global user.name "$_n" && ok "Name set"
        [[ -n "$_e" ]] && git config --global user.email "$_e" && ok "Email set"
        git config --global init.defaultBranch main 2>/dev/null
        ok "Default branch: main"
    }

    echo ""; _section "TMUX CONFIG"
    info "Write a minimal ~/.tmux.conf?"
    _ask && {
        cat > ~/.tmux.conf << 'TMUXCONF'
set -g default-terminal "screen-256color"
set -g mouse on
set -g history-limit 10000
set -g base-index 1
set -g status-style bg=colour235,fg=colour213
set -g status-left "#[fg=colour198,bold] [K9] BOJACK "
set -g status-right "#[fg=colour51] %H:%M  SOI  999 "
TMUXCONF
        ok "~/.tmux.conf written - mouse on, 256 color, Bojack statusbar"
    }

    echo ""; _section "GO PATH CHECK"
    if command -v go &>/dev/null; then
        local _gopath; _gopath=$(go env GOPATH)/bin
        ok "Go installed: $(go version | awk '{print $3}')"
        [[ ":$PATH:" == *":$_gopath:"* ]] \
            && ok "GOPATH/bin in PATH" \
            || {
                warn "GOPATH/bin not in PATH"
                info "Add to ~/.bashrc?"
                _ask && {
                    echo "export PATH=\$PATH:${_gopath}" >> ~/.bashrc
                    ok "GOPATH added to ~/.bashrc - run: source ~/.bashrc"
                }
            }
    else
        warn "Go not installed - run D2 or D1"
    fi

    _pause
}

_mod_h3() {
    _banner "H3  |  ANDROID BRIDGE CHECK"
    _synopsis "Checks termux-api installation, tests clipboard, vibration, and notification."

    _section "TERMUX-API STATUS"
    info "Checking termux-api package..."
    if command -v termux-clipboard-get &>/dev/null; then
        ok "termux-api installed"
    else
        warn "termux-api not installed"
        info "Install termux-api?"
        _ask && _spin "Installing termux-api" "pkg install -y termux-api > /dev/null 2>&1"
    fi
    echo ""

    info "Checking Termux:API Android app..."
    tip "App must be installed from F-Droid or Play Store for API calls to work"
    tip "F-Droid: search 'Termux:API' - install alongside the Termux app"
    echo ""

    _dvc
    info "Test clipboard read?"
    _ask && {
        local _clip; _clip=$(termux-clipboard-get 2>/dev/null)
        if [[ -n "$_clip" ]]; then
            ok "Clipboard contents retrieved"
            printf "  ${FADE}Content: %s${RESET}\n" "${_clip:0:60}"
        else
            warn "Clipboard empty or API not responding"
        fi
    }

    echo ""; _dvc
    info "Test vibration?"
    _ask && {
        termux-vibrate -d 200 2>/dev/null \
            && ok "Vibration triggered - 200ms" \
            || warn "Vibration failed - check Termux:API app is installed"
    }

    echo ""; _dvc
    info "Send a test notification?"
    _ask && {
        termux-notification --title "ARSENAL | SOI | 999" \
            --content "Bojack says the wire is clean. [K9]" 2>/dev/null \
            && ok "Notification sent" \
            || warn "Notification failed - check Termux:API app"
    }

    echo ""; _dvc
    info "Available termux-api commands on this device:"
    local _api_cmds=(termux-clipboard-get termux-clipboard-set termux-vibrate
                     termux-notification termux-battery-status termux-wifi-connectioninfo
                     termux-sensor termux-camera-photo termux-sms-list termux-location)
    for cmd in "${_api_cmds[@]}"; do
        command -v "$cmd" &>/dev/null \
            && ok "$cmd" \
            || warn "$cmd - missing"
    done

    _pause
}

# ══════════════════════════════════════════════════════════════════════
#  [S] SEARCH - KEYWORD >> MODULE ROUTER
# ══════════════════════════════════════════════════════════════════════
_mod_search() {
    _banner "SEARCH - TYPE YOUR PROBLEM"
    _synopsis "Type a keyword describing the issue - Bojack routes you to the right module."

    _section "KEYWORD >> MODULE ROUTER"
    printf "  ${WH}Describe what's broken - ARSENAL routes you to the fix.${RESET}\n"
    printf "  ${FADE}Examples: freeze | broken | mirror | alias | storage | ssh | slow | backup${RESET}\n"
    echo ""
    printf "  ${HOT}${BOLD}Problem >> ${RESET}"
    read -r _query
    _query="${_query,,}"
    echo ""; _dvf; echo ""

    local _dest_label="" _dest_fn=""

    if   [[ "$_query" =~ (freez|slow|hang|stuck|lag|kill|proc|cpu|ram|memory) ]]; then
        _dest_label="C1  |  Performance & Freeze Fix";      _dest_fn="_mod_c1"
    elif [[ "$_query" =~ (detox|clean|cache|junk|space|full|disk|tmp|wipe) ]]; then
        _dest_label="C3  |  DETOX Full Clean";              _dest_fn="_mod_c3"
    elif [[ "$_query" =~ (pkg|apt|broken|lock|install|depend|dpkg|upgrade|repo) ]]; then
        _dest_label="B1  |  Package Manager Rescue";        _dest_fn="_mod_b1"
    elif [[ "$_query" =~ (mirror|cdn|404|offline|source|fetch|update.fail) ]]; then
        _dest_label="B2  |  Mirror Reset";                  _dest_fn="_mod_b2"
    elif [[ "$_query" =~ (bashrc|\.bashrc|source|syntax|script|alias.error) ]]; then
        _dest_label="B3  |  .bashrc Validator & Fixer";     _dest_fn="_mod_b3"
    elif [[ "$_query" =~ (alias|command|not.found|dl|station|reload|fezzy) ]]; then
        _dest_label="B4  |  Alias Repair & Explainer";      _dest_fn="_mod_b4"
    elif [[ "$_query" =~ (storage|sdcard|permission|download|symlink) ]]; then
        _dest_label="B5  |  Storage Recovery";              _dest_fn="_mod_b5"
    elif [[ "$_query" =~ (ssh|git|push|github|key|auth|remote|commit|branch|reject) ]]; then
        _dest_label="E1  |  SSH & GitHub Troubleshoot";     _dest_fn="_mod_e1"
    elif [[ "$_query" =~ (network|ip|dns|ping|wifi|internet|connect|offline) ]]; then
        _dest_label="E2  |  Network Check";                 _dest_fn="_mod_e2"
    elif [[ "$_query" =~ (tor|proxy|proxychains|anonymous|onion|socks) ]]; then
        _dest_label="E3  |  Tor & Proxychains";             _dest_fn="_mod_e3"
    elif [[ "$_query" =~ (nuclei|trivy|nikto|lynis|gobuster|security|scanner) ]]; then
        _dest_label="D2  |  Security Hub Install";          _dest_fn="_mod_d2"
    elif [[ "$_query" =~ (yt.dlp|gallery|media|video|music|audio|spotdl|ffmpeg) ]]; then
        _dest_label="D3  |  Media Tools Install";           _dest_fn="_mod_d3"
    elif [[ "$_query" =~ (osint|photon|harvest|exif|metadata|recon|sherlock|holehe) ]]; then
        _dest_label="D4  |  OSINT Tools Install";           _dest_fn="_mod_d4"
    elif [[ "$_query" =~ (rebuild|fresh|wipe|reinstall|restore|reset|new.phone) ]]; then
        _dest_label="G2  |  One-Shot Fresh Install";        _dest_fn="_mod_g2"
    elif [[ "$_query" =~ (auto|repair|all|fix.everything|everything) ]]; then
        _dest_label="G1  |  Full Auto-Repair";              _dest_fn="_mod_g1"
    elif [[ "$_query" =~ (error|code|what.does|mean|message|unknown) ]]; then
        _dest_label="F2  |  Error Code Guide";              _dest_fn="_mod_f2"
    elif [[ "$_query" =~ (audit|check|path|env|environment|info) ]]; then
        _dest_label="A1  |  Environment Audit";             _dest_fn="_mod_a1"
    elif [[ "$_query" =~ (python|pip|module|package.missing|venv) ]]; then
        _dest_label="A4  |  Python Environment";            _dest_fn="_mod_a4"
    elif [[ "$_query" =~ (backup|restore|save|config|archive) ]]; then
        _dest_label="H1  |  Backup & Restore";              _dest_fn="_mod_h1"
    elif [[ "$_query" =~ (vim|git.config|tmux|dev|editor|setup) ]]; then
        _dest_label="H2  |  Dev Environment Setup";         _dest_fn="_mod_h2"
    elif [[ "$_query" =~ (android|api|notification|vibrate|clipboard|termux.api) ]]; then
        _dest_label="H3  |  Android Bridge Check";          _dest_fn="_mod_h3"
    else
        _dest_label="A1  |  Environment Audit  (no direct match - starting broad)"
        _dest_fn="_mod_a1"
    fi

    printf "  ${CYAN}*  Found:${RESET}  ${HOT}${BOLD}%s${RESET}\n" "$_dest_label"
    echo ""
    printf "  ${HOT}${BOLD}[ENTER]${RESET}  ${WH}Go to module  ${PINK}[m]${RESET}  ${WH}Back to menu${RESET}  > "
    read -r _confirm
    echo ""
    [[ "${_confirm,,}" == "m" ]] && _show_menu || "$_dest_fn"
}

_mod_i1() {
    _banner "I1  --  ORPHAN & GHOST FILES"
    _synopsis "Finds broken symlinks, stale tmp files, partial downloads. Ask before each delete."

    _section "BROKEN SYMLINKS"
    info "Scanning for broken symlinks in ~ (max depth 5)..."
    echo ""
    local _bslinks
    _bslinks=$(find ~ -maxdepth 5 -xtype l 2>/dev/null | grep -v "proc\|dev\|sys\|\.git" || true)
    local _bsc; _bsc=$(echo "$_bslinks" | grep -c '.' 2>/dev/null || echo 0)
    if [[ -z "$_bslinks" || "$_bsc" -eq 0 ]]; then
        ok "No broken symlinks found"
    else
        warn "$_bsc broken symlink(s) found:"
        echo "$_bslinks" | while IFS= read -r ln; do
            [[ -n "$ln" ]] && printf "  ${RED}  %s${RESET}\n" "$ln"
        done
        echo ""
        info "Remove broken symlinks?"
        _ask && {
            echo "$_bslinks" | while IFS= read -r ln; do
                [[ -n "$ln" ]] && rm -f "$ln" 2>/dev/null && ok "Removed: $ln"
            done
        }
    fi

    echo ""; _section "STALE / PARTIAL FILES"
    info "Scanning for .part .tmp .crdownload .download files..."
    local _stale
    _stale=$(find "${TMPDIR:-$PREFIX/tmp}" ~ ~/storage/downloads /sdcard/Download 2>/dev/null \
        -maxdepth 5 \( -name "*.part" -o -name "*.tmp" -o -name "*.crdownload" -o -name "*.download" \) \
        2>/dev/null | grep -v "^$" || true)
    local _sc; _sc=$(echo "$_stale" | grep -c '.' 2>/dev/null || echo 0)
    printf "  ${YEL}  Found: %s stale/partial file(s)${RESET}\n\n" "$_sc"
    if [[ "$_sc" -gt 0 ]]; then
        echo "$_stale" | head -20 | while IFS= read -r f; do
            [[ -n "$f" ]] && printf "  ${FADE}  %s${RESET}\n" "$f"
        done
        echo ""
        info "Delete stale/partial files?"
        _ask && {
            echo "$_stale" | while IFS= read -r f; do
                [[ -f "$f" && -n "$f" ]] && rm -f "$f" 2>/dev/null && ok "Removed: $(basename "$f")"
            done
        }
    else
        ok "No stale files found"
    fi

    echo ""; _section "OLD TMP FILES (30+ DAYS)"
    local _oldtmp_c
    _oldtmp_c=$(find "${TMPDIR:-$PREFIX/tmp}" -maxdepth 2 -mtime +30 2>/dev/null | wc -l || echo 0)
    printf "  ${YEL}  Files older than 30 days in TMPDIR: %s${RESET}\n\n" "$_oldtmp_c"
    if [[ "$_oldtmp_c" -gt 0 ]]; then
        info "Clear old TMPDIR files?"
        _ask && _spin "Clearing old tmp files" \
            "find '${TMPDIR:-$PREFIX/tmp}' -maxdepth 2 -mtime +30 -delete 2>/dev/null; true"
    else
        ok "TMPDIR is clean"
    fi

    _pause
}

_mod_i2() {
    _banner "I2  --  DUPLICATE FILE HUNTER"
    _synopsis "Finds likely duplicates in Downloads by pattern matching. Review before any delete."

    _section "SCANNING DOWNLOADS"
    local _scan_dir="${DLDIR:-$HOME/storage/downloads}"
    if [[ ! -d "$_scan_dir" ]]; then
        warn "Downloads folder not found  --  run B5 Storage Recovery first"
        _pause; return
    fi
    info "Scanning: $_scan_dir"
    echo ""

    _section "PATTERN: COPY FILES  (name (N).ext)"
    local _copy_files
    _copy_files=$(find "$_scan_dir" -maxdepth 5 -type f 2>/dev/null \
        | grep -E ' \([0-9]+\)\.[^/]+$' | head -30 || true)
    local _cfc; _cfc=$(echo "$_copy_files" | grep -c '.' 2>/dev/null || echo 0)
    if [[ "$_cfc" -gt 0 ]]; then
        warn "$_cfc copy-pattern file(s) found:"
        echo "$_copy_files" | while IFS= read -r f; do
            [[ -n "$f" ]] && printf "  ${YEL}  %s${RESET}\n" "$(basename "$f")"
        done
        echo ""
        tip "Review manually then: rm -f 'filename'"
    else
        ok "No copy-pattern files found"
    fi

    echo ""; _section "PATTERN: SAME FILENAME IN MULTIPLE LOCATIONS"
    local _dupes
    _dupes=$(find "$_scan_dir" -maxdepth 5 -type f 2>/dev/null \
        | awk -F/ '{print $NF}' | sort | uniq -d | head -20 || true)
    local _dc; _dc=$(echo "$_dupes" | grep -c '.' 2>/dev/null || echo 0)
    if [[ "$_dc" -gt 0 ]]; then
        warn "$_dc duplicate filename(s):"
        echo "$_dupes" | while IFS= read -r name; do
            [[ -n "$name" ]] && printf "  ${YEL}  %s${RESET}\n" "$name"
        done
        echo ""
        info "Show full paths for a filename?"
        _ask && {
            printf "  ${PINK}${BOLD}Filename > ${RESET}"; read -r _fname; echo ""
            [[ -n "$_fname" ]] && find "$_scan_dir" -maxdepth 5 -name "$_fname" 2>/dev/null | while IFS= read -r p; do
                printf "  ${FADE}  %s  (%s)${RESET}\n" "$p" "$(du -sh "$p" 2>/dev/null | cut -f1)"
            done
        }
    else
        ok "No duplicate filenames found"
    fi

    echo ""; _dvc
    tip "To delete a file: rm -f '/full/path/to/file'"
    tip "Review before deleting  --  no undo"

    _pause
}

_mod_i3() {
    _banner "I3  --  EMPTY FOLDER SWEEP"
    _synopsis "Finds empty directories in home and storage. Ask before removing each batch."

    _section "EMPTY DIRS IN HOME"
    local _empty_home
    _empty_home=$(find ~ -maxdepth 6 -type d -empty 2>/dev/null \
        | grep -v '\.git\|\.ssh\|\.gnupg\|node_modules\|__pycache__' || true)
    local _ehc; _ehc=$(echo "$_empty_home" | grep -c '.' 2>/dev/null || echo 0)
    printf "  ${YEL}  Found: %s empty dir(s) in ~${RESET}\n\n" "$_ehc"

    if [[ "$_ehc" -gt 0 ]]; then
        echo "$_empty_home" | while IFS= read -r d; do
            [[ -n "$d" ]] && printf "  ${FADE}  %s${RESET}\n" "$d"
        done
        echo ""
        info "Remove empty home directories?"
        _ask && {
            echo "$_empty_home" | while IFS= read -r d; do
                [[ -d "$d" && -n "$d" ]] && rmdir "$d" 2>/dev/null && ok "Removed: $d"
            done
        }
    else
        ok "No empty directories in home"
    fi

    echo ""; _section "EMPTY DIRS IN DOWNLOADS"
    info "Scan ~/storage/downloads for empty dirs?"
    _ask && {
        local _empty_dl
        _empty_dl=$(find ~/storage/downloads -maxdepth 6 -type d -empty 2>/dev/null || true)
        local _edc; _edc=$(echo "$_empty_dl" | grep -c '.' 2>/dev/null || echo 0)
        printf "  ${YEL}  Found: %s empty folder(s) in downloads${RESET}\n\n" "$_edc"
        if [[ "$_edc" -gt 0 ]]; then
            echo "$_empty_dl" | while IFS= read -r d; do
                [[ -n "$d" ]] && printf "  ${FADE}  %s${RESET}\n" "$d"
            done
            echo ""
            info "Remove them?"
            _ask && {
                echo "$_empty_dl" | while IFS= read -r d; do
                    [[ -d "$d" && -n "$d" ]] && rmdir "$d" 2>/dev/null && ok "Removed: $(basename "$d")"
                done
            }
        else
            ok "No empty dirs in downloads"
        fi
    } || printf "  ${FADE}  skipped${RESET}\n"

    _pause
}

_mod_i4() {
    _banner "I4  --  DEAD DEPS & RESIDUALS"
    _synopsis "Residual config packages, orphaned deps, stale pip packages, unused Go binaries."

    _section "RESIDUAL CONFIG PACKAGES (dpkg rc state)"
    info "Packages removed but configs still on disk:"
    echo ""
    local _rc_pkgs
    _rc_pkgs=$(dpkg -l 2>/dev/null | awk '/^rc/{print $2}' || true)
    if [[ -z "$_rc_pkgs" ]]; then
        ok "No residual config packages"
    else
        echo "$_rc_pkgs" | while IFS= read -r p; do
            [[ -n "$p" ]] && printf "  ${YEL}  %s  ${FADE}(removed, config remains)${RESET}\n" "$p"
        done
        echo ""
        warn "$(echo "$_rc_pkgs" | grep -c '.' || echo 0) residual config package(s)"
        info "Purge residual configs?"
        _ask && {
            _spin "Purging residual configs" \
                "dpkg --purge \$(dpkg -l 2>/dev/null | awk '/^rc/{print \$2}' | tr '\n' ' ') 2>/dev/null; true"
            ok "Residual configs purged"
        }
    fi

    echo ""; _section "ORPHANED PACKAGES"
    info "Packages no longer needed as dependencies:"
    echo ""
    local _orphans
    _orphans=$(apt-get autoremove --dry-run 2>/dev/null | awk '/^Remv /{print $2}' | head -20 || true)
    if [[ -z "$_orphans" ]]; then
        ok "No orphaned packages"
    else
        echo "$_orphans" | while IFS= read -r p; do
            [[ -n "$p" ]] && printf "  ${YEL}  %s${RESET}\n" "$p"
        done
        echo ""
        info "Remove orphaned packages? (apt autoremove)"
        _ask && _spin "apt autoremove" "apt autoremove -y > /dev/null 2>&1; true"
    fi

    echo ""; _section "STALE PIP PACKAGES"
    info "Checking for outdated pip packages..."
    pip list --outdated --break-system-packages 2>/dev/null | head -15 \
        || warn "pip outdated check unavailable"
    echo ""
    info "Upgrade all outdated pip packages?"
    _ask && {
        _spin "Upgrading pip packages" \
            "pip list --outdated --break-system-packages 2>/dev/null | awk 'NR>2{print \$1}' | xargs -r pip install --upgrade --break-system-packages -q 2>/dev/null; true"
        ok "pip packages upgraded"
    }

    echo ""; _section "GO BINARY INVENTORY"
    if command -v go &>/dev/null; then
        local _gobin; _gobin=$(go env GOPATH 2>/dev/null)/bin
        info "Go binaries in $_gobin:"
        ls -1 "$_gobin" 2>/dev/null | while IFS= read -r b; do
            printf "  ${FADE}  %s${RESET}\n" "$b"
        done | head -20
        echo ""
        tip "Remove a Go binary: rm \$GOPATH/bin/<name>"
        tip "Reinstall: go install <pkg>@latest"
    else
        info "Go not installed  --  no Go binary inventory"
    fi

    _pause
}

_mod_i5() {
    _banner "I5  --  FULL HEALTH AUDIT"
    _synopsis "Read-only diagnostic snapshot. 10-point check. No changes made. Fix map at end."

    local _score=0 _max=10
    local _fixes=()

    _section "1 -- STORAGE"
    if [[ -d ~/storage/downloads ]]; then
        ok "Storage linked"; (( _score++ )) || true
    else
        fail "Storage not linked"; _fixes+=("B5  -- Storage Recovery")
    fi
    local _free; _free=$(df -h ~/ 2>/dev/null | awk 'NR==2{print $4}' || echo "?")
    info "Free space: ${_free}"

    echo ""; _section "2 -- PACKAGE MANAGER"
    if dpkg -l &>/dev/null; then
        ok "dpkg responding"; (( _score++ )) || true
    else
        fail "dpkg issues  -- run B1"; _fixes+=("B1  -- Package Manager Rescue")
    fi
    local _broken_c; _broken_c=$(dpkg -l 2>/dev/null | grep -cE '^[^ih ]' || echo 0)
    if [[ "$_broken_c" -le 2 ]]; then
        ok "Package states clean"; (( _score++ )) || true
    else
        warn "$_broken_c package state issues  -- run B1"; _fixes+=("B1  -- Package Manager Rescue")
    fi

    echo ""; _section "3 -- SHELL HEALTH"
    if bash -n ~/.bashrc 2>/dev/null; then
        ok ".bashrc syntax clean"; (( _score++ )) || true
    else
        fail ".bashrc has errors  -- run B3"; _fixes+=("B3  -- .bashrc Validator & Fixer")
    fi
    if grep -q 'alias dl=' ~/.bashrc 2>/dev/null; then
        ok "alias dl present"; (( _score++ )) || true
    else
        warn "alias dl missing  -- run B4"; _fixes+=("B4  -- Alias Repair")
    fi

    echo ""; _section "4 -- NETWORK"
    if ping -c 1 -W 3 8.8.8.8 &>/dev/null 2>&1; then
        ok "Internet reachable"; (( _score++ )) || true
    else
        fail "No internet  -- check WiFi/data"; _fixes+=("E2  -- Network Check")
    fi

    echo ""; _section "5 -- CORE TOOLS"
    local _missing_tools=0
    for _tc in curl git python3 pip ffmpeg yt-dlp; do
        command -v "$_tc" &>/dev/null || (( _missing_tools++ )) || true
    done
    if [[ "$_missing_tools" -eq 0 ]]; then
        ok "All core tools present"; (( _score++ )) || true
    else
        warn "$_missing_tools core tool(s) missing  -- run D1"; _fixes+=("D1  -- Core Environment Setup")
    fi

    echo ""; _section "6 -- CLEANLINESS"
    local _orphan_c; _orphan_c=$(apt-get autoremove --dry-run 2>/dev/null | grep -c "^Remv" || echo 0)
    local _tmp_mb; _tmp_mb=$(du -sm "${TMPDIR:-$PREFIX/tmp}" 2>/dev/null | cut -f1 || echo 0)
    local _cache_sz; _cache_sz=$(du -sh ~/.cache 2>/dev/null | cut -f1 || echo "?")
    if [[ "$_orphan_c" -le 0 ]]; then
        ok "No orphaned packages"; (( _score++ )) || true
    else
        warn "$_orphan_c orphaned package(s)  -- run I4"; _fixes+=("I4  -- Dead Deps & Residuals")
    fi
    info "Cache: ${_cache_sz}  --  Tmp: ${_tmp_mb}MB"
    if [[ "$_tmp_mb" -lt 50 ]]; then
        ok "Tmp size acceptable"; (( _score++ )) || true
    else
        warn "Tmp is ${_tmp_mb}MB  -- run C3 DETOX"; _fixes+=("C3  -- DETOX Full Clean")
    fi

    echo ""; _dv
    local _pct=$(( _score * 100 / _max ))
    printf "  ${HOT}${BOLD}ARSENAL HEALTH SCORE:  %d / %d  (%d%%)${RESET}\n" "$_score" "$_max" "$_pct"
    _dvf
    if [[ "$_pct" -ge 80 ]]; then
        printf "  ${GRN}${BOLD}BOJACK VERDICT:${RESET}  ${WH}Wire is clean. 999. [K9]${RESET}\n"
    elif [[ "$_pct" -ge 50 ]]; then
        printf "  ${YEL}${BOLD}BOJACK VERDICT:${RESET}  ${WH}Few loose wires. Handle it.${RESET}\n"
    else
        printf "  ${RED}${BOLD}BOJACK VERDICT:${RESET}  ${WH}This terminal has seen better days.${RESET}\n"
    fi
    _dv

    if [[ "${#_fixes[@]}" -gt 0 ]]; then
        echo ""; _section "SUGGESTED FIXES"
        for _fx in "${_fixes[@]}"; do
            printf "  ${PINK}  -- %s${RESET}\n" "$_fx"
        done
    fi

    _pause
}

# ====================================================================
#  ENTRY
# ====================================================================
_boot
_show_menu

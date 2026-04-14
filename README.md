# ARSENAL — Rebuild V2
### Unified Termux Command Hub · Strategy Over Impulse · 999

> Built by **Grant Fezzy Festers** · Ravensmead, Cape Town, ZA  
> Built entirely from an Android phone. No laptop. No team. Just Termux.

---

## 🐕 What is this?

ARSENAL is a single-script Termux maintenance and security hub covering diagnostics, repair, cleaning, tool installation, connectivity, and system health. Every module asks for your permission before doing anything. Nothing runs without you.

Guided by the **Bojack Daemon** — a Lab/Husky-inspired health judge who rates your terminal and tells you exactly what to fix.

---

## 📦 Clone it

**SSH:**
```bash
git clone git@github.com:philfesters/rebuild.git
```

**HTTPS:**
```bash
git clone https://github.com/philfesters/rebuild.git
```

---

## 🚀 Launch it

```bash
bash ~/rebuild/rebuild.sh
```

---

## ⚡ Optional — Set as alias

Add this to your `~/.bashrc`:

```bash
alias rebuild='bash ~/rebuild/rebuild.sh'
```

Then reload:

```bash
source ~/.bashrc
```

Now just type `rebuild` from anywhere.

---

## 🗂️ 9 Module Categories

### A — Diagnostics & Audit
🔍 Environment scan, command availability check, system info report (arch, RAM, CPU, Android), Python environment audit. Know exactly what you have before you touch anything.

### B — Repair & Fix
🔧 Package manager rescue, mirror CDN reset for 404 errors, `.bashrc` syntax validator and auto-fixer, alias repair and explainer, storage and `/sdcard` symlink recovery. Covers the Catch-22 scenarios where the fix requires the broken tool.

### C — Performance & Clean
⚡ Freeze and hang fixer, live process manager (kill by name or PID), and DETOX — a 9-module full clean covering cache, orphaned dependencies, history, tmp files, and junk.

### D — Install & Rebuild
📲 Core environment setup, Security Hub installer (nuclei, trivy, nikto, lynis, gobuster), Media tools (yt-dlp, gallery-dl, ffmpeg, mpv, spotdl), OSINT toolkit (sherlock, photon, theHarvester, maigret), and a complete full rebuild module.

### E — Connectivity & GitHub
🌐 SSH key setup and GitHub push fix, PAT and remote management, network diagnostics (IP, DNS, ping, HTTPS), Tor status and Proxychains config.

### F — Encyclopedia
📖 Reference only — nothing is ever modified. Full alias reference with Fezzy Station map, Termux error code guide with causes and fixes, common issues routing matrix, SOI knowledge base.

### G — Auto-Repair
🤖 Full auto-repair runs all repair modules sequentially. One-Shot Fresh Install rebuilds your complete Termux environment from scratch across 7 modules — no manual input required.

### H — Extras
🛠️ Backup and restore `.bashrc`, scripts, and configs to `/sdcard`. Dev environment setup (vim config, git config, tmux, gum, Go PATH). Android Bridge diagnostics for clipboard, notifications, and sensors.

### I — Housekeeping & Health
🧹 Broken symlink and orphan file hunter, duplicate file scanner in Downloads, empty folder sweep, dead dependency and residual config cleaner, and a 10-point read-only health audit with a Bojack verdict and fix map.

---

## 🐕 Bojack Daemon

The health audit scores your Termux environment out of 10 across storage, package manager, shell health, network, core tools, and cleanliness.

- **80%+** → _"Wire is clean. 999. [K9]"_
- **50-79%** → _"Few loose wires. Handle it."_
- **Below 50%** → _"This terminal has seen better days."_

At the end of every audit, Bojack gives you a suggested fix map pointing to the exact module for each issue.

---

## 🔒 Key Principles

- ✅ **Stable** — every module is tested and verified
- 🔒 **Nothing runs without your permission** — every action is gated behind a yes/no prompt
- 🐕 **Bojack Daemon** — health scoring, routing, and verdict on every audit
- 📱 **Android-native** — built for Termux on Android, no root required
- 🔍 **Tool detection** — scans for nmap, nikto, nuclei, sherlock, lynis, and 40+ more

---

## 🛡️ Security Tools Detected

Arsenal scans for and installs: `nmap`, `nikto`, `lynis`, `nuclei`, `trivy`, `gobuster`, `subfinder`, `httpx`, `sqlmap`, `sherlock`, `holehe`, `photon`, `theHarvester`, `maigret`, `wfuzz`, `hydra`, `whatweb`, `exiftool`, `tor`, `proxychains4`, `steghide`, and more.

---

## 👤 About the Builder

**Grant Fezzy Festers** — self-taught developer, rapper, and builder from Ravensmead, Cape Town, South Africa.

Built entirely from an Honor X5b Android phone using Termux. Every line of code written on a phone screen, every module tested on real hardware. No laptop. No team.

Personal philosophy: **Strategy Over Impulse · 999** — turning struggle into something positive.

🎤 Also known as **Fezzy CPT** — hip-hop artist from the Cape.

---

## 🎵 Music

Listen to Fezzy CPT:

- ☁️ [SoundCloud](https://m.soundcloud.com/hiphopfezzy)
- 🎵 [ReverbNation](https://www.reverbnation.com/FezzyFesters/songs)
- 📘 [Facebook](https://www.facebook.com/search/top?q=Fezzy%20CPT)

---

## 🌐 Links

- GitHub: [philfesters](https://github.com/philfesters)
- Project page: [philfesters.github.io](https://philfesters.github.io)

---

> Strategy Over Impulse · Ravensmead · Cape Town · 999 · Bojack [K9]

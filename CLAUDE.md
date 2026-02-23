# CLAUDE.md — DeckRC

## Project Overview

DeckRC is an open source project that turns a **Steam Deck into an R/C (Radio Control) ground controller** for drones and other Mavlink-compatible vehicles. It is a **configuration and setup project** — not a traditional compiled software project. The repository contains:

- A Bash installation/setup script
- A systemd service unit file
- An SC-Controller input profile (JSON)
- Documentation (README, GitHub wiki references)

The target platform is **SteamOS** (Arch Linux-based) running on a Valve Steam Deck.

---

## Repository Structure

```
DeckRC/
├── setup.sh                        # Main setup script — run once to configure the Steam Deck
├── sc-controller-restart.service   # Systemd service: restarts SC-Controller after suspend/resume
├── UAX-Hybrid-Profile.sccprofile  # SC-Controller input mapping profile (JSON)
├── README.md                       # Project overview and goals
├── LICENSE                         # License file
└── .github/
    ├── ISSUE_TEMPLATE/
    │   ├── bug_report.md
    │   └── feature_request.md
    └── workflows/
        └── lint.yml                # CI: ShellCheck, JSON validation, systemd unit check
```

---

## Key Components

### 1. `setup.sh` — Installation Script

The primary deliverable. Executed once on the Steam Deck after a fresh SteamOS install. It:

1. **Verifies/sets user password** (required before `sudo` use)
2. **Installs CoreKeyboard** (on-screen keyboard via Flatpak, for use outside Steam)
3. **Unlocks SteamOS read-only filesystem** via `steamos-readonly disable`
4. **Configures pacman** (Arch package manager) with the `holo` keyring to fix pgp signature issues on SteamOS
5. **Installs system packages** via pacman:
   - Build tools: `git`, `cmake`, `base-devel`, `ninja`, `mono` (+ addins/tools/msbuild)
   - Runtime: `python`, `python-pip`, `zlib`, `glibc`, `linux-api-headers`, `docker`
   - QGC dependencies: `patchelf`, `xdg-desktop-portal-kde`, `espeak-ng`, `speech-dispatcher`
   - GStreamer stack: `gstreamer`, `gst-plugins-{base,good,bad,ugly}`, `gst-libav`
6. **Optionally installs QGroundControl (QGC)** AppImage (v4.4.2) to `~/Desktop/`
   - Grants `deck` user serial port access (`uucp` group)
   - Disables "grandma"/"grandpa" espeak voices to prevent QGC from defaulting to them
7. **Optionally installs SC-Controller** AppImage (kozec fork v0.4.10-pre) to `~/Desktop/`
8. **Optionally configures Herelink network routing** (`192.168.144.0/24` via `192.168.43.1`)
9. **Optionally switches session to Plasma/X11** (`steamos-session-select plasma-x11-persistent`) — required because QGC has known issues under Wayland
10. **Optionally reboots** the system

Interactive prompts use `y/n` with explicit default values shown.

### 2. `sc-controller-restart.service` — Systemd Service

Restarts the SC-Controller daemon after the system wakes from suspend. Without this, the Steam Deck's controller inputs may stop being recognized by QGC after sleep.

- **Unit type**: oneshot
- **Trigger**: `suspend.target` (after suspend)
- **Command**: `/home/deck/Desktop/sc-controller.AppImage daemon restart`
- **Install location**: deployed as a systemd user or system service

### 3. `UAX-Hybrid-Profile.sccprofile` — SC-Controller Profile

A JSON profile for [SC-Controller](https://github.com/kozec/sc-controller) that maps Steam Deck hardware inputs to Linux input events consumed by QGroundControl.

#### Button Mappings

| Control        | Action                         | Notes                              |
|----------------|--------------------------------|------------------------------------|
| A              | `BTN_GAMEPAD`                  | Standard gamepad A                 |
| B              | `BTN_EAST`                     | Standard gamepad B                 |
| X              | `BTN_NORTH`                    | Standard gamepad X                 |
| Y              | `BTN_WEST`                     | Standard gamepad Y                 |
| LB             | `BTN_TL`                       | Left bumper                        |
| RB             | `BTN_TR`                       | Right bumper                       |
| Left Trigger   | `BTN_RIGHT`                    | Mouse right-click                  |
| Right Trigger  | `BTN_LEFT`                     | Mouse left-click                   |
| Left Stick     | `ABS_X` / `ABS_Y` (1.2x sens) | Drone pitch/roll axis              |
| Right Stick    | `ABS_RX` / `ABS_RY` (1.2x)    | Camera/yaw axis (Y axis inverted)  |
| Left Pad       | Horizontal/vertical scroll     | Ball physics with haptic feedback  |
| Right Pad      | Mouse cursor                   | Ball physics, 5.0 friction         |
| Center Pad     | Mouse left-click               |                                    |
| D-Pad          | Arrow keys                     |                                    |
| Gyro           | CeMU hook                      | Gyroscope data passthrough         |
| BACK           | `KEY_ESC`                      |                                    |
| START          | `KEY_ENTER`                    |                                    |
| C (Quick Menu) | `KEY_LEFTMETA`                 | Super/Windows key                  |
| L Grip         | `KEY_LEFTCTRL`                 |                                    |
| L Grip 2       | `KEY_LEFTSHIFT`                |                                    |
| R Grip         | `KEY_LEFTALT`                  |                                    |
| R Grip 2       | `KEY_TAB`                      |                                    |
| L Stick Press  | `BTN_THUMBL`                   |                                    |
| R Stick Press  | `BTN_THUMBR`                   |                                    |

Profile version: `1.4`

---

## Supported Hardware / Compatibility

- **Target device**: Valve Steam Deck (SteamOS / Arch Linux)
- **Aircraft protocol**: Mavlink (any compatible vehicle)
- **Direct WiFi**: Some aircraft (e.g., SkyViperV2450) connect via built-in WiFi
- **Radio modules**: USB-powered (max ~7.5W from Steam Deck USB port)
  - Doodle Labs NanoOEM (tested to 1km+)
  - Ubiquiti gear
  - ESP chips with DroneBridge
  - RFD + 5.8 GHz vRX

---

## Development Workflows

### Branching Strategy

- Primary branch: `master`
- Feature/fix branches are created per change, then merged via Pull Request
- Branch naming follows standard descriptive convention (e.g., `sc-controller-fixes`, `Update-Documentation`)

### Making Changes

1. Create a feature branch from `master`
2. Edit the relevant file(s)
3. Run the local validation commands listed in "CI / Automated Checks" below before committing
4. Commit with a clear, descriptive message (see commit history for style reference)
5. Open a PR against `master` — CI runs automatically on push

### CI / Automated Checks

`.github/workflows/lint.yml` runs on every PR and push to `master`/`main`. The three checks are:

| Check | Command | What it validates |
|---|---|---|
| ShellCheck | `shellcheck setup.sh` | Bash correctness in `setup.sh` |
| JSON validation | `python3 -m json.tool UAX-Hybrid-Profile.sccprofile` | SC-Controller profile is valid JSON |
| Systemd unit check | Python `configparser` script | `sc-controller-restart.service` has required sections/keys |

**Run these locally before pushing** to avoid CI failures:

```bash
shellcheck setup.sh
python3 -m json.tool UAX-Hybrid-Profile.sccprofile > /dev/null && echo OK
bash -n setup.sh
```

**Why Python for the systemd check (not `systemd-analyze verify`):** The GitHub Actions ubuntu runner does not have an active D-Bus/systemd session, so `systemd-analyze` cannot connect and fails. The Python `configparser` approach validates unit file structure without needing a running systemd.

### File Editing Conventions

- **`setup.sh`**: Bash script; keep interactive prompts consistent with the existing `y/n` pattern (default shown in parentheses). All changes must pass `shellcheck setup.sh` with zero findings. Key patterns to follow:
  - Use `read -rp "... (y/n; default=X): " varname` (the `-r` flag is required by ShellCheck)
  - Use `cd /some/path || exit` (never bare `cd` without error handling)
  - Use bash arrays for commands stored in variables: `CMD=(sudo pacman -S --noconfirm)` and `"${CMD[@]}" pkg` — **not** a plain string variable, which breaks quoting
  - Use `# comment` lines for disabled code — **not** the `:'...'` heredoc trick (ShellCheck SC2289 flags it as an error)
  - Quote all variable expansions that may contain spaces or special characters
- **`UAX-Hybrid-Profile.sccprofile`**: Valid JSON; maintain the `version: 1.4` field; test with SC-Controller before committing.
- **Systemd service files**: Follow standard systemd unit syntax.

---

## Known Issues / TODOs (from code comments)

- `setup.sh` line 72: QGC download URL points to v4.4.2; should be updated for future 5.x stable releases once tested
- `setup.sh` line 104: SC-Controller autostart is commented out — autostart fix is pending
- `setup.sh` line 124: Herelink IP route does not survive reboots; a persistent solution via KDE connection manager routes must be documented/automated
- `sc-controller-restart.service`: Path assumes `deck` user and AppImage on Desktop — may break if installation location changes

---

## GitHub Issues Tracker

### Open Issues

| # | Title | Labels | Summary |
|---|-------|--------|---------|
| #28 | Speech Not Working in QGC Daily Build | — | Text-to-speech fails in QGC daily builds with a `speechd` plugin error despite `espeak-ng` and `speech-dispatcher` being installed; suspected Qt/Linux version incompatibility. |
| #27 | Tutorial Video | — | Request for a video tutorial covering the full setup process; open question whether hardware and software setup should be separate videos. |
| #26 | Add Automated (CI) Testing | — | Proposal to run `setup.sh` inside a Docker container via GitHub Actions; references `linuxserver/docker-steamos` as a candidate base image. |
| #22 | Stop Steam from Running on R/C Only Installs | — | Goal to remove Steam from DeckRC-only installs; a prior attempt to disable the Steam binary caused boot failures and was reverted. |
| #20 | Move as Many Functions as Possible into User Space | enhancement | Many script commands require root; proposal to shift to unprivileged operation via AppImage bundling, Nix, or rwfus overlay to avoid needing `steamos-readonly disable`. |
| #16 | Detect if QGC and/or SCC Are Already Installed Before Downloading | enhancement | `setup.sh` re-downloads both AppImages on every run, causing file accumulation on `~/Desktop/`; fix should detect existing installs and skip or replace them. |
| #15 | Joystick Controls Do Not Work When Resuming from Sleep | bug | After suspend/resume, SC-Controller inputs stop working in QGC due to USB errors; workaround is restarting the SC-Controller daemon (which `sc-controller-restart.service` implements). |
| #11 | Any Updates and Tutorials | documentation | Community request for full end-to-end build documentation (Steam Deck setup → radio integration → drone construction); basic wiki instructions started, four-part roadmap planned. |
| #4 | Radio Reboots When Plugged In | bug | Doodle Labs NanoOEM radio unexpectedly restarts when powered via USB hub; possibly power-supply dependent (observed with Anker 65W adapter). |
| #2 | Arming Scheme Issue | bug | Prearm error prevents RC1/RC2 channels from reaching neutral when RS click + R1 are used together during the arming sequence. |

### Closed Issues (with Resolution)

| # | Title | Resolution |
|---|-------|------------|
| #14 | Controls Not Functioning with SC Controller | **Fixed** — Switched to kozec fork AppImage (`v0.4.10-pre`), which resolved right trackpad behaving as a joystick mouse. |
| #10 | Video Not Working on Latest Version of QGC | **Fixed** — Added `gst-libav` to install list; removed `gstreamer-vaapi` which conflicted. |
| #9 | Getting Keyring Errors on Install | **Fixed** — Replaced `archlinux` keyring with `holo` keyring (`pacman-key --populate holo`), now in `setup.sh`. |
| #6 | Radio Failsafes If Screen Goes to Sleep | **Not Planned** — Marked intentional: controls and external radio power should be off when the unit sleeps. |
| #5 | Steam Deck Audio Set to Wrong Device | **Not Reproducible** — Could not reproduce across multiple factory resets on two different Steam Decks. |
| #3 | Mavproxy Battery Alerts | **Fixed** — Removed Mavproxy from the standard install; QGC's built-in voice prompts are sufficient. |
| #1 | System Crash (AMD GPU Page Fault) | **Not Planned** — Crash occurred twice in 2022 but did not recur for over a year; closed as one-off. |

### Key Patterns from Issue History

- **SC-Controller issues** have frequently been caused by the upstream AppImage; always use the **kozec fork** (`v0.4.10-pre`), not the original.
- **GStreamer** is a recurring pain point. The working set is: `gstreamer`, `gst-plugins-{base,good,bad,ugly}`, `gst-libav`. Do **not** add `gstreamer-vaapi` — it breaks video.
- **Pacman keyring** on SteamOS requires `--populate holo`, not `--populate archlinux`.
- **Sleep/resume** breaks SC-Controller USB recognition — this is the entire reason `sc-controller-restart.service` exists.
- **Root filesystem access** (`steamos-readonly disable`) is a known SteamOS constraint; there is active interest (issue #20) in reducing reliance on it.
- **QGC + Wayland** is a known incompatibility (issue #22 adjacent); Plasma/X11 session is the current workaround.

---

## External Dependencies

| Dependency | Source | Purpose |
|---|---|---|
| QGroundControl | `github.com/mavlink/qgroundcontrol` AppImage | Drone ground control station |
| SC-Controller (kozec fork) | `github.com/kozec/sc-controller` AppImage | Steam Deck joystick mapping |
| GStreamer | pacman / SteamOS | Video pipeline for drone feeds |
| CoreKeyboard | Flathub Flatpak | On-screen keyboard outside Steam |
| Mono | pacman | Runtime for some QGC components |

---

## Commercial Context

DeckRC is developed by [UAX Technologies](https://uaxtech.com/). Commercial hardware (pre-integrated radio modules using Doodle Labs, Silvus, Persistent Systems, Microhard radios) is available separately. The open source repository supports DIY and community builds.

---

## Common AI Assistant Tasks

When working on this repository, AI assistants should:

1. **Run ShellCheck before committing** — `shellcheck setup.sh` must exit 0 with no findings. ShellCheck is enforced in CI. Common pitfalls:
   - Store command arrays as bash arrays, not strings: `CMD=(sudo pacman -S --noconfirm)` / `"${CMD[@]}" pkg`
   - Always use `read -rp` (not `read -p`) to avoid SC2162
   - Always use `cd /path || exit` (not bare `cd`) to avoid SC2164
   - Never use `:'...'` for multi-line comments (SC2289 error) — use `#` lines instead
   - Quote all variable expansions: `"$USER"`, not `$USER`
2. **Validate bash syntax** before modifying `setup.sh` — `bash -n setup.sh` catches parse errors
3. **Preserve interactive prompt patterns** — new optional features should follow the same `read -rp "... (y/n; default=X): "` pattern
4. **Keep the JSON profile valid** — run `python3 -m json.tool UAX-Hybrid-Profile.sccprofile` to validate after edits
5. **Do not use `systemd-analyze verify` in CI** — it requires a live D-Bus session unavailable on GitHub Actions runners; use Python `configparser` to validate unit file structure instead
6. **Not assume a build system exists** — there is no `make`, `npm`, `cargo`, or other build tool; the only automated checks are the three in `lint.yml`
7. **Be aware of SteamOS constraints**: the root filesystem is read-only by default (`steamos-readonly disable` is required for pacman installs); packages installed via pacman may be wiped on SteamOS system updates
8. **Reference the wiki** for user-facing installation instructions — the README links to `github.com/UAX-Technologies/DeckRC/wiki`
9. **Update this file** if new scripts, services, profiles, CI checks, or major dependencies are added

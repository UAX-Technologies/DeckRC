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
    └── ISSUE_TEMPLATE/
        ├── bug_report.md
        └── feature_request.md
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

Since this project has no build system or tests, the workflow is straightforward:

1. Create a feature branch from `master`
2. Edit the relevant file(s)
3. Commit with a clear, descriptive message (see commit history for style reference)
4. Open a PR against `master`

### No Build/Test System

There is no `Makefile`, no CI pipeline, and no automated tests. Changes to `setup.sh` should be manually validated on actual SteamOS hardware (or in a SteamOS environment). Linting bash scripts with `shellcheck` is recommended before committing.

### File Editing Conventions

- **`setup.sh`**: Bash script; keep interactive prompts consistent with the existing `y/n` pattern (default shown in parentheses). Commented-out code using `:'...'` heredoc syntax is used for sections under development (e.g., yay setup).
- **`UAX-Hybrid-Profile.sccprofile`**: Valid JSON; maintain the `version: 1.4` field; test with SC-Controller before committing.
- **Systemd service files**: Follow standard systemd unit syntax.

---

## Known Issues / TODOs (from code comments)

- `setup.sh` line 72: QGC download URL points to v4.4.2; should be updated for future 5.x stable releases once tested
- `setup.sh` line 104: SC-Controller autostart is commented out — autostart fix is pending
- `setup.sh` line 124: Herelink IP route does not survive reboots; a persistent solution via KDE connection manager routes must be documented/automated
- `sc-controller-restart.service`: Path assumes `deck` user and AppImage on Desktop — may break if installation location changes

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

1. **Validate bash syntax** before modifying `setup.sh` — use `bash -n setup.sh` to check for syntax errors
2. **Preserve interactive prompt patterns** — new optional features should follow the same `read -p "... (y/n; default=X): "` pattern
3. **Keep the JSON profile valid** — run `python3 -m json.tool UAX-Hybrid-Profile.sccprofile` to validate after edits
4. **Not assume a build system exists** — there is no `make`, `npm`, `cargo`, or other build tool
5. **Be aware of SteamOS constraints**: the root filesystem is read-only by default (`steamos-readonly disable` is required for pacman installs); packages installed via pacman may be wiped on SteamOS system updates
6. **Reference the wiki** for user-facing installation instructions — the README links to `github.com/UAX-Technologies/DeckRC/wiki`
7. **Update this file** if new scripts, services, profiles, or major dependencies are added

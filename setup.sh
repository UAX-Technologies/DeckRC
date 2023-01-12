#!/bin/bash

# Allow read/write access to root filesystem
steamos-readonly disable

# Set desktop session to Plasma/X11.
# TODO: Why does QGC fail to launch under Wayland?
steamos-session-select plasma-persistent

# Disable steam client
# TODO: Use a more elegant solution.
chmod -x /usr/bin/steam

pacman-key --init
pacman-key --populate archlinux
pacman -Syu --disable-download-timeout --overwrite '*' <<EOF
Y
EOF

# Split the following package installations into separate pacman commands to
# avoid an "insufficient disk space" error.

pacman -S --disable-download-timeout --overwrite '*' \
    tmux git mono mono-addins mono-tools mono-msbuild cmake base-devel glibc \
    <<EOF

Y
EOF

pacman -S --disable-download-timeout --overwrite '*' \
    linux-api-headers qt5-tools qt5-wayland qt5-base python zlib <<EOF
Y
EOF

pacman -S --disable-download-timeout --overwrite '*' \
    lib32-gst-plugins-good lib32-gst-plugins-base lib32-gstreamer \
    lib32-gst-plugins-base-libs qt-gstreamer gstreamer-vaapi gstreamermm <<EOF
2
1
1
1
1
Y
EOF

pacman -S --disable-download-timeout --overwrite '*' \
    ninja python-pip docker espeak-ng speech-dispatcher <<EOF
Y
EOF

# Dependencies for sc-controller
pacman -S --disable-download-timeout --overwrite '*' \
    python-gobject python-pylibacl python-evdev

# Install sc-controller-git from AUR.
# TODO: Use the stable release instead of the -git version. The -git version is
# needed for now because the latest release does not yet support the Deck.

mkdir ~/aur
cd ~/aur
git clone https://aur.archlinux.org/sc-controller-git.git
cd sc-controller-git
makepkg -i

# Auto-start sc-controller
cp /usr/share/applications/sc-controller.desktop ~/.config/autostart/

# TODO: Drop configuration file for sc-controller to ~/.config/scc/config.json
# and profile to ~/.config/scc/profiles/

# Dependencies for QGC
pacman -S --disable-download-timeout --overwrite '*' \
    qt5-speech qt5-multimedia qt5-serialport qt5-charts qt5-quickcontrols \
    qt5-quickcontrols2 qt5-location qt5-svg qt5-graphicaleffects qt5-x11extras \
    patchelf xdg-desktop-portal-kde

# Fetch QGC AppImage
cd ~/Desktop/
wget https://d176tv9ibo4jno.cloudfront.net/latest/QGroundControl.AppImage
chmod +x QGroundControl.AppImage

# Give 'deck' user permission to access serial I/O devices.
usermod -a -G uucp deck

# Force QGC to use the 'm5' voice. Move all others to ~deck/voices/
VOICE='m5'
VOICE_DUMP="${HOME}/voices"

mkdir ${VOICE_DUMP}
find '/usr/share/espeak-ng-data/voices/!v' -type f -not -name $VOICE \
    -exec mv '{}' ${VOICE_DUMP} ';'

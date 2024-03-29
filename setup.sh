#!/bin/bash

#
# The --deckrc-only flag causes the Steam client to be disabled and the default
# session to be set to KDE.
#

# Allow read/write access to root filesystem
steamos-readonly disable

if [ "$1" = "--deckrc-only" ]
then
    # Set desktop session to Plasma/X11.
    # TODO: Why does QGC fail to launch under Wayland?
    steamos-session-select plasma-x11-persistent

    # Disable steam client
    # TODO: Use a more elegant solution.
    chmod -x /usr/bin/steam
fi

pacman-key --init
pacman-key --populate archlinux

INSTALL="pacman -S --disable-download-timeout --overwrite '*' --noconfirm"

# Update the system
${INSTALL} -yu

# Install required packages
${INSTALL} tmux
${INSTALL} git
${INSTALL} mono
${INSTALL} mono-addins
${INSTALL} mono-tools
${INSTALL} mono-msbuild
${INSTALL} cmake
${INSTALL} base-devel
${INSTALL} glibc
${INSTALL} linux-api-headers
${INSTALL} qt5-tools
${INSTALL} qt5-wayland
${INSTALL} qt5-base
${INSTALL} python
${INSTALL} zlib
${INSTALL} ninja
${INSTALL} python-pip
${INSTALL} docker

# Dependencies for sc-controller
${INSTALL} python-gobject
${INSTALL} python-pylibacl
${INSTALL} python-evdev
${INSTALL} python-cairo
${INSTALL} xorg-xinput
${INSTALL} python-setuptools

# Dependencies for QGC
${INSTALL} qt5-speech
${INSTALL} qt5-multimedia
${INSTALL} qt5-serialport
${INSTALL} qt5-charts
${INSTALL} qt5-quickcontrols
${INSTALL} qt5-quickcontrols2
${INSTALL} qt5-location
${INSTALL} qt5-svg
${INSTALL} qt5-graphicaleffects
${INSTALL} qt5-x11extras
${INSTALL} patchelf
${INSTALL} xdg-desktop-portal-kde
${INSTALL} espeak-ng
${INSTALL} speech-dispatcher

${INSTALL} lib32-pipewire-jack
${INSTALL} lib32-gst-plugins-good
${INSTALL} lib32-gst-plugins-base
${INSTALL} lib32-gstreamer
${INSTALL} lib32-gst-plugins-base-libs
${INSTALL} qt-gstreamer
${INSTALL} gstreamer-vaapi
${INSTALL} gstreamermm

# Install sc-controller-git from AUR.
# TODO: Use the stable release instead of the -git version. The -git version is
# needed for now because the latest release does not yet support the Deck.

mkdir ~/aur
cd ~/aur
git clone --depth 1 https://aur.archlinux.org/sc-controller-git.git
cd sc-controller-git
sudo -u deck makepkg -i

# Auto-start sc-controller
cp /usr/share/applications/sc-controller.desktop ~/.config/autostart/

# Setup configuration file for sc-controller
mkdir ~/.config/scc
tee >~/.config/scc/config.json <<EOF
{
    "gui": {
        "enable_status_icon": true,
        "minimize_on_start": true,
        "minimize_to_status_icon": true
    }
}
EOF

# TODO: Add sc-controller profile to ~/.config/scc/profiles/

# Fetch QGC AppImage
cd ~/Desktop/
wget https://d176tv9ibo4jno.cloudfront.net/latest/QGroundControl.AppImage
chmod +x QGroundControl.AppImage

# Give 'deck' user permission to access serial I/O devices.
usermod -a -G uucp deck

# Move the Grandma and Grandpa voices to prevent QGC from using them as default
VOICES_DISABLED='grandma grandpa'
VOICE_DIR='/usr/share/espeak-ng-data/voices/!v'
VOICE_DUMP='${VOICE_DIR}/.disabled'

mkdir ${VOICE_DUMP}
for v in ${VOICES_DISABLED}
do
    mv ${VOICE_DIR}/${v} ${VOICE_DUMP}
done

# Reboot into the newly setup DeckRC
read -p "Reboot the system? (y/n; default=y): " reboot
if [[ ${#reboot} == 0 || ${reboot:0:1} == "Y" || ${reboot:0:1} == "y" ]]
then
    reboot
fi

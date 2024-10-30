#!/bin/bash

#
# The --deckrc-only flag causes the Steam client to be disabled and the default
# session to be set to KDE.
#


# Check if a password is set. If there is none prompot the user for a new password
PASSWORD_STATUS=$(passwd --status $USER | awk '{print $2}')

# Check if the status is "NP", indicating no password
if [ "$PASSWORD_STATUS" == "NP" ]; then
    echo "No password set for user $USER. You need to set a password."
    # Run the passwd command to prompt for a new password
    passwd $USER
else
    echo "User password is already set. Continuing setup process."
fi



# Allow read/write access to root filesystem
echo "Enabling write access to system partitions."
sudo steamos-readonly disable

echo "Starting pacman setup..."
sudo pacman-key --init
sudo pacman-key --populate archlinux
#adding this key to fix issues with pgp signatures on steamdeck. Might be able to remove the previous link for --populate archlinux
sudo pacman-key --populate holo

INSTALL="sudo pacman -S --disable-download-timeout --overwrite '*' --noconfirm"

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

#Setup yay
mkdir ~/aur
cd ~/aur
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin/
git checkout 96f90180a3cf72673b1769c23e2c74edb0293a9f
makepkg -si --noconfirm

# Install sc-controller-git from AUR.
echo "Starting sc-controller setup"
yay -S sc-controller

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
echo "Setting up QGC..."
cd ~/Desktop/
wget https://d176tv9ibo4jno.cloudfront.net/latest/QGroundControl.AppImage
chmod +x QGroundControl.AppImage



# Give 'deck' user permission to access serial I/O devices.
sudo usermod -a -G uucp deck

# Move the Grandma and Grandpa voices to prevent QGC from using them as default
echo "Fixing QGC voices..."
VOICES_DISABLED='grandma grandpa'
VOICE_DIR='/usr/share/espeak-ng-data/voices/!v'
VOICE_DUMP="${VOICE_DIR}/.disabled"

sudo mkdir "${VOICE_DUMP}"
for v in ${VOICES_DISABLED}
do
    sudo mv "${VOICE_DIR}/${v}" "${VOICE_DUMP}"
done

read -p "Enable routing for Herelink network (y/n; default=y): " herelinkask
if [[ ${#herelinkask} == 0 || ${herelinkask:0:1} == "Y" || ${herelinkask:0:1} == "y" ]]; then
#Set Herleink IP routes
#TODO: make this persistent. Right now it doesn't survive reboots
sudo ip route add 192.168.144.0/24 via 192.168.43.1
fi

read -p "Preserve Steam and Gaming (y/n; default=y): " gamingask
if [[ ${#gamingask} == 0 || ${gamingask:0:1} == "Y" || ${gamingask:0:1} == "y" ]]; then
    echo "Steam and gaming settings will be unchanged or re-enabled"
        sudo chmod +x /usr/bin/steam-jupiter
else
    # Set desktop session to Plasma/X11.
    # TODO: Why does QGC fail to launch under Wayland?
        echo "Forcing X11 for QGC compatibility"
        steamos-session-select plasma-x11-persistent

    # Disable steam client
    # TODO: Use a more elegant solution.
    # commenting out because this was causing a hung boot
    # echo "Disabling Steam client"
    # sudo chmod -x /usr/bin/steam
fi

# Reboot into the newly setup DeckRC
echo "Finished Script"
read -p "Reboot the system? (y/n; default=y): " reboot
if [[ ${#reboot} == 0 || ${reboot:0:1} == "Y" || ${reboot:0:1} == "y" ]]
then
    reboot
fi

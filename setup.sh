#!/bin/bash

# Check if a password is set. If there is none prompot the user for a new password
PASSWORD_STATUS=$(passwd --status "$USER" | awk '{print $2}')

# Check if the status is "NP", indicating no password
if [ "$PASSWORD_STATUS" == "NP" ]; then
    echo "No password set for user $USER. You need to set a password."
    # Run the passwd command to prompt for a new password
    passwd "$USER"
else
    echo "User password is already set. Continuing setup process."
fi

#Install CoreKeyboard - This is so the user has a keyboard when Steam is not running
flatpak install -y flathub org.cubocore.CoreKeyboard


# Allow read/write access to root filesystem
echo "Enabling write access to system partitions."
sudo steamos-readonly disable

echo "Starting pacman setup..."
sudo pacman-key --init
#sudo pacman-key --populate archlinux
#adding the holo key to fix issues with pgp signatures on steamdeck. Might be able to remove the previous link for --populate archlinux
sudo pacman-key --populate holo

INSTALL=(sudo pacman -S --disable-download-timeout --overwrite '*' --noconfirm)

# Update the system
"${INSTALL[@]}" -yu

# Install required packages
#"${INSTALL[@]}" tmux
"${INSTALL[@]}" git
"${INSTALL[@]}" mono
"${INSTALL[@]}" mono-addins
"${INSTALL[@]}" mono-tools
"${INSTALL[@]}" mono-msbuild
"${INSTALL[@]}" cmake
"${INSTALL[@]}" base-devel
"${INSTALL[@]}" glibc
"${INSTALL[@]}" linux-api-headers
"${INSTALL[@]}" python
"${INSTALL[@]}" zlib
"${INSTALL[@]}" ninja
"${INSTALL[@]}" python-pip
"${INSTALL[@]}" docker

# Dependencies for QGC
"${INSTALL[@]}" patchelf
"${INSTALL[@]}" xdg-desktop-portal-kde
"${INSTALL[@]}" espeak-ng
"${INSTALL[@]}" speech-dispatcher

#Gstreamer
"${INSTALL[@]}" gstreamer
"${INSTALL[@]}" gst-plugins-base
"${INSTALL[@]}" gst-plugins-good
"${INSTALL[@]}" gst-plugins-bad
"${INSTALL[@]}" gst-plugins-ugly
"${INSTALL[@]}" gst-libav


# Fetch QGC AppImage
read -rp "Install QGroundControl? (y/n; default=y): " qgcask
if [[ ${#qgcask} == 0 || ${qgcask:0:1} == "Y" || ${qgcask:0:1} == "y" ]]; then
    echo "Setting up QGC..."
    cd ~/Desktop/ || exit
    # TODO: Replace with stable version once fully tested for upcomming (5.x) releases
    wget -O QGroundControl.AppImage https://github.com/mavlink/qgroundcontrol/releases/download/v4.4.2/QGroundControl.AppImage
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
fi



# Install sc-controller
read -rp "Install SC-Controller to Manage the Joysticks? (y/n; default=n): " joystickask
if [[ ${#joystickask} == 1 || ${joystickask:0:1} == "Y" || ${joystickask:0:1} == "y" ]]; then
    echo "Starting sc-controller setup"
    cd ~/Desktop/ || exit
    # Using Kozec branch with fixes for right trackpad
    wget -O sc-controller.AppImage https://github.com/kozec/sc-controller/releases/download/v0.4.10-pre/sc-controller-0.4.8+5b42308-x86_64.AppImage
    chmod +x sc-controller.AppImage
    
    # Auto-start sc-controller
    # TODO: fix autostart for sccontroller
    # cp /usr/share/applications/sc-controller.desktop ~/.config/autostart/
    
    # Setup configuration file for sc-controller
    #mkdir ~/.config/scc
    #tee >~/.config/scc/config.json <<EOF
    #    {
    #        "gui": {
    #            "enable_status_icon": true,
    #            "minimize_on_start": true,
    #            "minimize_to_status_icon": true
    #        }
    #    }
    #    EOF
    # TODO: Add sc-controller profile to ~/.config/scc/profiles/
fi

#Set Herleink IP routes
read -rp "Enable routing for Herelink network? (y/n; default=n): " herelinkask
if [[ ${#herelinkask} == 1 || ${herelinkask:0:1} == "Y" || ${herelinkask:0:1} == "y" ]]; then
    #TODO: make this persistent. Right now it doesn't survive reboots. Right now a user can make it persistent easily by setting it up in the routes section of the ipv4 menu in the KDE connection manager.
    sudo ip route add 192.168.144.0/24 via 192.168.43.1
fi



# Setup yay (disabled — pending testing)
# read -rp "Install YAY to help with using the AUR package repo? (y/n; default=n): " yayask
# if [[ ${#yayask} == 1 || ${yayask:0:1} == "Y" || ${yayask:0:1} == "y" ]]; then
#     git clone https://aur.archlinux.org/yay-bin.git
#     cd yay-bin/ || exit
#     # Check out this specific version that is compatible with SteamOS
#     git checkout 96f90180a3cf72673b1769c23e2c74edb0293a9f
#     makepkg -si --noconfirm
# fi



# Setup to boot directly to the desktop
read -rp "Set the system to boot directly to the Desktop? (y/n; default=n): " desktopask
if [[ ${#desktopask} == 1 || ${desktopask:0:1} == "Y" || ${desktopask:0:1} == "y" ]]; then
    # Disable steam client
    # TODO: Use a more elegant solution.
    # commenting out because this was causing a hung boot
    # echo "Disabling Steam client"
    # sudo chmod -x /usr/bin/steam

    # Set desktop session to Plasma/X11.
    #Note these commands must be last in the if statment as well as the whole script because they force a logout
    # TODO: Why does QGC fail to launch under Wayland?
    echo "Forcing X11 for QGC compatibility"
    echo "This will trigger a logout and login..."
    steamos-session-select plasma-x11-persistent
else
    echo "Steam and gaming settings will be unchanged or re-enabled"
        sudo chmod +x /usr/bin/steam-jupiter
fi



# Reboot into the newly setup DeckRC
echo "Finished Script"
read -rp "Reboot the system? (y/n; default=y): " reboot
if [[ ${#reboot} == 0 || ${reboot:0:1} == "Y" || ${reboot:0:1} == "y" ]]; then
    reboot
fi
exit 0

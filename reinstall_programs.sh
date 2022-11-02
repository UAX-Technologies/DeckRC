#!/bin/bash
sudo steamos-readonly disable
sudo pacman-key --init
sudo pacman-key --populate archlinux
sudo pacman -Syu
sudo pacman -S --overwrite "*" tmux git mono mono-addins mono-tools mono-msbuild cmake base-devel glibc linux-api-headers qt5-tools qt5-wayland qt5-base python zlib lib32-gst-plugins-good lib32-gst-plugins-base lib32-gstreamer lib32-gst-plugins-base-libs qt-gstreamer gstreamer-vaapi gstreamermm ninja python-pip docker espeak-ng speech-dispatcher
# Thanks to this post for getting started with fixing dependancies: https://www.reddit.com/r/SteamDeck/comments/t92ozw/for_compiling_c_code/

#Select the second option for source when propmpted during the installation of pipejack

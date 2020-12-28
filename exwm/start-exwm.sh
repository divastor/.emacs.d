#!/bin/sh

# NOTE: Only needed for a qemu vm, not needed for your configuration!
# spice-vdagent

# Execute this line in terminal: sudo ln -s ~/.emacs.d/exwm/EXWM.desktop /usr/share/xsessions/EXWM.desktop

# Set the screen DPI
xrdb /home/stavros/.emacs.d/exwm/Xresources

# Fire it up
exec dbus-launch --exit-with-session emacs-snapshot -mm --debug-init

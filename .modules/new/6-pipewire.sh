# ---------------------------------------------------------------------
#   ______ ___    | Command&Control (C2) - [Module] Audio driver      |
#  /      |__ \   |---------------------------------------------------|
# |  ,----'  ) |  | Description | Install and configure 'pipewire'    |
# |  |      / /   |             | audio driver.                       |
# |  `----./ /_   |---------------------------------------------------|
#  \______|____|  |    Owner    | a7ir3                               |
#                 |    GitHub   | https://github.com/atirelli3        |
#                 |   Version   | 1.0.0 (beta)                        |
# ---------------------------------------------------------------------

#!/bin/bash

# Script argument(s)
#
# * $1 : Configuration file
# * $2 : stdout log level

# ------------------------------------------------------------------------------
#                                 MODULE HEADER
# ------------------------------------------------------------------------------
source "$1"  # Load configuration file

# ------------------------------------------------------------------------------
#                               MODULE FUNCTION(s)
# ------------------------------------------------------------------------------

# Install and configure Pipewire:
# This function installs the Pipewire audio system along with related components
# such as JACK, ALSA, and PulseAudio replacement. It then disables PulseAudio
# services and enables Pipewire as the primary audio server for the user session.
setup_pipewire() {
  # Install Pipewire and related packages
  eval "pacman -S --noconfirm pipewire lib32-pipewire \
    pipewire-jack lib32-pipewire-jack \
    wireplumber \
    pipewire-alsa \
    pipewire-audio \
    pipewire-ffado \
    pipewire-pulse \
    pipewire-docs $2"

  # Disable PulseAudio services
  eval "systemctl --user disable pulseaudio.service pulseaudio.socket $2"
  eval "systemctl --user stop pulseaudio.service pulseaudio.socket $2"

  # Enable Pipewire and Pipewire-Pulse services
  eval "systemctl --user enable pipewire pipewire-pulse $2"
  eval "systemctl --user start pipewire pipewire-pulse $2"
}

# ------------------------------------------------------------------------------
#                                  MODULE BODY
# ------------------------------------------------------------------------------
setup_pipewire  ## 1. Install and configure Pipewire driver(s)

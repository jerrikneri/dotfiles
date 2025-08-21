{ pkgs }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    chocolate-doom # Doom source port that accurately reproduces the experience of Doom
    cmake
    SDL2
    SDL2_mixer
    SDL2_net
    fluidsynth
    libpng
    zlib


    # gzdoom # Modder-friendly OpenGL and Vulkan source port based on the DOOM engine
    # zdoom # Enhanced port of the official DOOM source code
    gnumake
    gcc
    xorg.libX11
    xorg.libXext
  ];

shellHook = ''
  echo "DOOM dev shell"
  zsh
'';
}


#!/bin/bash

source $SCRIPTS/get_os_variables.sh

# Use os_name and os_version in this script
echo "Operating System: $os_name"
echo "OS Version: $os_version"
# Determine the OS
# if command -v uname &> /dev/null; then
#   os_name=$(uname -s) # MacOS
# fi

# if command -v lsb_release &> /dev/null; then
#   os_version=$(lsb_release -c | awk '{print $2}' 2>/dev/null) # Linux
# fi

case "$os_name" in
    Darwin)
        echo "Detected macOS"
        # Call macOS install script
        $SCRIPTS/install_macOS.sh
        ;;

    Linux)
        if [[ -f /etc/os-release ]]; then
            . /etc/os-release
            case "$ID" in
                arch|archarm)
                    echo "Detected Arch Linux"
                    # Call Arch Linux install script
                    $SCRIPTS/install_arch.sh
                    ;;
                
                ubuntu|debian)
                    echo "Detected Ubuntu/Debian"
                    # Call Ubuntu install script
                    $SCRIPTS/install_ubuntu.sh
                    ;;
                
                *)
                    echo "Unsupported Linux distribution: $ID"
                    ;;
            esac
        else
            echo "Unsupported Linux distribution"
        fi
        ;;
    
    *)
        echo "Unsupported OS: $os_name"
        ;;
esac

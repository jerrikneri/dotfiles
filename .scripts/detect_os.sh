### #!/bin/bash
#!/run/current-system/sw/bin/bash


source $SCRIPTS/get_os_variables.sh

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

		nixos)
		    echo "Detected NixOS"
    		    $SCRIPTS/install_nixos.sh		    
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

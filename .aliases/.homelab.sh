alias rbackup="cd ~/code/forgejo/homelab-backups/ && scripts/./router-backup full"
alias docs="cd ~/code/forgejo/homelab-documentation"
alias infra="cd ~/code/forgejo/homelab-infrastructure"

#Home Server
alias h-check="ping $HOME_SERVER_IP"
alias h-luks="ssh -o \"HostKeyAlgorithms ssh-rsa\" -p $HOME_SERVER_PORT root@$HOME_SERVER_IP"
alias h-ssh="ssh jerrik@$HOME_SERVER_IP -p $HOME_SERVER_SSH_PORT"
alias h-wake="wakeonlan -i 192.168.1.255 -p 7 $HOME_SERVER_MAC"

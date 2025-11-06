alias claude-container="open -a Orbstack && sleep 5 && docker start claude-container && docker exec -it claude-container zsh"

alias claude-dir="cd ~/code/claude-docker/.devcontainer"
alias dc-cc="cd ~/code/claude-docker/.devcontainer && open -a Orbstack && sleep 5 && docker compose up -d claude-code && docker exec -it claude-code zsh"

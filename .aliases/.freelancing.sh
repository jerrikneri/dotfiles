# PHP
alias 74ci="/usr/bin/php7.4 /usr/local/bin/composer install"

alias sail='sh $([ -f sail ] && echo sail || echo vendor/bin/sail)'

# TP
alias tpp="cd $REPOS/trialpartners/portal"
# WSL2 / Linux
# alias tpup="sqlstart && tpp && tpserve"
# MacOS

# TODO: turn into function with flags to use brew / takeout / valet / etc.
# alias tpup="tpp && sqlstart && tpserve"
alias tpup="tpp && dockerstart && tpserve"
alias tpdn="tpp && sail down && dockerstop"
# Php Serve
# alias tpserve="php artisan serve --host=trialpartners.local --port=8080 --env=.env"
# Valet
# alias tpserve="valet start"

alias tpserve="sail up"

# Win/Linux
alias psife-up="psife && nvm use 16.13 && is"
alias psibe-up="psibe && sqlstart && php artisan serve --host=psi.local --port=8000 --env=.env"

# Mac
# Brew
# alias sqlstart="brew services start mysql"
# alias sqlstop="brew services stop mysql"

alias dockerstart="open --background -a Docker; sleep 1"
alias dockerstop="killall Docker"

# Takeout
alias sqlstart="open --background -a Docker; sleep 1; takeout start --all"
alias sqlstop="takeout stop --all; killall Docker"

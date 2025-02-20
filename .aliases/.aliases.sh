#Docker
alias docker-format="docker ps --format $FORMAT"

#Sourcing
alias refrash="cfg && srcdf && zsrc && cd -"
alias srcdf="source $DOTFILES/.index"
alias vsrc="cp ~/Config/.vimrc ~/.vimrc"
alias zfg="vim $ZDOTDIR/.zshrc"

#Stress Test
alias stress="yes > /dev/null & yes > /dev/null & yes > /dev/null & yes > /dev/null &"
alias stop="killall yes"

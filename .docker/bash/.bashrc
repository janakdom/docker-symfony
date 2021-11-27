export HISTFILE=~/bash/.bash_history
touch $HISTFILE
HISTSIZE=
HISTFILESIZE=
export HISTCONTROL=ignoreboth:erasedups

PS1="\[\e[37m\]\w\[\e[m\]\[\e[32m\] \\$\[\e[m\] "

# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
bindkey -e
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/zenyyxz/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall
#

# Load colors
autoload -U colors && colors

# A better prompt: [user@host] directory % (in color)
PROMPT='%n%m %F{blue}%~%f %# '

# Better history navigation (up/down arrows search based on what you've typed)
autoload -Uz up-line-or-beginning-search down-line-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' doown-line-or-beginning-search



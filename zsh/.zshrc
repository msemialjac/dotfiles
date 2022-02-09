#!/bin/sh

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZDOTDIR=$HOME/.config/zsh
HISTFILE=~/.zsh_history
setopt appendhistory
setopt SHARE_HISTORY
HISTSIZE=10000
SAVEHIST=10000

# some useful options (man zshoptions)
setopt autocd extendedglob nomatch menucomplete
setopt interactive_comments
#stty stop undef		# Disable ctrl-s to freeze terminal.
zle_highlight=('paste:none')

# beeping is annoying
unsetopt BEEP

ZSH_DISABLE_COMPFIX="true"
# completions
autoload -Uz compinit
compinit
zstyle ':completion:*' menu select
# zstyle ':completion::complete:lsof:*' menu yes select
zmodload zsh/complist
_comp_options+=(globdots)		# Include hidden files.

### SET MANPAGER
### Uncomment only one of these!

### "bat" as manpager
#export MANPAGER="sh -c 'col -bx | bat -l man -p'"

### "vim" as manpager
#export MANPAGER='/bin/bash -c "vim -MRn -c \"set buftype=nofile showtabline=0 ft=man ts=8 nomod nolist norelativenumber nonu noma\" -c \"normal L\" -c \"nmap q :qa<CR>\"</dev/tty <(col -b)"'
#export PATH="$PATH:$HOME/.vim/bundle/vim-superman/bin"

export MANPAGER="/bin/sh -c \"col -b | vim -c 'set ft=man ts=8 nomod nolist nonu noma' -\""
compdef vman="man"
### "nvim" as manpager
#export MANPAGER="nvim -c 'set ft=man' -"

autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

# Colors
autoload -Uz colors && colors

# Useful Functions
source "$ZDOTDIR/zsh-functions"

# Normal files to source
zsh_add_file "zsh-exports"
zsh_add_file "zsh-vim-mode"
zsh_add_file "zsh-aliases"
zsh_add_file "zsh-prompt"

# Plugins
zsh_add_plugin "zsh-users/zsh-autosuggestions"
zsh_add_plugin "zsh-users/zsh-syntax-highlighting"
zsh_add_plugin "hlissner/zsh-autopair"
zsh_add_plugin "mdumitru/git-aliases"
zsh_add_plugin "zpm-zsh/clipboard"
#zsh_add_plugin "Yabanahano/web-search"
#zsh_add_plugin "hcgraf/zsh-sudo"
#zsh_add_plugin "hcgraf/zsh-sudo"
#zsh_add_plugin "hcgraf/zsh-sudo"
zsh_add_completion "esc/conda-zsh-completion" false
# For more plugins: https://github.com/unixorn/awesome-zsh-plugins
# More completions https://github.com/zsh-users/zsh-completions

#----------------------------
#PLUGINS / FUNCTIONS MANUALY
# Copies the pathname of the current directory to the system or X Windows clipboard

# copydir to copy pwd into clipboard
function copydir {
  emulate -L zsh
  print -n $PWD | pbcopy # instead of clipcopy
}

# Web Search 
function web_search() {
  emulate -L zsh

  # define search engine URLS
  typeset -A urls
  urls=(
    $ZSH_WEB_SEARCH_ENGINES
    google      "https://www.google.com/search?q="
    github      "https://github.com/search?q="
    stackoverflow  "https://stackoverflow.com/search?q="
    reddit "https://www.reddit.com/search/?q="
  )

  # check whether the search engine is supported
  if [[ -z "$urls[$1]" ]]; then
    echo "Search engine '$1' not supported."
    return 1
  fi

  # search or go to main page depending on number of arguments passed
  if [[ $# -gt 1 ]]; then
    # build search url:
    # join arguments passed with '+', then append to search engine URL
    url="${urls[$1]}${(j:+:)@[2,-1]}"
  else
    # build main page url:
    # split by '/', then rejoin protocol (1) and domain (2) parts with '//'
    url="${(j://:)${(s:/:)urls[$1]}[1,2]}"
  fi

  open_command "$url"
}

alias google='web_search google'
alias github='web_search github'
alias stackoverflow='web_search stackoverflow'
alias reddit='web_search reddit'

# other search engine aliases
if [[ ${#ZSH_WEB_SEARCH_ENGINES} -gt 0 ]]; then
  typeset -A engines
  engines=($ZSH_WEB_SEARCH_ENGINES)
  for key in ${(k)engines}; do
    alias "$key"="web_search $key"
  done
  unset engines key
fi

# sudo - 2x ESC for sudo prefix
sudo-command-line() {
    [[ -z $BUFFER ]] && zle up-history
    if [[ $BUFFER == sudo\ * ]]; then
        LBUFFER="${LBUFFER#sudo }"
    elif [[ $BUFFER == $EDITOR\ * ]]; then
        LBUFFER="${LBUFFER#$EDITOR }"
        LBUFFER="sudoedit $LBUFFER"
    elif [[ $BUFFER == sudoedit\ * ]]; then
        LBUFFER="${LBUFFER#sudoedit }"
        LBUFFER="$EDITOR $LBUFFER"
    else
        LBUFFER="sudo $LBUFFER"
    fi
}
zle -N sudo-command-line
# Defined shortcut keys: CTRL+[Esc] CTRL+[Esc]
bindkey "\^e\^e" sudo-command-line
bindkey -M vicmd '\e\e' sudo-command-line

# copyfile <file>
function copyfile {
  emulate -L zsh
  pbcopy $1
}

# copy the active line from the command line buffer
# onto the system clipboard

copybuffer () {
  if which pbcopy &>/dev/null; then
    printf "%s" "$BUFFER" | pbcopy # clipcopy
  else
    zle -M "clipcopy not found. Please make sure you have Oh My Zsh installed correctly."
  fi
}

zle -N copybuffer

#bindkey -M emacs "^O" copybuffer
#bindkey -M viins "^O" copybuffer
bindkey -M vicmd "^O" copybuffer

##
#   Navigate directory history using ALT-LEFT and ALT-RIGHT. ALT-LEFT moves back to directories
#   that the user has changed to in the past, and ALT-RIGHT undoes ALT-LEFT.
#
#   Navigate directory hierarchy using ALT-UP and ALT-DOWN.
#   ALT-UP moves to higher hierarchy (cd ..)
#   ALT-DOWN moves into the first directory found in alphabetical order
#

dirhistory_past=($PWD)
dirhistory_future=()
export dirhistory_past
export dirhistory_future

export DIRHISTORY_SIZE=30

# Pop the last element of dirhistory_past.
# Pass the name of the variable to return the result in.
# Returns the element if the array was not empty,
# otherwise returns empty string.
function pop_past() {
  typeset -g $1="${dirhistory_past[$#dirhistory_past]}"
  if [[ $#dirhistory_past -gt 0 ]]; then
    dirhistory_past[$#dirhistory_past]=()
  fi
}

function pop_future() {
  typeset -g $1="${dirhistory_future[$#dirhistory_future]}"
  if [[ $#dirhistory_future -gt 0 ]]; then
    dirhistory_future[$#dirhistory_future]=()
  fi
}

# History aliases
alias h='history'
alias hs='history | grep'
alias hsi='history | grep -i'

# Push a new element onto the end of dirhistory_past. If the size of the array
# is >= DIRHISTORY_SIZE, the array is shifted
function push_past() {
  if [[ $#dirhistory_past -ge $DIRHISTORY_SIZE ]]; then
    shift dirhistory_past
  fi
  if [[ $#dirhistory_past -eq 0 || $dirhistory_past[$#dirhistory_past] != "$1" ]]; then
    dirhistory_past+=($1)
  fi
}

function push_future() {
  if [[ $#dirhistory_future -ge $DIRHISTORY_SIZE ]]; then
    shift dirhistory_future
  fi
  if [[ $#dirhistory_future -eq 0 || $dirhistory_futuret[$#dirhistory_future] != "$1" ]]; then
    dirhistory_future+=($1)
  fi
}

# Called by zsh when directory changes
autoload -U add-zsh-hook
add-zsh-hook chpwd chpwd_dirhistory
function chpwd_dirhistory() {
  push_past $PWD
  # If DIRHISTORY_CD is not set...
  if [[ -z "${DIRHISTORY_CD+x}" ]]; then
    # ... clear future.
    dirhistory_future=()
  fi
}

function dirhistory_cd(){
  DIRHISTORY_CD="1"
  cd $1
  unset DIRHISTORY_CD
}

# Move backward in directory history
function dirhistory_back() {
  local cw=""
  local d=""
  # Last element in dirhistory_past is the cwd.

  pop_past cw
  if [[ "" == "$cw" ]]; then
    # Someone overwrote our variable. Recover it.
    dirhistory_past=($PWD)
    return
  fi

  pop_past d
  if [[ "" != "$d" ]]; then
    dirhistory_cd $d
    push_future $cw
  else
    push_past $cw
  fi
}


# Move forward in directory history
function dirhistory_forward() {
  local d=""

  pop_future d
  if [[ "" != "$d" ]]; then
    dirhistory_cd $d
    push_past $d
  fi
}


# Bind keys to history navigation
function dirhistory_zle_dirhistory_back() {
  # Erase current line in buffer
  zle .kill-buffer
  dirhistory_back
  zle .accept-line
}

function dirhistory_zle_dirhistory_future() {
  # Erase current line in buffer
  zle .kill-buffer
  dirhistory_forward
  zle .accept-line
}

zle -N dirhistory_zle_dirhistory_back
bindkey "\e[3D" dirhistory_zle_dirhistory_back    # xterm in normal mode
bindkey "\e[1;3D" dirhistory_zle_dirhistory_back  # xterm in normal mode
bindkey "\e\e[D" dirhistory_zle_dirhistory_back   # Putty
bindkey "\eO3D" dirhistory_zle_dirhistory_back    # GNU screen
case "$TERM_PROGRAM" in
iTerm.app) bindkey "^[^[[D" dirhistory_zle_dirhistory_back ;;   # iTerm2
Apple_Terminal) bindkey "^[b" dirhistory_zle_dirhistory_back ;; # Terminal.app
esac
if (( ${+terminfo[kcub1]} )); then
  bindkey "^[${terminfo[kcub1]}" dirhistory_zle_dirhistory_back  # urxvt
fi

zle -N dirhistory_zle_dirhistory_future
bindkey "\e[3C" dirhistory_zle_dirhistory_future    # xterm in normal mode
bindkey "\e[1;3C" dirhistory_zle_dirhistory_future  # xterm in normal mode
bindkey "\e\e[C" dirhistory_zle_dirhistory_future   # Putty
bindkey "\eO3C" dirhistory_zle_dirhistory_future    # GNU screen
case "$TERM_PROGRAM" in
iTerm.app) bindkey "^[^[[C" dirhistory_zle_dirhistory_future ;;   # iTerm2
Apple_Terminal) bindkey "^[f" dirhistory_zle_dirhistory_future ;; # Terminal.app
esac
if (( ${+terminfo[kcuf1]} )); then
  bindkey "^[${terminfo[kcuf1]}" dirhistory_zle_dirhistory_future # urxvt
fi


#
# HIERARCHY Implemented in this section, in case someone wants to split it to another plugin if it clashes bindings
#

# Move up in hierarchy
function dirhistory_up() {
  cd .. || return 1
}

# Move down in hierarchy
function dirhistory_down() {
  cd "$(find . -mindepth 1 -maxdepth 1 -type d | sort -n | head -n 1)" || return 1
}


# Bind keys to hierarchy navigation
function dirhistory_zle_dirhistory_up() {
  zle .kill-buffer   # Erase current line in buffer
  dirhistory_up
  zle .accept-line
}

function dirhistory_zle_dirhistory_down() {
  zle .kill-buffer   # Erase current line in buffer
  dirhistory_down
  zle .accept-line
}

zle -N dirhistory_zle_dirhistory_up
bindkey "\e[3A" dirhistory_zle_dirhistory_up    # xterm in normal mode
bindkey "\e[1;3A" dirhistory_zle_dirhistory_up  # xterm in normal mode
bindkey "\e\e[A" dirhistory_zle_dirhistory_up   # Putty
bindkey "\eO3A" dirhistory_zle_dirhistory_up    # GNU screen
case "$TERM_PROGRAM" in
iTerm.app) bindkey "^[^[[A" dirhistory_zle_dirhistory_up ;;     # iTerm2
Apple_Terminal) bindkey "^[[A" dirhistory_zle_dirhistory_up ;;  # Terminal.app
esac
if (( ${+terminfo[kcuu1]} )); then
  bindkey "^[${terminfo[kcuu1]}" dirhistory_zle_dirhistory_up # urxvt
fi

zle -N dirhistory_zle_dirhistory_down
bindkey "\e[3B" dirhistory_zle_dirhistory_down    # xterm in normal mode
bindkey "\e[1;3B" dirhistory_zle_dirhistory_down  # xterm in normal mode
bindkey "\e\e[B" dirhistory_zle_dirhistory_down   # Putty
bindkey "\eO3B" dirhistory_zle_dirhistory_down    # GNU screen
case "$TERM_PROGRAM" in
iTerm.app) bindkey "^[^[[B" dirhistory_zle_dirhistory_down ;;     # iTerm2
Apple_Terminal) bindkey "^[[B" dirhistory_zle_dirhistory_down ;;  # Terminal.app
esac
if (( ${+terminfo[kcud1]} )); then
  bindkey "^[${terminfo[kcud1]}" dirhistory_zle_dirhistory_down # urxvt
fi


#This is based on: https://github.com/ranger/ranger/blob/master/examples/bash_automatic_cd.sh
#Paste this into your .zshrc:

function ranger-cd {
    tempfile="$(mktemp -t tmp.XXXXXX)"
    /usr/bin/ranger --choosedir="$tempfile" "${@:-$(pwd)}"
    test -f "$tempfile" &&
    if [ "$(cat -- "$tempfile")" != "$(echo -n `pwd`)" ]; then
        cd -- "$(cat "$tempfile")"
    fi  
    rm -f -- "$tempfile"
}


bindkey -s '^U' 'ranger-cd\n'
#ranger-cd will fire for Ctrl+O

alias rc="ranger-cd"
alias rcd="ranger-cd"
alias alc="setsid alacritty"
alias alacritty="setsid alacritty"
# alias pgweb="pgweb_linux_amd64"
alias yu="yay -Syu"
alias syu="sudo pacman Syu"
alias y="yay -S"
alias ys="yay -Ss"
alias yrns="yay -Rns"
alias yr="yay -R"
alias yar="pacman -Qtdq | yay -Rns -"
alias yarc="yay -Rcns $(pacman -Qdtq)"
#----------------------------

#END PLUGINS / FUNCTIONS MANUALY

# Key-bindings
#bindkey -s '^o' 'ranger^M'
#bindkey -s '^f' 'zi^M'
#bindkey -s '^s' 'ncdu^M'
# bindkey -s '^n' 'nvim $(fzf)^M'
# bindkey -s '^v' 'nvim\n'
bindkey -s '^z' 'zi^M'
bindkey '^[[P' delete-char
bindkey "^p" up-line-or-beginning-search # Up
bindkey "^n" down-line-or-beginning-search # Down
bindkey "^k" up-line-or-beginning-search # Up
bindkey "^j" down-line-or-beginning-search # Down
bindkey -r "^u"
bindkey -r "^d"

# Luke #1
# Edit line in vim with ctrl-e:
autoload edit-command-line; zle -N edit-command-line
bindkey '^e' edit-command-line

# FZF 
# TODO update for mac
#[ -f /usr/share/fzf/completion.zsh ] && source /usr/share/fzf/completion.zsh
#[ -f /usr/share/fzf/key-bindings.zsh ] && source /usr/share/fzf/key-bindings.zsh
#[ -f /usr/share/doc/fzf/examples/completion.zsh ] && source /usr/share/doc/fzf/examples/completion.zsh
#[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh
#[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
#[ -f $ZDOTDIR/completion/_fnm ] && fpath+="$ZDOTDIR/completion/"
# export FZF_DEFAULT_COMMAND='rg --hidden -l ""'
compinit

# Edit line in vim with ctrl-e:
#autoload edit-command-line; zle -N edit-command-line
# bindkey '^e' edit-command-line

# TODO Remove these
#setxkbmap -option caps:escape
#xset r rate 210 40

# Speedy keys
#xset r rate 210 40

# Environment variables set everywhere
#export EDITOR="nvim"
#export TERMINAL="alacritty"
#export BROWSER="brave"

# For QT Themes
export QT_QPA_PLATFORMTHEME=qt5ct

setxkbmap -option caps:escape
# swap escape and caps
# setxkbmap -option caps:swapescape
# setxkbmap -option caps:escape
# swap escape and caps
# setxkbmap -option caps:swapescape
# --------------------------------------

# Enable colors and change prompt:
#autoload -U colors && colors
#PS1="%B%{$fg[red]%}[%{$fg[yellow]%}%n%{$fg[green]%}@%{$fg[blue]%}%M %{$fg[magenta]%}%~%{$fg[red]%}]%{$reset_color%}$%b "

# History in cache directory:
#HISTSIZE=10000
#"SAVEHIST=10000
#"HISTFILE=~/.cache/zsh/history

# Basic auto/tab complete:
##autoload -U compinite "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh
##zstyle ':completion:*' menu select
##zmodload zsh/complist
##compinit
##_comp_options+=(globdots)		# Include hidden files.

# vi mode
bindkey -v
export KEYTIMEOUT=1

# Use vim keys in tab complete menu:
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -v '^?' backward-delete-char

# MSB Change CD for LF
#LFCD="$GOPATH/src/github.com/gokcehan/lf/etc/lfcd.sh"  # source
#LFCD="/home/msb/.config/lf/lfcd.sh"                                #  pre-built binary, make sure to use absolute path
#if [ -f "$LFCD" ]; then
#    source "$LFCD"
#fi

LS_COLORS='no=00;37:fi=00:di=00;33:ln=04;36:pi=40;33:so=01;35:bd=40;33;01:'
export CLICOLOR=1
export LS_COLORS
export LSCOLORS=ExGxBxDxCxEgEdxbxgxcxd
alias ls='ls --color=auto'
#alias ll="ls -alG"
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
#unalias run-help
#autoload run-help
HELPDIR=/usr/share/zsh/"${ZSH_VERSION}"/help
alias help=run-help


#bind '"\C-o":"lfcd\C-m"'

# Change cursor shape for different vi modes.
function zle-keymap-select {
  if [[ ${KEYMAP} == vicmd ]] ||
     [[ $1 = 'block' ]]; then
    echo -ne '\e[1 q'
  elif [[ ${KEYMAP} == main ]] ||
       [[ ${KEYMAP} == viins ]] ||
       [[ ${KEYMAP} = '' ]] ||
       [[ $1 = 'beam' ]]; then
    echo -ne '\e[5 q'
  fi
}
zle -N zle-keymap-select
zle-line-init() {
    zle -K viins # initiate `vi insert` as keymap (can be removed if `bindkey -V` has been set elsewhere)
    echo -ne "\e[5 q"
}
zle -N zle-line-init
echo -ne '\e[5 q' # Use beam shape cursor on startup.
preexec() { echo -ne '\e[5 q' ;} # Use beam shape cursor for each new prompt.

# Use lf to switch directories and bind it to ctrl-o
lfcd () {
    tmp="$(mktemp)"
    lf -last-dir-path="$tmp" "$@"
    if [ -f "$tmp" ]; then
        dir="$(cat "$tmp")"
        rm -f "$tmp"
        [ -d "$dir" ] && [ "$dir" != "$(pwd)" ] && cd "$dir"
    fi
}
#bindkey -s 'o' 'lfcd\n'
bindkey '\eq' push-input
bindkey -s '^o' '\eqlfcd\n'
bindkey -s '^r' '\eqrcd\n'
# Edit line in vim with ctrl-e:
autoload edit-command-line; zle -N edit-command-line
bindkey '^e' edit-command-line

# Load aliases and shortcuts if existent.
[ -f "$HOME/.config/shortcutrc" ] && source "$HOME/.config/shortcutrc"
[ -f "$HOME/.config/aliasrc" ] && source "$HOME/.config/aliasrc"


# Load zsh-syntax-highlighting; should be last.
source ~/powerlevel10k/powerlevel10k.zsh-theme
source /home/msb/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
fpath+=${ZDOTDIR:-~}/.zsh_functions

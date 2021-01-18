#!/bin/bash

# Set terminal window and tab/icon title
#
# usage: title short_tab_title [long_window_title]
#
# See: http://www.faqs.org/docs/Linux-mini/Xterm-Title.html#ss3.1
# Fully supports screen, hyper, iterm, and probably most modern xterm and rxvt
# (In screen, only short_tab_title is used)
function title {
  emulate -L zsh
  setopt prompt_subst

  [[ "$EMACS" == *term* ]] && return

  # if $2 is unset use $1 as default
  # if it is set and empty, leave it as is
  : "${2=$1}"

  if [[ "$TERM_PROGRAM" == "iTerm.app" ]]; then
    print -Pn "\e]2;$2:q\a" # set window name
    print -Pn "\e]1;$1:q\a" # set tab name
  elif [[ "$TERM_PROGRAM" == "Hyper" ]]; then
    print -Pn "\e]1;$2:q\a" # set tab name
    print -Pn "\e]2;$1:q\a" # set window name
  else
    case "$TERM" in
      cygwin|xterm*|putty*|rxvt*|ansi)
        print -Pn "\e]2;$2:q\a" # set window name
        print -Pn "\e]1;$1:q\a" # set tab name
      ;;

      screen*|tmux*)
        print -Pn "\ek$1:q\e\\" # set screen hardstatus
      ;;
    esac
  fi
}

function settitle() {
	local thetitle
    local _vcs_root_prefix
    thetitle="%3~"
    # [[ -n ${vcs_info_git_root} ]] && thetitle="${_vcs_root_prefix}$vcs_info_git_root:t${${PWD:A}#$~~vcs_info_git_root}"
    [[ -n ${vcs_info_git_root} ]] && {
        [[ ${vcs_info_msg_0_} == *red* ]] && _vcs_root_prefix="🔻" || _vcs_root_prefix="🔆"
        thetitle="${_vcs_root_prefix}$vcs_info_git_root:t"
    }
	ZSH_THEME_TERM_TITLE_IDLE="$ZSH_TAB_TITLE_PREFIX${thetitle} $ZSH_TAB_TITLE_SUFFIX"
}

ZSH_THEME_TERM_TAB_TITLE_IDLE="%20<..<%~%<<" #15 char left truncated PWD

if [[ "$ZSH_TAB_TITLE_DEFAULT_DISABLE_PREFIX" == true ]]; then
  ZSH_TAB_TITLE_PREFIX=""
elif [[ -z "$ZSH_TAB_TITLE_PREFIX" ]]; then
  ZSH_TAB_TITLE_PREFIX="%n@%m:"
fi

settitle

# Runs before showing the prompt
function omz_termsupport_precmd {
  emulate -L zsh

  if [[ "$ZSH_TAB_TITLE_DISABLE_AUTO_TITLE" == true ]]; then
    return
  fi

  settitle

  if [[ "$ZSH_TAB_TITLE_ONLY_FOLDER" == true ]]; then
    ZSH_THEME_TERM_TAB_TITLE_IDLE=${PWD##*/}
  fi

  title "$ZSH_THEME_TERM_TAB_TITLE_IDLE" "$ZSH_THEME_TERM_TITLE_IDLE"
}

# Runs before executing the command
function omz_termsupport_preexec {
  emulate -L zsh
  setopt extended_glob

  if [[ "$ZSH_TAB_TITLE_DISABLE_AUTO_TITLE" == true ]]; then
    return
  fi

  # cmd name only, or if this is sudo or ssh, the next cmd
  local CMD=${1[(wr)^(*=*|sudo|ssh|mosh|rake|-*)]:gs/%/%%}
  local LINE="${2:gs/%/%%}"

  if [[ "$ZSH_TAB_TITLE_CONCAT_FOLDER_PROCESS" == true ]]; then
    title "${PWD##*/}:%100>...>$LINE%<<" "${PWD##*/}:${CMD}"
  else
    title "%100>...>$LINE%<<" "$CMD"
  fi
}


# Execute the first time, so it show correctly on terminal load
title "$ZSH_THEME_TERM_TAB_TITLE_IDLE" "$ZSH_THEME_TERM_TITLE_IDLE"

autoload -U add-zsh-hook
add-zsh-hook precmd omz_termsupport_precmd
#add-zsh-hook preexec omz_termsupport_preexec

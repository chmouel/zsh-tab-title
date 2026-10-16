#!/usr/bin/env zsh
#bashbash Set terminal window and tab/icon title
#
# usage: title short_tab_title long_window_title
#
# See: http://www.faqs.org/docs/Linux-mini/Xterm-Title.html#ss3.1
# Fully supports screen, hyper, iterm, zellij, and probably most modern xterm and rxvt
# (In screen, only short_tab_title is used)

# Detect Zellij
_in_zellij() { [[ -n "$ZELLIJ" || -n "$ZELLIJ_SESSION_NAME" ]]; }

# Zellij rename actions
_zt_rename_tab()  { command zellij action rename-tab  "$1" >/dev/null 2>&1; }
_zt_rename_pane() { command zellij action rename-pane "$1" >/dev/null 2>&1; }

# Detect Herdr (https://herdr.dev), which only labels tabs via its CLI
_in_herdr() { [[ -n "$HERDR_TAB_ID" ]] && (( $+commands[herdr] )); }

# Commands considered AI coding agents. While one runs in herdr, a background
# watcher keeps the tab title in sync with the agent session name.
(( ${+ZSH_TAB_TITLE_AGENTS} )) || typeset -ga ZSH_TAB_TITLE_AGENTS=(pi claude codex opencode gemini amp crush cursor-agent droid)

# Print the current agent session title for this herdr pane.
# Prefers the pi session name (session_info entry), falls back to the
# terminal title set by the agent. Returns 1 when herdr reports no agent.
_zt_agent_title() {
  local json agent sess name
  json=$(command herdr pane get "$HERDR_PANE_ID" 2>/dev/null) || return 2
  agent=$(command jq -r '.result.pane.agent // empty' <<<"$json" 2>/dev/null)
  [[ -n "$agent" ]] || return 1
  sess=$(command jq -r '.result.pane.agent_session.value // empty' <<<"$json" 2>/dev/null)
  if [[ "$agent" == pi && -f "$sess" ]]; then
    name=$(command grep -F '"type":"session_info"' "$sess" 2>/dev/null | command tail -n 1 | command jq -r '.name // empty' 2>/dev/null)
  fi
  [[ -n "$name" ]] || name=$(command jq -r '.result.pane.terminal_title_stripped // empty' <<<"$json" 2>/dev/null)
  print -r -- "$name"
}

# Background loop: rename the herdr tab whenever the agent title changes.
# Exits once herdr stops reporting an agent (after it was seen) or after a
# grace period if no agent is ever detected.
_zt_agent_watch() {
  local title label seen=0 misses=0 rc
  local interval=${ZSH_TAB_TITLE_AGENT_POLL:-3}
  while :; do
    title=$(_zt_agent_title); rc=$?
    if (( rc == 0 )); then
      seen=1; misses=0
      # Compare against the live tab label so we re-assert our title if
      # something else (another shell, the agent) renamed the tab meanwhile
      label=$(command herdr tab get "$HERDR_TAB_ID" 2>/dev/null | command jq -r '.result.tab.label // empty' 2>/dev/null)
      if [[ -n "$title" && "$title" != "$label" ]]; then
        command herdr tab rename "$HERDR_TAB_ID" "$title" >/dev/null 2>&1
      fi
    else
      (( seen )) && break
      (( ++misses > 10 )) && break
    fi
    sleep "$interval"
  done
}

_zt_agent_watch_stop() {
  if [[ -n "${_zt_agent_watch_pid:-}" ]]; then
    kill "$_zt_agent_watch_pid" 2>/dev/null
    unset _zt_agent_watch_pid
  fi
}

# Optional associative arrays for custom name mapping
(( ${+ZSH_TAB_TITLE_CMD_MAP} )) || typeset -gA ZSH_TAB_TITLE_CMD_MAP

function title {
  emulate -L zsh
  setopt prompt_subst

  [[ "$EMACS" == *term* ]] && return

  # Handle Zellij first - use actual arguments directly
  if _in_zellij; then
    # Expand prompt sequences in arguments before passing to zellij
    local tab_name="$(print -P "$1")"
    local pane_name="$(print -P "$2")"
    _zt_rename_tab "$tab_name"
    _zt_rename_pane "$pane_name"
    return
  fi

  if _in_herdr; then
    local herdr_tab_name="$(print -P "$1")"
    if [[ -n "$herdr_tab_name" && "$herdr_tab_name" != "${_zt_herdr_last:-}" ]]; then
      typeset -g _zt_herdr_last="$herdr_tab_name"
      command herdr tab rename "$HERDR_TAB_ID" "$herdr_tab_name" >/dev/null 2>&1 &!
    fi
  fi

  tabTitle="\$1"
  termTitle="\$2"

  if [[ "$TERM_PROGRAM" == "iTerm.app" ]]; then
    print -Pn "\e]2;$termTitle:q\a" # set window name
    print -Pn "\e]1;$tabTitle:q\a" # set tab name
  elif [[ "$TERM_PROGRAM" == "Hyper" ]]; then
    print -Pn "\e]1;$termTitle:q\a" # set tab name
    print -Pn "\e]2;$tabTitle:q\a" # set window name
  else
    case "$TERM" in
      xterm-kitty)
        print -Pn "\e]1;$termTitle:q\a" # set window name
        print -Pn "\e]2;$tabTitle:q\a" # set tab name
      ;;

      cygwin|xterm*|putty*|rxvt*|ansi|${~ZSH_TAB_TITLE_ADDITIONAL_TERMS})
        print -Pn "\e]2;$termTitle:q\a" # set window name
        print -Pn "\e]1;$tabTitle:q\a" # set tab name
      ;;

      screen*|tmux*)
        print -Pn "\ek$tabTitle:q\e\\" # set screen hardstatus
      ;;
    esac
  fi
}

function setTerminalTitleInIdle {

  if [[ "${ZSH_TAB_TITLE_DISABLE_AUTO_TITLE:-}" == true ]]; then
    return
  fi

  if [[ "${ZSH_TAB_TITLE_ONLY_FOLDER:-}" == true ]]; then
    ZSH_THEME_TERM_TAB_TITLE_IDLE=${PWD##*/}
  else
    ZSH_THEME_TERM_TAB_TITLE_IDLE="%20<..<%~%<<" #15 char left truncated PWD
  fi

  if [[ "${ZSH_TAB_TITLE_DEFAULT_DISABLE_PREFIX:-}" == true ]]; then
  ZSH_TAB_TITLE_PREFIX=""
  elif [[ -z "${ZSH_TAB_TITLE_PREFIX:-}" ]]; then
    ZSH_TAB_TITLE_PREFIX="%n@%m:"
  fi

  ZSH_THEME_TERM_TITLE_IDLE="${ZSH_TAB_TITLE_PREFIX:-} %~ $ZSH_TAB_TITLE_SUFFIX"

  title "$ZSH_THEME_TERM_TAB_TITLE_IDLE" "$ZSH_THEME_TERM_TITLE_IDLE"
}

# Runs before showing the prompt
function omz_termsupport_precmd {
  emulate -L zsh

  _zt_agent_watch_stop
  # Force the idle title to be re-sent to herdr after an agent renamed the tab
  unset _zt_herdr_last

  setTerminalTitleInIdle
}

# Runs before executing the command
function omz_termsupport_preexec {
  emulate -L zsh
  setopt extended_glob

  if [[ "$ZSH_TAB_TITLE_DISABLE_AUTO_TITLE" == true ]]; then
    return
  fi

  # Check for ZSH_TAB_PROMPT environment variable override
  local zsh_tab_prompt_override=""
  local args
  args=("${(z)1}")  # Tokenize command line, respecting quotes

  # Search for ZSH_TAB_PROMPT= assignment
  for arg in "${args[@]}"; do
    if [[ "$arg" == ZSH_TAB_PROMPT=* ]]; then
      zsh_tab_prompt_override="${arg#ZSH_TAB_PROMPT=}"
      # Remove surrounding quotes if present
      zsh_tab_prompt_override="${zsh_tab_prompt_override%\"}"
      zsh_tab_prompt_override="${zsh_tab_prompt_override#\"}"
      zsh_tab_prompt_override="${zsh_tab_prompt_override%\'}"
      zsh_tab_prompt_override="${zsh_tab_prompt_override#\'}"
      break
    fi
  done

  # If override found and non-empty, use it and skip normal parsing
  if [[ -n "$zsh_tab_prompt_override" ]]; then
    title "$zsh_tab_prompt_override" "$zsh_tab_prompt_override"
    return
  fi

  if [[ "$ZSH_TAB_TITLE_ENABLE_FULL_COMMAND" == true ]]; then
  	  # full command
	  local CMD=${1:gs/%/%%}
    local LINE=${2:gs/%/%%}
  else
	  # cmd name only, or if this is sudo or ssh, the next cmd
	  local CMD=${1[(wr)^(*=*|sudo|ssh|mosh|rake|-*)]:gs/%/%%}
    local LINE=${2[(wr)^(*=*|sudo|ssh|mosh|rake|-*)]:gs/%/%%}
  fi

  if (( ${+ZSH_TAB_TITLE_CMD_MAP} )) && (( ${#ZSH_TAB_TITLE_CMD_MAP} > 0 )); then
    local base_cmd="${CMD}"

    if [[ -n "${ZSH_TAB_TITLE_CMD_MAP[$base_cmd]:-}" ]]; then
      local mapped_cmd="${ZSH_TAB_TITLE_CMD_MAP[$base_cmd]}"

      CMD="$mapped_cmd"

      if [[ "$ZSH_TAB_TITLE_ENABLE_FULL_COMMAND" == true ]]; then
        LINE="${LINE/$base_cmd/$mapped_cmd}"
      else
        LINE="$mapped_cmd"
      fi
    fi
  fi

  if [[ "$ZSH_TAB_TITLE_CONCAT_FOLDER_PROCESS" == true ]]; then
    title "${PWD##*/}:%100>...>$LINE%<<" "${PWD##*/}:${CMD}"
  else
    title "%100>...>$LINE%<<" "$CMD"
  fi

  # Agent sessions: follow the agent's session name while it runs
  if [[ "${ZSH_TAB_TITLE_AGENT_SESSION:-true}" == true ]] && _in_herdr && (( $+commands[jq] )); then
    local agent_cmd=${${1[(wr)^(*=*|sudo|command|exec|env|nocorrect|noglob|-*)]}:t}
    if (( ${ZSH_TAB_TITLE_AGENTS[(Ie)$agent_cmd]} )); then
      _zt_agent_watch_stop
      _zt_agent_watch &!
      typeset -g _zt_agent_watch_pid=$!
    fi
  fi
}

# Execute the first time, so it show correctly on terminal load
setTerminalTitleInIdle

autoload -U add-zsh-hook
add-zsh-hook precmd omz_termsupport_precmd
add-zsh-hook preexec omz_termsupport_preexec

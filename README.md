# ZSH Smart Title

A light fork of [trystan2k/zsh-tab-title](https://github.com/trystan2k/zsh-tab-title) — a ZSH plugin that automatically sets terminal tab titles based on current location and running command, based on the [oh-my-zsh](https://github.com/ohmyzsh/ohmyzsh/blob/master/lib/termsupport.zsh) termsupport library.

This fork adds:

- **Command name mapping** — rename commands in the tab title via `ZSH_TAB_TITLE_CMD_MAP`
- **Custom tab title override** — force a specific title per command with `ZSH_TAB_PROMPT`
- **Herdr terminal support** — tab title updates for the [Herdr](https://herdr.dev) terminal emulator
- **Agent session tracking** — keeps the tab title in sync with AI coding agent session names in Herdr

## Installation

### Using [zinit](https://github.com/zdharma/zinit)

Add `zinit light chmouel/zsh-smart-title` into `.zshrc`

### Using [zpm](https://github.com/zpm-zsh/zpm)

Add `zpm load chmouel/zsh-smart-title` into `.zshrc`

### Using [oh-my-zsh](https://github.com/robbyrussell/oh-my-zsh)

Execute `git clone https://github.com/chmouel/zsh-smart-title ~/.oh-my-zsh/custom/plugins/zsh-smart-title`. Add `zsh-smart-title` into plugins array in `.zshrc`

### Using [antigen](https://github.com/zsh-users/antigen)

Add `antigen bundle chmouel/zsh-smart-title` into `.zshrc`

### Using [zgen](https://github.com/tarjoilija/zgen)

Add `zgen load chmouel/zsh-smart-title` into `.zshrc`

## Configuration

You can configure the prefix and/or suffix to be showed in tab title, besides the current folder.

### DISABLE

You can disable the plugin adding

```sh
ZSH_TAB_TITLE_DISABLE_AUTO_TITLE=true
```

### CURRENT FOLDER

You can display in the tab title, just the last folder you are in. So for example, if you are at `/home/user/zsh-smart-title`, the tab will only display `zsh-smart-title`. The default behavior, it will show the complete path, truncated at 20 chars. To enable current folder only, do:

```sh
ZSH_TAB_TITLE_ONLY_FOLDER=true
```

### CONCAT FOLDER AND PROCESS

When executing a command, it is showed in the tab title. You can setup to concatenate the current folder to it, so it can display, for example, `zsh-smart-title:ls`, when doing a `ls` in `/home/user/zsh-smart-title`. To enable concat folder and process, do:

```sh
ZSH_TAB_TITLE_CONCAT_FOLDER_PROCESS=true
```

### FULL COMMAND

Enable to show the full command being run with it's arguments in the tab title. For example, ``nano .zshrc`` will show ``nano .zshrc`` instead of just ``nano``. Default is to display only the command without it's arguments.

```sh
ZSH_TAB_TITLE_ENABLE_FULL_COMMAND=true
```

### PREFIX

The prefix can be configured using the variable `ZSH_TAB_TITLE_PREFIX` and it will be added **before** the current folder, in tab title. For example:

```sh
ZSH_TAB_TITLE_PREFIX='$USER@$HOST - '
```

By default, if no value is informed, it is used the value `%m@%n:` which will show the user name and computer name, separated by @. For example: `trystan2k@MyPC: /home/trystan2k`. This default value can be disabled if variable `ZSH_TAB_TITLE_DEFAULT_DISABLE_PREFIX` is set to true. For example:

```sh
ZSH_TAB_TITLE_DEFAULT_DISABLE_PREFIX=true
```

### SUFFIX

The suffix can be configured using the variable `ZSH_TAB_TITLE_SUFFIX` and it will be added **after** the current folder, in tab title. For example:

```sh
ZSH_TAB_TITLE_SUFFIX='- $USER'
```

This variable has no default value, so if nothing is informed, no suffix is added

### COMMAND MAPPING

You can map command names to custom display names using the `ZSH_TAB_TITLE_CMD_MAP` associative array:

```sh
typeset -gA ZSH_TAB_TITLE_CMD_MAP
ZSH_TAB_TITLE_CMD_MAP=(
  "node" " NodeJS"
  "python3" " 🐍 Python"
  "docker-compose" " ⛴️ Docker"
  "nvim" " NeoVim"
  "git" " Git"
)
```

This must be declared **before** loading the plugin in your `.zshrc`. The mapping applies to the command name extracted by the plugin (after stripping sudo, ssh, etc.).

**Example**: When running `node server.js`, the tab title will show `NodeJS` (or `NodeJS server.js` if `ZSH_TAB_TITLE_ENABLE_FULL_COMMAND=true`).

### CUSTOM TAB TITLE OVERRIDE

You can force a specific tab title for individual commands by setting the `ZSH_TAB_PROMPT` environment variable. This bypasses all automatic command parsing, mapping, and concatenation logic.

**Syntax:**

```sh
env ZSH_TAB_PROMPT="Custom Title" command
ZSH_TAB_PROMPT="Custom Title" command
```

**Examples:**

```sh
# Running Claude Code with a custom tab title
env ZSH_TAB_PROMPT="Claude Code" claude

# Running a development server with project name
ZSH_TAB_PROMPT="API Dev" npm run dev

# Multiple environment variables with custom title
DEBUG=true ZSH_TAB_PROMPT="Debug Mode" node server.js
```

### AGENT SESSION TITLE (Herdr)

When running inside [Herdr](https://herdr.dev) and launching an AI coding agent, the plugin starts a small background watcher that keeps the tab title in sync with the agent session while it runs. It asks Herdr (`herdr pane get`) which agent runs in the pane and uses:

1. the session name for [pi](https://pi.dev) (last `session_info` entry of the session file), or
2. the terminal title set by the agent (e.g. Claude Code, Codex).

The watcher stops when the agent exits and the normal idle title is restored. Requires `jq`.

```sh
# Commands treated as agents (default shown)
ZSH_TAB_TITLE_AGENTS=(pi claude codex opencode gemini amp crush cursor-agent droid)
# Poll interval in seconds (default 3)
ZSH_TAB_TITLE_AGENT_POLL=3
# Disable the feature
ZSH_TAB_TITLE_AGENT_SESSION=false
```

### ADDITIONAL TERMS

By default the tab title is set for iTerm, Hyper, Zellij, Herdr (via ``herdr tab rename``), and where ``$TERM`` is set to one of ``cygwin,xterm*,putty*,rxvt*,ansi,screen*,tmux*``
Additional $TERMS to set the tab title for can be configured with the variable ``ZSH_TAB_TITLE_ADDITIONAL_TERMS``. For example:

```sh
ZSH_TAB_TITLE_ADDITIONAL_TERMS='alacritty|kitty|foot'
```

This variable has no default value, so if nothing is informed, no suffix is added

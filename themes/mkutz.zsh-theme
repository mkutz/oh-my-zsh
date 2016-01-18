# vim:ft=zsh ts=2 sw=2 sts=2
#
# mkutz's theme based on agnoster's Theme - https://gist.github.com/3712874
# A Powerline-inspired theme for ZSH
#
# # README
#
# In order for this theme to render correctly, you will need a
# [Powerline-patched font](https://github.com/Lokaltog/powerline-fonts).
# Make sure you have a recent version: the code points that Powerline
# uses changed in 2012, and older versions will display incorrectly,
# in confusing ways.
#
# In addition, I recommend the
# [Solarized theme](https://github.com/altercation/solarized/) and, if you're
# using it on Mac OS X, [iTerm 2](http://www.iterm2.com/) over Terminal.app -
# it has significantly better color fidelity.
#
# # Goals
#
# The aim of this theme is to only show you *relevant* information. Like most
# prompts, it will only show git information when in a git working directory.
# However, it goes a step further: everything from the current user and
# hostname to whether the last call exited with an error to whether background
# jobs are running in this shell will all be displayed automatically when
# appropriate.

### Segment drawing
# A few utility functions to make it easy and re-usable to draw segmented prompts

CURRENT_BG='NONE'

# Special Powerline characters

() {
  local LC_ALL="" LC_CTYPE="en_US.UTF-8"
  # NOTE: This segment separator character is correct.  In 2012, Powerline changed
  # the code points they use for their special characters. This is the new code point.
  # If this is not working for you, you probably have an old version of the
  # Powerline-patched fonts installed. Download and install the new version.
  # Do not submit PRs to change this unless you have reviewed the Powerline code point
  # history and have new information.
  # This is defined using a Unicode escape sequence so it is unambiguously readable, regardless of
  # what font the user is viewing this source code in. Do not replace the
  # escape sequence with a single literal character.
  # Do not change this! Do not make it '\u2b80'; that is the old, wrong code point.
  SEGMENT_SEPARATOR=$'\ue0b0'
  SEGMENT_SEPARATOR_BACK=$'\ue0b2'
}

SEGMENTS=0
SEGMENTS_BACK=0

function apply_fg {
  if [[ $1 =~ '^[0-9]+$' ]]; then
    echo -ne "$FG[$1]"
  else
    echo -ne "%F{$1}"
  fi
}

function apply_bg {
  if [[ $1 =~ '^[0-9]+$' ]]; then
    echo -ne "$BG[$1]"
  else
    echo -ne "%K{$1}"
  fi
}

function exitcode_marker {
  local exit_code="$1"
  if [ ! -z "${last_command}" ]; then
    if [ "${exit_code}" = 0 ]; then
      echo -ne "✔"
    else
      echo -ne "✘"
    fi
    return 0
  fi
  return 1
}


# Begin a segment
# Takes two arguments, background and foreground. Both can be omitted,
# rendering default background/foreground.
function prompt_segment {
  local bg=$1
  local fg=$2
  local text=$3

  if [[ $SEGMENTS -gt 0 ]]; then
    echo -ne " $(apply_fg $CURRENT_BG)$(apply_bg $bg)$SEGMENT_SEPARATOR"
  fi

  echo -ne "$(apply_bg $bg)$(apply_fg $fg) "

  CURRENT_BG=$bg
  SEGMENTS+=1
  [[ -n $text ]] && echo -ne $text
}


# End the prompt, closing any open segments
function prompt_end {
  if [[ -n $CURRENT_BG ]]; then
    echo -ne "$(apply_fg $CURRENT_BG)$(apply_bg default)$SEGMENT_SEPARATOR"
  else
    echo -ne "%{%k%}"
  fi
  echo -ne "%K{default}%F{default}"
  CURRENT_BG=''
}

function prompt_back_segment {
  local bg=$1
  local fg=$2
  local text=$3
  local length=$((${#text}+2))

  tput cuf $(($COLUMNS-$SEGMENTS_BACK-$length))

  if [[ $SEGMENTS_BACK -gt 0 ]]; then
    echo -ne "$(apply_fg $CURRENT_BG)$(apply_bg $bg)$SEGMENT_SEPARATOR"
  fi

  echo -ne "$(apply_bg $bg)$(apply_fg $fg) "

  CURRENT_BG=$bg
  SEGMENTS_BACK+=$length
  [[ -n $text ]] && echo -ne "$text "

  tput rc
}

function prompt_back_end {
  tput cuf $(($COLUMNS-$SEGMENTS_BACK-1))
  if [[ -n $CURRENT_BG ]]; then
    echo -ne "$(apply_fg $CURRENT_BG)$(apply_bg default)$SEGMENT_SEPARATOR_BACK"
  else
    echo -ne "%{%k%}"
  fi
  echo -ne "%K{default}%F{default}\n"
  CURRENT_BG=''
}


### Prompt components
# Each component will draw itself, and hide itself if no information needs to be shown

# Context: user@hostname (who am I and where am I)
function prompt_context {
  if [[ "$USER" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
    prompt_segment yellow 000
    [[ $UID -eq 0 ]] && echo -ne "♚ " || echo -n "♟ "
    echo -ne "$USER@%m"
  fi
}

# Git: branch/detached head, dirty status
function prompt_git {
  if git is-repo; then
    prompt_segment 202 000 "$(git prompt-status)"
  fi
}

function

# Dir: current working directory
function prompt_dir {
  prompt_segment blue black '%~'
}

# Virtualenv: current working virtualenv
function prompt_virtualenv {
  local virtualenv_path="$VIRTUAL_ENV"
  if [[ -n $virtualenv_path && -n $VIRTUAL_ENV_DISABLE_PROMPT ]]; then
    prompt_segment blue black "(`basename $virtualenv_path`)"
  fi
}

# Status:
# - was there an error
# - are there background jobs?
function prompt_status {
  if [ ! -z "${last_command}" ]; then
    if [[ "${exit_code}" -ne 0 ]]; then
      prompt_segment red black "$(exitcode_marker ${exit_code})"
    else
      prompt_segment green black "$(exitcode_marker ${exit_code})"
    fi

    if [[ $(jobs -l | wc -l) -gt 0 ]]; then
      prompt_segment yellow black ⧗
    fi
  fi
}

## Main prompt
function build_prompt {
  prompt_status
  #prompt_back_end

  prompt_virtualenv
  prompt_context
  prompt_dir
  prompt_git
  prompt_end
}

function set_prompt {
  PROMPT="%{%f%b%k%}$(build_prompt) "
}

function update_title_precmd {
  echo -ne "\e]0;"
  if git is-repo; then
    echo -ne "$(git repo-name)"
  else
    echo -ne "$(pwd)"
  fi
  if [ ! -z "${last_command}" ]; then
    echo -ne ": ${last_command/%\ */}"
    echo -ne " $(exitcode_marker ${exit_code})"
  fi
  echo -ne "\007"
}

function update_title_preexec {
    local current_command="$1"
    echo -ne "\e]0;"
    if git is-repo; then
        echo -ne "$(git repo-name)"
    else
        echo -ne "$(pwd)"
    fi
    echo -ne ": ${current_command/%\ */}"
    echo -ne " ⧗"
    echo -ne "\007"
}

function update_last_command_preexec {
  last_command=$1
}

function update_exit_code_precmd {
  exit_code="$?"
}

preexec_functions+=update_last_command_preexec
preexec_functions+=update_title_preexec

precmd_functions+=update_exit_code_precmd
precmd_functions+=update_title_precmd
precmd_functions+=set_prompt

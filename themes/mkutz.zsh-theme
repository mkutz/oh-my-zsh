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
}

SEGMENTS=0

function apply_fg {
  #echo -n "fg=$1"
  if [[ $1 =~ '^[0-9]+$' ]]; then
    echo -ne "$FG[$1]"
  else
    echo -ne "%F{$1}"
  fi  
}

function apply_bg {
  #echo -n "bg=$1"
  if [[ $1 =~ '^[0-9]+$' ]]; then
    echo -ne "$BG[$1]"
  else
    echo -ne "%K{$1}"
  fi  
}

# Begin a segment
# Takes two arguments, background and foreground. Both can be omitted,
# rendering default background/foreground.
function prompt_segment {
  local bg=$1
  local fg=$2
  local text=$3

  if [[ $SEGMENTS -gt 0 ]]; then
    echo -n " $(apply_fg $CURRENT_BG)$(apply_bg $bg)$SEGMENT_SEPARATOR"
  fi

  echo -n "$(apply_bg $bg)$(apply_fg $fg) "

  CURRENT_BG=$bg
  SEGMENTS+=1
  [[ -n $text ]] && echo -n $text
}

# End the prompt, closing any open segments
function prompt_end {
  if [[ -n $CURRENT_BG ]]; then
    echo -n "$(apply_fg $CURRENT_BG)$(apply_bg default)$SEGMENT_SEPARATOR"
  else
    echo -n "%{%k%}"
  fi
  echo -n "%K{default}%F{default}"
  CURRENT_BG=''
}

### Prompt components
# Each component will draw itself, and hide itself if no information needs to be shown

# Context: user@hostname (who am I and where am I)
function prompt_context {
  if [[ "$USER" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
    prompt_segment yellow 000
    [[ $UID -eq 0 ]] && echo -n "♚ " || echo -n "♟ "
    echo -n "$USER@%m"
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
prompt_status() {
  local symbols
  symbols=()
  if [ ! -z "${RETVAL}" ]; then
    [[ $RETVAL -ne 0 ]] && symbols+="%{%F{red}%}✘" || symbols+="%{%F{green}%}✔"
  fi
  [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="%{%F{yellow}%}⧗"

  [[ -n "$symbols" ]] && prompt_segment 000 default "$symbols"
}

## Main prompt
build_prompt() {
  RETVAL=$?
  prompt_status
  prompt_virtualenv
  prompt_context
  prompt_dir
  prompt_git
  prompt_end
}

PROMPT='%{%f%b%k%}$(build_prompt) '

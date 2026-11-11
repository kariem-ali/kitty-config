# Full-width prompt separator for bash, rebuilt before every prompt so it
# follows window resizes and font zoom (from the next prompt on).
#
# Not installed automatically: your prompt lives in your own dotfiles.
# To use it, source this file from ~/.bashrc and reference the variable
# lazily in PS1 (note the backslash, so it is expanded at every prompt):
#
#   . /path/to/kitty-config/extras/prompt-separator.bash
#   PS1="\${separator}\n\u@\h:\W\n\\$ "

__update_separator() {
  # printf can only pad with spaces, so build COLUMNS spaces, then turn
  # them into dashes. Pure bash: no external programs per prompt.
  printf -v separator '%*s' "${COLUMNS:-80}" ''
  separator=${separator// /-}
}

# Register once, even if ~/.bashrc is sourced again in the same session,
# and keep any existing PROMPT_COMMAND hooks (e.g. kitty shell integration).
if [[ $PROMPT_COMMAND != *__update_separator* ]]; then
  PROMPT_COMMAND="__update_separator${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
fi

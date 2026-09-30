/// Helper utilities providing non-intrusive shell integration scripts for remote SSH sessions.
class ShellIntegrationBootstrap {
  /// Generates a lightweight, in-memory Bash hook for OSC 133 sequences.
  static String get bashSnippet => '''
# Shellit OSC 133 Integration (Bash)
__shellit_precmd() {
  local exit_code=\$?
  printf "\\033]133;D;%s\\007" "\$exit_code"
  printf "\\033]133;A\\007"
}
__shellit_preexec() {
  printf "\\033]133;C\\007"
}
if [[ -z "\$__shellit_integrated" ]]; then
  __shellit_integrated=1
  PROMPT_COMMAND="__shellit_precmd; \$PROMPT_COMMAND"
  PS0="\\[\\033]133;B\\007\\]"
  trap '__shellit_preexec' DEBUG
fi
''';

  /// Generates a lightweight Zsh hook for OSC 133 sequences.
  static String get zshSnippet => '''
# Shellit OSC 133 Integration (Zsh)
__shellit_precmd() {
  local exit_code=\$?
  printf "\\033]133;D;%s\\007" "\$exit_code"
  printf "\\033]133;A\\007"
}
__shellit_preexec() {
  printf "\\033]133;B\\007"
  printf "\\033]133;C\\007"
}
if [[ -z "\$__shellit_integrated" ]]; then
  __shellit_integrated=1
  autoload -Uz add-zsh-hook
  add-zsh-hook precmd __shellit_precmd
  add-zsh-hook preexec __shellit_preexec
fi
''';

  /// Generates Fish shell integration for OSC 133 sequences.
  static String get fishSnippet => '''
# Shellit OSC 133 Integration (Fish)
function __shellit_postexec --on-event fish_postexec
    set -l exit_code \$status
    printf "\\033]133;D;%s\\007" "\$exit_code"
end
function __shellit_prompt --on-event fish_prompt
    printf "\\033]133;A\\007"
end
function __shellit_preexec --on-event fish_preexec
    printf "\\033]133;B\\007"
    printf "\\033]133;C\\007"
end
''';
}

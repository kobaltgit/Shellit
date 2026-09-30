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

  /// Generates a clean session-only one-liner that clears the screen on completion.
  static String get sessionSnippet => ' if [ -n "\$BASH_VERSION" ]; then '
      '__shellit_precmd() { local ec=\$?; printf "\\033]133;D;%s\\007\\033]133;A\\007" "\$ec"; }; '
      '__shellit_preexec() { printf "\\033]133;C\\007"; }; '
      'if [ -z "\$__shellit_integrated" ]; then '
      '__shellit_integrated=1; '
      'PROMPT_COMMAND="__shellit_precmd; \$PROMPT_COMMAND"; '
      'PS0="\\[\\033]133;B\\007\\]"; '
      'trap \'__shellit_preexec\' DEBUG; '
      'fi; '
      'elif [ -n "\$ZSH_VERSION" ]; then '
      'autoload -Uz add-zsh-hook 2>/dev/null; '
      '__shellit_precmd() { local ec=\$?; printf "\\033]133;D;%s\\007\\033]133;A\\007" "\$ec"; }; '
      '__shellit_preexec() { printf "\\033]133;B\\007\\033]133;C\\007"; }; '
      'if [ -z "\$__shellit_integrated" ]; then '
      '__shellit_integrated=1; '
      'add-zsh-hook precmd __shellit_precmd 2>/dev/null; '
      'add-zsh-hook preexec __shellit_preexec 2>/dev/null; '
      'fi; '
      'fi; clear\n';

  /// Generates a command that safely appends the hook into ~/.bashrc and reloads it.
  static String get permanentSnippet => 'cat << \'EOF\' >> ~/.bashrc\n'
      '\n'
      '# Shellit OSC 133 Integration\n'
      '__shellit_precmd() {\n'
      '  local exit_code=\$?\n'
      '  printf "\\033]133;D;%s\\007\\033]133;A\\007" "\$exit_code"\n'
      '}\n'
      '__shellit_preexec() {\n'
      '  printf "\\033]133;C\\007"\n'
      '}\n'
      'if [ -z "\$__shellit_integrated" ]; then\n'
      '  __shellit_integrated=1\n'
      '  PROMPT_COMMAND="__shellit_precmd; \$PROMPT_COMMAND"\n'
      '  PS0="\\[\\033]133;B\\007\\]"\n'
      '  trap \'__shellit_preexec\' DEBUG\n'
      'fi\n'
      'EOF\n'
      'source ~/.bashrc 2>/dev/null; clear\n';

  /// Backwards-compatible alias for sessionSnippet.
  static String get autoInjectSnippet => sessionSnippet;
}

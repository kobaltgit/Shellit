/// Environment type for the host with security implications.
enum HostEnvironment {
  production,
  staging,
  development,
  defaultEnv,
}

/// Supported authentication methods for SSH connections.
enum HostAuthType {
  password,
  privateKey,
  sshAgent,
  keyboardInteractive,
  none,
}

/// Key algorithms supported for private key generation & parsing.
enum KeyType {
  ed25519,
  rsa,
  ecdsa,
}

/// OS / Device type of remote servers for displaying icons.
enum OsType {
  ubuntu,
  debian,
  centos,
  alpine,
  arch,
  fedora,
  rocky,
  almalinux,
  redhat,
  freebsd,
  raspberryPi,
  macOS,
  windows,
  router,
  genericServer,
}

/// State of an active terminal SSH session.
enum SessionState {
  initial,
  connecting,
  authenticating,
  ready,
  disconnected,
  error,
}

/// Plugin UI mount target areas on Desktop.
enum PluginTarget {
  sidebar,
  statusbar,
  modal,
  headless,
  localization,
}

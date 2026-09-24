import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../localization/localization_scope.dart';
import '../../theme/shellit_theme.dart';

/// OpenSSH "Drunken Bishop" Randomart generator for SSH host key fingerprints.
class Randomart {
  Randomart._();

  /// Converts a fingerprint string (e.g. "SHA256:abc..." or hex or base64) into raw bytes.
  static List<int> parseFingerprint(String fingerprint) {
    var cleaned = fingerprint.trim();
    if (cleaned.startsWith('SHA256:')) {
      cleaned = cleaned.substring(7);
    }
    cleaned = cleaned.replaceAll(':', '').replaceAll(' ', '');

    // Check for hex format (e.g. MD5 or hex SHA256)
    final hexReg = RegExp(r'^[0-9a-fA-F]+$');
    if (cleaned.length >= 32 &&
        cleaned.length % 2 == 0 &&
        hexReg.hasMatch(cleaned)) {
      try {
        final bytes = <int>[];
        for (int i = 0; i < cleaned.length; i += 2) {
          bytes.add(int.parse(cleaned.substring(i, i + 2), radix: 16));
        }
        return bytes;
      } catch (_) {}
    }

    // Check for Base64 format (standard OpenSSH SHA-256)
    try {
      var b64 = cleaned;
      while (b64.length % 4 != 0) {
        b64 += '=';
      }
      return base64Decode(b64);
    } catch (_) {}

    // Fallback to UTF-8 bytes
    return utf8.encode(fingerprint);
  }

  /// Generates the standard OpenSSH visual ASCII box from a fingerprint string.
  static String generate({
    required String fingerprint,
    String keyType = 'RSA',
    String hashAlgo = 'SHA256',
  }) {
    final digest = parseFingerprint(fingerprint);
    return generateFromBytes(
      digest: digest,
      keyType: keyType,
      hashAlgo: hashAlgo,
    );
  }

  /// Generates Randomart from raw digest bytes using OpenSSH drunken bishop rules.
  static String generateFromBytes({
    required List<int> digest,
    String keyType = 'RSA',
    String hashAlgo = 'SHA256',
  }) {
    const width = 17;
    const height = 9;
    final board = List.generate(height, (_) => List.filled(width, 0));
    int x = width ~/ 2; // 8
    int y = height ~/ 2; // 4

    for (final b in digest) {
      var byteVal = b;
      for (int i = 0; i < 4; i++) {
        final dx = (byteVal & 0x1) != 0 ? 1 : -1;
        final dy = (byteVal & 0x2) != 0 ? 1 : -1;
        x = (x + dx).clamp(0, width - 1);
        y = (y + dy).clamp(0, height - 1);
        board[y][x]++;
        byteVal >>= 2;
      }
    }

    const symbols = ' .o+=*BOX@%&#/^';
    final lines = <String>[];

    // Header border: +--[keyType]----+ (17 inner characters)
    final titleTag = keyType.trim().isNotEmpty ? '[${keyType.trim()}]' : '';
    lines.add('+${_centerPad(titleTag, width)}+');

    // 9 rows of ASCII art
    for (int r = 0; r < height; r++) {
      final buffer = StringBuffer('|');
      for (int c = 0; c < width; c++) {
        if (r == height ~/ 2 && c == width ~/ 2 && !(r == y && c == x)) {
          buffer.write('S'); // Start position
        } else if (r == y && c == x) {
          buffer.write('E'); // End position
        } else {
          final count = board[r][c];
          final char = count >= symbols.length
              ? symbols[symbols.length - 1]
              : symbols[count];
          buffer.write(char);
        }
      }
      buffer.write('|');
      lines.add(buffer.toString());
    }

    // Footer border: +----[SHA256]-----+ (17 inner characters)
    final algoTag = hashAlgo.trim().isNotEmpty ? '[${hashAlgo.trim()}]' : '';
    lines.add('+${_centerPad(algoTag, width)}+');

    return lines.join('\n');
  }

  static String _centerPad(String tag, int totalWidth, [String padChar = '-']) {
    if (tag.length >= totalWidth) {
      return tag.substring(0, totalWidth);
    }
    final remaining = totalWidth - tag.length;
    final left = remaining ~/ 2;
    final right = remaining - left;
    return (padChar * left) + tag + (padChar * right);
  }
}

/// Modal dialog for SSH host key verification (TOFU & MitM change warning).
class HostKeyDialog extends StatefulWidget {
  final String hostname;
  final int port;
  final String keyType;
  final String fingerprintSha256;
  final String? expectedFingerprint;
  final bool isMismatch;

  const HostKeyDialog({
    super.key,
    required this.hostname,
    required this.port,
    required this.keyType,
    required this.fingerprintSha256,
    this.expectedFingerprint,
    this.isMismatch = false,
  });

  /// Displays the host key verification dialog and returns true if trusted, false if aborted.
  static Future<bool> show({
    required BuildContext context,
    required String hostname,
    required int port,
    required String keyType,
    required String fingerprintSha256,
    String? expectedFingerprint,
    bool isMismatch = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => HostKeyDialog(
        hostname: hostname,
        port: port,
        keyType: keyType,
        fingerprintSha256: fingerprintSha256,
        expectedFingerprint: expectedFingerprint,
        isMismatch: isMismatch,
      ),
    );
    return result ?? false;
  }

  @override
  State<HostKeyDialog> createState() => _HostKeyDialogState();
}

class _HostKeyDialogState extends State<HostKeyDialog> {
  bool _overrideConfirmed = false;
  late final String _randomart;

  @override
  void initState() {
    super.initState();
    _randomart = Randomart.generate(
      fingerprint: widget.fingerprintSha256,
      keyType: widget.keyType,
      hashAlgo: 'SHA256',
    );
  }

  Future<void> _copy(String text, String successMessage) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline,
                  size: 14, color: ShellitColors.statusGreen),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  successMessage,
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: ShellitColors.obsidianCard,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1500),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: ShellitColors.border),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMismatch = widget.isMismatch;
    final primaryColor =
        isMismatch ? ShellitColors.statusRed : ShellitColors.accentCyan;

    return AlertDialog(
      backgroundColor: ShellitColors.obsidianCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isMismatch ? ShellitColors.statusRed : ShellitColors.border,
          width: isMismatch ? 2 : 1,
        ),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isMismatch ? Icons.warning_amber_rounded : Icons.shield_outlined,
            color: primaryColor,
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isMismatch
                  ? context.tr(
                      'host_key.mismatch_title',
                      defaultText:
                          'WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!',
                    )
                  : context.tr(
                      'host_key.tofu_title',
                      defaultText: 'Trust this host?',
                    ),
              style: TextStyle(
                color: isMismatch ? ShellitColors.statusRed : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 580,
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Mismatch Warning Banner or TOFU Info
              if (isMismatch) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ShellitColors.statusRed.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: ShellitColors.statusRed.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.gpp_bad_rounded,
                              color: ShellitColors.statusRed, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.tr(
                                'host_key.mismatch_alert_head',
                                defaultText:
                                    'POTENTIAL SECURITY BREACH (MAN-IN-THE-MIDDLE)!',
                              ),
                              style: const TextStyle(
                                color: ShellitColors.statusRed,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.tr(
                          'host_key.mismatch_explanation',
                          defaultText:
                              'Someone could be eavesdropping on your connection right now (man-in-the-middle attack)! '
                              'It is also possible that the host key has legitimately been changed or the server was re-installed. '
                              'Verify the new fingerprint before accepting.',
                        ),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ] else ...[
                Text(
                  context.tr(
                    'host_key.tofu_explanation',
                    defaultText:
                        'The authenticity of host \'${widget.hostname}:${widget.port}\' cannot be established. '
                        'This is the first time you are connecting to this server. '
                        'Verify the key fingerprint below before connecting.',
                  ),
                  style: const TextStyle(
                    color: ShellitColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Host Details Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1117),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ShellitColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(
                      context.tr('host_key.field_host', defaultText: 'Host:'),
                      '${widget.hostname}:${widget.port}',
                    ),
                    const SizedBox(height: 6),
                    _buildDetailRow(
                      context.tr('host_key.field_key_type',
                          defaultText: 'Key Type:'),
                      widget.keyType,
                    ),
                    const SizedBox(height: 8),

                    // Expected/Old Fingerprint (if mismatch)
                    if (isMismatch && widget.expectedFingerprint != null) ...[
                      Text(
                        context.tr('host_key.expected_fingerprint_label',
                            defaultText:
                                'Previously Trusted Fingerprint (Old):'),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: SelectableText(
                          widget.expectedFingerprint!,
                          style: const TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 12,
                            color: Colors.white54,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Offered/New Fingerprint
                    Row(
                      children: [
                        Text(
                          isMismatch
                              ? context.tr('host_key.offered_fingerprint_label',
                                  defaultText:
                                      'Offered Server Fingerprint (New):')
                              : context.tr('host_key.fingerprint_label',
                                  defaultText: 'SHA-256 Fingerprint:'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isMismatch
                                ? ShellitColors.statusRed
                                : ShellitColors.accentCyan,
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () => _copy(
                            widget.fingerprintSha256,
                            context.tr('host_key.fingerprint_copied',
                                defaultText: 'Fingerprint copied to clipboard'),
                          ),
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.copy_rounded,
                                    size: 12, color: Colors.white70),
                                const SizedBox(width: 4),
                                Text(
                                  context.tr('common.copy',
                                      defaultText: 'Copy'),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isMismatch
                              ? ShellitColors.statusRed.withValues(alpha: 0.5)
                              : ShellitColors.accentCyan.withValues(alpha: 0.4),
                        ),
                      ),
                      child: SelectableText(
                        widget.fingerprintSha256,
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isMismatch
                              ? const Color(0xFFFF8A80)
                              : ShellitColors.accentCyan,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Visual Randomart ASCII Box
              Row(
                children: [
                  Text(
                    context.tr('host_key.randomart_label',
                        defaultText: 'Visual Host Key (Randomart):'),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: ShellitColors.textMuted,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => _copy(
                      _randomart,
                      context.tr('host_key.randomart_copied',
                          defaultText: 'Randomart ASCII copied to clipboard'),
                    ),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.copy_rounded,
                              size: 12, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            context.tr('common.copy', defaultText: 'Copy'),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                alignment: Alignment.center,
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0C10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ShellitColors.border),
                ),
                child: SelectableText(
                  _randomart,
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 12,
                    height: 1.25,
                    color: Color(0xFF80CBC4),
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              // Mismatch Security Override Checkbox
              if (isMismatch) ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {
                    setState(() {
                      _overrideConfirmed = !_overrideConfirmed;
                    });
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 20,
                          width: 20,
                          child: Checkbox(
                            value: _overrideConfirmed,
                            activeColor: ShellitColors.statusRed,
                            onChanged: (val) {
                              setState(() {
                                _overrideConfirmed = val ?? false;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            context.tr(
                              'host_key.confirm_mismatch_checkbox',
                              defaultText:
                                  'I understand the risks of Man-in-the-Middle attacks and wish to accept and replace the host key.',
                            ),
                            style: const TextStyle(
                              color: ShellitColors.statusRed,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white70,
            side: const BorderSide(color: ShellitColors.border),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: Text(
            isMismatch
                ? context.tr('host_key.abort_btn',
                    defaultText: 'Cancel (Abort Connection)')
                : context.tr('common.cancel', defaultText: 'Cancel'),
          ),
        ),
        ElevatedButton(
          onPressed: (isMismatch && !_overrideConfirmed)
              ? null
              : () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isMismatch ? ShellitColors.statusRed : ShellitColors.accentCyan,
            foregroundColor: isMismatch ? Colors.white : Colors.black,
            disabledBackgroundColor: Colors.white12,
            disabledForegroundColor: Colors.white30,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: Text(
            context.tr('host_key.trust_and_connect',
                defaultText: 'Trust and Connect'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: ShellitColors.textMuted,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontFamily: 'JetBrains Mono',
            ),
          ),
        ),
      ],
    );
  }
}

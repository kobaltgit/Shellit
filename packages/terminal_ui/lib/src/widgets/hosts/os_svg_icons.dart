import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/material.dart';

/// Metadata and crisp SVG vector icons for each supported [OsType].
class OsMeta {
  final String label;
  final Color brandColor;
  final Color backgroundColor;
  final String svgContent;

  const OsMeta({
    required this.label,
    required this.brandColor,
    required this.backgroundColor,
    required this.svgContent,
  });

  /// Get metadata and SVG icon for a given [OsType].
  static OsMeta forType(OsType os) {
    return _osRegistry[os] ?? _genericServerMeta;
  }

  static const _genericServerMeta = OsMeta(
    label: 'Server',
    brandColor: Color(0xFF3B82F6),
    backgroundColor: Color(0x203B82F6),
    svgContent:
        '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<rect x="3" y="4" width="18" height="6" rx="1.5" stroke="#3B82F6" stroke-width="1.8"/>
<rect x="3" y="14" width="18" height="6" rx="1.5" stroke="#3B82F6" stroke-width="1.8"/>
<circle cx="6.5" cy="7" r="1" fill="#3B82F6"/>
<circle cx="9.5" cy="7" r="1" fill="#3B82F6"/>
<circle cx="6.5" cy="17" r="1" fill="#3B82F6"/>
<circle cx="9.5" cy="17" r="1" fill="#3B82F6"/>
<line x1="14" y1="7" x2="18" y2="7" stroke="#3B82F6" stroke-width="1.5" stroke-linecap="round"/>
<line x1="14" y1="17" x2="18" y2="17" stroke="#3B82F6" stroke-width="1.5" stroke-linecap="round"/>
</svg>''',
  );

  static final Map<OsType, OsMeta> _osRegistry = {
    OsType.ubuntu: const OsMeta(
      label: 'Ubuntu',
      brandColor: Color(0xFFE95420),
      backgroundColor: Color(0x25E95420),
      svgContent:
          '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<circle cx="12" cy="12" r="10" fill="#E95420"/>
<circle cx="12" cy="12" r="5.2" stroke="white" stroke-width="1.6"/>
<circle cx="18" cy="12" r="1.6" fill="white"/>
<circle cx="9" cy="6.8" r="1.6" fill="white"/>
<circle cx="9" cy="17.2" r="1.6" fill="white"/>
<path d="M15.5 12H18.5" stroke="#E95420" stroke-width="1.4"/>
<path d="M10.2 8.5L8 7" stroke="#E95420" stroke-width="1.4"/>
<path d="M10.2 15.5L8 17" stroke="#E95420" stroke-width="1.4"/>
</svg>''',
    ),
    OsType.debian: const OsMeta(
      label: 'Debian',
      brandColor: Color(0xFFD70A53),
      backgroundColor: Color(0x25D70A53),
      svgContent:
          '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M12 3C7.03 3 3 7.03 3 12C3 16.97 7.03 21 12 21C16.97 21 21 16.97 21 12C21 7.03 16.97 3 12 3ZM12.2 6.5C14.7 6.5 16.8 8.1 17.5 10.3C18.2 12.6 17.3 15 15.4 16.5C13.4 18 10.7 18.2 8.5 17.1C7.8 16.7 8.2 15.6 8.9 15.9C10.6 16.7 12.6 16.5 14.1 15.3C15.6 14.1 16.2 12.2 15.6 10.4C15 8.7 13.3 7.5 11.4 7.6C9.6 7.7 8.1 8.9 7.6 10.6C7.2 12 7.7 13.4 8.8 14.3C9.2 14.6 8.7 15.3 8.3 14.9C6.9 13.7 6.3 11.9 6.8 10.1C7.5 7.9 9.5 6.4 11.8 6.5C11.9 6.5 12.1 6.5 12.2 6.5Z" fill="#D70A53"/>
</svg>''',
    ),
    OsType.alpine: const OsMeta(
      label: 'Alpine',
      brandColor: Color(0xFF0D597F),
      backgroundColor: Color(0x250D597F),
      svgContent:
          '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M3 18L10 6L14 13L11.5 17.5L3 18Z" fill="#0D597F"/>
<path d="M10 6L12 9.5L10 13L8 9.5L10 6Z" fill="#38BDF8"/>
<path d="M12.5 13L16 7L21 18H14L12.5 13Z" fill="#0284C7"/>
<path d="M16 7L17.5 10L16 13L14.5 10L16 7Z" fill="white"/>
</svg>''',
    ),
    OsType.arch: const OsMeta(
      label: 'Arch Linux',
      brandColor: Color(0xFF1793D1),
      backgroundColor: Color(0x251793D1),
      svgContent:
          '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M12 3.5L19.5 20.5C18.2 19.6 17 19.1 15.6 19.1C14.7 19.1 13.8 19.4 12.9 19.8C12 18.5 11.1 17.2 10.2 15.9C11.5 15.4 12.9 15.3 14.1 15.8C13 14.1 12 12.5 12 12.5L9.6 15C8.8 13.8 8.1 12.5 7.3 11.3L12 3.5ZM4.5 20.5L9.1 13.5C9.7 14.6 10.4 15.7 11.1 16.9C9.8 17.5 8.7 18.4 7.8 19.5C6.7 19.9 5.6 20.2 4.5 20.5Z" fill="#1793D1"/>
</svg>''',
    ),
    OsType.fedora: const OsMeta(
      label: 'Fedora',
      brandColor: Color(0xFF51A2DA),
      backgroundColor: Color(0x2551A2DA),
      svgContent:
          '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<circle cx="12" cy="12" r="9.5" fill="#294172"/>
<path d="M16.5 12C16.5 14.5 14.5 16.5 12 16.5C9.5 16.5 7.5 14.5 7.5 12C7.5 9.5 9.5 7.5 12 7.5C13.5 7.5 14.8 8.2 15.6 9.4L13.8 10.6C13.4 9.9 12.7 9.5 12 9.5C10.6 9.5 9.5 10.6 9.5 12C9.5 13.4 10.6 14.5 12 14.5C13.4 14.5 14.5 13.4 14.5 12H12V10H16.5V12Z" fill="#51A2DA"/>
<rect x="14" y="6" width="2" height="6" rx="1" fill="white"/>
</svg>''',
    ),
    OsType.centos: const OsMeta(
      label: 'CentOS',
      brandColor: Color(0xFF932279),
      backgroundColor: Color(0x25932279),
      svgContent:
          '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M12 4L16 8H12V4Z" fill="#FFA800"/>
<path d="M12 4L8 8H12V4Z" fill="#932279"/>
<path d="M20 12L16 16V12H20Z" fill="#009639"/>
<path d="M20 12L16 8V12H20Z" fill="#FFA800"/>
<path d="M12 20L8 16H12V20Z" fill="#262577"/>
<path d="M12 20L16 16H12V20Z" fill="#009639"/>
<path d="M4 12L8 8V12H4Z" fill="#932279"/>
<path d="M4 12L8 16V12H4Z" fill="#262577"/>
<rect x="10.5" y="10.5" width="3" height="3" fill="white"/>
</svg>''',
    ),
    OsType.rocky: const OsMeta(
      label: 'Rocky Linux',
      brandColor: Color(0xFF10B981),
      backgroundColor: Color(0x2510B981),
      svgContent:
          '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M12 3C7.03 3 3 7.03 3 12C3 16.97 7.03 21 12 21C16.97 21 21 16.97 21 12C21 7.03 16.97 3 12 3ZM12 5.5C15.6 5.5 18.5 8.4 18.5 12C18.5 15.6 15.6 18.5 12 18.5C8.4 18.5 5.5 15.6 5.5 12C5.5 8.4 8.4 5.5 12 5.5Z" fill="#10B981"/>
<path d="M15 15L12 9L9 15H15Z" fill="#10B981"/>
</svg>''',
    ),
    OsType.almalinux: const OsMeta(
      label: 'AlmaLinux',
      brandColor: Color(0xFF0284C7),
      backgroundColor: Color(0x250284C7),
      svgContent:
          '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M12 3.5L14.5 7.5H9.5L12 3.5Z" fill="#EF4444"/>
<path d="M20.5 12L16.5 14.5V9.5L20.5 12Z" fill="#F59E0B"/>
<path d="M12 20.5L9.5 16.5H14.5L12 20.5Z" fill="#10B981"/>
<path d="M3.5 12L7.5 9.5V14.5L3.5 12Z" fill="#0284C7"/>
<circle cx="12" cy="12" r="3.2" fill="#1E293B"/>
</svg>''',
    ),
    OsType.redhat: const OsMeta(
      label: 'Red Hat',
      brandColor: Color(0xFFEE0000),
      backgroundColor: Color(0x25EE0000),
      svgContent:
          '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M19.8 13.5C20.3 13.5 21.5 14.1 21.5 15.3C21.5 17 17.5 19 12 19C6.5 19 2.5 17 2.5 15.3C2.5 14.1 3.7 13.5 4.2 13.5C4.8 13.5 7.5 14.6 12 14.6C16.5 14.6 19.2 13.5 19.8 13.5Z" fill="#EE0000"/>
<path d="M12 6C8.5 6 7 8 7 11C7 12.3 8 13.7 12 13.7C16 13.7 17 12.3 17 11C17 8 15.5 6 12 6Z" fill="#EE0000"/>
<path d="M7 11.5C7 11.5 7.5 12.5 12 12.5C16.5 12.5 17 11.5 17 11.5C17 12.5 16 14 12 14C8 14 7 12.5 7 11.5Z" fill="#1E293B"/>
</svg>''',
    ),
    OsType.raspberryPi: const OsMeta(
      label: 'Raspberry Pi',
      brandColor: Color(0xFFC51A4A),
      backgroundColor: Color(0x25C51A4A),
      svgContent:
          '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M12 6.5C11 4.5 9 4.5 8 5C7 5.5 7 7 8.5 7.5C10 8 12 6.5 12 6.5Z" fill="#6DB33F"/>
<path d="M12 6.5C13 4.5 15 4.5 16 5C17 5.5 17 7 15.5 7.5C14 8 12 6.5 12 6.5Z" fill="#6DB33F"/>
<circle cx="10" cy="10" r="2.2" fill="#C51A4A"/>
<circle cx="14" cy="10" r="2.2" fill="#C51A4A"/>
<circle cx="7.5" cy="13.5" r="2.2" fill="#C51A4A"/>
<circle cx="16.5" cy="13.5" r="2.2" fill="#C51A4A"/>
<circle cx="12" cy="13.5" r="2.4" fill="#C51A4A"/>
<circle cx="9.5" cy="17" r="2.2" fill="#C51A4A"/>
<circle cx="14.5" cy="17" r="2.2" fill="#C51A4A"/>
<circle cx="12" cy="19.5" r="1.8" fill="#C51A4A"/>
</svg>''',
    ),
    OsType.macOS: const OsMeta(
      label: 'macOS',
      brandColor: Color(0xFFE2E8F0),
      backgroundColor: Color(0x20E2E8F0),
      svgContent:
          '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M15.2 12.9C15.2 10.6 17 9.4 17.1 9.3C16 7.7 14.3 7.5 13.7 7.4C12.2 7.2 10.7 8.3 9.9 8.3C9.1 8.3 7.9 7.4 6.7 7.4C5.1 7.4 3.6 8.3 2.8 9.7C1.1 12.7 2.4 17.1 4 19.5C4.8 20.7 5.8 22 7.1 22C8.3 22 8.8 21.2 10.3 21.2C11.8 21.2 12.2 22 13.5 22C14.8 22 15.6 20.8 16.4 19.6C17.4 18.2 17.8 16.8 17.8 16.7C17.7 16.7 15.2 15.7 15.2 12.9Z" fill="#F8FAFC"/>
<path d="M13.8 5.6C14.5 4.7 15 3.5 14.8 2.3C13.8 2.3 12.5 3 11.9 3.8C11.3 4.5 10.8 5.7 11 6.9C12.1 7 13.2 6.4 13.8 5.6Z" fill="#F8FAFC"/>
</svg>''',
    ),
    OsType.windows: const OsMeta(
      label: 'Windows',
      brandColor: Color(0xFF0078D4),
      backgroundColor: Color(0x250078D4),
      svgContent:
          '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<rect x="3" y="3.5" width="8" height="8" rx="0.5" fill="#0078D4"/>
<rect x="13" y="3.5" width="8" height="8" rx="0.5" fill="#0078D4"/>
<rect x="3" y="13.5" width="8" height="8" rx="0.5" fill="#0078D4"/>
<rect x="13" y="13.5" width="8" height="8" rx="0.5" fill="#0078D4"/>
</svg>''',
    ),
    OsType.freebsd: const OsMeta(
      label: 'FreeBSD',
      brandColor: Color(0xFFAB2B28),
      backgroundColor: Color(0x25AB2B28),
      svgContent:
          '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<circle cx="12" cy="13" r="8" fill="#AB2B28"/>
<path d="M6 7C6.5 5 8 3.5 9 3C8.5 4.5 8.5 6 8.5 7.5L6 7Z" fill="#AB2B28"/>
<path d="M18 7C17.5 5 16 3.5 15 3C15.5 4.5 15.5 6 15.5 7.5L18 7Z" fill="#AB2B28"/>
<circle cx="9.5" cy="11.5" r="1.5" fill="white"/>
<circle cx="14.5" cy="11.5" r="1.5" fill="white"/>
<circle cx="10" cy="11.5" r="0.8" fill="#1E293B"/>
<circle cx="15" cy="11.5" r="0.8" fill="#1E293B"/>
</svg>''',
    ),
    OsType.router: const OsMeta(
      label: 'Router / Network',
      brandColor: Color(0xFF06B6D4),
      backgroundColor: Color(0x2506B6D4),
      svgContent:
          '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<rect x="3" y="12" width="18" height="7" rx="1.5" stroke="#06B6D4" stroke-width="1.8"/>
<circle cx="7" cy="15.5" r="1" fill="#06B6D4"/>
<circle cx="10.5" cy="15.5" r="1" fill="#06B6D4"/>
<circle cx="14" cy="15.5" r="1" fill="#06B6D4"/>
<line x1="6" y1="12" x2="6" y2="5" stroke="#06B6D4" stroke-width="1.8" stroke-linecap="round"/>
<line x1="18" y1="12" x2="18" y2="5" stroke="#06B6D4" stroke-width="1.8" stroke-linecap="round"/>
<path d="M9 7C10 6 11 5.5 12 5.5C13 5.5 14 6 15 7" stroke="#06B6D4" stroke-width="1.5" stroke-linecap="round"/>
</svg>''',
    ),
    OsType.genericServer: _genericServerMeta,
  };
}

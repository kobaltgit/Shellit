import 'package:core_foundation/core_foundation.dart';
import 'package:test/test.dart';
import 'package:ssh_network_core/ssh_network_core.dart';

void main() {
  group('OsDetector parseOsRelease Tests', () {
    const detector = OsDetector();

    test('parses Ubuntu from /etc/os-release', () {
      const ubuntuRelease = '''
NAME="Ubuntu"
VERSION="22.04.3 LTS (Jammy Jellyfish)"
ID=ubuntu
ID_LIKE=debian
PRETTY_NAME="Ubuntu 22.04.3 LTS"
VERSION_ID="22.04"
''';
      expect(detector.parseOsRelease(ubuntuRelease), equals(OsType.ubuntu));
    });

    test('parses Debian from /etc/os-release', () {
      const debianRelease = '''
PRETTY_NAME="Debian GNU/Linux 12 (bookworm)"
NAME="Debian GNU/Linux"
VERSION_ID="12"
VERSION="12 (bookworm)"
VERSION_CODENAME=bookworm
ID=debian
''';
      expect(detector.parseOsRelease(debianRelease), equals(OsType.debian));
    });

    test('parses Alpine from /etc/os-release', () {
      const alpineRelease = '''
NAME="Alpine Linux"
ID=alpine
VERSION_ID=3.19.1
PRETTY_NAME="Alpine Linux v3.19"
''';
      expect(detector.parseOsRelease(alpineRelease), equals(OsType.alpine));
    });

    test('parses Arch Linux from /etc/os-release', () {
      const archRelease = '''
NAME="Arch Linux"
PRETTY_NAME="Arch Linux"
ID=arch
BUILD_ID=rolling
''';
      expect(detector.parseOsRelease(archRelease), equals(OsType.arch));
    });

    test('parses Fedora from /etc/os-release', () {
      const fedoraRelease = '''
NAME="Fedora Linux"
VERSION="39 (Server Edition)"
ID=fedora
VERSION_ID=39
PLATFORM_ID="platform:f39"
PRETTY_NAME="Fedora Linux 39 (Server Edition)"
''';
      expect(detector.parseOsRelease(fedoraRelease), equals(OsType.fedora));
    });

    test('parses Rocky Linux from /etc/os-release', () {
      const rockyRelease = '''
NAME="Rocky Linux"
VERSION="9.3 (Blue Onyx)"
ID="rocky"
ID_LIKE="rhel centos fedora"
VERSION_ID="9.3"
PLATFORM_ID="platform:el9"
PRETTY_NAME="Rocky Linux 9.3 (Blue Onyx)"
''';
      expect(detector.parseOsRelease(rockyRelease), equals(OsType.rocky));
    });

    test('parses AlmaLinux from /etc/os-release', () {
      const almaRelease = '''
NAME="AlmaLinux"
VERSION="9.3 (Shamrock Pampas Cat)"
ID="almalinux"
ID_LIKE="rhel centos fedora"
VERSION_ID="9.3"
PLATFORM_ID="platform:el9"
PRETTY_NAME="AlmaLinux 9.3 (Shamrock Pampas Cat)"
''';
      expect(detector.parseOsRelease(almaRelease), equals(OsType.almalinux));
    });

    test('parses Red Hat Enterprise Linux from /etc/os-release', () {
      const rhelRelease = '''
NAME="Red Hat Enterprise Linux"
VERSION="8.9 (Ootpa)"
ID="rhel"
ID_LIKE="fedora"
VERSION_ID="8.9"
PRETTY_NAME="Red Hat Enterprise Linux 8.9 (Ootpa)"
''';
      expect(detector.parseOsRelease(rhelRelease), equals(OsType.redhat));
    });

    test('parses Raspberry Pi OS from /etc/os-release', () {
      const raspbianRelease = '''
PRETTY_NAME="Raspbian GNU/Linux 11 (bullseye)"
NAME="Raspbian GNU/Linux"
VERSION_ID="11"
VERSION="11 (bullseye)"
VERSION_CODENAME=bullseye
ID=raspbian
ID_LIKE=debian
''';
      expect(
          detector.parseOsRelease(raspbianRelease), equals(OsType.raspberryPi));
    });

    test('parses macOS from Darwin uname output', () {
      const darwinUname = 'Darwin\n';
      expect(detector.parseOsRelease(darwinUname), equals(OsType.macOS));
    });

    test('parses FreeBSD from uname output', () {
      const freebsdUname = 'FreeBSD\n';
      expect(detector.parseOsRelease(freebsdUname), equals(OsType.freebsd));
    });

    test('parses OpenWrt from /etc/os-release', () {
      const openwrtRelease = '''
NAME="OpenWrt"
VERSION="23.05.2"
ID="openwrt"
ID_LIKE="lede openwrt"
PRETTY_NAME="OpenWrt 23.05.2"
''';
      expect(detector.parseOsRelease(openwrtRelease), equals(OsType.router));
    });

    test('parses Windows OpenSSH or MINGW output', () {
      const windowsOutput = 'MINGW64_NT-10.0-19045';
      expect(detector.parseOsRelease(windowsOutput), equals(OsType.windows));
    });

    test('falls back to genericServer on unknown or empty output', () {
      expect(detector.parseOsRelease(''), equals(OsType.genericServer));
      expect(detector.parseOsRelease('unknown kernel'),
          equals(OsType.genericServer));
    });
  });
}

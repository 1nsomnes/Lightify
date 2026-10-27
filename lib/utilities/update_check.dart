import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

enum UpdateStatus { upToDate, outOfDate, unknown }

/// The running version and how it compares with the latest GitHub release.
class VersionInfo {
  const VersionInfo(this.version, this.status, {this.releaseUrl});

  final String version;
  final UpdateStatus status;
  // the latest release's page, when it's newer than this one
  final String? releaseUrl;
}

/// Compares the app's version (from pubspec.yaml) with the latest release on
/// GitHub. Releases are tagged `v<version>`, e.g. `v1.0.0`.
abstract final class UpdateCheck {
  static const repo = "1nsomnes/Lightify";
  // the window stays open for days, so check again after a while
  static const _maxAge = Duration(hours: 6);

  static Future<VersionInfo>? _cached;
  static DateTime _checkedAt = DateTime(0);

  /// Swappable for tests.
  @visibleForTesting
  static Future<VersionInfo> Function() checker = _check;

  /// The latest result, checking GitHub at most every few hours.
  static Future<VersionInfo> latest() {
    final now = DateTime.now();
    if (_cached == null || now.difference(_checkedAt) > _maxAge) {
      _checkedAt = now;
      _cached = checker();
    }
    return _cached!;
  }

  @visibleForTesting
  static void reset() {
    _cached = null;
    checker = _check;
  }

  static Future<VersionInfo> _check() async {
    final version = (await PackageInfo.fromPlatform()).version;
    try {
      // a plain client: the Spotify one would send its token to GitHub
      final response = await Dio().get(
        "https://api.github.com/repos/$repo/releases/latest",
        options: Options(headers: {"Accept": "application/vnd.github+json"}),
      );
      final String tag = response.data["tag_name"];
      final newer = compareVersions(tag, version) > 0;
      return VersionInfo(
        version,
        newer ? UpdateStatus.outOfDate : UpdateStatus.upToDate,
        releaseUrl: newer ? response.data["html_url"] : null,
      );
    } catch (e) {
      // offline, rate limited, or no release published yet
      debugPrint("couldn't check for updates: $e");
      return VersionInfo(version, UpdateStatus.unknown);
    }
  }

  /// Compares two versions like `v1.2` and `1.2.0` part by part; missing
  /// parts count as 0. Positive when [a] is newer.
  static int compareVersions(String a, String b) {
    List<int> parts(String v) => v
        .replaceFirst(RegExp(r"^v"), "")
        .split(RegExp(r"[+-]"))
        .first
        .split(".")
        .map((p) => int.tryParse(p) ?? 0)
        .toList();
    final pa = parts(a), pb = parts(b);
    for (var i = 0; i < pa.length || i < pb.length; i++) {
      final diff = (i < pa.length ? pa[i] : 0) - (i < pb.length ? pb[i] : 0);
      if (diff != 0) return diff;
    }
    return 0;
  }
}

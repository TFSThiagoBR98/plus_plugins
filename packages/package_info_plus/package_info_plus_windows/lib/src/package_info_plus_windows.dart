/// The Windows implementation of `package_info_plus`.
library package_info_plus_windows;

import 'dart:convert';
import 'dart:io';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:package_info_plus_platform_interface/package_info_data.dart';
import 'package:package_info_plus_platform_interface/package_info_platform_interface.dart';
import 'package:win32/win32.dart';
import 'package:path/path.dart' as path;

part 'file_version_info.dart';

/// The Windows implementation of [PackageInfoPlatform].
class PackageInfoWindows extends PackageInfoPlatform {
  /// Register this dart class as the platform implementation for linux
  static void registerWith() {
    PackageInfoPlatform.instance = PackageInfoWindows();
  }

  /// Returns a map with the following keys:
  /// appName, packageName, version, buildNumber
  @override
  Future<PackageInfoData> getAll() async {
    final info = _FileVersionInfo(Platform.resolvedExecutable);
    final versions = info.productVersion!.split('+');
    final versionJson = await _getVersionJson();
    final data = PackageInfoData(
      appName: versionJson['app_name'] ?? (info.productName ?? ''),
      packageName: info.internalName ?? '',
      version: versionJson['version'] ?? (versions.getOrNull(0) ?? ''),
      buildNumber: versionJson['build_number'] ?? (versions.getOrNull(1) ?? ''),
      buildSignature: '',
    );
    info.dispose();
    return data;
  }

  Future<Map<String, dynamic>> _getVersionJson() async {
    try {
      final exePath = await File(Platform.resolvedExecutable).resolveSymbolicLinks();
      final appPath = path.dirname(exePath);
      final assetPath = path.join(appPath, 'data', 'flutter_assets');
      final versionPath = path.join(assetPath, 'version.json');
      return jsonDecode(await File(versionPath).readAsString());
    } catch (_) {
      return <String, dynamic>{};
    }
  }
}

extension _GetOrNull<T> on List<T> {
  T? getOrNull(int index) => _checkIndex(index) ? this[index] : null;
  bool _checkIndex(int index) => index >= 0 && index < length;
}

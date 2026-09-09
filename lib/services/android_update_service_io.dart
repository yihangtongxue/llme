import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class AndroidUpdateInfo {
  const AndroidUpdateInfo({
    required this.versionName,
    required this.notes,
    required this.apkUrl,
    required this.size,
    required this.sha256,
  });

  final String versionName;
  final List<String> notes;
  final String apkUrl;
  final int size;
  final String sha256;
}

class _ReleaseAsset {
  const _ReleaseAsset({
    required this.fileName,
    required this.platform,
    required this.architecture,
    required this.packageType,
    required this.size,
    required this.sha256,
    required this.downloadUrl,
  });

  factory _ReleaseAsset.fromJson(Map<String, dynamic> json) {
    final fileName = json['fileName'];
    final platform = json['platform'];
    final architecture = json['architecture'];
    final packageType = json['packageType'];
    final size = json['size'];
    final sha256 = json['sha256'];
    final downloadUrl = json['downloadUrl'];
    final uri = downloadUrl is String ? Uri.tryParse(downloadUrl) : null;
    if (fileName is! String ||
        fileName.isEmpty ||
        platform is! String ||
        architecture is! String ||
        packageType is! String ||
        size is! int ||
        size < 1 ||
        sha256 is! String ||
        !RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(sha256) ||
        uri == null ||
        !uri.isScheme('https') ||
        uri.host.isEmpty) {
      throw const FormatException('更新附件格式不正确');
    }
    return _ReleaseAsset(
      fileName: fileName,
      platform: platform,
      architecture: architecture,
      packageType: packageType,
      size: size,
      sha256: sha256.toLowerCase(),
      downloadUrl: downloadUrl,
    );
  }

  final String fileName;
  final String platform;
  final String architecture;
  final String packageType;
  final int size;
  final String sha256;
  final String downloadUrl;
}

class _ReleaseManifest {
  const _ReleaseManifest({
    required this.version,
    required this.notes,
    required this.assets,
  });

  factory _ReleaseManifest.fromJson(Map<String, dynamic> json) {
    final schemaVersion = json['schemaVersion'];
    final channel = json['channel'];
    final version = json['version'];
    final notes = json['notes'];
    final assets = json['assets'];
    if ((schemaVersion != null && schemaVersion != 1) ||
        (channel != null && channel != 'stable') ||
        version is! String ||
        !_versionPattern.hasMatch(version) ||
        notes is! String ||
        assets is! List) {
      throw const FormatException('更新清单格式不正确');
    }
    return _ReleaseManifest(
      version: version,
      notes: notes
          .split(RegExp(r'\r?\n'))
          .map((note) => note.trim())
          .where((note) => note.isNotEmpty)
          .toList(growable: false),
      assets: assets
          .map((asset) {
            if (asset is! Map<String, dynamic>) {
              throw const FormatException('更新附件格式不正确');
            }
            return _ReleaseAsset.fromJson(asset);
          })
          .toList(growable: false),
    );
  }

  final String version;
  final List<String> notes;
  final List<_ReleaseAsset> assets;
}

final _versionPattern = RegExp(r'^\d+\.\d+\.\d+$');

enum AndroidUpdateInstallResult { installerOpened, permissionRequired }

class AndroidUpdateService {
  AndroidUpdateService._();

  static const _channel = MethodChannel('com.yihang.llme/android_update');
  static final _manifestUri = Uri.parse(
    'https://gitee.com/api/v5/repos/yihangtongxue/llme-releases/contents/'
    '.release-hub/updates/stable.json?ref=main',
  );

  static Future<AndroidUpdateInfo?> checkForUpdate() async {
    if (!Platform.isAndroid) return null;
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (!_versionPattern.hasMatch(packageInfo.version)) return null;
      final manifest = await _fetchManifest();
      if (_compareVersions(manifest.version, packageInfo.version) <= 0) {
        return null;
      }
      final asset = _selectAndroidApk(
        manifest.assets,
        await _supportedAbis(),
      );
      if (asset == null) return null;
      return AndroidUpdateInfo(
        versionName: manifest.version,
        notes: manifest.notes,
        apkUrl: asset.downloadUrl,
        size: asset.size,
        sha256: asset.sha256,
      );
    } catch (_) {
      // A failed update check must never prevent training records from loading.
      return null;
    }
  }

  static Future<_ReleaseManifest> _fetchManifest() async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(_manifestUri).timeout(
        const Duration(seconds: 8),
      );
      request.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');
      final response = await request.close().timeout(const Duration(seconds: 8));
      if (response.statusCode != HttpStatus.ok) {
        throw const HttpException('未能读取更新清单');
      }
      final responseJson = jsonDecode(await utf8.decoder.bind(response).join());
      if (responseJson is! Map<String, dynamic> ||
          responseJson['content'] is! String) {
        throw const FormatException('更新清单响应格式不正确');
      }
      final manifestJson = jsonDecode(
        utf8.decode(base64.decode(responseJson['content'] as String)),
      );
      if (manifestJson is! Map<String, dynamic>) {
        throw const FormatException('更新清单格式不正确');
      }
      return _ReleaseManifest.fromJson(manifestJson);
    } finally {
      client.close(force: true);
    }
  }

  static Future<List<String>> _supportedAbis() async {
    final abis = await _channel.invokeListMethod<String>('getSupportedAbis');
    return abis ?? const [];
  }

  static _ReleaseAsset? _selectAndroidApk(
    List<_ReleaseAsset> assets,
    List<String> supportedAbis,
  ) {
    final androidApks = assets.where(
      (asset) => asset.platform == 'android' && asset.packageType == 'apk',
    );
    for (final abi in supportedAbis) {
      for (final asset in androidApks) {
        if (asset.architecture == abi) return asset;
      }
    }
    for (final asset in androidApks) {
      if (asset.architecture == 'universal') return asset;
    }
    return null;
  }

  static int _compareVersions(String left, String right) {
    final leftParts = left.split('.').map(int.parse).toList(growable: false);
    final rightParts = right.split('.').map(int.parse).toList(growable: false);
    for (var index = 0; index < 3; index++) {
      final comparison = leftParts[index].compareTo(rightParts[index]);
      if (comparison != 0) return comparison;
    }
    return 0;
  }

  static Future<bool> canInstallPackages() async {
    if (!Platform.isAndroid) return false;
    return await _channel.invokeMethod<bool>('canRequestPackageInstalls') ??
        false;
  }

  static Future<Object> download(
    AndroidUpdateInfo update, {
    required void Function(double progress) onProgress,
  }) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(update.apkUrl)).timeout(
        const Duration(seconds: 15),
      );
      final response = await request.close().timeout(const Duration(seconds: 15));
      if (response.statusCode != HttpStatus.ok) {
        throw const HttpException('未能下载更新包');
      }
      final directory = await getApplicationSupportDirectory();
      final updates = Directory('${directory.path}/updates');
      await updates.create(recursive: true);
      final apk = File('${updates.path}/llme-${update.versionName}.apk');
      final sink = apk.openWrite();
      var received = 0;
      try {
        await for (final bytes in response) {
          sink.add(bytes);
          received += bytes.length;
          onProgress(received / update.size);
        }
      } finally {
        await sink.close();
      }
      if (received != update.size) {
        await apk.delete();
        throw const FormatException('更新包大小校验失败，请稍后重试');
      }
      return apk;
    } finally {
      client.close(force: true);
    }
  }

  static Future<AndroidUpdateInstallResult> verifyAndInstall(
    Object apkFile,
    AndroidUpdateInfo update,
  ) async {
    final apk = apkFile as File;
    if (await apk.length() != update.size) {
      await apk.delete();
      throw const FormatException('更新包大小校验失败，请稍后重试');
    }
    final checksum = await _channel.invokeMethod<String>('sha256', {
      'path': apk.path,
    });
    if (checksum?.toLowerCase() != update.sha256) {
      await apk.delete();
      throw const FormatException('更新包校验失败，请稍后重试');
    }
    final result = await _channel.invokeMethod<String>('installApk', {
      'path': apk.path,
    });
    return switch (result) {
      'installerOpened' => AndroidUpdateInstallResult.installerOpened,
      'permissionRequired' => AndroidUpdateInstallResult.permissionRequired,
      _ => throw StateError('无法打开系统安装器'),
    };
  }
}

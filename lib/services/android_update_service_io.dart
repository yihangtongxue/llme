import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class AndroidUpdateInfo {
  const AndroidUpdateInfo({
    required this.versionName,
    required this.versionCode,
    required this.minSupportedVersionCode,
    required this.notes,
    required this.apkUrl,
    required this.sha256,
    required this.currentVersionCode,
  });

  factory AndroidUpdateInfo.fromJson(
    Map<String, dynamic> json, {
    required int currentVersionCode,
  }) {
    final versionName = json['versionName'];
    final versionCode = json['versionCode'];
    final minSupportedVersionCode = json['minSupportedVersionCode'];
    final apkUrl = json['apkUrl'];
    final sha256 = json['sha256'];
    final notes = json['notes'];
    if (versionName is! String ||
        versionName.isEmpty ||
        versionCode is! int ||
        versionCode < 1 ||
        minSupportedVersionCode is! int ||
        minSupportedVersionCode < 1 ||
        apkUrl is! String ||
        Uri.tryParse(apkUrl)?.hasScheme != true ||
        sha256 is! String ||
        !RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(sha256) ||
        notes is! List ||
        notes.any((note) => note is! String)) {
      throw const FormatException('更新配置格式不正确');
    }
    return AndroidUpdateInfo(
      versionName: versionName,
      versionCode: versionCode,
      minSupportedVersionCode: minSupportedVersionCode,
      notes: notes.cast<String>(),
      apkUrl: apkUrl,
      sha256: sha256.toLowerCase(),
      currentVersionCode: currentVersionCode,
    );
  }

  final String versionName;
  final int versionCode;
  final int minSupportedVersionCode;
  final List<String> notes;
  final String apkUrl;
  final String sha256;
  final int currentVersionCode;

  bool get isRequired => currentVersionCode < minSupportedVersionCode;
}

enum AndroidUpdateInstallResult { installerOpened, permissionRequired }

class AndroidUpdateService {
  AndroidUpdateService._();

  static const _channel = MethodChannel('com.yihang.llme/android_update');
  static final _manifestUri = Uri.parse(
    'https://gitee.com/yihangtongxue/llme-releases/raw/master/updates/android.json',
  );

  static Future<AndroidUpdateInfo?> checkForUpdate() async {
    if (!Platform.isAndroid) return null;
    try {
      final currentVersionCode =
          await _channel.invokeMethod<int>('getVersionCode') ?? 0;
      if (currentVersionCode < 1) return null;
      final client = HttpClient();
      try {
        final request = await client.getUrl(_manifestUri).timeout(
          const Duration(seconds: 8),
        );
        request.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');
        final response = await request.close().timeout(const Duration(seconds: 8));
        if (response.statusCode != HttpStatus.ok) return null;
        final body = await utf8.decoder.bind(response).join();
        final json = jsonDecode(body);
        if (json is! Map<String, dynamic>) return null;
        final update = AndroidUpdateInfo.fromJson(
          json,
          currentVersionCode: currentVersionCode,
        );
        return update.versionCode > currentVersionCode ? update : null;
      } finally {
        client.close(force: true);
      }
    } catch (_) {
      // A failed update check must never prevent training records from loading.
      return null;
    }
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
      final apk = File('${updates.path}/llme-${update.versionCode}.apk');
      final sink = apk.openWrite();
      var received = 0;
      try {
        await for (final bytes in response) {
          sink.add(bytes);
          received += bytes.length;
          if (response.contentLength > 0) {
            onProgress(received / response.contentLength);
          }
        }
      } finally {
        await sink.close();
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

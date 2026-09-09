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

enum AndroidUpdateInstallResult { installerOpened, permissionRequired }

class AndroidUpdateService {
  static Future<AndroidUpdateInfo?> checkForUpdate() async => null;

  static Future<bool> canInstallPackages() async => false;

  static Future<Object> download(
    AndroidUpdateInfo update, {
    required void Function(double progress) onProgress,
  }) => throw UnsupportedError('仅 Android 支持应用更新');

  static Future<AndroidUpdateInstallResult> verifyAndInstall(
    Object apk,
    AndroidUpdateInfo update,
  ) => throw UnsupportedError('仅 Android 支持应用更新');
}

class AndroidUpdateInfo {
  const AndroidUpdateInfo({
    required this.versionName,
    required this.versionCode,
    required this.minSupportedVersionCode,
    required this.notes,
  });

  final String versionName;
  final int versionCode;
  final int minSupportedVersionCode;
  final List<String> notes;

  bool get isRequired => false;
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

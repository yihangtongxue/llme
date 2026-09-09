# Android 直装更新发布

Android 客户端启动后会读取以下公开配置：

```text
https://api.github.com/repos/yihangtongxue/llme/contents/.release-hub/updates/stable.json?ref=main
```

每次发布版本时：

1. 递增 `pubspec.yaml` 中的版本，例如 `1.0.1+2`。
2. 构建签名后的 `prodRelease` APK，命名为 `llme-v1.0.1.apk`。
3. 计算 APK 的 SHA-256：`shasum -a 256 llme-v1.0.1.apk`。
4. 在 ReleaseHub 中以当前 `llme` GitHub 仓库创建稳定版，版本号使用三段数字（例如 `1.0.6`），并上传 Android APK。
5. ReleaseHub 会创建 Release、上传附件并写入 `.release-hub/updates/stable.json`；不要手工维护更新 JSON。

首个 `1.0.0+1` 正式包是更新基线。要验证更新流程，需要安装它后，再发布版本号更高的 APK，例如 `1.0.1+2`。

`.release-hub/updates/stable.json` 与 Release 附件必须保持匿名可访问；不要向 APK 或清单写入访问令牌。客户端会按 Android ABI 选择 APK（没有精确匹配时仅回退到 `universal`），并校验文件大小和 SHA-256。

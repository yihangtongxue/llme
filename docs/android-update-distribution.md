# Android 直装更新发布

Android 客户端启动后会读取以下公开配置：

```text
https://gitee.com/yihangtongxue/llme-releases/raw/master/updates/android.json
```

每次发布版本时：

1. 递增 `pubspec.yaml` 中的版本，例如 `1.0.1+2`。
2. 构建签名后的 `prodRelease` APK，命名为 `llme-v1.0.1.apk`。
3. 计算 APK 的 SHA-256：`shasum -a 256 llme-v1.0.1.apk`。
4. 在 Gitee `llme-releases` 创建 tag 为 `v1.0.1` 的 Release，并上传 APK 作为附件。
5. 修改并提交 Release 仓库的 `updates/android.json`，填写新版本号、附件下载地址、SHA-256 与更新说明。

首个 `1.0.0+1` 正式包是更新基线。要验证更新流程，需要安装它后，再发布版本号更高的 APK，例如 `1.0.1+2`。

`updates/android.json` 必须保持公开可访问；不要向 APK 或该文件写入 Gitee 访问令牌。

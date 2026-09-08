# 练了么

一个以快速记录训练为核心的 Flutter MVP。启动默认进入「打卡」，底部为日历、打卡、我的三个页面。

## V1 功能

- 打卡：精力可选、内置/自定义计次项目、沿用同项目上次组数与次数、每组单独填写。
- 保存成功后显示今日记录；支持编辑、删除与短时撤销。连点保存不会重复提交。
- 日历：按月查看有记录的日期，点击日期查看及编辑记录。
- 我的：进入训练数据，查看本周训练天数、近四周训练天数与单个项目总次数变化；可查看关于应用。
- 一天多条训练只计一个训练日；今天未打卡时，连续天数可统计至昨天。
- 数据在本机持久化，Android/iOS 使用 Sembast 文件数据库，Web 使用 IndexedDB。
- 不含账号、云同步、跑步、训练推荐和训练计划。默认 3 × 12 仅是可编辑示例，不是训练建议。

## 开发运行

使用项目现有 FVM Flutter 环境：

```sh
fvm flutter pub get
fvm flutter run
```

第一次接入本机存储插件需要完整重启应用，仅热重载无法加载新插件。

```sh
fvm flutter analyze
fvm flutter test
fvm flutter build apk --debug
```

本地 Web 预览：

```sh
fvm flutter run -d web-server --web-port 5367 --web-hostname 127.0.0.1
```

## 代码结构

- `lib/main.dart`：主题、数据库启动与读取失败重试。
- `lib/app/app_home.dart`：导航、页面状态保持、跨天刷新。
- `lib/data/`：记录模型、本地存储与统计口径。
- `lib/features/check_in/`：打卡页及可复用的记录编辑表单。
- `lib/features/calendar/`：日历与当天记录。
- `lib/features/trends/`：按周汇总及项目趋势。
- `lib/features/profile/`：我的页、训练数据入口与关于应用。
- `lib/shared/widgets/`：玻璃导航、卡片、记录列表等共享组件。
- `test/`：持久化、统计边界、错误恢复及打卡交互测试。

## 数据说明

数据仅存于当前设备或浏览器，没有云端备份。卸载应用或清除浏览器站点数据可能移除记录。
记录日期保存为打卡时的本地日期；编辑历史记录保留原日期。
数据库写入成功后才更新内存与显示成功提示；读取失败不会用空数据覆盖已有记录。

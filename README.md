# TIM - Tactile Interaction Module（触觉交互模块）

[![Version](https://img.shields.io/badge/version-0.0.4-blue.svg)](https://github.com/mobius-toy/tim)
[![Flutter](https://img.shields.io/badge/flutter-%5E3.3.0-blue.svg)](https://flutter.dev/)
[![License](https://img.shields.io/badge/license-Dual-blue.svg)](LICENSE)

TIM 是 Tactile Interaction Module（触觉交互模块）的缩写，是一个基于 Flutter 的跨平台智能设备控制框架，专为蓝牙低功耗（BLE）设备设计。TIM 提供了高性能的原生设备控制能力，支持 Android、iOS 和 macOS 平台。

## ✨ 核心特性

- **📱 跨平台**: 支持 Android、iOS、macOS 三大平台
- **🔗 蓝牙集成**: 完整的 BLE 设备扫描、连接和管理功能
- **🎮 实时控制**: 支持实时电机控制和设备状态监控
- **📊 数据流**: 基于 Stream 的实时数据推送和状态同步
- **🛡️ 错误处理**: 完善的异常处理和错误恢复机制
- **🔧 易于集成**: 简洁的 API 设计，快速集成到现有项目

## 🏗️ 项目架构

TIM 是一个完整的 Flutter 插件包，提供智能设备控制的核心功能：

### 核心特性

- **Flutter 插件**: 提供跨平台的设备控制 API
- **原生性能**: 高性能的设备通信和协议解析
- **BLE 集成**: 完整的蓝牙低功耗设备支持
- **实时控制**: 支持设备状态监控和实时控制

## 🚀 快速开始

### 环境要求

#### 开发环境最低版本

| 组件 | 最低版本 | 推荐版本 | 说明 |
|------|----------|----------|------|
| **Flutter SDK** | 3.3.0 | 3.16.0+ | TIM SDK 要求的最低版本 |
| **Dart SDK** | 3.9.2 | 3.2.0+ | 与Flutter版本对应 |
| **Android** | API 24 (7.0) | API 33+ | TIM SDK 实际要求的最低版本 |
| **iOS** | 13.0 | 15.0+ | TIM SDK 实际要求的最低版本 |
| **macOS** | 10.15 | 12.0+ | TIM SDK 实际要求的最低版本 |

#### 平台特定工具链

- **Android**: 
  - Android SDK API 34
  - Android NDK 21+
  - Gradle 7.0+
- **iOS/macOS**: 
  - Xcode 14.0+
  - iOS Deployment Target 13.0+
  - macOS Deployment Target 10.15+

### 蓝牙权限设置

使用 TIM 前需要配置蓝牙权限：

#### Android 权限配置

在 `android/app/src/main/AndroidManifest.xml` 中添加：

```xml
<!-- Tell Google Play Store that your app uses Bluetooth LE
Set android:required="true" if bluetooth is necessary -->
<uses-feature
   android:name="android.hardware.bluetooth_le"
   android:required="true" />
<!-- New Bluetooth permissions in Android 12
https://developer.android.com/about/versions/12/features/bluetooth-permissions -->
<uses-permission
   android:name="android.permission.BLUETOOTH_SCAN"
   android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<!-- legacy for Android 11 or lower -->
<uses-permission
   android:name="android.permission.BLUETOOTH"
   android:maxSdkVersion="30" />
<uses-permission
   android:name="android.permission.BLUETOOTH_ADMIN"
   android:maxSdkVersion="30" />
```

#### iOS 权限配置

在 `ios/Runner/Info.plist` 中添加：

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>此应用需要蓝牙权限来连接和控制TIM设备</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>此应用需要蓝牙权限来连接和控制TIM设备</string>
```

#### macOS 权限配置

在 `macos/Runner/Info.plist` 中添加：

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>此应用需要蓝牙权限来连接和控制TIM设备</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>此应用需要蓝牙权限来连接和控制TIM设备</string>
```

### 安装依赖

在您的 Flutter 项目中添加 TIM 依赖：

```yaml
dependencies:
  tim:
    git:
      url: https://github.com/mobius-toy/tim.git
      ref: v0.0.4
  permission_handler: ^11.3.1  # 用于权限管理
  device_info_plus: ^10.1.0    # 用于检测Android版本

# 确保您的项目支持最低版本要求
environment:
  sdk: '>=3.9.2 <4.0.0'
  flutter: '>=3.3.0'
```

#### 版本兼容性

- **TIM v0.0.4**: 支持 Flutter 3.3.0+ 和 Dart 3.9.2+
- **permission_handler v11.3.1**: 需要 Flutter 3.0.0+ 支持
- **device_info_plus v10.1.0**: 用于检测Android版本，支持所有平台
- **flutter_blue_plus v1.35.5**: TIM内部依赖，自动管理版本
- **flutter_rust_bridge v2.11.1**: TIM内部依赖，自动管理版本

> **⚠️ 许可证提醒**: 如果您计划将 TIM 用于商业项目，请确保获得商业许可证。开源版本仅限个人学习和非商业用途。

### 基础使用

```dart
import 'package:tim/tim.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

// 检查并请求蓝牙权限
Future<bool> requestBluetoothPermissions() async {
  if (Platform.isAndroid) {
    // 检查Android版本
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final isAndroid12OrHigher = androidInfo.version.sdkInt >= 31;
    
    if (isAndroid12OrHigher) {
      // Android 12+ 使用新的蓝牙权限
      final bluetoothScanStatus = await Permission.bluetoothScan.request();
      final bluetoothConnectStatus = await Permission.bluetoothConnect.request();
      return bluetoothScanStatus == PermissionStatus.granted && 
             bluetoothConnectStatus == PermissionStatus.granted;
    } else {
      // Android 11 及以下需要位置权限来扫描蓝牙设备
      final locationStatus = await Permission.locationWhenInUse.request();
      if (locationStatus != PermissionStatus.granted) {
        return false;
      }
      
      final bluetoothStatus = await Permission.bluetooth.request();
      return bluetoothStatus == PermissionStatus.granted;
    }
  } else if (Platform.isIOS) {
    // iOS 使用蓝牙权限
    final bluetoothStatus = await Permission.bluetooth.request();
    return bluetoothStatus == PermissionStatus.granted;
  }
  
  return false;
}

// 使用 TIM
Future<void> useTim() async {
  // 1. 请求权限
  final hasPermission = await requestBluetoothPermissions();
  if (!hasPermission) {
    print('蓝牙权限被拒绝');
    return;
  }
  
  // 2. 初始化 TIM 服务
  await Tim.instance.initialize();
  
  // 3. 扫描设备
  final devices = await Tim.instance.startScan(
    timeout: Duration(seconds: 10),
    onFoundDevices: (devices) {
      print('发现 ${devices.length} 个设备');
      return true; // 返回 true 停止扫描
    },
  );
  
  if (devices.isEmpty) {
    print('未发现设备');
    return;
  }
  
  // 4. 连接设备
  final device = devices.first;
  await device.connect();
  
  // 5. 控制电机
  await device.writeMotor([50]); // PWM 值
  await device.writeMotorStop();
  
  // 6. 监听设备状态
  device.connection.listen((isConnected) {
    print('设备连接状态: $isConnected');
  });
  
  device.battery.listen((batteryLevel) {
    print('电池电量: $batteryLevel%');
  });
  
  // 7. 断开连接
  await device.disconnect();
}
```

## 📖 API 文档

### Tim 主类

```dart
class Tim {
  static Tim get instance;           // 单例实例
  
  Future<void> initialize();         // 初始化服务
  Future<List<TimDevice>> startScan({ // 开始扫描
    Duration timeout,
    List<String> withNames,
    OnScanCallback? onFoundDevices,
  });
  Future<void> stopScan();           // 停止扫描
}
```

### TimDevice 设备类

```dart
abstract class TimDevice {
  String get id;                     // 设备 ID
  String get name;                   // 设备名称
  String get mac;                    // MAC 地址
  String get fv;                     // 固件版本
  String get pid;                    // 产品 ID
  
  bool get isConnected;              // 连接状态
  Stream<bool> get connection;       // 连接状态流
  Stream<int> get rssi;              // 信号强度流
  Stream<int> get battery;           // 电池电量流
  
  Future<void> connect({             // 连接设备
    Duration timeout,
  });
  Future<void> disconnect();         // 断开连接
  Future<void> writeMotor(List<int> pwmValues); // 电机控制
  Future<void> writeMotorStop();     // 停止电机
}
```

### 错误处理

```dart
enum TimError {
  bluetoothUnavailable,     // 蓝牙不可用
  bluetoothStateOff,        // 蓝牙已关闭
  connectionTimeout,        // 连接超时
  peripheralNotFound,       // 设备未找到
  // ... 更多错误类型
}

class TimException implements Exception {
  final String message;
  final TimError? error;
  final Object? original;
}
```

## 🔧 开发指南

### 版本检查

在开发前，请确保您的环境满足最低版本要求：

```bash
# 检查 Flutter 版本
flutter --version

# 检查 Dart 版本
dart --version

# 检查 Android SDK 版本
flutter doctor -v
```

### 构建项目

```bash
flutter pub get
flutter build
```

### 平台特定配置

#### Android

TIM插件要求最低Android版本为API 24 (Android 7.0)。在您的应用 `android/app/build.gradle` 中设置：

```gradle
android {
    compileSdkVersion 34
    defaultConfig {
        minSdkVersion 24
    }
}
```

#### iOS

在 `ios/Podfile` 中设置最低版本：

```ruby
platform :ios, '13.0'  # TIM SDK 实际要求的最低版本
```

#### macOS

在 `macos/Podfile` 中设置最低版本：

```ruby
platform :osx, '10.15'  # TIM SDK 实际要求的最低版本
```

## 📄 许可证

TIM 采用**双许可证模式**，为不同使用场景提供灵活的许可选择：

### 🔓 开源许可证 (MIT)
- **适用场景**: 个人学习、教育用途、非商业项目
- **权限**: 自由使用、修改、分发
- **限制**: 仅限非商业用途
- **获取方式**: 直接从 GitHub 下载

### 💼 商业许可证
- **适用场景**: 商业应用、企业部署、盈利项目
- **权益**: 
  - 商业使用授权
  - 专业技术支持
  - 优先更新服务
  - 定制开发服务
  - 企业级功能
- **获取方式**: 联系 [licensing@mobiustoy.com](mailto:licensing@mobiustoy.com)

### ⚠️ 使用限制
以下用途需要商业许可证：
- 商业应用程序
- 盈利性软件
- 企业级部署
- OEM 集成
- 有偿分发或转售

### 📞 许可证咨询
- **商业许可证**: [licensing@mobiustoy.com](mailto:licensing@mobiustoy.com)
- **许可证信息**: [https://mobiustoy.com/licensing](https://mobiustoy.com/licensing)
- **详细条款**: 查看 [LICENSE](LICENSE) 文件

## 🔗 相关链接

- [Flutter Blue Plus 插件](https://pub.dev/packages/flutter_blue_plus)
- [Flutter 插件开发指南](https://docs.flutter.dev/packages-and-plugins/plugin)

## 📞 支持

如果您遇到问题或有功能建议，请：

- 提交 [Issue](https://github.com/mobius-toy/tim/issues)
- 查看 [Wiki](https://github.com/mobius-toy/tim/wiki) 获取更多文档
- 加入我们的社区讨论

---

**TIM（Tactile Interaction Module，触觉交互模块）** - 让智能设备控制变得简单而强大 🚀
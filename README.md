# TIM SDK

[![pub package](https://img.shields.io/pub/v/tim.svg)](https://pub.dev/packages/tim)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

一个 Flutter 插件，提供蓝牙低功耗 (BLE) 功能，用于连接和控制玩具设备。

## 📦 安装

在你的 `pubspec.yaml` 文件中添加依赖：

```yaml
dependencies:
  tim:
    git:
      url: https://github.com/heymarcusday/tim_sdk.git
```

然后运行：

```bash
flutter pub get
```

## ⚙️ 配置

### iOS 配置

#### 1. 设置部署目标
在 `ios/Runner.xcodeproj` 中设置：
- **iOS Deployment Target**: 12.0
- **Swift Language Version**: Swift 5

#### 2. 添加权限
在你的 `ios/Runner/Info.plist` 文件中添加以下权限：

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>此应用使用蓝牙连接 XXX 设备，用于控制电机和读取电池电量。</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>此应用使用蓝牙连接 XXX 设备，用于控制电机和读取电池电量。</string>
```

### Android 配置

#### 1. 设置编译版本
在 `android/app/build.gradle` 中设置：
```gradle
android {
    compileSdkVersion 34
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}
```

#### 2. 添加权限
在你的 `android/app/src/main/AndroidManifest.xml` 文件中添加以下权限：

```xml
<!-- Tell Google Play Store that your app uses Bluetooth LE
     Set android:required="true" if bluetooth is necessary -->
<uses-feature android:name="android.hardware.bluetooth_le" android:required="false" />

<!-- New Bluetooth permissions in Android 12
https://developer.android.com/about/versions/12/features/bluetooth-permissions -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />

<!-- legacy for Android 11 or lower -->
<uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" android:maxSdkVersion="30"/>

<!-- legacy for Android 9 or lower -->
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" android:maxSdkVersion="28" />
```

## 📦 依赖集成

TIM SDK 通过 JitPack 自动集成 OpenToy Android Library，无需手动配置。

### 自动集成（推荐）
TIM SDK 默认使用 JitPack 自动获取 OpenToy Android Library 依赖，无需任何额外配置。

### 手动集成（可选）
如果需要使用特定版本的 OpenToy Android Library，请在 `android/build.gradle` 中修改依赖版本：

```gradle
dependencies {
    implementation 'com.github.mobius-toy:opentoy_android:1.0.0'  // 修改为所需版本
}
```

## 🚀 快速开始

### 基本用法

```dart
import 'package:tim/tim.dart';

// 获取 TIM 实例
final tim = Tim.instance;

// 初始化 TIM 蓝牙 SDK，必须在调用其他蓝牙相关方法前执行此操作。
// 该方法会完成蓝牙适配器的初始化、权限检查等准备工作。
// 建议在应用启动时或首次需要使用蓝牙功能时调用。
await tim.initialize();

// 开始扫描设备（注意：扫描是高功耗操作，建议在发现目标设备后及时调用 stopScan() 停止扫描，避免长时间或频繁扫描）
await tim.startScan();
// 发现可连接的设备后及时停止扫描
await tim.stopScan();

// 监听设备发现事件
tim.deviceDiscovered.listen((device) {
  print('发现设备: ${device.name} (${device.deviceId})');
  print('信号强度: ${device.rssi} dBm');
});

// 连接设备
await tim.connect(deviceId);

// 监听连接状态
tim.deviceConnected.listen((device) {
  print('设备已连接: ${device.name}');
});

tim.deviceDisconnected.listen((device) {
  print('设备已断开: ${device.name}');
});

// 读取电池电量
int? batteryLevel = await tim.readBatteryLevel(deviceId);

// 控制电机（PWM 值范围: 0 到 100）
// 数组的元素个数代表马达或工作单元的数量，例如 [80, 20] 表示有两个马达分别设置为 80 和 20
await tim.writeMotor(deviceId, [80, 20]);

// 断开设备连接
await tim.disconnect(deviceId);

// 监听蓝牙状态变化
tim.state.listen((state) {
  switch (state) {
    case TimState.poweredOn:
      print('蓝牙已开启');
      break;
    case TimState.poweredOff:
      print('蓝牙已关闭');
      break;
    case TimState.unauthorized:
      print('蓝牙权限被拒绝');
      break;
    case TimState.unsupported:
      print('设备不支持蓝牙');
      break;
    case TimState.resetting:
      print('蓝牙重置中');
      break;
    case TimState.unknown:
      print('蓝牙状态未知');
      break;
  }
});

// 获取设备详细信息
tim.deviceConnected.listen((device) {
  final info = device.deviceInfo;
  print('设备详细信息:');
  print('  MAC地址: ${info.mac ?? "未知"}');
  print('  硬件代码: ${info.hardwareCode ?? "未知"}');
  print('  固件版本: ${info.firmwareVersion ?? "未知"}');
  print('  序列号: ${info.serialNumber ?? "未知"}');
  print('  电池电量: ${info.battery ?? 0}%');
});

// 检查设备连接状态
final device = await tim.connect(deviceId);
if (device.isConnected) {
  print('设备连接成功');
} else {
  print('设备连接失败');
}
```

## 📱 示例应用

项目包含一个完整的示例应用，展示了所有功能的使用方法：

```bash
cd example
flutter run
```

## 🔧 API 参考

### 主要方法

| 方法 | 描述 | 参数 | 返回值 |
|------|------|------|--------|
| `initialize()` | 初始化蓝牙 | 无 | `Future<void>` |
| `startScan()` | 开始扫描设备 | 无 | `Future<void>` |
| `stopScan()` | 停止扫描设备 | 无 | `Future<void>` |
| `connect(deviceId)` | 连接指定设备 | `String deviceId` | `Future<TimDevice>` |
| `disconnect(deviceId)` | 断开设备连接 | `String deviceId` | `Future<void>` |
| `readBatteryLevel(deviceId)` | 读取电池电量 | `String deviceId` | `Future<int?>` |
| `writeMotor(deviceId, pwm)` | 控制电机 | `String deviceId, List<int> pwm` | `Future<void>` |

### 事件流

| 流 | 描述 | 数据类型 |
|----|------|----------|
| `state` | 蓝牙状态变化 | `TimState` |
| `deviceDiscovered` | 设备发现 | `TimDevice` |
| `deviceConnected` | 设备连接 | `TimDevice` |
| `deviceDisconnected` | 设备断开 | `TimDevice` |

## 🐛 故障排除

### 常见问题

1. **蓝牙权限被拒绝**
   - 确保在设备设置中授予了蓝牙权限
   - 检查 Info.plist 和 AndroidManifest.xml 中的权限配置

2. **设备扫描不到**
   - 确保设备处于可发现模式
   - 检查蓝牙是否已开启

3. **连接失败**
   - 确保设备在范围内
   - 检查设备是否已被其他应用连接
   - 尝试重启蓝牙


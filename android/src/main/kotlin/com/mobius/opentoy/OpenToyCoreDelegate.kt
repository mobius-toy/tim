package com.mobius.opentoy

/**
 * OpenToy Core Delegate Protocol
 * 与 iOS 版本的 OpenToyCoreDelegate 保持一致
 */
interface OpenToyCoreDelegate {
    fun bluetoothStateChanged(state: String)
    fun deviceDiscovered(device: Map<String, Any>)
    
    // 设备连接相关
    fun deviceConnected(deviceId: String, deviceInfo: Map<String, Any>)
    fun deviceDisconnected(deviceId: String, error: String?)
    fun deviceConnectionFailed(deviceId: String, error: String?)
    
    // 特征值操作相关
    fun characteristicValueUpdated(deviceId: String, characteristicId: String, data: List<UInt>)
    fun characteristicReadFailed(deviceId: String, characteristicId: String, error: String)
    fun characteristicWriteSuccess(deviceId: String, characteristicId: String)
    fun characteristicWriteFailed(deviceId: String, characteristicId: String, error: String)
    
    // 服务发现相关
    fun servicesDiscoveryFailed(deviceId: String, error: String)
    fun characteristicsDiscoveryFailed(deviceId: String, serviceId: String, error: String)
}

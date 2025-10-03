package com.mobius.opentoy

import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattService
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

/**
 * Device Discovery State
 * 管理设备发现和连接状态
 */
class DeviceDiscoveryState(val deviceId: String) {
    val queue: ExecutorService = Executors.newSingleThreadExecutor()
    val mutex = Mutex()
    
    // 服务发现状态
    var servicesDiscovered = false
    var services: List<BluetoothGattService> = emptyList()
    
    // 特征值发现状态
    val characteristicsDiscovered = ConcurrentHashMap<String, Boolean>()
    val characteristics = ConcurrentHashMap<String, BluetoothGattCharacteristic>()
    
    // 待处理的读取操作
    val pendingReads = ConcurrentHashMap<String, (OpenToyResult) -> Unit>()
    
    // 待处理的写入操作
    val pendingWrites = ConcurrentHashMap<String, (OpenToyResult) -> Unit>()
    
    fun cleanup() {
        queue.shutdown()
        pendingReads.clear()
        pendingWrites.clear()
        characteristicsDiscovered.clear()
        characteristics.clear()
    }
}

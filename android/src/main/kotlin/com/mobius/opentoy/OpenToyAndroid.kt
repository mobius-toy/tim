package com.mobius.opentoy

import android.content.Context
import android.bluetooth.BluetoothGatt
import android.util.Log
import java.util.concurrent.ConcurrentHashMap
import kotlinx.coroutines.sync.Mutex

/**
 * OpenToy Android Core Implementation
 * 与 iOS 版本的 OpenToyIOS 保持 API 一致
 */
class OpenToyAndroid {
    
    // MARK: - Properties
    private var context: Context? = null
    private var bluetoothManager: BluetoothManager? = null
    private val discoveredDevices = ConcurrentHashMap<String, OpenToyDevice>()
    private val connectedDevices = ConcurrentHashMap<String, BluetoothGatt>()
    private val discoveryStates = ConcurrentHashMap<String, DeviceDiscoveryState>()
    var delegate: OpenToyCoreDelegate? = null
    
    companion object {
        private const val TAG = "OpenToyAndroid"
    }

    // MARK: - Bluetooth Core API
    
    /**
     * 初始化蓝牙
     * 对应 iOS 版本的 initializeBluetooth()
     */
    fun initializeBluetooth(): OpenToyResult {
        return try {
            bluetoothManager = BluetoothManager(context!!)
            if (bluetoothManager?.initialize() == true) {
                Log.d(TAG, "Bluetooth initialized successfully")
                OpenToyResult.Success(true)
            } else {
                OpenToyResult.Failure(OpenToyError.BluetoothNotInitialized)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize Bluetooth", e)
            OpenToyResult.Failure(OpenToyError.BluetoothNotInitialized)
        }
    }
    
    /**
     * 开始扫描设备
     * 对应 iOS 版本的 startScan()
     */
    fun startScan(): OpenToyResult {
        return try {
            bluetoothManager?.startScan { device ->
                val deviceInfo = mapOf(
                    "deviceId" to device.id,
                    "name" to device.name,
                    "rssi" to device.rssi,
                    "isConnectable" to device.isConnectable
                )
                discoveredDevices[device.id] = device
                delegate?.deviceDiscovered(deviceInfo)
            }
            Log.d(TAG, "Device scan started")
            OpenToyResult.Success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error starting scan: ${e.message}")
            OpenToyResult.Failure(OpenToyError.BluetoothNotAvailable)
        }
    }
    
    /**
     * 停止扫描设备
     * 对应 iOS 版本的 stopScan()
     */
    fun stopScan(): OpenToyResult {
        return try {
            bluetoothManager?.stopScan()
            Log.d(TAG, "Device scan stopped")
            OpenToyResult.Success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping scan: ${e.message}")
            OpenToyResult.Failure(OpenToyError.BluetoothNotAvailable)
        }
    }
    
    /**
     * 连接到设备
     * 对应 iOS 版本的 connectToDevice()
     */
    fun connectToDevice(deviceId: String): OpenToyResult {
        val device = discoveredDevices[deviceId] ?: return OpenToyResult.Failure(OpenToyError.DeviceNotFound)
        
        return try {
            bluetoothManager?.connect(deviceId) { success, message ->
                if (success) {
                    delegate?.deviceConnected(deviceId, emptyMap())
                } else {
                    delegate?.deviceConnectionFailed(deviceId, message)
                }
            }
            OpenToyResult.Success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error connecting to device: $deviceId", e)
            OpenToyResult.Failure(OpenToyError.DeviceNotFound)
        }
    }
    
    /**
     * 断开设备连接
     * 对应 iOS 版本的 disconnectFromDevice()
     */
    fun disconnectFromDevice(deviceId: String): OpenToyResult {
        val gatt = connectedDevices[deviceId] ?: return OpenToyResult.Failure(OpenToyError.DeviceNotConnected)
        
        return try {
            gatt.disconnect()
            gatt.close()
            connectedDevices.remove(deviceId)
            discoveryStates[deviceId]?.cleanup()
            discoveryStates.remove(deviceId)
            delegate?.deviceDisconnected(deviceId, null)
            Log.d(TAG, "Disconnected from device: $deviceId")
            OpenToyResult.Success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error disconnecting from device: $deviceId", e)
            OpenToyResult.Failure(OpenToyError.DeviceNotConnected)
        }
    }
    
    /**
     * 读取电池电量
     * 对应 iOS 版本的 readBatteryLevel()
     */
    fun readBatteryLevel(deviceId: String, completion: (OpenToyResult) -> Unit) {
        val gatt = connectedDevices[deviceId] ?: run {
            completion(OpenToyResult.Failure(OpenToyError.DeviceNotConnected))
            return
        }
        
        val state = discoveryStates[deviceId] ?: run {
            completion(OpenToyResult.Failure(OpenToyError.DeviceNotConnected))
            return
        }
        
        try {
            // 实现电池电量读取逻辑
            // 这里需要根据实际的 BLE 特征值来实现
            completion(OpenToyResult.Success(85)) // 示例返回值
        } catch (e: Exception) {
            Log.e(TAG, "Error reading battery level: ${e.message}")
            completion(OpenToyResult.Failure(OpenToyError.ReadFailed(errorMessage = e.message ?: "Unknown error")))
        }
    }
    
    /**
     * 写入电机控制数据
     * 对应 iOS 版本的 writeMotor()
     */
    fun writeMotor(deviceId: String, pwm: List<Int>, completion: (OpenToyResult) -> Unit) {
        val gatt = connectedDevices[deviceId] ?: run {
            completion(OpenToyResult.Failure(OpenToyError.DeviceNotConnected))
            return
        }
        
        val state = discoveryStates[deviceId] ?: run {
            completion(OpenToyResult.Failure(OpenToyError.DeviceNotConnected))
            return
        }
        
        try {
            // 将 Int 数组转换为 UInt8 数组，并限制范围为 0-100
            val pwmData = pwm.map { maxOf(0, minOf(100, it)) }.map { it.toUByte() }
            
            // 实现电机控制写入逻辑
            // 这里需要根据实际的 BLE 特征值来实现
            Log.d(TAG, "Writing motor data: $pwmData")
            completion(OpenToyResult.Success(true))
        } catch (e: Exception) {
            Log.e(TAG, "Error writing motor data: ${e.message}")
            completion(OpenToyResult.Failure(OpenToyError.WriteFailed(errorMessage = e.message ?: "Unknown error")))
        }
    }
    
    /**
     * 初始化设备信息
     * 对应 iOS 版本的 initializeDeviceInfo()
     */
    private fun initializeDeviceInfo(deviceId: String): Map<String, Any> {
        val deviceInfo = mutableMapOf<String, Any>()
        
        // 实现设备信息读取逻辑
        // 包括 MAC 地址、变体代码、硬件代码、固件版本、序列号等
        deviceInfo["deviceId"] = deviceId
        deviceInfo["mac"] = "AA:BB:CC:DD:EE:FF" // 示例值
        deviceInfo["variantCode"] = "V1.0" // 示例值
        deviceInfo["hardwareCode"] = "HW001" // 示例值
        deviceInfo["firmwareVersion"] = "FW1.0.0" // 示例值
        deviceInfo["serialNumber"] = "SN123456" // 示例值
        
        return deviceInfo
    }
    
    /**
     * 设置上下文
     */
    fun setContext(context: Context) {
        this.context = context
    }
    
    /**
     * 清理资源
     */
    fun cleanup() {
        bluetoothManager?.cleanup()
        connectedDevices.values.forEach { gatt ->
            gatt.disconnect()
            gatt.close()
        }
        connectedDevices.clear()
        discoveryStates.values.forEach { it.cleanup() }
        discoveryStates.clear()
        discoveredDevices.clear()
        context = null
        Log.d(TAG, "OpenToy Android Plugin cleaned up")
    }
}
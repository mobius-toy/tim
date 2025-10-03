package com.mobius.opentoy

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattService
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.bluetooth.le.BluetoothLeScanner
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.content.Context
import android.util.Log

/**
 * Bluetooth Manager for handling BLE operations
 */
class BluetoothManager(private val context: Context) {
    
    private var bluetoothAdapter: BluetoothAdapter? = null
    private var bluetoothLeScanner: BluetoothLeScanner? = null
    private var isScanning = false
    private var scanCallback: ScanCallback? = null
    
    companion object {
        private const val TAG = "BluetoothManager"
    }

    fun initialize(): Boolean {
        return try {
            val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
            bluetoothAdapter = bluetoothManager.adapter
            
            if (bluetoothAdapter == null) {
                Log.e(TAG, "Bluetooth adapter is null")
                return false
            }
            
            if (!bluetoothAdapter!!.isEnabled) {
                Log.e(TAG, "Bluetooth is not enabled")
                return false
            }
            
            bluetoothLeScanner = bluetoothAdapter!!.bluetoothLeScanner
            Log.d(TAG, "Bluetooth manager initialized successfully")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize Bluetooth manager", e)
            false
        }
    }

    fun startScan(onDeviceFound: (OpenToyDevice) -> Unit) {
        if (isScanning) {
            Log.w(TAG, "Scan is already running")
            return
        }

        scanCallback = object : ScanCallback() {
            override fun onScanResult(callbackType: Int, result: ScanResult) {
                val device = result.device
                val openToyDevice = OpenToyDevice(
                    id = device.address,
                    name = device.name ?: "Unknown Device",
                    rssi = result.rssi,
                    isConnectable = result.isConnectable
                )
                onDeviceFound(openToyDevice)
            }

            override fun onScanFailed(errorCode: Int) {
                Log.e(TAG, "Scan failed with error code: $errorCode")
                isScanning = false
            }
        }

        try {
            bluetoothLeScanner?.startScan(scanCallback)
            isScanning = true
            Log.d(TAG, "BLE scan started")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start scan", e)
        }
    }

    fun stopScan() {
        if (!isScanning) {
            return
        }

        try {
            bluetoothLeScanner?.stopScan(scanCallback)
            isScanning = false
            Log.d(TAG, "BLE scan stopped")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to stop scan", e)
        }
    }

    fun getBluetoothDevice(deviceId: String): BluetoothDevice? {
        return bluetoothAdapter?.getRemoteDevice(deviceId)
    }
    
    fun connect(deviceId: String, callback: (Boolean, String) -> Unit) {
        val device = getBluetoothDevice(deviceId)
        if (device == null) {
            callback(false, "Device not found")
            return
        }
        
        val gattCallback = object : BluetoothGattCallback() {
            override fun onConnectionStateChange(gatt: BluetoothGatt?, status: Int, newState: Int) {
                when (newState) {
                    BluetoothProfile.STATE_CONNECTED -> {
                        Log.d(TAG, "Connected to device: $deviceId")
                        gatt?.discoverServices()
                        callback(true, "Connected successfully")
                    }
                    BluetoothProfile.STATE_DISCONNECTED -> {
                        Log.d(TAG, "Disconnected from device: $deviceId")
                        callback(false, "Disconnected")
                    }
                }
            }
            
            override fun onServicesDiscovered(gatt: BluetoothGatt?, status: Int) {
                if (status == BluetoothGatt.GATT_SUCCESS) {
                    Log.d(TAG, "Services discovered for device: $deviceId")
                } else {
                    Log.e(TAG, "Service discovery failed for device: $deviceId")
                }
            }
        }
        
        try {
            device.connectGatt(context, false, gattCallback)
        } catch (e: Exception) {
            Log.e(TAG, "Error connecting to device: $deviceId", e)
            callback(false, "Connection error: ${e.message}")
        }
    }

    fun cleanup() {
        stopScan()
        bluetoothAdapter = null
        bluetoothLeScanner = null
        scanCallback = null
    }
}

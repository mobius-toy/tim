package com.mobius.tim

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import com.mobius.opentoy.OpenToyAndroid
import com.mobius.opentoy.OpenToyCoreDelegate
import com.mobius.opentoy.OpenToyResult
import com.mobius.opentoy.OpenToyError

/** TimSdkPlugin */
class TimSdkPlugin :
    FlutterPlugin,
    MethodCallHandler,
    EventChannel.StreamHandler,
    OpenToyCoreDelegate {
    
    // The MethodChannel that will the communication between Flutter and native Android
    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    
    // OpenToy Android Plugin
    private val openToyAndroid = OpenToyAndroid()

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "tim")
        channel.setMethodCallHandler(this)
        
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "tim/events")
        eventChannel.setStreamHandler(this)
        
        // 设置 OpenToy Android 的代理
        openToyAndroid.delegate = this
        
        // 设置上下文
        val context = flutterPluginBinding.applicationContext
        openToyAndroid.setContext(context)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            // 蓝牙相关方法
            "initializeBluetooth" -> {
                val bluetoothResult = openToyAndroid.initializeBluetooth()
                handleOpenToyResult(bluetoothResult, result)
            }
            "startScan" -> {
                val scanResult = openToyAndroid.startScan()
                handleOpenToyResult(scanResult, result)
            }
            "stopScan" -> {
                val stopResult = openToyAndroid.stopScan()
                handleOpenToyResult(stopResult, result)
            }
            "connectToDevice" -> {
                val args = call.arguments as? Map<String, Any>
                val deviceId = args?.get("deviceId") as? String
                if (deviceId != null) {
                    val connectResult = openToyAndroid.connectToDevice(deviceId)
                    handleOpenToyResult(connectResult, result)
                } else {
                    result.error("INVALID_ARGUMENTS", "deviceId is required", null)
                }
            }
            "disconnectFromDevice" -> {
                val args = call.arguments as? Map<String, Any>
                val deviceId = args?.get("deviceId") as? String
                if (deviceId != null) {
                    val disconnectResult = openToyAndroid.disconnectFromDevice(deviceId)
                    handleOpenToyResult(disconnectResult, result)
                } else {
                    result.error("INVALID_ARGUMENTS", "deviceId is required", null)
                }
            }
            "readBatteryLevel" -> {
                val args = call.arguments as? Map<String, Any>
                val deviceId = args?.get("deviceId") as? String
                if (deviceId != null) {
                    openToyAndroid.readBatteryLevel(deviceId) { batteryResult ->
                        handleOpenToyResult(batteryResult, result)
                    }
                } else {
                    result.error("INVALID_ARGUMENTS", "deviceId is required", null)
                }
            }
            "writeMotor" -> {
                val args = call.arguments as? Map<String, Any>
                val deviceId = args?.get("deviceId") as? String
                val pwm = args?.get("pwm") as? List<Int>
                if (deviceId != null && pwm != null) {
                    openToyAndroid.writeMotor(deviceId, pwm) { motorResult ->
                        handleOpenToyResult(motorResult, result)
                    }
                } else {
                    result.error("INVALID_ARGUMENTS", "deviceId and pwm are required", null)
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun handleOpenToyResult(openToyResult: OpenToyResult, result: Result) {
        when (openToyResult) {
            is OpenToyResult.Success -> result.success(openToyResult.value)
            is OpenToyResult.Failure -> result.error("BLUETOOTH_ERROR", openToyResult.error.message, null)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        openToyAndroid.cleanup()
    }

    // EventChannel.StreamHandler implementation
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    // OpenToyCoreDelegate implementation
    override fun bluetoothStateChanged(state: String) {
        eventSink?.success(mapOf("type" to "bluetoothStateChanged", "state" to state))
    }

    override fun deviceDiscovered(device: Map<String, Any>) {
        eventSink?.success(mapOf("type" to "deviceDiscovered", "device" to device))
    }

    override fun deviceConnected(deviceId: String, deviceInfo: Map<String, Any>) {
        eventSink?.success(mapOf("type" to "deviceConnected", "deviceId" to deviceId, "deviceInfo" to deviceInfo))
    }

    override fun deviceDisconnected(deviceId: String, error: String?) {
        eventSink?.success(mapOf("type" to "deviceDisconnected", "deviceId" to deviceId, "error" to error))
    }

    override fun deviceConnectionFailed(deviceId: String, error: String?) {
        eventSink?.success(mapOf("type" to "deviceConnectionFailed", "deviceId" to deviceId, "error" to error))
    }

    override fun characteristicValueUpdated(deviceId: String, characteristicId: String, data: List<UInt>) {
        eventSink?.success(mapOf("type" to "characteristicValueUpdated", "deviceId" to deviceId, "characteristicId" to characteristicId, "data" to data))
    }

    override fun characteristicReadFailed(deviceId: String, characteristicId: String, error: String) {
        eventSink?.success(mapOf("type" to "characteristicReadFailed", "deviceId" to deviceId, "characteristicId" to characteristicId, "error" to error))
    }

    override fun characteristicWriteSuccess(deviceId: String, characteristicId: String) {
        eventSink?.success(mapOf("type" to "characteristicWriteSuccess", "deviceId" to deviceId, "characteristicId" to characteristicId))
    }

    override fun characteristicWriteFailed(deviceId: String, characteristicId: String, error: String) {
        eventSink?.success(mapOf("type" to "characteristicWriteFailed", "deviceId" to deviceId, "characteristicId" to characteristicId, "error" to error))
    }

    override fun servicesDiscoveryFailed(deviceId: String, error: String) {
        eventSink?.success(mapOf("type" to "servicesDiscoveryFailed", "deviceId" to deviceId, "error" to error))
    }

    override fun characteristicsDiscoveryFailed(deviceId: String, serviceId: String, error: String) {
        eventSink?.success(mapOf("type" to "characteristicsDiscoveryFailed", "deviceId" to deviceId, "serviceId" to serviceId, "error" to error))
    }
}

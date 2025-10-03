package com.mobius.opentoy

/**
 * OpenToy Core Result Types
 * 与 iOS 版本的 OpenToyResult 保持一致
 */
sealed class OpenToyResult {
    data class Success(val value: Any) : OpenToyResult()
    data class Failure(val error: OpenToyError) : OpenToyResult()
}

/**
 * OpenToy Error Types
 * 与 iOS 版本的 OpenToyError 保持一致
 */
sealed class OpenToyError : Exception() {
    object BluetoothNotInitialized : OpenToyError()
    object BluetoothNotAvailable : OpenToyError()
    object DeviceNotFound : OpenToyError()
    object DeviceNotConnected : OpenToyError()
    object EmptyData : OpenToyError()
    data class ReadFailed(val errorMessage: String) : OpenToyError()
    data class WriteFailed(val errorMessage: String) : OpenToyError()
    data class InvalidArguments(val errorMessage: String) : OpenToyError()
    
    override val message: String
        get() = when (this) {
            is BluetoothNotInitialized -> "Bluetooth not initialized"
            is BluetoothNotAvailable -> "Bluetooth not available"
            is DeviceNotFound -> "Device not found"
            is DeviceNotConnected -> "Device not connected"
            is EmptyData -> "Data is empty"
            is ReadFailed -> "Read failed: $errorMessage"
            is WriteFailed -> "Write failed: $errorMessage"
            is InvalidArguments -> "Invalid arguments: $errorMessage"
        }
}

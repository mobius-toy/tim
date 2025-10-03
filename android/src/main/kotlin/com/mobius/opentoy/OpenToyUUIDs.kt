package com.mobius.opentoy

import java.util.UUID

/**
 * OpenToy BLE Service and Characteristic UUIDs
 * 与 iOS 版本保持一致的 UUID 定义
 */
object OpenToyUUIDs {
    // Service UUIDs
    val serviceInfoUUID = UUID.fromString("0000180A-0000-1000-8000-00805F9B34FB")
    val serviceBatteryUUID = UUID.fromString("0000180F-0000-1000-8000-00805F9B34FB")
    val serviceMotorUUID = UUID.fromString("0000180D-0000-1000-8000-00805F9B34FB")
    
    // Characteristic UUIDs for Info Service
    val characteristicMacUUID = UUID.fromString("00002A00-0000-1000-8000-00805F9B34FB")
    val characteristicVariantUUID = UUID.fromString("00002A01-0000-1000-8000-00805F9B34FB")
    val characteristicHardwareUUID = UUID.fromString("00002A02-0000-1000-8000-00805F9B34FB")
    val characteristicFirmwareUUID = UUID.fromString("00002A03-0000-1000-8000-00805F9B34FB")
    val characteristicSerialUUID = UUID.fromString("00002A04-0000-1000-8000-00805F9B34FB")
    
    // Characteristic UUIDs for Battery Service
    val characteristicBatteryUUID = UUID.fromString("00002A19-0000-1000-8000-00805F9B34FB")
    
    // Characteristic UUIDs for Motor Service
    val characteristicMotorUUID = UUID.fromString("00002A05-0000-1000-8000-00805F9B34FB")
    val characteristicDualMotorUUID = UUID.fromString("00002A06-0000-1000-8000-00805F9B34FB")
    val characteristicMultiMotorUUID = UUID.fromString("00002A07-0000-1000-8000-00805F9B34FB")
}

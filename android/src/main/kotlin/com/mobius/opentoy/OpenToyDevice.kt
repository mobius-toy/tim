package com.mobius.opentoy

/**
 * Data class representing an OpenToy device
 */
data class OpenToyDevice(
    val id: String,
    val name: String,
    val rssi: Int,
    val isConnectable: Boolean
)

package com.airplay.padcast.receiver

import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress
import java.net.MulticastSocket
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.TimeUnit

class MdnsPlugin : FlutterPlugin, MethodCallHandler {
    companion object {
        private const val CHANNEL = "com.airplay.padcast.receiver/mdns"
        private const val TAG = "MdnsPlugin"
        private const val MDNS_ADDRESS = "224.0.0.251"
        private const val MDNS_PORT = 5353
    }

    private lateinit var channel: MethodChannel
    private var multicastSocket: MulticastSocket? = null
    private var mdnsAddress: InetAddress? = null
    private var scheduler: ScheduledExecutorService? = null
    private var isAdvertising = false

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "startAdvertising" -> {
                val serviceName = call.argument<String>("serviceName") ?: ""
                val port = call.argument<Int>("port") ?: 7000
                val txtRecords = call.argument<Map<String, String>>("txtRecords") ?: emptyMap()
                val localIP = call.argument<String>("localIP") ?: ""
                startAdvertising(serviceName, port, txtRecords, localIP, result)
            }
            "stopAdvertising" -> {
                stopAdvertising(result)
            }
            "sendRecord" -> {
                val data = call.argument<ByteArray>("data")
                if (data != null) {
                    sendMdnsRecord(data, result)
                } else {
                    result.error("INVALID_ARGUMENT", "Data is null", null)
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun startAdvertising(
        serviceName: String,
        port: Int,
        txtRecords: Map<String, String>,
        localIP: String,
        result: Result
    ) {
        try {
            if (isAdvertising) {
                result.success(true)
                return
            }

            // 初始化多播套接字
            multicastSocket = MulticastSocket().apply {
                reuseAddress = true
                timeToLive = 255
            }
            
            mdnsAddress = InetAddress.getByName(MDNS_ADDRESS)
            
            // 开始定期广播
            scheduler = Executors.newSingleThreadScheduledExecutor()
            scheduler?.scheduleWithFixedDelay({
                advertiseService(serviceName, port, txtRecords, localIP)
            }, 0, 30, TimeUnit.SECONDS)

            isAdvertising = true
            result.success(true)
            Log.d(TAG, "mDNS advertising started for $serviceName")
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start mDNS advertising", e)
            result.error("START_ERROR", "Failed to start: ${e.message}", null)
        }
    }

    private fun stopAdvertising(result: Result) {
        try {
            isAdvertising = false
            
            scheduler?.shutdown()
            scheduler = null
            
            multicastSocket?.close()
            multicastSocket = null
            
            mdnsAddress = null
            
            result.success(true)
            Log.d(TAG, "mDNS advertising stopped")
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to stop mDNS advertising", e)
            result.error("STOP_ERROR", "Failed to stop: ${e.message}", null)
        }
    }

    private fun advertiseService(
        serviceName: String,
        port: Int,
        txtRecords: Map<String, String>,
        localIP: String
    ) {
        try {
            val deviceName = serviceName.split('.').firstOrNull() ?: "OPPO-Pad"
            val serviceType = "_airplay._tcp.local"
            
            // 发送PTR记录
            sendPtrRecord(serviceType, serviceName)
            
            // 发送SRV记录
            sendSrvRecord(serviceName, "$deviceName.local", port)
            
            // 发送TXT记录
            sendTxtRecord(serviceName, txtRecords)
            
            // 发送A记录
            sendARecord("$deviceName.local", localIP)
            
            Log.d(TAG, "mDNS records sent for $serviceName")
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to advertise service", e)
        }
    }

    private fun sendPtrRecord(serviceType: String, serviceName: String) {
        val message = buildDnsMessage {
            // PTR记录指向服务实例
            addAnswer(
                name = serviceType,
                type = 12, // PTR
                clazz = 0x8001, // IN with cache flush
                ttl = 120,
                data = encodeName(serviceName)
            )
        }
        sendMdnsPacket(message)
    }

    private fun sendSrvRecord(serviceName: String, targetHost: String, port: Int) {
        val srvData = mutableListOf<Byte>()
        srvData.addAll(encodeUint16(0)) // Priority
        srvData.addAll(encodeUint16(0)) // Weight
        srvData.addAll(encodeUint16(port)) // Port
        srvData.addAll(encodeName(targetHost)) // Target
        
        val message = buildDnsMessage {
            addAnswer(
                name = serviceName,
                type = 33, // SRV
                clazz = 0x8001,
                ttl = 120,
                data = srvData
            )
        }
        sendMdnsPacket(message)
    }

    private fun sendTxtRecord(serviceName: String, txtRecords: Map<String, String>) {
        val txtData = mutableListOf<Byte>()
        
        txtRecords.forEach { (key, value) ->
            val record = "$key=$value"
            val bytes = record.toByteArray()
            txtData.add(bytes.size.toByte())
            txtData.addAll(bytes.toList())
        }
        
        val message = buildDnsMessage {
            addAnswer(
                name = serviceName,
                type = 16, // TXT
                clazz = 0x8001,
                ttl = 120,
                data = txtData
            )
        }
        sendMdnsPacket(message)
    }

    private fun sendARecord(hostName: String, ipAddress: String) {
        val ipBytes = ipAddress.split('.').map { it.toInt().toByte() }
        
        val message = buildDnsMessage {
            addAnswer(
                name = hostName,
                type = 1, // A
                clazz = 0x8001,
                ttl = 120,
                data = ipBytes
            )
        }
        sendMdnsPacket(message)
    }

    private fun sendMdnsRecord(data: ByteArray, result: Result) {
        try {
            sendMdnsPacket(data.toList())
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to send mDNS record", e)
            result.error("SEND_ERROR", "Failed to send: ${e.message}", null)
        }
    }

    private fun sendMdnsPacket(data: List<Byte>) {
        try {
            val packet = DatagramPacket(
                data.toByteArray(),
                data.size,
                mdnsAddress,
                MDNS_PORT
            )
            multicastSocket?.send(packet)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to send mDNS packet", e)
        }
    }

    private fun buildDnsMessage(builder: DnsMessageBuilder.() -> Unit): List<Byte> {
        val messageBuilder = DnsMessageBuilder()
        builder(messageBuilder)
        return messageBuilder.build()
    }

    private fun encodeName(name: String): List<Byte> {
        val result = mutableListOf<Byte>()
        val parts = name.split('.')
        
        for (part in parts) {
            if (part.isNotEmpty()) {
                result.add(part.length.toByte())
                result.addAll(part.toByteArray().toList())
            }
        }
        result.add(0) // 结束标记
        
        return result
    }

    private fun encodeUint16(value: Int): List<Byte> {
        return listOf(
            ((value shr 8) and 0xFF).toByte(),
            (value and 0xFF).toByte()
        )
    }

    private fun encodeUint32(value: Long): List<Byte> {
        return listOf(
            ((value shr 24) and 0xFF).toByte(),
            ((value shr 16) and 0xFF).toByte(),
            ((value shr 8) and 0xFF).toByte(),
            (value and 0xFF).toByte()
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        stopAdvertising(object : Result {
            override fun success(result: Any?) {}
            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {}
            override fun notImplemented() {}
        })
    }

    private class DnsMessageBuilder {
        private val answers = mutableListOf<DnsAnswer>()

        fun addAnswer(name: String, type: Int, clazz: Int, ttl: Long, data: List<Byte>) {
            answers.add(DnsAnswer(name, type, clazz, ttl, data))
        }

        fun build(): List<Byte> {
            val message = mutableListOf<Byte>()
            
            // DNS头部 (12字节)
            message.addAll(listOf(0x00, 0x00).map { it.toByte() }) // ID
            message.addAll(listOf(0x84, 0x00).map { it.toByte() }) // 标志 (Response, Authoritative)
            message.addAll(listOf(0x00, 0x00).map { it.toByte() }) // QDCOUNT
            message.addAll(encodeUint16(answers.size)) // ANCOUNT
            message.addAll(listOf(0x00, 0x00).map { it.toByte() }) // NSCOUNT
            message.addAll(listOf(0x00, 0x00).map { it.toByte() }) // ARCOUNT
            
            // 回答部分
            for (answer in answers) {
                message.addAll(encodeName(answer.name))
                message.addAll(encodeUint16(answer.type))
                message.addAll(encodeUint16(answer.clazz))
                message.addAll(encodeUint32(answer.ttl))
                message.addAll(encodeUint16(answer.data.size))
                message.addAll(answer.data)
            }
            
            return message
        }

        private fun encodeName(name: String): List<Byte> {
            val result = mutableListOf<Byte>()
            val parts = name.split('.')
            
            for (part in parts) {
                if (part.isNotEmpty()) {
                    result.add(part.length.toByte())
                    result.addAll(part.toByteArray().toList())
                }
            }
            result.add(0) // 结束标记
            
            return result
        }

        private fun encodeUint16(value: Int): List<Byte> {
            return listOf(
                ((value shr 8) and 0xFF).toByte(),
                (value and 0xFF).toByte()
            )
        }

        private fun encodeUint32(value: Long): List<Byte> {
            return listOf(
                ((value shr 24) and 0xFF).toByte(),
                ((value shr 16) and 0xFF).toByte(),
                ((value shr 8) and 0xFF).toByte(),
                (value and 0xFF).toByte()
            )
        }
    }

    private data class DnsAnswer(
        val name: String,
        val type: Int,
        val clazz: Int,
        val ttl: Long,
        val data: List<Byte>
    )
}
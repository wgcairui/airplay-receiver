package com.airplay.padcast.receiver

import android.media.*
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.concurrent.LinkedBlockingQueue

class AudioDecoderPlugin : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
    companion object {
        private const val CHANNEL = "com.airplay.padcast.receiver/audio_decoder"
        private const val EVENT_CHANNEL = "com.airplay.padcast.receiver/audio_events"
        private const val TAG = "AudioDecoderPlugin"
        private const val MIME_TYPE_AAC = "audio/mp4a-latm"
    }

    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    
    private var mediaCodec: MediaCodec? = null
    private var audioTrack: AudioTrack? = null
    private var isInitialized = false
    private var isDecoding = false
    
    private val frameQueue = LinkedBlockingQueue<ByteArray>()
    private val handler = Handler(Looper.getMainLooper())
    
    private var sampleRate = 44100
    private var channels = 2
    private var frameCount = 0
    private var lastFrameTime = System.currentTimeMillis()

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
        
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, EVENT_CHANNEL)
        eventChannel.setStreamHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initialize" -> {
                val sampleRate = call.argument<Int>("sampleRate") ?: 44100
                val channels = call.argument<Int>("channels") ?: 2
                val codecType = call.argument<String>("codecType") ?: MIME_TYPE_AAC
                initialize(sampleRate, channels, codecType, result)
            }
            "decode" -> {
                val data = call.argument<ByteArray>("data")
                if (data != null) {
                    decode(data, result)
                } else {
                    result.error("INVALID_ARGUMENT", "Data is null", null)
                }
            }
            "start" -> {
                startDecoding(result)
            }
            "stop" -> {
                stopDecoding(result)
            }
            "release" -> {
                release(result)
            }
            "setParams" -> {
                val volume = call.argument<Double>("volume")
                val muted = call.argument<Boolean>("muted")
                val bufferSize = call.argument<Int>("bufferSize")
                setParams(volume, muted, bufferSize, result)
            }
            "getDeviceInfo" -> {
                getDeviceInfo(result)
            }
            "flush" -> {
                flush(result)
            }
            "reset" -> {
                reset(result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun initialize(sampleRate: Int, channels: Int, codecType: String, result: Result) {
        try {
            this.sampleRate = sampleRate
            this.channels = channels

            // 创建MediaFormat
            val format = MediaFormat.createAudioFormat(codecType, sampleRate, channels).apply {
                setInteger(MediaFormat.KEY_MAX_INPUT_SIZE, 16384)
                setInteger(MediaFormat.KEY_AAC_PROFILE, MediaCodecInfo.CodecProfileLevel.AACObjectLC)
            }

            // 创建MediaCodec解码器
            mediaCodec = MediaCodec.createDecoderByType(codecType).apply {
                configure(format, null, null, 0)
            }

            // 创建AudioTrack
            val channelConfig = if (channels == 1) AudioFormat.CHANNEL_OUT_MONO else AudioFormat.CHANNEL_OUT_STEREO
            val audioFormat = AudioFormat.ENCODING_PCM_16BIT
            val bufferSize = AudioTrack.getMinBufferSize(sampleRate, channelConfig, audioFormat)

            audioTrack = AudioTrack(
                AudioManager.STREAM_MUSIC,
                sampleRate,
                channelConfig,
                audioFormat,
                bufferSize,
                AudioTrack.MODE_STREAM
            )

            isInitialized = true
            result.success(true)
            Log.d(TAG, "Audio decoder initialized: ${sampleRate}Hz ${channels}ch")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize audio decoder", e)
            result.error("INIT_ERROR", "Failed to initialize: ${e.message}", null)
        }
    }

    private fun startDecoding(result: Result) {
        if (!isInitialized) {
            result.error("NOT_INITIALIZED", "Decoder not initialized", null)
            return
        }

        try {
            mediaCodec?.start()
            audioTrack?.play()
            isDecoding = true
            
            // 启动解码线程
            Thread {
                processFrameQueue()
            }.start()
            
            result.success(true)
            Log.d(TAG, "Audio decoding started")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start decoding", e)
            result.error("START_ERROR", "Failed to start: ${e.message}", null)
        }
    }

    private fun decode(data: ByteArray, result: Result) {
        if (!isDecoding) {
            result.error("NOT_DECODING", "Decoder not started", null)
            return
        }

        try {
            frameQueue.offer(data)
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to queue audio frame", e)
            result.error("DECODE_ERROR", "Failed to decode: ${e.message}", null)
        }
    }

    private fun processFrameQueue() {
        while (isDecoding) {
            try {
                val frameData = frameQueue.poll(100, java.util.concurrent.TimeUnit.MILLISECONDS)
                if (frameData != null) {
                    processFrame(frameData)
                }
            } catch (e: InterruptedException) {
                Log.d(TAG, "Audio frame processing interrupted")
                break
            } catch (e: Exception) {
                Log.e(TAG, "Error processing audio frame", e)
            }
        }
    }

    private fun processFrame(data: ByteArray) {
        val codec = mediaCodec ?: return
        val track = audioTrack ?: return
        
        try {
            val inputBufferIndex = codec.dequeueInputBuffer(1000)
            if (inputBufferIndex >= 0) {
                val inputBuffer = codec.getInputBuffer(inputBufferIndex)
                inputBuffer?.apply {
                    clear()
                    put(data)
                }
                
                codec.queueInputBuffer(
                    inputBufferIndex, 
                    0, 
                    data.size, 
                    System.nanoTime() / 1000, 
                    0
                )
            }

            // 处理输出
            val bufferInfo = MediaCodec.BufferInfo()
            val outputBufferIndex = codec.dequeueOutputBuffer(bufferInfo, 0)
            
            when (outputBufferIndex) {
                MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                    val format = codec.outputFormat
                    Log.d(TAG, "Audio output format changed: $format")
                    notifyEvent("formatChanged", mapOf<String, Any>(
                        "sampleRate" to format.getInteger(MediaFormat.KEY_SAMPLE_RATE),
                        "channels" to format.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
                    ))
                }
                MediaCodec.INFO_TRY_AGAIN_LATER -> {
                    // 暂时没有输出可用
                }
                else -> {
                    if (outputBufferIndex >= 0) {
                        val outputBuffer = codec.getOutputBuffer(outputBufferIndex)
                        if (outputBuffer != null && bufferInfo.size > 0) {
                            // 播放音频数据
                            val pcmData = ByteArray(bufferInfo.size)
                            outputBuffer.get(pcmData)
                            track.write(pcmData, 0, pcmData.size)
                            
                            // 统计
                            frameCount++
                            val currentTime = System.currentTimeMillis()
                            if (currentTime - lastFrameTime >= 1000) {
                                notifyEvent("frameRate", mapOf<String, Any>("fps" to (frameCount * 1000.0 / (currentTime - lastFrameTime))))
                                frameCount = 0
                                lastFrameTime = currentTime
                            }
                            
                            notifyEvent("frameDecoded", mapOf<String, Any>(
                                "timestamp" to bufferInfo.presentationTimeUs,
                                "sampleRate" to sampleRate,
                                "channels" to channels
                            ))
                        }
                        
                        codec.releaseOutputBuffer(outputBufferIndex, false)
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error processing audio frame", e)
            notifyEvent("error", mapOf<String, Any>("message" to (e.message ?: "Unknown error")))
        }
    }

    private fun stopDecoding(result: Result) {
        try {
            isDecoding = false
            frameQueue.clear()
            
            mediaCodec?.apply {
                stop()
                flush()
            }
            
            audioTrack?.apply {
                pause()
                flush()
            }
            
            result.success(true)
            Log.d(TAG, "Audio decoding stopped")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to stop decoding", e)
            result.error("STOP_ERROR", "Failed to stop: ${e.message}", null)
        }
    }

    private fun setParams(volume: Double?, muted: Boolean?, bufferSize: Int?, result: Result) {
        try {
            audioTrack?.apply {
                volume?.let { setStereoVolume(it.toFloat(), it.toFloat()) }
                // Note: AudioTrack doesn't have a direct mute method
                // Muting would need to be implemented by setting volume to 0
                if (muted == true) {
                    setStereoVolume(0f, 0f)
                }
            }
            
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to set audio params", e)
            result.error("PARAM_ERROR", "Failed to set params: ${e.message}", null)
        }
    }

    private fun getDeviceInfo(result: Result) {
        try {
            val deviceInfo = mapOf<String, Any>(
                "sampleRate" to sampleRate,
                "channels" to channels,
                "bufferSize" to (audioTrack?.bufferSizeInFrames ?: 0),
                "state" to (audioTrack?.state ?: AudioTrack.STATE_UNINITIALIZED)
            )
            result.success(deviceInfo)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get device info", e)
            result.error("INFO_ERROR", "Failed to get info: ${e.message}", null)
        }
    }

    private fun flush(result: Result) {
        try {
            mediaCodec?.flush()
            audioTrack?.flush()
            frameQueue.clear()
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to flush", e)
            result.error("FLUSH_ERROR", "Failed to flush: ${e.message}", null)
        }
    }

    private fun reset(result: Result) {
        try {
            flush(result)
            frameCount = 0
            lastFrameTime = System.currentTimeMillis()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to reset", e)
            result.error("RESET_ERROR", "Failed to reset: ${e.message}", null)
        }
    }

    private fun release(result: Result) {
        try {
            stopDecoding(result)
            
            mediaCodec?.release()
            mediaCodec = null
            
            audioTrack?.release()
            audioTrack = null
            
            isInitialized = false
            Log.d(TAG, "Audio decoder released")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to release decoder", e)
            result.error("RELEASE_ERROR", "Failed to release: ${e.message}", null)
        }
    }

    private fun notifyEvent(event: String, data: Map<String, Any>) {
        handler.post {
            eventSink?.success(mapOf<String, Any>(
                "event" to event,
                "data" to data,
                "timestamp" to System.currentTimeMillis()
            ))
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        Log.d(TAG, "Audio event stream started")
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
        Log.d(TAG, "Audio event stream cancelled")
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        
        try {
            release(object : Result {
                override fun success(result: Any?) {}
                override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {}
                override fun notImplemented() {}
            })
        } catch (e: Exception) {
            Log.e(TAG, "Error during cleanup", e)
        }
    }
}
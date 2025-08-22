package com.airplay.padcast.receiver

import android.graphics.SurfaceTexture
import android.media.MediaCodec
import android.media.MediaFormat
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.Surface
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.nio.ByteBuffer
import java.util.concurrent.LinkedBlockingQueue

class VideoDecoderPlugin : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
    companion object {
        private const val CHANNEL = "com.airplay.padcast.receiver/video_decoder"
        private const val EVENT_CHANNEL = "com.airplay.padcast.receiver/video_events"
        private const val TAG = "VideoDecoderPlugin"
        private const val MIME_TYPE = "video/avc"
    }

    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    
    private var mediaCodec: MediaCodec? = null
    private var surface: Surface? = null
    private var surfaceTexture: SurfaceTexture? = null
    private var isInitialized = false
    private var isDecoding = false
    
    private val frameQueue = LinkedBlockingQueue<ByteArray>()
    private val handler = Handler(Looper.getMainLooper())
    
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
                val width = call.argument<Int>("width") ?: 1920
                val height = call.argument<Int>("height") ?: 1080
                initialize(width, height, result)
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
            "getSurfaceTextureId" -> {
                result.success(getSurfaceTextureId())
            }
            "createTexture" -> {
                createTexture(result)
            }
            "getTextureId" -> {
                result.success(getTextureId())
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun initialize(width: Int, height: Int, result: Result) {
        try {
            // 创建MediaFormat
            val format = MediaFormat.createVideoFormat(MIME_TYPE, width, height).apply {
                setInteger(MediaFormat.KEY_MAX_INPUT_SIZE, width * height)
                setInteger(MediaFormat.KEY_LOW_LATENCY, 1)
            }

            // 创建SurfaceTexture用于渲染
            surfaceTexture = SurfaceTexture(0)
            surface = Surface(surfaceTexture)

            // 创建MediaCodec解码器
            mediaCodec = MediaCodec.createDecoderByType(MIME_TYPE).apply {
                configure(format, surface, null, 0)
            }

            isInitialized = true
            result.success(true)
            Log.d(TAG, "Video decoder initialized: ${width}x${height}")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize video decoder", e)
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
            isDecoding = true
            
            // 启动解码线程
            Thread {
                processFrameQueue()
            }.start()
            
            result.success(true)
            Log.d(TAG, "Video decoding started")
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
            Log.e(TAG, "Failed to queue frame", e)
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
                Log.d(TAG, "Frame processing interrupted")
                break
            } catch (e: Exception) {
                Log.e(TAG, "Error processing frame", e)
            }
        }
    }

    private fun processFrame(data: ByteArray) {
        val codec = mediaCodec ?: return
        
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
                    Log.d(TAG, "Output format changed: $format")
                    notifyEvent("formatChanged", mapOf<String, Any>(
                        "width" to format.getInteger(MediaFormat.KEY_WIDTH),
                        "height" to format.getInteger(MediaFormat.KEY_HEIGHT)
                    ))
                }
                MediaCodec.INFO_TRY_AGAIN_LATER -> {
                    // 暂时没有输出可用
                }
                else -> {
                    if (outputBufferIndex >= 0) {
                        // 释放输出缓冲区，这会触发Surface渲染
                        codec.releaseOutputBuffer(outputBufferIndex, true)
                        
                        // 统计帧率
                        frameCount++
                        val currentTime = System.currentTimeMillis()
                        if (currentTime - lastFrameTime >= 1000) {
                            val fps = frameCount * 1000.0 / (currentTime - lastFrameTime)
                            notifyEvent("frameRate", mapOf<String, Any>("fps" to fps))
                            frameCount = 0
                            lastFrameTime = currentTime
                        }
                        
                        notifyEvent("frameDecoded", mapOf<String, Any>("timestamp" to bufferInfo.presentationTimeUs))
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error processing frame", e)
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
            
            result.success(true)
            Log.d(TAG, "Video decoding stopped")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to stop decoding", e)
            result.error("STOP_ERROR", "Failed to stop: ${e.message}", null)
        }
    }

    private fun release(result: Result) {
        try {
            stopDecoding(result)
            
            mediaCodec?.release()
            mediaCodec = null
            
            surface?.release()
            surface = null
            
            surfaceTexture?.release()
            surfaceTexture = null
            
            isInitialized = false
            Log.d(TAG, "Video decoder released")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to release decoder", e)
            result.error("RELEASE_ERROR", "Failed to release: ${e.message}", null)
        }
    }

    private fun getSurfaceTextureId(): Long {
        return surfaceTexture?.hashCode()?.toLong() ?: -1L
    }
    
    private fun createTexture(result: Result) {
        try {
            if (surfaceTexture != null) {
                result.success(getTextureId())
                return
            }
            
            // 创建新的SurfaceTexture用于Flutter Texture widget
            surfaceTexture = SurfaceTexture(0).apply {
                setDefaultBufferSize(1920, 1080)
                setOnFrameAvailableListener { texture ->
                    // 通知Flutter有新帧可用
                    notifyEvent("frameAvailable", mapOf<String, Any>(
                        "textureId" to (texture.hashCode().toLong())
                    ))
                }
            }
            
            surface = Surface(surfaceTexture)
            
            result.success(getTextureId())
            Log.d(TAG, "Created texture with ID: ${getTextureId()}")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to create texture", e)
            result.error("TEXTURE_ERROR", "Failed to create texture: ${e.message}", null)
        }
    }
    
    private fun getTextureId(): Long {
        return surfaceTexture?.hashCode()?.toLong() ?: -1L
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
        Log.d(TAG, "Event stream started")
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
        Log.d(TAG, "Event stream cancelled")
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
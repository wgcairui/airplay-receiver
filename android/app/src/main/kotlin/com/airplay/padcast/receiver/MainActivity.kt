package com.airplay.padcast.receiver

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // 注册视频解码器插件
        flutterEngine.plugins.add(VideoDecoderPlugin())
        
        // 注册音频解码器插件
        flutterEngine.plugins.add(AudioDecoderPlugin())
        
        // 注册mDNS插件
        flutterEngine.plugins.add(MdnsPlugin())
    }
}
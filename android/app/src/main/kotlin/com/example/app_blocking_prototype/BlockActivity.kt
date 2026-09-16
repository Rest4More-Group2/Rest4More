package com.example.app_blocking_prototype

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngineCache

class BlockActivity : FlutterActivity() {
    override fun provideFlutterEngine(context: android.content.Context) =
        FlutterEngineCache.getInstance().get("block_engine")
}
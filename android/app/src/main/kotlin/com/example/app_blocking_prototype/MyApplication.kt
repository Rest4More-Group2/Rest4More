package com.example.app_blocking_prototype

import android.app.Application
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache

class MyApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        val flutterEngine = FlutterEngine(this)
        // blockMain only shows the block screen. Running the normal main()
        // here would open the app database a second time at every start.
        flutterEngine.dartExecutor.executeDartEntrypoint(
            io.flutter.embedding.engine.dart.DartExecutor.DartEntrypoint(
                io.flutter.FlutterInjector.instance().flutterLoader().findAppBundlePath(),
                "blockMain"
            )
        )
        FlutterEngineCache.getInstance().put("block_engine", flutterEngine)
    }
}
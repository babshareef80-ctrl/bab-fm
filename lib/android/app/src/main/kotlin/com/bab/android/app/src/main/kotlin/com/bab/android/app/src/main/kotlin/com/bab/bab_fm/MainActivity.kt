package com.bab.bab_fm

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val channel = "bab.fm/radio"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channel
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "start" -> {
                    // FM hardware integration will be added later.
                    result.success(null)
                }

                "stop" -> {
                    result.success(null)
                }

                "tune" -> {
                    val frequency =
                        call.argument<Double>("frequency") ?: 99.5

                    // Real C671L FM driver will be connected here.
                    result.success(frequency)
                }

                "scan" -> {
                    // Real FM auto-scan will be connected here.
                    result.success(emptyList<Double>())
                }

                "startRecording" -> {
                    // Direct FM recording integration will be added later.
                    result.success(null)
                }

                "stopRecording" -> {
                    result.success(null)
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}

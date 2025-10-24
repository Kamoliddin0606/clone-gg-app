package com.example.gloria_marketing_flutter

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.yandex.mapkit.MapKitFactory

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.gloria.map_tokens"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Initialize Yandex MapKit
        try {
            MapKitFactory.initialize(this)
            println("Yandex MapKit initialized successfully")
        } catch (e: Exception) {
            println("Error initializing Yandex MapKit: ${e.message}")
        }

        // Set up method channel for map tokens
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setYandexToken" -> {
                    val token = call.argument<String>("token")
                    if (token != null) {
                        try {
                            MapKitFactory.setApiKey(token)
                            result.success(true)
                            println("Yandex Maps API key set successfully")
                        } catch (e: Exception) {
                            result.error("YANDEX_TOKEN_ERROR", "Failed to set Yandex token: ${e.message}", null)
                        }
                    } else {
                        result.error("INVALID_TOKEN", "Yandex token is null", null)
                    }
                }
                "setGoogleToken" -> {
                    // Google Maps token is handled in AndroidManifest.xml
                    // This is just for consistency with the Flutter interface
                    result.success(true)
                }
                "initializeMaps" -> {
                    try {
                        // Ensure MapKit is properly initialized
                        MapKitFactory.initialize(this)
                        result.success(true)
                        println("Maps initialization completed")
                    } catch (e: Exception) {
                        result.error("INIT_ERROR", "Failed to initialize maps: ${e.message}", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onStart() {
        super.onStart()
        try {
            MapKitFactory.getInstance().onStart()
        } catch (e: Exception) {
            println("Error starting MapKit: ${e.message}")
        }
    }

    override fun onStop() {
        try {
            MapKitFactory.getInstance().onStop()
        } catch (e: Exception) {
            println("Error stopping MapKit: ${e.message}")
        }
        super.onStop()
    }
}

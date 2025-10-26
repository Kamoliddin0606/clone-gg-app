//package com.example.gloria_marketing_flutter
//
//import io.flutter.embedding.android.FlutterActivity
//
//class MainActivity : FlutterActivity()
// android/app/src/main/kotlin/com/example/gloria_marketing_flutter/MainActivity.kt
package com.example.gloria_marketing_flutter

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        // FlutterActivity V2 auto-registration ishlaydi,
        // biroq ba'zi hollarda aniq registratsiya yordam beradi:
        super.configureFlutterEngine(flutterEngine)
        try {
            // Qo‘lda registratsiyani ham chaqirib qo‘yamiz (idempotent, zarar qilmaydi)
            GeneratedPluginRegistrant.registerWith(flutterEngine)
        } catch (_: Throwable) {
            // Hech narsa qilmaymiz: auto-reg allaqachon ishlagan bo‘lishi mumkin
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Eslatma:
        // - Google API key AndroidManifest.xml dagi:
        //     <meta-data android:name="com.google.android.geo.API_KEY" android:value="..."/>
        // - Yandex API key AndroidManifest.xml dagi:
        //     <meta-data android:name="com.yandex.maps.apikey" android:value="..."/>
        //
        // MapKitFactory.setApiKey(...) bu loyihada SHART EMAS,
        // chunki kalitlar manifestda berilgan.
        // Hech qanday method-channel yoki qo‘shimcha init KERAK EMAS.
    }
}

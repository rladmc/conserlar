package com.rladmc.pdfconserlar

import android.content.Context // Necessário para pegar o serviço de Wi-Fi
import android.net.wifi.WifiManager // Necessário para o MulticastLock
import android.os.Bundle
import android.view.WindowManager
import android.content.Intent
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.rladmc.pdfconserlar/android"
    private var multicastLock: WifiManager.MulticastLock? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // 🔒 BLOQUEIA PRINTS, GRAVAÇÕES DE TELA E ESCONDE NO MULTITAREFA (RECENT APPS)
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 📡 ATIVA O MULTICAST LOCK PARA O DLNA/SSDP CONSEGUIR ESCUTAR AS TVS NA REDE
        try {
            val wifiManager = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            multicastLock = wifiManager.createMulticastLock("ConserlarMulticastLock").apply {
                setReferenceCounted(true)
                acquire()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "abrirScanInversora" -> {
                    val intent = Intent(this@MainActivity, ScanInversoraActivity::class.java)
                    startActivity(intent)
                    result.success(true)
                }
                "abrirPrimeiroEeprom" -> {
                    val intent = Intent(this@MainActivity, PrimeiroEeprom::class.java).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    startActivity(intent)
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        // Libera o multicast lock ao fechar o app para economizar bateria
        try {
            multicastLock?.let {
                if (it.isHeld) {
                    it.release()
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
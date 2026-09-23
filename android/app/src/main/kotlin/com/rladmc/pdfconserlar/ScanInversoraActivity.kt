package com.rladmc.pdfconserlar

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Bundle
import android.util.Log
import android.widget.Button
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

class ScanInversoraActivity : AppCompatActivity() {

    private val REQUEST_BT_PERMISSIONS = 2
    private lateinit var txtSoftware: TextView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        supportActionBar?.hide()
        setContentView(R.layout.layout_scan_inversora)

        txtSoftware = findViewById(R.id.txtStatusSoftware)

        // 1. Verifica permissões de Bluetooth específicas para esta função
        checkBtPermissions()

        // 2. Configura botões físicos
        findViewById<Button>(R.id.btnIniciarControle).setOnClickListener {
            startActivity(Intent(this, ConexaoActivity2::class.java))
        }

        findViewById<Button>(R.id.btnIniciarSimulac).setOnClickListener {
            startActivity(Intent(this, ConexaoActivity3::class.java))
        }

        findViewById<Button>(R.id.btnManual).setOnClickListener {
            startActivity(Intent(this, ManualActivity::class.java))
        }

        findViewById<Button>(R.id.btnAtualizacao).setOnClickListener {
            startActivity(Intent(this, ConexaoActivity12::class.java))
        }

        // 3. Captura o Deep Link se o app foi aberto pelo ESP32
        handleOtaSuccess(intent)
        exibirVersaoSoftware()
    }

    override fun onStart() {
        super.onStart()
    }

    override fun onStop() {
        super.onStop()
    }

    override fun onResume() {
        super.onResume()
        exibirVersaoSoftware()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleOtaSuccess(intent)
    }

    private fun handleOtaSuccess(intent: Intent?) {
        val uri: Uri? = intent?.data
        if (uri != null && "motorapp" == uri.scheme && "ota.success" == uri.host) {
            Toast.makeText(this, "✅ Configuração Wi-Fi e OTA concluída!", Toast.LENGTH_LONG).show()
            exibirVersaoSoftware()
            intent.data = null
        }
    }

    private fun exibirVersaoSoftware() {
        val prefs = getSharedPreferences("FIRMWARE_PREFS", Context.MODE_PRIVATE)
        val softwareVersion = prefs.getString("SAVED_FIRMWARE_VERSION", "N/A")
        txtSoftware.text = "Firmware Placa: $softwareVersion"
    }

    private fun checkBtPermissions() {
        val permissions = mutableListOf<String>()
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
            permissions.add(Manifest.permission.BLUETOOTH_SCAN)
            permissions.add(Manifest.permission.BLUETOOTH_CONNECT)
        } else {
            permissions.add(Manifest.permission.ACCESS_FINE_LOCATION)
        }

        val missing = permissions.filter {
            ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
        }

        if (missing.isNotEmpty()) {
            ActivityCompat.requestPermissions(this, missing.toTypedArray(), REQUEST_BT_PERMISSIONS)
        }
    }

    override fun onBackPressed() {
        super.onBackPressed()
    }
}
package com.rladmc.pdfconserlar

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.Bundle
import android.os.IBinder
import android.widget.LinearLayout
import androidx.activity.OnBackPressedCallback
import androidx.appcompat.app.AppCompatActivity

class ModelosPhilcoActivity : AppCompatActivity() {

    private var bluetoothService: BluetoothService? = null
    private var isBound = false

    private lateinit var cardPLS11: LinearLayout
    private lateinit var cardPLS12: LinearLayout

    private val serviceConnection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName, service: IBinder) {
            val binder = service as BluetoothService.LocalBinder
            bluetoothService = binder.getService()
            isBound = true
        }

        override fun onServiceDisconnected(name: ComponentName) {
            isBound = false
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        supportActionBar?.hide()
        setContentView(R.layout.modelosphilco)

        inicializarViews()
        configurarListeners()
        configurarBotaoVoltar()

        // Inicia e conecta o BluetoothService
        val serviceIntent = Intent(this, BluetoothService::class.java)
        startService(serviceIntent)
        bindService(serviceIntent, serviceConnection, Context.BIND_AUTO_CREATE)
    }

    private fun inicializarViews() {
        cardPLS11 = findViewById(R.id.cardPLS11)
        cardPLS12 = findViewById(R.id.cardPLS12)
    }

    private fun enviarComandoEAbrirActivity(comando: String, tipo: String) {
        if (isBound && bluetoothService != null) {
            bluetoothService?.write(comando)
        }

        val intent = Intent(this, ControleMotorActivity::class.java).apply {
            putExtra("MODELO", "PHILCO")
            putExtra("TIPO", tipo) // PLS11 ou PLS12
        }
        startActivity(intent)
    }

    private fun configurarListeners() {
        // 👉 Philco PLS11 → comando "2"
        cardPLS11.setOnClickListener {
            enviarComandoEAbrirActivity("2", "PLS11")
        }

        // 👉 Philco PLS12 → comando "1"
        cardPLS12.setOnClickListener {
            enviarComandoEAbrirActivity("1", "PLS12")
        }
    }

    private fun configurarBotaoVoltar() {
        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                val serviceIntent = Intent(this@ModelosPhilcoActivity, BluetoothService::class.java)

                if (isBound) {
                    unbindService(serviceConnection)
                    isBound = false
                }

                stopService(serviceIntent)

                finish()
            }
        })
    }
}
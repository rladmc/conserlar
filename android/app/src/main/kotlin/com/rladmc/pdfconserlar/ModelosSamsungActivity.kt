package com.rladmc.pdfconserlar

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.Bundle
import android.os.IBinder
import android.view.View
import android.widget.ImageView
import android.widget.LinearLayout
import androidx.activity.OnBackPressedCallback
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity

class ModelosSamsungActivity : AppCompatActivity() {

    private var bluetoothService: BluetoothService? = null
    private var isBound = false

    private lateinit var cardSimples: LinearLayout
    private lateinit var cardDupla: LinearLayout

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

        setContentView(R.layout.modelossamsung)

        inicializarViews()
        configurarListeners()
        configurarBotaoVoltar()

        // Inicia e conecta o BluetoothService
        val serviceIntent = Intent(this, BluetoothService::class.java)
        startService(serviceIntent)
        bindService(serviceIntent, serviceConnection, Context.BIND_AUTO_CREATE)
    }

    private fun inicializarViews() {
        cardSimples = findViewById(R.id.cardSimples)
        cardDupla = findViewById(R.id.cardDupla)
    }

    private fun enviarComandoEAbrirActivity(comando: String, tipo: String) {
        if (isBound && bluetoothService != null) {
            bluetoothService?.write(comando) // continua sendo "4"
        }

        val intent = Intent(this, ControleMotorActivity::class.java).apply {
            putExtra("MODELO", "SAMSUNG")
            putExtra("TIPO", tipo) // SIMPLES ou DUPLA
        }
        startActivity(intent)
    }

    private fun configurarListeners() {
        cardSimples.setOnClickListener {
            mostrarDialogSimples()
        }

        cardDupla.setOnClickListener {
            enviarComandoEAbrirActivity("4", "DUPLA")
        }
    }

    private fun configurarBotaoVoltar() {
        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                val serviceIntent = Intent(this@ModelosSamsungActivity, BluetoothService::class.java)

                if (isBound) {
                    unbindService(serviceConnection)
                    isBound = false
                }

                stopService(serviceIntent)
                finish()
            }
        })
    }

    private fun mostrarDialogSimples() {
        val builder = AlertDialog.Builder(this)
        val inflater = layoutInflater
        val dialogView = inflater.inflate(R.layout.dialog_simples, null)

        builder.setView(dialogView)
        val dialog = builder.create()

        val imgSimples = dialogView.findViewById<ImageView>(R.id.imgSimples)
        val imgSimplesCor = dialogView.findViewById<ImageView>(R.id.imgSimplesCor)

        imgSimples.setOnClickListener {
            enviarComandoEAbrirActivity("s", "SIMPLES")
            dialog.dismiss()
        }

        imgSimplesCor.setOnClickListener {
            enviarComandoEAbrirActivity("t", "SIMPLESCOR")
            dialog.dismiss()
        }

        dialog.show()
    }
}
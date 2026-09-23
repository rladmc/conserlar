package com.rladmc.pdfconserlar

import android.app.AlertDialog
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.Bundle
import android.os.IBinder
import android.view.View
import android.widget.LinearLayout
import android.widget.Toast
import androidx.activity.OnBackPressedCallback
import androidx.appcompat.app.AppCompatActivity

class MenuPrincipalActivity : AppCompatActivity() {

    private var bluetoothService: BluetoothService? = null
    private var isBound = false
    private var simuladorDialog: AlertDialog? = null

    // Cartões clicáveis (Midea, Philco, Hisense, Samsung, LG)
    private lateinit var cardMidea: LinearLayout
    private lateinit var cardPhilco: LinearLayout
    private lateinit var cardHisense: LinearLayout
    private lateinit var cardSamsung: LinearLayout
    private lateinit var cardLG: LinearLayout

    private val serviceConnection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName, service: IBinder) {
            val binder = service as BluetoothService.LocalBinder
            bluetoothService = binder.getService()
            isBound = true

            // ENVIA O COMANDO DE INICIALIZAÇÃO "z" QUANDO O MENU É ABERTO
            enviarComando("z")
        }

        override fun onServiceDisconnected(name: ComponentName) {
            isBound = false
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        supportActionBar?.hide()
        setContentView(R.layout.menu_principal)

        // 1. Inicializa Views
        inicializarViews()

        // 2. Configura os comandos de clique
        configurarListeners()
        configurarBotaoVoltar()

        // 3. Lógica do SERVICE
        val serviceIntent = Intent(this, BluetoothService::class.java)
        startService(serviceIntent)
        bindService(serviceIntent, serviceConnection, Context.BIND_AUTO_CREATE)
    }

    // --- Inicialização da UI ---

    private fun inicializarViews() {
        cardMidea = findViewById(R.id.cardMidea)
        cardPhilco = findViewById(R.id.cardPhilco)
        cardHisense = findViewById(R.id.cardHisense)
        cardSamsung = findViewById(R.id.cardSamsung)
        cardLG = findViewById(R.id.cardLG)
        cardLG.visibility = View.GONE
    }

    // --- Lógica de Comandos e Navegação ---

    private fun enviarComando(comando: String) {
        if (isBound && bluetoothService != null) {
            bluetoothService?.write(comando)
        }
    }

    private fun configurarBotaoVoltar() {
        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                if (simuladorDialog != null && simuladorDialog?.isShowing == true) {
                    simuladorDialog?.dismiss()
                    return
                }

                // 1. Unbind primeiro
                if (isBound) {
                    unbindService(serviceConnection)
                    isBound = false
                }

                // 2. Para o serviço explicitamente para forçar o fechamento do Bluetooth
                val serviceIntent = Intent(this@MenuPrincipalActivity, BluetoothService::class.java)
                stopService(serviceIntent)

                finish()
            }
        })
    }

    private fun enviarComandoEAbrirActivity(comando: String, nomeActivity: String, activityClass: Class<*>) {
        if (isBound && bluetoothService != null) {
            bluetoothService?.write(comando)
        }
        val intent = Intent(this, activityClass)
        startActivity(intent)
    }

    private fun abrirManutencao() {
        Toast.makeText(this, "Funcionalidade em desenvolvimento.", Toast.LENGTH_SHORT).show()
        val intent = Intent(this, ManutencaoActivity::class.java)
        startActivity(intent)
    }

    // --- Configuração dos Listeners de Cards (Cliques) ---

    private fun configurarListeners() {
        cardMidea.setOnClickListener {
            enviarComando("1")
            val intent = Intent(this, ControleMotorActivity::class.java).apply {
                putExtra("MODELO", "MIDEA")
            }
            startActivity(intent)
        }

        cardPhilco.setOnClickListener {
            val intent = Intent(this, ModelosPhilcoActivity::class.java)
            startActivity(intent)
        }

        cardHisense.setOnClickListener {
            enviarComandoEAbrirActivity("3", "Motor", ControleMotorActivity::class.java)
        }

        cardSamsung.setOnClickListener {
            val intent = Intent(this, ModelosSamsungActivity::class.java)
            startActivity(intent)
        }
    }

    // --- Gerenciamento do Service ---

    override fun onDestroy() {
        super.onDestroy()
        if (simuladorDialog != null && simuladorDialog?.isShowing == true) {
            simuladorDialog?.dismiss()
        }
    }
}
package com.rladmc.pdfconserlar

import android.app.AlertDialog
import android.content.ComponentName
import android.content.Intent
import android.content.ServiceConnection
import android.content.SharedPreferences
import android.content.res.Configuration
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ProgressBar
import android.widget.TextView
import android.widget.Toast
import androidx.activity.OnBackPressedCallback
import androidx.appcompat.app.AppCompatActivity
import java.util.Locale

class ControleMotorActivity : AppCompatActivity() {

    private var dialogProgresso: AlertDialog? = null
    private var progressBarSamsung: ProgressBar? = null
    private var txtProgressoEtapa: TextView? = null
    private var isSamsung = false // Para saber se ativamos a lógica especial

    private var bluetoothService: BluetoothService? = null
    private var isBound = false

    // --- Views ---
    private lateinit var txtRPM: TextView
    private var txtStatusChat: TextView? = null

    private lateinit var btnMotorHorario: Button
    private lateinit var btnMotorAntiHorario: Button
    private lateinit var btnPararMotor: Button
    private lateinit var btnMotorAgit: Button
    private lateinit var btn400RPM: Button
    private lateinit var btn1000RPM: Button
    private lateinit var btnHabilitarMotor: Button

    // --- Controle de Estado ---
    private var popupAberto = false

    private val timeoutAgitHandler = Handler(Looper.getMainLooper())
    private var timeoutAgitRunnable: Runnable? = null

    private val timeoutHandler = Handler(Looper.getMainLooper())
    private var timeoutRunnable: Runnable? = null

    private var tipoAtual = ""
    private var cmdMotorHorario = "h"
    private var cmdMotorAntiHorario = "a"
    private var cmdMotorparar = "p"
    private var cmdMotor400 = "4"
    private var cmdMotor1000 = "1"

    // Conexão com o Service
    private val serviceConnection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName, service: IBinder) {
            val binder = service as BluetoothService.LocalBinder
            bluetoothService = binder.getService()
            isBound = true

            txtStatusChat?.text = "Conectado"
        }

        override fun onServiceDisconnected(name: ComponentName) {
            isBound = false
            txtStatusChat?.text = "Service Desconectado"
        }
    }

    companion object {
        private const val TIMEOUT_AGITACAO_MIDEA = 4000L // 4 segundos de tolerância
        private const val TIMEOUT_C_SAMSUNG = 5000L // 5 segundos
        private var instance: ControleMotorActivity? = null

        @JvmStatic
        fun processarMensagem(mensagem: String) {
            instance?.let { activity ->
                Handler(Looper.getMainLooper()).post {
                    activity.atualizarRPM(mensagem)
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        applySavedLocale()
        super.onCreate(savedInstanceState)
        supportActionBar?.hide()
        setContentView(R.layout.tela_controle_motor)

        // 1. Inicializa Views e Configurações
        inicializarViews()
        configurarBotoesControle()
        configurarBotaoVoltar()

        // 🔥 AQUI entra a lógica
        ajustarTextoBotoes()

        // 2. Conecta-se ao Service que já está rodando
        val serviceIntent = Intent(this, BluetoothService::class.java)
        bindService(serviceIntent, serviceConnection, 0)
    }

    // ------------------------------------------
    // MÉTODOS DE CICLO DE VIDA E RECEPÇÃO DE DATAS
    // ------------------------------------------

    override fun onResume() {
        super.onResume()
        instance = this // Define a instância ativa para o Service poder chamar o processarMensagem
    }

    override fun onPause() {
        super.onPause()
        instance = null
    }

    // ------------------------------------------
    // LÓGICA DE CONTROLE E UI
    // ------------------------------------------

    private fun enviarComando(comando: String) {
        if (isBound && bluetoothService != null) {
            bluetoothService?.write(comando)
        } else {
            Toast.makeText(this, getString(R.string.motor_service_error), Toast.LENGTH_SHORT).show()
        }
    }

    private fun atualizarRPM(texto: String) {
        txtRPM.text = texto

        if (texto.contains("G")) {
            cancelarTimeoutAgitacao()
        }

        if (isSamsung && dialogProgresso?.isShowing == true) {
            val comandoLimpo = texto.trim().uppercase()
            if (comandoLimpo.startsWith("C")) {
                try {
                    val etapa = comandoLimpo.substring(1).toInt()
                    iniciarTimeoutSamsung()

                    progressBarSamsung?.progress = etapa
                    txtProgressoEtapa?.text = getString(R.string.motor_enabling, etapa)

                    if (etapa >= 64) {
                        cancelarTimeoutSamsung()
                        Handler(Looper.getMainLooper()).postDelayed({
                            if (dialogProgresso?.isShowing == true) {
                                dialogProgresso?.dismiss()
                                Toast.makeText(this, getString(R.string.motor_enabled_success), Toast.LENGTH_SHORT).show()
                            }
                        }, 1000)
                    }
                } catch (e: Exception) { /* erro de parse ignore */ }
            }
        }

        if (!popupAberto) {
            if (texto.contains("E56") || texto.contains("E10")) {
                mostrarPopupErro(if (texto.contains("E56")) "E56" else "E10", getString(R.string.error_dclink_ipm))
            } else if (texto.contains("3CP4")) {
                mostrarPopupErro("3CP4", getString(R.string.error_3cp4))
            } else if (texto.contains("3C2")) {
                mostrarPopupErro("3C2", getString(R.string.error_3c2))
            } else if (texto.contains("3C")) {
                mostrarPopupErro("3C", getString(R.string.error_3c))
            } else if (texto.contains("E64") || texto.contains("E09") || texto.contains("F22") || texto.contains("AC6")) {
                var titulo = "ERR"
                if (texto.contains("E64")) titulo = "E64"
                else if (texto.contains("E09")) titulo = "E09"
                else if (texto.contains("F22")) titulo = "F22"
                else if (texto.contains("AC6")) titulo = "AC6"

                mostrarPopupErro(titulo, getString(R.string.error_comm_failure))
            }
        }
    }

    private fun mostrarPopupErro(titulo: String, mensagemErro: String) {
        popupAberto = true

        val inflater = LayoutInflater.from(this)
        val dialogView = inflater.inflate(R.layout.custom_error_dialog, null)

        val txtTitulo = dialogView.findViewById<TextView>(R.id.txtTituloErro)
        val txtMensagem = dialogView.findViewById<TextView>(R.id.txtMensagemErro)
        val txtInfo = dialogView.findViewById<TextView>(R.id.txtInfoAdicional)

        txtTitulo.textSize = 60f
        txtMensagem.textSize = 18f
        txtInfo.textSize = 17f

        txtTitulo.text = titulo
        txtMensagem.text = mensagemErro
        txtInfo.text = getString(R.string.motor_help_info)

        val builder = AlertDialog.Builder(this)
        builder.setView(dialogView)
        builder.setPositiveButton("OK", null)
        builder.setNeutralButton(getString(R.string.motor_help), null)
        builder.setCancelable(false)

        val dialog = builder.create()

        dialog.setOnDismissListener {
            enviarComando("p")
            popupAberto = false
        }

        dialog.show()

        val positiveButton = dialog.getButton(AlertDialog.BUTTON_POSITIVE)
        val neutralButton = dialog.getButton(AlertDialog.BUTTON_NEUTRAL)

        positiveButton?.setOnClickListener { dialog.dismiss() }

        neutralButton?.setOnClickListener {
            enviarComando("p")
            abrirLinkAjuda()
            dialog.dismiss()
        }
    }

    private fun abrirLinkAjuda() {
        val url = getString(R.string.link_ajuda)
        try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
            startActivity(intent)
        } catch (e: Exception) {
            Toast.makeText(this, "Erro ao abrir o link", Toast.LENGTH_SHORT).show()
        }
    }

    // ------------------------------------------
    // INICIALIZAÇÃO E LISTENERS
    // ------------------------------------------

    private fun inicializarViews() {
        txtStatusChat = findViewById(R.id.textViewStatusChat)
        txtRPM = findViewById(R.id.textViewRPM)
        btnMotorHorario = findViewById(R.id.btnMotorHorario)
        btnMotorAntiHorario = findViewById(R.id.btnMotorAntiHorario)
        btnPararMotor = findViewById(R.id.btnPararMotor)
        btn400RPM = findViewById(R.id.btn400RPM)
        btn1000RPM = findViewById(R.id.btn1000RPM)
        btnMotorAgit = findViewById(R.id.btnMotorAgit)
        btnHabilitarMotor = findViewById(R.id.btnHabilitarMotor)
    }

    private fun configurarBotoesControle() {
        btnMotorHorario.setOnClickListener { enviarComando(cmdMotorHorario) }
        btnMotorAntiHorario.setOnClickListener { enviarComando(cmdMotorAntiHorario) }
        btnPararMotor.setOnClickListener { enviarComando(cmdMotorparar) }

        btn400RPM.setOnClickListener { enviarComando(cmdMotor400) }
        btn1000RPM.setOnClickListener {
            if ("SAMSUNG" == intent.getStringExtra("MODELO") && "SIMPLESCOR" == tipoAtual) {
                mostrarAvisoPeso()
            } else {
                enviarComando(cmdMotor1000)
            }
        }

        btnHabilitarMotor.setOnClickListener {
            enviarComando("m")
            if (isSamsung) {
                mostrarPopupProgressoSamsung()
            }
        }

        btnMotorAgit.setOnClickListener {
            enviarComando("g")
            iniciarTimeoutAgitacao()
        }
    }

    private fun configurarBotaoVoltar() {
        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                enviarComando("0")
                finish()
            }
        })
    }

    private fun ajustarTextoBotoes() {
        val modelo = intent.getStringExtra("MODELO")
        val tipo = intent.getStringExtra("TIPO")
        tipoAtual = intent.getStringExtra("TIPO") ?: ""

        cmdMotorHorario = "h"
        cmdMotorAntiHorario = "a"
        cmdMotorparar = "p"
        cmdMotor400 = "4"
        cmdMotor1000 = "1"

        if ("MIDEA" == modelo) {
            btnMotorAgit.visibility = View.VISIBLE
            btnMotorHorario.text = "DIR"
            btnMotorAntiHorario.text = "ESQ"
        } else {
            btnMotorAgit.visibility = View.GONE
        }

        if ("PHILCO" == modelo) {
            if ("PLS11" == tipo) {
                btnHabilitarMotor.visibility = View.GONE
            }
        }

        if ("SAMSUNG" == modelo) {
            isSamsung = true

            if ("SIMPLES" == tipo) {
                btnMotorHorario.text = getString(R.string.motor_btn_agitation)
                btnMotorAntiHorario.visibility = View.GONE
                cmdMotorHorario = "d"
                cmdMotorparar = "q"
                cmdMotor400 = "5"
                cmdMotor1000 = "2"
            }

            if ("DUPLA" == tipo) {
                txtRPM.textSize = 40f
                btnMotorHorario.text = getString(R.string.motor_btn_agitation_double)
                btn400RPM.text = getString(R.string.motor_btn_cent_double)
                btnMotorAntiHorario.visibility = View.GONE
                cmdMotorHorario = "d"
            }

            if ("SIMPLESCOR" == tipo) {
                btnMotorHorario.text = getString(R.string.motor_btn_agitation)
                btnMotorAntiHorario.visibility = View.GONE
                cmdMotorHorario = "d"
                cmdMotor400 = "2"
            }
        }
    }

    private fun mostrarPopupProgressoSamsung() {
        val inflater = LayoutInflater.from(this)
        val view = inflater.inflate(R.layout.dialog_progresso_samsung, null)

        progressBarSamsung = view.findViewById(R.id.progressSamsung)
        txtProgressoEtapa = view.findViewById(R.id.txtProgressoEtapa)

        val builder = AlertDialog.Builder(this)
        builder.setView(view)
        builder.setCancelable(false)

        dialogProgresso = builder.create()
        dialogProgresso?.show()
    }

    override fun onDestroy() {
        if (dialogProgresso?.isShowing == true) {
            dialogProgresso?.dismiss()
        }

        super.onDestroy()
        if (isBound) {
            unbindService(serviceConnection)
        }

        cancelarTimeoutAgitacao()
        cancelarTimeoutSamsung()
    }

    private fun iniciarTimeoutSamsung() {
        cancelarTimeoutSamsung()

        timeoutRunnable = Runnable {
            if (dialogProgresso?.isShowing == true) {
                dialogProgresso?.dismiss()
            }

            enviarComando("p")
            mostrarPopupErro("AC6", getString(R.string.motor_timeout_error))
        }

        timeoutHandler.postDelayed(timeoutRunnable!!, TIMEOUT_C_SAMSUNG)
    }

    private fun cancelarTimeoutSamsung() {
        timeoutRunnable?.let {
            timeoutHandler.removeCallbacks(it)
            timeoutRunnable = null
        }
    }

    private fun applySavedLocale() {
        val prefs = getSharedPreferences("Settings", MODE_PRIVATE)
        val langCode = prefs.getString("app_lang", "PT_BR")

        val locale = when (langCode) {
            "ENG" -> Locale("en", "US")
            "ESP" -> Locale("es", "ES")
            else -> Locale("pt", "BR")
        }

        Locale.setDefault(locale)
        val config = Configuration()
        config.setLocale(locale)
        resources.updateConfiguration(config, resources.displayMetrics)
    }

    private fun mostrarAvisoPeso() {
        AlertDialog.Builder(this)
            .setTitle(getString(R.string.aviso_peso_titulo))
            .setMessage(getString(R.string.aviso_peso_corpo))
            .setPositiveButton(getString(R.string.btn_ciente)) { _, _ ->
                enviarComando(cmdMotor1000)
            }
            .setNegativeButton(getString(R.string.btn_cancelar)) { dialog, _ -> dialog.dismiss() }
            .setIcon(android.R.drawable.ic_dialog_alert)
            .show()
    }

    private fun iniciarTimeoutAgitacao() {
        cancelarTimeoutAgitacao()

        timeoutAgitRunnable = Runnable {
            enviarComando("p")
            mostrarPopupAtualizacaoConserlar()
        }

        timeoutAgitHandler.postDelayed(timeoutAgitRunnable!!, TIMEOUT_AGITACAO_MIDEA)
    }

    private fun cancelarTimeoutAgitacao() {
        timeoutAgitRunnable?.let {
            timeoutAgitHandler.removeCallbacks(it)
            timeoutAgitRunnable = null
        }
    }

    private fun mostrarPopupAtualizacaoConserlar() {
        AlertDialog.Builder(this)
            .setTitle("Atualização Necessária")
            .setMessage("Seu testador precisa de uma atualização de firmware para executar o modo de Agitação Midea.\n\nEntre em contato com a CONSERLAR para atualizar seu equipamento.")
            .setPositiveButton("Falar com Conserlar") { _, _ ->
                try {
                    val intent = Intent(Intent.ACTION_VIEW, Uri.parse("https://api.whatsapp.com/send?phone=5521974638694"))
                    startActivity(intent)
                } catch (e: Exception) {
                    Toast.makeText(this, "Não foi possível abrir o WhatsApp", Toast.LENGTH_SHORT).show()
                }
            }
            .setNegativeButton("Fechar") { dialog, _ -> dialog.dismiss() }
            .setIcon(android.R.drawable.ic_dialog_alert)
            .show()
    }
}
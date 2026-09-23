package com.rladmc.pdfconserlar

import android.app.AlertDialog
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.content.SharedPreferences
import android.content.res.Configuration
import android.graphics.Color
import android.graphics.PorterDuff
import android.graphics.PorterDuffColorFilter
import android.os.Bundle
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.view.Gravity
import android.view.View
import android.widget.LinearLayout
import android.widget.TextView
import androidx.activity.OnBackPressedCallback
import androidx.appcompat.app.AppCompatActivity
import com.airbnb.lottie.LottieAnimationView
import com.airbnb.lottie.LottieProperty
import com.airbnb.lottie.model.KeyPath
import java.util.Locale

class MenuPrincipalActivity2 : AppCompatActivity() {

    private var bluetoothService: BluetoothService? = null
    private var isBound = false
    private var popupDialog: AlertDialog? = null

    private lateinit var lottieAnim: LottieAnimationView
    private lateinit var txtStatus: TextView
    private var txtSubStatus: TextView? = null
    private var recebeuOK = false

    private val handlerTimers = Handler(Looper.getMainLooper())
    private var timeoutOK: Runnable? = null
    private var timeoutC: Runnable? = null

    private lateinit var cardMidea1: LinearLayout
    private lateinit var cardMidea2: LinearLayout
    private lateinit var cardPhilco1: LinearLayout
    private lateinit var cardPhilco2: LinearLayout
    private lateinit var cardHisense1: LinearLayout
    private lateinit var cardSamsung1: LinearLayout

    private val serviceConnection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName, service: IBinder) {
            val binder = service as BluetoothService.LocalBinder
            bluetoothService = binder.getService()
            isBound = true
            enviarComando("z")
        }

        override fun onServiceDisconnected(name: ComponentName) {
            isBound = false
        }
    }

    companion object {
        private var instance: MenuPrincipalActivity2? = null

        @JvmStatic
        fun processarMensagem(mensagem: String) {
            android.util.Log.d("DEBUG_BLUETOOTH", "Recebido: [$mensagem]")
            instance?.let { activity ->
                Handler(Looper.getMainLooper()).post {
                    activity.tratarDadosBluetooth(mensagem)
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        applySavedLocale()
        super.onCreate(savedInstanceState)
        supportActionBar?.hide()
        setContentView(R.layout.menu_principal2)

        inicializarViews()
        configurarListeners()
        configurarBotaoVoltar()

        val serviceIntent = Intent(this, BluetoothService::class.java)
        startService(serviceIntent)
        bindService(serviceIntent, serviceConnection, Context.BIND_AUTO_CREATE)
    }

    override fun onResume() {
        super.onResume()
        instance = this
    }

    override fun onPause() {
        super.onPause()
        instance = null
    }

    private fun tratarDadosBluetooth(dados: String) {
        if (popupDialog == null || popupDialog?.isShowing != true) return
        val msg = dados.trim()

        // 1. RECEBEU "OK"
        if (msg.equals("OK", ignoreCase = true)) {
            recebeuOK = true
            timeoutOK?.let { handlerTimers.removeCallbacks(it) }

            popupDialog?.setTitle(getString(R.string.sim_status_connected))
            txtStatus.text = getString(R.string.sim_msg_cable_detected)

            lottieAnim.speed = 0.5f
            lottieAnim.addValueCallback(
                KeyPath("**"),
                LottieProperty.COLOR_FILTER
            ) { PorterDuffColorFilter(Color.GREEN, PorterDuff.Mode.SRC_ATOP) }

            iniciarMonitoramentoC()
        }

        // 2. RECEBEU "C" (RECONEXÃO)
        if (msg.contains("C")) {
            timeoutOK?.let { handlerTimers.removeCallbacks(it) }

            if (!recebeuOK) {
                iniciarMonitoramentoC()
                recebeuOK = true
            }

            resetarTimerC()

            popupDialog?.setTitle(getString(R.string.sim_status_simulating))
            txtStatus.text = getString(R.string.sim_msg_active)

            lottieAnim.speed = 4.0f
            lottieAnim.addValueCallback(
                KeyPath("**"),
                LottieProperty.COLOR_FILTER
            ) { PorterDuffColorFilter(Color.GREEN, PorterDuff.Mode.SRC_ATOP) }

            popupDialog?.getButton(AlertDialog.BUTTON_POSITIVE)?.visibility = View.VISIBLE
            popupDialog?.setCancelable(true)
        }

        if (msg.matches(".*\\d.*".toRegex())) {
            resetarTimerC()

            txtSubStatus?.let {
                it.text = "Tensão de Comunicação:\n $msg${if (msg.contains(" V")) "" else " V"}"
                it.setTextColor(Color.RED)
            }
        }
    }

    private fun iniciarMonitoramentoC() {
        timeoutC?.let { handlerTimers.removeCallbacks(it) }
        timeoutC = Runnable {
            lottieAnim.speed = 0f

            lottieAnim.addValueCallback(
                KeyPath("**"),
                LottieProperty.COLOR_FILTER
            ) { PorterDuffColorFilter(Color.WHITE, PorterDuff.Mode.SRC_ATOP) }

            popupDialog?.setTitle(getString(R.string.sim_status_lost))
            txtStatus.text = getString(R.string.sim_msg_check_washer)
            popupDialog?.getButton(AlertDialog.BUTTON_POSITIVE)?.visibility = View.VISIBLE
        }
        handlerTimers.postDelayed(timeoutC!!, 10000)
    }

    private fun resetarTimerC() {
        timeoutC?.let {
            handlerTimers.removeCallbacks(it)
            handlerTimers.postDelayed(it, 5000)
        }
    }

    private fun mostrarPopupAguardando(titulo: String, comando: String) {
        recebeuOK = false
        enviarComando(comando)

        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(50, 50, 50, 50)
            gravity = Gravity.CENTER
        }

        lottieAnim = LottieAnimationView(this).apply {
            setAnimation(R.raw.circuit_animation)
            layoutParams = LinearLayout.LayoutParams(800, 800)
            repeatCount = -1
            speed = 0f
            playAnimation()
            addValueCallback(
                KeyPath("**"),
                LottieProperty.COLOR_FILTER
            ) { PorterDuffColorFilter(Color.GRAY, PorterDuff.Mode.SRC_ATOP) }
        }

        txtStatus = TextView(this).apply {
            text = getString(R.string.sim_msg_trying)
            gravity = Gravity.CENTER
        }

        if (titulo != "Samsung" && titulo != "Midea MF") {
            txtSubStatus = TextView(this).apply {
                text = "Tensão da Comunicação"
                gravity = Gravity.CENTER
                setPadding(0, 20, 0, 0)
                textSize = 20f
            }
            layout.addView(txtSubStatus)
        } else {
            txtSubStatus = null
        }

        layout.addView(lottieAnim)
        layout.addView(txtStatus)

        val builder = AlertDialog.Builder(this).apply {
            setTitle(titulo)
            setView(layout)
            setCancelable(true)
            setPositiveButton("FECHAR") { dialog, _ ->
                pararTodosOsTimers()
                dialog.dismiss()
            }
        }

        popupDialog = builder.create()
        popupDialog?.setOnCancelListener { pararTodosOsTimers() }
        popupDialog?.show()

        timeoutOK = Runnable {
            if (!recebeuOK && popupDialog?.isShowing == true) {
                lottieAnim.speed = 0f
                lottieAnim.addValueCallback(
                    KeyPath("**"),
                    LottieProperty.COLOR_FILTER
                ) { PorterDuffColorFilter(Color.RED, PorterDuff.Mode.SRC_ATOP) }
                popupDialog?.setTitle(getString(R.string.sim_status_error_init))
                txtStatus.text = getString(R.string.sim_msg_no_response)
                popupDialog?.getButton(AlertDialog.BUTTON_POSITIVE)?.visibility = View.VISIBLE
            }
        }
        handlerTimers.postDelayed(timeoutOK!!, 120000)
    }

    private fun pararTodosOsTimers() {
        timeoutOK?.let { handlerTimers.removeCallbacks(it) }
        timeoutC?.let { handlerTimers.removeCallbacks(it) }
        enviarComando("0")
    }

    private fun inicializarViews() {
        cardMidea1 = findViewById(R.id.cardMidea1)
        cardMidea2 = findViewById(R.id.cardMidea2)
        cardPhilco1 = findViewById(R.id.cardPhilco1)
        cardPhilco2 = findViewById(R.id.cardPhilco2)
        cardHisense1 = findViewById(R.id.cardHisense1)
        cardSamsung1 = findViewById(R.id.cardSamsung1)
    }

    private fun enviarComando(comando: String) {
        if (isBound && bluetoothService != null) {
            bluetoothService?.write(comando)
        }
    }

    private fun configurarListeners() {
        cardMidea1.setOnClickListener { mostrarPopupAguardando("Midea LS", "6") }
        cardMidea2.setOnClickListener { mostrarPopupAguardando("Midea MF", "7") }
        cardPhilco1.setOnClickListener { mostrarPopupAguardando("Philco PLS11", "8") }
        cardPhilco2.setOnClickListener { mostrarPopupAguardando("Philco PLS12", "6") }
        cardHisense1.setOnClickListener { mostrarPopupAguardando("Hisense", "9") }
        cardSamsung1.setOnClickListener { mostrarPopupAguardando("Samsung", "5") }
    }

    private fun configurarBotaoVoltar() {
        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                if (popupDialog != null && popupDialog?.isShowing == true) {
                    popupDialog?.dismiss()
                    return
                }

                if (isBound) {
                    unbindService(serviceConnection)
                    isBound = false
                }

                val serviceIntent = Intent(this@MenuPrincipalActivity2, BluetoothService::class.java)
                stopService(serviceIntent)

                finish()
            }
        })
    }

    override fun onDestroy() {
        super.onDestroy()
        handlerTimers.removeCallbacksAndMessages(null)
        popupDialog?.dismiss()
    }

    private fun applySavedLocale() {
        val prefs = getSharedPreferences("Settings", MODE_PRIVATE)
        val langCode = prefs.getString("app_lang", "PT_BR") ?: "PT_BR"
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
}
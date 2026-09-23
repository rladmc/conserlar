package com.rladmc.pdfconserlar

import android.app.Service
import android.bluetooth.BluetoothSocket
import android.content.Intent
import android.content.res.Configuration
import android.os.Binder
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import java.io.IOException
import java.io.InputStream
import java.io.OutputStream
import java.util.Locale

class BluetoothService : Service() {

    private val binder = LocalBinder()
    private var socket: BluetoothSocket? = null
    private var connectedThread: ConnectedThread? = null

    inner class LocalBinder : Binder() {
        fun getService(): BluetoothService = this@BluetoothService
    }

    override fun onBind(intent: Intent): IBinder {
        return binder
    }

    override fun onCreate() {
        applySavedLocale()
        super.onCreate()

        socket = BluetoothSocketHolder.getSocket()

        if (socket != null && socket?.isConnected == true) {
            startCommunication()
        } else {
            stopSelf()
        }
    }

    private fun startCommunication() {
        if (connectedThread == null) {
            val currentSocket = socket ?: return
            connectedThread = ConnectedThread(currentSocket)
            connectedThread?.start()
        }
    }

    fun write(data: String) {
        connectedThread?.write(data.toByteArray())
    }

    private fun stopCommunication() {
        if (connectedThread != null) {
            // Envia comando de encerramento para o hardware
            connectedThread?.write("w\n".toByteArray())

            // Aguarda o envio ser processado pelo hardware
            try {
                Thread.sleep(200)
            } catch (e: InterruptedException) {
                Thread.currentThread().interrupt()
            }

            connectedThread?.cancel()
            connectedThread = null
        }

        // Limpa a referência global para permitir nova conexão
        BluetoothSocketHolder.clearSocket()
        Log.i(TAG, "Conexão Bluetooth completamente resetada.")
    }

    override fun onDestroy() {
        stopCommunication()
        super.onDestroy()
    }

    fun notifyActivities(message: String) {
        // Descomente ou ajuste conforme as classes forem migradas para Kotlin
        // ControleMotorActivity.processarMensagem(message)
        // MenuPrincipalActivity2.processarMensagem(message)
        // testedeinterface.processarMensagem(message)
        // TelaTesteActivity.processarMensagemPainel(message)
        // TelaTesteActivity2.processarMensagemPainel(message)
    }

    private inner class ConnectedThread(private val mmSocket: BluetoothSocket) : Thread() {
        private var mmInStream: InputStream? = null
        private var mmOutStream: OutputStream? = null
        private val sb = StringBuilder()

        init {
            var tmpIn: InputStream? = null
            var tmpOut: OutputStream? = null
            try {
                tmpIn = mmSocket.inputStream
                tmpOut = mmSocket.outputStream
            } catch (e: IOException) {
                Log.e(TAG, "Erro streams I/O", e)
            }
            mmInStream = tmpIn
            mmOutStream = tmpOut
        }

        override fun run() {
            val buffer = ByteArray(1024)
            var bytes: Int

            while (mmSocket.isConnected) {
                try {
                    val input = mmInStream ?: break
                    bytes = input.read(buffer)
                    if (bytes > 0) {
                        val incomingMessage = String(buffer, 0, bytes)
                        for (i in incomingMessage.indices) {
                            val ch = incomingMessage[i]
                            if (ch == '\n' || ch == '\r') {
                                if (sb.isNotEmpty()) {
                                    val msg = sb.toString().trim()
                                    Handler(Looper.getMainLooper()).post {
                                        if (msg.isNotEmpty()) notifyActivities(msg)
                                    }
                                    sb.setLength(0)
                                }
                            } else {
                                sb.append(ch)
                            }
                        }
                    }
                } catch (e: IOException) {
                    Log.e(TAG, "Desconectado durante a leitura.")
                    break
                }
            }
        }

        fun write(bytes: ByteArray) {
            try {
                mmOutStream?.let {
                    it.write(bytes)
                    it.flush()
                }
            } catch (e: IOException) {
                Log.e(TAG, "Erro envio", e)
            }
        }

        fun cancel() {
            try {
                mmInStream?.close()
                mmOutStream?.close()
                mmSocket.close()
            } catch (e: IOException) {
                Log.e(TAG, "Erro ao fechar thread", e)
            }
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

    companion object {
        private const val TAG = "BluetoothService"
    }
}
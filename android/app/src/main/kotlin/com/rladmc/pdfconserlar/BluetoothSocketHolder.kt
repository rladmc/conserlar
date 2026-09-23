package com.rladmc.pdfconserlar

import android.bluetooth.BluetoothSocket
import android.util.Log
import java.io.IOException

/**
 * Utilitário Singleton para manter e transferir o BluetoothSocket entre Activities e Services.
 */
object BluetoothSocketHolder {
    private var socket: BluetoothSocket? = null

    @Synchronized
    fun setSocket(s: BluetoothSocket?) {
        socket = s
    }

    @Synchronized
    fun getSocket(): BluetoothSocket? {
        return socket
    }

    @Synchronized
    fun clearSocket() {
        if (socket != null) {
            try {
                socket?.close()
                Log.d("BluetoothSocketHolder", "Socket fechado com sucesso.")
            } catch (e: IOException) {
                Log.e("BluetoothSocketHolder", "Erro ao fechar socket no clearSocket", e)
            }
        }
        socket = null
    }
}
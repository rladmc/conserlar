package com.rladmc.pdfconserlar

import android.Manifest
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothSocket
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.widget.ArrayAdapter
import android.widget.Button
import android.widget.ListView
import android.widget.TextView
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.core.app.ActivityCompat
import java.io.IOException
import java.util.UUID

class ConexaoActivity3 : AppCompatActivity() {

    private var bluetoothAdapter: BluetoothAdapter? = null
    private lateinit var dispositivosAdapter: ArrayAdapter<String>
    private val dispositivosList = ArrayList<BluetoothDevice>()

    private lateinit var btnListar: Button
    private lateinit var listaDispositivos: ListView
    private lateinit var txtStatus: TextView

    // Lançador moderno para substituir o onActivityResult obsoleto
    private val enableBtLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        if (result.resultCode == Activity.RESULT_OK) {
            listarDispositivos()
        }
    }

    companion object {
        private val MY_UUID: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
        private const val REQUEST_BLUETOOTH_SCAN = 4
        private const val TAG = "ConexaoActivity3"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        supportActionBar?.hide()
        setContentView(R.layout.tela_conexao)

        // Limpa qualquer socket antigo que possa ter ficado preso ao abrir esta tela
        BluetoothSocketHolder.clearSocket()

        btnListar = findViewById(R.id.btnListarPareados)
        listaDispositivos = findViewById(R.id.listViewDispositivos)
        txtStatus = findViewById(R.id.textViewStatus)

        dispositivosAdapter = ArrayAdapter(this, R.layout.list_item_bluetooth)
        listaDispositivos.adapter = dispositivosAdapter

        bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
        if (bluetoothAdapter == null) {
            Toast.makeText(this, getString(R.string.bt_not_supported), Toast.LENGTH_LONG).show()
            finish()
            return
        }

        btnListar.setOnClickListener { listarDispositivos() }

        listaDispositivos.setOnItemClickListener { _, _, position, _ ->
            if (position < dispositivosList.size) {
                conectarDispositivo(dispositivosList[position])
            }
        }

        listarDispositivos()
    }

    private fun listarDispositivos() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (ActivityCompat.checkSelfPermission(
                    this,
                    Manifest.permission.BLUETOOTH_CONNECT
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(
                        Manifest.permission.BLUETOOTH_CONNECT,
                        Manifest.permission.BLUETOOTH_SCAN
                    ),
                    REQUEST_BLUETOOTH_SCAN
                )
                return
            }
        }

        val adapter = bluetoothAdapter ?: return
        if (!adapter.isEnabled) {
            val enableBtIntent = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
            enableBtLauncher.launch(enableBtIntent)
            return
        }

        dispositivosAdapter.clear()
        dispositivosList.clear()

        val dispositivosPareados: Set<BluetoothDevice>? = adapter.bondedDevices
        if (!dispositivosPareados.isNullOrEmpty()) {
            for (device in dispositivosPareados) {
                val nome = device.name ?: getString(R.string.bt_unknown_device)
                dispositivosAdapter.add("$nome\n${device.address}")
                dispositivosList.add(device)
            }
            txtStatus.text = getString(R.string.bt_found_paired)
        } else {
            txtStatus.text = getString(R.string.bt_none_paired)
            Toast.makeText(this, getString(R.string.bt_must_pair_settings), Toast.LENGTH_LONG).show()
        }
    }

    private fun conectarDispositivo(device: BluetoothDevice) {
        txtStatus.text = getString(R.string.bt_connecting)

        Thread {
            var tempSocket: BluetoothSocket? = null
            val adapter = bluetoothAdapter ?: return@Thread

            try {
                // 1. Cancela busca (essencial)
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
                    ActivityCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_SCAN) == PackageManager.PERMISSION_GRANTED
                ) {
                    adapter.cancelDiscovery()
                }

                // 2. Limpa o Holder antes de tudo
                BluetoothSocketHolder.clearSocket()

                // 3. Tenta conexão padrão
                tempSocket = device.createRfcommSocketToServiceRecord(MY_UUID)
                tempSocket?.connect()

            } catch (e: IOException) {
                Log.e(TAG, "Conexão padrão falhou, tentando fallback...", e)

                // 4. FALLBACK: Tenta conectar via Reflection (ignora restrições de porta)
                try {
                    val method = device.javaClass.getMethod("createRfcommSocket", Int::class.javaPrimitiveType)
                    tempSocket = method.invoke(device, 1) as BluetoothSocket
                    tempSocket?.connect()
                } catch (e2: Exception) {
                    Log.e(TAG, "Fallback também falhou.", e2)

                    runOnUiThread {
                        txtStatus.text = "Erro total na conexão."
                        Toast.makeText(
                            this,
                            "A ESP32 ainda está ocupada. Tente em 5 segundos.",
                            Toast.LENGTH_LONG
                        ).show()
                    }
                    return@Thread
                }
            }

            // Se chegou aqui, conectou com sucesso (seja padrão ou fallback)
            val finalSocket = tempSocket
            if (finalSocket != null) {
                runOnUiThread {
                    txtStatus.text = "Conectado!"
                    navigateToControl(finalSocket)
                }
            }
        }.start()
    }

    private fun navigateToControl(socket: BluetoothSocket) {
        // Salva o novo socket no Holder para o Service usar
        BluetoothSocketHolder.setSocket(socket)
        val intent = Intent(this, MenuPrincipalActivity2::class.java)
        startActivity(intent)
        finish()
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_BLUETOOTH_SCAN &&
            grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED
        ) {
            listarDispositivos()
        }
    }
}
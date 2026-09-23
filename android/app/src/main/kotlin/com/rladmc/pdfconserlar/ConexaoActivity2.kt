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

class ConexaoActivity2 : AppCompatActivity() {

    private var bluetoothAdapter: BluetoothAdapter? = null
    private lateinit var dispositivosAdapter: ArrayAdapter<String>
    private val dispositivosList = ArrayList<BluetoothDevice>()

    private lateinit var btnListar: Button
    private lateinit var listaDispositivos: ListView
    private lateinit var txtStatus: TextView

    private val MY_UUID: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
    private val REQUEST_BLUETOOTH_SCAN = 4

    private val enableBtLauncher = registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { result ->
        if (result.resultCode == Activity.RESULT_OK) {
            listarDispositivos()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        supportActionBar?.hide()
        setContentView(R.layout.tela_conexao)

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
            if (ActivityCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED) {
                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(Manifest.permission.BLUETOOTH_CONNECT, Manifest.permission.BLUETOOTH_SCAN),
                    REQUEST_BLUETOOTH_SCAN
                )
                return
            }
        }

        val btAdapter = bluetoothAdapter ?: return
        if (!btAdapter.isEnabled) {
            val enableBtIntent = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
            enableBtLauncher.launch(enableBtIntent)
            return
        }

        dispositivosAdapter.clear()
        dispositivosList.clear()

        val dispositivosPareados: Set<BluetoothDevice>? = btAdapter.bondedDevices
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
        Toast.makeText(this, "Conectando a ${device.name ?: "Dispositivo"}...", Toast.LENGTH_SHORT).show()

        Thread {
            var tempSocket: BluetoothSocket? = null
            try {
                bluetoothAdapter?.cancelDiscovery()
                BluetoothSocketHolder.clearSocket()

                // Tenta a conexão segura padrão
                tempSocket = device.createRfcommSocketToServiceRecord(MY_UUID)
                tempSocket?.connect()
            } catch (e: IOException) {
                Log.e("BT_ERROR", "Conexão padrão falhou, tentando fallback...", e)
                try {
                    // Tenta o método de reflexão (fallback para ESP32)
                    val method = device.javaClass.getMethod("createRfcommSocket", Int::class.javaPrimitiveType)
                    tempSocket = method.invoke(device, 1) as BluetoothSocket
                    tempSocket?.connect()
                } catch (e2: Exception) {
                    Log.e("BT_ERROR", "Fallback também falhou.", e2)
                    try {
                        tempSocket?.close()
                    } catch (ex: Exception) { }

                    runOnUiThread {
                        txtStatus.text = "Erro total na conexão."
                        Toast.makeText(this, "A ESP32 ainda está ocupada. Tente em 5 segundos.", Toast.LENGTH_LONG).show()
                    }
                    return@Thread
                }
            }

            val finalSocket = tempSocket
            if (finalSocket != null && finalSocket.isConnected) {
                runOnUiThread {
                    txtStatus.text = "Conectado!"
                    navigateToControl(finalSocket)
                }
            } else {
                runOnUiThread {
                    txtStatus.text = "Erro na conexão."
                    Toast.makeText(this, "Não foi possível estabelecer o socket.", Toast.LENGTH_SHORT).show()
                }
            }
        }.start()
    }

    private fun navigateToControl(socket: BluetoothSocket?) {
        BluetoothSocketHolder.setSocket(socket)
        // Corrigido para ir corretamente para o MenuPrincipalActivity como no seu código original
        val intent = Intent(this, MenuPrincipalActivity::class.java)
        startActivity(intent)
        finish()
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_BLUETOOTH_SCAN && grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            listarDispositivos()
        }
    }
}
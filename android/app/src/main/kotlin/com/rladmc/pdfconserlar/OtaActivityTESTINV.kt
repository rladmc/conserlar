package com.rladmc.pdfconserlar

import android.Manifest
import android.bluetooth.BluetoothSocket
import android.content.Intent
import android.content.pm.PackageManager
import android.location.LocationManager
import android.net.*
import android.net.wifi.WifiNetworkSpecifier
import android.os.*
import android.provider.Settings
import android.util.Log
import android.os.PatternMatcher
import android.view.View
import android.widget.*
import androidx.appcompat.app.AppCompatActivity
import androidx.core.app.ActivityCompat
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import org.json.JSONObject
import java.io.IOException
import java.io.InputStream
import java.util.concurrent.TimeUnit

class OtaActivityTESTINV : AppCompatActivity() {

    private val TAG = "CONSERLAR_OTA"

    private lateinit var txtStatusOta: TextView
    private lateinit var progressOta: ProgressBar
    private lateinit var btnIniciarUpdate: Button

    private var socket: BluetoothSocket? = null
    private var isListening = false

    private var urlFirmwareSelecionado: String? = null
    private var atualizacaoConcluida = false

    private var connectivityManager: ConnectivityManager? = null
    private var networkCallback: ConnectivityManager.NetworkCallback? = null

    // 🌐 NOVA URL DO GOOGLE APPS SCRIPT
    private val LINK_API_CONSERLAR =
        "https://script.google.com/macros/s/AKfycbxWOaNg2iYseVQOk2ceIqVzeBKcbBOaW-oMtFe22YVPrpmKww2NY6qroSpgQe6jNAhq/exec"

    private val client = OkHttpClient.Builder()
        .connectTimeout(90, TimeUnit.SECONDS)
        .writeTimeout(90, TimeUnit.SECONDS)
        .readTimeout(90, TimeUnit.SECONDS)
        .retryOnConnectionFailure(true)
        .build()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContentView(R.layout.activity_ota)

        txtStatusOta = findViewById(R.id.txtStatusOta)
        progressOta = findViewById(R.id.progressOta)
        btnIniciarUpdate = findViewById(R.id.btnIniciarUpdate)

        socket = BluetoothSocketHolder.getSocket()

        solicitarPermissoes()

        if (socket == null || !socket!!.isConnected) {
            txtStatusOta.text = "Erro: placa não conectada."
            btnIniciarUpdate.visibility = View.GONE
            return
        }

        btnIniciarUpdate.visibility = View.GONE

        btnIniciarUpdate.setOnClickListener {
            if (atualizacaoConcluida) {
                voltarParaScan()
            } else {
                iniciarFluxoDeAtualizacao()
            }
        }

        startBluetoothListening()

        enviarComandoBluetooth("z\n")
        enviarComandoBluetooth("V\n")

        // 📶 Pega o Endereço MAC do Bluetooth da ESP32 conectada
        val macBluetoothEsp32 = socket?.remoteDevice?.address ?: ""

        if (macBluetoothEsp32.isEmpty()) {
            txtStatusOta.text = "Erro: MAC Bluetooth não identificado."
            return
        }

        txtStatusOta.text = "Validando autorização..."

        // Envia o MAC da ESP32 para a API
        verificarAutorizacaoNaAPI(macBluetoothEsp32)
    }

    private fun solicitarPermissoes() {
        val permissoes = mutableListOf<String>()

        if (
            ActivityCompat.checkSelfPermission(
                this,
                Manifest.permission.ACCESS_FINE_LOCATION
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            permissoes.add(Manifest.permission.ACCESS_FINE_LOCATION)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (
                ActivityCompat.checkSelfPermission(
                    this,
                    Manifest.permission.NEARBY_WIFI_DEVICES
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                permissoes.add(Manifest.permission.NEARBY_WIFI_DEVICES)
            }
        }

        if (permissoes.isNotEmpty()) {
            ActivityCompat.requestPermissions(
                this,
                permissoes.toTypedArray(),
                100
            )
        }
    }

    private fun startBluetoothListening() {
        isListening = true

        Thread {
            val buffer = ByteArray(1024)

            val inputStream: InputStream? = try {
                socket?.inputStream
            } catch (e: IOException) {
                null
            }

            while (isListening && inputStream != null) {
                try {
                    val bytes = inputStream.read(buffer)

                    if (bytes > 0) {
                        val resposta = String(buffer, 0, bytes).trim()

                        if (resposta.isNotEmpty()) {
                            Log.d(TAG, "ESP32: $resposta")

                            // Verificar se o texto recebido tem formato de versão (ex: 1.0.0 ou 2.1.5)
                            if (resposta.matches(Regex("\\d+\\.\\d+\\.\\d+"))) {

                                val prefs = getSharedPreferences("FIRMWARE_PREFS", MODE_PRIVATE)
                                val savedVersion = prefs.getString("SAVED_FIRMWARE_VERSION", "N/A")

                                if (resposta != savedVersion) {
                                    prefs.edit().putString("SAVED_FIRMWARE_VERSION", resposta).apply()
                                    Log.d(TAG, "Nova versão gravada com sucesso: $resposta")
                                }
                            }
                        }
                    }

                } catch (e: IOException) {
                    Log.e(TAG, "Bluetooth encerrado")
                    break
                }
            }
        }.start()
    }

    private fun verificarAutorizacaoNaAPI(macBluetooth: String) {
        Thread {
            try {
                // Envia o macBt e o tipo=TESTINV para bater exatamente com a nova função do Apps Script
                val urlCompleta =
                    "$LINK_API_CONSERLAR?macBt=$macBluetooth&tipo=TESTINV"

                Log.d(TAG, "Chamando API: $urlCompleta")

                val request = Request.Builder()
                    .url(urlCompleta)
                    .build()

                client.newCall(request)
                    .execute()
                    .use { response ->

                        if (!response.isSuccessful) {
                            throw IOException("Erro rede: ${response.code}")
                        }

                        val respostaRaw = response.body?.string() ?: ""
                        val jsonResponse = JSONObject(respostaRaw)
                        val status = jsonResponse.optString("status", "erro")

                        runOnUiThread {
                            if (status == "sucesso") {
                                urlFirmwareSelecionado = jsonResponse.getString("url")
                                txtStatusOta.text = "Atualização disponível"
                                btnIniciarUpdate.visibility = View.VISIBLE
                            } else {
                                txtStatusOta.text = "Dispositivo não autorizado"
                                btnIniciarUpdate.visibility = View.GONE
                            }
                        }
                    }

            } catch (e: Exception) {
                Log.e(TAG, "Erro API", e)

                runOnUiThread {
                    txtStatusOta.text = "Erro servidor"
                }
            }
        }.start()
    }

    private fun iniciarFluxoDeAtualizacao() {
        if (urlFirmwareSelecionado == null) return

        btnIniciarUpdate.isEnabled = false
        progressOta.isIndeterminate = true
        txtStatusOta.text = "Preparando Testador..."

        Log.d(TAG, "Enviando comando OTA")
        enviarComandoBluetooth("i\n")

        Handler(Looper.getMainLooper()).postDelayed({
            txtStatusOta.text = "Baixando firmware..."

            val request = Request.Builder()
                .url(urlFirmwareSelecionado!!)
                .build()

            client.newCall(request)
                .enqueue(object : Callback {
                    override fun onFailure(call: Call, e: IOException) {
                        Log.e(TAG, "Erro download", e)

                        runOnUiThread {
                            txtStatusOta.text = "Erro download firmware"
                            btnIniciarUpdate.isEnabled = true
                        }
                    }

                    override fun onResponse(call: Call, response: Response) {
                        val bytes = response.body?.bytes()

                        if (response.isSuccessful && bytes != null) {
                            Log.d(TAG, "Firmware baixado: ${bytes.size} bytes")

                            runOnUiThread {
                                txtStatusOta.text = "Conectando WiFi ..."
                                conectarWifiEEnviar(bytes)
                            }
                        } else {
                            runOnUiThread {
                                txtStatusOta.text = "Falha download"
                                btnIniciarUpdate.isEnabled = true
                            }
                        }
                    }
                })
        }, 6000)
    }

    private fun conectarWifiEEnviar(dadosFirmware: ByteArray) {
        val lm = getSystemService(LOCATION_SERVICE) as LocationManager

        if (!lm.isProviderEnabled(LocationManager.GPS_PROVIDER)) {
            txtStatusOta.text = "Ative o GPS"
            btnIniciarUpdate.isEnabled = true
            return
        }

        liberarRede()

        val specifier = WifiNetworkSpecifier.Builder()
            .setSsidPattern(
                PatternMatcher(
                    "CONSERSCAN_UPDATE_TESTINV",
                    PatternMatcher.PATTERN_PREFIX
                )
            )
            .setWpa2Passphrase("conserlar123")
            .build()

        val request = NetworkRequest.Builder()
            .addTransportType(NetworkCapabilities.TRANSPORT_WIFI)
            .removeCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            .setNetworkSpecifier(specifier)
            .build()

        connectivityManager = getSystemService(CONNECTIVITY_SERVICE) as ConnectivityManager

        txtStatusOta.text = "Buscando WiFi da placa..."

        networkCallback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                super.onAvailable(network)

                Log.d(TAG, "WiFi conectado")

                val bind = connectivityManager?.bindProcessToNetwork(network)
                Log.d(TAG, "Bind: $bind")

                Handler(Looper.getMainLooper()).postDelayed({
                    runOnUiThread {
                        txtStatusOta.text = "Enviando firmware..."
                        uploadHttpFinal(dadosFirmware, network)
                    }
                }, 3000)
            }

            override fun onUnavailable() {
                super.onUnavailable()

                Log.e(TAG, "WiFi não encontrado")

                runOnUiThread {
                    txtStatusOta.text = "Testador não encontrado"
                    btnIniciarUpdate.isEnabled = true
                }

                liberarRede()
            }
        }

        try {
            connectivityManager?.requestNetwork(request, networkCallback!!)
        } catch (e: Exception) {
            Log.e(TAG, "Erro requestNetwork", e)

            txtStatusOta.text = "Erro conexão WiFi"
            btnIniciarUpdate.isEnabled = true
        }
    }

    private fun uploadHttpFinal(dados: ByteArray, network: Network) {
        Log.d(TAG, "Iniciando OTA")

        val mediaType = "application/octet-stream".toMediaTypeOrNull()
        val arquivoBody = RequestBody.create(mediaType, dados)

        val multipart = MultipartBody.Builder()
            .setType(MultipartBody.FORM)
            .addFormDataPart("update", "firmware.bin", arquivoBody)
            .build()

        val request = Request.Builder()
            .url("http://192.168.4.1/update")
            .header("Connection", "close")
            .post(multipart)
            .build()

        val clientOta = OkHttpClient.Builder()
            .socketFactory(network.socketFactory)
            .connectTimeout(30, TimeUnit.SECONDS)
            .writeTimeout(120, TimeUnit.SECONDS)
            .readTimeout(60, TimeUnit.SECONDS)
            .retryOnConnectionFailure(false)
            .build()

        clientOta.newCall(request)
            .enqueue(object : Callback {
                override fun onFailure(call: Call, e: IOException) {
                    Log.e(TAG, "Falha OTA", e)

                    runOnUiThread {
                        txtStatusOta.text = "Erro OTA: ${e.localizedMessage}"
                        btnIniciarUpdate.isEnabled = true
                    }

                    liberarRede()
                }

                override fun onResponse(call: Call, response: Response) {
                    val resposta = response.body?.string()?.trim() ?: ""

                    Log.d(TAG, "HTTP ${response.code}")
                    Log.d(TAG, "Resposta: $resposta")

                    runOnUiThread {
                        if (response.isSuccessful && resposta.contains("OK")) {
                            progressOta.isIndeterminate = false
                            progressOta.progress = 100

                            txtStatusOta.text = "Atualização concluída"
                            atualizacaoConcluida = true

                            btnIniciarUpdate.text = "CONCLUÍDO - VOLTAR"
                            btnIniciarUpdate.isEnabled = true
                        } else {
                            txtStatusOta.text = "Erro gravação OTA"
                            btnIniciarUpdate.isEnabled = true
                        }

                        liberarRede()
                    }
                }
            })
    }

    private fun enviarComandoBluetooth(comando: String): Boolean {
        return try {
            val out = socket?.outputStream
            out?.write(comando.toByteArray())
            out?.flush()

            Log.d(TAG, "Bluetooth enviado: $comando")
            true
        } catch (e: IOException) {
            Log.e(TAG, "Erro Bluetooth", e)
            false
        }
    }

    private fun liberarRede() {
        try {
            connectivityManager?.bindProcessToNetwork(null)
            networkCallback?.let {
                connectivityManager?.unregisterNetworkCallback(it)
            }
            networkCallback = null
        } catch (e: Exception) {
            Log.e(TAG, "Erro liberar rede", e)
        }
    }

    private fun voltarParaScan() {
        liberarRede()
        isListening = false

        try {
            socket?.close()
            BluetoothSocketHolder.setSocket(null)
        } catch (_: Exception) {
        }

        val intent = Intent(this, ScanInversoraActivity::class.java)
        intent.flags = Intent.FLAG_ACTIVITY_CLEAR_TOP
        startActivity(intent)
        finish()
    }

    override fun onDestroy() {
        super.onDestroy()
        isListening = false
        liberarRede()
    }
}
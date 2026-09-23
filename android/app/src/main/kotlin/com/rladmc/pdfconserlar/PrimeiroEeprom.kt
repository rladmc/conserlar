package com.rladmc.pdfconserlar

import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.net.wifi.WifiNetworkSpecifier
import android.os.Build
import android.os.Bundle
import android.view.View
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat

class PrimeiroEeprom : AppCompatActivity() {

    private lateinit var rootLayout: LinearLayout
    private lateinit var webView: WebView
    private lateinit var progressBar: ProgressBar

    private var connectivityManager: ConnectivityManager? = null
    private var networkCallback: ConnectivityManager.NetworkCallback? = null

    companion object {
        const val TARGET_SSID = "ConsertestScan - EEPROM"
        const val TARGET_PASSWORD = "" // Insira a senha se houver (ex: "12345678")
        const val TARGET_URL = "http://192.168.4.1"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_primeiro_eeprom)

        rootLayout = findViewById(R.id.rootLayout)
        webView = findViewById(R.id.webView)
        progressBar = findViewById(R.id.progressBar)

        // Aplica o padding exato para respeitar a Barra de Status (notch) e de Navegação
        ViewCompat.setOnApplyWindowInsetsListener(rootLayout) { _, insets ->
            val systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            rootLayout.setPadding(
                systemBars.left,
                systemBars.top,
                systemBars.right,
                systemBars.bottom
            )
            insets
        }

        configurarWebView()
        conectarAoTestadorEAbrir()
    }

    @SuppressLint("SetJavaScriptEnabled")
    private fun configurarWebView() {
        webView.settings.apply {
            javaScriptEnabled = true
            domStorageEnabled = true
            useWideViewPort = true
            loadWithOverviewMode = true
        }

        webView.webViewClient = object : WebViewClient() {
            override fun shouldOverrideUrlLoading(view: WebView?, request: WebResourceRequest?): Boolean {
                return false
            }

            override fun onPageFinished(view: WebView?, url: String?) {
                super.onPageFinished(view, url)
                // Oculta a barra de progresso assim que a interface do AP carregar
                progressBar.visibility = View.GONE

                // Detecta se o usuário clicou em salvar e a ESP32 respondeu na rota /salvar
                if (url != null && url.contains("/salvar")) {
                    view?.postDelayed({
                        val intent = Intent(this@PrimeiroEeprom, ConserTestActivity::class.java)
                        startActivity(intent)
                        finish()
                    }, 2000)
                }
            }
        }
    }

    private fun conectarAoTestadorEAbrir() {
        connectivityManager = getSystemService(CONNECTIVITY_SERVICE) as ConnectivityManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val specifierBuilder = WifiNetworkSpecifier.Builder()
                .setSsid(TARGET_SSID)

            if (TARGET_PASSWORD.isNotEmpty()) {
                specifierBuilder.setWpa2Passphrase(TARGET_PASSWORD)
            }

            val specifier = specifierBuilder.build()

            val request = NetworkRequest.Builder()
                .addTransportType(NetworkCapabilities.TRANSPORT_WIFI)
                .removeCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
                .setNetworkSpecifier(specifier)
                .build()

            networkCallback = object : ConnectivityManager.NetworkCallback() {
                override fun onAvailable(network: Network) {
                    super.onAvailable(network)
                    connectivityManager?.bindProcessToNetwork(network)

                    runOnUiThread {
                        Toast.makeText(applicationContext, "Conectado ao ConsertestScan!", Toast.LENGTH_SHORT).show()
                        webView.loadUrl(TARGET_URL)
                    }
                }

                override fun onUnavailable() {
                    super.onUnavailable()
                    runOnUiThread {
                        progressBar.visibility = View.GONE
                        Toast.makeText(applicationContext, "Não foi possível conectar ao testador.", Toast.LENGTH_LONG).show()
                    }
                }
            }

            connectivityManager?.requestNetwork(request, networkCallback as ConnectivityManager.NetworkCallback)

        } else {
            Toast.makeText(this, "Conecte manualmente à rede $TARGET_SSID", Toast.LENGTH_LONG).show()
            webView.loadUrl(TARGET_URL)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            connectivityManager?.bindProcessToNetwork(null)
        }
        networkCallback?.let {
            try {
                connectivityManager?.unregisterNetworkCallback(it)
            } catch (_: Exception) {}
        }
    }
}
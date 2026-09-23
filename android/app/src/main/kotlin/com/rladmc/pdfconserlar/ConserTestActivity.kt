package com.rladmc.pdfconserlar

import android.annotation.SuppressLint
import android.content.Intent
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import android.webkit.*
import androidx.appcompat.app.AppCompatActivity

class ConserTestActivity : AppCompatActivity() {

    private lateinit var webView: WebView

    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        // Bloqueia capturas de tela, prints e gravações no aplicativo
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )

        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_consertest)

        webView = findViewById(R.id.webview_consertest)

        // Configurações do WebView
        val settings: WebSettings = webView.settings
        settings.javaScriptEnabled = true
        settings.domStorageEnabled = true
        settings.databaseEnabled = true
        settings.useWideViewPort = true
        settings.loadWithOverviewMode = true
        settings.allowFileAccess = true
        settings.allowContentAccess = true

        // Força a navegação a permanecer no app e intercepta as URLs antes da navegação
        webView.webViewClient = object : WebViewClient() {

            override fun shouldOverrideUrlLoading(view: WebView?, request: WebResourceRequest?): Boolean {
                val url = request?.url?.toString() ?: ""

                // Intercepta qualquer chamada que contenha /resetwifi no momento do clique
                if (url.contains("/resetwifi")) {
                    // 1. Carrega a URL para a ESP32 receber a ordem de reset
                    view?.loadUrl(url)

                    // 2. Aguarda 1.5s para o envio do comando, abre a PrimeiroEeprom e fecha a atual
                    view?.postDelayed({
                        val intent = Intent(this@ConserTestActivity, PrimeiroEeprom::class.java)
                        startActivity(intent)
                        finish()
                    }, 1500)

                    return true // Indica que o clique foi tratado pelo aplicativo
                }

                // Carregamento padrão de outras URLs no WebView
                request?.url?.let { view?.loadUrl(it.toString()) }
                return true
            }

            // Android 6.0+ (API 23+)
            override fun onReceivedError(
                view: WebView?,
                request: WebResourceRequest,
                error: WebResourceError
            ) {
                super.onReceivedError(view, request, error)
                if (request.isForMainFrame) {
                    val descricao = error.description?.toString() ?: ""
                    exibirPaginaErroCustomizada(view, error.errorCode, descricao)
                }
            }

            // Versões antigas do Android
            @Suppress("DEPRECATION")
            override fun onReceivedError(
                view: WebView?,
                errorCode: Int,
                description: String?,
                failingUrl: String?
            ) {
                super.onReceivedError(view, errorCode, description, failingUrl)
                exibirPaginaErroCustomizada(view, errorCode, description ?: "")
            }
        }

        // Suporte para dialogs, uploads e carregamento
        webView.webChromeClient = WebChromeClient()

        // Carrega o site da aplicação com checagem prévia
        carregarUrlOuTratarErro("https://consertest.conserlar.com")
    }

    private fun carregarUrlOuTratarErro(url: String) {
        if (temConexaoComInternet()) {
            webView.loadUrl(url)
        } else {
            exibirPaginaErroCustomizada(
                webView,
                WebViewClient.ERROR_HOST_LOOKUP,
                "ERR_INTERNET_DISCONNECTED"
            )
        }
    }

    private fun exibirPaginaErroCustomizada(view: WebView?, errorCode: Int, errorDescription: String) {
        val descUpper = errorDescription.uppercase()

        val (titulo, mensagem) = when {
            descUpper.contains("ERR_INTERNET_DISCONNECTED") || !temConexaoComInternet() -> {
                Pair(
                    "Sem Conexão com a Internet",
                    "Dispositivo desconectado. Verifique se o Wi-Fi ou os dados móveis estão ativos no seu celular."
                )
            }
            descUpper.contains("ERR_ADDRESS_UNREACHABLE") -> {
                Pair(
                    "CONSER TEST SCAN Inacessível",
                    "Não foi possível se comunicar com o IP na rede. Verifique se o dispositivo está ligado e com o led inferior na cor magenta."
                )
            }
            descUpper.contains("ERR_CONNECTION_REFUSED") -> {
                Pair(
                    "Conexão Recusada",
                    "O IP foi encontrado, mas a porta ou o servidor recusou a conexão."
                )
            }
            errorCode == WebViewClient.ERROR_TIMEOUT || descUpper.contains("TIMED_OUT") -> {
                Pair(
                    "Tempo de Conexão Esgotado",
                    "O servidor demorou muito para responder. Verifique o estado da rede."
                )
            }
            else -> {
                Pair(
                    "Falha de Comunicação",
                    "Ocorreu um erro ao tentar conectar: $errorDescription"
                )
            }
        }

        val htmlErro = """
            <!DOCTYPE html>
            <html>
            <head>
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <style>
                    body {
                        font-family: Arial, sans-serif;
                        background-color: #121212;
                        color: #ffffff;
                        display: flex;
                        flex-direction: column;
                        align-items: center;
                        justify-content: center;
                        height: 100vh;
                        margin: 0;
                        text-align: center;
                        padding: 20px;
                        box-sizing: border-box;
                    }
                    h2 { color: #ff5252; margin-bottom: 10px; }
                    p { color: #b0bec5; font-size: 15px; margin-bottom: 25px; line-height: 1.4; }
                    .btn-recargar {
                        background-color: #0088cc;
                        color: white;
                        border: none;
                        padding: 12px 24px;
                        font-size: 16px;
                        font-weight: bold;
                        border-radius: 8px;
                        cursor: pointer;
                        box-shadow: 0 4px 6px rgba(0,0,0,0.3);
                    }
                    .btn-recargar:active { background-color: #006699; }
                </style>
            </head>
            <body>
                <h2>$titulo</h2>
                <p>$mensagem</p>
                <button class="btn-recargar" onclick="location.href='https://consertest.conserlar.com'">Tentar Novamente</button>
            </body>
            </html>
        """.trimIndent()

        view?.loadDataWithBaseURL(null, htmlErro, "text/html", "UTF-8", null)
    }

    private fun temConexaoComInternet(): Boolean {
        val connectivityManager = getSystemService(CONNECTIVITY_SERVICE) as ConnectivityManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val network = connectivityManager.activeNetwork ?: return false
            val activeNetwork = connectivityManager.getNetworkCapabilities(network) ?: return false
            return activeNetwork.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) ||
                    activeNetwork.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) ||
                    activeNetwork.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET)
        } else {
            @Suppress("DEPRECATION")
            val networkInfo = connectivityManager.activeNetworkInfo
            @Suppress("DEPRECATION")
            return networkInfo != null && networkInfo.isConnected
        }
    }

    override fun onBackPressed() {
        if (::webView.isInitialized && webView.canGoBack()) {
            webView.goBack()
        } else {
            super.onBackPressed()
        }
    }
}
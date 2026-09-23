package com.rladmc.pdfconserlar

import android.content.SharedPreferences
import android.content.res.Configuration
import android.os.Bundle
import android.text.Html
import android.text.method.LinkMovementMethod
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import java.util.Locale

class ManualActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        applySavedLocale()
        super.onCreate(savedInstanceState)
        supportActionBar?.hide()
        setContentView(R.layout.tela_manual)

        val txtLinks = findViewById<TextView>(R.id.linkText)
        if (txtLinks != null) {
            // Agora pegamos o texto traduzido antes de montar o link HTML
            val htmlLinks = ("<a href='https://www.youtube.com/watch?v=czeV6NdbSPE'>" + getString(R.string.video_test_lsd11) + "</a><br><br>"
                    + "<a href='https://www.youtube.com/watch?v=mw9bp1pl88I'>" + getString(R.string.video_test_lsx121) + "</a><br><br>"
                    + "<a href='https://www.youtube.com/watch?v=gKBZhKxwPRw'>" + getString(R.string.video_test_motors) + "</a><br><br>"
                    + "<a href='https://www.youtube.com/watch?v=GaJkY3vrWow'>" + getString(R.string.video_test_round) + "</a><br><br>"
                    + "<a href='https://www.youtube.com/watch?v=dPw1j7th33k'>MANUAL DE USUÁRIO 1 SAMSUNG</a><br><br>"
                    + "<a href='https://www.youtube.com/watch?v=dD8F3MLvAsw'>MANUAL DE USUÁRIO 2 SAMSUNG</a><br><br>"
                    + "<a href='https://www.youtube.com/watch?v=Vmq9bBRcrgg'>MANUAL DE USUÁRIO 3 SAMSUNG</a>")

            txtLinks.text = Html.fromHtml(htmlLinks, Html.FROM_HTML_MODE_LEGACY)
            txtLinks.movementMethod = LinkMovementMethod.getInstance()
        }
    }

    private fun applySavedLocale() {
        // 1. Busca a preferência salva
        val prefs = getSharedPreferences("Settings", MODE_PRIVATE)
        val langCode = prefs.getString("app_lang", "PT_BR") ?: "PT_BR"

        // 2. Define o objeto Locale
        val locale = when (langCode) {
            "ENG" -> Locale("en", "US")
            "ESP" -> Locale("es", "ES")
            else -> Locale("pt", "BR")
        }

        // 3. Aplica a configuração no sistema
        Locale.setDefault(locale)
        val config = Configuration()
        config.setLocale(locale)

        // 4. Atualiza os recursos para que o getString() pegue a pasta certa
        resources.updateConfiguration(config, resources.displayMetrics)
    }
}
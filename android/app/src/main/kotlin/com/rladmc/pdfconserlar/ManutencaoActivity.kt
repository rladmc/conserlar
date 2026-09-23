package com.rladmc.pdfconserlar

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity

class ManutencaoActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        supportActionBar?.hide()
        setContentView(R.layout.tela_manutencao)
    }
}
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:screen_protector/screen_protector.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🔒 Garante a proteção contra print e gravação
  await ScreenProtector.preventScreenshotOn();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainMenuView(), // Começa pelo Menu Principal igual ao Android
    );
  }
}

// ==========================================
// TELA DO MENU PRINCIPAL (Estilo Android)
// ==========================================
class MainMenuView extends StatelessWidget {
  const MainMenuView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF37474F), // Fundo #37474F do seu XML
      body: SafeArea(
        child: Column(
          children: [
            // Cabeçalho com Logo
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 60), // Espaçamento para equilibrar o layout
                  Expanded(
                    child: Center(
                      child: Image.asset(
                        'assets/sua_logo.png', // Certifique-se de ter a logo nos assets
                        height: 100,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback caso a imagem não carregue ainda
                          return const Text(
                            "CONSERLAR",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 60),
                ],
              ),
            ),

            // Lista Rolável de Botões
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    // Botão 1: Bluetooth
                    _buildMenuButton(
                      color: const Color(0xFF512DA8), // Roxo
                      title: "CONSER TEST SCAN",
                      subtitle: "BLUETOOTH",
                      icon: Icons.bluetooth,
                      onTap: () {
                        // Implementar ação Bluetooth futuramente
                      },
                    ),

                    // Botão 2: WiFi
                    _buildMenuButton(
                      color: const Color(0xFFE67E22), // Laranja
                      title: "CONSER TEST SCAN",
                      subtitle: "WIFI",
                      icon: Icons.wifi,
                      onTap: () {
                        // Implementar ação WiFi futuramente
                      },
                    ),

                    // Botão 3: Plataforma do Aluno (Abre a WebView)
                    _buildMenuButton(
                      color: const Color(0xFF27AE60), // Verde
                      title: "PLATAFORMA DO ALUNO",
                      subtitle: null,
                      icon: Icons.book,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TelaDeEstudosSegura(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // Bloco de Redes Sociais
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: const [
                              Icon(Icons.close, color: Colors.white, size: 35), // X / Twitter
                              Icon(Icons.camera_alt, color: Colors.white, size: 35), // Instagram
                              Icon(Icons.chat, color: Colors.white, size: 35), // WhatsApp
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: const [
                              Icon(Icons.play_arrow, color: Colors.white, size: 35), // YouTube
                              Icon(Icons.facebook, color: Colors.white, size: 35), // Facebook
                              Icon(Icons.language, color: Colors.white, size: 35), // Site
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Rodapé com Versão
            const Padding(
              padding: EdgeInsets.only(bottom: 20, top: 10),
              child: Text(
                "Versão 1.0.0",
                style: TextStyle(color: Color(0xFF7F8C8D), fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para criar os botões com padrão igual ao do Android
  Widget _buildMenuButton({
    required Color color,
    required String title,
    String? subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 90,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 35),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFFF1C40F),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              offset: Offset(2, 2),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Color(0xFFBDC3C7),
                            fontSize: 12,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                offset: Offset(2, 2),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(icon, color: Colors.white, size: 35),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// TELA DA PLATAFORMA DO ALUNO (WebView Segura)
// ==========================================
class TelaDeEstudosSegura extends StatefulWidget {
  const TelaDeEstudosSegura({super.key});

  @override
  State<TelaDeEstudosSegura> createState() => _TelaDeEstudosSeguraState();
}

class _TelaDeEstudosSeguraState extends State<TelaDeEstudosSegura> {
  InAppWebViewController? webViewController;

  @override
  void initState() {
    super.initState();
    _ativarSeguranca();
  }

  Future<void> _ativarSeguranca() async {
    await ScreenProtector.preventScreenshotOn();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Conserlar - Área do Aluno"),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18),
      ),
      body: SafeArea(
        child: InAppWebView(
          initialUrlRequest: URLRequest(
            url: WebUri("https://aluno.conserlar.com"),
          ),
          
          contextMenu: ContextMenu(
            settings: ContextMenuSettings(hideDefaultSystemContextMenuItems: true),
          ),

          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            allowsInlineMediaPlayback: true,
            allowsAirPlayForMediaPlayback: true,
            mediaPlaybackRequiresUserGesture: false,
            allowsPictureInPictureMediaPlayback: false,
            userAgent: "iphoneconserlar2026",
            supportZoom: false,
          ),

          onWebViewCreated: (controller) {
            webViewController = controller;
          },

          onEnterFullscreen: (controller) async {
            await ScreenProtector.preventScreenshotOn();
          },
          onExitFullscreen: (controller) async {
            await ScreenProtector.preventScreenshotOn();
          },
        ),
      ),
    );
  }
}
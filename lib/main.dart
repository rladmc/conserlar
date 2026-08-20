import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:screen_protector/screen_protector.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🔒 Garante a proteção logo no arranque do app (evita print nos primeiros ms)
  await ScreenProtector.preventScreenshotOn();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TelaDeEstudosSegura(),
    );
  }
}

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
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Conserlar - Área do Aluno"),
        backgroundColor: Colors.black,
        actions: [
          // 📺 Botão de Chromecast
          IconButton(
            icon: const Icon(Icons.cast, color: Colors.white),
            onPressed: () {
              _mostrarDispositivosChromecast(context);
            },
          ),
          
          // 🍏 Botão de AirPlay
          IconButton(
            icon: const Icon(Icons.airplay, color: Colors.white),
            onPressed: () {
              _ativarAirPlayNativo();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: InAppWebView(
          initialUrlRequest: URLRequest(
            url: WebUri("https://aluno.conserlar.com"),
          ),
          
          // 🚫 Oculta menus de contexto e toque longo (evita copiar/salvar mídia)
          contextMenu: ContextMenu(
            settings: ContextMenuSettings(hideDefaultSystemContextMenuItems: true),
          ),

          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            allowsInlineMediaPlayback: true, // Mantém o vídeo rodando na tela do app
            allowsAirPlayForMediaPlayback: true, // Libera o AirPlay nativo
            mediaPlaybackRequiresUserGesture: false, // Libera o áudio automaticamente sem travar no iOS
            allowsPictureInPictureMediaPlayback: false,
            userAgent: "iphoneconserlar2026",
            supportZoom: false,
          ),

          onWebViewCreated: (controller) {
            webViewController = controller;
          },

          // 🔄 Reforça a proteção ao entrar e sair do modo tela cheia do player
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

  void _mostrarDispositivosChromecast(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Transmitir via Chromecast"),
        content: const Text("Buscando Smart TVs compatíveis na rede local..."),
        actions: [
          TextButton(
            child: const Text("Fechar"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _ativarAirPlayNativo() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Abra a Central de Controle do iPhone e selecione o AirPlay se necessário.")),
    );
  }
}
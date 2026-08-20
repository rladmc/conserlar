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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Conserlar - Área do Aluno"),
        backgroundColor: Colors.black,
        actions: [
          // 📺 Botão de Chromecast (Abre o aviso / seletor de rede)
          IconButton(
            icon: const Icon(Icons.cast, color: Colors.white),
            onPressed: () {
              _mostrarDispositivosChromecast(context);
            },
          ),
          
          // 🍏 Botão de AirPlay (Instrução rápida para projeção sem corte de áudio)
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
        backgroundColor: Colors.grey[900],
        title: const Text("Transmitir via Chromecast", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Para espelhar a aula em TVs com Chromecast ou Android TV:\n\n"
          "1. Abra a plataforma Conserlar pelo navegador Google Chrome no seu iPhone.\n"
          "2. Utilize o botão de transmissão nativo do player web.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: const Text("Entendi", style: TextStyle(color: Colors.blueAccent)),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _ativarAirPlayNativo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Transmitir via AirPlay", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Você pode usar o botão de AirPlay direto no player da aula ou:\n\n"
          "1. Deslize o canto superior direito do iPhone para baixo (Central de Controle).\n"
          "2. Toque em Espelhamento de Tela para mandar imagem e som perfeitos para sua TV.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: const Text("Fechar", style: TextStyle(color: Colors.blueAccent)),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
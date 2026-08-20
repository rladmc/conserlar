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
  
  @override
  void initState() {
    super.initState();
    _ativarSeguranca();
  }

  Future<void> _ativarSeguranca() async {
    await ScreenProtector.preventScreenshotOn();
    // Protege contra vazamento/gravação de tela em segundo plano
    //wait ScreenProtector.protectDataLeakageOn();
  }

  @override
  void dispose() {
    // Mantemos comentado ou evitamos desligar para que o app continue seguro
    // ScreenProtector.preventScreenshotOff();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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
            allowsInlineMediaPlayback: true,
            allowsPictureInPictureMediaPlayback: false, // Trava o PiP
            userAgent: "iphoneconserlar2026",
            disableLongPressContextMenuOnLinks: true, // Trava toque longo em links/imagens
            supportZoom: false, // Evita zoom acidental na plataforma
          ),

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
}
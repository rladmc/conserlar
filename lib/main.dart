import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:screen_protector/screen_protector.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
    // 🔒 ATIVA A SEGURANÇA TOTAL ASSIM QUE O APP ABRE
    activarProtecaoDeTela();
  }

  void activarProtecaoDeTela() async {
    // Versão atualizada do pacote usa preventScreenshotOn para bloquear tudo no iOS
    await ScreenProtector.preventScreenshotOn();
  }

  @override
  void dispose() {
    // Desativa ao fechar o app
    ScreenProtector.preventScreenshotOff();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fundo preto elegante para o player
      body: SafeArea(
        child: InAppWebView(
          initialUrlRequest: URLRequest(
            url: WebUri("https://conserlar.com"),
          ),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true, // Necessário para o player da Bunny rodar os scripts
            allowsInlineMediaPlayback: true, // Permite que os vídeos rodem direto na página
          ),
        ),
      ),
    );
  }
}

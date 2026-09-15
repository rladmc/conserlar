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
      ),
      body: SafeArea(
        child: InAppWebView(
          initialUrlRequest: URLRequest(
            url: WebUri("https://aluno.conserlar.com"),
          ),
          
          // 🚫 Oculta menus de contexto para proteger a mídia
          contextMenu: ContextMenu(
            settings: ContextMenuSettings(hideDefaultSystemContextMenuItems: true),
          ),

          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            allowsInlineMediaPlayback: true, // Mantém o vídeo rodando na tela
            allowsAirPlayForMediaPlayback: true, // Libera o AirPlay nativo no player do Bunny
            mediaPlaybackRequiresUserGesture: false, // Libera o áudio sem travar
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
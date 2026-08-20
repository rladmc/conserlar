import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🔒 Garante a proteção contra print e gravação
  await ScreenProtector.preventScreenshotOn();

  // Inicializa o contexto do Google Cast
  await _initCast();

  runApp(const MyApp());
}

Future<void> _initCast() async {
  const appId = GoogleCastDiscoveryCriteria.kDefaultApplicationId;
  if (Platform.isIOS) {
    GoogleCastContext.instance.setSharedInstanceWithOptions(
      IOSGoogleCastOptions(
        GoogleCastDiscoveryCriteriaInitialize.initWithApplicationID(appId),
        stopCastingOnAppTerminated: true,
      ),
    );
  } else if (Platform.isAndroid) {
    GoogleCastContext.instance.setSharedInstanceWithOptions(
      GoogleCastOptionsAndroid(appId: appId),
    );
  }
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
          // 📺 Botão Real de Chromecast (Busca as TVs na rede local)
          IconButton(
            icon: const Icon(Icons.cast, color: Colors.white),
            onPressed: () {
              _mostrarSeletorChromecast(context);
            },
          ),
        ],
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

  void _mostrarSeletorChromecast(BuildContext context) {
    GoogleCastDiscoveryManager.instance.startDiscovery();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Dispositivos Chromecast Encontrados",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<List<GoogleCastDevice>>(
                  stream: GoogleCastDiscoveryManager.instance.devicesStream,
                  builder: (context, snapshot) {
                    final devices = snapshot.data ?? [];
                    if (devices.isEmpty) {
                      return const Center(
                        child: Text(
                          "Buscando TVs na rede Wi-Fi...\n(Certifique-se de estar na mesma rede)",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54),
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        final device = devices[index];
                        return ListTile(
                          leading: const Icon(Icons.tv, color: Colors.white),
                          title: Text(device.friendlyName, style: const TextStyle(color: Colors.white)),
                          onTap: () async {
                            await GoogleCastSessionManager.instance.startSessionWithDevice(device);
                            if (!context.mounted) return;
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
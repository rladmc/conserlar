import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';
import 'package:lottie/lottie.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🔒 Garante a proteção contra print e gravação
  await ScreenProtector.preventScreenshotOn();

  // Inicializa o contexto do Google Cast de forma segura
  await _initCast();

  runApp(const MyApp());
}

Future<void> _initCast() async {
  const appId = GoogleCastDiscoveryCriteria.kDefaultApplicationId;
  GoogleCastOptions? options; // Correção do tipo para aceitar ambas as plataformas

  if (Platform.isIOS) {
    options = IOSGoogleCastOptions(
      GoogleCastDiscoveryCriteriaInitialize.initWithApplicationID(appId),
      stopCastingOnAppTerminated: true,
    );
  } else if (Platform.isAndroid) {
    options = GoogleCastOptionsAndroid(appId: appId);
  }

  if (options != null) {
    GoogleCastContext.instance.setSharedInstanceWithOptions(options);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MenuPrincipalScreen(),
    );
  }
}

// ==========================================
// TELA DO MENU PRINCIPAL
// ==========================================
class MenuPrincipalScreen extends StatelessWidget {
  const MenuPrincipalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF37474F),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.7,
                child: Lottie.asset(
                  'assets/sci_fi_background.json',
                  fit: BoxFit.fill,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(),
                ),
              ),
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Column(
                        children: [
                          Image.asset(
                            'assets/sua_logo.png',
                            height: 120,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Text(
                              "CONSERLAR",
                              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.topRight,
                        child: FloatingActionButton.small(
                          backgroundColor: const Color(0xFFC0392B),
                          onPressed: () {
                            // Ação de sair
                          },
                          child: const Icon(Icons.power_settings_new, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        _buildMenuButton(
                          colorBg: const Color(0xFF4A148C),
                          title: "CONSER TEST SCAN",
                          subtitle: "BLUETOOTH",
                          iconAsset: Icons.bluetooth,
                          onTap: () {},
                        ),
                        _buildMenuButton(
                          colorBg: const Color(0xFFE65100),
                          title: "CONSER TEST SCAN",
                          subtitle: "WIFI",
                          iconAsset: Icons.wifi,
                          onTap: () {},
                        ),
                        _buildMenuButton(
                          colorBg: const Color(0xFF1B5E20),
                          title: "PLATAFORMA DO ALUNO",
                          subtitle: "",
                          iconAsset: Icons.book,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const TelaDeEstudosSegura()),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF263238),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildSocialIcon(Icons.close),
                                  _buildSocialIcon(Icons.camera_alt),
                                  _buildSocialIcon(Icons.chat),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildSocialIcon(Icons.play_arrow),
                                  _buildSocialIcon(Icons.facebook),
                                  _buildSocialIcon(Icons.language),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Text(
                    "Versão 1.0.0",
                    style: TextStyle(color: Color(0xFF7F8C8D), fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required Color colorBg,
    required String title,
    required String subtitle,
    required IconData iconAsset,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 90,
      decoration: BoxDecoration(
        color: colorBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(iconAsset, color: Colors.white, size: 36),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFFF1C40F),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Color(0xFFBDC3C7),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(iconAsset, color: Colors.white, size: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Icon(icon, color: Colors.white, size: 30),
    );
  }
}

// ==========================================
// TELA DO WEBVIEW (PLATAFORMA DO ALUNO + CAST)
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
        title: const Text("Plataforma do Aluno"),
        backgroundColor: const Color(0xFF37474F),
        actions: [
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
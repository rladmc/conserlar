import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lottie/lottie.dart';
import 'package:dart_cast/dart_cast.dart';
import 'package:bonsoir/bonsoir.dart';
import 'package:flutter_ios_airplay/flutter_ios_airplay.dart';
import 'package:dlna_dart/dlna.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart' as shelf_router; // <--- ADICIONADO "as shelf_router" AQUI
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // O dart_cast não exige inicialização prévia global de SDK nativo no main()

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainMenuView(),
    );
  }
}



// ==========================================
// TELA DO MENU PRINCIPAL
// ==========================================
class MainMenuView extends StatelessWidget {
  const MainMenuView({super.key});

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Não foi possível abrir o link: $urlString');
    }
  }

  // Função que chama a Activity Nativa do Android via MethodChannel
  Future<void> _abrirScanInversoraAndroid() async {
    const platform = MethodChannel('com.rladmc.pdfconserlar/android');
    try {
      await platform.invokeMethod('abrirScanInversora');
    } on PlatformException catch (e) {
      debugPrint("Falha ao abrir activity nativa: '${e.message}'.");
    }
  }

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
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Center(
                    child: Image.asset(
                      'assets/logo.png',
                      height: 180,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const SizedBox(height: 180),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    child: Column(
                      children: [
                        // Botão 1: Wi-Fi
                        _buildCustomButton(
                          title: "CONSER TEST SCAN",
                          subtitle: "WIFI",
                          lottieRes: 'assets/wifi.json',
                          gradientColors: const [
                            Color(0xFF000000),
                            Color(0xFFBA4A00),
                            Color(0xFF000000),
                          ],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ConserTestScanView(),
                              ),
                            );
                          },
                        ),

                        // Botão 2: Bluetooth (Exibido EXCLUSIVAMENTE no Android)
                        if (Platform.isAndroid) ...[
                          _buildCustomButton(
                            title: "CONSER TEST SCAN",
                            subtitle: "BLUETOOTH",
                            lottieRes: 'assets/bluetooth.json',
                            // Cores convertidas do seu XML: Preto -> Roxo (#800080) -> Preto
                            gradientColors: const [
                              Color(0xFF000000),
                              Color(0xFF800080),
                              Color(0xFF000000),
                            ],
                            onTap: () {
                              _abrirScanInversoraAndroid();
                            },
                          ),
                        ],

                        // Botão 3: Plataforma do Aluno
                        _buildCustomButton(
                          title: "PLATAFORMA DO ALUNO",
                          subtitle: null,
                          lottieRes: 'assets/book.json',
                          gradientColors: const [
                            Color(0xFF000000),
                            Color(0xFF238C00),
                            Color(0xFF000000),
                          ],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TelaDeEstudosSegura(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C3E50).withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildSocialIcon(assetName: 'assets/x_logo.png', onTap: () => _launchUrl('https://x.com/ConserlarR')),
                                  _buildSocialIcon(assetName: 'assets/insta_logo.png', onTap: () => _launchUrl('http://instagram.com/conserlar_oficial')),
                                  _buildSocialIcon(assetName: 'assets/what_logo.png', onTap: () => _launchUrl('https://api.whatsapp.com/send?phone=5521974638694')),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildSocialIcon(assetName: 'assets/you_logo.png', onTap: () => _launchUrl('https://www.youtube.com/@RSconserlar')),
                                  _buildSocialIcon(assetName: 'assets/face_logo.png', onTap: () => _launchUrl('https://www.facebook.com/conserlaroficial')),
                                  _buildSocialIcon(assetName: 'assets/site.png', onTap: () => _launchUrl('https://loja.conserlar.com')),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 40, top: 5),
                  child: Text(
                    Platform.isAndroid ? "Versão 6.0.0" : "Versão 1.0.0",
                    style: const TextStyle(color: Color(0xFF7F8C8D), fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomButton({
    required String title,
    String? subtitle,
    required String lottieRes,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 85,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(35),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 55,
                  height: 55,
                  child: Lottie.asset(lottieRes, fit: BoxFit.contain, errorBuilder: (c, e, s) => const Icon(Icons.star, color: Colors.white)),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFF1C40F),
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(2, 2))],
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFBDC3C7),
                            fontSize: 12,
                            shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(2, 2))],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                SizedBox(
                  width: 55,
                  height: 55,
                  child: Lottie.asset(lottieRes, fit: BoxFit.contain, errorBuilder: (c, e, s) => const Icon(Icons.star, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialIcon({required String assetName, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Image.asset(assetName, width: 45, height: 45, fit: BoxFit.contain, errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.white, size: 35)),
      ),
    );
  }
}

// ==========================================
// TELA CONSER TEST SCAN
// ==========================================
class ConserTestScanView extends StatelessWidget {
  const ConserTestScanView({super.key});

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
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 15),
                  child: Center(
                    child: Image.asset(
                      'assets/logo.png',
                      height: 130,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const SizedBox(height: 130),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        _buildScanButton(
                          title: "CONSER TEST SCAN",
                          subtitle: "WIFI",
                          lottieRes: 'assets/wifi.json',
                          gradientColors: const [
                            Color(0xFF000000),
                            Color(0xFFBA4A00),
                            Color(0xFF000000),
                          ],
                          textColor: const Color(0xFFF1C40F),
                          showBothIcons: true,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ConserTestWebView(),
                              ),
                            );
                          },
                        ),
                        _buildScanButton(
                          title: "PRIMEIRO ACESSO",
                          // Exibe "EEPROM" se for Android, senão fica null no iOS
                          subtitle: Platform.isAndroid ? "CONSER TEST SCAN - EEPROM" : null,
                          lottieRes: null,
                          gradientColors: const [
                            Color(0xFF000000),
                            Color(0xFF238C00),
                            Color(0xFF000000),
                          ],
                          textColor: Colors.white,
                          showBothIcons: false,
                          onTap: () async {
                            if (Platform.isAndroid) {
                              // Abre a Activity nativa MenuConsertestWifi.kt no Android
                              try {
                                const platform = MethodChannel('com.rladmc.pdfconserlar/android');
                                await platform.invokeMethod('abrirPrimeiroEeprom');
                              } catch (e) {
                                print("Erro ao chamar activity nativa: $e");
                              }
                            } else {
                              // Comportamento original para iOS
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PrimeiroAcessoWebViewView(),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanButton({
    required String title,
    String? subtitle,
    String? lottieRes,
    required List<Color> gradientColors,
    required Color textColor,
    required bool showBothIcons,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 85,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(35),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (showBothIcons && lottieRes != null)
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: Lottie.asset(lottieRes, fit: BoxFit.contain),
                  ),
                const SizedBox(width: 5),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          shadows: const [
                            Shadow(color: Colors.black, blurRadius: 5, offset: Offset(3, 3)),
                          ],
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFBDC3C7),
                            fontSize: 11,
                            shadows: [
                              Shadow(color: Colors.black, blurRadius: 5, offset: Offset(3, 3)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                if (showBothIcons && lottieRes != null)
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: Lottie.asset(lottieRes, fit: BoxFit.contain),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// TELA DO WEBVIEW DO CONSER TEST SCAN
// ==========================================
class ConserTestWebView extends StatefulWidget {
  const ConserTestWebView({super.key});

  @override
  State<ConserTestWebView> createState() => _ConserTestWebViewState();
}

class _ConserTestWebViewState extends State<ConserTestWebView> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent("iphoneconserlar2026")
      ..loadRequest(Uri.parse('https://consertest.conserlar.com'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: WebViewWidget(controller: controller),
      ),
    );
  }
}

// ==========================================
// TELA DO WEBVIEW PRIMEIRO ACESSO
// ==========================================
class PrimeiroAcessoWebViewView extends StatefulWidget {
  const PrimeiroAcessoWebViewView({super.key});

  @override
  State<PrimeiroAcessoWebViewView> createState() => _PrimeiroAcessoWebViewViewState();
}

class _PrimeiroAcessoWebViewViewState extends State<PrimeiroAcessoWebViewView> {
  late final WebViewController controller;
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _inicializarWebView();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mostrarGuiaParaIphone(context);
    });
  }

  void _inicializarWebView() {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              isLoading = true;
              hasError = false;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              isLoading = false;
              hasError = false;
            });
            if (url.contains("/salvar")) {
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  Navigator.pop(context);
                }
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint("Erro no WebView Primeiro Acesso: ${error.description}");
            setState(() {
              isLoading = false;
              hasError = true;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse('http://192.168.4.1'));
  }

  void _recarregarPagina() {
    setState(() {
      isLoading = true;
      hasError = false;
    });
    controller.reload();
  }

  void _mostrarGuiaParaIphone(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E272C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFF1C40F), width: 2),
          ),
          title: const Row(
            children: [
              Icon(Icons.wifi, color: Color(0xFFF1C40F), size: 28),
              SizedBox(width: 10),
              Text(
                "Conexão Wi-Fi da Placa",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Para configurar o seu testador, conecte o celular na rede Wi-Fi correspondente:",
                style: TextStyle(color: Color(0xFFBDC3C7), fontSize: 14),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green, width: 1.5),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.wifi, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "ConsertestScan - XXXX",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "1️⃣ Abra os **Ajustes > Wi-Fi** do seu celular.\n2️⃣ Conecte na rede do seu testador.\n3️⃣ Retorne a esta página para salvar suas redes Wi-Fi.",
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF238C00),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "ENTENDIDO",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF37474F),
        title: const Text("Primeiro Acesso - Configuração", style: TextStyle(color: Colors.white, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Color(0xFFF1C40F)),
            onPressed: () => _mostrarGuiaParaIphone(context),
            tooltip: "Ajuda com o Wi-Fi",
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: controller),
            if (hasError)
              Container(
                color: const Color(0xFF37474F),
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.wifi_off_rounded,
                        size: 70,
                        color: Color(0xFFF1C40F),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Aguardando Conexão com a Placa",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Certifique-se de que o seu celular está conectado na rede Wi-Fi correspondente ao seu testador:\n\n👉 ConsertestScan - XXXX\n\nAssim que conectar, retorne e toque no botão abaixo.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFBDC3C7),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF238C00),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          label: const Text(
                            "TENTAR NOVAMENTE",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: _recarregarPagina,
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextButton.icon(
                        icon: const Icon(Icons.help_outline, color: Color(0xFFF1C40F), size: 18),
                        label: const Text(
                          "Ver Instruções de Conexão",
                          style: TextStyle(color: Color(0xFFF1C40F), fontSize: 13),
                        ),
                        onPressed: () => _mostrarGuiaParaIphone(context),
                      ),
                    ],
                  ),
                ),
              ),
            if (isLoading && !hasError)
              const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF238C00),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class TelaDeEstudosSegura extends StatefulWidget {
  const TelaDeEstudosSegura({super.key});

  @override
  State<TelaDeEstudosSegura> createState() => _TelaDeEstudosSeguraState();
}

class _TelaDeEstudosSeguraState extends State<TelaDeEstudosSegura>
    with WidgetsBindingObserver {
  late final WebViewController controller;

  bool _conteudoVisivel = true;
  bool _isFullScreen = false;

  String _currentMediaUrl = '';
  String _currentMediaTitle = '';
  String _currentMediaType = 'video';

  HttpServer? _localProxyServer;
  final int _localProxyPort = 8080;

  final Map<String, File> _mediaFiles = {};

  late final CastService _castService = CastService(
    discoveryProviders: [
      ChromecastDiscoveryProvider(),
      DlnaDiscoveryProvider(),
    ],
    sessionFactory: (device) {
      switch (device.protocol) {
        case CastProtocol.chromecast:
          return ChromecastSession(device: device);

        case CastProtocol.dlna:
          return DlnaSession(
            device: device,
            description: DlnaDeviceDescription(
              friendlyName: device.name,
              manufacturer: 'Generic DLNA',
              modelName: 'Smart TV',
              udn: device.id,
              locationUrl:
              'http://${device.address}:${device.port}/description.xml',
            ),
          );

        case CastProtocol.airplay:
          return AirPlaySession(device);

        default:
          throw UnsupportedError(
            'Protocolo não suportado: ${device.protocol}',
          );
      }
    },
  );

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _iniciarServidorProxyLocal();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent('iphoneconserlar2026')
      ..addJavaScriptChannel(
        'AndroidCastBridge',
        onMessageReceived: (message) {
          try {
            final data = jsonDecode(message.message);

            final url = (data['url'] ?? '').toString().trim();
            final titulo = (data['titulo'] ?? '').toString().trim();
            final tipo = (data['tipo'] ?? 'video').toString().trim();

            debugPrint('');
            debugPrint('======================================');
            debugPrint('MEDIA RECEBIDA DO WEBVIEW');
            debugPrint('TIPO: $tipo');
            debugPrint('URL: $url');
            debugPrint('TÍTULO: $titulo');
            debugPrint('======================================');

            if (!mounted) return;

            /*
       * IMPORTANTE:
       *
       * O JavaScript agora só deve mandar uma mídia real.
       * Mesmo assim fazemos uma segunda validação no Dart
       * para impedir que uma URL de página/planilha seja usada.
       */
            if (!_pareceSerMidiaValida(url, tipo)) {
              debugPrint(
                'URL IGNORADA: não parece ser uma mídia real: $url',
              );
              return;
            }

            final mudouDeMidia = url.isNotEmpty && url != _currentMediaUrl;

            setState(() {
              _currentMediaUrl = url;
              _currentMediaTitle =
              titulo.isNotEmpty ? titulo : 'Aula Conserlar';
              _currentMediaType =
              tipo == 'image' ? 'image' : 'video';
            });

            if ((data['abrirMenu'] ?? false) &&
                _currentMediaUrl.isNotEmpty) {
              _mostrarMenuDispositivosTransmissao();
            }
            // AUTO-CAST: Se o usuário já conectou a TV antes e mudou de aula/esquema
            else if (mudouDeMidia && _castService.activeSession != null) {
              debugPrint('[CAST] Nova mídia detectada com sessão ativa. Disparando Auto-Cast...');
              _enviarMidiaParaDispositivo(null, true); // true = modo silencioso (sem popups)
            }
          } catch (e) {
            debugPrint('ERRO BRIDGE: $e');

            if (message.message.contains('pararTransmissao')) {
              _pararTransmissaoNaTv();
            }
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            if (request.url.contains('app://full_clicked') ||
                request.url.contains('app://exit_full_clicked')) {
              _toggleFullInterno();
              return NavigationDecision.prevent;
            }

            if (request.url.contains('app://airplay_clicked')) {
              _acionarAirPlayNativo();
              return NavigationDecision.prevent;
            }

            if (request.url.contains('app://cast_clicked')) {
              if (_currentMediaUrl.isNotEmpty &&
                  _pareceSerMidiaValida(
                    _currentMediaUrl,
                    _currentMediaType,
                  )) {
                _mostrarMenuDispositivosTransmissao();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Aguarde a mídia real carregar na tela...',
                    ),
                  ),
                );
              }

              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
          onPageFinished: (_) => _configurarWebView(),
        ),
      )
      ..loadRequest(
        Uri.parse('https://aluno.conserlar.com'),
      );
  }

  /*
   * ============================================================
   * VALIDAÇÃO DART
   * ============================================================
   */

  bool _pareceSerMidiaValida(String url, String tipo) {
    if (url.isEmpty) return false;

    final lower = url.toLowerCase();

    /*
     * Nunca aceitar como mídia a própria página/documento.
     */
    final bloqueadas = [
      '.html',
      '.htm',
      '.php',
      '.asp',
      '.aspx',
      '/planilha',
      '/planilhas',
      '/spreadsheet',
      '/document',
      '/documento',
      '/pagas/',
      'google.com',
      'docs.google.com',
      'drive.google.com',
    ];

    for (final item in bloqueadas) {
      if (lower.contains(item)) {
        /*
         * Exceção:
         *
         * /pagas/ sozinho não significa necessariamente que seja
         * página, então não usamos isso como bloqueio absoluto
         * quando a URL possui extensão de mídia.
         */
        if (lower.endsWith('.mp4') ||
            lower.endsWith('.webm') ||
            lower.endsWith('.m3u8') ||
            lower.endsWith('.jpg') ||
            lower.endsWith('.jpeg') ||
            lower.endsWith('.png') ||
            lower.endsWith('.webp')) {
          continue;
        }

        return false;
      }
    }

    if (tipo == 'image') {
      return _pareceImagem(url);
    }

    if (tipo == 'video') {
      /*
       * Alguns vídeos do Bunny/CDN não possuem extensão .mp4
       * na URL. Por isso não exigimos extensão.
       */
      return lower.startsWith('http://') ||
          lower.startsWith('https://');
    }

    return false;
  }

  bool _pareceImagem(String url) {
    final lower = url.toLowerCase();

    return lower.contains('.jpg') ||
        lower.contains('.jpeg') ||
        lower.contains('.png') ||
        lower.contains('.webp') ||
        lower.contains('.gif') ||
        lower.contains('.bmp') ||
        lower.contains('image/');
  }

  /*
   * ============================================================
   * JAVASCRIPT
   *
   * A diferença principal está aqui.
   *
   * NÃO usamos mais window.location.
   * NÃO usamos URL da página.
   * NÃO usamos link da planilha.
   *
   * Procuramos o elemento REAL que está mostrando a mídia.
   * ============================================================
   */

  void _configurarWebView() {
    controller.runJavaScript(r'''
    (function() {
      console.log('[CONSERLAR] Configurando WebView...');

      /*
       * ============================================================
       * MENU HORIZONTAL
       * ============================================================
       */

      function configurarMenuHorizontal() {
        /*
         * Cria o CSS somente uma vez.
         */
        if (!document.getElementById('conserlarCastStyle')) {
          var style = document.createElement('style');

          style.id = 'conserlarCastStyle';

          style.innerHTML = `
            /*
             * Containers externos não podem cortar o menu.
             */
            header,
            nav,
            .navbar,
            .navbar-nav,
            .menu,
            .container-fluid,
            .row {
              overflow: visible !important;
            }

            /*
             * MENU PRINCIPAL
             */
            #menuNavegacaoSuperior {
              display: flex !important;

              flex-direction: row !important;

              flex-wrap: nowrap !important;

              justify-content: flex-start !important;

              align-items: center !important;

              width: 100% !important;

              max-width: 100% !important;

              overflow-x: auto !important;

              overflow-y: hidden !important;

              white-space: nowrap !important;

              -webkit-overflow-scrolling: touch !important;

              scrollbar-width: none !important;

              padding-left: 10px !important;

              padding-right: 10px !important;

              gap: 4px !important;
            }

            /*
             * Esconde a barra de rolagem no Chrome/WebView.
             */
            #menuNavegacaoSuperior::-webkit-scrollbar {
              display: none !important;

              width: 0 !important;

              height: 0 !important;
            }

            /*
             * Cada item fica lado a lado.
             */
            #menuNavegacaoSuperior .nav-item {
              display: inline-flex !important;

              flex: 0 0 auto !important;

              width: auto !important;

              max-width: none !important;

              white-space: nowrap !important;
            }

            /*
             * Links do menu também não podem quebrar.
             */
            #menuNavegacaoSuperior .nav-link {
              display: inline-flex !important;

              align-items: center !important;

              flex: 0 0 auto !important;

              width: auto !important;

              white-space: nowrap !important;
            }

            /*
             * Caso o menu use <li> sem Bootstrap.
             */
            #menuNavegacaoSuperior > li {
              display: inline-flex !important;

              flex: 0 0 auto !important;

              width: auto !important;

              white-space: nowrap !important;
            }

            /*
             * Evita que algum container interno force
             * o menu a ficar vertical.
             */
            #menuNavegacaoSuperior > ul,
            #menuNavegacaoSuperior .navbar-nav {
              display: flex !important;

              flex-direction: row !important;

              flex-wrap: nowrap !important;

              align-items: center !important;

              width: max-content !important;

              min-width: max-content !important;

              white-space: nowrap !important;

              overflow: visible !important;
            }

            /*
             * Se houver dropdown, ele continua funcionando.
             */
            #menuNavegacaoSuperior .dropdown {
              position: relative !important;

              flex: 0 0 auto !important;
            }

            /*
             * Botões também ficam lado a lado.
             */
            #menuNavegacaoSuperior button {
              flex: 0 0 auto !important;

              width: auto !important;

              white-space: nowrap !important;
            }

            /*
             * Não deixa o Bootstrap transformar o menu
             * em coluna em telas pequenas.
             */
            @media (max-width: 768px) {
              #menuNavegacaoSuperior {
                display: flex !important;

                flex-direction: row !important;

                flex-wrap: nowrap !important;

                overflow-x: auto !important;

                overflow-y: hidden !important;
              }

              #menuNavegacaoSuperior .navbar-nav {
                display: flex !important;

                flex-direction: row !important;

                flex-wrap: nowrap !important;

                width: max-content !important;

                min-width: max-content !important;
              }
            }
          `;

          document.head.appendChild(style);

          console.log(
            '[CONSERLAR] CSS do menu horizontal instalado.'
          );
        }

        /*
         * ========================================================
         * FORÇA O MENU EXISTENTE
         * ========================================================
         *
         * Além do CSS, aplicamos diretamente os estilos.
         * Isso ajuda caso o site tenha algum JavaScript
         * sobrescrevendo o Bootstrap.
         */

        var menu =
          document.getElementById(
            'menuNavegacaoSuperior'
          );

        if (!menu) {
          console.log(
            '[CONSERLAR] menuNavegacaoSuperior ainda não encontrado.'
          );

          return;
        }

        menu.style.setProperty(
          'display',
          'flex',
          'important'
        );

        menu.style.setProperty(
          'flex-direction',
          'row',
          'important'
        );

        menu.style.setProperty(
          'flex-wrap',
          'nowrap',
          'important'
        );

        menu.style.setProperty(
          'justify-content',
          'flex-start',
          'important'
        );

        menu.style.setProperty(
          'align-items',
          'center',
          'important'
        );

        menu.style.setProperty(
          'width',
          '100%',
          'important'
        );

        menu.style.setProperty(
          'max-width',
          '100%',
          'important'
        );

        menu.style.setProperty(
          'overflow-x',
          'auto',
          'important'
        );

        menu.style.setProperty(
          'overflow-y',
          'hidden',
          'important'
        );

        menu.style.setProperty(
          'white-space',
          'nowrap',
          'important'
        );

        menu.style.setProperty(
          '-webkit-overflow-scrolling',
          'touch',
          'important'
        );

        /*
         * Procura o container interno do menu.
         */
        var menuInterno =
          menu.querySelector(
            '.navbar-nav'
          );

        if (!menuInterno) {
          menuInterno =
            menu.querySelector('ul');
        }

        if (menuInterno) {
          menuInterno.style.setProperty(
            'display',
            'flex',
            'important'
          );

          menuInterno.style.setProperty(
            'flex-direction',
            'row',
            'important'
          );

          menuInterno.style.setProperty(
            'flex-wrap',
            'nowrap',
            'important'
          );

          menuInterno.style.setProperty(
            'width',
            'max-content',
            'important'
          );

          menuInterno.style.setProperty(
            'min-width',
            'max-content',
            'important'
          );

          menuInterno.style.setProperty(
            'white-space',
            'nowrap',
            'important'
          );

          menuInterno.style.setProperty(
            'overflow',
            'visible',
            'important'
          );
        }

        /*
         * Cada item.
         */
        var itens =
          menu.querySelectorAll(
            '.nav-item, li'
          );

        for (var i = 0; i < itens.length; i++) {
          itens[i].style.setProperty(
            'display',
            'inline-flex',
            'important'
          );

          itens[i].style.setProperty(
            'flex',
            '0 0 auto',
            'important'
          );

          itens[i].style.setProperty(
            'width',
            'auto',
            'important'
          );

          itens[i].style.setProperty(
            'white-space',
            'nowrap',
            'important'
          );
        }
      }

      /*
       * Executa agora.
       */
      configurarMenuHorizontal();

      /*
       * O site pode recriar o menu depois que a página
       * termina de carregar. Por isso verificamos novamente.
       */
      setTimeout(
        configurarMenuHorizontal,
        300
      );

      setTimeout(
        configurarMenuHorizontal,
        1000
      );

      setTimeout(
        configurarMenuHorizontal,
        2000
      );

      setInterval(
        configurarMenuHorizontal,
        1500
      );


      /*
       * ============================================================
       * DETECTOR DE MÍDIA REAL
       * ============================================================
       */

      console.log(
        '[CONSERLAR CAST] Instalando detector de mídia real...'
      );

      if (window.__conserlarCastInstalado) {
        console.log(
          '[CONSERLAR CAST] Detector já instalado.'
        );

        return;
      }

      window.__conserlarCastInstalado = true;

      var ultimoUrl = '';
      var ultimoTipo = '';

      /*
       * ------------------------------------------------------------
       * UTILITÁRIOS
       * ------------------------------------------------------------
       */

      function normalizarUrl(url) {
        if (!url) return '';

        try {
          return new URL(
            url,
            window.location.href
          ).href;
        } catch(e) {
          return String(url);
        }
      }

      function visivel(el) {
        if (!el) return false;

        try {
          var style =
            window.getComputedStyle(el);

          var rect =
            el.getBoundingClientRect();

          return style.display !== 'none' &&
                 style.visibility !== 'hidden' &&
                 parseFloat(
                   style.opacity || '1'
                 ) > 0 &&
                 rect.width > 10 &&
                 rect.height > 10;
        } catch(e) {
          return false;
        }
      }

      function tamanhoVisivel(el) {
        if (!el) return 0;

        try {
          var r =
            el.getBoundingClientRect();

          return Math.max(
            0,
            r.width * r.height
          );
        } catch(e) {
          return 0;
        }
      }

      function urlParecePagina(url) {
        if (!url) return true;

        var u =
          url.toLowerCase();

        if (
          u.includes('/planilha') ||
          u.includes('/planilhas') ||
          u.includes('/spreadsheet') ||
          u.includes('/document') ||
          u.includes('/documento')
        ) {
          return true;
        }

        if (
          u.includes('_page-') &&
          !u.match(
            /\.(mp4|webm|m3u8|jpg|jpeg|png|webp|gif)(\?|$)/i
          )
        ) {
          return true;
        }

        if (
          u.endsWith('.html') ||
          u.endsWith('.htm') ||
          u.endsWith('.php') ||
          u.endsWith('.asp') ||
          u.endsWith('.aspx')
        ) {
          return true;
        }

        return false;
      }

      function extrairUrlDoElemento(el) {
        if (!el) return '';

        var candidatos = [];

        if (el.currentSrc) {
          candidatos.push(
            el.currentSrc
          );
        }

        if (el.src) {
          candidatos.push(
            el.src
          );
        }

        try {
          var sources =
            el.querySelectorAll(
              'source'
            );

          for (
            var i = 0;
            i < sources.length;
            i++
          ) {
            if (sources[i].src) {
              candidatos.push(
                sources[i].src
              );
            }

            var ds =
              sources[i].getAttribute(
                'data-src'
              );

            if (ds) {
              candidatos.push(ds);
            }
          }
        } catch(e) {}

        var atributos = [
          'data-src',
          'data-original',
          'data-url',
          'data-image',
          'data-image-url',
          'data-video',
          'data-video-url',
          'data-file',
          'data-media',
          'data-media-url'
        ];

        for (
          var j = 0;
          j < atributos.length;
          j++
        ) {
          try {
            var valor =
              el.getAttribute(
                atributos[j]
              );

            if (valor) {
              candidatos.push(valor);
            }
          } catch(e) {}
        }

        for (
          var k = 0;
          k < candidatos.length;
          k++
        ) {
          var url =
            normalizarUrl(
              candidatos[k]
            );

          if (!url) continue;

          if (
            url.indexOf('blob:') === 0
          ) {
            continue;
          }

          if (
            urlParecePagina(url)
          ) {
            console.log(
              '[CONSERLAR CAST] Ignorando URL que parece página:',
              url
            );

            continue;
          }

          return url;
        }

        return '';
      }

      /*
       * ------------------------------------------------------------
       * ENCONTRAR VÍDEO REAL
       * ------------------------------------------------------------
       */

      function encontrarVideoReal() {
        var candidatos = [];

        var videos =
          document.querySelectorAll(
            'video'
          );

        for (
          var i = 0;
          i < videos.length;
          i++
        ) {
          var video = videos[i];

          if (!visivel(video)) {
            continue;
          }

          var url =
            extrairUrlDoElemento(
              video
            );

          if (!url) continue;

          candidatos.push({
            el: video,
            url: url,
            area:
              tamanhoVisivel(video),
            prioridade: 100
          });
        }

        var mediaViewer =
          document.getElementById(
            'mediaViewer'
          );

        if (
          mediaViewer &&
          visivel(mediaViewer)
        ) {
          var urlViewer =
            extrairUrlDoElemento(
              mediaViewer
            );

          if (urlViewer) {
            candidatos.push({
              el: mediaViewer,
              url: urlViewer,
              area:
                tamanhoVisivel(
                  mediaViewer
                ),
              prioridade: 90
            });
          }
        }

        var wrapper =
          document.getElementById(
            'playerWrapper'
          );

        if (wrapper) {
          var videosWrapper =
            wrapper.querySelectorAll(
              'video'
            );

          for (
            var w = 0;
            w < videosWrapper.length;
            w++
          ) {
            var vw =
              videosWrapper[w];

            if (!visivel(vw)) {
              continue;
            }

            var uw =
              extrairUrlDoElemento(vw);

            if (uw) {
              candidatos.push({
                el: vw,
                url: uw,
                area:
                  tamanhoVisivel(vw),
                prioridade: 110
              });
            }
          }
        }

        if (
          candidatos.length === 0
        ) {
          return null;
        }

        candidatos.sort(
          function(a, b) {
            if (
              b.prioridade !==
              a.prioridade
            ) {
              return (
                b.prioridade -
                a.prioridade
              );
            }

            return b.area - a.area;
          }
        );

        return candidatos[0];
      }

      /*
       * ------------------------------------------------------------
       * ENCONTRAR IMAGEM REAL
       * ------------------------------------------------------------
       */

      function encontrarImagemReal() {
        var candidatos = [];

        var apostila =
          document.getElementById(
            'imagemApostila'
          );

        if (
          apostila &&
          visivel(apostila)
        ) {
          var urlApostila =
            extrairUrlDoElemento(
              apostila
            );

          if (urlApostila) {
            candidatos.push({
              el: apostila,
              url: urlApostila,
              area:
                tamanhoVisivel(
                  apostila
                ),
              prioridade: 200
            });
          }
        }

        var imagens =
          document.querySelectorAll(
            'img'
          );

        for (
          var i = 0;
          i < imagens.length;
          i++
        ) {
          var img = imagens[i];

          if (!visivel(img)) {
            continue;
          }

          if (
            tamanhoVisivel(img) < 5000
          ) {
            continue;
          }

          var url =
            extrairUrlDoElemento(img);

          if (!url) continue;

          candidatos.push({
            el: img,
            url: url,
            area:
              tamanhoVisivel(img),
            prioridade: 100
          });
        }

        var elementos =
          document.querySelectorAll('*');

        for (
          var j = 0;
          j < elementos.length;
          j++
        ) {
          var el =
            elementos[j];

          if (!visivel(el)) {
            continue;
          }

          if (
            tamanhoVisivel(el) < 10000
          ) {
            continue;
          }

          try {
            var bg =
              window.getComputedStyle(
                el
              ).backgroundImage;

            if (
              bg &&
              bg !== 'none' &&
              bg.indexOf(
                'url('
              ) !== -1
            ) {
              var match =
                bg.match(
                  /url\(["']?(.*?)["']?\)/
                );

              if (
                match &&
                match[1]
              ) {
                var bgUrl =
                  normalizarUrl(
                    match[1]
                  );

                if (
                  bgUrl &&
                  !urlParecePagina(
                    bgUrl
                  )
                ) {
                  candidatos.push({
                    el: el,
                    url: bgUrl,
                    area:
                      tamanhoVisivel(el),
                    prioridade: 80
                  });
                }
              }
            }
          } catch(e) {}
        }

        if (
          candidatos.length === 0
        ) {
          return null;
        }

        candidatos.sort(
          function(a, b) {
            if (
              b.prioridade !==
              a.prioridade
            ) {
              return (
                b.prioridade -
                a.prioridade
              );
            }

            return b.area - a.area;
          }
        );

        return candidatos[0];
      }

      /*
       * ------------------------------------------------------------
       * DETECTOR PRINCIPAL
       * ------------------------------------------------------------
       */

      function obterMidiaReal() {
        var video =
          encontrarVideoReal();

        if (
          video &&
          video.url
        ) {
          return {
            url: video.url,

            titulo:
              document.getElementById(
                'aulaTitulo'
              )?.innerText ||
              document.title ||
              'Aula Conserlar',

            tipo: 'video',

            abrirMenu: false
          };
        }

        var imagem =
          encontrarImagemReal();

        if (
          imagem &&
          imagem.url
        ) {
          return {
            url: imagem.url,

            titulo:
              document.getElementById(
                'aulaTitulo'
              )?.innerText ||
              document.title ||
              'Esquema Conserlar',

            tipo: 'image',

            abrirMenu: false
          };
        }

        return {
          url: '',
          titulo: '',
          tipo: '',
          abrirMenu: false
        };
      }

      /*
       * ------------------------------------------------------------
       * ENVIO PARA FLUTTER
       * ------------------------------------------------------------
       */

      function enviarMidia(
        abrirMenu
      ) {
        var info =
          obterMidiaReal();

        if (!info.url) {
          console.log(
            '[CONSERLAR CAST] Nenhuma mídia real encontrada.'
          );

          return;
        }

        if (
          info.url === ultimoUrl &&
          info.tipo === ultimoTipo &&
          !abrirMenu
        ) {
          return;
        }

        ultimoUrl = info.url;
        ultimoTipo = info.tipo;

        info.abrirMenu =
          !!abrirMenu;

        console.log(
          '[CONSERLAR CAST] MÍDIA REAL:',
          info.tipo,
          info.url
        );

        if (
          window.AndroidCastBridge
        ) {
          window.AndroidCastBridge.postMessage(
            JSON.stringify(info)
          );
        }
      }

      /*
       * ------------------------------------------------------------
       * BOTÃO FULLSCREEN
       * ------------------------------------------------------------
       */

      setInterval(
        function() {
          var full =
            document.getElementById(
              'btnFull'
            );

          if (full) {
            full.innerHTML =
              '<i class="bi bi-fullscreen"></i> Full';

            if (
              !full.dataset.configurado
            ) {
              full.dataset.configurado =
                'true';

              full.onclick =
                function(e) {
                  e.preventDefault();

                  window.location.href =
                    'app://full_clicked';
                };
            }
          }
        },
        300
      );

      /*
       * ------------------------------------------------------------
       * BOTÃO CAST
       * ------------------------------------------------------------
       */

      setInterval(
        function() {
          var cast =
            document.getElementById(
              'btnCast'
            );

          if (cast) {
            cast.classList.remove(
              'd-none'
            );

            cast.innerHTML =
              '<i class="bi bi-cast me-1"></i> Transmitir';

            if (
              !cast.dataset.configurado
            ) {
              cast.dataset.configurado =
                'true';

              cast.onclick =
                function(e) {
                  e.preventDefault();

                  enviarMidia(true);
                };
            }
          }
        },
        300
      );

      /*
       * ------------------------------------------------------------
       * MONITORAMENTO
       * ------------------------------------------------------------
       */

      setInterval(
        function() {
          enviarMidia(false);
        },
        1000
      );

      /*
       * ------------------------------------------------------------
       * MUTATION OBSERVER
       * ------------------------------------------------------------
       */

      try {
        var observer =
          new MutationObserver(
            function() {
              configurarMenuHorizontal();
              enviarMidia(false);
            }
          );

        if (document.body) {
          observer.observe(
            document.body,
            {
              childList: true,
              subtree: true,
              attributes: true,
              attributeFilter: [
                'src',
                'data-src',
                'data-image',
                'data-url',
                'class',
                'style'
              ]
            }
          );
        }
      } catch(e) {}

      /*
       * ------------------------------------------------------------
       * EVENTOS DE VÍDEO
       * ------------------------------------------------------------
       */

      document.addEventListener(
        'loadedmetadata',
        function() {
          enviarMidia(false);
        },
        true
      );

      document.addEventListener(
        'play',
        function() {
          enviarMidia(false);
        },
        true
      );

      console.log(
        '[CONSERLAR] Configuração concluída.'
      );

    })();
  ''');
  }


  /*
   * ============================================================
   * AIRPLAY
   * ============================================================
   */

  void _acionarAirPlayNativo() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'O AirPlay é compatível apenas com dispositivos iOS/Apple.',
        ),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /*
   * ============================================================
   * SERVIDOR LOCAL
   * ============================================================
   */

  Future<void> _iniciarServidorProxyLocal() async {
    if (_localProxyServer != null) return;

    final router = shelf_router.Router();

    router.get('/proxy', (request) async {
      var target = request.url.queryParameters['url'];

      debugPrint('');
      debugPrint('======================================');
      debugPrint('PROXY REQUEST ORIGINAL: $target');
      debugPrint('======================================');

      if (target == null || target.isEmpty) {
        return shelf.Response.badRequest(
          body: 'URL não informada',
        );
      }

      // SE FOR O EMBED DO BUNNY, CONVERTEMOS PARA O LINK DO VÍDEO ANTES DO PROXY BUSCAR
      if (target.contains('mediadelivery.net/embed/')) {
        try {
          final uriTarget = Uri.parse(target);
          final segments = uriTarget.pathSegments;
          if (segments.length >= 3) {
            final libraryId = segments[1];
            final videoId = segments[2];

            // O servidor aponta para o .mp4 da CDN, mas quem vai buscar
            // injetando o Referer é o próprio servidor local!
            target = 'https://vz-84a4a5f4-d42.b-cdn.net/$videoId/play_360p.mp4';
            debugPrint('PROXY BUNNY CONVERTIDO INTERNAMENTE PARA: $target');
          }
        } catch (e) {
          debugPrint('ERRO CONVERSÃO BUNNY: $e');
        }
      }

      final client = http.Client();

      try {
        final uri = Uri.parse(target);

        // O SERVIDOR LOCAL APLICA O REFERER AQUI AO CHAMAR A CDN DO BUNNY
        final req = http.Request('GET', uri)
          ..headers['Referer'] = 'https://aluno.conserlar.com/'
          ..headers['User-Agent'] =
              'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) '
              'AppleWebKit/605.1.15 (KHTML, like Gecko) '
              'Version/16.0 Mobile/15E148 Safari/604.1';

        // Se o Chromecast mandou um header Range (pedindo pedaços do vídeo), repassamos para a CDN
        if (request.headers.containsKey('range')) {
          req.headers['Range'] = request.headers['range']!;
        }

        final response = await client.send(req);

        debugPrint('PROXY STATUS: ${response.statusCode}');
        debugPrint('PROXY CONTENT-TYPE: ${response.headers['content-type']}');

        // Repassamos o stream do vídeo com o cabeçalho correto para o Chromecast
        return shelf.Response(
          response.statusCode,
          body: response.stream,
          headers: {
            'Content-Type': response.headers['content-type'] ?? 'video/mp4',
            'Access-Control-Allow-Origin': '*',
            'Accept-Ranges': 'bytes',
            if (response.headers.containsKey('content-range'))
              'Content-Range': response.headers['content-range']!,
            if (response.headers.containsKey('content-length'))
              'Content-Length': response.headers['content-length']!,
            'Cache-Control': 'no-cache',
          },
        );
      } catch (e) {
        debugPrint('PROXY EXCEPTION: $e');
        return shelf.Response.internalServerError(
          body: e.toString(),
        );
      } 
    });

    router.get('/media/<id>', (request, id) async {
      final file = _mediaFiles[id];

      if (file == null || !await file.exists()) {
        debugPrint('MEDIA NÃO ENCONTRADA: $id');

        return shelf.Response.notFound(
          'Mídia não encontrada',
        );
      }

      final size = await file.length();
      final range = request.headers['range'];

      debugPrint(
        'MEDIA REQUEST: ${request.method} '
            '/media/$id Range=$range Size=$size',
      );

      final headers = {
        'Content-Type': 'video/mp4',
        'Accept-Ranges': 'bytes',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': '*',
        'Cache-Control': 'no-cache',
      };

      if (request.method == 'HEAD') {
        return shelf.Response.ok(
          null,
          headers: {
            ...headers,
            'Content-Length': size.toString(),
          },
        );
      }

      if (range == null || !range.startsWith('bytes=')) {
        return shelf.Response.ok(
          file.openRead(),
          headers: {
            ...headers,
            'Content-Length': size.toString(),
          },
        );
      }

      try {
        final value = range.substring(6).split('-');

        var start = int.tryParse(value[0]) ?? 0;

        var end =
        value.length > 1 && value[1].isNotEmpty
            ? int.tryParse(value[1]) ?? size - 1
            : size - 1;

        if (start >= size) {
          return shelf.Response(
            416,
            headers: {
              ...headers,
              'Content-Range': 'bytes */$size',
            },
          );
        }

        if (end >= size) {
          end = size - 1;
        }

        if (end < start) {
          end = size - 1;
        }

        final length = end - start + 1;

        debugPrint(
          'RANGE: $start-$end/$size',
        );

        return shelf.Response(
          206,
          body: file.openRead(start, end + 1),
          headers: {
            ...headers,
            'Content-Length': length.toString(),
            'Content-Range':
            'bytes $start-$end/$size',
          },
        );
      } catch (e) {
        debugPrint('ERRO RANGE: $e');

        return shelf.Response.badRequest(
          body: 'Range inválido',
        );
      }
    });

    try {
      _localProxyServer = await shelf_io.serve(
        router.call,
        '0.0.0.0',
        _localProxyPort,
      );

      debugPrint(
        'Servidor local: 0.0.0.0:$_localProxyPort',
      );
    } catch (e) {
      debugPrint(
        'Erro servidor local: $e',
      );
    }
  }

  /*
   * ============================================================
   * IP LOCAL
   * ============================================================
   */

  Future<String> _obterIpLocal() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );

      for (final i in interfaces) {
        for (final a in i.addresses) {
          final ip = a.address;

          if (ip.startsWith('192.168.') ||
              ip.startsWith('10.') ||
              RegExp(
                r'^172\.(1[6-9]|2[0-9]|3[0-1])\.',
              ).hasMatch(ip)) {
            debugPrint(
              'IP LOCAL SELECIONADO: $ip',
            );

            return ip;
          }
        }
      }

      for (final i in interfaces) {
        for (final a in i.addresses) {
          if (!a.isLoopback) {
            return a.address;
          }
        }
      }
    } catch (e) {
      debugPrint(
        'Erro obtendo IP: $e',
      );
    }

    return '127.0.0.1';
  }

  /*
   * ============================================================
   * PROXY BUNNY
   * ============================================================
   */

  Future<String> _gerarUrlProxyLocalParaBunny(
      String url,
      ) async {
    await _iniciarServidorProxyLocal();

    final ip = await _obterIpLocal();

    final proxyUrl =
        'http://$ip:$_localProxyPort/proxy'
        '?url=${Uri.encodeComponent(url)}';

    debugPrint('');
    debugPrint('======================================');
    debugPrint('URL PROXY');
    debugPrint(proxyUrl);
    debugPrint('======================================');

    return proxyUrl;
  }

  /*
   * ============================================================
   * IMAGEM -> MP4
   * ============================================================
   */

  Future<File> _converterImagemParaMp4(
      Uint8List bytes,
      ) async {
    final dir =
    await Directory.systemTemp.createTemp(
      'conserlar_cast_',
    );

    final input =
    File('${dir.path}/imagem.jpg');

    final output =
    File('${dir.path}/imagem.mp4');

    await input.writeAsBytes(
      bytes,
      flush: true,
    );

    final command =
        '-y '
        '-loop 1 '
        '-i "${input.path}" '
        '-t 5 '
        '-r 30 '
        '-vf "scale=trunc(iw/2)*2:trunc(ih/2)*2,format=yuv420p" '
        '-c:v libx264 '
        '-profile:v baseline '
        '-level 3.1 '
        '-preset ultrafast '
        '-pix_fmt yuv420p '
        '-movflags +faststart '
        '"${output.path}"';

    final session =
    await FFmpegKit.execute(command);

    final code =
    await session.getReturnCode();

    if (!ReturnCode.isSuccess(code)) {
      final logs =
      await session.getAllLogsAsString();

      await dir
          .delete(recursive: true)
          .catchError((_) {});

      throw Exception(
        'FFmpeg falhou:\n$logs',
      );
    }

    if (!await output.exists() ||
        await output.length() == 0) {
      throw Exception(
        'MP4 não foi criado corretamente.',
      );
    }

    return output;
  }

  /*
   * ============================================================
   * PUBLICAR MP4 LOCAL
   * ============================================================
   */

  Future<String> _publicarMp4ParaChromecast(
      File file,
      ) async {
    await _iniciarServidorProxyLocal();

    final ip = await _obterIpLocal();

    final id =
        '${DateTime.now().millisecondsSinceEpoch}_${file.hashCode}';

    _mediaFiles[id] = file;

    final url =
        'http://$ip:$_localProxyPort/media/$id';

    debugPrint('');
    debugPrint('======================================');
    debugPrint('CHROMECAST MP4');
    debugPrint('IP: $ip');
    debugPrint('ARQUIVO: ${file.path}');
    debugPrint(
      'TAMANHO: ${await file.length()} bytes',
    );
    debugPrint('URL: $url');
    debugPrint('======================================');

    return url;
  }

  /*
   * ============================================================
   * MENU CAST
   * ============================================================
   */

  void _mostrarMenuDispositivosTransmissao() {
    if (_currentMediaUrl.isEmpty ||
        !_pareceSerMidiaValida(
          _currentMediaUrl,
          _currentMediaType,
        )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nenhuma mídia real carregada!',
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: 380,
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Transmitir',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.grey,
                  ),
                  onPressed: () =>
                      Navigator.pop(context),
                ),
              ],
            ),
            const Text(
              'Selecione um aparelho:',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            const Divider(
              color: Colors.grey,
            ),
            Expanded(
              child: _BonsoirDeviceListWidget(
                castService: _castService,
                onDeviceSelected:
                    (device) async {
                  Navigator.pop(context);

                  await _enviarMidiaParaDispositivo(
                    device,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

/*
* ============================================================
* PAUSAR VÍDEO NA TV
* ============================================================
*/

  Future<void> _pausarVideoDaImagem(CastSession session) async {
    try {
      debugPrint('[CAST] Aguardando o vídeo da imagem iniciar...');

      await Future.delayed(const Duration(milliseconds: 800));

      debugPrint('[CAST] Pausando o vídeo criado a partir da imagem...');

      await session.pause();

      debugPrint('[CAST] Imagem congelada na tela.');
    } catch (e) {
      debugPrint('[CAST] Erro ao pausar vídeo da imagem: $e');
    }
  }

  /*
* ============================================================
* CAST
* ============================================================
*/

  Future<void> _enviarMidiaParaDispositivo(
      [CastDevice? device, bool silencioso = false]
      ) async {
    try {
      final targetDevice = device ?? _castService.activeSession?.device;
      if (targetDevice == null) return;

      debugPrint('');
      debugPrint('======================================');
      debugPrint('INICIANDO CAST');
      debugPrint('DEVICE: ${targetDevice.name}');
      debugPrint('IP: ${targetDevice.address.address}');
      debugPrint('PORTA: ${targetDevice.port}');
      debugPrint('TIPO: $_currentMediaType');
      debugPrint('URL ORIGINAL: $_currentMediaUrl');
      debugPrint('======================================');

      if (!_pareceSerMidiaValida(_currentMediaUrl, _currentMediaType)) {
        throw Exception('A URL capturada não é uma mídia válida: $_currentMediaUrl');
      }

      final session = await _castService.connect(targetDevice);
      final isImage = _currentMediaType == 'image';

      /*
       * ==========================================================
       * IMAGEM
       * ==========================================================
       */
      if (isImage) {
        if (!silencioso && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Preparando imagem...')),
          );
        }

        final proxyUrl = await _gerarUrlProxyLocalParaBunny(_currentMediaUrl);
        final response = await http.get(Uri.parse(proxyUrl));

        if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
          throw Exception('Erro baixando imagem: HTTP ${response.statusCode}');
        }

        if (!silencioso && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Convertendo imagem para vídeo...')),
          );
        }

        final mp4 = await _converterImagemParaMp4(response.bodyBytes);
        final mediaUrl = await _publicarMp4ParaChromecast(mp4);

        final tituloFinal = _currentMediaTitle.trim().isNotEmpty
            ? '${_currentMediaTitle.trim()} - Conserlar'
            : 'Esquema Conserlar';

        await session.loadMedia(
          CastMedia(
            url: mediaUrl,
            title: tituloFinal,
            type: CastMediaType.mp4,
          ),
        );

        await _pausarVideoDaImagem(session);

        if (!silencioso && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Imagem transmitida com sucesso!'),
              backgroundColor: Color(0xFF00C853),
            ),
          );
        }
        return;
      }

      /*
       * ==========================================================
       * VÍDEO (Com Proxy Local para injetar o Referer do Bunny)
       * ==========================================================
       */
      debugPrint('[CAST] Preparando vídeo com proxy (Referer)...');

      final videoUrl = await _gerarUrlProxyLocalParaBunny(_currentMediaUrl);

      debugPrint('');
      debugPrint('======================================');
      debugPrint('VIDEO CAST PROXY URL:');
      debugPrint(videoUrl);
      debugPrint('======================================');

      if (!silencioso && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transmitindo vídeo para a TV...')),
        );
      }

      final tituloVideoFinal = _currentMediaTitle.trim().isNotEmpty
          ? '${_currentMediaTitle.trim()} - Conserlar'
          : 'Aula Conserlar';

      await session.loadMedia(
        CastMedia(
          url: videoUrl,
          title: tituloVideoFinal,
          type: CastMediaType.mp4,
        ),
      );

      debugPrint('[CAST] Vídeo carregado na TV.');

      if (!silencioso && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vídeo transmitido com sucesso!'),
            backgroundColor: Color(0xFF00C853),
          ),
        );
      }

    } catch (e, stack) {
      debugPrint('');
      debugPrint('======================================');
      debugPrint('ERRO CAST');
      debugPrint('$e');
      debugPrint('$stack');
      debugPrint('======================================');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro na transmissão: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  /*
   * ============================================================
   * FULLSCREEN
   * ============================================================
   */

  void _toggleFullInterno() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });

    if (_isFullScreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);

      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
      );

      controller.runJavaScript('''
        var wrapper=document.getElementById('playerWrapper');
        var viewer=document.getElementById('mediaViewer');
        var apostila=document.getElementById('imagemApostila');

        if(wrapper){
          wrapper.style.setProperty('position','fixed','important');
          wrapper.style.setProperty('top','0','important');
          wrapper.style.setProperty('left','0','important');
          wrapper.style.setProperty('width','100vw','important');
          wrapper.style.setProperty('height','100vh','important');
          wrapper.style.setProperty('z-index','9999999','important');
          wrapper.style.setProperty('background','#000','important');
          wrapper.style.setProperty('margin','0','important');
          wrapper.style.setProperty('border-radius','0','important');
        }

        if(viewer){
          viewer.style.setProperty('width','100%','important');
          viewer.style.setProperty('height','100%','important');
        }

        if(apostila){
          apostila.style.setProperty('width','100%','important');
          apostila.style.setProperty('height','100%','important');
          apostila.style.setProperty('object-fit','contain','important');
        }

        if(!document.getElementById('btnSairFullscreenFlutuante')){
          var b=document.createElement('button');

          b.id='btnSairFullscreenFlutuante';

          b.innerHTML=
            '<i class="bi bi-x-lg me-1"></i> Sair';

          b.style.cssText=
            'position:fixed!important;' +
            'top:15px!important;' +
            'right:15px!important;' +
            'z-index:10000000!important;' +
            'background:rgba(220,53,69,.95)!important;' +
            'color:white!important;' +
            'border:1px solid rgba(255,255,255,.4)!important;' +
            'padding:8px 16px!important;' +
            'font-weight:bold!important;' +
            'border-radius:6px!important;' +
            'cursor:pointer!important;';

          b.onclick=function(e){
            e.preventDefault();

            window.location.href=
              'app://exit_full_clicked';
          };

          document.body.appendChild(b);
        }
      ''');
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
      );

      controller.runJavaScript('''
        var wrapper=document.getElementById('playerWrapper');
        var viewer=document.getElementById('mediaViewer');
        var apostila=document.getElementById('imagemApostila');

        if(wrapper) wrapper.style.cssText='';
        if(viewer) viewer.style.cssText='';
        if(apostila) apostila.style.cssText='';

        var b=
          document.getElementById(
            'btnSairFullscreenFlutuante'
          );

        if(b) b.remove();
      ''');
    }
  }

  /*
   * ============================================================
   * PARAR CAST
   * ============================================================
   */

  void _pararTransmissaoNaTv() async {
    try {
      await _castService.activeSession?.disconnect();
    } catch (_) {}
  }

  /*
   * ============================================================
   * LIFECYCLE
   * ============================================================
   */

  @override
  void didChangeAppLifecycleState(
      AppLifecycleState state,
      ) {
    setState(() {
      _conteudoVisivel =
          state == AppLifecycleState.resumed;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(
      this,
    );

    _localProxyServer?.close(
      force: true,
    );

    for (final file in _mediaFiles.values) {
      try {
        if (file.parent.existsSync()) {
          file.parent.deleteSync(
            recursive: true,
          );
        }
      } catch (_) {}
    }

    _mediaFiles.clear();

    SystemChrome.setPreferredOrientations(
      DeviceOrientation.values,
    );

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );

    super.dispose();
  }

  /*
   * ============================================================
   * BUILD
   * ============================================================
   */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            if (_conteudoVisivel)
              WebViewWidget(
                controller: controller,
              )
            else
              Container(
                color: Colors.black,
                child: const Center(
                  child: Text(
                    'CONTEÚDO PROTEGIDO',
                    style: TextStyle(
                      color: Color(0xFF7F8C8D),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/*
 * ==============================================================
 * DISCOVERY CHROMECAST
 * ==============================================================
 */

class _BonsoirDeviceListWidget
    extends StatefulWidget {
  final CastService castService;
  final Function(CastDevice) onDeviceSelected;

  const _BonsoirDeviceListWidget({
    required this.castService,
    required this.onDeviceSelected,
  });

  @override
  State<_BonsoirDeviceListWidget> createState() =>
      _BonsoirDeviceListWidgetState();
}

class _BonsoirDeviceListWidgetState
    extends State<_BonsoirDeviceListWidget> {
  BonsoirDiscovery? _chromecastDiscovery;

  final List<CastDevice> _foundDevices = [];

  bool _isSearching = true;

  @override
  void initState() {
    super.initState();

    _startDiscoveryUnified();
  }

  void _startDiscoveryUnified() async {
    _chromecastDiscovery =
        BonsoirDiscovery(
          type: '_googlecast._tcp',
        );

    await _chromecastDiscovery!.initialize();

    _chromecastDiscovery!
        .eventStream!
        .listen((event) {
      if (event
      is BonsoirDiscoveryServiceFoundEvent) {
        event.service?.resolve(
          _chromecastDiscovery!.serviceResolver,
        );
      } else if (event
      is BonsoirDiscoveryServiceResolvedEvent) {
        final service = event.service;

        if (service?.hostAddresses == null) {
          return;
        }

        String? ip;

        for (final addr
        in service!.hostAddresses!) {
          if (!addr.contains(':') &&
              addr.split('.').length == 4) {
            ip = addr;
            break;
          }
        }

        if (ip == null) return;

        final name =
        service.name.contains('.')
            ? service.name
            .split('.')
            .first
            : service.name;

        final device = CastDevice(
          id: service.name,
          name: name,
          address: InternetAddress(ip),
          port: service.port,
          protocol:
          CastProtocol.chromecast,
        );

        if (!_foundDevices.any(
              (d) =>
          d.address.address == ip,
        ) &&
            mounted) {
          setState(() {
            _foundDevices.add(device);
            _isSearching = false;
          });
        }
      }
    });

    await _chromecastDiscovery!.start();
  }

  @override
  void dispose() {
    _chromecastDiscovery?.stop();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CastDevice>>(
      stream:
      widget.castService.startDiscovery(),
      builder: (context, snapshot) {
        final devices =
        <CastDevice>[];

        if (snapshot.hasData) {
          devices.addAll(snapshot.data!);
        }

        for (final d in _foundDevices) {
          if (!devices.any(
                (x) =>
            x.address.address ==
                d.address.address,
          )) {
            devices.add(d);
          }
        }

        if (devices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment:
              MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  color: Color(0xFF00E676),
                ),
                const SizedBox(
                  height: 12,
                ),
                Text(
                  _isSearching
                      ? 'Procurando aparelhos na rede...'
                      : 'Nenhum dispositivo encontrado',
                  style:
                  const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: devices.length,
          itemBuilder:
              (context, index) {
            final device =
            devices[index];

            return ListTile(
              leading: const Icon(
                Icons.cast,
                color: Color(0xFF00E676),
              ),
              title: Text(
                device.name,
                style:
                const TextStyle(
                  color: Colors.white,
                ),
              ),
              subtitle: Text(
                'Protocolo: '
                    '${device.protocol.name.toUpperCase()} '
                    '• IP: '
                    '${device.address.address}',
                style:
                const TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                ),
              ),
              trailing:
              const Icon(
                Icons.cast_connected,
                color: Colors.white70,
              ),
              onTap: () =>
                  widget.onDeviceSelected(
                    device,
                  ),
            );
          },
        );
      },
    );
  }
}

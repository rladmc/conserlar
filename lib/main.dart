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

class _TelaDeEstudosSeguraState extends State<TelaDeEstudosSegura> with WidgetsBindingObserver {
  late final WebViewController controller;
  bool _conteudoVisivel = true;
  bool _isFullScreen = false;
  String _currentMediaUrl = '';
  String _currentMediaTitle = '';
  String _currentMediaType = 'video';
  HttpServer? _localProxyServer;
  final int _localProxyPort = 8080;

  late final CastService _castService = CastService(
    discoveryProviders: [ChromecastDiscoveryProvider(), DlnaDiscoveryProvider()],
    sessionFactory: (device) {
      switch (device.protocol) {
        case CastProtocol.chromecast:
          return ChromecastSession(device: device);
        case CastProtocol.dlna:
          final dlnaDescription = DlnaDeviceDescription(
            friendlyName: device.name, manufacturer: 'Generic DLNA', modelName: 'Smart TV', udn: device.id,
            locationUrl: 'http://${device.address}:${device.port}/description.xml',
          );
          return DlnaSession(device: device, description: dlnaDescription);
        case CastProtocol.airplay:
          return AirPlaySession(device);
        default:
          throw UnsupportedError('Protocolo não suportado: ${device.protocol}');
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
      ..addJavaScriptChannel('AndroidCastBridge', onMessageReceived: (JavaScriptMessage message) {
        try {
          final data = jsonDecode(message.message);
          if (!mounted) return;
          setState(() {
            _currentMediaUrl = data['url'] ?? '';
            _currentMediaTitle = data['titulo'] ?? 'Conserlar Aula';
            _currentMediaType = data['tipo'] ?? 'video';
          });
          if ((data['abrirMenu'] ?? false) && _currentMediaUrl.isNotEmpty) {
            _mostrarMenuDispositivosTransmissao();
          }
        } catch (e) {
          if (message.message.contains('pararTransmissao')) _pararTransmissaoNaTv();
        }
      })
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (NavigationRequest request) {
          if (request.url.contains('app://full_clicked')) {
            _toggleFullInterno();
            return NavigationDecision.prevent;
          }
          if (request.url.contains('app://airplay_clicked')) {
            _acionarAirPlayNativo();
            return NavigationDecision.prevent;
          }
          if (request.url.contains('app://cast_clicked')) {
            if (_currentMediaUrl.isNotEmpty) {
              _mostrarMenuDispositivosTransmissao();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aguarde a mídia carregar na tela...')));
            }
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
        onPageFinished: (String url) {
          controller.runJavaScript('''
            (function() {
              var style = document.createElement('style');
              style.innerHTML = `
                body { background-color: #121212 !important; color: #E0E0E0 !important; }
                
                /* Libera o container para não cortar nada à esquerda */
                header, nav, .navbar, .navbar-nav, .menu, .container-fluid, .row, div {
                  overflow: visible;
                }

                /* Força a barra de navegação/menu principal a aceitar scroll horizontal completo, alinhado à esquerda */
                header nav, .navbar-nav, .menu, nav ul, .nav, .nav-tabs, [class*="menu"], [class*="nav"] {
                  display: flex !important;
                  flex-direction: row !important;
                  flex-wrap: nowrap !important;
                  justify-content: flex-start !important;
                  align-items: center !important;
                  overflow-x: auto !important;
                  overflow-y: hidden !important;
                  white-space: nowrap !important;
                  -webkit-overflow-scrolling: touch !important;
                  scrollbar-width: none !important;
                  padding-left: 10px !important;
                }
                
                /* Esconde a barra de rolagem visual mantendo a função de toque */
                header nav::-webkit-scrollbar, .navbar-nav::-webkit-scrollbar, .menu::-webkit-scrollbar, nav ul::-webkit-scrollbar, .nav::-webkit-scrollbar, .nav-tabs::-webkit-scrollbar {
                  display: none !important;
                }

                /* Garante que todos os itens do menu fiquem acessíveis, sem encolher */
                header nav li, .navbar-nav li, .menu li, nav ul li, .nav-item, .nav-link, a {
                  flex: 0 0 auto !important;
                  white-space: nowrap !important;
                  display: inline-block !important;
                }
              `;
              document.head.appendChild(style);

              var checkBtnCastName = setInterval(function() {
                var btnCastSite = document.getElementById('btnCast');
                if (btnCastSite && !btnCastSite.dataset.configurado) {
                  btnCastSite.dataset.configurado = "true";
                  btnCastSite.innerText = "Transmitir";
                  btnCastSite.onclick = function(e) {
                    e.preventDefault();
                    var info = getMidiaInfo();
                    info.abrirMenu = true;
                    if (window.AndroidCastBridge) window.AndroidCastBridge.postMessage(JSON.stringify(info));
                  };
                  clearInterval(checkBtnCastName);
                }
              }, 500);

              var checkBtnFullName = setInterval(function() {
                var btnFullSite = document.getElementById('btnFull');
                if (btnFullSite && !btnFullSite.dataset.configurado) {
                  btnFullSite.dataset.configurado = "true";
                  btnFullSite.innerText = "Full";
                  btnFullSite.id = "btnFullInjetado";
                  btnFullSite.onclick = function(e) {
                    e.preventDefault();
                    window.location.href = "app://full_clicked";
                  };
                  clearInterval(checkBtnFullName);
                }
              }, 500);

              function getMidiaInfo() {
                var mediaViewer = document.getElementById('mediaViewer');
                if (mediaViewer && mediaViewer.src && !mediaViewer.classList.contains('d-none') && mediaViewer.src !== window.location.href && mediaViewer.src !== "") {
                  var srcUrl = mediaViewer.src;
                  if (srcUrl.includes('mediadelivery.net')) {
                    var partes = srcUrl.split('/');
                    var videoId = partes[partes.length - 1].split('?')[0];
                    if (videoId && videoId.length > 10) {
                      return { url: "https://vz-84a4a5f4-d42.b-cdn.net/" + videoId + "/play_360p.mp4", titulo: document.title || 'Aula Conserlar', tipo: 'video', abrirMenu: false };
                    }
                  }
                  return { url: srcUrl, titulo: document.title || 'Aula Conserlar', tipo: 'video', abrirMenu: false };
                }
                var imgApostila = document.getElementById('imagemApostila');
                if (imgApostila && !imgApostila.classList.contains('d-none')) {
                  var iUrl = imgApostila.src || imgApostila.getAttribute('data-src') || '';
                  if (iUrl) return { url: iUrl, titulo: document.title || 'Esquema Conserlar', tipo: 'image', abrirMenu: false };
                }
                return { url: '', titulo: '', tipo: 'video', abrirMenu: false };
              }

              setInterval(function() {
                var info = getMidiaInfo();
                if (info.url && window.AndroidCastBridge) window.AndroidCastBridge.postMessage(JSON.stringify(info));
              }, 2000);
            })();
          ''');
        },
      ))
      ..loadRequest(Uri.parse('https://aluno.conserlar.com'));
  }

  Future<void> _iniciarServidorProxyLocal() async {
    if (_localProxyServer != null) return;
    final router = shelf_router.Router();
    router.get('/proxy', (shelf.Request request) async {
      final targetUrlStr = request.requestedUri.queryParameters['url'];
      if (targetUrlStr == null || targetUrlStr.isEmpty) return shelf.Response.badRequest(body: 'URL não informada');
      final client = http.Client();
      try {
        final proxyReq = http.Request('GET', Uri.parse(targetUrlStr));
        proxyReq.headers['Referer'] = 'https://aluno.conserlar.com';
        proxyReq.headers['User-Agent'] = 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1';
        final streamedResponse = await client.send(proxyReq);
        final bytes = await streamedResponse.stream.toBytes();
        final contentType = streamedResponse.headers['content-type'] ?? 'application/octet-stream';
        return shelf.Response(streamedResponse.statusCode, body: bytes, headers: {'Content-Type': contentType, 'Content-Length': bytes.length.toString(), 'Access-Control-Allow-Origin': '*', 'Cache-Control': 'no-cache'});
      } catch (e) {
        return shelf.Response.internalServerError(body: e.toString());
      } finally {
        client.close();
      }
    });
    try {
      _localProxyServer = await shelf_io.serve(router.call, '0.0.0.0', _localProxyPort);
    } catch (_) {}
  }

  Future<String> _gerarUrlProxyLocalParaBunny(String urlOriginal) async {
    await _iniciarServidorProxyLocal();
    String localIp = '127.0.0.1';
    try {
      for (final interface in await NetworkInterface.list()) {
        for (final addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            localIp = addr.address;
            break;
          }
        }
        if (localIp != '127.0.0.1') break;
      }
    } catch (_) {}
    return 'http://$localIp:$_localProxyPort/proxy?url=${Uri.encodeComponent(urlOriginal)}';
  }

  Future<Uint8List> _converterImagemParaMp4(Uint8List imageBytes) async {
    Directory? tempDir;
    try {
      tempDir = await Directory.systemTemp.createTemp('conserlar_cast_');
      final inputFile = File('${tempDir.path}/imagem.jpg');
      final outputFile = File('${tempDir.path}/imagem.mp4');
      await inputFile.writeAsBytes(imageBytes, flush: true);
      final command = '-y -loop 1 -i "${inputFile.path}" -t 2 -r 25 -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" -c:v libx264 -preset ultrafast -tune stillimage -pix_fmt yuv420p -movflags +faststart "${outputFile.path}"';
      final session = await FFmpegKit.execute(command);
      if (!ReturnCode.isSuccess(await session.getReturnCode())) throw Exception('FFmpeg falhou');
      return await outputFile.readAsBytes();
    } finally {
      if (tempDir != null) await tempDir.delete(recursive: true).catchError((_) {});
    }
  }

  void _mostrarMenuDispositivosTransmissao() {
    if (_currentMediaUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nenhuma mídia carregada!'), backgroundColor: Colors.red));
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 380,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Transmitir Mídia na Rede', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Text('Selecione um aparelho:', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const Divider(color: Colors.grey),
              Expanded(
                child: _BonsoirDeviceListWidget(
                  castService: _castService,
                  onDeviceSelected: (device) async {
                    Navigator.pop(context);
                    await _enviarMidiaParaDispositivo(device);
                  },
                ),
              ),
              if (Platform.isIOS)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Color(0xFF198754)), minimumSize: const Size(double.infinity, 40)),
                    icon: const Icon(Icons.airplay, color: Color(0xFF00E676)),
                    label: const Text('Usar AirPlay Nativo (Apple TV)'),
                    onPressed: () { Navigator.pop(context); _acionarAirPlayNativo(); },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _enviarMidiaParaDispositivo(CastDevice device) async {
    try {
      final session = await _castService.connect(device);
      final bool isImage = _currentMediaType == 'image';
      if (isImage) {
        final imageProxyUrl = await _gerarUrlProxyLocalParaBunny(_currentMediaUrl);
        final imageResponse = await http.get(Uri.parse(imageProxyUrl));
        final mp4Bytes = await _converterImagemParaMp4(imageResponse.bodyBytes);
        final mediaSource = MediaSource.bytes(mp4Bytes, contentType: 'video/mp4');
        final imageMedia = CastMedia.source(mediaSource, type: CastMediaType.mp4, fileExtension: '.mp4', title: _currentMediaTitle.trim().isNotEmpty ? _currentMediaTitle.trim() : 'Esquema Conserlar');
        await session.loadMedia(imageMedia);
        try {
          await session.stateStream.firstWhere((state) => state == SessionState.playing).timeout(const Duration(seconds: 5));
          await session.pause();
        } catch (_) {}
        return;
      }
      final videoProxyUrl = await _gerarUrlProxyLocalParaBunny(_currentMediaUrl);
      final videoMedia = CastMedia(url: videoProxyUrl, title: _currentMediaTitle.trim().isNotEmpty ? _currentMediaTitle.trim() : 'Aula Conserlar', type: CastMediaType.mp4);
      await session.loadMedia(videoMedia);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro na transmissão: $e'), backgroundColor: Colors.red));
    }
  }

  void _toggleFullInterno() {
    setState(() => _isFullScreen = !_isFullScreen);
    if (_isFullScreen) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      controller.runJavaScript('const wrapper = document.getElementById("playerWrapper"); if(wrapper) { wrapper.style.setProperty("position", "fixed", "important"); wrapper.style.setProperty("top", "0", "important"); wrapper.style.setProperty("left", "0", "important"); wrapper.style.setProperty("width", "100vw", "important"); wrapper.style.setProperty("height", "100vh", "important"); wrapper.style.setProperty("z-index", "999999", "important"); }');
    } else {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      controller.runJavaScript('const wrapper = document.getElementById("playerWrapper"); if(wrapper) wrapper.style.cssText = "";');
    }
  }

  void _acionarAirPlayNativo() async {
    if (_currentMediaUrl.isEmpty) return;
    try {
      final urlProxyLocal = await _gerarUrlProxyLocalParaBunny(_currentMediaUrl);
      await FlutterIosAirplay.url(url: urlProxyLocal);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao iniciar AirPlay: $e'), backgroundColor: Colors.red));
    }
  }

  void _pararTransmissaoNaTv() async {
    try { await _castService.activeSession?.disconnect(); } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() { _conteudoVisivel = (state == AppLifecycleState.resumed); });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _localProxyServer?.close(force: true);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            if (_conteudoVisivel) WebViewWidget(controller: controller)
            else Container(color: Colors.black, child: const Center(child: Text('CONTEÚDO PROTEGIDO', style: TextStyle(color: Color(0xFF7F8C8D), fontSize: 14, fontWeight: FontWeight.bold))))
          ],
        ),
      ),
    );
  }
}

class _BonsoirDeviceListWidget extends StatefulWidget {
  final CastService castService;
  final Function(CastDevice) onDeviceSelected;
  const _BonsoirDeviceListWidget({required this.castService, required this.onDeviceSelected});
  @override
  State<_BonsoirDeviceListWidget> createState() => _BonsoirDeviceListWidgetState();
}

class _BonsoirDeviceListWidgetState extends State<_BonsoirDeviceListWidget> {
  BonsoirDiscovery? _chromecastDiscovery;
  final List<CastDevice> _foundDevices = [];
  bool _isSearching = true;

  @override
  void initState() {
    super.initState();
    _startDiscoveryUnified();
  }

  void _startDiscoveryUnified() async {
    // Inicializa o Bonsoir para varrer Chromecast no iOS de forma nativa
    _chromecastDiscovery = BonsoirDiscovery(type: '_googlecast._tcp');
    await _chromecastDiscovery!.initialize();
    _chromecastDiscovery!.eventStream!.listen((event) {
      if (event is BonsoirDiscoveryServiceFoundEvent) {
        event.service?.resolve(_chromecastDiscovery!.serviceResolver);
      } else if (event is BonsoirDiscoveryServiceResolvedEvent) {
        final resolvedService = event.service;
        if (resolvedService != null && resolvedService.hostAddresses != null) {
          String? ipv4Address;
          for (var addr in resolvedService.hostAddresses!) {
            if (!addr.contains(':') && addr.split('.').length == 4) { ipv4Address = addr; break; }
          }
          if (ipv4Address != null) {
            String deviceName = resolvedService.name.contains('.') ? resolvedService.name.split('.').first : resolvedService.name;
            final device = CastDevice(id: resolvedService.name, name: deviceName, address: InternetAddress(ipv4Address), port: resolvedService.port, protocol: CastProtocol.chromecast);
            if (!_foundDevices.any((d) => d.address.address == device.address.address) && mounted) {
              setState(() { _foundDevices.add(device); _isSearching = false; });
            }
          }
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
    // Unifica a listagem utilizando tanto o Bonsoir (essencial pro iOS achar Chromecast na rede local) quanto o nativo do CastService
    return StreamBuilder<List<CastDevice>>(
      stream: widget.castService.startDiscovery(),
      builder: (context, snapshot) {
        final List<CastDevice> devices = [];
        if (snapshot.hasData) {
          devices.addAll(snapshot.data!);
        }
        for (var d in _foundDevices) {
          if (!devices.any((existing) => existing.address.address == d.address.address)) {
            devices.add(d);
          }
        }

        if (devices.isEmpty) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const CircularProgressIndicator(color: Color(0xFF00E676)),
            const SizedBox(height: 12),
            Text(_isSearching ? "Procurando aparelhos na rede..." : "Nenhum dispositivo encontrado", style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ]));
        }

        return ListView.builder(
          itemCount: devices.length,
          itemBuilder: (context, index) {
            final device = devices[index];
            return ListTile(
              leading: const Icon(Icons.cast, color: Color(0xFF00E676)),
              title: Text(device.name, style: const TextStyle(color: Colors.white)),
              subtitle: Text("Protocolo: ${device.protocol.name.toUpperCase()} • IP: ${device.address.address}", style: const TextStyle(color: Colors.grey, fontSize: 11)),
              trailing: const Icon(Icons.cast_connected, color: Colors.white70),
              onTap: () => widget.onDeviceSelected(device),
            );
          },
        );
      },
    );
  }
}
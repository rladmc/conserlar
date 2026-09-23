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

HttpServer? _localProxyServer;
int _localProxyPort = 8080;

// Inicia o servidor local
Future<void> _iniciarServidorProxyLocal() async {
  if (_localProxyServer != null) return;

  // Usa o prefixo shelf_router para evitar conflito com o Router do Flutter
  final router = shelf_router.Router();

  router.get('/proxy', (shelf.Request request) async {
    final targetUrlStr = request.requestedUri.queryParameters['url'];
    if (targetUrlStr == null || targetUrlStr.isEmpty) {
      return shelf.Response.badRequest(body: 'URL não informada');
    }

    final client = http.Client();
    try {
      final targetUri = Uri.parse(targetUrlStr);
      final proxyReq = http.Request('GET', targetUri);

      // Injeta os cabeçalhos exigidos pelo Bunny CDN
      proxyReq.headers['Referer'] = 'https://aluno.conserlar.com';
      proxyReq.headers['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36';

      if (request.headers.containsKey('range')) {
        proxyReq.headers['Range'] = request.headers['range']!;
      }

      final streamedResponse = await client.send(proxyReq);

      // Detecta se é imagem para ajustar os headers de entrega na TV
      final isImage = targetUrlStr.toLowerCase().contains('.jpg') ||
          targetUrlStr.toLowerCase().contains('.jpeg') ||
          targetUrlStr.toLowerCase().contains('.png');

      final headers = <String, String>{
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': '*',
        'Accept-Ranges': 'bytes',
      };

      streamedResponse.headers.forEach((key, value) {
        if (key.toLowerCase() != 'transfer-encoding') {
          headers[key] = value;
        }
      });

      // Se for imagem, forçamos o tipo correto para o client/TV reconhecer
      if (isImage) {
        headers['Content-Type'] = targetUrlStr.toLowerCase().contains('.png') ? 'image/png' : 'image/jpeg';
      }

      return shelf.Response(
        streamedResponse.statusCode,
        body: streamedResponse.stream.handleError((_, __) {}),
        headers: headers,
      );
    } catch (e) {
      client.close();
      debugPrint("[ProxyLocal] Erro no streaming proxy: $e");
      return shelf.Response.internalServerError(body: e.toString());
    }
  });

  try {
    // MUDE DE '127.0.0.1' PARA '0.0.0.0' PARA LIBERAR A REDE WI-FI
    _localProxyServer = await shelf_io.serve(router.call, '0.0.0.0', _localProxyPort);
    debugPrint('[ProxyLocal] Servidor rodando na rede em http://0.0.0.0:$_localProxyPort');
  } catch (e) {
    debugPrint('[ProxyLocal] Erro ao iniciar servidor local: $e');
  }
}

Future<String> _gerarUrlProxyLocalParaBunny(String urlOriginal) async {
  await _iniciarServidorProxyLocal();

  String localIp = '127.0.0.1';
  try {
    for (var interface in await NetworkInterface.list()) {
      for (var addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
          localIp = addr.address;
          break;
        }
      }
    }
  } catch (_) {}

  final encodedUrl = Uri.encodeComponent(urlOriginal);
  return 'http://$localIp:$_localProxyPort/proxy?url=$encodedUrl';
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

// ==========================================
// TELA DA PLATAFORMA DO ALUNO (COM PROXY LOCAL E BONSOIR iOS)
// ==========================================

class TelaDeEstudosSegura extends StatefulWidget {
  const TelaDeEstudosSegura({super.key});

  @override
  State<TelaDeEstudosSegura> createState() => _TelaDeEstudosSeguraState();
}

class _TelaDeEstudosSeguraState extends State<TelaDeEstudosSegura> with WidgetsBindingObserver {
  late final WebViewController controller;
  bool _conteudoVisivel = true;
  bool _isFullScreen = false;

  // Dados da mídia atual extraídos do WebView
  String _currentMediaUrl = '';
  String _currentMediaTitle = '';
  String _currentMediaType = 'video';

  // ==========================================
  // CONFIGURAÇÃO DO SERVIDOR PROXY LOCAL (BUNNY CDN)
  // ==========================================
  HttpServer? _localProxyServer;
  final int _localProxyPort = 8080;

  // ==========================================
  // SERVIÇO DE CAST UNIFICADO (ANDROID)
  // ==========================================
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
          final dlnaDescription = DlnaDeviceDescription(
            friendlyName: device.name,
            manufacturer: 'Generic DLNA',
            modelName: 'Smart TV',
            udn: device.id,
            locationUrl: 'http://${device.address}:${device.port}/description.xml',
          );
          return DlnaSession(
            device: device,
            description: dlnaDescription,
          );
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
    _protegerTela();

    // Inicia o servidor proxy local assim que a tela sobe na rede Wi-Fi
    _iniciarServidorProxyLocal();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent("iphoneconserlar2026")

    // ==========================================
    // PONTE DE COMUNICAÇÃO DE CAST / CONTROLE (JS -> FLUTTER)
    // ==========================================
      ..addJavaScriptChannel(
        'AndroidCastBridge',
        onMessageReceived: (JavaScriptMessage message) {
          try {
            final data = jsonDecode(message.message);
            setState(() {
              _currentMediaUrl = data['url'] ?? '';
              _currentMediaTitle = data['titulo'] ?? 'Conserlar Aula';
              _currentMediaType = data['tipo'] ?? 'video';
            });
            final bool dispararMenu = data['abrirMenu'] ?? false;

            debugPrint("Mídia capturada -> URL: $_currentMediaUrl | Tipo:$_currentMediaType");

            if (dispararMenu && _currentMediaUrl.isNotEmpty) {
              _mostrarMenuDispositivosTransmissao();
            }
          } catch (e) {
            if (message.message.contains("pararTransmissao")) {
              _pararTransmissaoNaTv();
            }
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            String url = request.url;

            if (url.contains("app://full_clicked")) {
              _toggleFullInterno();
              return NavigationDecision.prevent;
            }

            if (url.contains("app://airplay_clicked")) {
              debugPrint("AirPlay acionado pelo site");
              _acionarAirPlayNativo();
              return NavigationDecision.prevent;
            }

            if (url.contains("app://cast_clicked")) {
              debugPrint("Cast acionado pelo site");
              if (_currentMediaUrl.isNotEmpty) {
                _mostrarMenuDispositivosTransmissao();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Aguarde a mídia carregar na tela...")),
                );
              }
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
          onPageFinished: (String url) {
            final bool isIosDevice = Platform.isIOS;

            controller.runJavaScript(
              '''
              (function() {
                var style = document.createElement('style');
                style.innerHTML = `
                    body {
                        -webkit-tap-highlight-color: transparent;
                        -webkit-touch-callout: none;
                        overscroll-behavior-y: contain;
                        background-color: #121212 !important;
                        color: #E0E0E0 !important;
                    }
                    button[onclick*="alternarAba"] {
                        display: none !important;
                    }
                    button, .btn {
                        border-radius: 8px !important;
                        cursor: pointer;
                    }
                    video, iframe {
                        max-width: 100% !important;
                        border-radius: 8px;
                    }
                    
                    .app-injected-btn {
                      display: inline-flex;
                      align-items: center;
                      gap: 5px;
                      margin-left: 6px;
                      padding: 6px 12px;
                      background-color: #212529;
                      color: #fff;
                      border: 1px solid #198754;
                      border-radius: 4px;
                      font-size: 14px;
                      cursor: pointer;
                      vertical-align: middle;
                      z-index: 99999;
                    }
                    .app-injected-btn:hover {
                      background-color: #198754;
                    }
                    
                    #containerTabelaErros .table {
                        font-size: 11px !important;
                    }
                    #containerTabelaErros th, 
                    #containerTabelaErros td {
                        padding: 4px 6px !important;
                        word-break: break-word;
                    }

                    #menuNavegacaoSuperior {
                        display: flex !important;
                        flex-wrap: nowrap !important;
                        overflow-x: auto !important;
                        overflow-y: hidden !important;
                        justify-content: flex-start !important;
                        white-space: nowrap !important;
                        padding-bottom: 10px !important;
                        -webkit-overflow-scrolling: touch;
                        scrollbar-width: none;
                    }
                    #menuNavegacaoSuperior::-webkit-scrollbar {
                        display: none; 
                    }
                    #menuNavegacaoSuperior .nav-item {
                        flex: 0 0 auto !important;
                        margin-right: 8px !important;
                    }
                    #menuNavegacaoSuperior .nav-link {
                        background-color: #1E1E1E !important;
                        border: 1px solid #333 !important;
                        border-radius: 20px !important;
                        padding: 8px 16px !important;
                        font-size: 13px !important;
                        transition: all 0.2s ease;
                    }
                    #menuNavegacaoSuperior .nav-link.active {
                        background-color: #00E676 !important;
                        color: #000 !important;
                        border-color: #00E676 !important;
                        font-weight: bold;
                    }
                `;
                document.head.appendChild(style);      

                var checkBtnCastName = setInterval(function() {
                    var btnCastSite = document.getElementById('btnCast');
                    if (btnCastSite && !btnCastSite.dataset.configurado) {
                        btnCastSite.dataset.configurado = "true";
                        btnCastSite.innerText = "Transmitir";
                        btnCastSite.style.cursor = "pointer";
                        
                        btnCastSite.onclick = function(e) {
                            e.preventDefault();
                            var info = getMidiaInfo();
                            info.abrirMenu = true;
                            if (window.AndroidCastBridge) {
                                window.AndroidCastBridge.postMessage(JSON.stringify(info));
                            }
                        };

                        var isIos = $isIosDevice;
                        if (isIos && !document.getElementById('btnAirPlayInjetado')) {
                          var btnAirPlay = document.createElement('button');
                          btnAirPlay.className = "app-injected-btn";
                          btnAirPlay.id = "btnAirPlayInjetado";
                          btnAirPlay.innerHTML = "AirPlay";
                          btnAirPlay.onclick = function(e) {
                            e.preventDefault();
                            window.location.href = "app://airplay_clicked";
                          };
                          btnCastSite.parentNode.insertBefore(btnAirPlay, btnCastSite.nextSibling);
                        }
                        clearInterval(checkBtnCastName);
                    }
                }, 500);
                
                var checkBtnFullName = setInterval(function() {
                    var btnFullSite = document.getElementById('btnFull');
                    if (btnFullSite && !btnFullSite.dataset.configurado) {
                        btnFullSite.dataset.configurado = "true";
                        btnFullSite.innerText = "Full";
                        btnFullSite.id = "btnFullInjetado";
                        btnFullSite.style.cursor = "pointer";
                        
                        btnFullSite.onclick = function(e) {
                            e.preventDefault();
                            window.location.href = "app://full_clicked";
                        };
                        clearInterval(checkBtnFullName);
                    }
                }, 500);

                document.addEventListener('contextmenu', function(e) {
                    if (e.target.tagName === 'VIDEO' || e.target.tagName === 'IMG' || e.target.tagName === 'IFRAME') {
                        e.preventDefault();
                    }
                });

                function getMidiaInfo() {
                    var mediaViewer = document.getElementById('mediaViewer');
                    if (mediaViewer && mediaViewer.src && !mediaViewer.classList.contains('d-none') && mediaViewer.src !== window.location.href && mediaViewer.src !== "") {
                        var srcUrl = mediaViewer.src;
                        if (srcUrl.includes('mediadelivery.net')) {
                            var partes = srcUrl.split('/');
                            var videoId = partes[partes.length - 1].split('?')[0];
                            if (videoId && videoId.length > 10) {
                                var urlDiretaVideo = "https://vz-84a4a5f4-d42.b-cdn.net/" + videoId + "/play_360p.mp4";
                                return { url: urlDiretaVideo, titulo: document.title || 'Aula Conserlar', tipo: 'video', abrirMenu: false };
                            }
                        }
                        return { url: srcUrl, titulo: document.title || 'Aula Conserlar', tipo: 'video', abrirMenu: false };
                    }

                    var imgApostila = document.getElementById('imagemApostila');
                    if (imgApostila) {
                        var iUrl = imgApostila.src || imgApostila.getAttribute('data-src') || '';
                        if (iUrl && !imgApostila.classList.contains('d-none')) {
                            return { url: iUrl, titulo: document.title || 'Esquema Conserlar', tipo: 'image', abrirMenu: false };
                        }
                    }
                    return { url: '', titulo: '', tipo: 'video', abrirMenu: false };
                }

                setInterval(function() {
                    var info = getMidiaInfo();
                    if (info.url && window.AndroidCastBridge) {
                        window.AndroidCastBridge.postMessage(JSON.stringify(info));
                    }
                }, 2000);
              })();
              ''',
            );
          },
        ),
      )
      ..loadRequest(Uri.parse('https://aluno.conserlar.com'));
  }

  // ==========================================
  // SERVIDOR PROXY LOCAL (BUNNY CDN)
  // ==========================================
  Future<void> _iniciarServidorProxyLocal() async {
    if (_localProxyServer != null) return;

    final router = shelf_router.Router();

    router.get('/proxy', (shelf.Request request) async {
      final targetUrlStr = request.requestedUri.queryParameters['url'];
      if (targetUrlStr == null || targetUrlStr.isEmpty) {
        return shelf.Response.badRequest(body: 'URL não informada');
      }

      final client = http.Client();
      try {
        final targetUri = Uri.parse(targetUrlStr);
        final proxyReq = http.Request('GET', targetUri);

        proxyReq.headers['Referer'] = 'https://aluno.conserlar.com';
        proxyReq.headers['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36';

        if (request.headers.containsKey('range')) {
          proxyReq.headers['Range'] = request.headers['range']!;
        }

        final streamedResponse = await client.send(proxyReq);

        final isImage = targetUrlStr.toLowerCase().contains('.jpg') ||
            targetUrlStr.toLowerCase().contains('.jpeg') ||
            targetUrlStr.toLowerCase().contains('.png');

        final headers = <String, String>{
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Headers': '*',
          'Accept-Ranges': 'bytes',
        };

        streamedResponse.headers.forEach((key, value) {
          if (key.toLowerCase() != 'transfer-encoding') {
            headers[key] = value;
          }
        });

        if (isImage) {
          headers['Content-Type'] = targetUrlStr.toLowerCase().contains('.png') ? 'image/png' : 'image/jpeg';
        }

        return shelf.Response(
          streamedResponse.statusCode,
          body: streamedResponse.stream.handleError((_, __) {}),
          headers: headers,
        );
      } catch (e) {
        client.close();
        debugPrint("[ProxyLocal] Erro no streaming proxy: $e");
        return shelf.Response.internalServerError(body: e.toString());
      }
    });

    try {
      _localProxyServer = await shelf_io.serve(router.call, '0.0.0.0', _localProxyPort);
      debugPrint('[ProxyLocal] Servidor rodando na rede em http://0.0.0.0:$_localProxyPort');
    } catch (e) {
      debugPrint('[ProxyLocal] Erro ao iniciar servidor local: $e');
    }
  }

  Future<String> _gerarUrlProxyLocalParaBunny(String urlOriginal) async {
    await _iniciarServidorProxyLocal();

    String localIp = '127.0.0.1';
    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            localIp = addr.address;
            break;
          }
        }
      }
    } catch (_) {}

    final encodedUrl = Uri.encodeComponent(urlOriginal);
    return 'http://$localIp:$_localProxyPort/proxy?url=$encodedUrl';
  }

  // ==========================================
  // MENU DE TRANSMISSÃO MULTIPLATAFORMA
  // ==========================================
  void _mostrarMenuDispositivosTransmissao() {
    if (_currentMediaUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nenhuma mídia carregada para transmitir!"), backgroundColor: Colors.red),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isDismissible: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
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
                  const Text(
                    "Transmitir Mídia na Rede",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Text(
                "Selecione um aparelho compatível abaixo:",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const Divider(color: Colors.grey),
              Expanded(
                child: Platform.isIOS
                    ? _BonsoirDeviceListWidget(
                  onDeviceSelected: (device) async {
                    Navigator.pop(context);
                    await _enviarMidiaParaDispositivo(device);
                  },
                )
                    : StreamBuilder<List<CastDevice>>(
                  stream: _castService.startDiscovery(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Color(0xFF00E676)),
                            SizedBox(height: 12),
                            Text("Procurando Chromecasts e TVs...", style: TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      );
                    }

                    final devices = snapshot.data!;

                    return ListView.builder(
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        final device = devices[index];
                        return ListTile(
                          leading: const Icon(Icons.cast, color: Color(0xFF00E676)),
                          title: Text(device.name, style: const TextStyle(color: Colors.white)),
                          subtitle: Text("Protocolo: ${device.protocol.name.toUpperCase()}", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                          trailing: const Icon(Icons.cast_connected, color: Colors.white70),
                          onTap: () async {
                            Navigator.pop(context);
                            await _enviarMidiaParaDispositivo(device);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              if (Platform.isIOS)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF198754)),
                      minimumSize: const Size(double.infinity, 40),
                    ),
                    icon: const Icon(Icons.airplay, color: Color(0xFF00E676)),
                    label: const Text("Usar AirPlay Nativo (Apple TV)"),
                    onPressed: () {
                      Navigator.pop(context);
                      _acionarAirPlayNativo();
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _enviarMidiaParaDispositivo(CastDevice device) async {
    debugPrint("[Cast] Conectando ao device: ${device.name} [IP:${device.address}]");

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Conectando a ${device.name}..."),
          backgroundColor: const Color(0xFF198754),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    try {
      final session = await _castService.connect(device);

      final urlProxyLocal = await _gerarUrlProxyLocalParaBunny(_currentMediaUrl);
      debugPrint("[Cast] URL Proxy gerada: $urlProxyLocal");

      final media = CastMedia(
        url: urlProxyLocal,
        title: _currentMediaTitle.isNotEmpty ? _currentMediaTitle : 'Esquema Conserlar',
        type: CastMediaType.mp4,
      );

      await session.loadMedia(media);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Esquema enviado para a TV com sucesso!"),
            backgroundColor: Color(0xFF198754),
          ),
        );
      }
    } catch (e) {
      debugPrint("[Cast Erro]: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro na transmissão: $e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _toggleFullInterno() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });

    if (_isFullScreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

      controller.runJavaScript('''
        (function() {
          const wrapper = document.getElementById('playerWrapper');
          if (wrapper) {
            wrapper.classList.add('player-fullscreen-fix');
            wrapper.style.setProperty('position', 'fixed', 'important');
            wrapper.style.setProperty('top', '0', 'important');
            wrapper.style.setProperty('left', '0', 'important');
            wrapper.style.setProperty('width', '100vw', 'important');
            wrapper.style.setProperty('height', '100vh', 'important');
            wrapper.style.setProperty('z-index', '999999', 'important');
          }

          const mediaViewer = document.getElementById('mediaViewer');
          if (mediaViewer) {
            mediaViewer.style.setProperty('width', '100%', 'important');
            mediaViewer.style.setProperty('height', '100%', 'important');
          }

          const btnExit = document.getElementById('btnExitFullscreen');
          if (btnExit) {
            btnExit.classList.remove('d-none');
            btnExit.style.setProperty('z-index', '10000000', 'important');
            btnExit.style.setProperty('position', 'fixed', 'important');
            btnExit.style.setProperty('top', '15px', 'important');
            btnExit.style.setProperty('right', '15px', 'important');
            
            btnExit.onclick = function(e) {
              e.preventDefault();
              window.location.href = "app://full_clicked";
            };
          }

          const btnFull = document.getElementById('btnFullInjetado');
          if (btnFull) { btnFull.innerHTML = "Sair Full"; }
        })();
      ''');
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

      controller.runJavaScript('''
        (function() {
          const wrapper = document.getElementById('playerWrapper');
          if (wrapper) {
            wrapper.classList.remove('player-fullscreen-fix');
            wrapper.style.removeProperty('position');
            wrapper.style.removeProperty('top');
            wrapper.style.removeProperty('left');
            wrapper.style.removeProperty('width');
            wrapper.style.removeProperty('height');
            wrapper.style.removeProperty('z-index');
          }

          const mediaViewer = document.getElementById('mediaViewer');
          if (mediaViewer) {
            mediaViewer.style.removeProperty('width');
            mediaViewer.style.removeProperty('height');
          }

          const btnExit = document.getElementById('btnExitFullscreen');
          if (btnExit) {
            btnExit.classList.add('d-none');
          }

          const btnFull = document.getElementById('btnFullInjetado');
          if (btnFull) { btnFull.innerHTML = "Full"; }
        })();
      ''');
    }
  }

  void _acionarAirPlayNativo() async {
    if (_currentMediaUrl.isNotEmpty) {
      try {
        final urlProxyLocal = await _gerarUrlProxyLocalParaBunny(_currentMediaUrl);
        debugPrint("[AirPlay] URL Proxy gerada: $urlProxyLocal");

        await FlutterIosAirplay.url(url: urlProxyLocal);
      } catch (e) {
        debugPrint("Erro no AirPlay: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erro ao iniciar AirPlay: $e"), backgroundColor: Colors.red),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nenhuma mídia selecionada para o AirPlay.")),
      );
    }
  }

  void _pararTransmissaoNaTv() async {
    try {
      await _castService.activeSession?.disconnect();
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Transmissão encerrada."), backgroundColor: Colors.red),
      );
    }
  }

  void _protegerTela() async {
    try {
      // await ScreenProtector.preventScreenshotOn();
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      setState(() {
        _conteudoVisivel = false;
      });
    } else if (state == AppLifecycleState.resumed) {
      setState(() {
        _conteudoVisivel = true;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _localProxyServer?.close(force: true);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
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
            if (_conteudoVisivel)
              WebViewWidget(controller: controller)
            else
              Container(
                color: Colors.black,
                child: const Center(
                  child: Text(
                    "CONTEÚDO PROTEGIDO",
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

// ==========================================
// WIDGET UNIFICADO DE BUSCA (CHROMECAST + DLNA)
// ==========================================
class _BonsoirDeviceListWidget extends StatefulWidget {
  final Function(CastDevice) onDeviceSelected;
  const _BonsoirDeviceListWidget({required this.onDeviceSelected});

  @override
  State<_BonsoirDeviceListWidget> createState() => _BonsoirDeviceListWidgetState();
}

class _BonsoirDeviceListWidgetState extends State<_BonsoirDeviceListWidget> {
  BonsoirDiscovery? _chromecastDiscovery;
  BonsoirDiscovery? _dlnaDiscovery;

  final List<CastDevice> _foundDevices = [];
  bool _isSearching = true;

  @override
  void initState() {
    super.initState();
    _startAllDiscoveries();
  }

  void _startAllDiscoveries() async {
    // 1. Inicia busca por Chromecast
    _chromecastDiscovery = BonsoirDiscovery(type: '_googlecast._tcp');
    await _chromecastDiscovery!.initialize();
    _listenToDiscovery(_chromecastDiscovery!, CastProtocol.chromecast);
    await _chromecastDiscovery!.start();

    // 2. Inicia busca por DLNA
    _dlnaDiscovery = BonsoirDiscovery(type: '_dlna._tcp');
    await _dlnaDiscovery!.initialize();
    _listenToDiscovery(_dlnaDiscovery!, CastProtocol.dlna);
    await _dlnaDiscovery!.start();
  }

  void _listenToDiscovery(BonsoirDiscovery discovery, CastProtocol protocol) {
    discovery.eventStream!.listen((event) {
      if (event is BonsoirDiscoveryServiceFoundEvent) {
        event.service?.resolve(discovery.serviceResolver);
      } else if (event is BonsoirDiscoveryServiceResolvedEvent) {
        final resolvedService = event.service;
        if (resolvedService != null) {
          final List<String>? addresses = resolvedService.hostAddresses;

          if (addresses != null && addresses.isNotEmpty) {
            final String serviceIp = addresses.first;

            // Limpa o nome do dispositivo
            String deviceName = resolvedService.name;
            if (deviceName.contains('.')) {
              deviceName = deviceName.split('.').first;
            }

            final device = CastDevice(
              id: resolvedService.name,
              name: deviceName,
              address: InternetAddress(serviceIp),
              port: resolvedService.port,
              protocol: protocol,
            );

            // Evita duplicatas na lista com base no IP
            if (!_foundDevices.any((d) => d.address.address == device.address.address)) {
              if (mounted) {
                setState(() {
                  _foundDevices.add(device);
                  _isSearching = false;
                });
              }
            }
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _chromecastDiscovery?.stop();
    _dlnaDiscovery?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_foundDevices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF00E676)),
            const SizedBox(height: 12),
            Text(
              _isSearching ? "Procurando Chromecasts e TVs DLNA..." : "Nenhum aparelho encontrado",
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _foundDevices.length,
      itemBuilder: (context, index) {
        final device = _foundDevices[index];
        final bool isDlna = device.protocol == CastProtocol.dlna;

        return ListTile(
          leading: Icon(
            isDlna ? Icons.tv : Icons.cast,
            color: const Color(0xFF00E676),
          ),
          title: Text(device.name, style: const TextStyle(color: Colors.white)),
          subtitle: Text(
            "${isDlna ? 'DLNA' : 'Chromecast'} • IP: ${device.address.address}:${device.port}",
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
          trailing: const Icon(Icons.cast_connected, color: Colors.white70),
          onTap: () => widget.onDeviceSelected(device),
        );
      },
    );
  }
}
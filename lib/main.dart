import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lottie/lottie.dart';
import 'package:screen_protector/screen_protector.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
                const Padding(
                  padding: EdgeInsets.only(bottom: 40, top: 5),
                  child: Text(
                    "Versão 1.1.0",
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
                          subtitle: null,
                          lottieRes: null,
                          gradientColors: const [
                            Color(0xFF000000),
                            Color(0xFF238C00),
                            Color(0xFF000000),
                          ],
                          textColor: Colors.white,
                          showBothIcons: false,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PrimeiroAcessoWebViewView(),
                              ),
                            );
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
// TELA DO WEBVIEW PRIMEIRO ACESSO (GENÉRICA)
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
// TELA DA PLATAFORMA DO ALUNO (BLINDAGEM DE IFRAME E TELA PRETA)
// ==========================================
class TelaDeEstudosSegura extends StatefulWidget {
  const TelaDeEstudosSegura({super.key});

  @override
  State<TelaDeEstudosSegura> createState() => _TelaDeEstudosSeguraState();
}

class _TelaDeEstudosSeguraState extends State<TelaDeEstudosSegura> with WidgetsBindingObserver {
  late final WebViewController controller;
  bool _conteudoVisivel = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _protegerTela();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent("iphoneconserlar2026")
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            // Script cirúrgico focado no mediaViewer e nas camadas de proteção
            const String scriptBlindagem = '''
              (function() {
                // 1. Trata especificamente o iframe do player (#mediaViewer)
                const iframe = document.getElementById('mediaViewer');
                if (iframe) {
                  iframe.removeAttribute('allowfullscreen');
                  let src = iframe.getAttribute('src');
                  if (src) {
                    // Força parâmetros de inline para YouTube/Vimeo se for o caso
                    if (src.includes('youtube.com/embed') && !src.includes('playsinline=1')) {
                      iframe.src = src + (src.indexOf('?') === -1 ? '?' : '&') + 'playsinline=1&fs=0&controls=1';
                    }
                  }
                }

                // 2. Ajusta qualquer outro iframe que apareça na plataforma
                const iframes = document.querySelectorAll('iframe');
                iframes.forEach(f => {
                  f.removeAttribute('allowfullscreen');
                });

                // 3. Remove ou desativa a camada de proteção por cima do player se ela estiver bloqueando o toque correto
                const overlay = document.querySelector('.pdf-protection-overlay');
                if (overlay) {
                  // Se o player estiver ativo, fazemos a camada ignorar os cliques para não bugar o player
                  overlay.style.pointerEvents = 'none';
                }

                // 4. Observador dinâmico caso o src do iframe mude via JS (ao trocar de aula)
                const observer = new MutationObserver((mutations) => {
                  const targetIframe = document.getElementById('mediaViewer');
                  if (targetIframe && targetIframe.hasAttribute('allowfullscreen')) {
                    targetIframe.removeAttribute('allowfullscreen');
                  }
                });
                
                const wrapper = document.getElementById('playerWrapper');
                if (wrapper) {
                  observer.observe(wrapper, { childList: true, subtree: true, attributes: true });
                }
              })();
            ''';

            controller.runJavaScript(scriptBlindagem);
          },
        ),
      )
      ..loadRequest(Uri.parse('https://aluno.conserlar.com'));
  }

  Future<void> _protegerTela() async {
    try {
      await ScreenProtector.preventScreenshotOn();
    } catch (e) {
      debugPrint("Erro ao ativar screen_protector: $e");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      setState(() {
        _conteudoVisivel = false; // Tela preta imediata
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
    try {
      ScreenProtector.preventScreenshotOff();
    } catch (_) {}
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
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart'
    hide NavigationAction;
import 'package:hotwire_native_flutter/hotwire_native_flutter.dart';

import 'bridge/form_component.dart';
import 'bridge/menu_component.dart';
import 'bridge/overflow_menu_component.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Hotwire().config.debugLoggingEnabled = true;
  runApp(const DemoApp());
}

final RouteObserver<PageRoute<dynamic>> demoRouteObserver =
    RouteObserver<PageRoute<dynamic>>();

enum DemoEnvironment { remote, local }

class DemoConfig {
  static const DemoEnvironment current = DemoEnvironment.remote;

  static String get baseUrl {
    if (current == DemoEnvironment.remote) {
      return "https://hotwire-native-demo.dev";
    }
    return Platform.isAndroid
        ? "http://10.0.2.2:3000"
        : "http://localhost:3000";
  }
}

class DemoTab {
  final String title;
  final IconData icon;
  final String url;

  const DemoTab({required this.title, required this.icon, required this.url});
}

class DemoApp extends StatelessWidget {
  final Widget? webViewOverride;
  final SessionWebViewAdapter? adapterOverride;
  final Object? controllerOverride;

  const DemoApp({
    this.webViewOverride,
    this.adapterOverride,
    this.controllerOverride,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Hotwire Native Demo",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      navigatorObservers: [demoRouteObserver],
      home: MainScreen(
        webViewOverride: webViewOverride,
        adapterOverride: adapterOverride,
        controllerOverride: controllerOverride,
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final Widget? webViewOverride;
  final SessionWebViewAdapter? adapterOverride;
  final Object? controllerOverride;

  const MainScreen({
    this.webViewOverride,
    this.adapterOverride,
    this.controllerOverride,
    super.key,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  List<DemoTab> get _tabs {
    final baseUrl = DemoConfig.baseUrl;
    final tabs = <DemoTab>[
      DemoTab(title: "Navigation", icon: Icons.swap_horiz, url: baseUrl),
      DemoTab(
        title: "Bridge Components",
        icon: Icons.widgets,
        url: "$baseUrl/components",
      ),
      DemoTab(
        title: "Resources",
        icon: Icons.menu_book,
        url: "$baseUrl/resources",
      ),
    ];

    if (DemoConfig.current == DemoEnvironment.local) {
      tabs.add(
        DemoTab(
          title: "Bugs & Fixes",
          icon: Icons.bug_report,
          url: "$baseUrl/bugs",
        ),
      );
    }
    return tabs;
  }

  void _openNumbersScreen(
    Session modalSession,
    InAppWebViewKeepAlive modalKeepAlive,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NumbersScreen(
          baseUrl: DemoConfig.baseUrl,
          modalSession: modalSession,
          modalKeepAlive: modalKeepAlive,
          routeObserver: demoRouteObserver,
          webViewOverride: widget.webViewOverride,
          adapterOverride: widget.adapterOverride,
          controllerOverride: widget.controllerOverride,
        ),
      ),
    );
  }

  void _openModalWeb(
    String url,
    Session modalSession,
    InAppWebViewKeepAlive modalKeepAlive,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => WebScreen(
          url: url,
          title: "Details",
          session: modalSession,
          isModal: true,
          routeObserver: demoRouteObserver,
          webViewOverride: widget.webViewOverride,
          adapterOverride: widget.adapterOverride,
          controllerOverride: widget.controllerOverride,
          keepAlive: modalKeepAlive,
        ),
      ),
    );
  }

  void _openImageViewer(String url) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ImageViewerScreen(url: url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _tabs;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          for (final tab in tabs)
            WebTab(
              url: tab.url,
              onOpenNumbers: _openNumbersScreen,
              onOpenModalWeb: _openModalWeb,
              onOpenImage: _openImageViewer,
              routeObserver: demoRouteObserver,
              webViewOverride: widget.webViewOverride,
              adapterOverride: widget.adapterOverride,
              controllerOverride: widget.controllerOverride,
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: [
          for (final tab in tabs)
            BottomNavigationBarItem(icon: Icon(tab.icon), label: tab.title),
        ],
      ),
    );
  }
}

class WebTab extends StatefulWidget {
  final String url;
  final void Function(
    Session modalSession,
    InAppWebViewKeepAlive modalKeepAlive,
  )
  onOpenNumbers;
  final void Function(
    String url,
    Session modalSession,
    InAppWebViewKeepAlive modalKeepAlive,
  )
  onOpenModalWeb;
  final void Function(String url) onOpenImage;
  final Session? session;
  final Bridge? bridge;
  final RouteObserver<PageRoute<dynamic>>? routeObserver;
  final Widget? webViewOverride;
  final SessionWebViewAdapter? adapterOverride;
  final Object? controllerOverride;

  const WebTab({
    required this.url,
    required this.onOpenNumbers,
    required this.onOpenModalWeb,
    required this.onOpenImage,
    this.session,
    this.bridge,
    this.routeObserver,
    this.webViewOverride,
    this.adapterOverride,
    this.controllerOverride,
    super.key,
  });

  @override
  State<WebTab> createState() => _WebTabState();
}

class _WebTabState extends State<WebTab> {
  late final Session _session;
  late final Session _modalSession;
  late final InAppWebViewKeepAlive _mainKeepAlive;
  late final InAppWebViewKeepAlive _modalKeepAlive;
  late final Bridge _bridge;
  FormActionState? _formAction;
  OverflowActionState? _overflowAction;
  bool _showFormProgress = false;

  @override
  void initState() {
    super.initState();
    _session =
        widget.session ??
        Session(navigationStack: NavigationStack(startLocation: widget.url));
    _modalSession = Session();
    _mainKeepAlive = InAppWebViewKeepAlive();
    _modalKeepAlive = InAppWebViewKeepAlive();
    _session.delegate = _DemoSessionDelegate(
      onFormSubmissionStarted: () {
        if (!mounted) {
          return;
        }
        setState(() => _showFormProgress = true);
      },
      onFormSubmissionFinished: () {
        if (!mounted) {
          return;
        }
        setState(() => _showFormProgress = false);
      },
      onVisitProposed: _handleVisitProposal,
    );
    _modalSession.delegate = _session.delegate;
    _bridge = widget.bridge ?? Bridge();
    _bridge.register(
      DemoFormComponent(
        onChanged: (state) {
          if (!mounted) {
            return;
          }
          setState(() => _formAction = state);
        },
      ),
    );
    _bridge.register(
      DemoOverflowMenuComponent(
        onChanged: (state) {
          if (!mounted) {
            return;
          }
          setState(() => _overflowAction = state);
        },
      ),
    );
    _bridge.register(DemoMenuComponent(state: this));
  }

  void _handleRouteRequest(String location, Map<String, dynamic> properties) {
    final uri = Uri.tryParse(location);
    if (uri == null) {
      return;
    }

    final instruction = _handleNavigationInstruction(
      uri.toString(),
      properties: properties,
    );
    if (instruction?.action == NavigationAction.none ||
        instruction?.action == NavigationAction.refresh ||
        instruction?.action == NavigationAction.pop) {
      return;
    }

    _handleNativeRoute(
      uri,
      isModal:
          instruction?.targetStack == NavigationStackType.modal ||
          _isModalPath(uri),
    );
  }

  void _handleVisitProposal(VisitProposal proposal) {
    final uri = proposal.url;
    final instruction = _handleNavigationInstruction(
      uri.toString(),
      properties: proposal.properties,
      options: proposal.options,
    );
    if (instruction?.action == NavigationAction.none ||
        instruction?.action == NavigationAction.refresh ||
        instruction?.action == NavigationAction.pop) {
      return;
    }

    final handled = _handleNativeRoute(
      uri,
      isModal:
          instruction?.targetStack == NavigationStackType.modal ||
          proposal.context == PresentationContext.modal ||
          _isModalPath(uri),
    );
    if (handled) {
      return;
    }

    _session.visitWithOptions(uri.toString(), options: proposal.options);
  }

  NavigationInstruction? _handleNavigationInstruction(
    String location, {
    Map<String, dynamic>? properties,
    VisitOptions? options,
  }) {
    final instruction = _session.routeWithNavigationStack(
      location,
      properties: properties,
      options: options,
    );
    if (instruction == null) {
      return null;
    }

    if (instruction.didDismissModal && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }

    if (instruction.action == NavigationAction.refresh &&
        instruction.refreshLocation != null) {
      _session.restoreOrVisit(instruction.refreshLocation!);
    }

    if (instruction.action == NavigationAction.pop && mounted) {
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop();
      }
    }

    return instruction;
  }

  bool _handleNativeRoute(Uri uri, {required bool isModal}) {
    if (_isNumbersIndex(uri)) {
      widget.onOpenNumbers(_modalSession, _modalKeepAlive);
      return true;
    }

    if (_isNumbersDetail(uri) || isModal) {
      widget.onOpenModalWeb(uri.toString(), _modalSession, _modalKeepAlive);
      return true;
    }

    if (_isImageUrl(uri)) {
      widget.onOpenImage(uri.toString());
      return true;
    }

    return false;
  }

  bool _isNumbersIndex(Uri uri) {
    if (uri.scheme == "hotwire" && uri.host == "fragment") {
      return uri.path == "/numbers";
    }
    return uri.path == "/numbers";
  }

  bool _isNumbersDetail(Uri uri) {
    if (uri.pathSegments.length != 2) {
      return false;
    }
    if (uri.pathSegments.first != "numbers") {
      return false;
    }
    return int.tryParse(uri.pathSegments[1]) != null;
  }

  bool _isModalPath(Uri uri) {
    final path = uri.path;
    return path.endsWith("/new") ||
        path.endsWith("/edit") ||
        path.contains("/modal");
  }

  bool _isImageUrl(Uri uri) {
    final path = uri.path.toLowerCase();
    return path.endsWith(".bmp") ||
        path.endsWith(".gif") ||
        path.endsWith(".heic") ||
        path.endsWith(".jpg") ||
        path.endsWith(".jpeg") ||
        path.endsWith(".png") ||
        path.endsWith(".svg") ||
        path.endsWith(".webp");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hotwire Native Demo'),
        actions: [
          if (_showFormProgress)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          if (_overflowAction != null)
            IconButton(
              tooltip: _overflowAction!.label,
              icon: const Icon(Icons.more_horiz),
              onPressed: _overflowAction!.onPressed,
            ),
          if (_formAction != null)
            TextButton(
              onPressed: _formAction!.enabled ? _formAction!.onPressed : null,
              child: Text(_formAction!.title),
            ),
        ],
      ),
      body: HotwireVisitable(
        url: widget.url,
        session: _session,
        bridge: _bridge,
        onRouteRequest: _handleRouteRequest,
        routeObserver: widget.routeObserver,
        webViewOverride: widget.webViewOverride,
        adapterOverride: widget.adapterOverride,
        controllerOverride: widget.controllerOverride,
        keepAlive: _mainKeepAlive,
      ),
    );
  }
}

class _DemoSessionDelegate extends SessionDelegate {
  final VoidCallback onFormSubmissionStarted;
  final VoidCallback onFormSubmissionFinished;
  final void Function(VisitProposal proposal) onVisitProposed;

  _DemoSessionDelegate({
    required this.onFormSubmissionStarted,
    required this.onFormSubmissionFinished,
    required this.onVisitProposed,
  });

  @override
  void sessionDidStartFormSubmission(Session session) {
    onFormSubmissionStarted();
  }

  @override
  void sessionDidFinishFormSubmission(Session session) {
    onFormSubmissionFinished();
  }

  @override
  void sessionDidProposeVisit(Session session, VisitProposal proposal) {
    onVisitProposed(proposal);
  }
}

class WebScreen extends StatelessWidget {
  final String url;
  final String title;
  final bool isModal;
  final Session session;
  final Bridge? bridge;
  final RouteObserver<PageRoute<dynamic>>? routeObserver;
  final Widget? webViewOverride;
  final SessionWebViewAdapter? adapterOverride;
  final Object? controllerOverride;
  final InAppWebViewKeepAlive? keepAlive;

  const WebScreen({
    required this.url,
    required this.title,
    required this.session,
    this.isModal = false,
    this.bridge,
    this.routeObserver,
    this.webViewOverride,
    this.adapterOverride,
    this.controllerOverride,
    this.keepAlive,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: isModal ? const CloseButton() : null,
      ),
      body: HotwireVisitable(
        url: url,
        session: session,
        bridge: bridge,
        routeObserver: routeObserver,
        webViewOverride: webViewOverride,
        adapterOverride: adapterOverride,
        controllerOverride: controllerOverride,
        keepAlive: keepAlive,
      ),
    );
  }
}

class NumbersScreen extends StatelessWidget {
  final String baseUrl;
  final Session modalSession;
  final InAppWebViewKeepAlive modalKeepAlive;
  final RouteObserver<PageRoute<dynamic>>? routeObserver;
  final Widget? webViewOverride;
  final SessionWebViewAdapter? adapterOverride;
  final Object? controllerOverride;

  const NumbersScreen({
    required this.baseUrl,
    required this.modalSession,
    required this.modalKeepAlive,
    this.routeObserver,
    this.webViewOverride,
    this.adapterOverride,
    this.controllerOverride,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Numbers")),
      body: ListView.separated(
        itemCount: 100,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final number = index + 1;
          return ListTile(
            title: Text("Row $number"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              final url = "$baseUrl/numbers/$number";
              Navigator.of(context).push(
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => WebScreen(
                    url: url,
                    title: "Number $number",
                    session: modalSession,
                    isModal: true,
                    routeObserver: routeObserver,
                    webViewOverride: webViewOverride,
                    adapterOverride: adapterOverride,
                    controllerOverride: controllerOverride,
                    keepAlive: modalKeepAlive,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ImageViewerScreen extends StatelessWidget {
  final String url;

  const ImageViewerScreen({required this.url, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: const CloseButton(),
      ),
      body: Center(child: InteractiveViewer(child: Image.network(url))),
    );
  }
}

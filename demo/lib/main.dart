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

  @override
  void initState() {
    super.initState();
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
              webViewOverride: widget.webViewOverride,
              adapterOverride: widget.adapterOverride,
              controllerOverride: widget.controllerOverride,
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
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
  final Bridge? bridge;
  final RouteObserver<PageRoute<dynamic>>? routeObserver;
  final Widget? webViewOverride;
  final SessionWebViewAdapter? adapterOverride;
  final Object? controllerOverride;

  const WebTab({
    required this.url,
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
  late final GlobalKey<NavigatorState> _navigatorKey;
  late final HotwireRouteBuilder _routeBuilder;
  late final NavigationStack _navigationStack;
  late final HotwireSessionPair _sessionPair;
  late final HotwireNavigator _navigator;
  late final RouteObserver<PageRoute<dynamic>> _routeObserver;
  late final Bridge _bridge;
  late final DemoActionController _actions;

  @override
  void initState() {
    super.initState();
    _navigatorKey = GlobalKey<NavigatorState>();
    _routeBuilder = const MaterialHotwireRouteBuilder();
    _routeObserver =
        widget.routeObserver ?? RouteObserver<PageRoute<dynamic>>();
    _navigationStack = NavigationStack(startLocation: widget.url);
    _sessionPair = HotwireSessionPair(
      mainSession: Session(navigationStack: _navigationStack),
      modalSession: Session(),
      mainKeepAlive: InAppWebViewKeepAlive(),
      modalKeepAlive: InAppWebViewKeepAlive(),
    );
    _actions = DemoActionController();
    _bridge = widget.bridge ?? Bridge();
    _bridge.register(
      DemoFormComponent(
        onChanged: (state) {
          _actions.formAction.value = state;
        },
      ),
    );
    _bridge.register(
      DemoOverflowMenuComponent(
        onChanged: (state) {
          _actions.overflowAction.value = state;
        },
      ),
    );
    _bridge.register(DemoMenuComponent(state: this));

    _navigator = HotwireNavigator(
      navigatorKey: _navigatorKey,
      sessions: _sessionPair,
      navigationStack: _navigationStack,
      routeBuilder: _routeBuilder,
      routeObserver: _routeObserver,
      delegate: DemoNavigatorDelegate(
        actions: _actions,
        sessionPair: _sessionPair,
        routeObserver: _routeObserver,
        webViewOverride: widget.webViewOverride,
        adapterOverride: widget.adapterOverride,
        controllerOverride: widget.controllerOverride,
      ),
      visitableBuilder: ({
        required VisitProposal proposal,
        required Session session,
        required InAppWebViewKeepAlive keepAlive,
        required RouteObserver<PageRoute<dynamic>> routeObserver,
        required bool isModal,
      }) {
        return DemoWebScaffold(
          title: isModal ? "Details" : "Hotwire Native Demo",
          url: proposal.url.toString(),
          session: session,
          bridge: isModal ? null : _bridge,
          isModal: isModal,
          actions: _actions,
          routeObserver: _routeObserver,
          webViewOverride: widget.webViewOverride,
          adapterOverride: widget.adapterOverride,
          controllerOverride: widget.controllerOverride,
          keepAlive: keepAlive,
          onRouteRequest: (location, properties) {
            _navigator.routeLocation(
              location,
              properties: properties,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: _navigatorKey,
      observers: _navigator.observers,
      onGenerateInitialRoutes: (navigator, _) {
        final proposal = VisitProposal(
          url: Uri.parse(widget.url),
          options: const VisitOptions(),
          properties: Hotwire().config.pathConfiguration.properties(widget.url),
        );
        final page = DemoWebScaffold(
          title: "Hotwire Native Demo",
          url: widget.url,
          session: _sessionPair.mainSession,
          bridge: _bridge,
          actions: _actions,
          routeObserver: _routeObserver,
          webViewOverride: widget.webViewOverride,
          adapterOverride: widget.adapterOverride,
          controllerOverride: widget.controllerOverride,
          keepAlive: _sessionPair.mainKeepAlive,
          onRouteRequest: (location, properties) {
            _navigator.routeLocation(
              location,
              properties: properties,
            );
          },
        );
        final route = _routeBuilder.buildRoute(
          page,
          isModal: false,
          location: proposal.url.toString(),
        );
        return [route];
      },
    );
  }
}

class DemoActionController {
  final ValueNotifier<FormActionState?> formAction =
      ValueNotifier<FormActionState?>(null);
  final ValueNotifier<OverflowActionState?> overflowAction =
      ValueNotifier<OverflowActionState?>(null);
  final ValueNotifier<bool> showFormProgress = ValueNotifier<bool>(false);

  void dispose() {
    formAction.dispose();
    overflowAction.dispose();
    showFormProgress.dispose();
  }
}

class DemoNavigatorDelegate extends HotwireNavigatorDelegate {
  final DemoActionController actions;
  final HotwireSessionPair sessionPair;
  final RouteObserver<PageRoute<dynamic>>? routeObserver;
  final Widget? webViewOverride;
  final SessionWebViewAdapter? adapterOverride;
  final Object? controllerOverride;

  DemoNavigatorDelegate({
    required this.actions,
    required this.sessionPair,
    this.routeObserver,
    this.webViewOverride,
    this.adapterOverride,
    this.controllerOverride,
  });

  @override
  HotwireProposalResult handle(VisitProposal proposal, HotwireNavigator navigator) {
    if (_isNumbersIndex(proposal.url)) {
      return HotwireProposalResult.acceptCustom(
        NumbersScreen(
          baseUrl: DemoConfig.baseUrl,
          onOpenDetail: (url) {
            navigator.routeLocation(
              url,
              properties: const {'context': 'modal'},
              parameters: const {'demo_modal_override': true},
            );
          },
        ),
      );
    }

    if (_isNumbersDetail(proposal.url)) {
      final parameters = proposal.parameters ?? const <String, dynamic>{};
      if (proposal.context != PresentationContext.modal &&
          parameters['demo_modal_override'] != true) {
        final properties = Map<String, dynamic>.from(proposal.properties)
          ..['context'] = 'modal';
        navigator.routeLocation(
          proposal.url.toString(),
          options: proposal.options,
          properties: properties,
          parameters: {
            ...parameters,
            'demo_modal_override': true,
          },
        );
        return HotwireProposalResult.reject;
      }
      return HotwireProposalResult.acceptCustom(
        WebScreen(
          url: proposal.url.toString(),
          title: "Details",
          session: sessionPair.modalSession,
          isModal: true,
          routeObserver: routeObserver,
          webViewOverride: webViewOverride,
          adapterOverride: adapterOverride,
          controllerOverride: controllerOverride,
          keepAlive: sessionPair.modalKeepAlive,
        ),
      );
    }

    if (_isImageUrl(proposal.url)) {
      return HotwireProposalResult.acceptCustom(
        ImageViewerScreen(url: proposal.url.toString()),
      );
    }

    return HotwireProposalResult.accept;
  }

  @override
  void sessionDidStartFormSubmission(Session session) {
    actions.showFormProgress.value = true;
  }

  @override
  void sessionDidFinishFormSubmission(Session session) {
    actions.showFormProgress.value = false;
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
}

class DemoWebScaffold extends StatelessWidget {
  final String title;
  final String url;
  final Session session;
  final Bridge? bridge;
  final bool isModal;
  final DemoActionController actions;
  final HotwireRouteRequestCallback onRouteRequest;
  final RouteObserver<PageRoute<dynamic>>? routeObserver;
  final Widget? webViewOverride;
  final SessionWebViewAdapter? adapterOverride;
  final Object? controllerOverride;
  final InAppWebViewKeepAlive? keepAlive;

  const DemoWebScaffold({
    required this.title,
    required this.url,
    required this.session,
    required this.actions,
    required this.onRouteRequest,
    this.bridge,
    this.isModal = false,
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
        actions: isModal
            ? null
            : [
                ValueListenableBuilder<bool>(
                  valueListenable: actions.showFormProgress,
                  builder: (_, value, __) {
                    if (!value) {
                      return const SizedBox.shrink();
                    }
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                ),
                ValueListenableBuilder<OverflowActionState?>(
                  valueListenable: actions.overflowAction,
                  builder: (_, value, __) {
                    if (value == null) {
                      return const SizedBox.shrink();
                    }
                    return IconButton(
                      tooltip: value.label,
                      icon: const Icon(Icons.more_horiz),
                      onPressed: value.onPressed,
                    );
                  },
                ),
                ValueListenableBuilder<FormActionState?>(
                  valueListenable: actions.formAction,
                  builder: (_, value, __) {
                    if (value == null) {
                      return const SizedBox.shrink();
                    }
                    return TextButton(
                      onPressed: value.enabled ? value.onPressed : null,
                      child: Text(value.title),
                    );
                  },
                ),
              ],
      ),
      body: HotwireVisitable(
        url: url,
        session: session,
        bridge: bridge,
        onRouteRequest: onRouteRequest,
        routeObserver: routeObserver,
        webViewOverride: webViewOverride,
        adapterOverride: adapterOverride,
        controllerOverride: controllerOverride,
        keepAlive: keepAlive,
      ),
    );
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
  final void Function(String url) onOpenDetail;

  const NumbersScreen({
    required this.baseUrl,
    required this.onOpenDetail,
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
              onOpenDetail(url);
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

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hotwire_native_flutter/hotwire_native_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DemoApp());
}

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
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Hotwire Native Demo",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

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

  void _openNumbersScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NumbersScreen(baseUrl: DemoConfig.baseUrl),
      ),
    );
  }

  void _openModalWeb(String url) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => WebScreen(url: url, title: "Details", isModal: true),
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
  final VoidCallback onOpenNumbers;
  final void Function(String url) onOpenModalWeb;
  final void Function(String url) onOpenImage;

  const WebTab({
    required this.url,
    required this.onOpenNumbers,
    required this.onOpenModalWeb,
    required this.onOpenImage,
    super.key,
  });

  @override
  State<WebTab> createState() => _WebTabState();
}

class _WebTabState extends State<WebTab> {
  late final Session _session;

  @override
  void initState() {
    super.initState();
    _session = Session();
  }

  void _handleRouteRequest(String location, Map<String, dynamic> properties) {
    final uri = Uri.tryParse(location);
    if (uri == null) {
      return;
    }

    if (_isNumbersIndex(uri)) {
      widget.onOpenNumbers();
      return;
    }

    if (_isNumbersDetail(uri) || _isModalPath(uri)) {
      widget.onOpenModalWeb(uri.toString());
      return;
    }

    if (_isImageUrl(uri)) {
      widget.onOpenImage(uri.toString());
      return;
    }
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
    return HotwireWebView(
      url: widget.url,
      session: _session,
      onRouteRequest: _handleRouteRequest,
    );
  }
}

class WebScreen extends StatelessWidget {
  final String url;
  final String title;
  final bool isModal;

  const WebScreen({
    required this.url,
    required this.title,
    this.isModal = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: isModal ? const CloseButton() : null,
      ),
      body: HotwireWebView(url: url, session: Session()),
    );
  }
}

class NumbersScreen extends StatelessWidget {
  final String baseUrl;

  const NumbersScreen({required this.baseUrl, super.key});

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
                    isModal: true,
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

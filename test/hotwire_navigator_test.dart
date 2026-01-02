import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotwire_native_flutter/hotwire_native_flutter.dart';

void main() {
  late Uri? originalStartLocation;

  setUp(() {
    originalStartLocation = Hotwire().config.startLocation;
    Hotwire().config.startLocation = Uri.parse('https://example.com');
  });

  tearDown(() {
    Hotwire().config.startLocation = originalStartLocation;
  });

  test('HotwireNavigator routes accepted proposals', () {
    final executor = _ExecutorSpy();
    final navigator = HotwireNavigator(
      navigatorKey: GlobalKey<NavigatorState>(),
      executorOverride: executor,
      navigationStack: NavigationStack(
        startLocation: 'https://example.com',
      ),
    );
    final proposal = VisitProposal(
      url: Uri.parse('https://example.com/next'),
      options: const VisitOptions(),
      properties: const {},
    );

    navigator.routeProposal(proposal);

    expect(
      executor.calls,
      ['push:main:https://example.com/next'],
    );
    expect(executor.lastActiveProposal, proposal);
  });

  test('HotwireNavigator does not route rejected proposals', () {
    final executor = _ExecutorSpy();
    final delegate = _DelegateSpy(HotwireProposalResult.reject);
    final navigator = HotwireNavigator(
      navigatorKey: GlobalKey<NavigatorState>(),
      executorOverride: executor,
      delegate: delegate,
      navigationStack: NavigationStack(
        startLocation: 'https://example.com',
      ),
    );
    final proposal = VisitProposal(
      url: Uri.parse('https://example.com/next'),
      options: const VisitOptions(),
      properties: const {},
    );

    navigator.routeProposal(proposal);

    expect(executor.calls, isEmpty);
  });

  test('HotwireNavigator forwards custom pages to executor', () {
    final executor = _ExecutorSpy();
    final customPage = Container();
    final delegate = _DelegateSpy(
      HotwireProposalResult.acceptCustom(customPage),
    );
    final navigator = HotwireNavigator(
      navigatorKey: GlobalKey<NavigatorState>(),
      executorOverride: executor,
      delegate: delegate,
      navigationStack: NavigationStack(
        startLocation: 'https://example.com',
      ),
    );
    final proposal = VisitProposal(
      url: Uri.parse('https://example.com/custom'),
      options: const VisitOptions(),
      properties: const {},
    );

    navigator.routeProposal(proposal);

    expect(executor.lastCustomPage, customPage);
  });
}

class _ExecutorSpy implements NavigationExecutor, HotwireProposalExecutor {
  final List<String> calls = [];
  VisitProposal? lastActiveProposal;
  Widget? lastCustomPage;

  @override
  void setActiveProposal(VisitProposal? proposal) {
    if (proposal != null) {
      lastActiveProposal = proposal;
    }
  }

  @override
  void setCustomPage(Widget? page) {
    if (page != null) {
      lastCustomPage = page;
    }
  }

  @override
  void push(String location, {required bool isModal}) {
    calls.add('push:${_context(isModal)}:$location');
  }

  @override
  void replace(String location, {required bool isModal}) {
    calls.add('replace:${_context(isModal)}:$location');
  }

  @override
  void pop({required bool isModal}) {
    calls.add('pop:${_context(isModal)}');
  }

  @override
  void clearAll(String location) {
    calls.add('clearAll:$location');
  }

  @override
  void replaceRoot(String location) {
    calls.add('replaceRoot:$location');
  }

  @override
  void presentModal() {
    calls.add('presentModal');
  }

  @override
  void dismissModal() {
    calls.add('dismissModal');
  }

  @override
  void refresh(String location, {required bool isModal}) {
    calls.add('refresh:${_context(isModal)}:$location');
  }

  String _context(bool isModal) => isModal ? 'modal' : 'main';
}

class _DelegateSpy extends HotwireNavigatorDelegate {
  final HotwireProposalResult result;

  _DelegateSpy(this.result);

  @override
  HotwireProposalResult handle(VisitProposal proposal, HotwireNavigator navigator) {
    return result;
  }
}

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotwire_native_flutter/hotwire_native_flutter.dart';
import 'package:hotwire_native/bridge/demo_actions.dart';
import 'package:hotwire_native/main.dart';

void main() {
  test('Demo navigator delegate routes native handlers', () {
    final actions = DemoActionController();
    final sessionPair = HotwireSessionPair();
    final delegate = DemoNavigatorDelegate(
      actions: actions,
      sessionPair: sessionPair,
    );
    final navigator = HotwireNavigator(
      navigatorKey: GlobalKey<NavigatorState>(),
      sessions: sessionPair,
      navigationStack: NavigationStack(
        startLocation: 'https://example.com',
      ),
    );

    final numbersProposal = VisitProposal(
      url: Uri.parse('https://example.com/numbers'),
      options: const VisitOptions(),
      properties: const {},
    );
    final numbersResult = delegate.handle(numbersProposal, navigator);
    expect(numbersResult.decision, HotwireProposalDecision.acceptCustom);
    expect(numbersResult.customPage, isA<NumbersScreen>());

    final detailProposal = VisitProposal(
      url: Uri.parse('https://example.com/numbers/1'),
      options: const VisitOptions(),
      properties: const {'context': 'modal'},
      parameters: const {'demo_modal_override': true},
    );
    final detailResult = delegate.handle(detailProposal, navigator);
    expect(detailResult.decision, HotwireProposalDecision.acceptCustom);
    expect(detailResult.customPage, isA<WebScreen>());

    final imageProposal = VisitProposal(
      url: Uri.parse('https://example.com/assets/image.png'),
      options: const VisitOptions(),
      properties: const {},
    );
    final imageResult = delegate.handle(imageProposal, navigator);
    expect(imageResult.decision, HotwireProposalDecision.acceptCustom);
    expect(imageResult.customPage, isA<ImageViewerScreen>());
  });
}

import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../turbo/path_properties.dart';
import 'session.dart';

class HotwireSessionPair {
  final Session mainSession;
  final Session modalSession;
  final InAppWebViewKeepAlive mainKeepAlive;
  final InAppWebViewKeepAlive modalKeepAlive;

  HotwireSessionPair({
    Session? mainSession,
    Session? modalSession,
    InAppWebViewKeepAlive? mainKeepAlive,
    InAppWebViewKeepAlive? modalKeepAlive,
  }) : mainSession = mainSession ?? Session(),
       modalSession = modalSession ?? Session(),
       mainKeepAlive = mainKeepAlive ?? InAppWebViewKeepAlive(),
       modalKeepAlive = modalKeepAlive ?? InAppWebViewKeepAlive();

  Session sessionForContext(PresentationContext context) {
    return context == PresentationContext.modal ? modalSession : mainSession;
  }

  InAppWebViewKeepAlive keepAliveForContext(PresentationContext context) {
    return context == PresentationContext.modal
        ? modalKeepAlive
        : mainKeepAlive;
  }
}

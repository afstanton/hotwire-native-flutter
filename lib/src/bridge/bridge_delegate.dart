import 'message.dart';

abstract class BridgeDelegate {
  bool replyWith(BridgeMessage message);
}

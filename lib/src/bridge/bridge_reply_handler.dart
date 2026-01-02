import 'message.dart';

abstract class BridgeReplyHandler {
  bool replyWith(BridgeMessage message);
}

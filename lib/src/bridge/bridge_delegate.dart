import 'message.dart';

abstract class BridgeDelegate {
  void replyWith(BridgeMessage originalMessage, Map<String, dynamic> data);
}

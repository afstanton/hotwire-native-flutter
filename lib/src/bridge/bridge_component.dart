import 'bridge_delegate.dart';
import 'message.dart';

abstract class BridgeComponent {
  BridgeDelegate? delegate;

  String get name;

  void onReceive(BridgeMessage message);

  void didReceive(BridgeMessage message) {}

  void reply(BridgeMessage message, Map<String, dynamic> data) {
    delegate?.replyWith(message, data);
  }
}

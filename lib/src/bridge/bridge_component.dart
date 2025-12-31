import 'bridge_delegate.dart';
import 'message.dart';

abstract class BridgeComponent {
  BridgeDelegate? delegate;
  final Map<String, BridgeMessage> _receivedMessages = {};

  String get name;

  void onReceive(BridgeMessage message);

  void onStart() {}

  void onStop() {}

  void didReceive(BridgeMessage message) {
    _receivedMessages[message.event] = message;
    onReceive(message);
  }

  void didStart() {
    onStart();
  }

  void didStop() {
    onStop();
  }

  BridgeMessage? receivedMessageFor(String event) {
    return _receivedMessages[event];
  }

  bool replyWith(BridgeMessage message) {
    return delegate?.replyWith(message) ?? false;
  }

  bool replyTo(String event) {
    final message = receivedMessageFor(event);
    if (message == null) {
      return false;
    }
    return replyWith(message);
  }

  bool replyToJson(String event, String jsonData) {
    final message = receivedMessageFor(event);
    if (message == null) {
      return false;
    }
    return replyWith(message.replacing(jsonData: jsonData));
  }

  bool replyToData(String event, Object data) {
    final message = receivedMessageFor(event);
    if (message == null) {
      return false;
    }
    return replyWith(message.replacingData(data));
  }

  bool reply(BridgeMessage message, Object data) {
    return replyWith(message.replacingData(data));
  }
}

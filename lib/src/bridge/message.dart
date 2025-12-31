import 'dart:convert';

import '../hotwire.dart';

class BridgeMessageMetadata {
  final String url;

  const BridgeMessageMetadata({required this.url});

  factory BridgeMessageMetadata.fromMap(Map<String, dynamic> map) {
    return BridgeMessageMetadata(url: map['url']?.toString() ?? '');
  }

  Map<String, dynamic> toMap() => {'url': url};
}

class BridgeMessage {
  final String id;
  final String component;
  final String event;
  final BridgeMessageMetadata? metadata;
  final String jsonData;

  const BridgeMessage({
    required this.id,
    required this.component,
    required this.event,
    required this.metadata,
    required this.jsonData,
  });

  factory BridgeMessage.fromMap(Map<String, dynamic> map) {
    final metadata = map['metadata'] is Map
        ? BridgeMessageMetadata.fromMap(
            Map<String, dynamic>.from(map['metadata'] as Map),
          )
        : null;

    String jsonData;
    final dataValue = map['data'];
    if (dataValue is String) {
      jsonData = dataValue;
    } else if (dataValue != null) {
      jsonData = json.encode(dataValue);
    } else {
      jsonData = map['jsonData']?.toString() ?? '{}';
    }

    return BridgeMessage(
      id: map['id']?.toString() ?? '',
      component: map['component']?.toString() ?? '',
      event: map['event']?.toString() ?? '',
      metadata: metadata,
      jsonData: jsonData,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'component': component,
    'event': event,
    'metadata': metadata?.toMap(),
    'data': jsonData,
  };

  BridgeMessage replacing({String? event, String? jsonData}) {
    return BridgeMessage(
      id: id,
      component: component,
      event: event ?? this.event,
      metadata: metadata,
      jsonData: jsonData ?? this.jsonData,
    );
  }

  BridgeMessage replacingData(Object data, {String? event}) {
    final encoder = Hotwire().config.bridgeJsonEncoder;
    final encoded = encoder != null ? encoder(data) : data;
    final jsonData = json.encode(encoded);
    return replacing(event: event, jsonData: jsonData);
  }

  T? data<T>() {
    try {
      final decoded = json.decode(jsonData);
      if (decoded is T) {
        return decoded;
      }
      final decoder = Hotwire().config.bridgeJsonDecoder;
      if (decoder != null) {
        final mapped = decoder(decoded);
        if (mapped is T) {
          return mapped as T;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

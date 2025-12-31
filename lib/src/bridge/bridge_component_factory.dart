import 'bridge_component.dart';

abstract class BridgeComponentFactory<T extends BridgeComponent> {
  String get name;

  T create();
}

import 'path_properties.dart';

class HistoricalLocationAction {
  final Presentation presentation;
  final bool dismissModal;

  const HistoricalLocationAction({
    required this.presentation,
    required this.dismissModal,
  });
}

HistoricalLocationAction? resolveHistoricalLocationAction({
  required Map<String, dynamic> properties,
  required bool isModal,
}) {
  if (!properties.isHistoricalLocation) {
    return null;
  }

  final presentation = properties.presentation;
  return HistoricalLocationAction(
    presentation: presentation == Presentation.defaultValue
        ? Presentation.none
        : presentation,
    dismissModal: isModal,
  );
}

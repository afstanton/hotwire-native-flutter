import '../path_properties.dart';
import 'visit_options.dart';

class VisitProposal {
  final Uri url;
  final VisitOptions options;
  final Map<String, dynamic> properties;
  final Map<String, dynamic>? parameters;

  const VisitProposal({
    required this.url,
    required this.options,
    this.properties = const {},
    this.parameters,
  });

  PresentationContext get context => properties.context;
}

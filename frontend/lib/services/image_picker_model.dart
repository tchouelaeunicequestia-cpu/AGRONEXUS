import 'dart:typed_data';

class PickedProduceImage {
  final Uint8List bytes;
  final String dataUrl;
  final String name;

  PickedProduceImage({
    required this.bytes,
    required this.dataUrl,
    required this.name,
  });
}

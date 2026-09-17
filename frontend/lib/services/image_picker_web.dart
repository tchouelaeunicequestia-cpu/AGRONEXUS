import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'image_picker_model.dart';

Future<PickedProduceImage?> pickDeviceImage({bool fromCamera = false}) {
  final completer = Completer<PickedProduceImage?>();
  final input = html.FileUploadInputElement()..accept = 'image/*';
  if (fromCamera) {
    input.setAttribute('capture', 'environment');
  }

  input.onChange.listen((event) {
    final files = input.files;
    if (files == null || files.isEmpty) {
      if (!completer.isCompleted) completer.complete(null);
      return;
    }
    final file = files[0];
    final reader = html.FileReader();
    reader.readAsDataUrl(file);
    reader.onLoadEnd.listen((_) {
      final dataUrl = reader.result as String?;
      if (dataUrl != null) {
        final byteReader = html.FileReader();
        byteReader.readAsArrayBuffer(file);
        byteReader.onLoadEnd.listen((_) {
          final rawResult = byteReader.result;
          if (rawResult != null && rawResult is ByteBuffer) {
            if (!completer.isCompleted) {
              completer.complete(PickedProduceImage(
                bytes: rawResult.asUint8List(),
                dataUrl: dataUrl,
                name: file.name,
              ));
            }
          } else if (rawResult != null && rawResult is List<int>) {
            if (!completer.isCompleted) {
              completer.complete(PickedProduceImage(
                bytes: Uint8List.fromList(rawResult),
                dataUrl: dataUrl,
                name: file.name,
              ));
            }
          } else {
            if (!completer.isCompleted) completer.complete(null);
          }
        });
      } else {
        if (!completer.isCompleted) completer.complete(null);
      }
    });
  });

  input.click();
  return completer.future;
}

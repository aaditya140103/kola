import 'package:file_picker/file_picker.dart';

final class PickedDocumentFile {
  const PickedDocumentFile({
    required this.name,
    required this.path,
    this.extension,
    this.reportedSize,
  });

  final String name;
  final String path;
  final String? extension;
  final int? reportedSize;
}

abstract interface class DocumentFilePicker {
  Future<PickedDocumentFile?> pickSingle();
}

final class NativeDocumentFilePicker implements DocumentFilePicker {
  const NativeDocumentFilePicker();

  @override
  Future<PickedDocumentFile?> pickSingle() async {
    final PlatformFile? file = await FilePicker.pickFile(
      dialogTitle: 'Import document into Kola',
      type: FileType.any,
    );
    if (file == null) return null;

    final String? path = file.path;
    if (path == null || path.isEmpty) {
      throw const DocumentPickerException(
        'The selected file does not expose a local path on this platform.',
      );
    }

    return PickedDocumentFile(
      name: file.name,
      path: path,
      extension: file.extension,
      reportedSize: file.lengthSync(),
    );
  }
}

final class DocumentPickerException implements Exception {
  const DocumentPickerException(this.message);

  final String message;

  @override
  String toString() => 'DocumentPickerException: $message';
}

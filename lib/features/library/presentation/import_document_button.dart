import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kola/core/providers/import_providers.dart';
import 'package:kola/core/providers/search_providers.dart';
import 'package:kola/document/import/document_file_picker.dart';
import 'package:kola/document/import/document_import_service.dart';

class ImportDocumentButton extends ConsumerStatefulWidget {
  const ImportDocumentButton({
    super.key,
    this.tooltip = 'Import document',
  });

  final String tooltip;

  @override
  ConsumerState<ImportDocumentButton> createState() =>
      _ImportDocumentButtonState();
}

class _ImportDocumentButtonState extends ConsumerState<ImportDocumentButton> {
  bool _importing = false;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: widget.tooltip,
      onPressed: _importing ? null : _importDocument,
      icon: _importing
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.add_rounded),
    );
  }

  Future<void> _importDocument() async {
    setState(() => _importing = true);
    try {
      final DocumentImportResult? result = await ref
          .read(documentImportServiceProvider)
          .pickAndImport();
      if (!mounted || result == null) return;

      unawaited(
        ref
            .read(documentSearchServiceProvider)
            .ensureIndexed(result.document)
            .catchError((Object _) {}),
      );

      final String title = result.document.metadata.title;
      final String message = switch (result.status) {
        DocumentImportStatus.imported => '$title was added to your library.',
        DocumentImportStatus.alreadyPresent => '$title is already in your library.',
        DocumentImportStatus.sourceUpdated => '$title was relinked to this source.',
        DocumentImportStatus.sourceRepaired =>
          'Managed copy for $title was restored.',
      };
      _showMessage(message);
    } on UnsupportedDocumentFormatException {
      if (mounted) {
        _showMessage('Kola cannot identify this document format yet.');
      }
    } on DocumentPickerException catch (error) {
      if (mounted) _showMessage(error.message);
    } on Object {
      if (mounted) {
        _showMessage('Kola could not import this document. The source was left unchanged.');
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

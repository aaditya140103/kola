import 'package:kola/document/model/document_models.dart';

abstract interface class DocumentRepository {
  Stream<List<KolaDocument>> watchAll();

  Future<KolaDocument?> getById(String id);

  Future<void> upsert(KolaDocument document);

  Future<void> remove(String id);
}

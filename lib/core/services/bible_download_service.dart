library;

import '../../domain/entities/bible_book.dart';
import '../../domain/repositories/bible_repository.dart';

/// Baixa a Bíblia (por versão) para leitura offline completa.
///
/// Itera livros → capítulos chamando getChapter (que já persiste cada
/// capítulo no CatalogCache). Serial e tolerante: capítulo que falha é
/// pulado; o progresso notifica quem observa.
class BibleDownloadService {
  final BibleRepository repository;

  BibleDownloadService(this.repository);

  /// Baixa todos os capítulos de [books] na versão [versionId].
  /// Retorna (baixados, falhas).
  Future<(int, int)> downloadVersion({
    required int versionId,
    required List<BibleBook> books,
    void Function(int done, int total)? onProgress,
  }) async {
    final total = books.fold<int>(0, (sum, b) => sum + b.chapters);
    var done = 0;
    var failed = 0;

    for (final book in books) {
      for (var chapter = 1; chapter <= book.chapters; chapter++) {
        try {
          await repository.getChapter(versionId, book.id, chapter);
          done++;
        } catch (_) {
          failed++;
        }
        onProgress?.call(done + failed, total);
      }
    }
    return (done, failed);
  }
}

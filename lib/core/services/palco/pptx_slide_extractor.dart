library;

import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// Extrai as imagens dos slides de um .pptx (ZIP com ppt/media/*).
///
/// Caso real (2026-08-18): PPTs da Escola Sabatina (ex: PRI_A_T3semana7.pptx)
/// são ~1 imagem por slide. O mobile não tem renderizador PPTX — mas o
/// .pptx é um ZIP: as imagens embutidas em ppt/media/ são os slides.
///
/// Ordenação: numérica pelo sufixo do arquivo (image1.png, image2.png...),
/// que é a ordem de inserção — coerente com a ordem dos slides na prática.
/// Filtra só extensões de imagem e ignora ícones minúsculos (< 20 KB),
/// que são logos/cliparts decorativos, não conteúdo de slide.
abstract final class PptxSlideExtractor {
  static const _imageExts = {'.png', '.jpg', '.jpeg', '.bmp', '.webp'};
  static const _minBytes = 20 * 1024;

  /// Retorna [{name, bytes}] dos slides em ordem. Vazio se não der.
  static List<({String name, Uint8List bytes})> extract(String pptxPath) {
    final file = File(pptxPath);
    if (!file.existsSync()) return const [];
    try {
      final archive = ZipDecoder().decodeBytes(file.readAsBytesSync());
      final media = <({String name, Uint8List bytes})>[];
      for (final f in archive.files) {
        if (!f.isFile) continue;
        final name = f.name.split('/').last.toLowerCase();
        final dot = name.lastIndexOf('.');
        if (dot < 0) continue;
        if (!_imageExts.contains(name.substring(dot))) continue;
        final data = Uint8List.fromList(f.content as List<int>);
        if (data.length < _minBytes) continue; // logo/icone, nao slide
        media.add((name: name, bytes: data));
      }
      // Ordem numerica do sufixo (image1 < image2 < ... image10).
      int num(String n) =>
          int.parse(RegExp(r'(\d+)').firstMatch(n)?.group(1) ?? '0');
      media.sort((a, b) => num(a.name).compareTo(num(b.name)));
      return media;
    } catch (_) {
      return const [];
    }
  }
}

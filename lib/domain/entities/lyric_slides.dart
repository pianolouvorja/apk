library;

/// Um slide de letra — espelho do Media.js (Electron).
///
/// Cada estrofe tem timestamp de troca (modo cantado [time] e
/// instrumental [instrumentalTime]), imagem de fundo opcional e ordem.
/// Slide sem imagem herda a última definida (carry-over do Electron).
class LyricSlide {
  final String text;
  final Duration? time;
  final Duration? instrumentalTime;
  final String? imageUrl;
  final int order;

  const LyricSlide({
    required this.text,
    this.time,
    this.instrumentalTime,
    this.imageUrl,
    required this.order,
  });

  /// Slide-capa (índice 0): nome da música + imagem principal.
  /// Time 00:00:00 — igual Media.js.
  factory LyricSlide.cover({
    required String title,
    String? imageUrl,
  }) =>
      LyricSlide(
        text: title,
        time: Duration.zero,
        instrumentalTime: Duration.zero,
        imageUrl: imageUrl,
        order: 0,
      );

  /// "00:00:08" → Duration(seconds: 8). Aceita null/vazio.
  static Duration? parseTime(dynamic raw) {
    if (raw is! String || raw.isEmpty) return null;
    final parts = raw.split(':');
    if (parts.length != 3) return null;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final s = int.tryParse(parts[2]) ?? 0;
    return Duration(hours: h, minutes: m, seconds: s);
  }
}

/// Lista de slides de uma música, montada como o Media.js:
///
/// 1. Capa (nome + url_image da música, time zero)
/// 2. lyric[] filtrado por show_slide == 1, ordenado por order
/// 3. Carry-over de imagem: slide sem url_image herda a anterior
class LyricSlides {
  final List<LyricSlide> slides;

  const LyricSlides(this.slides);

  static const empty = LyricSlides([]);

  /// Monta a partir do `lyric` bruto da API (endpoint music_{id}).
  factory LyricSlides.fromApi({
    required String musicName,
    String? coverUrl,
    required List raw,
  }) {
    final parsed = <LyricSlide>[];
    for (final entry in raw.whereType<Map>()) {
      final show = entry['show_slide'];
      final showOk = show == 1 ||
          show == '1' ||
          show == true ||
          show == 'true';
      if (!showOk) continue;

      final text = (entry['lyric'] ?? '').toString().trim();
      if (text.isEmpty) continue;

      parsed.add(LyricSlide(
        text: text,
        time: LyricSlide.parseTime(entry['time']),
        instrumentalTime: LyricSlide.parseTime(entry['instrumental_time']),
        imageUrl: (entry['url_image'] ?? '').toString().isEmpty
            ? null
            : entry['url_image'].toString(),
        order: int.tryParse(entry['order']?.toString() ?? '') ?? 0,
      ));
    }
    parsed.sort((a, b) => a.order.compareTo(b.order));

    // Carry-over de imagem (Electron): slide sem imagem herda a última.
    // F3.3e: o COVER (capa de álbum, ex: covers/2026.bmp) NÃO entra como
    // carry-over — cover não é BG de projeção. Só url_image dos slides.
    String? lastImage;
    final body = <LyricSlide>[];
    for (final s in parsed) {
      final img = s.imageUrl ?? lastImage;
      if (s.imageUrl != null) lastImage = s.imageUrl;
      body.add(LyricSlide(
        text: s.text,
        time: s.time,
        instrumentalTime: s.instrumentalTime,
        imageUrl: img,
        order: s.order,
      ));
    }
    return LyricSlides([
      LyricSlide.cover(title: musicName, imageUrl: coverUrl),
      ...body,
    ]);
  }

  /// Índice do slide ativo em [position], pelo timestamp do modo.
  /// Sem times: 0 (troca manual).
  int indexAt(Duration position, {bool instrumental = false}) {
    int idx = 0;
    for (var i = 0; i < slides.length; i++) {
      final t = instrumental
          ? slides[i].instrumentalTime
          : slides[i].time;
      if (t != null && position >= t) idx = i;
    }
    return idx;
  }
}

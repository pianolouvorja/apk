library;

/// Mensagens do protocolo Palco v2 (WS JSON).
///
/// Contrato validado no spike ~/palco-spike (2026-08-17, LG UM7510):
/// sender→receiver: projection, audio, video, timer, bgPalco, idle, volume.
/// receiver→sender: unlocked, ended, status, error, remote-key.
///
/// Regra crítica: mídia SEMPRE via proxy do sender com IP da sub-rede da TV
/// (nunca localhost) — ver PalcoProxy.
class PalcoMessage {
  const PalcoMessage({required this.type, this.version = 2, this.fields = const {}});

  final int version;
  final String type;
  final Map<String, dynamic> fields;

  Map<String, dynamic> toJson() => {'v': version, 'type': type, ...fields};

  factory PalcoMessage.fromJson(Map<String, dynamic> json) {
    final v = json['v'];
    if (v != 1 && v != 2) {
      throw FormatException('Versão de protocolo Palco não suportada: $v');
    }
    final type = json['type'];
    if (type is! String || type.isEmpty) {
      throw const FormatException('Mensagem Palco sem type');
    }
    return PalcoMessage(
      version: v as int,
      type: type,
      fields: Map<String, dynamic>.from(json)..remove('v')..remove('type'),
    );
  }

  // ---- Fabricadores sender→receiver ----

  /// Projeta texto/BG. [text] aceita <br> (quebra de linha, innerHTML no receiver).
  static PalcoMessage projection({
    required String text,
    String footer = '',
    String? background,
  }) =>
      PalcoMessage(type: 'projection', fields: {
        'text': text,
        'footer': footer,
        if (background != null) 'background': background,
      });

  /// Áudio com now-playing opcional.
  static PalcoMessage audio(
    String url, {
    String action = 'play',
    String? title,
    String? subtitle,
    String? cover,
  }) =>
      PalcoMessage(type: 'audio', fields: {
        'url': url,
        'action': action,
        if (title != null) 'title': title,
        if (subtitle != null) 'subtitle': subtitle,
        if (cover != null) 'cover': cover,
      });

  static PalcoMessage video(String url, {String action = 'play'}) =>
      PalcoMessage(type: 'video', fields: {'url': url, 'action': action});

  static PalcoMessage timer({
    required String action,
    int duration = 0,
    String mode = 'countdown',
    String label = '',
  }) =>
      PalcoMessage(type: 'timer', fields: {
        'action': action,
        'duration': duration,
        'mode': mode,
        'label': label,
      });

  static PalcoMessage bgPalco(String? url) =>
      PalcoMessage(type: 'bgPalco', fields: {'url': url ?? ''});

  static const PalcoMessage idleRequest = PalcoMessage(type: 'idle');

  // ---- Accessors receiver→sender ----

  /// remote-key: setas/OK do controle da TV ('next' | 'prev').
  String? get remoteKey => fields['key'] as String?;

  /// ended: audio|video terminou.
  String? get endedMedia => fields['media'] as String?;
}

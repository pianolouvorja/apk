library;

/// Guard de versão do APK: bloqueia instalar um APK que não avance a
/// versão instalada (mesma ou regredida).
///
/// Causa real (2026-08-16): release v0.1.16 anexada com APK que tinha
/// versionName 0.1.15 interno (build copiado antes do bump). O updater
/// baixava, instalava com sucesso e o app "continuava na 0.1.15" —
/// loop de atualização que não atualiza. Este guard aborta o fluxo ANTES
/// de baixar quando o alvo não avança a versão.
class ApkVersionGuard {
  static ApkVersionDecision canInstall({
    required String installed,
    required String available,
  }) {
    final cur = _parse(installed);
    final next = _parse(available);
    // Versão desconhecida (dev/edge): não bloqueia o fluxo.
    if (cur == null || next == null) {
      return const ApkVersionDecision(allowed: true);
    }
    if (next[0] == cur[0] && next[1] == cur[1] && next[2] == cur[2]) {
      return const ApkVersionDecision(
        allowed: false,
        reason: ApkVersionRejectReason.sameVersion,
      );
    }
    if (!_isNewer(next, cur)) {
      return const ApkVersionDecision(
        allowed: false,
        reason: ApkVersionRejectReason.regression,
      );
    }
    return const ApkVersionDecision(allowed: true);
  }

  static List<int>? _parse(String v) {
    if (v.isEmpty) return null;
    final clean = v.replaceFirst(RegExp('^v'), '');
    final parts = clean.split('.');
    if (parts.length != 3) return null;
    final nums = parts.map(int.tryParse).toList();
    if (nums.any((n) => n == null)) return null;
    return nums.cast<int>();
  }

  static bool _isNewer(List<int> a, List<int> b) {
    for (var i = 0; i < 3; i++) {
      if (a[i] != b[i]) return a[i] > b[i];
    }
    return false;
  }
}

class ApkVersionDecision {
  final bool allowed;
  final ApkVersionRejectReason? reason;
  const ApkVersionDecision({required this.allowed, this.reason});
}

enum ApkVersionRejectReason { sameVersion, regression }

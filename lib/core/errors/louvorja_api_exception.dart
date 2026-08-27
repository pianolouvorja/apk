library;

/// Exceção da API LouvorJA com código i18n para exibição ao usuário.
///
/// Códigos usados: errors.authFailed, errors.notFound, errors.serverBusy,
/// errors.connection.
class LouvorjaApiException implements Exception {
  final String code;
  final String detail;

  const LouvorjaApiException(this.code, this.detail);

  @override
  String toString() => 'LouvorjaApiException($code): $detail';
}

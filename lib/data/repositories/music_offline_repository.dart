library;

/// Implementação persistente em Android/iOS/Desktop e fallback explícito Web.
export 'music_offline_repository_stub.dart'
    if (dart.library.io) 'music_offline_repository_native.dart';

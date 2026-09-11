/// Música dentro de uma coletânea custom (lista da EditPage).
class CustomCollectionMusic {
  final int id;
  final int collectionId;
  final String name;
  final String? duration;
  final int? officialMusicId;

  const CustomCollectionMusic({
    required this.id,
    required this.collectionId,
    required this.name,
    this.duration,
    this.officialMusicId,
  });

  factory CustomCollectionMusic.fromJson(Map<String, dynamic> json) =>
      CustomCollectionMusic(
        id: (json['id_music'] as num?)?.toInt() ?? 0,
        collectionId: (json['id_collection'] as num?)?.toInt() ?? 0,
        name: (json['name'] as String?) ?? '',
        duration: json['duration'] as String?,
        officialMusicId: (json['official_music_id'] as num?)?.toInt(),
      );
}

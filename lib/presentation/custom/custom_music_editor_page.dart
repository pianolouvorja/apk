import 'dart:io';

import 'package:flutter/material.dart';

import 'package:file_selector/file_selector.dart';

import 'package:louvorja_piano_mobile/data/datasources/remote/custom_catalog_api_impl.dart';
import 'package:louvorja_piano_mobile/data/datasources/remote/custom_file_api.dart';
import 'package:louvorja_piano_mobile/domain/entities/custom_collection.dart';
import 'package:louvorja_piano_mobile/domain/entities/custom_lyric_slide.dart';

/// Criador de música custom (v3.1): nome, letra dividida em estrofes,
/// áudio opcional e timing gravado tocando a música.
///
/// Fluxo: salvar música → abre gravação de timing (se houver áudio).
class CustomMusicEditorPage extends StatefulWidget {
  final CustomCatalogApiImpl api;
  final CustomFileApi fileApi;
  final CustomCollection collection;
  final String bearerToken;

  const CustomMusicEditorPage({
    super.key,
    required this.api,
    required this.fileApi,
    required this.collection,
    required this.bearerToken,
  });

  @override
  State<CustomMusicEditorPage> createState() => _CustomMusicEditorPageState();
}

class _CustomMusicEditorPageState extends State<CustomMusicEditorPage> {
  final _nameController = TextEditingController();
  final _lyricController = TextEditingController();
  File? _audioFile;
  double _uploadProgress = 0;
  bool _busy = false;

  @override
  void dispose() {
    _nameController.dispose();
    _lyricController.dispose();
    super.dispose();
  }

  Future<void> _pickAudio() async {
    const typeGroup = XTypeGroup(
      label: 'Áudio',
      extensions: ['mp3', 'm4a', 'aac', 'ogg', 'wav'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return;
    setState(() => _audioFile = File(file.path));
  }

  /// Salva: upload de áudio (se houver) → cria música → cria estrofes com
  /// order sequencial (time vazio = slide manual; timing vem depois).
  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _busy || !mounted) return;
    final slides = CustomLyricSlide.splitIntoSlides(_lyricController.text);
    setState(() => _busy = true);

    try {
      int? idFileAudio;
      if (_audioFile != null) {
        final upload = await widget.fileApi.upload(
          _audioFile!,
          kind: 'audio',
          bearerToken: widget.bearerToken,
          onProgress: (p) => setState(() => _uploadProgress = p),
        );
        idFileAudio = upload.idFile;
      }

      final musicId = await widget.api.createMusic(
        collectionId: widget.collection.id,
        name: name,
        lyric: _lyricController.text.trim(),
        idFileAudio: idFileAudio,
        bearerToken: widget.bearerToken,
      );

      // Estrofes: salvo cada uma com order (timing opcional depois).
      for (var i = 0; i < slides.length; i++) {
        await widget.api.addLyric(
          musicId: musicId,
          lyric: slides[i],
          order: i,
          time: '00:00.000',
          bearerToken: widget.bearerToken,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$name" criada com ${slides.length} estrofes!'),
        ),
      );
      Navigator.of(context).pop(musicId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Falha ao salvar. Verifica o login e tenta de novo.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final slides = CustomLyricSlide.splitIntoSlides(_lyricController.text);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova música'),
        actions: [
          TextButton(
            onPressed: _busy ? null : _save,
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Salvar'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nome da música',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _lyricController,
            maxLines: 12,
            decoration: const InputDecoration(
              labelText: 'Letra',
              helperText:
                  'Separe os slides com uma linha em branco (igual no PC)',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          if (slides.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '${slides.length} estrofes detectadas',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _pickAudio,
                  icon: const Icon(Icons.audiotrack),
                  label: Text(
                    _audioFile == null
                        ? 'Escolher áudio (opcional)'
                        : 'Áudio: ${_audioFile!.path.split('/').last}',
                  ),
                ),
              ),
            ],
          ),
          if (_busy && _audioFile != null && _uploadProgress < 1) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(value: _uploadProgress),
            const SizedBox(height: 4),
            Text(
              'Enviando áudio: ${(_uploadProgress * 100).toStringAsFixed(0)}%',
              style: theme.textTheme.labelSmall,
            ),
          ],
        ],
      ),
    );
  }
}

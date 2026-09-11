import 'package:flutter/material.dart';

import 'package:louvorja_piano_mobile/data/datasources/remote/custom_catalog_api_impl.dart';
import 'package:louvorja_piano_mobile/domain/entities/custom_collection.dart';
import 'package:louvorja_piano_mobile/domain/entities/custom_collection_music.dart';

/// Edição de coletânea própria (v2.1): lista músicas, adicionar/remover,
/// renomear e excluir. Dono apenas — chamada quando collection.isOwner.
class CustomCollectionEditPage extends StatefulWidget {
  final CustomCatalogApiImpl api;
  final CustomCollection collection;
  final String bearerToken;

  const CustomCollectionEditPage({
    super.key,
    required this.api,
    required this.collection,
    required this.bearerToken,
  });

  @override
  State<CustomCollectionEditPage> createState() =>
      _CustomCollectionEditPageState();
}

class _CustomCollectionEditPageState extends State<CustomCollectionEditPage> {
  late String _name;
  List<CustomCollectionMusic>? _musics;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _name = widget.collection.name;
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await widget.api
          .fetchCollectionMusics(widget.collection.id, bearerToken: widget.bearerToken);
      if (!mounted) return;
      setState(() {
        _musics = list;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Não foi possível carregar as músicas.');
    }
  }

  Future<void> _removeMusic(CustomCollectionMusic music) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover música'),
        content: Text('Remover "${music.name}" desta coletânea?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remover')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.api.removeMusicFromCollection(
          musicId: music.id, bearerToken: widget.bearerToken);
      await _load();
    } catch (_) {
      if (mounted) _showSnack('Falha ao remover. Tente novamente.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _rename() async {
    final controller = TextEditingController(text: _name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renomear coletânea'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nome'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () =>
                  Navigator.pop(context, controller.text.trim()),
              child: const Text('Salvar')),
        ],
      ),
    );
    if (newName == null || newName.isEmpty || newName == _name || !mounted) {
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.api.updateCollection(widget.collection.id,
          name: newName, bearerToken: widget.bearerToken);
      if (!mounted) return;
      setState(() => _name = newName);
    } catch (_) {
      if (mounted) _showSnack('Falha ao renomear. Tente novamente.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteCollection() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir coletânea'),
        content: Text(
            'Excluir "$_name" e suas ${_musics?.length ?? 0} músicas? Isso não pode ser desfeito.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.api
          .deleteCollection(widget.collection.id, bearerToken: widget.bearerToken);
      if (!mounted) return;
      Navigator.of(context).pop(true); // sinaliza exclusão pra lista recarregar
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        _showSnack('Falha ao excluir. Tente novamente.');
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_name),
        actions: [
          IconButton(
            tooltip: 'Renomear',
            icon: const Icon(Icons.edit),
            onPressed: _busy ? null : _rename,
          ),
          IconButton(
            tooltip: 'Excluir coletânea',
            icon: const Icon(Icons.delete_outline),
            onPressed: _busy ? null : _deleteCollection,
          ),
        ],
      ),
      body: _musics == null && _error == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar novamente'),
                    ),
                  ],
                ))
              : _musics!.isEmpty
                  ? Center(
                      child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'Coletânea vazia.\nToque em "+" para adicionar hinos.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ))
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _musics!.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 4),
                      itemBuilder: (context, i) {
                        final m = _musics![i];
                        return ListTile(
                          leading: const Icon(Icons.music_note),
                          title: Text(m.name),
                          subtitle: m.duration != null ? Text(m.duration!) : null,
                          trailing: _busy
                              ? null
                              : IconButton(
                                  tooltip: 'Remover',
                                  icon: const Icon(Icons.close),
                                  onPressed: () => _removeMusic(m),
                                ),
                        );
                      },
                    ),
      // RF-03 (adicionar hino oficial) entra na v2.2 — depende do buscador
      // do catálogo local; a casca do FAB já fica pronta.
    );
  }
}

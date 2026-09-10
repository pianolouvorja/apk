import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:louvorja_piano_mobile/core/constants/api_config.dart';
import 'package:louvorja_piano_mobile/data/datasources/remote/custom_catalog_api_impl.dart';
import 'package:louvorja_piano_mobile/domain/entities/custom_collection.dart';

/// Coletâneas Custom da comunidade (v1 — leitura).
///
/// Lista coletâneas públicas da API custom, permite ver o detalhe
/// (músicas) e baixar uma coletânea inteira para uso offline.
class CustomCollectionsPage extends StatefulWidget {
  /// Injeção opcional de Dio (testes). Null = Dio padrão com timeouts.
  final Dio? dio;

  const CustomCollectionsPage({super.key, this.dio});

  /// Dio padrão da página. Visível p/ testes (RF-01: timeouts 8s/15s).
  @visibleForTesting
  static Dio buildDefaultDio() => Dio(BaseOptions(
        // Sem timeout o request fica pendurado quando o host não responde
        // (ex.: saiu do Wi-Fi de casa) — falha rápida com erro claro.
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 15),
      ));

  @override
  State<CustomCollectionsPage> createState() => _CustomCollectionsPageState();
}

class _CustomCollectionsPageState extends State<CustomCollectionsPage> {
  late final CustomCatalogApiImpl _api;
  List<CustomCollection>? _collections;
  String? _error;

  @override
  void initState() {
    super.initState();
    _api = CustomCatalogApiImpl.withDio(
      dio: widget.dio ?? CustomCollectionsPage.buildDefaultDio(),
      apiBaseUrl: _apiBase(),
      filesBaseUrl: ApiConfig.urlFiles,
    );
    _load();
  }

  /// A API custom vive na mesma origem da URL de database, menos o sufixo /json_db.
  static String _apiBase() {
    final db = ApiConfig.urlDatabase;
    return db.endsWith('/json_db')
        ? db.substring(0, db.length - '/json_db'.length)
        : db;
  }

  Future<void> _load() async {
    try {
      final collections = await _api.fetchCollections();
      if (!mounted) return;
      setState(() {
        _collections = collections;
        _error = null;
      });
    } catch (e) {
      // Diagnóstico: sem este log o catch engole a exceção e fica impossível
      // distinguir timeout de DNS de conexão recusada no logcat.
      // ignore: avoid_print
      print('[custom-collections] erro ao carregar: $e');
      if (!mounted) return;
      final detalhe = e is DioException
          ? ' (${e.type.name})'
          : '';
      setState(() =>
          _error = 'Não foi possível carregar as coletâneas$detalhe.\nVerifique sua conexão e tente novamente.');
    }
  }

  Future<void> _download(CustomCollection collection) async {
    try {
      await _api.joinCollection(collection);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Coletânea "${collection.name}" baixada!')),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falha ao baixar coletânea.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coletâneas da Comunidade'),
      ),
      body: _collections == null && _error == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _collections!.isEmpty
                      ? ListView(
                          children: const [
                            Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(
                                child: Text(
                                  'Nenhuma coletânea compartilhada ainda.\n\nCrie a primeira no app de desktop!',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _collections!.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final c = _collections![index];
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text('${c.musicsCount}'),
                                ),
                                title: Text(c.name),
                                subtitle: c.authorName != null
                                    ? Text('por ${c.authorName}')
                                    : null,
                                trailing: FutureBuilder<Set<int>>(
                                  future: _api.fetchJoinedCollectionIds(),
                                  builder: (context, snapshot) {
                                    final joined =
                                        snapshot.data?.contains(c.id) ?? false;
                                    return joined
                                        ? const Icon(Icons.download_done,
                                            color: Colors.green)
                                        : IconButton(
                                            icon: const Icon(Icons.download),
                                            tooltip: 'Baixar',
                                            onPressed: () => _download(c),
                                          );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}

library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;

/// Descoberta de receivers Palco na sub-rede (F3.4).
///
/// Espelho da técnica usada pelo receiver webOS para achar o sender:
/// `GET http://<ip>:7080/status` — JSON com campo "unlocked" identifica
/// um sender LouvorJA (nossa TV também responde assim quando viaja
/// no modo receiver-browser).
///
/// Usado pelo StageCastButton para listar "Palcos encontrados" em vez
/// de exigir digitação de IP.
abstract final class PalcoDiscovery {
  /// Varre [subnet].1-.254 (ex: '192.168.1') e retorna os IPs com sender.
  static Future<List<String>> scan({
    String? subnet,
    Duration timeout = const Duration(milliseconds: 900),
    int concurrency = 24,
  }) async {
    subnet ??= await _ownSubnet();
    if (subnet == null) return const [];
    final ips = [for (var i = 1; i < 255; i++) '$subnet.$i'];
    final found = <String>[];
    for (var i = 0; i < ips.length; i += concurrency) {
      final batch = ips.skip(i).take(concurrency);
      await Future.wait(batch.map((ip) => _probe(ip, timeout, found)));
    }
    return found;
  }

  static Future<void> _probe(
      String ip, Duration timeout, List<String> out) async {
    try {
      final hc = HttpClient()..connectionTimeout = timeout;
      final req = await hc
          .getUrl(Uri.parse('http://$ip:7080/status'))
          .timeout(timeout);
      final res = await req.close().timeout(timeout);
      final body = await res.transform(utf8.decoder).join().timeout(timeout);
      hc.close(force: true);
      final j = jsonDecode(body);
      if (j is Map && j.containsKey('unlocked')) {
        out.add(ip);
        debugPrint('[PALCO] discovery: sender em $ip');
      }
    } catch (_) {
      // sem resposta ou não é nosso — ignora
    }
  }

  /// Sub-rede (/24) do próprio aparelho, lendo as interfaces de rede.
  static Future<String?> _ownSubnet() async {
    try {
      for (final iface in await NetworkInterface.list()) {
        for (final addr in iface.addresses) {
          if (addr.type == InternetAddressType.IPv4 &&
              !addr.isLoopback &&
              !addr.address.startsWith('172.') // docker/bridge
          ) {
            final parts = addr.address.split('.');
            if (parts.length == 4) return parts.take(3).join('.');
          }
        }
      }
    } catch (_) {}
    return null;
  }
}

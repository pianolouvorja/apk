# SPEC: Sincronização Multi-Device — LouvorJA PIANO

> Como sincronizar dados (liturgia, favoritos, histórico, configurações, coletâneas pessoais) entre Desktop, Web e Mobile sem custo de infra e sem fricção para o usuário.

---

## Contexto

O operador pode usar o LouvorJA em múltiplos dispositivos:
- **Desktop da igreja** (Electron) — onde acontece o culto
- **Celular** (Flutter) — onde planeja no caminho
- **Desktop de casa** (Electron) — onde prepara durante a semana
- **Web app** (browser) — acesso rápido de qualquer PC

Os dados que precisam sincronizar:
| Dado | Tamanho típico | Frequência de mudança |
|------|---------------|---------------------|
| Liturgia do culto | 5-50 KB | Semanal |
| Coletâneas pessoais | 10-100 KB | Ocasional |
| Favoritos | 1-5 KB | Ocasional |
| Histórico/Recentes | 2-10 KB | A cada uso |
| Configurações (tema, fonte, idioma) | 1-3 KB | Raro |
| Schedule/Agendamento | 5-20 KB | Mensal |

**Nenhum desses dados é pesado.** O maior (coletâneas pessoais com referências) chega a 100KB. Isso abre possibilidades que não exigem infraestrutura pesada.

---

## Conflitos de Restrição

| Restrição | Implicação |
|-----------|-----------|
| **Zero custo de infra** | Não podemos ter servidor dedicado, VPS, ou banco de dados na nuvem |
| **Zero custo operacional** | Não podemos ter que gerenciar contas, senhas, reset, suporte |
| **Zero fricção pro usuário** | Login/senha é barreira — operador de igreja não quer criar conta |
| **LGPD** | Não coletar dado pessoal sem necessidade |
| **Offline-first** | Tudo funciona sem internet. Sync é bônus, não requisito |
| **Rede da igreja** | WiFi pode ser instável, lento, ou inexistente |

---

## As 7 Opções Mapeadas

### Opção 1: Sync via Rede Local (mDNS + WebSocket)
**Custo:** Zero | **Infra:** Zero | **Login:** Não precisa

```
Celular (Flutter)                    Desktop (Electron)
┌──────────────┐                    ┌──────────────┐
│ SQLite local │  WebSocket local   │ SQLite local │
│ dados novos  │ ─────────────────→ │ recebe dados │
│              │ ←───────────────── │ dados novos  │
└──────────────┘                    └──────────────┘
```

**Como funciona:**
1. Ambos dispositivos na mesma rede WiFi
2. mDNS encontra o desktop (issue #58 — já planejado)
3. WebSocket estabelece conexão (issue #59 — já planejado)
4. Protocolo de sync bilateral:
   - Cada lado envia seu `last_modified` timestamp por entidade
   - O lado mais novo envia o dado completo
   - Resolução de conflito: last-write-wins (LWW) por entidade

**Protocolo de sync:**
```json
{
  "type": "sync_request",
  "entities": {
    "liturgy": { "last_modified": "2026-08-06T10:00:00Z" },
    "favorites": { "last_modified": "2026-08-05T15:00:00Z" },
    "history": { "last_modified": "2026-08-06T09:00:00Z" }
  }
}
```
```json
{
  "type": "sync_response",
  "updates": [
    { "entity": "liturgy", "data": {...}, "modified": "2026-08-06T14:00:00Z" },
    { "entity": "favorites", "data": {...}, "modified": "2026-08-06T12:00:00Z" }
  ]
}
```

**Funciona para:** Todos os dados (liturgia, favoritos, histórico, config, coletâneas)
**Não funciona para:** Sync remoto (casa → igreja antes de chegar)
**Vantagem:** Automático, transparente, sem intervenção do usuário
**Desvantagem:** Só funciona na mesma rede
**Depende de:** Issues #58 (mDNS) + #59 (WebSocket)

**RFC: RF-SYNC-01**

---

### Opção 2: Sync via QR Code (transfer direto, sem rede)
**Custo:** Zero | **Infra:** Zero | **Login:** Não precisa

```
Celular gera QR → Desktop lê com câmera/webcam → Import
```

**Como funciona:**
1. Celular tem liturgia montada → toca "Exportar"
2. App gera QR code dinâmico (segmentado se >3KB)
3. Desktop aponta webcam pra tela do celular
4. Desktop decodifica e importa

**Capacidade do QR code:**
- 1 QR code: ~3KB de dados JSON (liturgia completa cabe fácil)
- QR segmentado (múltiplos): ~30KB (coletânea inteira)
- Compressão gzip antes de codificar: ~10KB útil por QR

**Funciona para:** Liturgia (pequeno), favoritos (minúsculo), config (minúsculo)
**Não funciona para:** Catálogo de hinos (grande), histórico longo
**Vantagem:** Funciona SEM rede, SEM internet, SEM qualquer infra
**Desvantagem:** Manual (usuário tem que gerar e apontar)
**Bibliotecas:** `qr_flutter` (gerar), `mobile_scanner` ou `flutter_inappwebview` (ler)

**RFC: RF-SYNC-02**

---

### Opção 3: Sync via Arquivo Exportável (.louvorja)
**Custo:** Zero | **Infra:** Zero | **Login:** Não precisa

```
Celular → exporta .louvorja → WhatsApp/email/USB → Desktop importa
```

**Como funciona:**
1. Usuário toca "Exportar" → app gera arquivo `.louvorja` (JSON gzipado)
2. Compartilha via WhatsApp, email, pendrive, Google Drive
3. Desktop abre o arquivo → importa

**Formato do arquivo:**
```
.louvorja = gzip({
  "version": 1,
  "exported_at": "2026-08-06T14:00:00Z",
  "device": "SM-A526B",
  "data": {
    "liturgy": {...},
    "favorites": [...],
    "collections": {...},
    "settings": {...}
  }
})
```

**Funciona para:** Todos os dados
**Não funciona para:** Sync automático (é manual)
**Vantagem:** Mais simples de implementar, funciona em qualquer cenário
**Desvantagem:** Não é automático, depende do usuário enviar o arquivo
**Bibliotecas:** `share_plus` (Flutter share), `file_picker` (Desktop import)

**RFC: RF-SYNC-03**

---

### Opção 4: Sync via GitHub (repo privado como backend)
**Custo:** Zero | **Infra:** Zero (GitHub grátis) | **Login:** GitHub OAuth

```
Celular → git push → GitHub repo privado → git pull → Desktop
```

**Como funciona:**
1. App pede GitHub OAuth login (que já temos no site)
2. Cria repo privado `louvorja-sync` automaticamente no primeiro uso
3. Dados salvos como JSON no repo: `data/liturgy.json`, `data/favorites.json`
4. Cada mudança = commit + push
5. Outro dispositivo = pull ao abrir

**Funciona para:** Todos os dados (repo privado tem 100MB grátis)
**Vantagem:** Sync remoto real, versionado, funciona de qualquer lugar
**Desvantagem:** Usuário precisa ter conta GitHub (barreira pra leigos)
**Bibliotecas:** `github_oauth` (Flutter), octokit no Electron

**RFC: RF-SYNC-04**

---

### Opção 5: Sync via WebRTC P2P (directo dispositivo-a-dispositório)
**Custo:** Zero | **Infra:** Mínima (signaling server simples) | **Login:** Não precisa

```
Celular → WebRTC data channel → Desktop (direto, sem servidor intermediário)
```

**Como funciona:**
1. Dispositivos trocam signaling via QR code ou código de 6 dígitos
2. WebRTC estabelece conexão P2P direta (STUN grátis do Google)
3. Data channel transfere JSON bidirecional
4. Depois de conectado, não precisa de servidor

**Funciona para:** Todos os dados
**Vantagem:** Funciona até pela internet (remoto), sem servidor de dados
**Desvantagem:** Signaling inicial complexo, NAT traversal pode falhar em redes corporativas
**Custo de infra:** STUN server grátis (stun.l.google.com). Signaling pode ser via QR ou WebSocket local.
**Bibliotecas:** `flutter_webrtc`, `wrtc` (Electron)

**RFC: RF-SYNC-05**

---

### Opção 6: Sync via Firestore (Firebase — já configurado)
**Custo:** Grátis até 50k reads/dia, 20k writes/dia | **Infra:** Já temos | **Login:** Anônimo

```
Celular → Firestore → Desktop
         (collection sync)
```

**Como funciona:**
1. App gera `device_id` (UUID aleatório, não PII)
2. Usuário pareia dispositivos com código de 6 dígitos (não login)
3. Dados salvos em `collection: sync_{pair_code}`
4. Firestore realtime listener atualiza ambos dispositivos

**Funciona para:** Todos os dados
**Vantagem:** Já temos Firebase configurado, realtime nativo
**Desvantagem:** Dado em servidor Google (EUA), LGPD exige consentimento, dependência de internet
**Custo real:** Praticamente zero pra volume de igreja (~100 writes/dia por dispositivo)
**Login:** Anônimo auth (Firebase Anonymous Auth — não pede email/senha)

**RFC: RF-SYNC-06**

---

### Opção 7: Sync via Nuvem Brasileira ( AngularFire / WebStorage / Object Storage)
**Custo:** ~R$5-10/mês | **Infra:** Sim | **Login:** Código de pareamento

```
Celular → POST /api/sync → Object Storage (Brasil) → GET /api/sync → Desktop
```

**Como funciona:**
1. Endpoint no piano-site (Nuxt server que já temos): `POST /api/sync` e `GET /api/sync`
2. Dados ficam em arquivo no disco do servidor (simples, sem DB)
3. Código de pareamento identifica qual conjunto de dados pertence a qual usuário
4. TTL de 7 dias (dados expiram se não sincronizar)

**Funciona para:** Todos os dados
**Vantagem:** Servidor no Brasil (LGPD-friendly), nosso controle
**Desvantagem:** Precisa de servidor rodando (já temos o piano-site)
**Custo:** O servidor do piano-site já roda de graça. Só adicionar 2 endpoints.

**RFC: RF-SYNC-07**

---

## Matriz de Decisão

| Critério | Opção 1 (Local) | Opção 2 (QR) | Opção 3 (Arquivo) | Opção 4 (GitHub) | Opção 5 (WebRTC) | Opção 6 (Firestore) | Opção 7 (Nuvem BR) |
|----------|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **Custo** | Zero | Zero | Zero | Zero | Zero | Grátis* | R$5/mês |
| **Infra** | Zero | Zero | Zero | Zero | Mínima | Já temos | Já temos |
| **Login necessário** | Não | Não | Não | GitHub | Não | Anônimo | Código |
| **Sync automático** | Sim | Não | Não | Sim | Sim | Sim | Sim |
| **Funciona remoto** | Não | Não | Sim (manual) | Sim | Sim | Sim | Sim |
| **Funciona offline** | N/A | Sim | Sim | Não | Não | Não | Não |
| **LGPD** | OK | OK | OK | Risco | OK | Atenção | OK |
| **Fricção usuário** | Zero | Baixa | Média | Alta | Baixa | Zero | Zero |
| **Esforço implementação** | 6h | 4h | 3h | 8h | 12h | 6h | 5h |
| **Depende de existente** | #58+#59 | — | — | OAuth site | — | Firebase | piano-site |

*Firestore grátis até 50k reads/dia

---

## Recomendação: Estratégia em 3 Camadas

Em vez de escolher uma, recomendo implementar **3 camadas complementares** que cobrem todos os cenários:

### Camada 1: Sync Local Automático (Opção 1) — Prioridade
- **Quando:** Chegou na igreja, celular e desktop no mesmo WiFi
- **Como:** mDNS + WebSocket, automático, transparente
- **Cobre:** Cenário principal (90% dos casos)
- **Esforço:** ~6h (mas #58 + #59 já vão estar implementados)

### Camada 2: Transferência por QR Code (Opção 2) — Fallback
- **Quando:** Sem WiFi na igreja, ou WiFi não permite mDNS
- **Como:** Celular gera QR, desktop lê com câmera
- **Cobre:** Cenário sem rede (8% dos casos)
- **Esforço:** ~4h

### Camada 3: Arquivo Exportável (Opção 3) — Último recurso
- **Quando:** Operador preparou em casa, quer levar pronto
- **Como:** Exporta `.louvorja`, manda no WhatsApp, abre no desktop
- **Cobre:** Cenário remoto assíncrono (2% dos casos)
- **Esforço:** ~3h

**Por que não as outras?**
- **GitHub (4):** Barreira de entrada muito alta pra usuário de igreja
- **WebRTC (5):** Complexidade alta, NAT traversal imprevisível em redes de igreja
- **Firestore (6):** Funciona mas adiciona dependência de Google + LGPD. Manter como opção futura se as 3 camadas não forem suficientes.
- **Nuvem BR (7):** Funciona mas adiciona custo/complexidade. Manter como opção futura.

**Esforço total das 3 camadas:** ~13h

---

## RFCs Detalhados

### RF-SYNC-01: Sync Local Automático (Opção 1)
**User Story:** Como operador, quero que minha liturgia e favoritos sincronizem entre celular e desktop automaticamente quando estou na igreja.

**Critérios de Aceite:**
- WHEN celular e desktop estão na mesma rede THE SYSTEM SHALL detectar via mDNS e conectar via WebSocket
- WHEN um dispositivo tem dados mais novos THE SYSTEM SHALL enviar para o outro automaticamente
- THE SYSTEM SHALL usar last-write-wins (LWW) por entidade para resolver conflitos
- THE SYSTEM SHALL mostrar indicador "Sincronizado" quando sync completa
- THE SYSTEM SHALL mostrar indicador "Sincronizando..." durante transferência
- WHEN sync falha THE SYSTEM SHALL notificar e tentar novamente
- THE SYSTEM SHALL NUNCA sobrescrever dados sem backup (manter versão anterior por 7 dias)

**Entidades sincronizadas:**
- `liturgy` — liturgia montada (array de itens)
- `favorites` — lista de hinos favoritos (array de IDs)
- `history` — últimos hinos acessados (array com timestamp)
- `collections` — coletâneas pessoais (objetos com itens)
- `settings` — preferências do usuário (tema, fonte, idioma, cor)

### RF-SYNC-02: Transferência por QR Code (Opção 2)
**User Story:** Como operador, quero transferir minha liturgia do celular pro desktop sem WiFi.

**Critérios de Aceite:**
- WHEN operador toca "Exportar via QR" THE SYSTEM SHALL gerar QR code na tela do celular
- IF dados > 3KB THE SYSTEM SHALL usar QR segmentado (múltiplos QR codes em sequência)
- THE SYSTEM SHALL comprimir dados com gzip antes de gerar QR
- WHEN desktop lê o QR code THE SYSTEM SHALL importar os dados
- THE SYSTEM SHALL confirmar antes de sobrescrever dados existentes

### RF-SYNC-03: Arquivo Exportável (Opção 3)
**User Story:** Como operador, quero exportar minha liturgia como arquivo pra enviar por WhatsApp.

**Critérios de Aceite:**
- WHEN operador toca "Exportar arquivo" THE SYSTEM SHALL gerar `.louvorja` (JSON gzipado)
- THE SYSTEM SHALL abrir share sheet do celular (WhatsApp, email, salvar)
- WHEN desktop abre arquivo `.louvorja` THE SYSTEM SHALL importar e aplicar
- THE SYSTEM SHALL versionar o formato (campo `version` no JSON)
- THE SYSTEM SHALL confirmar antes de sobrescrever dados existentes

### RF-SYNC-04: Sync via GitHub (Opção 4)
**User Story:** Como operador técnico, quero sincronizar via GitHub para ter versionamento completo.

**Critérios de Aceite:**
- THE SYSTEM SHALL pedir GitHub OAuth login (só uma vez)
- THE SYSTEM SHALL criar repo privado `louvorja-sync` automaticamente
- THE SYSTEM SHALL salvar dados como JSON no repo
- THE SYSTEM SHALL sincronizar ao abrir o app (pull) e ao modificar (push com debounce)
- THE SYSTEM SHALL resolver conflitos com merge ou LWW

### RF-SYNC-05: Sync via WebRTC P2P (Opção 5)
**User Story:** Como operador, quero sincronizar diretamente entre dois dispositivos sem servidor.

**Critérios de Aceite:**
- THE SYSTEM SHALL parear dispositivos via código de 6 dígitos ou QR code
- THE SYSTEM SHALL estabelecer WebRTC data channel P2P
- THE SYSTEM SHALL usar STUN server grátis (stun.l.google.com)
- THE SYSTEM SHALL transferir JSON bidirecional
- WHEN NAT impede conexão THE SYSTEM SHALL fallback para Opção 2 ou 3

### RF-SYNC-06: Sync via Firestore (Opção 6)
**User Story:** Como sistema, quero usar Firestore para sync realtime entre dispositivos.

**Critérios de Aceite:**
- THE SYSTEM SHALL gerar `device_id` (UUID) no primeiro uso
- THE SYSTEM SHALL parear dispositivos com código de 6 dígitos
- THE SYSTEM SHALL usar Firebase Anonymous Auth (sem email/senha)
- THE SYSTEM SHALL salvar dados em `collection: sync_{pair_code}`
- THE SYSTEM SHALL usar Firestore realtime listener para atualização instantânea
- THE SYSTEM SHALL expirar dados após 30 dias sem sync
- THE SYSTEM SHALL informar sobre transferência internacional (LGPD Art. 33)

### RF-SYNC-07: Sync via Nuvem Brasileira (Opção 7)
**User Story:** Como sistema, quero oferecer sync com dados no Brasil.

**Critérios de Aceite:**
- THE SYSTEM SHALL criar endpoints `POST /api/sync` e `GET /api/sync` no piano-site
- THE SYSTEM SHALL parear dispositivos com código de 6 dígitos
- THE SYSTEM SHALL salvar dados como arquivo JSON no disco do servidor
- THE SYSTEM SHALL aplicar TTL de 7 dias (dados expiram)
- THE SYSTEM SHALL limitar payload a 500KB por sync

---

## Fora de Escopo
- Sync de catálogo de hinos (já vem do servidor central via API)
- Sync de mídia (áudio, imagens — muito pesado, fica local por dispositivo)
- Multi-usuário (cada operador tem seu conjunto, não compartilha entre usuários)
- Collaborative editing (edição simultânea da mesma liturgia por 2 pessoas)

---

## Estimativa (3 camadas recomendadas)

| Camada | Opção | Esforço | Prioridade |
|--------|-------|---------|------------|
| 1 — Sync local | Opção 1 | 6h | P1 (depois de #58+#59) |
| 2 — QR code | Opção 2 | 4h | P2 |
| 3 — Arquivo | Opção 3 | 3h | P2 |
| **Total** | | **13h** | |

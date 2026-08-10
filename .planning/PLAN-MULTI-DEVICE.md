# PLAN: Ecossistema Multi-Device — Integração Desktop ↔ Mobile ↔ TV

> Pré-requisitos: Controle Remoto base (#27) no desktop, app Flutter inicial (F1-F2 do PLAN original)
> Esta SPEC adiciona conectividade multi-device por cima da base existente

---

## Fase MD-1: Descoberta e Conexão (mDNS + WebSocket)

### MD-1-T1: mDNS no Desktop Electron
**Repo:** pianolouvorja/app
**Instalar:** `bonjour-service`
**Criar:**
- `electron/remote/mdns.mjs` — anuncia `_louvorja._tcp` na porta 7070
**Modificar:**
- `electron/main.mjs` — iniciar mDNS no whenReady, parar no before-quit

**Commit:** `feat(remote): mDNS announcement para descoberta automatica`

### MD-1-T2: WebSocket Server no Desktop
**Repo:** pianolouvorja/app
**Criar:**
- `electron/remote/websocket.mjs` — WebSocket server (ws library ou Express + ws)
- Protocolo de mensagens bidirecional:
  ```json
  // Desktop → Mobile
  { "type": "state", "slide": { "title", "lyrics", "next" }, "player": { "playing", "position" } }
  // Mobile → Desktop
  { "type": "command", "action": "next_slide" | "prev_slide" | "play_pause" | "search" | "open_song" }
  ```

**Commit:** `feat(remote): WebSocket server para comunicacao bidirecional`

### MD-1-T3: Cliente mDNS + WebSocket no Flutter
**Repo:** pianolouvorja/mobile
**Instalar:** `bonsoir` (mDNS), `web_socket_channel` (WebSocket)
**Criar:**
- `lib/data/datasources/local/mdns_scanner.dart` — encontra desktops na rede
- `lib/data/datasources/remote/desktop_connection.dart` — WebSocket client
- `lib/presentation/connection/connection_page.dart` — UI de seleção de desktop

**UX:**
1. App abre → mostra "Procurando desktop LouvorJA..."
2. Encontra → "Conectar a DESKTOP-IGREJA (192.168.1.50)"
3. Não encontra → "Inserir IP manualmente"
4. Conecta → mostra estado do desktop (música atual, slide atual)

**Commit:** `feat(connection): mDNS discovery + WebSocket client`

---

## Fase MD-2: Controle Remoto Nativo (Flutter → Desktop)

### MD-2-T1: Tela de controle remoto no Flutter
**Repo:** pianolouvorja/mobile
**Criar:**
- `lib/presentation/remote/remote_control_page.dart`
- Grid de botões touch grandes (play/pause, próximo, anterior, volume)
- Busca de hinos com resultados do desktop
- Abre hino no desktop via WebSocket command

**Commit:** `feat(remote): tela de controle remoto nativo`

### MD-2-T2: Estado reativo do desktop no Flutter
**Criar:**
- `lib/presentation/remote/bloc/remote_bloc.dart`
- Recebe state do desktop via WebSocket → atualiza UI
- Mostra: música atual, slide atual, posição do player, tempo decorrido

**Commit:** `feat(remote): BLoC com estado reativo do desktop`

---

## Fase MD-3: Stage Display Remoto (Mirror no Celular)

### MD-3-T1: Renderização de slides no Flutter
**Repo:** pianolouvorja/mobile
**Criar:**
- `lib/presentation/stage/stage_display_page.dart`
- `lib/presentation/stage/widgets/slide_renderer.dart` — renderiza letra/versículo
- Recebe dados via WebSocket, renderiza nativamente (não é screenshot)
- Background escuro, fonte grande
- Wakelock (`wakelock_plus`) pra manter tela acesa

**Commit:** `feat(stage): renderização nativa de slides + wakelock`

### MD-3-T2: Preview do próximo slide
**Criar:**
- `lib/presentation/stage/widgets/next_slide_preview.dart`
- Mostra próximo slide em tamanho menor no rodapé

**Commit:** `feat(stage): preview do próximo slide`

---

## Fase MD-4: Cast para Chromecast/TV

### MD-4-T1: Cast SDK no Flutter
**Repo:** pianolouvorja/mobile
**Instalar:** `flutter_chrome_cast` ou platform channels nativos
**Criar:**
- `lib/presentation/cast/cast_page.dart` — escaneia dispositivos Cast
- `lib/presentation/cast/bloc/cast_bloc.dart` — gerencia sessão Cast

**UX:**
1. Usuário toca ícone de Cast na toolbar
2. Lista dispositivos Chromecast na rede
3. Seleciona → abre Custom Receiver na TV
4. Slides são enviados via Cast Message Channel

**Commit:** `feat(cast): Google Cast SDK + escaneamento de dispositivos`

### MD-4-T2: Cast Custom Receiver (HTML no Desktop)
**Repo:** pianolouvorja/app
**Criar:**
- `electron/remote/public/cast-receiver.html` — página HTML que o Chromecast carrega
- Recebe mensagens via Cast Message Channel
- Renderiza slide (letra, versículo) em tela cheia
- Tema escuro, fonte grande

**Commit:** `feat(cast): Custom Receiver HTML para Chromecast`

---

## Fase MD-5: DLNA (TVs sem Chromecast)

### MD-5-T1: DLNA sender no Desktop Electron
**Repo:** pianolouvorja/app
**Instalar:** `node-ssdp` (descoberta), `node-upnp-mediarenderer-client` (envio)
**Criar:**
- `electron/remote/dlna.mjs` — escaneia TVs DLNA na rede via SSDP
- Renderiza slide atual como JPEG → envia via DLNA para TV selecionada
- Atualiza quando slide muda (throttle 500ms pra não sobrecarregar)

**Commit:** `feat(dlna): descoberta e envio de slides para TVs via DLNA`

### MD-5-T2: UI de seleção de TV no Flutter
**Repo:** pianolouvorja/mobile
**Criar:**
- `lib/presentation/cast/device_selector_page.dart`
- Mostra dispositivos DLNA + Cast numa lista unificada
- Envia comando pro desktop: "conectar DLNA a este dispositivo"

**Commit:** `feat(cast): seletor de dispositivo unificado (Cast + DLNA)`

---

## Fase MD-6: QR Code + Browser Fallback

### MD-6-T1: QR Code na tela do Desktop
**Repo:** pianolouvorja/app
**Criar:**
- Renderizar QR code na janela de projeção com URL `http://IP:7070/mirror`
- Usuário aponta o celular e abre no browser — fallback universal

**Commit:** `feat(remote): QR code para acesso rapido ao mirror HTTP`

---

## Ordem de Implementação

```
MD-1 (descoberta + WebSocket)     → base de tudo
  ↓
MD-2 (controle remoto)            → valor imediato pro usuario
  ↓
MD-3 (stage display)              → valor pro musico
  ↓
MD-4 (Cast)                       → valor pra igreja com Chromecast
  ↓
MD-5 (DLNA)                       → valor pra igreja com TV inteligente
  ↓
MD-6 (QR code)                    → fallback universal
```

Cada fase é shippable independentemente. MD-1 + MD-2 ja entregam o controle remoto nativo.

## Estimativa

| Fase | Desktop | Flutter | Total |
|------|---------|---------|-------|
| MD-1: Descoberta + WS | 4h | 4h | 8h |
| MD-2: Controle remoto | — | 4h | 4h |
| MD-3: Stage display | — | 4h | 4h |
| MD-4: Cast | 2h | 4h | 6h |
| MD-5: DLNA | 4h | 2h | 6h |
| MD-6: QR code | 1h | — | 1h |
| **Total** | **11h** | **18h** | **29h** |

## Dependências
- MD-1 depende de #27 (servidor HTTP base no desktop)
- MD-2 depende de MD-1
- MD-4 depende de MD-1 (Cast precisa do desktop online)
- MD-5 depende de MD-1 (DLNA precisa do desktop)
- Fases MD-4 e MD-5 podem rodar em paralelo

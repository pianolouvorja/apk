# SPEC: Ecossistema Multi-Device LouvorJA — Desktop, Web, Mobile, TV

> Visão arquitetural completa de como todos os dispositivos se conectam.
> Desktop = source (fonte da projeção). Mobile = controle + display. TV = sink (recebe projeção).
> Repos: pianolouvorja/app (Electron), pianolouvorja/web (PWA), pianolouvorja/mobile (Flutter), pianolouvorja/site

---

## Arquitetura Geral

```
                    REDE LOCAL DA IGREJA (WiFi)
                    
Desktop (Electron)                          Celular (Flutter)
┌──────────────────────┐                   ┌──────────────────────┐
│ SOURCE — Fonte        │   WebSocket/SSE   │ CONTROLE + DISPLAY   │
│                      │ ←────────────────→ │                      │
│ • Player de mídia    │   Estado projeção  │ • Controlar player   │
│ • Projeção multi-tela│   Comandos remotos │ • Buscar hinos       │
│ • Liturgia completa  │                    │ • Ver letra          │
│ • Editor de slides   │   mDNS discovery   │ • Stage display      │
│ • Transmissão HTML   │ ←──────░░░░────────│ • Trocar de slide    │
│                      │                    │ • Cronômetro         │
│ Servidor HTTP:7070   │   DLNA/SSDP        │                      │
│ Cast Sender          │ ──────→░░░░░       │ Cast SDK             │
└──────────────────────┘            │       └──────────────────────┘
                                   │
                    ┌──────────────▼──────────────┐
                    │ SINK — Receptores            │
                    │                              │
                    │  ┌─────────────────────────┐ │
                    │  │ TV Samsung (DLNA)       │ │
                    │  │ TV LG (DLNA/AirPlay)    │ │
                    │  │ TV Philips (DLNA)       │ │
                    │  │ Chromecast (Cast)       │ │
                    │  │ Android TV (Browser/Cast)│ │
                    │  │ TV "burra" + Chromecast │ │
                    │  │ Browser da TV (HTTP)    │ │
                    │  └─────────────────────────┘ │
                    └──────────────────────────────┘
```

---

## Protocolos de Comunicação

### 1. WebSocket / SSE — Desktop ↔ Celular (tempo real)
- Desktop roda servidor HTTP (porta 7070) com WebSocket
- Celular Flutter conecta como cliente WebSocket
- Mensagens JSON: `{ type: "slide_change", data: { title, lyrics, next } }`
- Celular envia comandos: `{ type: "command", action: "next_slide" }`
- Baseado no que o Juan já implementou (events.js + SSE)

### 2. mDNS (Bonjour/Zeroconf) — Descoberta automática
- Desktop anuncia serviço `_louvorja._tcp` na rede via mDNS
- Celular escaneia e encontra o desktop automaticamente (sem digitar IP)
- Bibliotecas: `bonjour-service` (Node/Electron), `flutter_mdns_plugin` (Flutter)
- Fallback: input manual de IP se mDNS não funcionar (alguns routers bloqueiam)

### 3. DLNA / UPnP — Desktop → TV (sem app na TV)
- Desktop usa `node-upnp-mediarenderer-client` para encontrar TVs DLNA na rede
- Envia a projeção como stream de imagem/video simples
- TVs Samsung, LG, Philips, Sony suportam DLNA nativamente (sem instalar nada)
- Limitação: DLNA envia media (video/imagem), não HTML. Solução: desktop renderiza a projeção como imagem JPEG e envia como slideshow DLNA

### 4. Google Cast SDK — Celular → Chromecast/TV
- Celular Flutter usa `flutter_chrome_cast` ou Cast SDK nativo
- Envia a projeção (renderizada em Flutter) para Chromecast na TV
- Funciona em qualquer TV com HDMI + Chromecast (R$150)
- Cast Custom Receiver: página HTML servida pelo desktop que o Chromecast carrega

### 5. HTTP Browser na TV — Fallback universal
- Desktop serve `http://IP:7070/mirror` (já existe no Juan)
- TV inteligente abre no browser nativo
- Sem instalar nada, sem comprar nada
- Atualização via SSE (tempo real)

---

## Funcionalidades por Dispositivo

### Desktop Electron (SOURCE — fonte de tudo)

| Feature | Issue | Status |
|---------|-------|--------|
| Servidor HTTP + WebSocket na porta 7070 | #27 | SPEC pronta |
| mDNS announcement (descoberta automática) | NOVO | Esta SPEC |
| DLNA sender (enviar projeção pra TV) | NOVO | Esta SPEC |
| Cast Custom Receiver (página HTML pro Chromecast) | NOVO | Esta SPEC |
| Mirror endpoint HTTP (browser na TV) | #27 | Já no Juan |
| Transmissão HTML (OBS/vMix) | #29 | SPEC pronta |
| SSE (Server-Sent Events) | #36 | SPEC pronta |
| Stage display (janela local) | #28 | SPEC pronta |
| 3 modos player | #31 | SPEC pronta |

### Celular Flutter (CONTROLE + DISPLAY)

| Feature | Origem | Como |
|---------|--------|------|
| Controle remoto do player | Delphi/Juan | WebSocket client → Desktop |
| Stage display remoto | Delphi #28 | WebSocket → renderiza no Flutter |
| Busca de hinos | Delphi/Juan | Catálogo local SQLite (sqflite) |
| Letra offline | SPEC Flutter | Download + cache |
| Liturgia do dia | SPEC Flutter | API ou SQLite local |
| Cronômetro | SPEC Flutter | Timer nativo |
| Cast pra TV | NOVO | flutter_chrome_cast |
| mDNS discovery | NOVO | flutter_mdns_plugin |
| Favoritos | #33 | SQLite local |
| Histórico | #42 | SQLite local |
| Coletâneas pessoais | #41 | SQLite local |
| Telemetria | SPEC telemetry | POST /api/telemetry |
| i18n PT/EN/ES | #57/#75 | flutter_localizations |
| Contador crescente | #44 | UI nativa |
| Escala de músicos | SPEC Flutter | API ou local |

### TV (SINK — receptores)

| Método | Precisa de hardware? | Precisa de app na TV? | Latência |
|--------|---------------------|----------------------|----------|
| DLNA | Não (TV inteligente) | Não (nativo) | 500ms-2s |
| Chromecast | Sim (R$150) | Não | 200-500ms |
| Browser HTTP | Não (TV inteligente) | Não (browser nativo) | 1-3s (polling) |
| Android TV app | Não (Android TV) | Sim (APK Flutter) | 100-300ms |
| AirPlay | Não (LG/Apple TV) | Não (nativo) | 200ms |

---

## RFs — Requisitos Funcionais Multi-Device

### RF-MD-01: Descoberta automática (mDNS)
**User Story:** Como operador, quero que o celular encontre o desktop automaticamente, sem digitar IP.
**Critérios de Aceite:**
- WHEN o desktop inicia THE SYSTEM SHALL anunciar `_louvorja._tcp` via mDNS na porta 7070
- WHEN o celular Flutter abre THE SYSTEM SHALL escanear mDNS e listar desktops encontrados
- WHEN múltiplos desktops existem THE SYSTEM SHALL listar todos com nome da máquina
- WHEN mDNS falha (router bloqueia) THE SYSTEM SHALL oferecer input manual de IP:porta
- THE SYSTEM SHALL cache do último desktop conectado para reconexão rápida

### RF-MD-02: Controle remoto via WebSocket
**User Story:** Como operador, quero controlar o desktop do celular em tempo real.
**Critérios de Aceite:**
- WHEN celular conecta THE SYSTEM SHALL estabelecer WebSocket com o desktop
- WHEN operador toca "próximo" THE SYSTEM SHALL enviar comando em <100ms
- WHEN conexão cai THE SYSTEM SHALL tentar reconectar automaticamente (3 tentativas)
- WHEN reconecta THE SYSTEM SHALL sincronizar estado atual (slide, música, posição)
- THE SYSTEM SHALL funcionar com token de autenticação (6 chars)

## RF-MD-03: Palco digital na TV (view independente do operador)
**User Story:** Como congregação, quero ver na TV só o que importa (letra, versículo, slide), sem ver a interface do operador (busca, liturgia, timers).

**PRINCÍPIO FUNDAMENTAL — NÃO É SCREEN MIRROR:**
A TV mostra uma VIEW INDEPENDENTE da tela do operador. O operador tem lista de hinos, busca, liturgia completa, timers, próximos itens. A TV tem APENAS o slide ativo (letra/versículo/imagem). Igual ao `fmMonitorPainelDinamico` e `fmMusicaRetorno` do Delphi.

**Critérios de Aceite:**
- THE SYSTEM SHALL enviar para a TV apenas o conteúdo do slide ativo (letra, versículo, imagem de fundo)
- THE SYSTEM SHALL NUNCA enviar a interface do operador (busca, lista, liturgia, timers) para a TV
- THE SYSTEM SHALL aplicar overlay (logo da igreja, #37) no conteúdo da TV
- THE SYSTEM SHALL aplicar background personalizado (#23) no conteúdo da TV
- WHEN operador busca um hino THE SYSTEM SHALL NÃO mostrar a busca na TV (só quando o hino for selecionado)
- WHEN operador troca de slide THE SYSTEM SHALL atualizar a TV em <500ms
- THE SYSTEM SHALL suportar fundo personalizado (papel de parede da igreja, #23) ou fundo preto real (#000, #51) com fade-in/out

### RF-MD-04: Cast para Chromecast/TV
**User Story:** Como operador, quero enviar a projeção para a TV da igreja sem cabos.
**Critérios de Aceite:**
- WHEN operador toca "Enviar pra TV" THE SYSTEM SHALL escanear dispositivos Cast na rede
- WHEN operador seleciona Chromecast THE SYSTEM SHALL abrir Custom Receiver na TV
- THE SYSTEM SHALL enviar slides via Cast Message Channel (não video stream)
- WHEN slide muda no desktop THE SYSTEM SHALL atualizar a TV em <500ms
- WHEN conexão com Cast cai THE SYSTEM SHALL notificar e tentar reconectar

### RF-MD-05: DLNA sender (TVs sem Chromecast)
**User Story:** Como operador, quero enviar a projeção para a TV Samsung/LG da igreja sem hardware extra.
**Critérios de Aceite:**
- WHEN operador toca "Enviar pra TV" THE SYSTEM SHALL escanear dispositivos DLNA (SSDP)
- WHEN operador seleciona TV DLNA THE SYSTEM SHALL renderizar slide como imagem e enviar
- THE SYSTEM SHALL atualizar a TV quando slide muda (render → JPEG → DLNA push)
- Limitação: DLNA tem latência maior (500ms-2s) — informar o usuário

### RF-MD-06: Fallback browser na TV
**User Story:** Como operador, quero que a TV da igreja mostre a projeção abrindo uma URL no browser.
**Critérios de Aceite:**
- Desktop serve `http://IP:7070/mirror` (página com projeção + SSE)
- THE SYSTEM SHALL mostrar QR code na tela do desktop pra fácil acesso
- A página usa background #000, fonte grande, SSE para atualização
- Funciona em qualquer TV com browser (Samsung, LG, Android TV)

### RF-MD-07: Renderização de slides no Flutter (Cast + Stage Display)
**User Story:** Como sistema, quero renderizar slides nativamente no Flutter para Cast e stage display.
**Critérios de Aceite:**
- THE SYSTEM SHALL renderizar letra de hino com formatação (negrito, quebra de linha)
- THE SYSTEM SHALL renderizar versículo bíblico com referência
- THE SYSTEM SHALL suportar imagem de fundo (capa do hino ou fundo custom)
- THE SYSTEM SHALL suportar tema (claro/escuro, cor de destaque)
- THE SYSTEM SHALL aplicar overlay (logo da igreja) se configurado (#37)

### RF-MD-08: Stage Display no celular do músico (view do músico)
**User Story:** Como músico no palco, quero ver no celular o slide atual E o próximo, sem ver a interface do operador.

**DIFERENÇA DO PALCO NA TV (RF-MD-03):** O stage display é pra o músico, não pra congregação. Mostra o slide atual grande + o próximo slide menor (pra se preparar). Já tem fundo escuro (palco tem pouca luz). Igual ao `fmMusicaRetorno` do Delphi.

**Critérios de Aceite:**
- WHEN stage display ativado no celular THE SYSTEM SHALL mostrar slide atual (grande) + próximo (menor)
- THE SYSTEM SHALL atualizar em tempo real via WebSocket (<200ms)
- THE SYSTEM SHALL usar tema escuro (palco tem pouca luz)
- THE SYSTEM SHALL manter tela acesa (wakelock) enquanto stage display ativo
- THE SYSTEM SHALL NUNCA mostrar interface do operador (busca, lista, timer do operador)
- THE SYSTEM SHALL mostrar cronômetro/contador do item atual (diferente do palco na TV)

---

## Fluxo de Experiência do Usuário

### Cenário 1: Igreja com desktop + celular + TV com Chromecast
```
1. Operador liga o desktop → app abre, servidor HTTP na 7070, anuncia mDNS
2. Operador abre o app Flutter no celular → encontra desktop automaticamente
3. Operador seleciona "Conectar" → WebSocket estabelecido
4. Operador toca "Enviar pra TV" → escaneia Cast → seleciona Chromecast
5. Projeção aparece na TV via Cast Custom Receiver
6. Operador controla tudo pelo celular (próximo, anterior, buscar hino)
7. Músico abre o app no celular dele → "Stage Display" → vê projeção + próximo
```

### Cenário 2: Igreja com desktop + TV Samsung (sem Chromecast)
```
1. Desktop liga, anuncia DLNA na rede
2. Operador toca "Enviar pra TV" → encontra TV Samsung via SSDP
3. Desktop renderiza slides como JPEG e envia via DLNA
4. Latência maior (~1s) mas funcional sem comprar nada
```

### Cenário 3: Igreja pequena sem desktop (só celular + TV)
```
1. Operador abre app Flutter → modo "Autônomo"
2. Busca hinos, monta liturgia no próprio celular
3. "Enviar pra TV" → Cast direto do celular (sem desktop intermediário)
4. Limitação: sem player de áudio integrado, sem projeção multi-tela
```

### Cenário 4: Igreja com cabos (HDMI) — como hoje
```
1. Desktop conectado à TV via cabo HDMI (sem mudança)
2. Celular opcional como controle remoto
3. Tudo funciona como hoje, controle remoto é bônus
```

---

## Stack Multi-Device

### Desktop (Electron) — Adições
| Componente | Biblioteca | Função |
|-----------|-----------|--------|
| mDNS | `bonjour-service` | Anunciar serviço na rede |
| DLNA | `node-upnp-mediarenderer-client` | Encontrar e enviar pra TVs |
| SSDP | `node-ssdp` | Descoberta de dispositivos DLNA |
| Cast Receiver | HTML servido na porta 7070 | Receiver pro Chromecast carregar |
| WebSocket | `ws` ou Express + ws | Comunicação bidirecional com celular |

### Flutter (Mobile) — Adições
| Componente | Biblioteca | Função |
|-----------|-----------|--------|
| mDNS | `flutter_mdns_plugin` ou `bonsoir` | Encontrar desktop na rede |
| WebSocket | `web_socket_channel` | Cliente WebSocket pro desktop |
| Cast | `flutter_chrome_cast` ou platform channels | Enviar pra Chromecast |
| DLNA | `flutter_dlna` (pesquisar/criar) | Descobrir TVs DLNA |
| Wakelock | `wakelock_plus` | Manter tela acesa (stage display) |
| SQLite | `sqflite` + `drift` (ORM) | Catálogo offline |
| Telemetria | `http` package | POST /api/telemetry |

---

## Fora de Escopo
- App nativo pra Samsung Tizen (linguagem proprietária, nicho pequeno)
- App nativo pra LG webOS (mesmo motivo)
- App nativo pra Roku (BrightScript)
- Streaming de câmera do celular (YouTube app já faz)
- Screen mirror de video pesado (WebRTC) — foco em slides/texto, não video
- Sincronização de áudio entre desktop e celular (latência de rede varia)

# PIANO LouvorJA — Solução dos 3 Bugs de Projeção

**De:** Rafael (com análise técnica do SquadOps)
**Para:** Ezequias Fonseca
**Data:** 01/Agosto/2026

---

Ezequias, analyzei a fundo o código do Electron (`web-projection.mjs`, `main.mjs`, `preload.mjs`, `window-state.mjs`, `base.css`, `index.html`, e toda a cadeia de stores/services). Encontrei a **causa raiz exata** dos 3 bugs que você reportou e tenho a solução proposta para cada um.

---

## Bug 1 — Scrollbars aparecendo em projetores 1024×768

### O que está acontecendo

Quando você conecta um projetor antigo (1024×768, 4:3), o Windows frequentemente aplica **DPI scaling de 125% ou 150%** (scaleFactor 1.25 ou 1.5). O Electron respeita esse scaleFactor, mas o código **não compensa isso em nenhum lugar**.

Resultado: o Chromium renderiza o conteúdo em CSS pixels maiores que o viewport físico da janela fullscreen → surgem scrollbars.

Confirmei: não existe **nenhuma chamada** a `webContents.setZoomFactor()` no projeto inteiro. O scaleFactor é completamente ignorado.

Por isso o zoom 75% resolve temporariamente — você está compensando manualmente o DPI que o código deveria tratar.

### Causa raiz (3 fatores)

1. **`index.html`** — viewport meta sem travar escala do usuário:
   ```html
   <!-- Atual: -->
   <meta name="viewport" content="width=device-width, initial-scale=1.0">
   <!-- Deveria ser: -->
   <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
   ```

2. **`web-projection.mjs`** — ao criar janelas de projeção (mirror, image, pdf, etc.), faz `win.setBounds(display.bounds)` mas **não aplica** `setZoomFactor` para compensar o scaleFactor do display

3. **`base.css`** — usa `scrollbar-width: thin` (barra fina) mas **não esconde** as scrollbars nas telas de projeção

### Solução proposta (3 mudanças)

**Mudança A — `index.html`: travar escala do usuário**
```html
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
```

**Mudança B — `web-projection.mjs`: compensar scaleFactor**

Em cada função `createMirrorWindow`, `createImageProjectionWindow`, `createPdfProjectionWindow`, etc., dentro do `win.once('ready-to-show', ...)`:

```javascript
win.once('ready-to-show', () => {
  win.setBounds(display.bounds)
  win.setFullScreen(true)

  // CORRIGE DPI: normaliza zoom para scaleFactor do display
  const factor = display.scaleFactor || 1
  if (factor !== 1) {
    win.webContents.setZoomFactor(1 / factor)
  }

  // ... resto do código existente
})
```

**Mudança C — `web-projection.mjs`: esconder scrollbars via CSS injection**

Após criar cada janela de projeção:

```javascript
win.webContents.insertCSS(`
  html, body, #app {
    overflow: hidden !important;
    scrollbar-width: none !important;
  }
  ::-webkit-scrollbar {
    display: none !important;
  }
`)
```

**Tempo estimado: ~2h**

---

## Bug 2 — Multi-tela perde a posição do monitor selecionado

### O que está acontecendo

Quando você seleciona qual monitor deve receber a projeção, essa escolha **não persiste corretamente entre reinicializações do sistema**.

### Causa raiz

1. **`display.id` é instável no Windows** — o Electron usa o ID interno do SO para cada display. No Windows, esse ID **muda entre reinicializações** (especialmente com adaptadores HDMI/VGA/Docking USB). A preferência salva aponta para um ID que não existe mais.

2. **Não há fallback** — quando o ID salvo não é encontrado, não há mecanismo de matching alternativo. O sistema simplesmente não encontra o monitor.

3. **Sem persistência de estado da projeção** — `window-state.mjs` só salva a janela principal (posição/tamanho/ maximizada). As janelas de projeção são criadas do zero toda vez, sem saber se havia projeção ativa ao fechar o app.

### Solução proposta

**Mudança A — Matching por bounds relativos (não por ID)**

Quando o ID salvo não for encontrado, fazer fallback usando a **posição relativa do monitor** em relação ao display primário:

```javascript
function findDisplayByPreferences(preferences) {
  const displays = screen.getAllDisplays()

  // 1. Tentar por ID salvo (rápido — funciona na maioria dos casos)
  const byId = displays.find(d => d.id === preferences.targetDisplayId)
  if (byId) return byId

  // 2. Fallback: matching por posição relativa
  //    (se o monitor estava à direita do primário, procurar à direita)
  if (preferences.savedBounds) {
    const primary = screen.getPrimaryDisplay()
    const savedRelX = preferences.savedBounds.x - primary.bounds.x

    const byPosition = displays.find(d => {
      const dRelX = d.bounds.x - primary.bounds.x
      // Tolerância de 50px — monitores raramente mudam de posição exata
      return Math.abs(dRelX - savedRelX) < 50
    })
    if (byPosition) return byPosition
  }

  // 3. Último recurso: primeiro display estendido (não-primário)
  const extended = displays.filter(d => d.id !== screen.getPrimaryDisplay().id)
  return extended[0] || displays[0]
}
```

**Mudança B — Salvar bounds relativos nas preferências**

Em `projection-preferences.ts`, além do `targetDisplayId`, salvar também:

```typescript
interface ProjectionPreferences {
  targetDisplayId: number
  targetDisplayBounds: { x: number; y: number; width: number; height: number }  // NOVO
  openFullscreenOnPrimary: boolean
  lastProjectionActive: boolean   // NOVO: projeção estava ativa ao fechar?
  lastProjectionMode: string      // NOVO: qual módulo estava projetando?
}
```

**Mudança C — Re-binding na inicialização**

Após `app.ready`, comparar os displays atuais com as preferências salvas e atualizar o ID se necessário:

```javascript
// Em main.mjs, após a janela principal estar pronta:
const prefs = loadProjectionPreferences()
if (prefs.targetDisplayId) {
  const display = findDisplayByPreferences(prefs)
  if (display.id !== prefs.targetDisplayId) {
    // ID mudou — atualizar preferência com o novo ID
    saveProjectionPreferences({
      ...prefs,
      targetDisplayId: display.id,
      targetDisplayBounds: display.bounds,
    })
  }
}
```

**Tempo estimado: ~4h**

---

## Bug 3 — Módulo de mídia: slide às vezes não atualiza

### O que está acontecendo

Na projeção de mídia (imagens/vídeo/PDF), ao trocar de slide, **a tela do projetor às vezes não atualiza** — fica congelada no slide anterior.

### Causa raiz

Tem um comentário no próprio código (`web-projection.mjs`, linha 1074):

```javascript
/**
 * Projeção de imagens: carrega a mesma galeria nas telas (sem captura).
 * Captura de tela falha com conteúdo estático — o slide às vezes não atualiza.
 */
```

O modo imagem já migrou para janela direta (em vez de captura), mas o modo vídeo ainda depende de **`webContents.capturePage()`** em um loop periódico (mirror). Em PCs com GPU fraca ou projetores conectados via HDMI em adaptadores USB, a captura:

- Trava quando o conteúdo não muda visualmente (Chromium otimiza não repintando)
- Pula frames quando há mudanças rápidas
- Tem latência variável dependendo da carga do sistema

### Solução proposta (2 abordagens)

**Opção A — Forçar repaint ao trocar de slide (simples, ~1h)**

Adicionar uma função que invalida o webContents e força o Chromium a repintar:

```javascript
function forceRepaint(win) {
  if (!win || win.isDestroyed()) return

  // Método 1: invalidar cache de paint
  win.webContents.invalidate()

  // Método 2: piscar background para forçar redraw (1 frame)
  win.webContents.setBackgroundColor('#000001')
  setTimeout(() => {
    if (!win.isDestroyed()) {
      win.webContents.setBackgroundColor('#000000')
    }
  }, 16)  // ~1 frame a 60fps
}
```

Chamar `forceRepaint(sourceWindow)` toda vez que o operador trocar de slide.

**Opção B — Substituir capturePage por painting contínuo (robusto, ~2h)**

Usar a API de painting contínuo do Electron (v30+):

```javascript
function startMirrorCapture(sourceWin, mirrorWins) {
  // Desabilitar throttling de background
  sourceWin.webContents.setBackgroundThrottling(false)

  // Usar evento 'paint' em vez de captura periódica
  sourceWin.webContents.on('paint', (event, dirty, image) => {
    for (const mirror of mirrorWins) {
      if (!mirror.isDestroyed()) {
        // Enviar frame diretamente para o mirror
        mirror.webContents.send('mirror-frame', image.toDataURL())
      }
    }
  })
}
```

**Recomendação:** começar pela Opção A (mais rápida de implementar, resolve na maioria dos casos). Se persistir, migrar para Opção B.

**Tempo estimado: ~3h (A + B)**

---

## Resumo

| Bug | Causa Raiz | Solução | Tempo |
|-----|-----------|---------|-------|
| **1. Scrollbars 1024×768** | scaleFactor do display não é compensado (zero `setZoomFactor` no código) | `setZoomFactor(1/scaleFactor)` + esconder scrollbars via CSS + fix viewport meta | **~2h** |
| **2. Multi-tela perde posição** | `display.id` muda entre reinícios no Windows; sem fallback de matching | Matching por bounds relativos + persistir estado da projeção | **~4h** |
| **3. Mídia não atualiza slide** | `capturePage` trava em conteúdo estático (Chromium não repinta) | `webContents.invalidate()` forçando repaint + eventual migração para painting contínuo | **~3h** |

**Total estimado: ~9h de implementação.**

Todos os fixes são no Electron atual — **não exige mudança de arquitetura**. São compatíveis com Windows, macOS e Linux.

---

Se quiser, posso implementar os 3 fixes no código e te mandar um PR. É só falar.

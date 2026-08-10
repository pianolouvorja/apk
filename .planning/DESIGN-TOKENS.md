# DESIGN-TOKENS.md — LouvorJA PIANO Flutter

> **Source of truth:** Design system existente em `pianolouvorja/app` e `pianolouvorja/web`.
> Este arquivo **NÃO inventa** tokens — apenas traduz os tokens TypeScript/CSS do
> design system Vue para equivalentes em Flutter (Material Design 3 + `ThemeData`).
>
> **Repositórios de referência:**
> - App: https://github.com/pianolouvorja/app (`src/design-system/`)
> - Web: https://github.com/pianolouvorja/web (`src/design-system/`)
>
> Última sync: 2026-08-01

---

## 1. Tipografia

### Família tipográfica
```
Plus Jakarta Sans (Variable)
Fallbacks: system-ui, -apple-system, Segoe UI, sans-serif
```

**Flutter:**
```yaml
# pubspec.yaml
flutter:
  fonts:
    - family: PlusJakartaSans
      fonts:
        - asset: assets/fonts/PlusJakartaSans-Variable.ttf
```

### Tamanhos (extraídos dos componentes)
| Token web | px | Uso | Flutter `TextStyle.fontSize` |
|-----------|----|----|------------------------------|
| `0.625rem` | 10 | Labels de badge, metadata | `10.0` |
| `9px` | 9 | Dock icon label (inactive) | `9.0` |
| `0.75rem` | 12 | Dock icon label, caption | `12.0` |
| `0.875rem` | 14 | Body text, list items | `14.0` |
| `1rem` | 16 | Body, subtitles | `16.0` |
| `1.35rem` | ~22 | Card titles | `22.0` |
| `24px` | 24 | Dock icons (active) | `24.0` |
| `28px` | 28 | Dock icons web (active) | — |

### Pesos
| Token web | Flutter `FontWeight` |
|-----------|---------------------|
| `400` (normal) | `w400` |
| `500` (medium) | `w500` |
| `700` (bold) | `w700` |

---

## 2. Paleta de Cores

### Cores de marca (fixas)
| Token | Hex | Uso |
|-------|-----|-----|
| `primary` | `#2196F3` | Azul de ação / destaque |
| `primarySoft` | `#9ECAFF` | Texto de marca em dark mode |
| `secondary` | `#78D6D2` | Verde-água secundário |
| `brandBlueAlt` | `#0097D7` | Variante de azul |
| `brandYellow` | `#F8C800` | Amarelo do logo oficial |

### Dark — "Ethereal Lumens" (tema padrão)
| Token CSS | Hex | Flutter (`ColorScheme` dark) |
|-----------|-----|------------------------------|
| `--ds-color-background` | `#131313` | `surface` |
| `--ds-color-surface` | `#131313` | `surface` |
| `--ds-color-surface-elevated` | `#1E1E1E` | `surfaceContainerHighest` |
| `--ds-color-surface-card` | `#242424` | `surfaceContainer` |
| `--ds-color-surface-container` | `#201F1F` | `surfaceContainerLow` |
| `--ds-color-surface-container-high` | `#2A2A2A` | `surfaceContainerHigh` |
| `--ds-color-surface-variant` | `#353534` | `surfaceVariant` |
| `--ds-color-on-surface` | `#E5E2E1` | `onSurface` |
| `--ds-color-on-surface-variant` | `#BFC7D4` | `onSurfaceVariant` |
| `--ds-color-on-primary` | `#003258` | `onPrimary` |
| `--ds-color-outline` | `rgba(255,255,255,0.05)` | `outline` (com alpha) |
| `--ds-color-outline-strong` | `rgba(255,255,255,0.10)` | `outlineVariant` |

### Light — "Luminous Clarity"
| Token CSS | Hex | Flutter (`ColorScheme` light) |
|-----------|-----|-------------------------------|
| `--ds-color-background` | `#F8F9FF` | `surface` |
| `--ds-color-surface` | `#F8F9FF` | `surface` |
| `--ds-color-surface-elevated` | `#FFFFFF` | `surfaceContainerHighest` |
| `--ds-color-surface-card` | `#FFFFFF` | `surfaceContainer` |
| `--ds-color-surface-container` | `#EEEEEF` | `surfaceContainerLow` |
| `--ds-color-surface-container-high` | `#E8E8EA` | `surfaceContainerHigh` |
| `--ds-color-surface-variant` | `#DFE3EB` | `surfaceVariant` |
| `--ds-color-on-surface` | `#191C20` | `onSurface` |
| `--ds-color-on-surface-variant` | `#43474E` | `onSurfaceVariant` |
| `--ds-color-on-primary` | `#FFFFFF` | `onPrimary` |
| `--ds-color-outline` | `rgba(0,0,0,0.06)` | `outline` |
| `--ds-color-outline-strong` | `rgba(0,0,0,0.10)` | `outlineVariant` |

---

## 3. Acentos de Cor (Runtime Override)

O usuário pode escolher o acento de cor na tela de Aparência. Default: **orange** (`#E0895A`).

| Key | Label | Primary | Soft |
|-----|-------|---------|------|
| `azure` | Azul | `#5B9BD5` | `#B4D4F0` |
| `sky` | Céu | `#5BA4C9` | `#B5D8E8` |
| `teal` | Verde-água | `#4DB6AC` | `#B2DFDB` |
| `emerald` | Verde | `#6BAA7A` | `#B8D9C0` |
| `apricot` | Âmbar | `#E0A84A` | `#F0D9A8` |
| `orange` | Laranja | `#E0895A` | `#F0C4A8` |
| `coral` | Coral | `#D4847A` | `#F0C0B8` |
| `rose` | Rosa | `#C97B8F` | `#E8C4CE` |
| `violet` | Violeta | `#8B7BB8` | `#CDC4E0` |
| `slate` | Ardósia | `#7A8FA3` | `#C5D0DA` |

**Flutter:** Implementar como seeds de `ColorScheme.fromSeed()` ou overrides manuais de `primary` / `primaryContainer` no `ThemeData`.

---

## 4. Espaçamento — Grade 8px

| Token | px | Flutter (`double`) |
|-------|----|--------------------|
| `spacing.0` | 0 | `0` |
| `spacing.1` | 4 | `4.0` |
| `spacing.2` | 8 | `8.0` |
| `spacing.3` | 12 | `12.0` |
| `spacing.4` | 16 | `16.0` |
| `spacing.5` | 20 | `20.0` |
| `spacing.6` | 24 | `24.0` |
| `spacing.8` | 32 | `32.0` |
| `spacing.10` | 40 | `40.0` |
| `spacing.12` | 48 | `48.0` |
| `marginPage` | 32 | `32.0` |
| `gutterGrid` | 24 | `24.0` |
| `paddingCard` | 20 | `20.0` |
| `bottomNavHeight` | 72 | `72.0` |

**Flutter:**
```dart
abstract final class AppSpacing {
  static const double s0 = 0;
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s8 = 32;
  static const double s10 = 40;
  static const double s12 = 48;
  static const double pageMargin = 32;
  static const double cardPadding = 20;
  static const double navBarHeight = 72;
}
```

---

## 5. Raios de Borda — Assimetria de Marca

> **Identidade visual única:** TL + BR arredondados; TR + BL retos (0).
> formato CSS: `top-left top-right bottom-right bottom-left`

| Token | CSS | Flutter (`BorderRadius`) |
|-------|-----|--------------------------|
| `sm` / `eight` | `8px 0 8px 0` | `BorderRadius.only(topLeft: 8, bottomRight: 8)` |
| `md` | `12px 0 12px 0` | `BorderRadius.only(topLeft: 12, bottomRight: 12)` |
| `lg` | `16px 0 16px 0` | `BorderRadius.only(topLeft: 16, bottomRight: 16)` |
| `xl` | `24px 0 24px 0` | `BorderRadius.only(topLeft: 24, bottomRight: 24)` |
| `full` | `9999px` | `BorderRadius.circular(9999)` ou `BorderRadius.circular(1000)` |

**Flutter:**
```dart
abstract final class AppRadius {
  static const BorderRadius sm = BorderRadius.only(
    topLeft: Radius.circular(8), bottomRight: Radius.circular(8),
  );
  static const BorderRadius md = BorderRadius.only(
    topLeft: Radius.circular(12), bottomRight: Radius.circular(12),
  );
  static const BorderRadius lg = BorderRadius.only(
    topLeft: Radius.circular(16), bottomRight: Radius.circular(16),
  );
  static const BorderRadius xl = BorderRadius.only(
    topLeft: Radius.circular(24), bottomRight: Radius.circular(24),
  );
  static const BorderRadius full = BorderRadius.circular(9999);
}
```

> **Atenção:** A assimetria TL+BR é a **assinatura visual** do projeto.
> Nunca usar `BorderRadius.circular()` simétrico em cards, botões ou containers
> principais. Apenas `full` é circular (para avatars, chips, FAB).

---

## 6. Glass Morphism (Backdrop Blur)

O efeito de vidro é controlável pelo usuário via slider de intensidade (0–100). Default: **60**.

| Token | Blur px | Flutter (`sigmaX/Y` em `BackdropFilter`) |
|-------|---------|------------------------------------------|
| `none` | 0 | `0` |
| `low` | 8 | `8` |
| `medium` | 16 | `16` |
| `default` | 16 | `16` |
| `high` | 28 | `28` |
| `glow` | 120 | `120` |

### Fórmulas do slider (replicar em Flutter)
```
blurPx = 4 + (intensity / 100) * 24     → range: 4–28px
fillAlpha = 42 + (intensity / 100) * 40 → range: 42%–82%
```

**Flutter:**
```dart
// ImageFilter.blur(sigmaX: blurPx, sigmaY: blurPx)
// Container color: surface.withOpacity(fillAlpha / 100)
```

---

## 7. Z-Index (Elevação)

| Token web | z | Flutter (`zIndex` → `elevation` aprox) |
|-----------|---|----------------------------------------|
| `base` | 0 | `0` |
| `content` | 10 | `1` |
| `header` | 40 | `4` |
| `dock` | 50 | `8` (AppBar / BottomNav) |
| `modal` | 60 | `16` (Dialog) |
| `toast` | 70 | `24` (SnackBar) |

---

## 8. Breakpoints (Web → Flutter responsivo)

Para tablets/large screens no Flutter:

| Token web | px | Flutter (`Breakpoint`) |
|-----------|----|------------------------|
| `sm` | 600 | Phone portrait |
| `md` | 960 | Tablet / phone landscape |
| `lg` | 1280 | Desktop / tablet landscape |
| `xl` | 1920 | Wide desktop |

---

## 9. Motion / Animações

### Perfis de interação (escolhidos pelo usuário)
Default: **soft**

| Perfil | Duration | Easing | Flutter (`Duration` + `Curve`) |
|--------|----------|--------|--------------------------------|
| `dynamic` | 280ms | `cubic-bezier(0.34, 1.56, 0.64, 1)` | `Duration(milliseconds: 280)` + `Curves.easeOutBack` |
| `soft` | 450ms | `cubic-bezier(0.4, 0, 0.2, 1)` | `Duration(milliseconds: 450)` + `Curves.easeInOutCubic` |
| `mist` | 520ms | `cubic-bezier(0.22, 1, 0.36, 1)` | `Duration(milliseconds: 520)` + `Curves.easeOutQuart` |

### Dock animation (macOS-style)
| Token | Valor | Flutter |
|-------|-------|---------|
| `hoverScale` | 1.25 | `scale: 1.25` (TapTarget) |
| `hoverLift` | -4px | `transform: Translate(0, -4)` |
| `duration` | 300ms | `Duration(milliseconds: 300)` |
| `easing` | `cubic-bezier(0.22, 1, 0.36, 1)` | `Curves.easeOutQuart` |

### Theme transition
| Token | Valor | Flutter |
|-------|-------|---------|
| `duration` | 280ms | `Duration(milliseconds: 280)` |
| `easing` | `ease` | `Curves.ease` |

---

## 10. Scrollbar

Estilo neutro fixo (não varia com tema):
| Token | Valor |
|-------|-------|
| Largura | 6px |
| Track bg | `#282828` |
| Thumb bg | `#7A7A7A` |
| Thumb hover | `#929292` |
| Raio | `9999px` |

**Flutter:** `ScrollbarThemeData` com `thickness: 6`, `radius: Radius.circular(9999)`.

---

## 11. Componentes do Design System → Flutter Equivalents

| Componente Vue | Flutter Widget |
|----------------|----------------|
| `GlassCard` | `ClipRRect` + `BackdropFilter` + `Container` |
| `BlurContainer` | `BackdropFilter` wrapper |
| `GradientBackground` | `Container` com `LinearGradient` |
| `ProjectionBackground` | `Container` com gradiano customizado |
| `MediaCollectionList` | `ListView` + `ListTile` custom |
| `DockFooter` | `BottomNavigationBar` ou `NavigationBar` (M3) |
| `BottomNavigation` | `NavigationBar` (Material 3) |

---

## 12. Mapeamento Material Design 3

O Flutter usa Material Design 3 (`useMaterial3: true` no `ThemeData`).
O mapeamento de tokens do design system para `ColorScheme` do M3:

```dart
ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme(
    brightness: Brightness.dark,  // ou .light
    primary: Color(0xFFE0895A),    // accent override ou #2196F3
    onPrimary: Color(0xFF003258),  // dark mode
    secondary: Color(0xFF78D6D2),
    surface: Color(0xFF131313),
    onSurface: Color(0xFFE5E2E1),
    surfaceContainerHighest: Color(0xFF1E1E1E),
    surfaceContainer: Color(0xFF242424),
    surfaceVariant: Color(0xFF353534),
    onSurfaceVariant: Color(0xFFBFC7D4),
    outline: Color(0x0DFFFFFF),       // rgba(255,255,255,0.05)
    outlineVariant: Color(0x1AFFFFFF), // rgba(255,255,255,0.10)
  ),
)
```

---

## Change Log

| Data | Mudança |
|------|---------|
| 2026-08-01 | Extração inicial dos tokens de `pianolouvorja/app` + `/web` |

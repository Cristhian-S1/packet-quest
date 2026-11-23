# 09 · Arte y audio

## Dirección de arte

- **Estilo:** pixel art retro-techno con neón. Fondos oscuros, elementos interactivos brillantes.
- **Identidad propia:** se evita la estética de dibujos animados de los años 30. La referencia
  son las placas base, los diagramas de red y los terminales con fósforo verde.
- **Legibilidad por color:**

| Rol | Color | Hex |
|---|---|---|
| Fondo (lejano) | Azul noche | `#070B17` |
| Fondo (cercano) | Placa verde oscura | `#0E2A22` |
| Plataformas | Chip gris azulado | `#2D3A52` con borde `#4F6A8F` |
| Byte y sus balas | Cian | `#3BE8FF` |
| Enemigos | Magenta | `#FF4FD8` |
| Balas enemigas | Rosa | `#FF3D8B` (las destructibles con borde blanco) |
| Peligro / aviso | Rojo | `#FF3355` |
| Interactuables | Verde | `#3BFF8A` |
| Coleccionables | Ámbar | `#FFB13B` |

- **Fondos en parallax** de 3 capas: cuadrícula lejana, cables y racks, primer plano con LEDs.
- **Tipografía:** fuente pixel monoespaciada (por ejemplo *m5x7* o *Press Start 2P*, ambas
  con licencia libre; verificar la licencia antes de incluirlas).

## Pipeline de arte

1. Prototipo: formas dibujadas por código (sin assets).
2. Arte final: Aseprite → exportar *sprite sheet* + JSON → `SpriteFrames` en Godot.
3. Tamaño base de tile: 16×16. Personajes en múltiplos de 8.
4. Los cambios de forma o de hitbox se hacen primero en los datos y luego en el arte.

## Audio

| Tipo | Dirección | Fuente |
|---|---|---|
| Música | Chiptune, 120–140 BPM. Un tema por mundo, un tema para menú y mapa, uno para créditos y un tema compartido por los jefes a 140 BPM. | Composiciones originales sintetizadas en `scripts/audio/` |
| SFX | Pitidos y efectos digitales para movimiento, armas, impactos, puzles e interfaz. | Síntesis en `scripts/audio/` |
| Avisos | Los jefes usan sonidos asociados a sus ataques. | Catálogo de efectos sintetizados |

- El juego genera el audio al ejecutarse. `game/tools/export_audio.gd` exporta muestras WAV para revisión.
- `game/assets/CREDITS.md` registra la procedencia de los recursos de audio.

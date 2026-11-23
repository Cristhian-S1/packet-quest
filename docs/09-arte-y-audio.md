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
| Música | Chiptune / synthwave. Un tema por mundo a 120–140 BPM y uno por jefe a 130–150 BPM. | Composición propia en `MusicCatalog` |
| SFX | Sonidos de módem, clics de teclado, pitidos de router y barridos digitales. | Síntesis procedural en `SfxCatalog` |
| Avisos | Sonido fijo por tipo de enemigo común y por tipo de ataque de jefe, acompañado de una señal con forma. | Síntesis procedural en `SfxCatalog` |

| Jefe | BPM | Motivo |
|---|---:|---|
| Router | 134 | Llamada sincopada que salta a la octava y contesta en descenso. |
| Reina Wi-Fi | 142 | Arpegio ascendente con una nota aguda sostenida. |
| Firewall | 146 | Golpes repetidos y un semitono de respuesta sobre un bajo insistente. |
| Troyano Real | 138 | Frases agrupadas en 3+3+2 corcheas. |
| Malwarex | 148 | Cuatro notas de apertura reaparecen en Remezcla, Cables vivos, Núcleo blindado y Borrado de datos. |

Cada tema se genera en segundo plano como PCM mono de 16 bits a 22 050 Hz. El juego reutiliza el
audio de la sesión y aplica un fundido de 280 ms entre pistas, también al cambiar de fase Malwarex.
La muestra de Malwarex encadena sus cuatro secciones completas en el orden del combate.
[Muestras WAV](audio/README.md)

Los avisos comunes usan un margen de 32 px del viewport y un máximo de dos voces. Los blindados
comparten el sonido de su tipo base y los avisos de jefe tienen prioridad en la mezcla.

Registrar la licencia de cada recurso externo en `assets/CREDITS.md`.

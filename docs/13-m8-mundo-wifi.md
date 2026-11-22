# 13 · M8 — Mundo 2 Wi-Fi (especificación de implementación)

Amplía `04-niveles.md` (Mundo 2), `05-enemigos-y-jefes.md` (Spyware, Reina Wi-Fi) y
`06-puzles.md` (Reparar cables). Donde esos documentos callan, **este documento decide**.
Beads: épica `pq-c78`.

## Reglas globales (heredadas, no cambiar)

- Godot 4.7.2, GDScript con tipos estáticos, dibujo procedural con `_draw()` y `PQStyle`.
- Todo ataque: aviso → activo → recuperación. Daño a Byte siempre 1 PV.
- Fases de jefe de 3 fases al **70 %** y **40 %**, pausa invulnerable de **2,4 s**, las balas
  enemigas desaparecen y aparece la tarjeta de fase (reutilizar lo del Router).
- Capas de colisión 1–8 como en `08-arquitectura-tecnica.md`. Proyectiles con pool.
- Pruebas headless: `bash tools/run-tests.sh --integration` debe quedar en verde.
- Textos de interfaz en español.

## 1 · GameState por mundos

Hoy `GameState` tiene `LEVEL` y `BOSS` fijos del Mundo 1. Cambiar a:

- `const WORLDS: Array[Dictionary] = [{"level": ".../World1Level1.tscn", "boss": ".../RouterBoss.tscn"}, {"level": ".../World2Level1.tscn", "boss": ".../WifiQueenBoss.tscn"}]`
- `var current_world: int = 1` (1-based). `start_run(world: int = 1)`; `retry()` y `enter_boss()` usan el mundo actual.
- `win()`: añade `"w<N>_boss"` a `completed_levels` y desbloquea `N + 1` en `unlocked_worlds` (sin duplicados), guarda.
- `static func is_world_playable(data: Dictionary, world: int) -> bool`: desbloqueado **y** con escenas (hoy 1 y 2).
- Mapa de la red: el botón "Entrar" usa el mundo seleccionado; se puede elegir entre los mundos jugables con izquierda/derecha. Los no implementados siguen como PRÓXIMAMENTE.

## 2 · Nivel 2-1 "Zona de cobertura" (`World2Level1.tscn`)

2880×360 px, suelo base en y = 304, paleta de exteriores (cielo azul oscuro, antenas, arcos de onda).

| Sección | Rango X | Contenido |
|---|---|---|
| S1 Ondas | 0–560 | 2 zonas de onda (`WaveZone`), letrero "Las ondas te empujan" |
| S2 Cobertura | 560–1280 | 1 router + 4 `CoveragePlatform` sobre un foso de 240 px (caer = muerte) |
| S3 Combate | 1280–1920 | 3 Spyware, 2 Pop-up, 1 Gusano, 1 zona de onda |
| Checkpoint | 1920 | |
| S4 Mezcla | 1920–2400 | 2 `CoveragePlatform` + 1 zona de onda + 1 Spyware |
| P Puzle | 2400–2880 | Checkpoint al entrar; `CablePuzzle`; compuerta en x = 2880 → jefe |

Núcleos de datos: 2 (`w2_core_a` visible en S2, `w2_core_b` oculto sobre la última plataforma de S4).

### WaveZone (`scripts/objects/wave_zone.gd`)

- `Area2D` rectangular (export `size`, por defecto 160×120) que empuja a Byte en horizontal.
- Export `push: float = 90.0` px/s (signo = dirección). Mientras está activa y Byte dentro: `player.external_push.x += push` (Byte suma `external_push` a su velocidad horizontal y lo pone a cero cada frame de física).
- Ciclo: activa 2,0 s → aviso 0,5 s (arcos parpadean) → inactiva 1,0 s → activa… Estado inicial configurable (`phase_offset`).
- Función pura testeable: `static func state_at(t: float) -> StringName` devuelve `&"active"`, `&"inactive"` o `&"warning"` (el aviso son los últimos 0,5 s de la inactividad, antes de volver a activarse).

### CoveragePlatform (`scripts/objects/coverage_platform.gd`)

- Plataforma de 64×12 px enlazada a un nodo `router` (`NodePath`). Sólida si la distancia de Byte al router es ≤ `range_px` (160 por defecto).
- Al salir del rango: aviso de 0,3 s (parpadeo) y después se apaga (colisión desactivada, alfa 0,35). Al volver al rango se enciende al instante.
- Función pura: `static func is_covered(player_pos: Vector2, router_pos: Vector2, range_px: float) -> bool`.

## 3 · Spyware (`scripts/enemies/spyware.gd`, `scenes/enemies/Spyware.tscn`)

Extiende `EnemyBase`. 4 PV, capa de enemigo, entra en el grupo `homing_target` **solo al revelarse**.

Estados: `DISGUISED → TELEGRAPH → JUMP → RECOVER → TELEGRAPH…`

- `DISGUISED`: se dibuja como un `DataCore` (mismo color y forma). Inmune a las balas (no tiene hurtbox activa) y no daña.
- Cuando Byte está a < **64 px**: `TELEGRAPH` 0,4 s (parpadeo glitch magenta), activa hurtbox.
- `JUMP`: velocidad (±180, −260) hacia Byte, gravedad 900, daño por contacto 1.
- `RECOVER`: 0,8 s quieto al aterrizar. Si Byte está a < 160 px vuelve a `TELEGRAPH`; si no, se queda en `RECOVER`.
- Al morir: 10 % de fragmento de caché (lo que ya haga `EnemyBase`).

## 4 · Puzle "Reparar cables" (`CableGrid` + `CablePuzzle.tscn`)

Lógica pura en `scripts/puzzles/cable_grid.gd` (`class_name CableGrid`, `RefCounted`), escena aparte.

- Rejilla de **4 columnas × 3 filas**, celdas de 32 px. Tipos: `STRAIGHT`, `ELBOW`, `TEE`, `EMPTY`.
- Lados como máscara de bits: N=1, E=2, S=4, W=8. Rotar 90° en sentido horario: `((m << 1) | (m >> 3)) & 15`. Aberturas base con rotación 0: STRAIGHT = N|S, ELBOW = N|E, TEE = N|E|S.
- La **antena** entra por el lado W de la celda (fila 1, col 0); el **router** sale por el lado E de la celda (fila 0, col 3).
- `connected_cells() -> Array[Vector2i]`: BFS desde la antena; dos celdas vecinas conectan solo si **ambas** tienen abierto el lado común.
- `is_solved() -> bool`: la celda del router está conectada y abre su lado E.
- Disposición fija (tipo por celda; fila 0 arriba):

```
fila 0:  TEE      ELBOW     STRAIGHT  STRAIGHT
fila 1:  STRAIGHT ELBOW     TEE       ELBOW
fila 2:  ELBOW    STRAIGHT  ELBOW     TEE
```

  Camino solución: (1,0) W–E → (1,1) W–N → (0,1) S–E → (0,2) W–E → (0,3) W–E. Las rotaciones iniciales deben dejar
  el puzle **sin resolver** y necesitar ≤ 10 disparos en total.
- Escena: cada celda es un `Area2D` en la capa de "interactuables por disparo" que gira 90° al recibir una bala de Byte (la bala se desactiva). Celdas conectadas en cian, el resto en gris. Nodo ↺ con `interact` que restaura las rotaciones iniciales. Al resolverse: emite `solved`, sonido de conexión, abre la `PacketDoor`, muestra el dato curioso: "Dato: los cables y repetidores llevan la señal donde el Wi-Fi no llega."

## 5 · Jefe Reina Wi-Fi (`scripts/bosses/wifi_queen_boss.gd`, `WifiQueenBoss.tscn`)

Arena fija de 640×360, suelo en y = 304. Flota; su cuerpo es una `Hurtbox` con `homing_target = true`. **90 PV**.
Antenas de teletransporte en (160, 112), (320, 88) y (480, 112); empieza en la central.

**Repetidores** en (120, 288) y (520, 288): con `interact` a ≤ 32 px crean una cúpula de radio 48 px durante **3 s**
(recarga 6 s, indicador visual). La cúpula destruye las balas enemigas que la tocan y protege de la Interferencia.

| | F1 "Señal estable" (100–70 %) | F2 "Itinerancia" (70–40 %) | F3 "Interferencia" (40–0 %) |
|---|---|---|---|
| Ataque A | **Ondas horizontales:** 2 de 3 carriles (y = 280, 232, 184) disparan una fila de 5 balas a 160 px/s desde un lado; rebotan **una vez** en la pared. Aviso 0,6 s: línea en el carril | Igual, desde ambos lados | — |
| Ataque B | **Ping descendente:** 5 balas caen desde arriba en x de Byte ± 0/32/64 a 180 px/s. Aviso 0,8 s: marcas en el techo | Igual | Igual cada 2 ataques |
| Ataque C | — | **Espiral:** 16 balas en 1,2 s, el emisor gira 30° por bala, 130 px/s. Aviso 0,5 s: la Reina gira | Espiral cada 2 ataques |
| Ataque D | — | **Teletransporte** a otra antena tras cada ataque. Aviso 0,4 s: silueta en el destino | — |
| Ataque E | — | — | **Interferencia:** la arena se divide en 4 franjas verticales de 160 px. Cada 4 s, 2 franjas no contiguas quedan "sin señal": aviso 1,0 s (rayado), activas 1,5 s, 1 PV al estar dentro (una vez por activación). Dentro de una cúpula no hacen daño |
| Patrón | A, B, A, B… recuperación 1,0 s | C, D, A, D, C, D, B, D… recuperación 0,8 s | E y entre activaciones B/C alternos, recuperación 0,8 s |

Función pura testeable: `static func phase_for(hp_ratio: float) -> int` (1, 2 o 3) y `static func interference_lanes(seed_index: int) -> Array[int]` (dos franjas no contiguas, determinista por índice).

Al vencerla: `GameState.win()` (desbloquea el Mundo 3 en el mapa, que seguirá como PRÓXIMAMENTE).

## 6 · Pruebas obligatorias (TDD: prueba roja → código → verde)

Nuevo `tests/test_world2.gd` registrado en `test_runner.gd` (con el patrón `finished` de los demás):

1. `CableGrid`: rotar 4 veces vuelve al origen; con las rotaciones iniciales `is_solved() == false`; con las rotaciones de la solución `== true`; dos celdas con lados no enfrentados no conectan; el total de disparos mínimo ≤ 10.
2. `WaveZone.state_at`: 0,0 → active, 1,9 → active, 2,2 → inactive, 2,6 → warning, 3,1 → active.
3. `CoveragePlatform.is_covered`: 159 px sí, 161 px no.
4. Spyware: instanciado con un Byte a 200 px sigue `DISGUISED`; a 50 px pasa a `TELEGRAPH`; tras 0,4 s está en `JUMP` con velocidad x hacia Byte.
5. Reina: `phase_for(1.0) == 1`, `phase_for(0.69) == 2`, `phase_for(0.39) == 3`; `interference_lanes` nunca devuelve franjas contiguas para índices 0–20; una cúpula activa desactiva una bala enemiga que entra en ella.
6. GameState: `win()` en el mundo 1 desbloquea el 2; `is_world_playable(data, 2)` falso antes y verdadero después; `is_world_playable(data, 3)` falso aunque esté desbloqueado.
7. `test_scenes_load.gd`: subir el mínimo de escenas según las nuevas (≥ 24).

## 7 · Criterios de aceptación

- Desde el mapa: vencer al Router desbloquea "Wi-Fi"; entrar lleva a 2-1; la compuerta del puzle lleva a la Reina; vencerla vuelve al mapa con el Mundo 3 desbloqueado (PRÓXIMAMENTE).
- 300 frames del nivel 2-1 y del jefe sin errores en headless.
- Capturas en `docs/capturas/` de `level2.png` y `boss2.png`.
- `README.md` del juego actualizado con la sección M8.

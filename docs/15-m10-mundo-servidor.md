# 15 · M10 — Mundo 4 Servidor (especificación de implementación)

Amplía `04-niveles.md` (Mundo 4), `05-enemigos-y-jefes.md` (Troyano, Troyano Real) y
`06-puzles.md` (Contraseñas lógicas). Donde esos documentos callan, **este documento decide**.

> **Alcance (decisión del director):** el juego tiene exactamente 5 mundos. El Mundo 5 es
> Centro de datos (Malwarex, 4 fases, M11); el antiguo mundo Nube/Botnet Nimbus queda
> absorbido por el Mundo 5. Este documento cubre **solo el Mundo 4**.

## Reglas globales (heredadas, no cambiar)

- Godot 4.7.2, GDScript con tipos estáticos, dibujo procedural con `_draw()` y `PQStyle`.
- Todo ataque: aviso → activo → recuperación. Daño a Byte siempre 1 PV.
- Fases de jefe de 3 fases al **70 %** y **40 %**, pausa invulnerable de **2,4 s**, las balas
  enemigas desaparecen y aparece la tarjeta de fase (reutilizar lo del Router).
- Capas de colisión 1–8 como en `08-arquitectura-tecnica.md`. Proyectiles con pool.
- Pruebas headless: `bash tools/run-tests.sh --integration` debe quedar en verde.
- Textos de interfaz en español.

## 1 · GameState por mundos

Desde M9, `GameState` tiene `WORLDS: Array[Dictionary]` y `current_world`; `win()`, `retry()` y
`enter_boss()` ya usan el mundo actual. Para el Mundo 4:

- Añadir la cuarta entrada a `WORLDS`: `{"level": "res://scenes/levels/World4Level1.tscn", "boss": "res://scenes/bosses/TrojanBoss.tscn"}` (queda `[World1, World2, World3, World4]`).
- `static func is_world_playable(data: Dictionary, world: int) -> bool`: desbloqueado **y** con escena. Hoy devuelve `true` para 1, 2, 3 y 4; `false` para 5 (Centro de datos) aunque esté desbloqueado.
- `win()` ya desbloquea `N + 1`; al vencer al Troyano Real (mundo 4) se desbloquea el Mundo 5 (Centro de datos), que seguirá como PRÓXIMAMENTE hasta M11.
- Mapa de la red: el botón "Entrar" usa el mundo seleccionado; izquierda/derecha elige entre los mundos jugables (1–4). El mundo 5 sigue como PRÓXIMAMENTE.

## 2 · Nivel 4-1 "Sala de servidores" (`World4Level1.tscn`)

3200×360 px, suelo base en y = 304, paleta interior de servidor (racks `PQStyle.CHIP` sobre
fondo `PQStyle.NIGHT`, LEDs cian `PQStyle.CYAN` y ámbar `PQStyle.AMBER`). Fondo con un nuevo
`ServerBackdrop` (`scripts/levels/server_backdrop.gd`, export `width`) que dibuja racks
verticales y LEDs que parpadean.

| Sección | Rango X | Contenido |
|---|---|---|
| S1 Ventiladores | 0–640 | Suelo plano, 2 `AirVent` (uno bajo una repisa con `w4_core_a`), letrero "Las corrientes de aire te elevan" |
| S2 Ascensores | 640–1280 | 1 `DataElevator` que sube a un rack elevado (y = 176); caída segura al suelo al final |
| S3 Combate | 1280–1920 | 2 `Trojan` con portales de Pop-ups, 1 foso de 96 px (salto + dash; caer = muerte) |
| Checkpoint | 1920 | |
| S4 Mezcla | 1920–2560 | 1 `DataElevator` + 1 `Trojan` + repisa con `w4_core_b` oculto |
| P Puzle | 2560–3200 | Checkpoint al entrar; `PasswordPuzzle`; compuerta en x = 3200 → jefe |

Núcleos de datos: 2 (`w4_core_a` visible en S1, `w4_core_b` oculto sobre la repisa de S4).

Coordenadas de construcción (todas sobre la rejilla de 16 px):

- S1: suelo `x[0, 640]`. Ventilador A en centro `(176, 244)`; repisa `(128, 208)` de 112×12
  one-way con `w4_core_a` en `(176, 196)`. Ventilador B en centro `(480, 244)` sobre suelo plano.
- S2: suelo `x[640, 800]` y `x[1120, 1280]` en y = 304. Rack sólido `(800, 176)` de 320×184
  (top en y = 176). `DataElevator` en centro `(760, 280)`, 80×12 one-way, anchor 280, travel 64.
- S3: suelo `x[1280, 1568]` y `x[1664, 1920]` (foso de 96 px entre 1568 y 1664, `fatal_pits`).
  2 `Trojan` en `(1400, 296)` y `(1800, 296)`.
- S4: suelo `x[1920, 2560]`. 1 `Trojan` en `(2000, 296)`. `DataElevator` en centro `(2160, 280)`
  (anchor 280, travel 64). Repisa `(2200, 176)` de 160×12 one-way con `w4_core_b` oculto en `(2280, 164)`.
- Salida: la compuerta del puzle (`PacketDoor`) está en x = 3200, **sin muro sólido** detrás;
  el suelo llega hasta x = 3200 y Byte la alcanza caminando (ver §6).

### AirVent (`scripts/objects/air_vent.gd`)

- `Area2D` rectangular (export `size`, por defecto 96×120) que ocupa una **columna de aire**
  desde el suelo (y = 304) hacia arriba; `position` es el centro. Mientras Byte está dentro y
  la columna está `active`, lo **empuja hacia arriba**: `player.velocity.y = lift_velocity(player.velocity.y, push_up)`.
- Export `push_up: float = 240.0` (px/s). `process_physics_priority = -10` (antes que el jugador).
- Ciclo (periodo 3,0 s): activo 2,0 s → inactivo 0,5 s → aviso 0,5 s (las partículas parpadean)
  → activo… Estado inicial configurable (`phase_offset`).
- Funciones puras testeables:
  - `static func state_at(t: float) -> StringName` devuelve `&"active"`, `&"inactive"` o `&"warning"` (el aviso son los últimos 0,5 s de la inactividad).
  - `static func lift_velocity(fall: float, push_up: float) -> float` = `minf(fall, -push_up)`: Byte asciende a `push_up` px/s; si ya cae más rápido hacia arriba (salto), se conserva su velocidad.

### DataElevator (`scripts/objects/data_elevator.gd`)

- `class_name DataElevator extends ChipPlatform`: un ascensor de datos (plataforma móvil
  vertical con aspecto de cabina de rack). Reutiliza la oscilación de `ChipPlatform`
  (`vertical_travel`, `period`); añade una función pura y el dibujo de raíles laterales.
- El borde superior oscila entre `anchor_y` (más bajo) y `anchor_y − travel` (más alto), con
  `position.y = anchor_y − (1 − cos(age·TAU/period))·travel/2`.
- Función pura: `static func top_y(anchor_y: float, travel: float, period: float, t: float) -> float`
  = `anchor_y - (1.0 - cos(t * TAU / period)) * travel / 2.0`. Con anchor 280, travel 64 y
  periodo 3,2 s el borde superior va de 280 (t = 0) a 216 (t = 1,6) y vuelve a 280 (t = 3,2).

## 3 · Troyano (`scripts/enemies/trojan.gd`, `scenes/enemies/Trojan.tscn`)

Extiende `EnemyBase`. **8 PV**, capa de enemigo, siempre en el grupo `homing_target`. Camina
despacio (40 px/s) en ping-pong dentro de un rango de patrulla (`patrol_half_width = 64`).
Debe eliminarse **antes** que sus Pop-ups: su peligro crece con el tiempo.

- Ciclo (reutiliza el `advance` de `EnemyBase`): `PATROL → TELEGRAPH (1,0 s, el portal crece)
  → ACTIVE (abre el portal y genera 2 Pop-ups) → RECOVERY (cycle_time 5,0 s) → PATROL…`.
- `fire()` sobrescrito: en vez de bala, crea el `TrojanPortal` (una única vez) y hace
  `portal.activate()`, que añade 2 `PopUp` (3 PV cada uno) en las posiciones de `spawn_offsets`.
- `static func spawn_offsets() -> Array[Vector2]` = `[Vector2(-28, 0), Vector2(28, 0)]`
  (a ambos lados del portal, a ras de suelo).
- El portal persiste y genera 2 Pop-ups más cada 5 s mientras el Troyano viva. Al morir
  (`_die()`), el Troyano cierra su portal (`portal.close()`): deja de generar; los Pop-ups ya
  creados siguen vivos.
- `TrojanPortal` (`scripts/enemies/trojan_portal.gd`, `Node2D`): anillo/rendija que crece
  durante el aviso y se abre en rojo/magenta al activarse; `activate()` genera los Pop-ups.

## 4 · Puzle "Contraseñas lógicas" (`PasswordLogic` + `PasswordPuzzle.tscn`)

Lógica pura en `scripts/puzzles/password_logic.gd` (`class_name PasswordLogic`, `RefCounted`),
escena aparte. Concepto real: **autenticación** (y por qué las contraseñas obvias son malas).

- Panel de **4 ranuras**, cada una muestra un símbolo de entre `TRIANGLE ▲`, `CIRCLE ●`,
  `STAR ★`, `SQUARE ■`. `interact` sobre una ranura hace `cycle()` (pasa al siguiente símbolo).
- 4 pistas visuales escondidas en la sala (pósteres/LEDs), una por restricción:

```
1  "● va justo antes que ★"
2  "▲ va antes que ■"
3  "● no va primero"
4  "★ no va al final"
```

- `enum Symbol { TRIANGLE, CIRCLE, STAR, SQUARE }` (orden de ciclo `[▲,●,★,■]`).
- `const SOLUTION: Array[Symbol] = [TRIANGLE, CIRCLE, STAR, SQUARE]` (= `▲ ● ★ ■`, la única
  ordenación que cumple las 4 pistas; ver §6).
- `const INITIAL: Array[Symbol] = [CIRCLE, STAR, SQUARE, TRIANGLE]` (revuelto, sin resolver).
- Funciones puras:
  - `static func cycle(symbol: int) -> int` = `(symbol + 1) % 4`.
  - `static func index_of(code: Array, symbol: int) -> int` (posición del símbolo, −1 si no está).
  - `static func circle_before_star(code: Array) -> bool` = `index_of(CIRCLE) + 1 == index_of(STAR)`.
  - `static func triangle_before_square(code: Array) -> bool` = `index_of(TRIANGLE) < index_of(SQUARE)`.
  - `static func circle_not_first(code: Array) -> bool` = `index_of(CIRCLE) != 0`.
  - `static func star_not_last(code: Array) -> bool` = `index_of(STAR) != 3`.
  - `static func is_solution(code: Array) -> bool` = las cuatro restricciones a la vez.
- Escena: `PasswordPuzzle` con 4 `PasswordSlot` (área `interactable`) + 4 pósteres + `PacketDoor`
  + `NetworkNode` ↺ de reinicio. Al resolverse: emite `solved`, sonido de conexión, abre la
  `PacketDoor` y muestra el dato: "Dato: la autenticación comprueba que eres quien dices ser;
  por eso una contraseña obvia es un riesgo." Se reutiliza `GameState.puzzle_complete` para
  conservar el estado (igual que `CablePuzzle`).

## 5 · Jefe Troyano Real (`scripts/bosses/trojan_boss.gd`, `TrojanBoss.tscn`)

Arena fija de 640×360, suelo en y = 304, muros en x = −16 y x = 640, y 2 plataformas-chip de
80 px con borde superior en y = 256 (x 96–176 y 448–528) para alcanzar los carriles altos. El
jefe es un **cofre digital** (cuerpo = `Hurtbox` de 48×48, `homing_target = true`, capa 4)
que **solo es vulnerable cuando está abierto**. **150 PV**.

El cofre alterna: cerrado (`body.invulnerable = true`) → salta a un `chest_spot` (arco fijo de
~0,6 s, aviso: sombra en el destino) → al aterrizar se abre (`invulnerable = false`) durante
`open_window(...)` y dispara la descarga → se cierra → salta… El contacto con el cofre cerrado
o en el aire quita 1 PV (con los i-frames normales).

`const CHEST_SPOTS: Array[Vector2] = [Vector2(160, 296), Vector2(320, 296), Vector2(480, 296)]`.

| | F1 "Cofre sellado" (100–70 %) | F2 "Invocación" (70–40 %) | F3 "Cofres falsos" (40–0 %) |
|---|---|---|---|
| Ataque A | **Salto del cofre:** salta a `chest_spot(_index)`; al aterrizar se abre **1,5 s**. Aviso 0,6 s: sombra en el destino | Igual, y al abrirse invoca **2 troyanos menores** | **Falsos cofres:** aparecen 3 cofres; solo `true_chest(step)` es real y se abre (brilla 0,4 s al empezar cada ciclo) |
| Ataque B | **Descarga:** 2 de 3 carriles `DESCARGA_LANES` a 160 px/s. Aviso 0,6 s: línea en el carril | Igual | Igual, desde el cofre real |
| Ataque C | — | **Troyanos menores:** 2 minions (Pop-up de 3 PV); cada uno eliminado alarga la apertura **+0,5 s** (máx 3,0 s) | **Mímicos:** los 2 cofres falsos quitan 1 PV al tocarlos |
| Punto débil | El cofre abierto | El cofre abierto (se alarga con los minions) | El cofre real abierto (identificado por el brillo) |
| Patrón | A, B, A, B… recuperación 0,8 s | A, C, B, A, C, B… recuperación 0,8 s | A (3 cofres), B… recuperación 0,8 s |

`const DESCARGA_LANES: Array[float] = [296.0, 256.0, 216.0]` (los mismos carriles probados de
la Reina Wi-Fi: bajo obliga a saltar, medio solo alcanza en el aire, alto queda sobre el pico
del salto).

Funciones puras testeables:

- `static func phase_for(hp_ratio: float) -> int` (1, 2 o 3): `1` si `> 0.7`, `2` si `> 0.4`, si no `3`.
- `static func chest_spot(index: int) -> Vector2` = `CHEST_SPOTS[posmod(index, 3)]`.
- `static func open_window(phase: int, minions_killed: int) -> float`
  = `clampf(1.5 + (0.5 if phase >= 2 else 0.0) * minions_killed, 0.0, 3.0)`.
- `static func true_chest(step: int) -> int` = `posmod(step, 3)` (F3, determinista por ciclo).
- `static func descarga_lanes(index: int) -> Array[int]` = `[0, 2]` o `[1, 2]` (nunca `[0, 1]`
  juntos; ver §6): `var lanes := [0, 2]; if (index >> 1) & 1 == 1: lanes = [1, 2]`.

Al vencerlo: `GameState.win()` (desbloquea el Mundo 5 en el mapa, que seguirá como PRÓXIMAMENTE).

## 6 · Comprobación de alcanzabilidad

Constantes físicas (de `player.gd`, verificadas en M1–M9): suelo en y = 304; Byte de pie ocupa
y 290–304 (hurtbox 10×14, centro en 297); salto `330²/(2·900) = 60,5 px` (~0,6 s); dash 72 px
(0,15 s de i-frames); bala enemiga de 6 px de alto (centro ± 3).

**S1 — ventilador → repisa (y = 208).**
Columna del `AirVent` de 96×120 con el borde inferior a ras de suelo: ocupa y ∈ [184, 304].
Byte entra con el centro en 297; deja de estar "dentro" cuando su centro baja de 177
(184 − 7, la mitad de la hurtbox). Ascenso dentro de la columna: 297 − 177 = **120 px** a
240 px/s = **0,5 s**. Al salir conserva `velocity.y = −240`, y el apex libre es
`240²/(2·900) = 32 px` más arriba → centro en 177 − 32 = 145 → pies en 152, es decir
**152 px sobre el suelo**. La repisa está a 304 − 208 = **96 px**, por debajo de 152 px:
alcanzable con 56 px de margen. El salto solo (60,5 px) no basta, así el ventilador es
obligatorio.

**S2 — ascensor → rack (y = 176).**
`DataElevator` con borde superior en [216, 280]. Suelo (304) → borde inferior (280): **24 px**
≤ 60. Borde superior (216) → rack (176): **40 px** ≤ 60. Salto solo (60,5 px) no sube los
128 px del rack: el ascensor es obligatorio. La caída del rack (176 → 304, 128 px) no hace
daño (no hay daño por caída, solo por foso).

**S3 — foso de 96 px.**
Salto horizontal ≈ 150 px/s × 0,6 s = **90 px**; con el dash (+72 px) se cruzan **96 px**.
Los bordes del foso están a la misma altura (y = 304), así no hay desnivel que incumpla la
regla de ≤ 60 px. `fatal_pits = true` convierte la caída en muerte.

**S4 — repisa (y = 176).**
Alcanzable con el `DataElevator` (216 → 176 = 40 px, igual que S2).

**Salida del nivel.**
El suelo llega hasta x = 3200 y la compuerta del puzle (`PacketDoor`) es la única barrera; al
abrirse, su colisión se desactiva y Byte llega caminando a `player.x >= WIDTH` (sin muro
sólido en la x de salida). Mismo patrón que `World2Level1` (`puzzle.is_solved` +
`global_position.x >= WIDTH`).

**Jefe — plataformas y carriles.**
Plataformas con borde en y = 256: 304 − 256 = **48 px** ≤ 60 (salto 60,5 px). `DESCARGA_LANES`
[296, 256, 216]:

- Bajo 296 (ocupa [293, 299]): alcanza a Byte de pie ([290, 304]) → obliga a saltar.
- Medio 256 (ocupa [253, 259]): 259 < 290 → no alcanza de pie; alcanza en el aire (durante el
  salto el cuerpo pasa por 256).
- Alto 216 (ocupa [213, 219]): 219 < 304 − 60,5 − 14 = 229,5 → no alcanza ni en el pico del salto.

`descarga_lanes(index)` devuelve `[0, 2]` (bajo + alto) o `[1, 2]` (medio + alto), **nunca**
bajo + medio juntos. Con `[1, 2]` Byte se queda quieto en el suelo (ambos carriles pasan por
encima de la cabeza); con `[0, 2]` salta (el bajo se esquiva saltando y el alto nunca lo toca).
Toda bala de la descarga y de los Pop-ups es esquivable. Los cofres de F3 caen en
`(160, 296)`, `(320, 296)`, `(480, 296)`, todos sobre el suelo, accesibles.

**Puzle — unicidad de la contraseña.**
Las 4 pistas fijan una única ordenación de 24 posibles: la pista 1 exige el bloque `●★`
adyacente; en las posiciones (1,2) viola la pista 3 y en (3,4) viola la pista 4, luego solo
queda (2,3); la pista 2 fuerza `▲` antes que `■`, dando `▲ ● ★ ■`. Verificado por fuerza bruta
en la prueba §7.1 (exactamente una ordenación satisface `is_solution`).

## 7 · Pruebas obligatorias (TDD: prueba roja → código → verde)

Nuevo `tests/test_world4.gd` registrado en `test_runner.gd` (con el patrón `finished` de los demás):

1. `PasswordLogic`: `is_solution([TRIANGLE, CIRCLE, STAR, SQUARE]) == true`; `false` para
   `[CIRCLE, TRIANGLE, STAR, SQUARE]`, `[TRIANGLE, CIRCLE, SQUARE, STAR]` y
   `[STAR, TRIANGLE, CIRCLE, SQUARE]`; al recorrer las 24 permutaciones, exactamente 1 es
   `true`; `cycle(TRIANGLE) == CIRCLE`, `cycle(SQUARE) == TRIANGLE` (cierra el ciclo);
   cada predicado de pista coincide con la pista correspondiente.
2. `AirVent.state_at`: 0,0 → active, 1,9 → active, 2,2 → inactive, 2,6 → warning, 3,1 → active.
3. `AirVent.lift_velocity`: `(0.0, 240) → −240`, `(−330, 240) → −330`, `(100, 240) → −240`.
4. `DataElevator.top_y`: `(280, 64, 3.2, 0.0) → 280`, `(280, 64, 3.2, 1.6) → 216`,
   `(280, 64, 3.2, 3.2) → 280`; y `304 − 280 = 24` y `216 − 176 = 40` (ambos ≤ 60).
5. `Trojan`: instanciado con un Byte lejano, al pasar 1,0 s de aviso y disparar, hay 2 Pop-ups
   nuevos en `spawn_offsets`; al matar el Troyano, el portal deja de generar.
6. Troyano Real: `phase_for(1.0) == 1`, `phase_for(0.69) == 2`, `phase_for(0.39) == 3`;
   `open_window(1, 0) == 1.5`, `open_window(2, 1) == 2.0`, `open_window(2, 4) == 3.0`,
   `open_window(3, 2) == 2.5`; `true_chest` devuelve solo 0/1/2 para índices 0–20 y cicla de
   forma determinista; `descarga_lanes` nunca devuelve `[0, 1]` juntos para índices 0–12;
   `DESCARGA_LANES` cumple la geometría de §6 (bajo alcanza de pie, alto sobre el pico).
7. GameState: `win()` en el mundo 3 desbloquea el 4; `is_world_playable(data, 4)` falso antes
   de añadir la escena y verdadero después; `is_world_playable(data, 5)` falso aunque esté desbloqueado.
8. `test_scenes_load.gd`: subir el mínimo de escenas según las nuevas (≥ 34).

## 8 · Criterios de aceptación

- Desde el mapa: vencer al Firewall Corrupto desbloquea "Servidor"; entrar lleva a 4-1; la
  compuerta del puzle lleva al Troyano Real; vencerlo vuelve al mapa con el Mundo 5 desbloqueado (PRÓXIMAMENTE).
- 300 frames del nivel 4-1 y del jefe sin errores en headless.
- Capturas en `docs/capturas/` de `level4.png` y `boss4.png`.
- `README.md` del juego actualizado con la sección M10.

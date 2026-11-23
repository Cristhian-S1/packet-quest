# 16 · M11 — Mundo 5 Centro de datos (especificación de implementación)

Amplía `04-niveles.md` (Mundo 5), `05-enemigos-y-jefes.md` (Bot DDoS, Malwarex) y
`06-puzles.md` (Prioridad de tráfico, Puzle en combate). Donde esos documentos callan,
**este documento decide**.

> **Decisión del director (supersede a `04-niveles.md`):** el juego tiene exactamente
> **5 mundos**. Se elimina el mundo *Nube* y su jefe *Botnet Nimbus*; sus elementos pasan
> al Mundo 5: el enemigo **Bot DDoS**, las **plataformas de nube que se desvanecen** y el
> puzle **"Prioridad de tráfico" (QoS)**. El Mundo 5 es el final: Malwarex (4 fases) remata
> la historia con créditos, epílogo y estadísticas.
>
> Beads: épica de M11 — Mundo 5 Centro de datos.

## Reglas globales (heredadas, no cambiar)

- Godot 4.7.2, GDScript con tipos estáticos, dibujo procedural con `_draw()` y `PQStyle`.
- Todo ataque: aviso → activo → recuperación. Daño a Byte siempre 1 PV.
- Fases de jefe de 3 fases al **70 %** y **40 %**; **Malwarex (4 fases) al 75/50/25 %**.
  Pausa invulnerable de **2,4 s**, las balas enemigas desaparecen y aparece la tarjeta de
  fase (reutilizar `StageBuilder.BOSS_TRANSITION_TIME`).
- Capas de colisión 1–8 como en `08-arquitectura-tecnica.md`. Proyectiles con pool.
- Pruebas headless: `bash tools/run-tests.sh --integration` debe quedar en verde.
- Textos de interfaz en español.
- Suelo base en y = 304; Byte tiene hurtbox de 10×14 px (de pie ocupa y 290–304).

## 1 · GameState: de 6 a 5 mundos (decisión del director)

Desde M8, `GameState` tiene `WORLDS: Array[Dictionary]` y `current_world`; `win()`, `retry()`
y `enter_boss()` ya usan el mundo actual. Para cerrar el juego en el Mundo 5:

- `WORLDS` pasa a **5 entradas** (una por mundo), con la última:
  `{"level": "res://scenes/levels/World5Level1.tscn", "boss": "res://scenes/bosses/MalwarexBoss.tscn"}`
  (queda `[World1, World2, World3, World4, World5]`; las entradas 3 y 4 las aportan M9 y M10).
- `static func is_world_playable(data: Dictionary, world: int) -> bool`: desbloqueado **y**
  con escena. Devuelve `true` para 1–5; `false` para 6 en adelante (ya no existe).
- `win()`: al vencer al Troyano Real (mundo 4) desbloquea el 5. Al vencer en `current_world == 5`
  (último mundo) **no** desbloquea el 6: registra `w5_boss`, marca `data["finished"] = true` y
  el jefe enruta a los créditos (ver §6).
- `network_map.gd`: `WORLDS` pasa a 5 nombres `["Red Local", "Wi-Fi", "Firewall", "Servidor",
  "Centro de datos"]` (se quita "Nube"). Ajustar `node_x(index)` para que 5 nodos repartan los
  640 px (p. ej. `70 + index * 112`). Los no implementados siguen como PRÓXIMAMENTE.
- `save_manager.gd`: la validación de `unlocked_worlds` pasa de `world > 6` a `world > 5`; al
  cargar, descartar cualquier mundo > 5 (el antiguo "Centro de datos"=6). El antiguo "Nube"=5
  se lee ahora como "Centro de datos"=5, sin migración adicional.

## 2 · Nivel 5-1 "Centro de datos" (`World5Level1.tscn`)

3600×360 px, suelo base en y = 304, paleta de centro de datos con pasillos fríos (azul
`#0B1A2E`/`#1B3A5C`) y calientes (rojo `#2A0F3A`) alternos, franjas de advertencia ámbar y
acentos cian. `EXIT_X = 3590` (la compuerta/muro final está en x = 3600; ver §7).

| Sección | Rango X | Contenido |
|---|---|---|
| S1 Corrientes | 0–560 | 1 `WaveZone` + 2 `AirVent` de M10 (suben a una plataforma en y = 184, 120 px, inalcanzable con salto); letrero "Ondas y corrientes de aire" |
| S2 Cobertura | 560–1280 | 1 router + 4 `CoveragePlatform` sobre un foso de 240 px (caer = muerte); letrero "Mantente cerca del router" |
| S3 Puertos | 1280–1920 | 3 `PortLaser`; un hueco de 96 px (salto + dash) entre el 2.º y el 3.º; letrero "Los puertos se abren y se cierran" |
| S4 Combate | 1920–2560 | 1 `NetworkWorm`, 2 `PopUp`, 1 `Spyware`, 1 `Trojan`, 2 `BotDDoS` |
| Checkpoint | 2560 | |
| S5 Nubes | 2560–3040 | 3 `CloudPlatform` sobre un foso de 280 px (caer = muerte) + 1 `BotDDoS` + 1 `PortLaser` |
| P Puzle | 3040–3600 | Checkpoint al entrar; `QoSPuzzle`; compuerta en x = 3600 → Malwarex |

Núcleos de datos: 2 (`w5_core_a` visible en S3, sobre la plataforma tras el hueco de 96 px;
`w5_core_b` oculto en S5 sobre la última nube, se revela al acercarse, como `w2_core_b`).

### CloudPlatform (`scripts/objects/cloud_platform.gd`)

- `StaticBody2D` de 64×12 px (mismo `SIZE` que `CoveragePlatform`). Sólida (capa 1 `world`) en
  los estados `solid` y `fading`; en `gone` desactiva la colisión y baja el alfa a 0,25.
- Ciclo determinista: `solid` 2,0 s → `fading` 0,5 s (parpadea en blanco; sigue sólida) →
  `gone` 1,5 s → `solid`… (periodo 4,0 s). `@export var phase_offset: float = 0.0` desfasa
  nubes vecinas para no dejar un foso intransitable (ver §7).
- Función pura testeable: `static func state_at(t: float) -> StringName` devuelve `&"solid"`,
  `&"fading"` o `&"gone"` (periodo 4,0 s: 0–2,0 solid, 2,0–2,5 fading, 2,5–4,0 gone).

### Corrientes de aire: se reutiliza `AirVent` de M10

No se crea un objeto nuevo: S1 usa el `AirVent` de `docs/15-m10-mundo-servidor.md`
(`scripts/objects/air_vent.gd`, columna de 96×120 desde el suelo, `push_up = 240`,
`lift_velocity`, ciclo de 3,0 s). Con esos valores Byte sube hasta 152 px sobre el suelo, así que
la plataforma de S1 a y = 184 (120 px) es alcanzable y el salto solo (60,5 px) no basta.
(Revisión del director: el borrador definía un `AirCurrent` que restaba `lift` a la velocidad en
cada frame, lo que acelera a Byte sin límite; además duplicaba el objeto de M10.)

### Reuso de objetos de mundos anteriores

- `WaveZone` (`objects/wave_zone.gd`) empuja en horizontal; sin cambios.
- `CoveragePlatform` (`objects/coverage_platform.gd`) y su `is_covered`; sin cambios.
- `PortLaser` (`objects/port_laser.gd`, de M9) y su `state_at`; sin cambios.
- `RuleBar`/reglas con hueco solo aparecen en la arena de Malwarex (§5), no en el nivel.

## 3 · Enemigos: Bot DDoS y mezcla de mundos

### BotDDoS (`scripts/enemies/bot_ddos.gd`, `scenes/enemies/BotDDoS.tscn`)

Extiende `EnemyBase`. **2 PV**. Vuela: sin gravedad, avanza en horizontal y oscila en vertical
con una onda sinusoidal (`y = base_y + sin(t) * 24`); entra en el grupo `homing_target` al aparecer.

- Ataque: cada 2,4 s, aviso **0,6 s** (se ilumina de ámbar), luego suelta **6 balas lentas en
  abanico** (90 px/s, ámbar) centradas hacia Byte, abriéndose 120° en total (60° a cada lado).
- Al morir: el 10 % de fragmento de caché que ya gestiona `EnemyBase`.
- Función pura testeable: `static func fan_directions(center: Vector2, count: int, spread_deg: float) -> Array[Vector2]`
  devuelve `count` direcciones normalizadas espaciadas `spread_deg / (count - 1)` grados centradas
  en `center`.

### Mezcla de enemigos (S4)

El Mundo 5 reúne enemigos de los cuatro mundos anteriores, sin variantes blindadas (eso era
exclusivo del Mundo 3):

| Enemigo | Script / escena | PV | Origen |
|---|---|---:|---|
| Pop-up | `pop_up.gd` / `PopUp.tscn` | 3 | Mundo 1 |
| Gusano de red | `network_worm.gd` / `NetworkWorm.tscn` | 5 | Mundo 1 |
| Spyware | `spyware.gd` / `Spyware.tscn` | 4 | Mundo 2 |
| Troyano | `trojan.gd` / `Trojan.tscn` (de M10) | 8 | Mundo 4 |
| Bot DDoS | `bot_ddos.gd` / `BotDDoS.tscn` | 2 | Mundo 5 (nuevo) |

Ninguno dispara fuera de pantalla (regla global). El Troyano abre un portal que genera 2 Pop-ups
cada 5 s (avisado 1 s), como en el Mundo 4.

## 4 · Puzle "Prioridad de tráfico" (`QosPuzzle` + `QoSPuzzle.tscn`)

Lógica pura en `scripts/puzzles/qos_puzzle.gd` (`class_name QosPuzzle`, `RefCounted`), escena
aparte. Concepto real: QoS (calidad de servicio).

- `const PRIORITY: Array[StringName] = [&"voz", &"video", &"correo", &"descarga"]` (orden de
  mayor a menor urgencia).
- `const LABELS: Dictionary = {&"voz": "VOZ", &"video": "VÍDEO", &"correo": "CORREO", &"descarga": "DESCARGA"}`.
- `static func urgency(id: StringName) -> int`: voz = 4, video = 3, correo = 2, descarga = 1
  (número de bloques de urgencia que dibuja cada interruptor).
- `static func is_correct_order(activated: Array[StringName]) -> bool`: `activated == PRIORITY`.
- `static func next_expected(activated: Array[StringName]) -> StringName`: `PRIORITY[activated.size()]`
  (para la pista suave y para iluminar el puente correcto).

Escena: 4 interruptores `QoSNode` en fila, etiquetados VOZ / VÍDEO / CORREO / DESCARGA con
iconos de urgencia (▮▮▮▮, ▮▮▮, ▮▮, ▮). Byte activa con `interact` el interruptor que toca; cada
pulsación añade su `id` a `activated` (se ilumina cian). Al activar los 4:

- `is_correct_order == true` → emite `solved`, sonido de conexión, abre la `PacketDoor`, muestra
  el dato curioso: "Dato: QoS prioriza el tráfico urgente (voz y vídeo) sobre las descargas."
- `is_correct_order == false` → los puentes se caen (animación de caída), `activated` se vacía y
  Byte reintenta sin daño y sin límite de tiempo.

Nodo ↺ con `interact` reinicia (`activated` vacío). Pista suave: tras 60 s, `next_expected` parpadea
1 s cada 10 s (como en `route_puzzle.gd`). `QoSNode` es un `Area2D` en el grupo `interactable` con
`interact()` y señal `pressed(id)`.

## 5 · Jefe Malwarex (`scripts/bosses/malwarex_boss.gd`, `MalwarexBoss.tscn`)

Arena fija de 640×360, suelo en y = 304. Malwarex flota: un núcleo glitch (`Hurtbox` de 64×64,
`homing_target = true`, capa 4 `enemy`) centrado en (320, 160). **200 PV**. La arena tiene
2 plataformas-chip de 80 px con el borde superior en y = 256, en x 96–176 y 272–352 (para alcanzar
los carriles altos de la regla, ver §7).

Constantes: `PHASE_TWO = 0.75`, `PHASE_THREE = 0.50`, `PHASE_FOUR = 0.25`;
`PHASE_NAMES = ["Remezcla", "Cables vivos", "Núcleo blindado", "Borrado de datos"]`.

| | F1 "Remezcla" (100–75 %) | F2 "Cables vivos" (75–50 %) | F3 "Núcleo blindado" (50–25 %) | F4 "Borrado de datos" (25–0 %) |
|---|---|---|---|---|
| Ataque A | **Anillo de señal** (Router): 12 balas en círculo desde (320, 112) a 150 px/s. Aviso 0,6 s (el núcleo brilla) | **Cables vivos:** 2 cables horizontales de 4 px barren en vertical entre y 96 y 300 a 90 px/s (uno baja desde 96, otro sube desde 300). Cada cable tiene un **hueco de 64 px** en `cable_gap_x(index)`; Byte se pone bajo el hueco del que baja y salta por el hueco del que sube. Tocarlos = 1 PV. Aviso 0,6 s (el cable se enciende y su hueco se marca en cian) | **Regla de bloqueo** (Firewall): barra vertical 16×360 px que barre de derecha a izquierda a 140 px/s con un hueco de 64 px centrado en un carril `LANES_Y` (288/240/184). Aviso 0,7 s (la franja parpadea) | **Borrado de datos:** el suelo se borra por columnas de 64 px (de derecha a izquierda), 1 columna cada 1,5 s; caer = muerte. Aviso 0,8 s (la columna parpadea en rojo) |
| Ataque B | **Ondas horizontales** (Reina): 2 de 3 carriles `WAVE_LANES` (296/256/216), fila de 5 a 160 px/s, rebote 1. Aviso 0,6 s (línea en el carril) | **Ventanas emergentes:** 2 ventanas de 160×96 aparecen en las esquinas superiores durante 1,2 s; se dibujan **debajo** de cables, balas y avisos (nunca ocultan un aviso: pilar "legible antes que difícil"), no dañan y se cierran con 1 disparo | **Ping descendente** (Reina): 5 balas caen en x de Byte ±0/32/64 a 180 px/s. Aviso 0,8 s (marcas en el techo) | **Anillo doble** (Router F2): 2 anillos de 12 desfasados 15°, a 0,35 s |
| Punto débil | Cuerpo (hurtbox) | Cuerpo (hurtbox) | **Puzle en combate:** 3 nodos a conectar quitan 3 escudos; luego el cuerpo es vulnerable | Cuerpo (hurtbox) |
| Patrón | A, B, A, B… rec 1,0 s | A, B, A, B… rec 0,8 s | A, B, A, B… (nodos en paralelo) rec 0,8 s | A continuo + B cada 2 s, rec 0,8 s |

Funciones puras testeables:

- `static func phase_for(hp_ratio: float) -> int`: 1 si `> 0.75`, 2 si `> 0.50`, 3 si `> 0.25`,
  si no 4.
- `static func erased_columns(elapsed: float) -> Array[int]`: columnas de suelo borradas en F4.
  Con 10 columnas de 64 px (0–639), cada 1,5 s se borra una más desde la derecha, **como máximo 6**
  (las columnas 0–3, x 0–255, nunca se borran: siempre queda suelo):
  `n = clampi(floori(elapsed / 1.5), 0, 6)`; devuelve `[9, 8, …]` (las `n` más a la derecha).
- `static func cable_gap_x(index: int) -> float`: x izquierda del hueco de 64 px de cada cable,
  determinista y dentro de [32, 544] (p. ej. `[64.0, 288.0, 512.0, 176.0, 400.0][posmod(index, 5)]`).
- `static func node_positions() -> Array[Vector2]`: las 3 posiciones fijas del puzle en combate
  `[Vector2(120, 288), Vector2(320, 240), Vector2(520, 288)]`.

### Puzle en combate (F3)

Al entrar en F3, Malwarex se blinda: `body.invulnerable = true` y aparecen **3 escudos** visuales.
3 nodos `NetworkNode` (reutilizar `objects/network_node.gd`) aparecen en `node_positions()`. Cada
`interact` conecta un nodo y quita **un escudo** (el nodo se ilumina cian y emite `activated`).
Con los 3 conectados: `body.invulnerable = false` y Malwarex queda vulnerable hasta el 25 %. Los
ataques C/D siguen mientras Byte conecta los nodos. Al caer por debajo del 25 %: transición a F4.

### Derrota y pantalla de muerte

- `_defeat()`: `GameState.win()` (registra `w5_boss`, marca `finished`), limpia el pool, emite
  `Events.boss_defeated.emit(&"malwarex")` y enruta a los créditos (§6). Los dos núcleos del
  Mundo 5 se recogen durante el nivel 5-1, antes de la arena.
- `death_screen.gd`: añadir `MALWAREX_THRESHOLDS: Array[float] = [0.25, 0.5, 0.75]` y elegirlo
  cuando `current_world == 5` (marcas de fase en la barra de progreso).

## 6 · Final del juego: epílogo, créditos y estadísticas

Nueva escena `scenes/ui/CreditsScreen.tscn` (`scripts/ui/credits_screen.gd`, extiende `PacketScreen`),
mostrada al derrotar a Malwarex (no hay vuelta al mapa: la historia termina).

- `GameState.show_credits()`: `playing = false; change_scene(CREDITS)` con
  `const CREDITS: String = "res://scenes/ui/CreditsScreen.tscn"`.
- `GameState.ALL_CORE_IDS` enumera los 12 núcleos de la partida. En los niveles se recogen
  `w1_hidden_a`, `w2_core_a`/`w2_core_b`, `w3_core_a`/`w3_core_b`, `w4_core_a`/`w4_core_b`
  y `w5_core_a`/`w5_core_b`. Las victorias contra el Router Furioso, el Firewall Corrupto
  y el Troyano Real dan `w1_router`, `w3_firewall_boss` y `w4_trojan_boss`.
- Contenido:
  - Título "INTERNET RESTAURADA" (verde) y un epílogo de 2–3 líneas.
  - **Estadísticas:** «Núcleos de datos: X/12» cuenta los identificadores únicos de
    `collected_cores` que figuran en `GameState.ALL_CORE_IDS`. Las compras en el Taller
    reducen el saldo `data_cores`. «Muertes: N» suma `stats.deaths.values()` y
    «Tiempo: mm:ss» usa `stats.play_time_s`.
  - **Créditos** (lista estática o desplazamiento lento).
  - Botones "Menú principal" (`GameState.menu`) y "Nueva partida".
- Función pura testeable: `static func format_time(seconds: float) -> String` → `"mm:ss"`.

## 7 · Comprobación de alcanzabilidad

Valores de `player.gd` (no cambiar): `jump_speed = 330`, `gravity = 900`, `fall_multiplier = 1.6`,
`speed = 150`, `dash_distance = 72`, `dash_iframes = 0.15`.

1. **Salto.** Altura = 330² / (2·900) = 108900 / 1800 = **60,5 px**. Tiempo en el aire ≈ 0,6 s.
   Alcance horizontal del salto ≈ 150 × 0,6 = **90 px**. Pico del salto: pies en y = 304 − 60,5 =
   243,5 y cabeza en 243,5 − 14 = 229,5.
2. **Dash.** 72 px con 0,15 s de i-frames. Salto + dash = 90 + 72 = **162 px**.
3. **Huecos.** Todo hueco del nivel es ≤ 96 px (el de S3 es exactamente 96 px): salto solo (90 px)
   no llega, salto + dash (162 px) sí. Los fosos de cobertura (240 px) y de nubes (280 px) **no son
   huecos a saltar**: se cruzan por `CoveragePlatform`/`CloudPlatform` con separación entre apoyos
   ≤ 96 px (en S2: 4 apoyos a ~64 px; en S5: 3 nubes a ~70 px).
4. **Regla de 60 px.** Toda superficie pisable está a ≤ 60 px por encima de otra alcanzable: una
   plataforma a y = 256 (48 px sobre el suelo) se alcanza con salto (60,5 px). La plataforma de S1
   a y = 184 (120 px) **no** se salta: se alcanza con el `AirVent` (sube hasta 152 px sobre el suelo, ver §15-6
   de M10).
5. **Carriles de la regla (`LANES_Y` = 288/240/184) en F3.** Hueco de 64 px centrado en el carril:
   288 → pasa de pie (hueco 256–320, piso 304); 240 → salto desde el suelo (hueco 208–272, pico
   229,5–243,5); 184 → desde la plataforma a y = 256 (pico 181,5–195,5 dentro de 152–216). La arena
   de Malwarex coloca sus 2 plataformas en y = 256 delante de la regla.
6. **Balas esquivables.** Una bala (6 px de alto) a y = 280 ocupa 277–283, por encima de Byte de
   pie (290–304): **no alcanza a Byte de pie**. Por eso las ondas usan `WAVE_LANES` = 296/256/216:
   la baja (296) obliga a saltar (pico de pies 243,5 < 296), la media y la alta no tocan a Byte de
   pie; `wave_lanes()` nunca empareja baja + media, así siempre hay un carril seguro.
7. **Salida caminando.** `EXIT_X = 3590 = WIDTH − 10`; el muro/compuerta está en x = 3600 y no hay
   muro sólido en la x de salida (mismo patrón que `World1Level1.EXIT_X = 2710`).
8. **F4.** El borrado deja 2 plataformas permanentes en y = 256 (x 96–176 y 272–352) alcanzables
   desde el suelo antes de que desaparezca su columna; `erased_columns` borra de derecha a izquierda
   y nunca más de 6 columnas: x 0–255 siempre tiene suelo. Los cables de F2 bajan hasta y = 300
   (alcanzan a Byte de pie) pero cada uno deja un hueco de 64 px (> 10 px de Byte) marcado en el aviso.

## 8 · Pruebas obligatorias (TDD: prueba roja → código → verde)

Nuevo `tests/test_world5.gd` registrado en `test_runner.gd` (`TESTS` += `"world5"`), con el patrón
`finished` de los demás:

1. `CloudPlatform.state_at`: 0,0 → solid, 1,9 → solid, 2,2 → fading, 2,6 → gone, 3,9 → gone, 4,1 → solid.
2. Reutiliza `AirVent` (sus pruebas son de M10); comprueba que la plataforma de S1 está a ≤ 152 px del suelo y a > 60 px (exige el ventilador).
3. `QosPuzzle`: `is_correct_order([]) == false`; `is_correct_order([voz, video, correo, descarga]) == true`;
   `is_correct_order([video, voz, correo, descarga]) == false`; `urgency` = 4/3/2/1;
   `next_expected([voz, video]) == &"correo"`.
4. `BotDDoS.fan_directions`: 6 direcciones, la primera y la última desfasadas ~120°, todas de
   longitud ≈ 1 (normalizadas).
5. `Malwarex.phase_for`: 1,0 → 1, 0,76 → 1, 0,75 → 2, 0,51 → 2, 0,50 → 3, 0,26 → 3, 0,25 → 4, 0,0 → 4.
6. `Malwarex.erased_columns`: 0,0 → `[]`, 1,5 → `[9]`, 3,0 → `[9, 8]`, 16,0 → `[9, 8, 7, 6, 5, 4]` (nunca borra 0–3); `cable_gap_x` devuelve valores en [32, 544] para índices 0–20.
7. Integración (igual patrón que `_test_queen`): instanciar Malwarex, `take_damage` cruza 75/50/25 %
   con `timer == 2.4` y balas limpiadas; en F3 `body.invulnerable` hasta conectar los 3 nodos; la
   derrota marca `finished` y abre `CreditsScreen`; `format_time(65) == "01:05"`.
8. GameState: `win()` en el mundo 4 desbloquea el 5; `is_world_playable(data, 5)` falso antes de
   añadir la escena y verdadero después; `is_world_playable(data, 6)` falso aunque esté desbloqueado;
   `win()` en el mundo 5 no añade `6` a `unlocked_worlds` y marca `finished`.
9. `test_scenes_load.gd`: subir el mínimo de escenas según las nuevas (M11 añade 6: `World5Level1`,
   `MalwarexBoss`, `BotDDoS`, `QoSPuzzle`, `QoSNode`, `CreditsScreen`; mínimo ≥ 40).

## 9 · Criterios de aceptación

- Desde el mapa: vencer al Troyano Real (M10) desbloquea "Centro de datos"; entrar lleva a 5-1; la
  compuerta del puzle QoS lleva a Malwarex; vencerlo muestra créditos/epílogo con "Núcleos de datos:
  X/12", muertes y tiempo, y **no** desbloquea ningún mundo 6.
- 300 frames del nivel 5-1 y del jefe sin errores en headless.
- Capturas en `docs/capturas/` de `level5.png`, `boss5.png` y `credits.png`.
- `README.md` del juego actualizado con la sección M11 y el nuevo mapa de 5 mundos.
- `bash tools/run-tests.sh --integration` en verde, incluyendo `test_world5`.

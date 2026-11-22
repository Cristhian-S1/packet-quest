# 14 · M9 — Mundo 3 Firewall (especificación de implementación)

Amplía `04-niveles.md` (Mundo 3), `05-enemigos-y-jefes.md` (Firewall Corrupto) y
`06-puzles.md` (Firewall). Donde esos documentos callan, **este documento decide**.
Beads: épica de M9 — Mundo 3 Firewall.

## Reglas globales (heredadas, no cambiar)

- Godot 4.7.2, GDScript con tipos estáticos, dibujo procedural con `_draw()` y `PQStyle`.
- Todo ataque: aviso → activo → recuperación. Daño a Byte siempre 1 PV.
- Fases de jefe de 3 fases al **70 %** y **40 %**, pausa invulnerable de **2,4 s**, las balas
  enemigas desaparecen y aparece la tarjeta de fase (reutilizar lo del Router).
- Capas de colisión 1–8 como en `08-arquitectura-tecnica.md`. Proyectiles con pool.
- Pruebas headless: `bash tools/run-tests.sh --integration` debe quedar en verde.
- Textos de interfaz en español.

## 1 · GameState por mundos

Desde M8, `GameState` tiene `WORLDS: Array[Dictionary]` y `current_world`; `win()`, `retry()` y
`enter_boss()` ya usan el mundo actual. Para el Mundo 3:

- Añadir la tercera entrada a `WORLDS`: `{"level": "res://scenes/levels/World3Level1.tscn", "boss": "res://scenes/bosses/FirewallBoss.tscn"}` (queda `[World1, World2, World3]`).
- `static func is_world_playable(data: Dictionary, world: int) -> bool`: desbloqueado **y** con escena. Hoy devuelve `true` para 1, 2 y 3; `false` para 4–6 aunque estén desbloqueados.
- `win()` ya desbloquea `N + 1`; al vencer al Firewall Corrupto (mundo 3) se desbloquea el Mundo 4, que seguirá como PRÓXIMAMENTE.
- Mapa de la red: el botón "Entrar" usa el mundo seleccionado; izquierda/derecha elige entre los mundos jugables (1–3). Los no implementados (4–6) siguen como PRÓXIMAMENTE.

## 2 · Nivel 3-1 "Muro de reglas" (`World3Level1.tscn`)

3040×360 px, suelo base en y = 304, paleta interior de firewall (muros rojos `#FF3355`, fondo
rojo oscuro `#2A0F3A`, franjas de advertencia ámbar).

| Sección | Rango X | Contenido |
|---|---|---|
| S1 Reglas | 0–560 | Suelo plano, 2 `ArmoredPopUp` estáticos, letrero "Dispara por detrás" |
| S2 Puertos | 560–1280 | 3 `PortLaser` sobre un foso de 160 px (caer = muerte), letrero "Los puertos se abren y se cierran" |
| S3 Combate | 1280–1920 | 2 `ArmoredWorm`, 2 `ArmoredPopUp`, 1 `PortLaser` |
| Checkpoint | 1920 | |
| S4 Mezcla | 1920–2400 | 1 `RuleBar` + 2 plataformas + 1 `ArmoredPopUp` |
| P Puzle | 2400–3040 | Checkpoint al entrar; `FirewallPuzzle`; compuerta en x = 3040 → jefe |

Núcleos de datos: 2 (`w3_core_a` visible en S2, `w3_core_b` oculto sobre la última plataforma de S4).

### PortLaser (`scripts/objects/port_laser.gd`)

- `Area2D` rectangular (export `size`, por defecto 48×16) que emite un **láser horizontal** de
  "puerto bloqueado". Mientras está `blocked`, Byte que lo toca recibe 1 PV (capa 7 `hazard`, máscara `player`).
- Ciclo: bloqueado 1,6 s → abierto 1,4 s; los últimos 0,5 s del abierto son `warning` (el láser
  parpadea y deja de hacer daño antes de cerrarse). Estado inicial configurable (`phase_offset`).
- Función pura testeable: `static func state_at(t: float) -> StringName` devuelve `&"blocked"`,
  `&"open"` o `&"warning"` (periodo 3,0 s: 0–1,6 bloqueado, 1,6–2,5 abierto, 2,5–3,0 aviso).

### RuleBar (`scripts/objects/rule_bar.gd`)

- Barrera vertical de 16×360 px en una posición fija (capa 7 `hazard`) con un **hueco de 64 px**.
  El hueco cambia de altura entre 3 carriles (y = 280, 208, 136) cada **1,5 s**.
- Tocar la parte sólida = 1 PV; pasar por el hueco es seguro. Aviso 0,4 s antes de mover el hueco
  (el hueco parpadea en blanco). Reutiliza el concepto del hueco del jefe (F1) para enseñar a leer huecos.
- Función pura: `static func gap_lane(t: float) -> int` = `int(fposmod(t / 1.5, 3.0))` (0/1/2 → 280/208/136), determinista.

## 3 · Enemigos blindados (`scripts/enemies/armor_rule.gd`, `armored_popup.gd`, `armored_worm.gd`)

En el Mundo 3 los enemigos comunes vuelven **blindados**: solo son vulnerables por detrás. La regla
compartida es pura:

- `ArmorRule` (`class_name ArmorRule`, `RefCounted`): `static func blocks(shooter: Vector2, body: Vector2, facing: Vector2) -> bool` → `(shooter - body).dot(facing) > 0.0`. Un disparo que llega por delante (`blocks == true`) es absorbido por la "regla" y no hace daño.

**ArmoredPopUp** (`class_name ArmoredPopUp extends PopUp`, `scenes/enemies/ArmoredPopUp.tscn`):

- 4 PV. `@export var facing: Vector2 = Vector2.LEFT` (la regla mira hacia donde llega Byte; no gira).
- Sobrescribe `take_damage(amount, origin)`: si `ArmorRule.blocks(origin, global_position, facing)` →
  `flash = 0.05` y `return` (sin daño, sin fragmento de caché); si no, `super.take_damage(amount, origin)`.
- Se dibuja como un Pop-up con una **regla roja vertical** (`PQStyle.RED`, borde blanco) en el lado `facing`.

**ArmoredWorm** (`class_name ArmoredWorm extends NetworkWorm`, `scenes/enemies/ArmoredWorm.tscn`):

- 6 PV. `facing` = dirección de desplazamiento actual (`Vector2.RIGHT`/`Vector2.LEFT` según el sentido
  del cable), actualizado cada frame.
- Misma sobrescritura de `take_damage`; mantiene la división en 2 paquetes solo al recibir daño **por detrás**.

## 4 · Puzle "Firewall" (`FirewallFilter` + `FirewallPuzzle.tscn`)

Lógica pura en `scripts/puzzles/firewall_filter.gd` (`class_name FirewallFilter`, `RefCounted`), escena aparte.

- Paquetes con forma (`CIRCLE`, `TRIANGLE`, `SQUARE`) y color (`RED`, `GREEN`, `BLUE`). Regla fija en
  pantalla: **"Bloquea ROJO · Permite ▲"** (bloquear los rojos, dejar pasar los triángulos).
- `static func is_allowed(shape: int, color: int, allowed_shape: int, blocked_color: int) -> bool`:
  `shape == allowed_shape and color != blocked_color`.
- `static func generate_sequence(seed: int) -> Array[Dictionary]`: 10 paquetes deterministas por semilla;
  con la semilla 0, exactamente **4 permitidos** y **6 bloqueados**. `●`=círculo, `▲`=triángulo, `■`=cuadrado; R/G/B:

```
1  ●R  BLOQUEAR   2  ▲G  PASAR   3  ■R  BLOQUEAR   4  ▲R  BLOQUEAR   5  ▲B  PASAR
6  ●G  BLOQUEAR   7  ▲G  PASAR   8  ■B  BLOQUEAR   9  ●B  BLOQUEAR  10  ▲G  PASAR
```

- Escena: la cinta muestra el paquete actual (forma + color con `_draw`). Byte decide con `interact` en
  uno de dos `NetworkNode`: **PASAR** (verde) y **BLOQUEAR** (rojo). Decisión correcta = `is_allowed`
  coincide con PASAR/BLOQUEAR; un fallo suma 1 y la cinta avanza al siguiente paquete. Con **≤ 2 fallos**
  en 10 paquetes: emite `solved`, sonido de conexión, abre la `PacketDoor`. Nodo ↺ con `interact` reinicia
  (fallos a 0, vuelve al paquete 1). Dato curioso: "Dato: un firewall deja pasar o bloquea cada paquete según sus reglas."

## 5 · Jefe Firewall Corrupto (`scripts/bosses/firewall_boss.gd`, `FirewallBoss.tscn`)

Arena fija de 640×360, suelo en y = 304. El **muro de reglas** ocupa el lado derecho (x 480–640); su
**núcleo** es una `Hurtbox` de 48×48 (`homing_target = true`, capa 3 `enemy`) detrás del muro. **120 PV**.
El muro se construye con `StageBuilder.platform` (capa 1) en tramos, dejando un hueco de 48×48 en el puerto abierto.

**Puertos** (cómo se daña): el muro tiene 3 puertos en (520, 112), (520, 176) y (520, 240). El núcleo solo
es dañable cuando un puerto está abierto (`core.invulnerable = false`); con todos cerrados, `invulnerable = true`.
El resto del muro absorbe las balas de Byte (capa 1 `world`).

| | F1 "Reglas de bloqueo" (100–70 %) | F2 "Puertos abiertos" (70–40 %) | F3 "El muro avanza" (40–0 %) |
|---|---|---|---|
| Ataque A | **Reglas de bloqueo:** una regla vertical (16×360 px) barre de derecha a izquierda a **140 px/s** con un **hueco de 64 px** en una de 3 alturas (y = 280, 208, 136). Aviso **0,7 s**: la franja del hueco parpadea en blanco. Una regla cada **2,2 s**. | Igual, a **170 px/s**, con **2 huecos** en dos alturas distintas. | Igual que F2, cada **1,6 s**, 1 hueco. |
| Ataque B | — | **Láser de puerto:** desde el puerto abierto sale un láser horizontal a la altura de Byte, activo **0,45 s**. Aviso **0,8 s**: línea discontinua roja. | — |
| Ataque C | — | — | **Avance del muro:** el muro avanza a **24 px/s** desde x = 640. Cada bala que golpea una "regla" lo retrocede **8 px** (mínimo x = 480). El contacto con el muro quita 1 PV. |
| Punto débil | Núcleo tras el puerto **central** (y = 176), abierto **1,2 s** cada **2,8 s** (aviso **0,4 s**: el marco parpadea en blanco). | Núcleo tras el puerto **indicado por color** (destello rojo/verde/azul = alto/medio/bajo); los 3 puertos se abren en secuencia **1,2 s** cada uno. | Núcleo expuesto de forma **permanente** en el puerto central; el resto del muro son reglas destructibles. |
| Patrón | A, A, A… (apertura en paralelo), recuperación 1,0 s | B, A, B, A…, recuperación 0,8 s | C continuo + A cada 1,6 s, recuperación 0,8 s |

Funciones puras testeables: `static func phase_for(hp_ratio: float) -> int` (1, 2 o 3),
`static func rule_gap_lane(index: int) -> int` (0/1/2 → y = 280/208/136, determinista por índice),
`static func correct_port(step: int) -> int` (0/1/2 → alto/medio/bajo, determinista por paso) y
`static func wall_x(hits: int) -> float` (`maxf(480.0, 640.0 - hits * 8.0)`).

Al vencerlo: `GameState.win()` (desbloquea el Mundo 4 en el mapa, que seguirá como PRÓXIMAMENTE).

## 6 · Pruebas obligatorias (TDD: prueba roja → código → verde)

Nuevo `tests/test_world3.gd` registrado en `test_runner.gd` (con el patrón `finished` de los demás):

1. `FirewallFilter`: `is_allowed` solo es `true` para ▲G y ▲B (con `allowed_shape = TRIANGLE`, `blocked_color = RED`); `generate_sequence(0)` da 10 paquetes con 4 permitidos y 6 bloqueados; `generate_sequence(0) == generate_sequence(0)` y `generate_sequence(0) != generate_sequence(1)`.
2. `PortLaser.state_at`: 0,0 → blocked, 1,5 → blocked, 1,7 → open, 2,4 → open, 2,6 → warning, 3,1 → blocked.
3. `RuleBar.gap_lane`: 0,0 → 0, 1,6 → 1, 3,1 → 2 (determinista y solo 0/1/2).
4. `ArmorRule.blocks`: disparo por delante → `true`, por detrás → `false`. `ArmoredPopUp`: con Byte a la izquierda, una bala desde la izquierda no reduce PV; desde la derecha sí.
5. Firewall: `phase_for(1.0) == 1`, `phase_for(0.69) == 2`, `phase_for(0.39) == 3`; `rule_gap_lane` y `correct_port` devuelven solo 0/1/2 para índices 0–20 y ciclan de forma determinista; `wall_x(0) == 640`, `wall_x(10) == 560`, `wall_x(100) == 480`.
6. GameState: `win()` en el mundo 2 desbloquea el 3; `is_world_playable(data, 3)` falso antes de añadir la escena y verdadero después; `is_world_playable(data, 4)` falso aunque esté desbloqueado.
7. `test_scenes_load.gd`: subir el mínimo de escenas según las nuevas (≥ 29).

## 7 · Criterios de aceptación

- Desde el mapa: vencer a la Reina Wi-Fi desbloquea "Firewall"; entrar lleva a 3-1; la compuerta del puzle lleva al Firewall Corrupto; vencerlo vuelve al mapa con el Mundo 4 desbloqueado (PRÓXIMAMENTE).
- 300 frames del nivel 3-1 y del jefe sin errores en headless.
- Capturas en `docs/capturas/` de `level3.png` y `boss3.png`.
- `README.md` del juego actualizado con la sección M9.

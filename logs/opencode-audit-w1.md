# Auditoría del Mundo 1 jugable (solo lectura)

- **Fecha:** 2026-11-22
- **Proyecto:** Packet Quest · Godot 4.7.2 (`game/`)
- **Alcance:** `scripts/player`, `enemies`, `bosses`, `levels` + `docs/03,04,05,06`
- **Método:** ejecución con el MCP `godot` (`run_project` de `World1Level1.tscn` y `RouterBoss.tscn` + `get_debug_output`) y revisión estática del código contra la especificación.
- **Resultado de ejecución:** sin errores en tiempo de ejecución. La salida de depuración solo contiene *warnings* de compilación (detallados abajo).

---

## Resumen ejecutivo

Los valores numéricos del movimiento y del combate **coinciden con la especificación** (velocidad 150, salto −330, gravedad 900, coyote/jump-buffer 0,10 s, dash 72 px / 0,18 s / 0,15 s / 0,6 s, PV 3, PV de Pop-up/Gusano 3/5, avisos 0,4/0,3/0,6/0,8/1,0 s, etc.). La física verifica lo prometido: salto ≈ 60,5 px de altura y el hueco de 96 px de S2 **sí exige dash** (no es trivial ni imposible).

El hallazgo crítico es de **geometría de salida**: el umbral de transición al jefe (`x >= 2720`) es **inalcanzable** porque el muro derecho del nivel detiene a Byte en `x ≈ 2715`. El resto son observaciones de fidelidad/legibilidad de severidad baja-media.

---

## Hallazgos (ordenados por severidad)

| # | Severidad | Archivo:línea | Problema | Evidencia | Corrección propuesta |
|---|---|---|---|---|---|
| 1 | **Alta** | `scripts/levels/world1_level1.gd:60` (umbral) y `:14` (muro) | La transición al jefe **nunca se dispara**. La condición `player.global_position.x >= 2720` es inalcanzable porque el muro derecho (ChipPlatform 16×360 en x=2720) detiene a Byte con su colisionador de 10 px en `x ≈ 2715`. | El colisionador del jugador es un rectángulo 10×14 centrado en su origen (`player.gd:75`), por lo que su borde derecho queda en `2720 − 5 = 2715`. La compuerta del puzle (`PacketDoor`) está en el mismo x=2720. `enter_boss()` (única salida al jefe) queda bloqueado. | Comparar contra `>= 2720 - 5` (o un `Area2D` de salida en x≈2715–2730) y reubicar/eliminar el muro para que la compuerta sea el único bloqueo. |
| 2 | **Media** | `scripts/puzzles/route_puzzle.gd:22-25` vs `scripts/levels/world1_level1.gd:14` | La compuerta del puzle y el muro del nivel comparten x=2720 y se solapan. Abrir la compuerta (`door.set_open(true)`) solo desactiva la forma de la puerta; el muro (`ChipPlatform`) permanece, así que la compuerta es **redundante**. | La puerta ocupa x 2712–2728 (`size` 16×304 con `shape.position=(0,-152)`); el muro ocupa x 2720–2736. Ambos en la capa `world` (1). | Debe quedar un único bloqueo: o la puerta (compuerta) con paso real detrás, o el muro; y el umbral de salida del hallazgo 1 debe ser alcanzable. |
| 3 | **Media** | `scripts/enemies/pop_up.gd` (script) + `enemy_base.gd:47` | El **Pop-up** no implementa "aparecer de golpe" ni la "animación de ventana que se abre" del GDD (`05-enemigos-y-jefes.md`). Está presente desde el arranque y solo alterna `visible = on_screen`. | No hay estado de spawn ni animación de apertura; `pop_up.gd` solo define `_draw` (una ventana estática) y hereda el ciclo de disparo de `EnemyBase`. | Añadir un estado de "aparición" (p. ej. escala/offset de apertura al entrar en pantalla) o generar el enemigo con un `Tween` de entrada. |
| 4 | **Baja** | `scripts/autoload/audio_manager.gd:4` + `scripts/player/player.gd:202-212` | Sin feedback sonoro: `play_sfx` no hace nada sin `stream` y el dash ni siquiera lo invoca. El "whoosh digital" del dash (`03-mecanicas.md`) y el resto de sonidos están ausentes. | `play_sfx` devuelve `return` si `stream == null`; el prototipo es deliberadamente silencioso (comentario en `audio_manager.gd:3`). | Conectar sonidos (o documentarlo como pendiente): dash `whoosh`, disparo, salto, bloqueo, avisos de jefe. |
| 5 | **Baja** | `scripts/puzzles/route_puzzle.gd:82` | La pista anti-atasco resalta los nodos **incorrectos** (`direction != solution`), mientras el GDD dice que "el nodo correcto parpadea". | `nodes[index].hint = ... and nodes[index].direction != solution[index]` (ver `06-puzles.md:57`). | Resaltar el nodo cuya `direction != solution[index]` de forma que indique el valor objetivo, o parpadear el nodo correcto. |
| 6 | **Baja** | `scripts/levels/world1_level1.gd:52` | La pista del núcleo oculto "↑ + K" es incompleta: el núcleo (y=144) exige **salto + dash** (el dash hacia arriba solo cubre 72 px desde y≈249, quedándose por debajo del núcleo). | Núcleo en `(912,144)`, plataforma en `(848,256)`; `249 − 72 = 177` no alcanza el núcleo (centro 144); se necesita `salto (60) + dash (72) = 132 px`. | Cambiar la pista a "Salta y ↑ + K" o similar. |
| 7 | **Baja** | `scripts/player/player.gd:208-209` | El dash **desde el suelo** no marca `air_dash_used`; al salir de un borde con un dash de suelo, queda un "dash aéreo gratis" disponible. | `air_dash_used = true` solo se ejecuta `if not is_on_floor()`. Limitado por el enfriamiento (0,6 s), no es explotable en el hueco de S2, pero rompe la regla "1 dash por salto". | Marcar `air_dash_used = true` también en el dash de suelo, o exigir tocar suelo entre dashes. |
| 8 | **Baja** | `scripts/autoload/events.gd:3-8` | *Warning*: 6 señales "declaradas pero nunca usadas". Son usadas de forma cruzada desde otros scripts (`Events.xxx.emit()`), falso positivo del analizador. | `player_died`, `boss_defeated`, `puzzle_solved`, `checkpoint_reached`, `core_collected`, `impact`. | Suprimir con `@warning_ignore("unused_signal")` o documentar; no es un error. |
| 9 | **Baja** | `scripts/components/style.gd:44` | *Warning*: la variable local `button` sombrea la función homónima `button(...)`. | `func button(...) -> Button:` declara `var button: Button = Button.new()`. | Renombrar la local a `node`/`b`. |
| 10 | **Baja** | `scripts/player/projectile.gd:106` | *Warning*: el parámetro `velocity` de `steer` sombrea el miembro `velocity`. Sin efecto funcional (dentro usa el parámetro). | `static func steer(velocity, to_target, max_turn_rad)`. | Renombrar el parámetro a `v`/`current`. |
| 11 | **Baja** | `scripts/bosses/router_boss.gd` (timing) | "Anillo cada 3 s" (especificado) realmente ocurre ≈ 2,8 s: el *gate* `ring_wait` (3,0 s) no llega a dispararse porque el ciclo A→B tarda 2,79 s. | Secuencia fase 1: A(0,6+0,15+0,2)+B(0,8+0,84+0,2)=2,79 s < 2,4 s necesarios para activar el gate (`ring_wait > ring_telegraph`). | Ajustar `ring_interval` o el ciclo para que el espaciado efectivo sea 3,0 s si se quiere fidelidad exacta. |
| 12 | **Baja** | `scripts/objects/platform.gd:33` | La línea guía del "cable" de la plataforma móvil mide 160 px pero el recorrido real es de 64 px (`vertical_travel`), sugiriendo un alcance mayor del real. | `draw_line(Vector2(size.x/2, 0), Vector2(size.x/2, -160), ...)` con `vertical_travel = 64`. | Dibujar la guía con la longitud `vertical_travel` real (o un cable completo coherente con el desplazamiento). |

---

## Verificación de valores contra la especificación (sin desviaciones)

- **Movimiento:** velocidad 150, aceleración 1200, fricción 1600, gravedad 900 (×1,6 al caer), salto −330 (corte ×0,45), coyote 0,10 s, jump buffer 0,10 s, caída máx 420. ✅
- **Dash:** 72 px / 0,18 s sin gravedad / i-frames 0,15 s / enfriamiento 0,6 s / 1 por salto. La corrección del último tick (`minf(1, dash_left/delta)`) hace el desplazamiento exacto de 72 px a 60 Hz. ✅
- **Armas:** Paquete 1 dmg / 8/s / 480 px/s · Ráfaga 0,6 / 5/s / 420 / ±12° · Ping 1,3 / 6/s / 300 / giro 180°/s. ✅
- **Escudo:** 100 / consumo 40/s / coste 15 / recarga 12/s / retardo 1 s / rotura 2 s / solo frontal / ×0,5 velocidad. ✅
- **Enemigos:** Pop-up PV 3, aviso 0,4 s, bala 120 px/s, ciclo 1,8 s · Gusano PV 5, 60 px/s, aviso 0,3 s, divide en 2 paquetes en arco. ✅
- **Jefe:** PV 60, fase al 50 %, transición 2,4 s, anillo 12×150 px/s aviso 0,6 s, estampida 4×200 px/s aviso 0,8 s, láser aviso 1,0 s, recovery −20 % en fase 2. ✅
- **Física del hueco de S2 (96 px):** el salto alcanza 48 px de altura a x=80 px (antes de los 96 px del hueco) y aterrizaría en la cara del rellano elevado (y=256), por lo que **requiere dash** — no trivial, no imposible. ✅
